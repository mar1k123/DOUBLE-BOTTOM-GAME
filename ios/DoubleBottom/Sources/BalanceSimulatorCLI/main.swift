import Foundation
import Core
import Rules

@main
struct BalanceSimulatorCLI {
    static func main() {
        print("=== ДВОЙНОЕ ДНО — BalanceSimulator (10 000 партий на каждую пару политик) ===")

        let initialSim = BalanceSimulator(deckSpec: DeckBuilder.initialSpec, tuning: .standard)
        let beforeReport = initialSim.runAllPairs(matchesPerPair: 10_000, presetTitle: "ДО БАЛАНСИРОВКИ (v1.0)")
        printReport(beforeReport)

        let balancedSim = BalanceSimulator(deckSpec: DeckBuilder.balancedSpec, tuning: .balanced)
        let afterReport = balancedSim.runAllPairs(matchesPerPair: 10_000, presetTitle: "ПОСЛЕ БАЛАНСИРОВКИ (v1.1)")
        printReport(afterReport)
    }

    private static func printReport(_ report: BalanceSimulationReport) {
        print("\n--- \(report.presetTitle) (партий на пару: \(report.matchesPerPair)) ---")
        print("Доля вскрытий в равновесии: \(report.equilibriumInspectionRatePercent)% (цель: 35–65%)")
        print("Макс. перевес чистой стратегии над смешанной: +\(report.maxPureStrategyAdvantageOverMixedPercent)% (цель: <= 25%)")
        print("Оценка длительности партии (3 игрока): \(report.estimated3PlayerMatchMinutes) мин (цель: 18–28 мин)")
        print("Статус всех критериев Раздела 12: \(report.meetsAllTargetCriteria ? "ВЫПОЛНЕНО" : "ТРЕБУЕТ ПРАВКИ")")
        for cell in report.cells {
            print("  [\(cell.courierPolicyName) vs \(cell.inspectorPolicyName)] -> К: \(cell.courierWinRatePercent)% | И: \(cell.inspectorWinRatePercent)% | Вскрытий: \(cell.inspectionRatePercent)% | Счёт \(cell.avgCourierFinalMarks):\(cell.avgInspectorFinalMarks)")
        }
    }
}
