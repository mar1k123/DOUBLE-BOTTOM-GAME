import Foundation

/// Единый реестр числовых констант геймдизайна, физики шарнира, нервомера и теплового бюджета.
/// Никаких магических чисел в логике правил, рендере или UI.
public struct Tuning: Sendable, Codable, Equatable {

    // MARK: - 1. Участники, партия и стартовая экономика (Раздел 4.1)
    public var minPlayers: Int = 2
    public var maxPlayers: Int = 6
    public var couriersPerPlayer: Int = 2
    public var startingMarks: Int = 40
    public var startingClueTokens: Int = 3
    public var maxClueTokens: Int = 5
    public var inspectorRoundClueBonus: Int = 1

    // MARK: - 2. Рука, чемодан и декларация (Раздел 4.3)
    public var handSize: Int = 6
    public var maxMulliganCards: Int = 2
    public var maxVisibleSlots: Int = 5
    public var maxHiddenSlotsWithFalseBottom: Int = 1
    public var compensationPerItem: Int = 2

    // MARK: - 3. Таймеры фаз раунда (Раздел 4.4)
    public var packingSeconds: TimeInterval = 75.0
    public var negotiationSeconds: TimeInterval = 45.0
    public var falseBottomSearchSeconds: TimeInterval = 6.0
    public var demoRoundSeconds: TimeInterval = 40.0

    // MARK: - 4. Зоны шарнира, печать и щёлочка (Разделы 4.4, 4.5, 5.1)
    /// Угол запечатывания и минимальный угол щёлочки (θ ≤ 3° — закрыт)
    public var sealAngleDeg: Double = 3.0
    public var peekMinAngleDeg: Double = 3.0
    /// Верхняя граница Уровня 1 («на ощупь» — суммарный вес W): 3° ≤ θ < 10°
    public var slitLevel1MaxAngleDeg: Double = 10.0
    /// Верхняя граница Уровня 2 («в щёлку» — силуэты предметов): 10° ≤ θ < 18°
    public var slitLevel2MaxAngleDeg: Double = 18.0
    /// Верхняя граница Уровня 3 («на просвет» — цветной намёк): 18° ≤ θ < 25°
    public var commitAngleDeg: Double = 25.0
    /// Порог, ниже которого закрытие после commit уже не отменяет вскрытие (и для гистерезиса)
    public var postCommitLockAngleDeg: Double = 15.0
    /// Полное раскрытие чемодана для PACKING и RESOLUTION
    public var openAngleDeg: Double = 100.0
    /// Полностью разложенный экран плашмя
    public var maxHingeAngleDeg: Double = 180.0
    /// Гистерезис переключения зон шарнира
    public var hysteresisDeg: Double = 2.0
    /// Время удержания угла для запечатывания и защиты от дребезга (250 мс)
    public var sealHoldMs: Int = 250
    /// Шаг угла в SLIT для тактильного «тика» Core Haptics
    public var slitHapticTickStepDeg: Double = 5.0
    /// Стоимость заглядывания в щёлочку (3°–25°) в жетонах «Улики»
    public var slitClueCost: Int = 1
    /// Вероятность верного цветного намёка на Уровне 3 щёлочки (18°–25°)
    public var tintAccuracy: Double = 0.75

    // MARK: - 5. Поиск двойного дна (гироскоп / акселерометр, Раздел 4.5)
    /// Требуемое число плавных наклонов влево-вправо после commit
    public var falseBottomRequiredTilts: Int = 2
    /// Минимальная амплитуда наклона (градусы)
    public var falseBottomTiltAmplitudeDeg: Double = 25.0
    /// Мягкий верхний порог угловой скорости (град/с), отсекающий резкую тряску
    public var falseBottomMaxAngularVelocityDegPerSec: Double = 140.0
    /// Минимальная угловая скорость для засчитывания плавного переката (град/с)
    public var falseBottomMinAngularVelocityDegPerSec: Double = 18.0

    // MARK: - 6. Нервомер и Рентген (Раздел 7)
    public var xrayClueCost: Int = 1
    public var calibrationSeconds: TimeInterval = 6.0
    public var scanSeconds: TimeInterval = 5.0
    public var nervometerBaseValue: Double = 50.0
    public var nervometerZScaleK: Double = 18.5
    public var nervometerEmaAlpha: Double = 0.25
    public var nervometerNoiseAmplitude: Double = 8.0
    public var nervometerUncertaintyBandWidth: Double = 12.0
    public var visionNominalFps: Int = 14
    public var visionFairThermalFps: Int = 9

    // MARK: - 7. Протокол вскрытия (Раздел 8)
    public var preCommitRingBufferSeconds: TimeInterval = 1.5
    public var postCommitCaptureWindowSeconds: TimeInterval = 3.0

    // MARK: - 8. Дисплеи и производительность (Разделы 1, 6.3, 13)
    public var logicTickHz: Int = 60
    public var innerTargetFps: Int = 120
    public var outerTargetFps: Int = 60
    /// Расчётные размеры экранов iPhone Duo в поинтах (для DuoSimulatorView)
    public var innerScreenWidthPt: Double = 890.0
    public var innerScreenHeightPt: Double = 626.0
    public var outerScreenWidthPt: Double = 466.0
    public var outerScreenHeightPt: Double = 678.0
    /// Безопасный отступ под вертикальный Dynamic Island сбоку (pt)
    public var dynamicIslandSideSafeInsetPt: Double = 34.0

    public static let standard = Tuning()

    /// Сбалансированный пресет после прогона BalanceSimulator (10 000 партий на пару политик)
    public static let balanced = Tuning(
        compensationPerItem: 2,
        tintAccuracy: 0.75
    )

    public init(
        minPlayers: Int = 2,
        maxPlayers: Int = 6,
        couriersPerPlayer: Int = 2,
        startingMarks: Int = 40,
        startingClueTokens: Int = 3,
        maxClueTokens: Int = 5,
        inspectorRoundClueBonus: Int = 1,
        handSize: Int = 6,
        maxMulliganCards: Int = 2,
        maxVisibleSlots: Int = 5,
        maxHiddenSlotsWithFalseBottom: Int = 1,
        compensationPerItem: Int = 2,
        packingSeconds: TimeInterval = 75.0,
        negotiationSeconds: TimeInterval = 45.0,
        falseBottomSearchSeconds: TimeInterval = 6.0,
        demoRoundSeconds: TimeInterval = 40.0,
        sealAngleDeg: Double = 3.0,
        peekMinAngleDeg: Double = 3.0,
        slitLevel1MaxAngleDeg: Double = 10.0,
        slitLevel2MaxAngleDeg: Double = 18.0,
        commitAngleDeg: Double = 25.0,
        postCommitLockAngleDeg: Double = 15.0,
        openAngleDeg: Double = 100.0,
        maxHingeAngleDeg: Double = 180.0,
        hysteresisDeg: Double = 2.0,
        sealHoldMs: Int = 250,
        slitHapticTickStepDeg: Double = 5.0,
        slitClueCost: Int = 1,
        tintAccuracy: Double = 0.75
    ) {
        self.minPlayers = minPlayers
        self.maxPlayers = maxPlayers
        self.couriersPerPlayer = couriersPerPlayer
        self.startingMarks = startingMarks
        self.startingClueTokens = startingClueTokens
        self.maxClueTokens = maxClueTokens
        self.inspectorRoundClueBonus = inspectorRoundClueBonus
        self.handSize = handSize
        self.maxMulliganCards = maxMulliganCards
        self.maxVisibleSlots = maxVisibleSlots
        self.maxHiddenSlotsWithFalseBottom = maxHiddenSlotsWithFalseBottom
        self.compensationPerItem = compensationPerItem
        self.packingSeconds = packingSeconds
        self.negotiationSeconds = negotiationSeconds
        self.falseBottomSearchSeconds = falseBottomSearchSeconds
        self.demoRoundSeconds = demoRoundSeconds
        self.sealAngleDeg = sealAngleDeg
        self.peekMinAngleDeg = peekMinAngleDeg
        self.slitLevel1MaxAngleDeg = slitLevel1MaxAngleDeg
        self.slitLevel2MaxAngleDeg = slitLevel2MaxAngleDeg
        self.commitAngleDeg = commitAngleDeg
        self.postCommitLockAngleDeg = postCommitLockAngleDeg
        self.openAngleDeg = openAngleDeg
        self.maxHingeAngleDeg = maxHingeAngleDeg
        self.hysteresisDeg = hysteresisDeg
        self.sealHoldMs = sealHoldMs
        self.slitHapticTickStepDeg = slitHapticTickStepDeg
        self.slitClueCost = slitClueCost
        self.tintAccuracy = tintAccuracy
    }
}
