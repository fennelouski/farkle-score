//
//  SharedGameTests.swift
//  Farkle Score.Tests
//

import Foundation
import Testing
@testable import Farkle_Score_

struct SharedGameTests {

    private func sampleState() -> GameStoreState {
        GameStoreState(
            players: [
                Player(name: "Alice", score: 4200, avatarEmoji: "😀"),
                Player(name: "Bob", score: 3800, avatarPhotoFileName: "bob-avatar.jpg"),
                Player(name: "Cleo", score: 5000, avatarColorIndex: 7)
            ],
            activePlayerIndex: 1,
            history: [
                ScoreEntry(
                    playerId: UUID(),
                    amount: 500,
                    timestamp: Date(timeIntervalSince1970: 1000)  // whole second: survives ISO-8601
                )
            ],
            autoAdvanceAfterScore: true,
            gamePhase: .regular
        )
    }

    private func customPrefs() -> ScoringPreferencesPayload {
        var prefs = ScoringPreferencesPayload.defaultTemplate(rulesetId: ScoringProfile.defaultRulesetId)
        prefs.activateCustomRuleset()
        prefs.custom.singleOne = 250
        return prefs
    }

    @Test func payloadRoundTripsPreservingStatePrefsAndPhotos() throws {
        let photos = ["bob-avatar.jpg": Data([0x01, 0x02, 0x03, 0x04])]
        let payload = SharedGamePayload(state: sampleState(), scoringPreferences: customPrefs(), photos: photos)

        let data = try payload.encoded()
        let decoded = try SharedGamePayload.decode(data)

        #expect(decoded.state == payload.state)
        #expect(decoded.scoringPreferences == payload.scoringPreferences)
        #expect(decoded.photos == photos)
    }

    @Test func applyPhotosWritesFreshFilesAndRewritesReferences() throws {
        let bytes = Data([9, 8, 7, 6, 5])
        let hydrated = SharedGamePayload.applyPhotos(["bob-avatar.jpg": bytes], to: sampleState())

        let newName = try #require(hydrated.players[1].avatarPhotoFileName)
        #expect(newName != "bob-avatar.jpg")
        #expect(try AvatarImageStore.data(for: newName) == bytes)
        // Non-photo avatars are untouched.
        #expect(hydrated.players[0].avatarPhotoFileName == nil)

        AvatarImageStore.deleteFile(named: newName)
    }

    @Test func danglingPhotoReferenceFallsBackInsteadOfBreaking() {
        let hydrated = SharedGamePayload.applyPhotos([:], to: sampleState())
        #expect(hydrated.players[1].avatarPhotoFileName == nil)
    }

    @Test func rejectsPayloadFromNewerAppVersion() throws {
        var payload = SharedGamePayload(state: sampleState(), scoringPreferences: nil, photos: [:])
        payload.schemaVersion = SharedGamePayload.currentSchemaVersion + 1
        let data = try payload.encoded()

        #expect(throws: SharedGameError.self) {
            _ = try SharedGamePayload.decode(data)
        }
    }
}
