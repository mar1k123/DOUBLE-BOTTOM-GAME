import XCTest
@testable import Core
@testable import Rules
@testable import DuoSecret
@testable import DuoHinge
@testable import DuoDisplay

final class PresentationPolicyTests: XCTestCase {

    /// Раздел 6.1 и Раздел 12:
    /// «Тесты PresentationPolicy: ни в одной фазе и ни при каком θ на внешний экран не уходит ничего из SecretState. Тест падает при утечке.»
    func testOuterScreenNeverReceivesSecretStateInAnyPhaseOrHingeAngle() {
        var rng = SeededRNG(seed: 1964)
        let deck = DeckBuilder.buildShuffledDeck(from: DeckBuilder.balancedSpec, rng: &rng)

        let secretGold = DeckBuilder.balancedSpec.items.first(where: { $0.id == "gold" })!
        let secretAntique = DeckBuilder.balancedSpec.items.first(where: { $0.id == "antique" })!
        let packed = PackedCase(
            visibleItems: [ItemCardInstance(definition: secretGold)],
            hasFalseBottomCard: true,
            hiddenItem: ItemCardInstance(definition: secretAntique)
        )
        let secretState = SecretState(
            deck: deck,
            courierHand: Array(deck.prefix(5)),
            packedCase: packed,
            slitLevel3Hints: [SecretTintHint(silhouette: .heavyBar, hintedLegalGreen: false)]
        )

        let allPhases = RoundPhase.allCases
        let sampleAngles: [Double] = [0.0, 2.5, 6.0, 14.0, 21.0, 25.0, 45.0, 120.0, 180.0]

        for phase in allPhases {
            for angle in sampleAngles {
                let zone = RoundStateMachine.evaluateZoneWithHysteresis(
                    angleDeg: angle,
                    previousZone: .closed,
                    isCommittedInInspection: angle >= 25.0 && phase == .inspection
                )

                let publicProjection = PublicProjection(
                    roundNumber: 2,
                    totalRounds: 4,
                    phase: phase,
                    hingeZone: zone,
                    courierName: "Мартин Фогель",
                    inspectorName: "Инспектор Кройц",
                    courierMarks: 40,
                    inspectorMarks: 40,
                    inspectorClueTokens: 3,
                    courierPassport: PassportPortraitSpec(combinationIndex: 2),
                    courierCountry: .altavia,
                    courierStamps: [],
                    declaration: Declaration(category: .oranges, declaredCount: 1, bribeMarks: 3),
                    remainingSeconds: 30,
                    verdictBanner: .caught,
                    captainLineText: "Проверка границы."
                )

                let presentation = PresentationPolicy.evaluate(
                    projection: publicProjection,
                    activeRole: .inspector,
                    slitUnlockedWithToken: true,
                    totalCaseWeight: secretState.packedCase.totalWeightIncludingHidden,
                    expectedUnitWeight: 1,
                    visibleSilhouettes: secretState.packedCase.visibleItems.map(\.silhouette),
                    tintedHints: [TintedSilhouetteHint(silhouette: .heavyBar, hintedLegalGreen: false)],
                    falseBottomSearchActive: true
                )

                // Проверяем через Mirror (рефлексию), что ни в OuterScreenDescriptor, ни в PublicProjection
                // нет ни одного поля с названиями реальных предметов ("gold", "antique"), силуэтами ("heavyBar", "tallVase"),
                // весом чемодана или скрытым дном.
                let outerDump = String(describing: presentation.outer) + "|" + String(describing: presentation.publicProjection)
                XCTAssertFalse(outerDump.contains("gold"), "Утечка секретного предмета gold на внешний экран в фазе \(phase) при θ=\(angle)")
                XCTAssertFalse(outerDump.contains("antique"), "Утечка скрытого предмета antique на внешний экран в фазе \(phase) при θ=\(angle)")
                XCTAssertFalse(outerDump.contains("heavyBar"), "Утечка силуэта heavyBar на внешний экран в фазе \(phase) при θ=\(angle)")
                XCTAssertFalse(outerDump.contains("tallVase"), "Утечка силуэта tallVase на внешний экран в фазе \(phase) при θ=\(angle)")
                XCTAssertFalse(outerDump.contains("totalWeight"), "Утечка веса чемодана на внешний экран в фазе \(phase) при θ=\(angle)")
            }
        }
    }

    /// Проверка запасного варианта DuoHingeProvider при отсутствии непрерывного угла (только дискретный статус).
    func testDuoHingeProviderInterpolatesSyntheticAngleWhenHardwareAngleIsNil() async {
        let provider = DuoHingeProvider()
        var iterator = provider.samples.makeAsyncIterator()

        provider.ingestHardwareUpdate(reportedAngleDegrees: nil, posture: .slitPeek, timestamp: 1.0)
        let sample = await iterator.next()

        XCTAssertNotNil(sample)
        XCTAssertEqual(sample?.isSynthetic, true)
        XCTAssertEqual(sample?.discretePosture, .slitPeek)
        XCTAssertNotNil(sample?.angleDegrees)
    }
}
