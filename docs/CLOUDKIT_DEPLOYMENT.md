# CloudKit production checklist

Use this when moving from development devices to TestFlight or the App Store. Schema and subscriptions must exist in **Production** for `iCloud.com.nathanfennel.Farkle-Score-`.

## Custom zone

- **Zone name** (from code): `FarkleSync` — created at runtime in the private database if missing.

## Record types and fields

Defined in [`Farkle Score./Sync/CloudKitSchema.swift`](../Farkle%20Score./Sync/CloudKitSchema.swift):

| Record type       | Record name(s)                    | Fields |
|-------------------|-----------------------------------|--------|
| `PlayerRoster`    | `roster`                          | `playersJSON` (Bytes) — JSON array of players (scores stripped on save). |
| `HistoryEntry`    | one per entry (`entry.id` UUID)   | `entryId`, `playerId`, `amount`, `timestamp`, optional `breakdownJSON` (Bytes) — JSON array of score chips |
| `CurrentSession`  | `active`                          | `payload` (Bytes), `modifiedAt` (Date/Double) |
| `AppPreferences` | `preferences`                     | `payload` (Bytes) — JSON `ScoringPreferencesPayload`; `modifiedAt` (Date/Double) for last-write-wins merge. |
| `SavedPlayerProfile` | one per profile (`profile.id` UUID) | `profileId`, `name`, `avatarEmoji`, `avatarColorIndex`, `modifiedAt`, `avatarPhotoFileName`, optional `photo` (Asset) |

## Indexes (Production)

- Query on `HistoryEntry` sorts by `timestamp` descending. In CloudKit Dashboard, ensure an index supports querying/sorting on **timestamp** for `HistoryEntry` in the custom zone (mirror Development after it works there).
- Query on `SavedPlayerProfile` uses a true predicate (`NSPredicate(value: true)`). Ensure the type is queryable in the custom zone (Development → Production).

## Subscriptions

- **Zone subscription ID** (from code): `FarkleSync-zone-subscription`
- Registered from the app via `CKRecordZoneSubscription` with `shouldSendContentAvailable = true` for silent push merges.

## Deploy steps

1. Exercise all sync paths against **Development** (roster save, history rows, optional current session, scoring preferences, saved player profiles with optional photo assets) so record types and fields appear.
2. In CloudKit Dashboard: **Deploy Schema Changes…** from Development to **Production**.
3. Archive a **Release** build (production `aps-environment` entitlements) and verify silent push on TestFlight.
4. If subscriptions fail in production, reset local `AppSettings.didRegisterZoneSubscription` only for debugging (UserDefaults key `farkle.didRegisterZoneSubscription`); release builds should register once per install.
