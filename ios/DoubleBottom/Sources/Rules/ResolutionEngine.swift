import Foundation
import Core

/// Строгая реализация раздела 4.6 («Результат вскрытия»), фазы PASS (раздел 4.4 п.6) и общей экономики партии (раздел 4.1).
public struct ResolutionEngine: Sendable {
    public let tuning: Tuning

    public init(tuning: Tuning = .standard) {
        self.tuning = tuning
    }

    /// Фаза PASS (Инспектор пропустил груз или принял взятку — Раздел 4.4 п. 6):
    /// Курьер получает сумму value всех предметов (включая скрытый) минус взятка (если принята).
    /// Инспектор получает взятку, если она была принята. Контрабанда проходит без последствий.
    public func resolvePass(
        packedCase: PackedCase,
        declaration: Declaration,
        bribeAccepted: Bool,
        courierMarks: Int,
        inspectorMarks: Int
    ) -> RoundResolutionSummary {
        let visibleValue = packedCase.visibleItems.reduce(0) { $0 + $1.value }
        let hiddenValue = packedCase.hiddenItem?.value ?? 0
        let totalPassedValue = visibleValue + hiddenValue

        let effectiveBribe = bribeAccepted ? min(courierMarks + totalPassedValue, declaration.bribeMarks) : 0
        let courierFinal = max(0, courierMarks + totalPassedValue - effectiveBribe)
        let inspectorFinal = max(0, inspectorMarks + effectiveBribe)

        return RoundResolutionSummary(
            wasInspected: false,
            bribeAccepted: bribeAccepted,
            falseBottomSearchedAndFound: false,
            verdictBanner: .clean,
            passedItemsValue: totalPassedValue,
            confiscatedFinesPaid: 0,
            compensationPaidByInspector: 0,
            bribeTransferred: effectiveBribe,
            courierNetDelta: courierFinal - courierMarks,
            inspectorNetDelta: inspectorFinal - inspectorMarks,
            courierFinalMarks: courierFinal,
            inspectorFinalMarks: inspectorFinal,
            inspectorWonInspection: false
        )
    }

    /// Фаза INSPECTION -> RESOLUTION (Раздел 4.6):
    /// - Каждый видимый предмет, легальный и из заявленной категории, проходит. Курьер получает его value.
    /// - Каждый остальной видимый предмет (контрабанда или чужая категория) конфискован. Курьер платит Инспектору его fine.
    /// - Найденный скрытый предмет конфискуется так же. Ненайденный проходит, Курьер получает его value.
    /// - Если все видимые предметы честные и скрытого дна нет (или оно не найдено, но предмет в нём легальный),
    ///   Инспектор платит Курьеру компенсацию compensationPerItem × n.
    ///   Если скрытый контрабандный предмет остался незамеченным, компенсации нет и предмет проходит как выигрыш Курьера.
    /// - Деньги не уходят ниже нуля, остаток долга сгорает.
    /// - Если взятка была и Инспектор вскрыл, взятка возвращается Курьеру.
    public func resolveInspection(
        packedCase: PackedCase,
        declaration: Declaration,
        falseBottomFound: Bool,
        courierMarks: Int,
        inspectorMarks: Int
    ) -> RoundResolutionSummary {
        var passedValue = 0
        var rawFines = 0
        var anyViolationFound = false

        for item in packedCase.visibleItems {
            if !item.isContraband && item.category == declaration.category {
                passedValue += item.value
            } else {
                rawFines += item.fine
                anyViolationFound = true
            }
        }

        if let hidden = packedCase.hiddenItem {
            if falseBottomFound {
                rawFines += hidden.fine
                anyViolationFound = true
            } else {
                passedValue += hidden.value
            }
        }

        let allVisibleHonest = packedCase.isVisibleCargoHonest(declaredCategory: declaration.category)
        let shouldPayCompensation: Bool = {
            guard allVisibleHonest else { return false }
            guard let hidden = packedCase.hiddenItem else {
                return true
            }
            if falseBottomFound {
                return false
            }
            // Скрытое дно не найдено: компенсация платится только если предмет в нём легальный
            return !hidden.isContraband
        }()

        let n = packedCase.visibleItems.count
        let rawCompensation = shouldPayCompensation ? (tuning.compensationPerItem * n) : 0

        // Сначала Курьер получает выручку за прошедшие легальные предметы, затем платит штраф (не более доступных марок)
        let courierAvailableBeforeFine = courierMarks + passedValue
        let effectiveFinePaid = min(courierAvailableBeforeFine, rawFines)

        // Инспектор платит компенсацию, но деньги не уходят ниже нуля (остаток долга сгорает)
        let inspectorAvailableBeforeComp = inspectorMarks + effectiveFinePaid
        let effectiveCompensationPaid = min(inspectorAvailableBeforeComp, rawCompensation)

        let courierFinal = max(0, courierAvailableBeforeFine - effectiveFinePaid + effectiveCompensationPaid)
        let inspectorFinal = max(0, inspectorAvailableBeforeComp - effectiveCompensationPaid)

        let verdict: InspectionVerdictBanner = anyViolationFound ? .caught : .clean

        return RoundResolutionSummary(
            wasInspected: true,
            bribeAccepted: false,
            falseBottomSearchedAndFound: falseBottomFound && (packedCase.hiddenItem != nil),
            verdictBanner: verdict,
            passedItemsValue: passedValue,
            confiscatedFinesPaid: effectiveFinePaid,
            compensationPaidByInspector: effectiveCompensationPaid,
            bribeTransferred: 0,
            courierNetDelta: courierFinal - courierMarks,
            inspectorNetDelta: inspectorFinal - inspectorMarks,
            courierFinalMarks: courierFinal,
            inspectorFinalMarks: inspectorFinal,
            inspectorWonInspection: anyViolationFound
        )
    }
}

/// Экономика партии, начисление жетонов «Улики» и определение победителя (Раздел 4.1).
public enum Economy {

    /// В начале раунда Инспектор получает +1 жетон «Улики» до максимума maxClueTokens (5).
    public static func grantInspectorRoundBonus(currentTokens: Int, tuning: Tuning = .standard) -> Int {
        min(tuning.maxClueTokens, max(0, currentTokens) + tuning.inspectorRoundClueBonus)
    }

    /// Определение победителя партии (Раздел 4.1: побеждает самый богатый; равенство — больше выигранных вскрытий).
    public static func rankPlayers(_ players: [PlayerState]) -> [PlayerState] {
        players.sorted { lhs, rhs in
            if lhs.marks != rhs.marks {
                return lhs.marks > rhs.marks
            }
            return lhs.inspectionsWon > rhs.inspectionsWon
        }
    }
}
