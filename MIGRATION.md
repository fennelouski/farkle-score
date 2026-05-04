# Persistence Migration Guide

This document covers the on-disk format used by the **last-session persistence**
feature (introduced together with `GameStorePersistence`). It is the contract
between past, present, and future builds of the app for the file at:

```
Application Support/<bundle-id>/farkle-session.json
```

It is _not_ a general-purpose data-model migration guide. The in-memory
`GameStore` API is intentionally untouched by persistence; the only thing that
needs to migrate is the JSON shape on disk.

---

## Current state

| Field                       | Type             | Notes                                              |
| --------------------------- | ---------------- | -------------------------------------------------- |
| `schemaVersion`             | `Int`            | Always present. Currently `1`.                     |
| `players`                   | `[Player]`       | Each: `id` (UUID), `name` (String), `score` (Int). |
| `activePlayerIndex`         | `Int`            | Clamped to `players` range on restore.             |
| `history`                   | `[ScoreEntry]`   | Each: `id`, `playerId`, `amount`, `timestamp`.     |
| `autoAdvanceAfterScore`     | `Bool`           | Mirrors the live store flag.                       |

**Encoding:** UTF-8 JSON with `.sortedKeys` and `.prettyPrinted`, ISO-8601 dates.

**Intentionally NOT persisted:** `currentInput`. Mid-typed digits are
session-local; rehydrating them across launches would surprise users.

---

## Versioning policy

1. The on-disk schema is identified by the integer `schemaVersion` field.
2. The currently-supported version is `GameStoreState.currentSchemaVersion`.
3. Any change to the persisted shape (added field, removed field, semantic
   reinterpretation of an existing field) **must** bump `currentSchemaVersion`
   by 1 and add a migration step.

### When you DO need to bump the version

- Adding a non-defaulted required field.
- Removing a field that callers relied on.
- Changing the meaning, units, or encoding of an existing field
  (e.g. switching `amount` from `Int` to `Decimal`).
- Renaming a field.

### When you do NOT need to bump the version

- Pure read-side / in-memory changes to `GameStore` that don't alter the DTO.
- Adding a new field that has a default value and is decoded with
  `decodeIfPresent` — both old and new files remain valid v1.
  (Use this sparingly; explicit version bumps are easier to reason about.)

---

## Adding a new schema version

Suppose v2 introduces a `roundNumber: Int` field.

1. **Snapshot the current shape under a versioned name** so old payloads can
   still be decoded:

   ```swift
   private struct GameStoreStateV1: Decodable {
       var schemaVersion: Int
       var players: [Player]
       var activePlayerIndex: Int
       var history: [ScoreEntry]
       var autoAdvanceAfterScore: Bool
   }
   ```

2. **Update the live `GameStoreState`** with the new field and bump the constant:

   ```swift
   static let currentSchemaVersion = 2
   ```

3. **Add a migration step** in `GameStorePersistence.swift`:

   ```swift
   private func migrateV1ToV2(_ old: GameStoreStateV1) -> GameStoreState {
       GameStoreState(
           schemaVersion: 2,
           players: old.players,
           activePlayerIndex: old.activePlayerIndex,
           history: old.history,
           autoAdvanceAfterScore: old.autoAdvanceAfterScore,
           roundNumber: 1 // sensible default for legacy sessions
       )
   }
   ```

4. **Wire it into `load()`**:

   ```swift
   switch probe.schemaVersion {
   case 1:
       let v1 = try decoder.decode(GameStoreStateV1.self, from: data)
       return migrateV1ToV2(v1)
   case 2:
       return try decoder.decode(GameStoreState.self, from: data)
   default:
       throw GameStorePersistenceError.unsupportedSchemaVersion(
           found: probe.schemaVersion,
           supported: GameStoreState.currentSchemaVersion
       )
   }
   ```

5. **Add tests** mirroring the existing pattern: a v1 payload is still readable
   and migrates with the expected defaults.

### Rules of the road

- **Never mutate the file in place.** Migration always reads the old version
  into an intermediate struct, transforms it, and the next save rewrites the
  file at the new version.
- **Never delete a `migrateVN_to_VNPlus1` step.** Migrations chain so a v1
  payload lying on a v3-binary still works.
- **Future-incompatible payloads throw.** A file whose `schemaVersion` is
  higher than the binary supports throws
  `GameStorePersistenceError.unsupportedSchemaVersion`. The app falls back to
  a fresh session rather than guessing.
- **Decoding failures** for any other reason are reported as
  `GameStorePersistenceError.decodingFailed`. The app also falls back to a
  fresh session in this case.

---

## Reset path

There is no in-app "wipe last session" UI today. To reset programmatically
(useful in tests or during debugging):

```swift
GameStorePersistence.default.reset()
```

Or simply delete the file at the path above.

---

## Out of scope

- iCloud / cross-device sync.
- Encryption-at-rest of saved sessions.
- Multiple saved games / named slots.
- Migrations of the in-memory `GameStore` API itself — persistence only adds
  optional disk serialization; the `GameStore` public API should remain stable
  unless the feature explicitly changes it.
