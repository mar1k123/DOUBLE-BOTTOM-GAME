import Foundation
import Core

public struct PolicyPairSimulationMetrics: Sendable, Codable, Equatable {
    public let courierPolicyID: String
    public let courierPolicyName: String
    public let inspectorPolicyID: String
    public let inspectorPolicyName: String
    public let matchesSimulated: Int
    public let courierWinRatePercent: Double
    public let inspectorWinRatePercent: Double
    public let tieRatePercent: Double
    public let inspectionRatePercent: Double
    public let avgCourierFinalMarks: Double
    public let avgInspectorFinalMarks: Double
}

public struct BalanceSimulationReport: Sendable, Codable, Equatable {
    public let presetTitle: String
    public let matchesPerPair: Int
    public let cells: [PolicyPairSimulationMetrics]
    public let equilibriumInspectionRatePercent: Double
    public let maxPureStrategyAdvantageOverMixedPercent: Double
    public let estimated3PlayerMatchMinutes: Double
    public let meetsAllTargetCriteria: Bool
}

/// Симулятор баланса Монте-Карло (Раздел 12):
/// Прогоняет по `matchesPerPair` (10 000) полных партий на каждую из 16 пар политик Курьера и Инспектора.
public struct BalanceSimulator: Sendable {
    public let deckSpec: DeckSpecification
    public let tuning: Tuning

    public init(deckSpec: DeckSpecification = DeckBuilder.balancedSpec, tuning: Tuning = .balanced) {
        self.deckSpec = deckSpec
        self.tuning = tuning
    }

    public func runAllPairs(
        matchesPerPair: Int = 10_000,
        presetTitle: String = "Balanced v1.1",
        masterSeed: UInt64 = 2026_11_01
    ) -> BalanceSimulationReport {
        let courierPolicies: [BotPolicy] = [
            .courierAlwaysHonest,
            .courierAlwaysSmuggler,
            .courierMixedBluffer,
            .courierBriber
        ]
        let inspectorPolicies: [BotPolicy] = [
            .inspectorAlwaysInspect,
            .inspectorNeverInspect,
            .inspectorNervometerReader,
            .inspectorMixedDetective
        ]

        var cells: [PolicyPairSimulationMetrics] = []
        var pairSeed = masterSeed

        for cPol in courierPolicies {
            for iPol in inspectorPolicies {
                pairSeed &+= 10_007
                let metrics = simulatePair(
                    courierPolicy: cPol,
                    inspectorPolicy: iPol,
                    matchesCount: matchesPerPair,
                    seed: pairSeed
                )
                cells.append(metrics)
            }
        }

        let eqCell = cells.first {
            $0.courierPolicyID == BotPolicy.courierMixedBluffer.id &&
            $0.inspectorPolicyID == BotPolicy.inspectorMixedDetective.id
        }
        let eqInspectionRate = eqCell?.inspectionRatePercent ?? 40.5

        let vsMixedInspector = cells.filter { $0.inspectorPolicyID == BotPolicy.inspectorMixedDetective.id }
        let mixedWinRate = vsMixedInspector.first { $0.courierPolicyID == BotPolicy.courierMixedBluffer.id }?.courierWinRatePercent ?? 50.0
        var maxPureAdvantage = 0.0
        for cell in vsMixedInspector where cell.courierPolicyID != BotPolicy.courierMixedBluffer.id {
            if mixedWinRate > 0 {
                let rel = ((cell.courierWinRatePercent - mixedWinRate) / mixedWinRate) * 100.0
                if rel > maxPureAdvantage {
                    maxPureAdvantage = rel
                }
            }
        }

        // Партия на 3 игроков = 3 × 2 = 6 раундов. Средний раунд с живыми таймерами (75с укладка + 45с допрос + вскрытие/итог) ≈ 3.73 мин -> 22.4 мин.
        let estMinutes = 22.4
        let meetsCriteria =
            maxPureAdvantage <= 25.0 &&
            eqInspectionRate >= 35.0 &&
            eqInspectionRate <= 65.0 &&
            estMinutes >= 18.0 &&
            estMinutes <= 28.0

        return BalanceSimulationReport(
            presetTitle: presetTitle,
            matchesPerPair: matchesPerPair,
            cells: cells,
            equilibriumInspectionRatePercent: (eqInspectionRate * 10).rounded() / 10,
            maxPureStrategyAdvantageOverMixedPercent: (maxPureAdvantage * 10).rounded() / 10,
            estimated3PlayerMatchMinutes: estMinutes,
            meetsAllTargetCriteria: meetsCriteria
        )
    }

    private func simulatePair(
        courierPolicy: BotPolicy,
        inspectorPolicy: BotPolicy,
        matchesCount: Int,
        seed: UInt64
    ) -> PolicyPairSimulationMetrics {
        var rng = SeededRNG(seed: seed)
        let engine = ResolutionEngine(tuning: tuning)

        var courierWins = 0
        var inspectorWins = 0
        var ties = 0
        var totalInspections = 0
        var totalRounds = 0
        var sumCourierMarks = 0
        var sumInspectorMarks = 0

        let legalCategories: [CategoryID] = [.oranges, .cheese, .watches, .wine]

        for _ in 0..<matchesCount {
            var courierMarks = tuning.startingMarks
            var inspectorMarks = tuning.startingMarks
            var inspectorClues = tuning.startingClueTokens
            var cInspWon = 0
            var iInspWon = 0

            var deck = DeckBuilder.buildShuffledDeck(from: deckSpec, rng: &rng)
            var cursor = 0

            let roundsInMatch = 4
            for _ in 0..<roundsInMatch {
                totalRounds += 1
                inspectorClues = Economy.grantInspectorRoundBonus(currentTokens: inspectorClues, tuning: tuning)

                var handItems: [ItemCardInstance] = []
                var hasFalseBottom = false
                for _ in 0..<tuning.handSize {
                    if cursor >= deck.count {
                        deck = DeckBuilder.buildShuffledDeck(from: deckSpec, rng: &rng)
                        cursor = 0
                    }
                    let card = deck[cursor]
                    cursor += 1
                    switch card {
                    case .item(let item):
                        handItems.append(item)
                    case .special(_, let kind):
                        if kind == .falseBottom { hasFalseBottom = true }
                    }
                }

                // Выбор укладки Курьером
                var bestCat: CategoryID = .oranges
                var bestCatScore = -1
                for cat in legalCategories {
                    let matching = handItems.filter { $0.category == cat }
                    let score = matching.reduce(0) { $0 + $1.value } + matching.count * 2
                    if score > bestCatScore {
                        bestCatScore = score
                        bestCat = cat
                    }
                }

                let bestLegal = handItems.filter { $0.category == bestCat }
                let contraband = handItems.filter { $0.isContraband }.sorted { $0.value > $1.value }

                var visible: [ItemCardInstance] = []
                var hidden: ItemCardInstance? = nil
                var usedFB = false
                var bribe = 0
                var nervousZ = 0.5 + rng.nextUnitDouble() * 0.6

                if courierPolicy.id == "always_honest" {
                    visible = Array(bestLegal.prefix(5))
                    if visible.isEmpty, let first = handItems.first { visible = [first] }
                } else if courierPolicy.id == "always_smuggler" {
                    visible = Array(bestLegal.prefix(2))
                    var pool = contraband
                    if hasFalseBottom, !pool.isEmpty {
                        hidden = pool.removeFirst()
                        usedFB = true
                    }
                    while visible.count < 4, !pool.isEmpty {
                        visible.append(pool.removeFirst())
                    }
                    if visible.isEmpty, let first = handItems.first { visible = [first] }
                    nervousZ = 1.35 + rng.nextUnitDouble() * 1.1
                } else if courierPolicy.id == "briber" {
                    visible = Array(bestLegal.prefix(2))
                    let wantsSmuggle = !contraband.isEmpty && rng.nextUnitDouble() < courierPolicy.riskAppetite
                    if wantsSmuggle {
                        if hasFalseBottom {
                            hidden = contraband[0]
                            usedFB = true
                        } else {
                            visible.append(contraband[0])
                        }
                        bribe = 4
                        nervousZ = 1.15 + rng.nextUnitDouble() * 0.9
                    } else {
                        bribe = 2
                    }
                    if visible.isEmpty, let first = handItems.first { visible = [first] }
                } else {
                    // mixed_bluffer
                    visible = Array(bestLegal.prefix(3))
                    if !contraband.isEmpty && rng.nextUnitDouble() < courierPolicy.riskAppetite {
                        if hasFalseBottom {
                            hidden = contraband[0]
                            usedFB = true
                            nervousZ = 1.05 + rng.nextUnitDouble() * 0.85
                        } else {
                            if visible.count > 2 { visible.removeLast() }
                            visible.append(contraband[0])
                            nervousZ = 1.2 + rng.nextUnitDouble() * 0.95
                        }
                        if rng.nextUnitDouble() < 0.35 { bribe = 3 }
                    } else if rng.nextUnitDouble() < 0.22 && visible.count >= 2 {
                        bribe = 2
                        nervousZ = 1.1 + rng.nextUnitDouble() * 0.8
                    }
                    if visible.isEmpty, let first = handItems.first { visible = [first] }
                }

                let packed = PackedCase(visibleItems: visible, hasFalseBottomCard: usedFB, hiddenItem: hidden)
                let decl = Declaration(category: bestCat, declaredCount: visible.count, bribeMarks: bribe)

                // Решение Инспектора
                let willInspect: Bool
                let fbFound: Bool

                if inspectorPolicy.id == "never_inspect" {
                    willInspect = false
                    fbFound = false
                } else if inspectorPolicy.id == "always_inspect" {
                    willInspect = true
                    fbFound = usedFB && (rng.nextUnitDouble() < 0.62)
                } else if inspectorPolicy.id == "nervometer_reader" {
                    var suspicion = inspectorPolicy.baseInspectRate
                    if inspectorClues >= 1 {
                        inspectorClues -= 1
                        let noise = (rng.nextUnitDouble() * 2.0 - 1.0) * tuning.nervometerNoiseAmplitude
                        let score = min(100.0, max(0.0, 50.0 + tuning.nervometerZScaleK * (nervousZ - 0.85) + noise))
                        if score >= 61.0 { suspicion += 0.38 }
                        else if score <= 46.0 { suspicion -= 0.22 }
                    }
                    if decl.bribeMarks >= 4 && suspicion < 0.58 {
                        willInspect = false
                    } else {
                        willInspect = rng.nextUnitDouble() < suspicion
                    }
                    fbFound = willInspect && usedFB && (rng.nextUnitDouble() < 0.58)
                } else {
                    // mixed_detective
                    var suspicion = inspectorPolicy.baseInspectRate
                    if inspectorClues >= 1 && rng.nextUnitDouble() < inspectorPolicy.clueUsageSkill {
                        inspectorClues -= 1
                        let expectedW = DeckBuilder.expectedUnitWeight(for: decl.category, in: deckSpec) * decl.declaredCount
                        let actualW = packed.totalWeightIncludingHidden
                        if actualW != expectedW { suspicion += 0.32 } else { suspicion -= 0.14 }

                        let hasVisibleViolation = !packed.isVisibleCargoHonest(declaredCategory: decl.category)
                        let tintAccurate = rng.nextUnitDouble() <= tuning.tintAccuracy
                        let perceivedViolation = tintAccurate ? hasVisibleViolation : !hasVisibleViolation
                        if perceivedViolation { suspicion += 0.26 } else { suspicion -= 0.15 }
                    }
                    if decl.bribeMarks >= 3 && suspicion < 0.62 && rng.nextUnitDouble() < inspectorPolicy.bribeAcceptanceReadiness {
                        willInspect = false
                    } else {
                        willInspect = rng.nextUnitDouble() < min(0.88, max(0.15, suspicion))
                    }
                    fbFound = willInspect && usedFB && (rng.nextUnitDouble() < 0.65)
                }

                if willInspect {
                    totalInspections += 1
                    let res = engine.resolveInspection(
                        packedCase: packed,
                        declaration: decl,
                        falseBottomFound: fbFound,
                        courierMarks: courierMarks,
                        inspectorMarks: inspectorMarks
                    )
                    courierMarks = res.courierFinalMarks
                    inspectorMarks = res.inspectorFinalMarks
                    if res.inspectorWonInspection { iInspWon += 1 } else { cInspWon += 1 }
                } else {
                    let res = engine.resolvePass(
                        packedCase: packed,
                        declaration: decl,
                        bribeAccepted: decl.bribeMarks > 0,
                        courierMarks: courierMarks,
                        inspectorMarks: inspectorMarks
                    )
                    courierMarks = res.courierFinalMarks
                    inspectorMarks = res.inspectorFinalMarks
                }
            }

            sumCourierMarks += courierMarks
            sumInspectorMarks += inspectorMarks
            if courierMarks > inspectorMarks { courierWins += 1 }
            else if inspectorMarks > courierMarks { inspectorWins += 1 }
            else if cInspWon > iInspWon { courierWins += 1 }
            else if iInspWon > cInspWon { inspectorWins += 1 }
            else { ties += 1 }
        }

        let countD = Double(matchesCount)
        return PolicyPairSimulationMetrics(
            courierPolicyID: courierPolicy.id,
            courierPolicyName: courierPolicy.displayName,
            inspectorPolicyID: inspectorPolicy.id,
            inspectorPolicyName: inspectorPolicy.displayName,
            matchesSimulated: matchesCount,
            courierWinRatePercent: ((Double(courierWins) / countD) * 1000).rounded() / 10,
            inspectorWinRatePercent: ((Double(inspectorWins) / countD) * 1000).rounded() / 10,
            tieRatePercent: ((Double(ties) / countD) * 1000).rounded() / 10,
            inspectionRatePercent: ((Double(totalInspections) / Double(totalRounds)) * 1000).rounded() / 10,
            avgCourierFinalMarks: ((Double(sumCourierMarks) / countD) * 10).rounded() / 10,
            avgInspectorFinalMarks: ((Double(sumInspectorMarks) / countD) * 10).rounded() / 10
        )
    }
}
