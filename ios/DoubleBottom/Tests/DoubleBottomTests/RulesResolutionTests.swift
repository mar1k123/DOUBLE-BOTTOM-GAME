import XCTest
@testable import Core
@testable import Rules

final class RulesResolutionTests: XCTestCase {

    private func makeCard(_ id: String, in spec: DeckSpecification = DeckBuilder.initialSpec) -> ItemCardInstance {
        let def = spec.items.first(where: { $0.id == id })!
        return ItemCardInstance(definition: def)
    }

    // MARK: - 1. Все ветки Раздела 4.6 («Результат вскрытия») и PASS

    func testHonestCargoInspectionPaysValueAndCompensation() {
        let engine = ResolutionEngine(tuning: .standard) // compensationPerItem = 2
        let orange = makeCard("orange") // value 2, fine 2, weight 1
        let packed = PackedCase(visibleItems: [orange, orange, orange], hasFalseBottomCard: false, hiddenItem: nil)
        let decl = Declaration(category: .oranges, declaredCount: 3, bribeMarks: 0)

        let res = engine.resolveInspection(
            packedCase: packed,
            declaration: decl,
            falseBottomFound: false,
            courierMarks: 40,
            inspectorMarks: 40
        )

        XCTAssertEqual(res.verdictBanner, .clean)
        XCTAssertEqual(res.passedItemsValue, 6)
        XCTAssertEqual(res.confiscatedFinesPaid, 0)
        XCTAssertEqual(res.compensationPaidByInspector, 6) // 2 * 3
        XCTAssertEqual(res.courierFinalMarks, 52)
        XCTAssertEqual(res.inspectorFinalMarks, 34)
        XCTAssertFalse(res.inspectorWonInspection)
    }

    func testVisibleContrabandAndWrongCategoryConfiscatedAndBribeReturned() {
        let engine = ResolutionEngine(tuning: .standard)
        let cheese = makeCard("cheese") // легально (.cheese), value 3, fine 3
        let watch = makeCard("watch")   // чужая категория (.watches), value 5, fine 4
        let radio = makeCard("radio")   // контрабанда (nil), value 8, fine 6

        let packed = PackedCase(visibleItems: [cheese, watch, radio], hasFalseBottomCard: false, hiddenItem: nil)
        let decl = Declaration(category: .cheese, declaredCount: 3, bribeMarks: 5)

        let res = engine.resolveInspection(
            packedCase: packed,
            declaration: decl,
            falseBottomFound: false,
            courierMarks: 40,
            inspectorMarks: 40
        )

        XCTAssertEqual(res.verdictBanner, .caught)
        XCTAssertEqual(res.passedItemsValue, 3)         // только сыр проходит
        XCTAssertEqual(res.confiscatedFinesPaid, 10)    // часы (4) + радио (6)
        XCTAssertEqual(res.compensationPaidByInspector, 0)
        XCTAssertEqual(res.bribeTransferred, 0)         // взятка возвращена Курьеру при вскрытии
        XCTAssertEqual(res.courierFinalMarks, 33)       // 40 + 3 - 10
        XCTAssertEqual(res.inspectorFinalMarks, 50)     // 40 + 10
        XCTAssertTrue(res.inspectorWonInspection)
    }

    func testUnfoundFalseBottomWithContrabandPassesWithoutCompensation() {
        let engine = ResolutionEngine(tuning: .standard)
        let wine = makeCard("wine") // value 4
        let gold = makeCard("gold") // контрабанда, value 10, fine 8

        let packed = PackedCase(visibleItems: [wine, wine], hasFalseBottomCard: true, hiddenItem: gold)
        let decl = Declaration(category: .wine, declaredCount: 2, bribeMarks: 0)

        let res = engine.resolveInspection(
            packedCase: packed,
            declaration: decl,
            falseBottomFound: false,
            courierMarks: 40,
            inspectorMarks: 40
        )

        // По 4.6: «Если скрытый контрабандный предмет остался незамеченным, компенсации нет и предмет проходит как выигрыш Курьера.»
        XCTAssertEqual(res.verdictBanner, .clean)
        XCTAssertEqual(res.passedItemsValue, 18) // 4 + 4 + 10
        XCTAssertEqual(res.compensationPaidByInspector, 0)
        XCTAssertEqual(res.courierFinalMarks, 58)
        XCTAssertEqual(res.inspectorFinalMarks, 40)
    }

    func testFoundFalseBottomConfiscatesHiddenItem() {
        let engine = ResolutionEngine(tuning: .standard)
        let wine = makeCard("wine")       // value 4
        let antique = makeCard("antique") // контрабанда, value 12, fine 9

        let packed = PackedCase(visibleItems: [wine, wine], hasFalseBottomCard: true, hiddenItem: antique)
        let decl = Declaration(category: .wine, declaredCount: 2, bribeMarks: 0)

        let res = engine.resolveInspection(
            packedCase: packed,
            declaration: decl,
            falseBottomFound: true,
            courierMarks: 40,
            inspectorMarks: 40
        )

        XCTAssertEqual(res.verdictBanner, .caught)
        XCTAssertTrue(res.falseBottomSearchedAndFound)
        XCTAssertEqual(res.passedItemsValue, 8)
        XCTAssertEqual(res.confiscatedFinesPaid, 9)
        XCTAssertEqual(res.compensationPaidByInspector, 0)
        XCTAssertEqual(res.courierFinalMarks, 39)
        XCTAssertEqual(res.inspectorFinalMarks, 49)
    }

    func testZeroBalanceFloorBurnsRemainingDebt() {
        let engine = ResolutionEngine(tuning: .standard)
        let antique = makeCard("antique") // fine 9
        let packed = PackedCase(visibleItems: [antique, antique, antique], hasFalseBottomCard: false, hiddenItem: nil)
        let decl = Declaration(category: .oranges, declaredCount: 3, bribeMarks: 0)

        let res = engine.resolveInspection(
            packedCase: packed,
            declaration: decl,
            falseBottomFound: false,
            courierMarks: 5,
            inspectorMarks: 40
        )

        XCTAssertEqual(res.courierFinalMarks, 0)
        XCTAssertEqual(res.confiscatedFinesPaid, 5) // заплатил только 5 из 27, остаток долга сгорел
        XCTAssertEqual(res.inspectorFinalMarks, 45)
    }

    // MARK: - 2. Тесты антидребезга печати (250 мс), щёлочки и гистерезиса

    func testSealDebounceRequires250MsAndCompleteCargo() {
        var rng = SeededRNG(seed: 77)
        let deck = DeckBuilder.buildShuffledDeck(from: DeckBuilder.initialSpec, rng: &rng)
        var sm = RoundStateMachine(
            roundNumber: 1,
            initialHand: Array(deck.prefix(6)),
            courierMarks: 40,
            inspectorMarks: 40,
            inspectorClueTokens: 3,
            initialAngleDeg: 120.0
        )

        // Попытка закрыть пустой чемодан вызывает предупреждение и не запечатывает
        sm.updateHinge(angleDeg: 1.5, deltaMs: 300)
        XCTAssertEqual(sm.phase, .packing)
        XCTAssertTrue(sm.isIncompleteSealWarningActive)

        // Кладём 2 апельсина и декларируем
        sm.updateHinge(angleDeg: 120.0, deltaMs: 50)
        let orange = makeCard("orange")
        XCTAssertTrue(sm.configureCargo(
            visibleItems: [orange, orange],
            hasFalseBottomCard: false,
            hiddenItem: nil,
            declaredCategory: .oranges,
            bribeMarks: 0
        ))

        // Удержание 150 мс (< 250 мс) ещё не ставит печать
        sm.updateHinge(angleDeg: 2.0, deltaMs: 150)
        XCTAssertEqual(sm.phase, .packing)

        // Ещё 120 мс (суммарно 270 мс >= 250 мс) — запечатано!
        sm.updateHinge(angleDeg: 2.0, deltaMs: 120)
        XCTAssertEqual(sm.phase, .sealing)
    }

    func testSlitTokenChargedOnceAndBlockedWhenZeroTokens() {
        var rng = SeededRNG(seed: 88)
        let deck = DeckBuilder.buildShuffledDeck(from: DeckBuilder.initialSpec, rng: &rng)
        var sm = RoundStateMachine(
            roundNumber: 1,
            initialHand: Array(deck.prefix(6)),
            courierMarks: 40,
            inspectorMarks: 40,
            inspectorClueTokens: 0, //+1 бонус раунда = 1 жетон
            initialAngleDeg: 120.0
        )
        XCTAssertEqual(sm.inspectorClueTokens, 1)

        let orange = makeCard("orange")
        _ = sm.configureCargo(visibleItems: [orange], hasFalseBottomCard: false, hiddenItem: nil, declaredCategory: .oranges, bribeMarks: 0)
        sm.updateHinge(angleDeg: 1.0, deltaMs: 260)
        sm.updateHinge(angleDeg: 1.0, deltaMs: 16) // переход в NEGOTIATION

        // Вход в Уровень 1 щёлочки (6°) списывает 1 жетон
        sm.updateHinge(angleDeg: 6.0, deltaMs: 16)
        XCTAssertEqual(sm.inspectorClueTokens, 0)
        XCTAssertTrue(sm.isSlitPermittedThisRound)

        // Переход на Уровень 2 (14°) и Уровень 3 (21°) в том же раунде повторно жетон НЕ списывает
        sm.updateHinge(angleDeg: 14.0, deltaMs: 16)
        sm.updateHinge(angleDeg: 21.0, deltaMs: 16)
        XCTAssertEqual(sm.inspectorClueTokens, 0)
        XCTAssertTrue(sm.isSlitPermittedThisRound)
    }
}
