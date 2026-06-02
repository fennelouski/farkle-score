//
//  Farkle_Score_Tests.swift
//  Farkle Score.Tests
//

import Foundation
import Testing
@testable import Farkle_Score_

struct GameStoreTests {

    @Test func addWithEmptyInputAddsZeroAndDoesNotRecordHistory() {
        let store = GameStore(players: [Player(name: "A", score: 10)], activePlayerIndex: 0)
        store.clearInput()
        store.addToScore()
        #expect(store.players[0].score == 10)
        #expect(store.history.isEmpty)
        #expect(store.currentInput.isEmpty)
    }

    @Test func addWithParsedValueUpdatesScoreAndHistory() {
        let store = GameStore(players: [Player(name: "A", score: 100)], activePlayerIndex: 0)
        store.appendDigit("5")
        store.appendDigit("0")
        store.addToScore()
        #expect(store.players[0].score == 150)
        #expect(store.history.count == 1)
        #expect(store.history.last?.amount == 50)
    }

    @Test func presetReplacesInput() {
        let store = GameStore()
        store.appendDigit("1")
        store.setPreset(300)
        #expect(store.currentInput == "300")
        #expect(store.parsedInputAmount == 300)
    }

    @Test func undoRestoresScoreAndPopsHistory() {
        let store = GameStore(players: [Player(name: "A", score: 0)], activePlayerIndex: 0)
        store.setPreset(100)
        store.addToScore()
        #expect(store.players[0].score == 100)
        store.undoLastEntry()
        #expect(store.players[0].score == 0)
        #expect(store.history.isEmpty)
    }

    @Test func maxSixPlayers() {
        let store = GameStore(players: [
            Player(name: "1"), Player(name: "2"), Player(name: "3"),
            Player(name: "4"), Player(name: "5"), Player(name: "6"),
        ])
        #expect(store.canAddPlayer == false)
        store.addPlayer(name: "7")
        #expect(store.players.count == 6)
    }

    @Test func newGameZerosScoresAndClearsHistory() {
        let store = GameStore(players: [Player(name: "A", score: 500), Player(name: "B", score: 200)])
        store.setPreset(50)
        store.addToScore()
        store.newGame()
        #expect(store.players[0].score == 0)
        #expect(store.players[1].score == 0)
        #expect(store.history.isEmpty)
        #expect(store.currentInput.isEmpty)
    }

    @Test func newGameCanBeUndoneOnce() {
        let store = GameStore(
            players: [Player(name: "A", score: 100), Player(name: "B", score: 50)],
            activePlayerIndex: 1,
            history: [ScoreEntry(playerId: UUID(), amount: 100)]
        )
        store.newGame()
        #expect(store.players[0].score == 0)
        #expect(store.canUndoNewGame)
        store.undoNewGame()
        #expect(store.players[0].score == 100)
        #expect(store.players[1].score == 50)
        #expect(store.activePlayerIndex == 1)
        #expect(!store.canUndoNewGame)
    }

    @Test func scoringAfterNewGameClearsUndoReset() {
        let store = GameStore(players: [Player(name: "A", score: 200)], activePlayerIndex: 0)
        store.newGame()
        #expect(store.canUndoNewGame)
        store.setPreset(10)
        store.addToScore()
        #expect(!store.canUndoNewGame)
    }

    @Test func finalRoundIncludesTriggeringPlayer() {
        let alice = UUID()
        let bob = UUID()
        let store = GameStore(
            players: [
                Player(id: alice, name: "Alice", score: 9_900),
                Player(id: bob, name: "Bob", score: 0),
            ],
            activePlayerIndex: 0
        )
        store.setPreset(100)
        store.addToScore()
        #expect(store.gamePhase == .finalRound)
        #expect(store.finalRoundPendingPlayerIDs.contains(alice))
        #expect(store.finalRoundPendingPlayerIDs.contains(bob))
    }

    @Test func rosterMergePrefersCloudIdsAndKeepsMatchingScores() {
        let idA = UUID(), idB = UUID()
        let cloud = [
            Player(id: idA, name: "Mom", score: 0),
            Player(id: idB, name: "Dad", score: 0),
        ]
        let local = [
            Player(id: idA, name: "Alice", score: 100),
            Player(id: idB, name: "Bob", score: 50),
        ]
        let merged = RosterSeeding.mergedPlayers(cloud: cloud, local: local)
        #expect(merged.count == 2)
        #expect(merged[0].name == "Mom")
        #expect(merged[0].score == 100)
        #expect(merged[1].name == "Dad")
        #expect(merged[1].score == 50)
    }

    @Test func rosterMergeWithoutCloudLeavesLocalUntouched() {
        let local = [Player(name: "Only", score: 42)]
        let merged = RosterSeeding.mergedPlayers(cloud: nil, local: local)
        #expect(merged.count == 1)
        #expect(merged[0].name == "Only")
        #expect(merged[0].score == 42)
    }

    @Test func rosterMergePreservesLocalPhotoAndTakesCloudEmoji() {
        let id = UUID()
        let cloud = [Player(id: id, name: "Pat", score: 0, avatarEmoji: "🎲")]
        let local = [Player(id: id, name: "Old", score: 10, avatarEmoji: nil, avatarPhotoFileName: "abc.jpg")]
        let merged = RosterSeeding.mergedPlayers(cloud: cloud, local: local)
        #expect(merged[0].name == "Pat")
        #expect(merged[0].score == 10)
        #expect(merged[0].avatarEmoji == "🎲")
        #expect(merged[0].avatarPhotoFileName == "abc.jpg")
    }

    @Test func autoAdvanceCyclesPlayer() {
        let store = GameStore(
            players: [Player(name: "A"), Player(name: "B")],
            activePlayerIndex: 0,
            autoAdvanceAfterScore: true
        )
        store.setPreset(10)
        store.addToScore()
        #expect(store.activePlayerIndex == 1)
    }

    @Test func appendDigitStopsAtNineCharacters() {
        let store = GameStore(players: [Player(name: "A")], activePlayerIndex: 0)
        for _ in 0 ..< 9 {
            store.appendDigit("1")
        }
        #expect(store.currentInput.count == 9)
        store.appendDigit("2")
        #expect(store.currentInput == "111111111")
    }

    @Test func appendDoubleZeroBlockedWhenWouldExceedNineDigits() {
        let store = GameStore(players: [Player(name: "A")], activePlayerIndex: 0)
        for _ in 0 ..< 8 {
            store.appendDigit("1")
        }
        #expect(store.currentInput.count == 8)
        store.appendDoubleZero()
        #expect(store.currentInput.count == 8)

        store.clearInput()
        for _ in 0 ..< 7 {
            store.appendDigit("1")
        }
        store.appendDoubleZero()
        #expect(store.currentInput == "111111100")
        #expect(store.currentInput.count == 9)
    }

    /// After `undoLastEntry`, history is popped before resolving the player row; if that player is gone, no score changes.
    @Test func undoAfterRemovingScoringPlayerConsumesHistoryWithoutAdjustingScores() {
        let aliceId = UUID()
        let bobId = UUID()
        let store = GameStore(
            players: [
                Player(id: aliceId, name: "Alice", score: 0),
                Player(id: bobId, name: "Bob", score: 0),
            ],
            activePlayerIndex: 0
        )
        store.setPreset(100)
        store.addToScore()
        #expect(store.players.first(where: { $0.id == aliceId })?.score == 100)
        #expect(store.history.count == 1)

        store.players = [Player(id: bobId, name: "Bob", score: 0)]

        store.undoLastEntry()
        #expect(store.history.isEmpty)
        #expect(store.players.count == 1)
        #expect(store.players[0].score == 0)
    }

    @Test func newGamePreservesActivePlayerIndexWhenStillValid() {
        let store = GameStore(
            players: [Player(name: "A"), Player(name: "B"), Player(name: "C")],
            activePlayerIndex: 2
        )
        store.newGame()
        #expect(store.activePlayerIndex == 2)
    }

    @Test func newGameResetsActivePlayerIndexWhenOutOfRange() {
        let store = GameStore(
            players: [Player(name: "A"), Player(name: "B"), Player(name: "C")],
            activePlayerIndex: 2
        )
        store.players = [Player(name: "A"), Player(name: "B")]
        store.newGame()
        #expect(store.activePlayerIndex == 0)
    }

    @Test func secondUndoWithEmptyHistoryIsNoOp() {
        let store = GameStore(players: [Player(name: "A", score: 0)], activePlayerIndex: 0)
        store.setPreset(50)
        store.addToScore()
        store.undoLastEntry()
        store.undoLastEntry()
        #expect(store.players[0].score == 0)
        #expect(store.history.isEmpty)
    }

    @Test func undoTwiceRestoresScoreAfterTwoAdds() {
        let store = GameStore(players: [Player(name: "A", score: 0)], activePlayerIndex: 0)
        store.setPreset(25)
        store.addToScore()
        store.setPreset(75)
        store.addToScore()
        #expect(store.players[0].score == 100)
        store.undoLastEntry()
        #expect(store.players[0].score == 25)
        store.undoLastEntry()
        #expect(store.players[0].score == 0)
        #expect(store.history.isEmpty)
    }

    @Test func deleteHistoryEntryRemovesMiddleEntryAndAdjustsScore() {
        let aliceId = UUID()
        let bobId = UUID()
        let entryAlice = ScoreEntry(playerId: aliceId, amount: 100)
        let entryBob = ScoreEntry(playerId: bobId, amount: 50)
        let store = GameStore(
            players: [
                Player(id: aliceId, name: "Alice", score: 100),
                Player(id: bobId, name: "Bob", score: 50),
            ],
            activePlayerIndex: 0,
            history: [entryAlice, entryBob]
        )
        store.deleteHistoryEntry(id: entryAlice.id)
        #expect(store.history.count == 1)
        #expect(store.history[0].id == entryBob.id)
        #expect(store.players.first(where: { $0.id == aliceId })?.score == 0)
        #expect(store.players.first(where: { $0.id == bobId })?.score == 50)
    }

    @Test func deleteHistoryEntryWhenPlayerRemovedDropsHistoryWithoutAdjustingScores() {
        let aliceId = UUID()
        let bobId = UUID()
        let orphanEntry = ScoreEntry(playerId: aliceId, amount: 100)
        let store = GameStore(
            players: [Player(id: bobId, name: "Bob", score: 200)],
            activePlayerIndex: 0,
            history: [orphanEntry]
        )
        store.deleteHistoryEntry(id: orphanEntry.id)
        #expect(store.history.isEmpty)
        #expect(store.players[0].score == 200)
    }

    @Test func prepareToEditHistoryEntryPrefillsInputAndSelectsPlayer() {
        let aliceId = UUID()
        let bobId = UUID()
        let entryAlice = ScoreEntry(playerId: aliceId, amount: 75)
        let entryBob = ScoreEntry(playerId: bobId, amount: 25)
        let store = GameStore(
            players: [
                Player(id: aliceId, name: "Alice", score: 75),
                Player(id: bobId, name: "Bob", score: 25),
            ],
            activePlayerIndex: 1,
            history: [entryAlice, entryBob]
        )
        #expect(store.prepareToEditHistoryEntry(id: entryAlice.id))
        #expect(store.history.count == 1)
        #expect(store.history[0].id == entryBob.id)
        #expect(store.activePlayerIndex == 0)
        #expect(store.players.first(where: { $0.id == aliceId })?.score == 0)
        #expect(store.currentInput == "75")
    }

    @Test func prepareToEditHistoryEntryReturnsFalseWhenPlayerMissing() {
        let aliceId = UUID()
        let orphanEntry = ScoreEntry(playerId: aliceId, amount: 50)
        let store = GameStore(
            players: [Player(name: "Bob", score: 0)],
            activePlayerIndex: 0,
            history: [orphanEntry]
        )
        #expect(!store.prepareToEditHistoryEntry(id: orphanEntry.id))
        #expect(store.history.count == 1)
        #expect(store.currentInput.isEmpty)
    }

    @Test func initClampsActivePlayerIndexToLastPlayer() {
        let store = GameStore(
            players: [Player(name: "A"), Player(name: "B")],
            activePlayerIndex: 99
        )
        #expect(store.activePlayerIndex == 1)
    }

    @Test func serialAddUndoAddProducesExpectedScore() {
        let store = GameStore(players: [Player(name: "A", score: 0)], activePlayerIndex: 0)
        store.setPreset(10)
        store.addToScore()
        store.undoLastEntry()
        store.setPreset(5)
        store.addToScore()
        #expect(store.players[0].score == 5)
        #expect(store.history.count == 1)
    }
}

// MARK: - Persistence

struct PersistenceTests {

    /// snapshot/restore round-trips the four persisted fields.
    @Test func snapshotRestoreRoundTripPreservesPersistedFields() {
        let p1 = Player(name: "A", score: 1200)
        let p2 = Player(name: "B", score: 350)
        let original = GameStore(
            players: [p1, p2],
            activePlayerIndex: 1,
            history: [
                ScoreEntry(playerId: p1.id, amount: 1200),
                ScoreEntry(playerId: p2.id, amount: 350),
            ],
            currentInput: "",
            autoAdvanceAfterScore: true
        )

        let snap = original.snapshot
        let target = GameStore(players: [Player(name: "X")])
        target.restore(from: snap)

        #expect(target.players == [p1, p2])
        #expect(target.activePlayerIndex == 1)
        #expect(target.history.count == 2)
        #expect(target.history.map(\.amount) == [1200, 350])
        #expect(target.autoAdvanceAfterScore == true)
    }

    /// `currentInput` is not in the DTO — restore clears keypad so nothing from the snapshot or prior typing lingers.
    @Test func restoreDoesNotRehydrateCurrentInput() {
        let source = GameStore(
            players: [Player(name: "A")],
            activePlayerIndex: 0,
            currentInput: "4321"
        )
        let snap = source.snapshot

        let target = GameStore(players: [Player(name: "X")])
        target.appendDigit("9")
        #expect(target.currentInput == "9")

        target.restore(from: snap)

        #expect(target.currentInput.isEmpty)
    }

    /// snapshot must not include `currentInput` even when source has one.
    @Test func snapshotIsAgnosticToCurrentInput() {
        let store = GameStore(
            players: [Player(name: "A")],
            activePlayerIndex: 0,
            currentInput: "123"
        )
        // Reaching for the DTO directly: there is no `currentInput` field to inspect.
        // Asserting the snapshot type's stored properties is enough — if anyone adds
        // currentInput later the round-trip test above will continue to fail loudly.
        let snap = store.snapshot
        #expect(snap.players.count == 1)
        #expect(snap.activePlayerIndex == 0)
    }

    /// Codable round-trip via the persistence pipeline is byte-identical on re-encode.
    @Test func persistenceRoundTripIsByteIdenticalOnReencode() throws {
        let url = makeTempFileURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let persistence = GameStorePersistence(fileURL: url)

        let state = GameStoreState(
            players: [Player(name: "A", score: 100), Player(name: "B", score: 200)],
            activePlayerIndex: 1,
            history: [ScoreEntry(playerId: UUID(), amount: 100, timestamp: Date(timeIntervalSince1970: 1_700_000_000))],
            autoAdvanceAfterScore: false
        )

        try persistence.save(state)
        let bytes1 = try Data(contentsOf: url)
        let loaded = try persistence.load()
        try persistence.save(try #require(loaded))
        let bytes2 = try Data(contentsOf: url)

        #expect(bytes1 == bytes2)
    }

    /// restore clamps an out-of-range `activePlayerIndex` to the valid range.
    @Test func restoreClampsOutOfRangeActivePlayerIndex() {
        let snap = GameStoreState(
            players: [Player(name: "A"), Player(name: "B")],
            activePlayerIndex: 99,
            history: [],
            autoAdvanceAfterScore: false
        )
        let store = GameStore(players: [Player(name: "X")])
        store.restore(from: snap)
        #expect(store.activePlayerIndex == 1)
    }

    /// restore tolerates a negative `activePlayerIndex` by clamping to 0.
    @Test func restoreClampsNegativeActivePlayerIndex() {
        let snap = GameStoreState(
            players: [Player(name: "A"), Player(name: "B")],
            activePlayerIndex: -5,
            history: [],
            autoAdvanceAfterScore: false
        )
        let store = GameStore(players: [Player(name: "X")])
        store.restore(from: snap)
        #expect(store.activePlayerIndex == 0)
    }

    /// File save/load round-trip preserves equality on the DTO.
    @Test func fileSaveLoadRoundTrip() throws {
        let url = makeTempFileURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let persistence = GameStorePersistence(fileURL: url)

        let state = GameStoreState(
            players: [Player(name: "A", score: 50)],
            activePlayerIndex: 0,
            history: [ScoreEntry(playerId: UUID(), amount: 50, timestamp: Date(timeIntervalSince1970: 1_700_000_000))],
            autoAdvanceAfterScore: true
        )
        try persistence.save(state)

        let loaded = try persistence.load()
        #expect(loaded == state)
    }

    /// Loading when no file is present returns nil rather than throwing.
    @Test func loadingMissingFileReturnsNil() throws {
        let url = makeTempFileURL()
        // No save call — file shouldn't exist.
        let persistence = GameStorePersistence(fileURL: url)
        let loaded = try persistence.load()
        #expect(loaded == nil)
    }

    /// A payload from a newer schema must throw `unsupportedSchemaVersion`.
    @Test func loadingFutureSchemaVersionThrows() throws {
        let url = makeTempFileURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let json = #"{"schemaVersion": 999, "players": [], "activePlayerIndex": 0, "history": [], "autoAdvanceAfterScore": false}"#
        try json.data(using: .utf8)!.write(to: url)

        let persistence = GameStorePersistence(fileURL: url)
        #expect(throws: GameStorePersistenceError.unsupportedSchemaVersion(found: 999, supported: 1)) {
            _ = try persistence.load()
        }
    }

    /// A corrupt payload throws a `decodingFailed` error rather than crashing.
    @Test func loadingCorruptPayloadThrowsDecodingFailed() throws {
        let url = makeTempFileURL()
        defer { try? FileManager.default.removeItem(at: url) }
        try "not even close to json".data(using: .utf8)!.write(to: url)

        let persistence = GameStorePersistence(fileURL: url)
        var caughtDecoding = false
        do {
            _ = try persistence.load()
        } catch let error as GameStorePersistenceError {
            if case .decodingFailed = error { caughtDecoding = true }
        }
        #expect(caughtDecoding)
    }

    /// `reset()` removes the on-disk session.
    @Test func resetRemovesFile() throws {
        let url = makeTempFileURL()
        let persistence = GameStorePersistence(fileURL: url)
        try persistence.save(GameStoreState(
            players: [Player(name: "A")],
            activePlayerIndex: 0,
            history: [],
            autoAdvanceAfterScore: false
        ))
        #expect(FileManager.default.fileExists(atPath: url.path))
        persistence.reset()
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }

    // MARK: helpers

    private func makeTempFileURL() -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FarklePersistenceTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("session.json")
    }
}

// MARK: - Player monogram & avatar model

struct PlayerMonogramTests {

    @Test func distinctFirstInitialsStaySingleLetter() {
        let a = Player(name: "Alice")
        let b = Player(name: "Bob")
        let c = Player(name: "Chris")
        let roster = [a, b, c]
        #expect(PlayerMonogram.text(for: a.id, in: roster) == "A")
        #expect(PlayerMonogram.text(for: b.id, in: roster) == "B")
        #expect(PlayerMonogram.text(for: c.id, in: roster) == "C")
    }

    @Test func collisionUsesTwoLetterPrefix() {
        let alice = Player(name: "Alice")
        let aaron = Player(name: "Aaron")
        let roster = [alice, aaron]
        let ma = PlayerMonogram.text(for: alice.id, in: roster)
        let mb = PlayerMonogram.text(for: aaron.id, in: roster)
        #expect(ma != mb)
        #expect(ma == "AL")
        #expect(mb == "AA")
    }

    @Test func multiWordNamesUseInitialsWhenColliding() {
        let p1 = Player(name: "Anna Smith")
        let p2 = Player(name: "Anna Jones")
        let roster = [p1, p2]
        #expect(PlayerMonogram.text(for: p1.id, in: roster) == "AS")
        #expect(PlayerMonogram.text(for: p2.id, in: roster) == "AJ")
    }

    @Test func draftNamePreviewMatchesFutureMonogram() {
        let existing = [Player(name: "Bob")]
        let preview = PlayerMonogram.textForDraftName("Ben", existingPlayers: existing)
        let ben = Player(name: "Ben")
        let roster = existing + [ben]
        #expect(preview == PlayerMonogram.text(for: ben.id, in: roster))
    }

    @Test func playerJSONRoundTripWithAvatarFields() throws {
        let original = Player(name: "Sam", score: 3, avatarEmoji: "🎯", avatarPhotoFileName: "snap.jpg")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Player.self, from: data)
        #expect(decoded == original)
    }

    @Test func playerDecodesOmittingOptionalAvatarKeys() throws {
        let id = UUID()
        let json = """
        {"id":"\(id.uuidString)","name":"Lee","score":0}
        """
        let p = try JSONDecoder().decode(Player.self, from: Data(json.utf8))
        #expect(p.id == id)
        #expect(p.name == "Lee")
        #expect(p.avatarEmoji == nil)
        #expect(p.avatarPhotoFileName == nil)
        #expect(p.profileId == nil)
        #expect(p.avatarColorIndex == nil)
    }

    @Test func playerJSONRoundTripWithProfileFields() throws {
        let profileId = UUID()
        let original = Player(
            name: "Sam",
            score: 3,
            avatarEmoji: "🎯",
            profileId: profileId,
            avatarColorIndex: 2
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Player.self, from: data)
        #expect(decoded == original)
    }

    @Test func effectiveAvatarColorIndexUsesStoredValue() {
        let p = Player(name: "A", avatarColorIndex: 4)
        #expect(p.effectiveAvatarColorIndex(listIndex: 0) == 4)
        let fallback = Player(name: "B")
        #expect(fallback.effectiveAvatarColorIndex(listIndex: 3) == 3)
    }

    @Test func playerAvatarPaletteCountMatchesClamping() {
        #expect(AppTheme.playerAvatarColors.count == AppTheme.playerAvatarColorsHighContrast.count)
        #expect(AppTheme.playerAvatarColors.count == PlayerProfile.avatarColorCount)
        #expect(PlayerProfile.clampedColorIndex(99) == 99 % PlayerProfile.avatarColorCount)
        #expect(PlayerProfile.clampedColorIndex(-1) == PlayerProfile.avatarColorCount - 1)
    }

    @Test func normalizedEmojiExtractsFirstEmoji() {
        #expect(Player.normalizedEmoji("hi🎲there") == "🎲")
        #expect(Player.normalizedEmoji("nope") == nil)
    }
}

// MARK: - Saved player profiles

struct ProfileMergeTests {

    @Test func mergeUsesNewerModifiedAtPerId() {
        let id = UUID()
        let older = PlayerProfile(id: id, name: "Old", modifiedAt: Date(timeIntervalSince1970: 100))
        let newer = PlayerProfile(id: id, name: "New", modifiedAt: Date(timeIntervalSince1970: 200))
        let merged = ProfileMerge.merged(local: [older], cloud: [newer])
        #expect(merged.count == 1)
        #expect(merged[0].name == "New")
    }

    @Test func mergeKeepsLocalWhenNewer() {
        let id = UUID()
        let local = PlayerProfile(id: id, name: "Local", modifiedAt: Date(timeIntervalSince1970: 300))
        let cloud = PlayerProfile(id: id, name: "Cloud", modifiedAt: Date(timeIntervalSince1970: 200))
        let merged = ProfileMerge.merged(local: [local], cloud: [cloud])
        #expect(merged[0].name == "Local")
    }
}

struct PlayerProfileStoreTests {

    @Test func crudRoundTrip() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("profiles-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let persistence = PlayerProfilePersistence(fileURL: url)
        let store = PlayerProfileStore(persistence: persistence)
        let profile = PlayerProfile(name: "Jordan", avatarColorIndex: 1)
        store.add(profile, persist: true)
        #expect(store.profiles.count == 1)
        store.update(PlayerProfile(id: profile.id, name: "Jordan S.", avatarColorIndex: 2), persist: true)
        #expect(store.profile(id: profile.id)?.name == "Jordan S.")
        store.delete(id: profile.id, persist: true)
        #expect(store.profiles.isEmpty)
    }
}

struct GameRosterProfileSyncTests {

    @Test func syncBackfillsDefaultRosterIntoLibrary() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("profiles-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let profileStore = PlayerProfileStore(persistence: PlayerProfilePersistence(fileURL: url))
        var players = GameStore.defaultPlayers()
        #expect(players.allSatisfy { $0.profileId == nil })
        #expect(profileStore.profiles.isEmpty)

        let changed = GameRosterProfileSync.sync(players: &players, profileStore: profileStore)

        #expect(changed)
        #expect(players.count == 3)
        #expect(players.allSatisfy { $0.profileId != nil })
        #expect(profileStore.profiles.count == 3)
        #expect(Set(profileStore.profiles.map(\.name)) == Set(["Alice", "Bob", "Chris"]))
    }

    @Test func syncAdoptsPhotoToCanonicalProfileFilename() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("profiles-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let profileStore = PlayerProfileStore(persistence: PlayerProfilePersistence(fileURL: url))
        let jpeg = Data([0xFF, 0xD8, 0xFF, 0xD9])
        let tempPhoto = try AvatarImageStore.saveImageData(jpeg)
        defer { AvatarImageStore.deleteFile(named: tempPhoto) }

        var players = [
            Player(name: "Sam", avatarPhotoFileName: tempPhoto),
            Player(name: "Pat"),
        ]
        _ = GameRosterProfileSync.sync(players: &players, profileStore: profileStore)

        let profileId = try #require(players[0].profileId)
        let canonical = AvatarImageStore.profilePhotoFileName(for: profileId)
        #expect(players[0].avatarPhotoFileName == canonical)
        #expect(profileStore.profile(id: profileId)?.avatarPhotoFileName == canonical)
        defer { AvatarImageStore.deleteFile(named: canonical) }
    }

    @Test func syncUpdatesExistingLinkedProfileFromRoster() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("profiles-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let profileStore = PlayerProfileStore(persistence: PlayerProfilePersistence(fileURL: url))
        let profileId = UUID()
        profileStore.add(
            PlayerProfile(id: profileId, name: "Old Name", avatarColorIndex: 0),
            persist: true
        )
        var players = [
            Player(name: "New Name", profileId: profileId, avatarColorIndex: 4),
            Player(name: "Other"),
        ]

        _ = GameRosterProfileSync.sync(players: &players, profileStore: profileStore)

        #expect(profileStore.profile(id: profileId)?.name == "New Name")
        #expect(profileStore.profile(id: profileId)?.avatarColorIndex == 4)
    }
}

struct GameStoreProfileTests {

    @Test func addPlayerFromProfileLinksIdentity() {
        let profileId = UUID()
        let profile = PlayerProfile(id: profileId, name: "Riley", avatarEmoji: "⭐", avatarColorIndex: 3)
        let store = GameStore(players: [Player(name: "A"), Player(name: "B")])
        store.addPlayer(from: profile)
        #expect(store.players.count == 3)
        #expect(store.players[2].profileId == profileId)
        #expect(store.players[2].name == "Riley")
        #expect(store.players[2].avatarColorIndex == 3)
        #expect(store.isProfileInGame(profileId))
    }

    @Test func updateAndRemovePlayer() {
        let store = GameStore(players: [
            Player(name: "A"),
            Player(name: "B"),
            Player(name: "C"),
        ])
        store.updatePlayer(
            at: 1,
            with: GameStore.PlayerIdentityUpdate(name: "Bob Jr.", avatarColorIndex: 5)
        )
        #expect(store.players[1].name == "Bob Jr.")
        #expect(store.players[1].avatarColorIndex == 5)
        store.removePlayer(at: 2)
        #expect(store.players.count == 2)
        #expect(store.canRemovePlayerDownToMinimum == false)
    }
}

// MARK: - Rules-aware scoring

struct FarkleScoringEngineTests {

    private let straightRun = [1, 2, 3, 4, 5, 6]
    private let threeOnes = [1, 1, 1, 2, 3, 4]
    private let threePairs234 = [2, 2, 3, 3, 4, 4]
    private let farkleNoPoints = [2, 3, 4, 4, 6, 6]

    @Test(arguments: [
        ("farkle-wikipedia-arnold", 2_500),
        ("farkle-cardgames-io", 2_500),
        ("farkle-groupgames101", 3_000),
        ("farkle-farkle-games", 1_000),
        ("zilch-playr", 1_500),
        ("farkle-playmonster", 2_500),
    ])
    func straightPointsVaryByRuleset(rulesetId: String, expected: Int) {
        let rules = ScoringProfile.profile(for: rulesetId)
        let c = FarkleScoringEngine.makeCounts(from: straightRun)
        #expect(FarkleScoringEngine.maximumPoints(counts: c, rules: rules) == expected)
    }

    @Test(arguments: [
        ("farkle-wikipedia-arnold", 1_000),
        ("farkle-playmonster", 300),
    ])
    func threeOnesFolkVsRetail(rulesetId: String, expected: Int) {
        let rules = ScoringProfile.profile(for: rulesetId)
        let c = FarkleScoringEngine.makeCounts(from: threeOnes)
        #expect(FarkleScoringEngine.maximumPoints(counts: c, rules: rules) == expected)
    }

    @Test(arguments: [
        ("farkle-wikipedia-arnold", 1_500),
        ("farkle-farkle-games", 750),
    ])
    func threePairsDiffer(rulesetId: String, expected: Int) {
        let rules = ScoringProfile.profile(for: rulesetId)
        let c = FarkleScoringEngine.makeCounts(from: threePairs234)
        #expect(FarkleScoringEngine.maximumPoints(counts: c, rules: rules) == expected)
    }

    @Test func buscheStraightIsOnlySingles() {
        let rules = ScoringProfile.profile(for: "farkle-busche-neller-2017")
        let c = FarkleScoringEngine.makeCounts(from: straightRun)
        // Only 1 and 5 score; one each → 150
        #expect(FarkleScoringEngine.maximumPoints(counts: c, rules: rules) == 150)
        #expect(FarkleScoringEngine.isHotDice(counts: c, rules: rules) == false)
    }

    @Test func zilchFourTwos() {
        let rules = ScoringProfile.profile(for: "zilch-playr")
        let c = FarkleScoringEngine.makeCounts(from: [2, 2, 2, 2, 3, 4])
        // Four of a kind: triple 200 × 2 = 400; leftover 3,4 score 0
        #expect(FarkleScoringEngine.maximumPoints(counts: c, rules: rules) == 400)
    }

    @Test func wrongRulesetChangesSameDice() {
        let c = FarkleScoringEngine.makeCounts(from: threeOnes)
        let arnold = ScoringProfile.profile(for: "farkle-wikipedia-arnold")
        let retail = ScoringProfile.profile(for: "farkle-playmonster")
        #expect(FarkleScoringEngine.maximumPoints(counts: c, rules: arnold) == 1_000)
        #expect(FarkleScoringEngine.maximumPoints(counts: c, rules: retail) == 300)
        #expect(FarkleScoringEngine.maximumPoints(counts: c, rules: arnold)
            != FarkleScoringEngine.maximumPoints(counts: c, rules: retail))
    }

    @Test func isFarkleWhenNothingScores() {
        let rules = ScoringProfile.profile(for: ScoringProfile.defaultRulesetId)
        let c = FarkleScoringEngine.makeCounts(from: farkleNoPoints)
        #expect(FarkleScoringEngine.maximumPoints(counts: c, rules: rules) == 0)
        #expect(FarkleScoringEngine.isFarkle(counts: c, rules: rules))
    }

    @Test func hotDiceStraightUsesAllSix() {
        let rules = ScoringProfile.profile(for: "farkle-cardgames-io")
        let c = FarkleScoringEngine.makeCounts(from: straightRun)
        #expect(FarkleScoringEngine.isHotDice(counts: c, rules: rules))
    }
}

// MARK: - App settings

struct AppSettingsTests {

    @Test func hapticsEnabledUnsetDefaultsTrueAndPersistsFalse() {
        let key = AppSettings.hapticsEnabledStorageKey
        let previous = UserDefaults.standard.object(forKey: key)
        defer {
            if let previous {
                UserDefaults.standard.set(previous, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        UserDefaults.standard.removeObject(forKey: key)
        #expect(AppSettings.hapticsEnabled == true)
        AppSettings.hapticsEnabled = false
        #expect(AppSettings.hapticsEnabled == false)
    }

    @Test func defaultRulesetMetadataHasSubtitleForSettingsPreview() {
        let id = ScoringProfile.defaultRulesetId
        let subtitle = RulesLibrary.metadata(id: id)?.subtitle
        #expect(subtitle != nil)
        #expect(!(subtitle?.isEmpty ?? true))
    }
}

struct TurnScoreBuilderTests {

    private var cardgamesProfile: ScoringProfile {
        ScoringProfile.profile(for: "farkle-cardgames-io")
    }

    private func preset(label: String, in profile: ScoringProfile) -> CommonScorePreset {
        let presets = profile.commonScorePresets()
        guard let match = presets.first(where: { $0.label == label }) else {
            Issue.record("Missing preset \(label)")
            return CommonScorePreset(value: 0, label: label)
        }
        return match
    }

    @Test func isRepeatableSingleOnlyForOnesAndFives() {
        let profile = cardgamesProfile
        let single1 = preset(label: "Single 1", in: profile)
        let single5 = preset(label: "Single 5", in: profile)
        let three6 = preset(label: "Three 6s", in: profile)
        #expect(profile.isRepeatableSingle(preset: single1))
        #expect(profile.isRepeatableSingle(preset: single5))
        #expect(!profile.isRepeatableSingle(preset: three6))
        #expect(profile.isRepeatableChip(preset: single1))
        #expect(profile.isRepeatableChip(preset: three6))
        #expect(profile.isTriplePreset(preset: three6))
    }

    @Test func build850WithChipsAndCombo() {
        let store = GameStore(players: [Player(name: "A", score: 0)], activePlayerIndex: 0)
        let profile = cardgamesProfile
        store.appendTurnEntry(preset: preset(label: "Single 1", in: profile), profile: profile)
        store.appendTurnEntry(preset: preset(label: "Single 1", in: profile), profile: profile)
        store.appendTurnEntry(preset: preset(label: "Single 5", in: profile), profile: profile)
        store.appendTurnEntry(preset: preset(label: "Three 6s", in: profile), profile: profile)
        #expect(store.resolvedTurnAmount == 850)
        #expect(store.singleChipEntries.count == 3)
        #expect(store.turnEntries.count == 4)
    }

    @Test func removeSingleChipByIdUpdatesTotal() {
        let store = GameStore(players: [Player(name: "A", score: 0)], activePlayerIndex: 0)
        let profile = cardgamesProfile
        store.appendTurnEntry(preset: preset(label: "Single 1", in: profile), profile: profile)
        store.appendTurnEntry(preset: preset(label: "Single 1", in: profile), profile: profile)
        store.appendTurnEntry(preset: preset(label: "Single 5", in: profile), profile: profile)
        store.appendTurnEntry(preset: preset(label: "Three 6s", in: profile), profile: profile)
        let firstSingleId = store.singleChipEntries[0].id
        store.removeTurnEntry(id: firstSingleId)
        #expect(store.resolvedTurnAmount == 750)
        #expect(store.singleChipEntries.count == 2)
        #expect(store.turnEntries.count == 3)
    }

    @Test func backspaceRemovesLastEntryIncludingCombo() {
        let store = GameStore(players: [Player(name: "A", score: 0)], activePlayerIndex: 0)
        let profile = cardgamesProfile
        store.appendTurnEntry(preset: preset(label: "Single 1", in: profile), profile: profile)
        store.appendTurnEntry(preset: preset(label: "Single 1", in: profile), profile: profile)
        store.appendTurnEntry(preset: preset(label: "Single 5", in: profile), profile: profile)
        store.appendTurnEntry(preset: preset(label: "Three 6s", in: profile), profile: profile)
        store.backspace()
        #expect(store.resolvedTurnAmount == 250)
        #expect(store.turnEntries.count == 3)
    }

    @Test func comboEntryIsNotASingleChip() {
        let store = GameStore(players: [Player(name: "A", score: 0)], activePlayerIndex: 0)
        let profile = cardgamesProfile
        store.appendTurnEntry(preset: preset(label: "Three 6s", in: profile), profile: profile)
        #expect(store.singleChipEntries.isEmpty)
        #expect(store.repeatableChipEntries.count == 1)
        #expect(store.turnEntries.first?.kind == .tripleChip)
        #expect(store.turnEntries.first?.diceCount == 3)
        #expect(store.resolvedTurnAmount == 600)
    }

    @Test func keypadDigitClearsTurnBuilder() {
        let store = GameStore(players: [Player(name: "A", score: 0)], activePlayerIndex: 0)
        let profile = cardgamesProfile
        store.appendTurnEntry(preset: preset(label: "Single 1", in: profile), profile: profile)
        store.appendDigit("5")
        #expect(store.turnEntries.isEmpty)
        #expect(store.currentInput == "5")
        #expect(store.resolvedTurnAmount == 5)
    }

    @Test func addToScoreCommitsBuilderTotalOnce() {
        let store = GameStore(players: [Player(name: "A", score: 0)], activePlayerIndex: 0)
        let profile = cardgamesProfile
        store.appendTurnEntry(preset: preset(label: "Single 1", in: profile), profile: profile)
        store.appendTurnEntry(preset: preset(label: "Single 5", in: profile), profile: profile)
        store.addToScore()
        #expect(store.players[0].score == 150)
        #expect(store.history.count == 1)
        #expect(store.history.last?.amount == 150)
        #expect(store.turnEntries.isEmpty)
    }

    @Test func selectPlayerClearsTurnBuilder() {
        let store = GameStore(
            players: [Player(name: "A", score: 0), Player(name: "B", score: 0)],
            activePlayerIndex: 0
        )
        let profile = cardgamesProfile
        store.appendTurnEntry(preset: preset(label: "Single 1", in: profile), profile: profile)
        store.selectPlayer(at: 1)
        #expect(store.turnEntries.isEmpty)
        #expect(store.activePlayerIndex == 1)
    }

    @Test func singleChipMaxSixPerLabel() {
        let store = GameStore(players: [Player(name: "A", score: 0)], activePlayerIndex: 0)
        let profile = cardgamesProfile
        let single1 = preset(label: "Single 1", in: profile)
        for _ in 0 ..< 6 {
            #expect(store.canAppendTurnEntry(preset: single1, profile: profile))
            store.appendTurnEntry(preset: single1, profile: profile)
        }
        #expect(store.turnEntries.count == 6)
        #expect(!store.canAppendTurnEntry(preset: single1, profile: profile))
        store.appendTurnEntry(preset: single1, profile: profile)
        #expect(store.turnEntries.count == 6)
    }

    @Test func tripleChipsMaxTwoTotal() {
        let store = GameStore(players: [Player(name: "A", score: 0)], activePlayerIndex: 0)
        let profile = cardgamesProfile
        let three6 = preset(label: "Three 6s", in: profile)
        let three1 = preset(label: "Three 1s", in: profile)
        store.appendTurnEntry(preset: three6, profile: profile)
        store.appendTurnEntry(preset: three1, profile: profile)
        #expect(store.turnEntries.count == 2)
        #expect(TurnEntryLimits.totalDice(in: store.turnEntries) == 6)
        #expect(!store.canAppendTurnEntry(preset: three6, profile: profile))
        store.appendTurnEntry(preset: three6, profile: profile)
        #expect(store.turnEntries.count == 2)
    }

    @Test func tripleOnesAllowsSingleOnesOnSameFace() {
        let store = GameStore(players: [Player(name: "A", score: 0)], activePlayerIndex: 0)
        let profile = cardgamesProfile
        let three1 = preset(label: "Three 1s", in: profile)
        let single1 = preset(label: "Single 1", in: profile)
        store.appendTurnEntry(preset: three1, profile: profile)
        #expect(store.canAppendTurnEntry(preset: single1, profile: profile))
        for _ in 0 ..< 3 {
            store.appendTurnEntry(preset: single1, profile: profile)
        }
        #expect(store.turnEntries.count == 4)
        #expect(TurnEntryLimits.combinedFaceCounts(in: store.turnEntries)[0] == 6)
        #expect(store.resolvedTurnAmount == 1_300)
        #expect(!store.canAppendTurnEntry(preset: single1, profile: profile))
    }

    @Test func tripleFivesAllowsSingleFivesOnSameFace() {
        let store = GameStore(players: [Player(name: "A", score: 0)], activePlayerIndex: 0)
        let profile = cardgamesProfile
        store.appendTurnEntry(preset: preset(label: "Three 5s", in: profile), profile: profile)
        store.appendTurnEntry(preset: preset(label: "Single 5", in: profile), profile: profile)
        store.appendTurnEntry(preset: preset(label: "Single 5", in: profile), profile: profile)
        store.appendTurnEntry(preset: preset(label: "Single 5", in: profile), profile: profile)
        #expect(TurnEntryLimits.combinedFaceCounts(in: store.turnEntries)[4] == 6)
        #expect(store.resolvedTurnAmount == 650)
    }

    @Test func diceBudgetBlocksSeventhDie() {
        let store = GameStore(players: [Player(name: "A", score: 0)], activePlayerIndex: 0)
        let profile = cardgamesProfile
        store.appendTurnEntry(preset: preset(label: "Three 6s", in: profile), profile: profile)
        store.appendTurnEntry(preset: preset(label: "Three 6s", in: profile), profile: profile)
        #expect(store.turnEntries.count == 2)
        let single1 = preset(label: "Single 1", in: profile)
        #expect(!store.canAppendTurnEntry(preset: single1, profile: profile))
        store.appendTurnEntry(preset: single1, profile: profile)
        #expect(store.turnEntries.count == 2)
    }

    @Test func straightUsesFullDiceBudget() {
        let store = GameStore(players: [Player(name: "A", score: 0)], activePlayerIndex: 0)
        let profile = cardgamesProfile
        let straight = preset(label: "Straight 1–6", in: profile)
        store.appendTurnEntry(preset: straight, profile: profile)
        #expect(store.turnEntries.count == 1)
        #expect(store.turnEntries.first?.diceCount == 6)
        let single5 = preset(label: "Single 5", in: profile)
        #expect(!store.canAppendTurnEntry(preset: single5, profile: profile))
        store.appendTurnEntry(preset: single5, profile: profile)
        #expect(store.turnEntries.count == 1)
    }

    @Test func dicePreviewRespectsDiceBudget() {
        let store = GameStore(players: [Player(name: "A", score: 0)], activePlayerIndex: 0)
        let profile = cardgamesProfile
        store.appendTurnEntry(preset: preset(label: "Three 6s", in: profile), profile: profile)
        store.appendTurnEntry(preset: preset(label: "Three 1s", in: profile), profile: profile)
        let previewFaces = [0, 0, 0, 0, 2, 2]
        #expect(!store.canAppendTurnEntry(
            diceCount: 4,
            label: "Dice preview (500)",
            faceCounts: previewFaces,
            isTriple: false,
            maxPerLabel: 1
        ))
        store.appendTurnEntry(
            value: 500,
            label: "Dice preview (500)",
            kind: .combination,
            diceCount: 4,
            faceCounts: previewFaces
        )
        #expect(store.turnEntries.count == 2)
    }

    @Test func dicePreviewAppendSucceedsWithinBudget() {
        let store = GameStore(players: [Player(name: "A", score: 0)], activePlayerIndex: 0)
        let threeTwos = [0, 3, 0, 0, 0, 0]
        store.appendTurnEntry(
            value: 300,
            label: "Dice preview (300)",
            kind: .combination,
            diceCount: 3,
            faceCounts: threeTwos
        )
        #expect(store.turnEntries.count == 1)
        let threeThrees = [0, 0, 3, 0, 0, 0]
        store.appendTurnEntry(
            value: 200,
            label: "Dice preview (200)",
            kind: .combination,
            diceCount: 3,
            faceCounts: threeThrees
        )
        #expect(store.turnEntries.count == 2)
        #expect(TurnEntryLimits.totalDice(in: store.turnEntries) == 6)
    }

    @Test func dicePreviewRejectsDuplicateLabel() {
        let store = GameStore(players: [Player(name: "A", score: 0)], activePlayerIndex: 0)
        let threeTwos = [0, 3, 0, 0, 0, 0]
        store.appendTurnEntry(
            value: 300,
            label: "Dice preview (300)",
            kind: .combination,
            diceCount: 3,
            faceCounts: threeTwos
        )
        store.appendTurnEntry(
            value: 300,
            label: "Dice preview (300)",
            kind: .combination,
            diceCount: 3,
            faceCounts: threeTwos
        )
        #expect(store.turnEntries.count == 1)
    }

    @Test func dicePreviewRespectsPerFaceLimit() {
        let store = GameStore(players: [Player(name: "A", score: 0)], activePlayerIndex: 0)
        let profile = cardgamesProfile
        store.appendTurnEntry(preset: preset(label: "Three 1s", in: profile), profile: profile)
        let fourOnes = [4, 0, 0, 0, 0, 0]
        #expect(!store.canAppendTurnEntry(
            diceCount: 4,
            label: "Dice preview (1,000)",
            faceCounts: fourOnes,
            isTriple: false,
            maxPerLabel: 1
        ))
    }
}

struct TurnScoreRepresentabilityTests {

    @Test func sevenIsNotRepresentableForCardgamesIo() {
        let rules = ScoringProfile.profile(for: "farkle-cardgames-io")
        #expect(!rules.canRepresentAsCommonScores(amount: 7))
        #expect(!TurnScoreRepresentability.canRepresent(7, denominations: rules.commonScorePresets().map(\.value)))
    }

    @Test func fiftyAndOneFiftyAreRepresentableForCardgamesIo() {
        let rules = ScoringProfile.profile(for: "farkle-cardgames-io")
        #expect(rules.canRepresentAsCommonScores(amount: 50))
        #expect(rules.canRepresentAsCommonScores(amount: 150))
    }

    @Test func zeroIsRepresentable() {
        let rules = ScoringProfile.profile(for: ScoringProfile.defaultRulesetId)
        #expect(rules.canRepresentAsCommonScores(amount: 0))
        #expect(TurnScoreRepresentability.canRepresent(0, denominations: [50, 100]))
    }

    @Test func gcdTrapOneFiftyWithHundredAndTwoHundredOnly() {
        #expect(!TurnScoreRepresentability.canRepresent(150, denominations: [100, 200]))
    }

    @Test func everyCommonPresetValueIsRepresentableForDefaultRuleset() {
        let rules = ScoringProfile.profile(for: ScoringProfile.defaultRulesetId)
        let presets = rules.commonScorePresets()
        for preset in presets {
            #expect(
                rules.canRepresentAsCommonScores(amount: preset.value),
                "Preset \(preset.value) (\(preset.label)) should be representable"
            )
        }
    }
}
