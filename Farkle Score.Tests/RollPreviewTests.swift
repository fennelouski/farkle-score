//
//  RollPreviewTests.swift
//  Farkle Score.Tests
//

import Foundation
import Testing
@testable import Farkle_Score_

struct RollPreviewTests {

    private func six(_ values: [Int?]) -> [Int?] {
        precondition(values.count == 6)
        return values
    }

    @Test func emptyRollSummary() {
        let rules = ScoringProfile.profile(for: ScoringProfile.defaultRulesetId)
        let s = RollPreview.summary(faces: six([nil, nil, nil, nil, nil, nil]), rules: rules)
        #expect(s.maxPoints == 0)
        #expect(s.isFarkle == false)
        #expect(s.isHotDice == false)
        #expect(s.diceUsed == 0)
    }

    @Test func singleOnePartialRoll() {
        let rules = ScoringProfile.profile(for: ScoringProfile.defaultRulesetId)
        let s = RollPreview.summary(faces: six([1, nil, nil, nil, nil, nil]), rules: rules)
        #expect(s.maxPoints == 100)
        #expect(s.isFarkle == false)
        #expect(s.isHotDice == false)
        #expect(s.diceUsed == 1)
    }

    @Test func straightCardgamesIo() {
        let rules = ScoringProfile.profile(for: "farkle-cardgames-io")
        let s = RollPreview.summary(faces: six([1, 2, 3, 4, 5, 6]), rules: rules)
        #expect(s.maxPoints == 2_500)
        #expect(s.isFarkle == false)
        #expect(s.isHotDice == true)
        #expect(s.diceUsed == 6)
    }

    @Test func threePairsFarkleGames() {
        let rules = ScoringProfile.profile(for: "farkle-farkle-games")
        let s = RollPreview.summary(faces: six([2, 2, 3, 3, 4, 4]), rules: rules)
        #expect(s.maxPoints == 750)
        #expect(s.isFarkle == false)
        #expect(s.isHotDice == true)
        #expect(s.diceUsed == 6)
    }

    @Test func farkleNoPointsDefaultRuleset() {
        let rules = ScoringProfile.profile(for: ScoringProfile.defaultRulesetId)
        let s = RollPreview.summary(faces: six([2, 3, 4, 4, 6, 6]), rules: rules)
        #expect(s.maxPoints == 0)
        #expect(s.isFarkle == true)
        #expect(s.isHotDice == false)
        #expect(s.diceUsed == 6)
    }

    @Test func zilchFourTwosWrapper() {
        let rules = ScoringProfile.profile(for: "zilch-playr")
        let s = RollPreview.summary(faces: six([2, 2, 2, 2, 3, 4]), rules: rules)
        #expect(s.maxPoints == 400)
        #expect(s.isFarkle == false)
        #expect(s.isHotDice == false)
        #expect(s.diceUsed == 6)
    }

    @Test func nextFaceCyclesAllSteps() {
        let steps: [(Int?, Int?)] = [
            (nil, 1),
            (1, 2),
            (2, 3),
            (3, 4),
            (4, 5),
            (5, 6),
            (6, nil),
        ]
        for (current, expected) in steps {
            #expect(RollPreview.nextFace(current) == expected)
        }
    }
}
