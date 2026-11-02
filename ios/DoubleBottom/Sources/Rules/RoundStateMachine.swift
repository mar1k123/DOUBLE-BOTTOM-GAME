import Foundation
import Core

/// Конечный автомат раунда (Раздел 4.4, 4.5, 5.1, 5.4):
/// DEAL → PACKING → SEALING → NEGOTIATION → DECISION → ( PASS | INSPECTION ) → RESOLUTION → ROUND_END
public struct RoundStateMachine: Sendable {
    public let tuning: Tuning
    public let roundNumber: Int
    public private(set) var phase: RoundPhase
    public private(set) var hingeZone: HingeZone
    public private(set) var currentAngleDeg: Double

    // Курьер и укладка
    public private(set) var hand: [HandCard]
    public private(set) var hasUsedMulligan: Bool = false
    public private(set) var packedCase: PackedCase = PackedCase()
    public private(set) var declaration: Declaration?

    // Запечатывание (SEALING антидребезг 250 мс)
    public private(set) var sealHoldAccumulatedMs: Int = 0
    public private(set) var isIncompleteSealWarningActive: Bool = false

    // Щёлочка и вскрытие (INSPECTION)
    public private(set) var slitClueTokenChargedThisRound: Bool = false
    public private(set) var isSlitPermittedThisRound: Bool = false
    public private(set) var isNoClueTokensWarningActive: Bool = false
    public private(set) var isOfficiallyCommitted: Bool = false

    // Поиск двойного дна (6 секунд, 2 плавных наклона ≥ 25°)
    public private(set) var falseBottomSmoothTiltCount: Int = 0
    public private(set) var falseBottomSearchRemainingSec: TimeInterval

    // Экономика участников раунда
    public private(set) var courierMarks: Int
    public private(set) var inspectorMarks: Int
    public private(set) var inspectorClueTokens: Int
    public private(set) var resolutionSummary: RoundResolutionSummary?

    public init(
        roundNumber: Int = 1,
        initialHand: [HandCard],
        courierMarks: Int,
        inspectorMarks: Int,
        inspectorClueTokens: Int,
        initialAngleDeg: Double = 120.0,
        tuning: Tuning = .standard
    ) {
        self.tuning = tuning
        self.roundNumber = roundNumber
        self.hand = initialHand
        self.courierMarks = courierMarks
        self.inspectorMarks = inspectorMarks
        self.inspectorClueTokens = Economy.grantInspectorRoundBonus(
            currentTokens: inspectorClueTokens,
            tuning: tuning
        )
        self.currentAngleDeg = initialAngleDeg
        self.falseBottomSearchRemainingSec = tuning.falseBottomSearchSeconds
        if initialAngleDeg >= tuning.openAngleDeg {
            self.hingeZone = .open
            self.phase = .packing
        } else {
            self.hingeZone = .closed
            self.phase = .deal
        }
    }

    // MARK: - 1. Сброс до 2 карт перед упаковкой (один раз за раунд, Раздел 4.3)

    public mutating func performMulligan(
        discardCardIDs: [UUID],
        deck: inout [HandCard]
    ) -> Bool {
        guard phase == .packing || phase == .deal else { return false }
        guard !hasUsedMulligan else { return false }
        guard !discardCardIDs.isEmpty && discardCardIDs.count <= tuning.maxMulliganCards else { return false }

        let idsSet = Set(discardCardIDs)
        let removedCount = hand.filter { idsSet.contains($0.id) }.count
        guard removedCount == discardCardIDs.count, deck.count >= removedCount else { return false }

        hand.removeAll { idsSet.contains($0.id) }
        for _ in 0..<removedCount {
            hand.append(deck.removeFirst())
        }
        hasUsedMulligan = true
        return true
    }

    // MARK: - 2. Укладка чемодана и декларация (Раздел 4.3)

    public mutating func configureCargo(
        visibleItems: [ItemCardInstance],
        hasFalseBottomCard: Bool,
        hiddenItem: ItemCardInstance?,
        declaredCategory: CategoryID,
        bribeMarks: Int
    ) -> Bool {
        guard phase == .packing else { return false }
        guard visibleItems.count >= 1 && visibleItems.count <= tuning.maxVisibleSlots else { return false }
        if hiddenItem != nil && !hasFalseBottomCard {
            return false
        }
        let clampedBribe = min(courierMarks, max(0, bribeMarks))
        self.packedCase = PackedCase(
            visibleItems: visibleItems,
            hasFalseBottomCard: hasFalseBottomCard,
            hiddenItem: hiddenItem
        )
        self.declaration = Declaration(
            category: declaredCategory,
            declaredCount: visibleItems.count,
            bribeMarks: clampedBribe
        )
        self.isIncompleteSealWarningActive = false
        return true
    }

    // MARK: - 3. Обработка угла шарнира θ, гистерезиса, антидребезга печати и зон щёлочки (Разделы 4.4, 4.5, 5.1, 5.4)

    public mutating func updateHinge(angleDeg: Double, deltaMs: Int) {
        let clamped = min(tuning.maxHingeAngleDeg, max(0.0, angleDeg))
        self.currentAngleDeg = clamped
        self.hingeZone = Self.evaluateZoneWithHysteresis(
            angleDeg: clamped,
            previousZone: hingeZone,
            isCommittedInInspection: isOfficiallyCommitted,
            tuning: tuning
        )

        switch phase {
        case .deal:
            if case .open = hingeZone {
                phase = .packing
            }

        case .packing:
            if clamped <= tuning.sealAngleDeg {
                guard let decl = declaration,
                      !packedCase.visibleItems.isEmpty,
                      decl.declaredCount == packedCase.visibleItems.count else {
                    // Груз не готов: закрытие не запечатывает (Раздел 4.4 п.3)
                    isIncompleteSealWarningActive = true
                    sealHoldAccumulatedMs = 0
                    return
                }
                isIncompleteSealWarningActive = false
                sealHoldAccumulatedMs += max(0, deltaMs)
                if sealHoldAccumulatedMs >= tuning.sealHoldMs {
                    phase = .sealing
                }
            } else {
                sealHoldAccumulatedMs = 0
                if clamped > tuning.postCommitLockAngleDeg {
                    isIncompleteSealWarningActive = false
                }
            }

        case .sealing:
            // Переход из SEALING в NEGOTIATION после постановки штампа
            if clamped <= tuning.sealAngleDeg {
                phase = .negotiation
            }

        case .negotiation, .decision, .inspection:
            if clamped >= tuning.commitAngleDeg {
                // Распахнуть ≥ 25° значит официально вскрыть (Раздел 4.4 п.5, 4.5)
                phase = .inspection
                isOfficiallyCommitted = true
                hingeZone = clamped >= tuning.openAngleDeg ? .open : .committed
            } else if case .slit = hingeZone {
                phase = .inspection
                handleSlitEntryTokenChargeIfNeeded()
            }

        case .pass, .resolution, .roundEnd:
            break
        }
    }

    private mutating func handleSlitEntryTokenChargeIfNeeded() {
        guard !slitClueTokenChargedThisRound else { return }
        slitClueTokenChargedThisRound = true
        if inspectorClueTokens >= tuning.slitClueCost {
            inspectorClueTokens -= tuning.slitClueCost
            isSlitPermittedThisRound = true
            isNoClueTokensWarningActive = false
        } else {
            isSlitPermittedThisRound = false
            isNoClueTokensWarningActive = true
        }
    }

    /// Расчёт зоны шарнира с гистерезисом hysteresisDeg = 2° и блокировкой отката после commit (Разделы 4.5, 5.1)
    public static func evaluateZoneWithHysteresis(
        angleDeg: Double,
        previousZone: HingeZone,
        isCommittedInInspection: Bool,
        tuning: Tuning = .standard
    ) -> HingeZone {
        let clamped = min(tuning.maxHingeAngleDeg, max(0.0, angleDeg))
        let h = tuning.hysteresisDeg

        // После официального commit закрытие обратно ниже 15° уже не отменяет вскрытие (Раздел 4.5)
        if isCommittedInInspection {
            return clamped >= tuning.openAngleDeg ? .open : .committed
        }

        if clamped >= tuning.openAngleDeg {
            return .open
        }
        if case .open = previousZone, clamped >= tuning.openAngleDeg - h {
            return .open
        }

        if clamped >= tuning.commitAngleDeg {
            return .committed
        }
        if case .committed = previousZone, clamped >= tuning.commitAngleDeg - h {
            return .committed
        }

        if clamped <= tuning.sealAngleDeg {
            return .closed
        }
        if case .closed = previousZone, clamped <= tuning.sealAngleDeg + (h * 0.5) {
            return .closed
        }

        // Под-зоны SLIT (3° < θ < 25°) с гистерезисом между уровнями 1, 2 и 3
        if clamped < tuning.slitLevel1MaxAngleDeg {
            if case .slit(.level2) = previousZone, clamped >= tuning.slitLevel1MaxAngleDeg - (h * 0.5) {
                return .slit(.level2)
            }
            return .slit(.level1)
        }

        if clamped < tuning.slitLevel2MaxAngleDeg {
            if case .slit(.level3) = previousZone, clamped >= tuning.slitLevel2MaxAngleDeg - (h * 0.5) {
                return .slit(.level3)
            }
            return .slit(.level2)
        }

        return .slit(.level3)
    }

    // MARK: - 4. Решения Инспектора и проверка двойного дна (Разделы 4.4, 4.5, 4.6)

    public mutating func advanceNegotiationToDecision() {
        guard phase == .negotiation else { return }
        phase = .decision
    }

    /// Списание 1 жетона за «Рентген» (возвращается, если лицо не найдено — Раздел 7.4)
    public mutating func spendTokenForXray() -> Bool {
        guard phase == .negotiation || phase == .decision else { return false }
        guard inspectorClueTokens >= tuning.xrayClueCost else { return false }
        inspectorClueTokens -= tuning.xrayClueCost
        return true
    }

    public mutating func refundXrayTokenDueToNoFace() {
        inspectorClueTokens = min(tuning.maxClueTokens, inspectorClueTokens + tuning.xrayClueCost)
    }

    public mutating func inspectorDecidePass(acceptBribe: Bool) -> RoundResolutionSummary? {
        guard phase == .negotiation || phase == .decision || (phase == .inspection && !isOfficiallyCommitted) else {
            return nil
        }
        guard let decl = declaration else { return nil }
        let engine = ResolutionEngine(tuning: tuning)
        let summary = engine.resolvePass(
            packedCase: packedCase,
            declaration: decl,
            bribeAccepted: acceptBribe && decl.bribeMarks > 0,
            courierMarks: courierMarks,
            inspectorMarks: inspectorMarks
        )
        self.courierMarks = summary.courierFinalMarks
        self.inspectorMarks = summary.inspectorFinalMarks
        self.resolutionSummary = summary
        self.phase = .pass
        return summary
    }

    /// Обработка жеста «перекатить открытый чемодан» (Раздел 4.5):
    /// 2 плавных наклона амплитудой ≥ 25° без резкого встряхивания в течение 6 секунд после commit.
    public mutating func registerGyroTiltSample(
        amplitudeDeg: Double,
        angularVelocityDegPerSec: Double
    ) -> Bool {
        guard phase == .inspection, isOfficiallyCommitted, falseBottomSearchRemainingSec > 0 else {
            return false
        }
        guard amplitudeDeg >= tuning.falseBottomTiltAmplitudeDeg else { return false }
        guard angularVelocityDegPerSec >= tuning.falseBottomMinAngularVelocityDegPerSec &&
              angularVelocityDegPerSec <= tuning.falseBottomMaxAngularVelocityDegPerSec else {
            // Слишком резкое встряхивание не засчитывается
            return false
        }
        falseBottomSmoothTiltCount += 1
        return falseBottomSmoothTiltCount >= tuning.falseBottomRequiredTilts
    }

    public mutating func finalizeCommittedInspection() -> RoundResolutionSummary? {
        guard phase == .inspection, isOfficiallyCommitted, let decl = declaration else {
            return nil
        }
        let fbFound = falseBottomSmoothTiltCount >= tuning.falseBottomRequiredTilts
        let engine = ResolutionEngine(tuning: tuning)
        let summary = engine.resolveInspection(
            packedCase: packedCase,
            declaration: decl,
            falseBottomFound: fbFound,
            courierMarks: courierMarks,
            inspectorMarks: inspectorMarks
        )
        self.courierMarks = summary.courierFinalMarks
        self.inspectorMarks = summary.inspectorFinalMarks
        self.resolutionSummary = summary
        self.phase = .resolution
        return summary
    }

    public mutating func completeRound() {
        guard phase == .pass || phase == .resolution else { return }
        phase = .roundEnd
    }
}
