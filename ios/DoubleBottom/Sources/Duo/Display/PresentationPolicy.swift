import Foundation
import Core
import Rules

/// Публичный снимок состояния для внешнего экрана (OuterScene).
/// На уровне типов и модулей НЕ содержит ссылки на SecretState, руку Курьера,
/// реальные предметы в чемодане или скрытый предмет под двойным дном.
public struct PublicProjection: Equatable, Sendable {
    public let roundNumber: Int
    public let totalRounds: Int
    public let phase: RoundPhase
    public let hingeZone: HingeZone
    public let courierName: String
    public let inspectorName: String
    public let courierMarks: Int
    public let inspectorMarks: Int
    public let inspectorClueTokens: Int
    public let courierPassport: PassportPortraitSpec
    public let courierCountry: CountryAllegiance
    public let courierStamps: [PassportStampRecord]
    public let declaration: Declaration?
    public let remainingSeconds: Int?
    public let isIncompleteSealWarningVisible: Bool
    public let isNoClueTokensWarningVisible: Bool
    public let nervometerReading: NervometerPublicReading?
    public let verdictBanner: InspectionVerdictBanner?
    public let resolutionSummary: RoundResolutionSummary?
    public let captainLineText: String

    public init(
        roundNumber: Int,
        totalRounds: Int,
        phase: RoundPhase,
        hingeZone: HingeZone,
        courierName: String,
        inspectorName: String,
        courierMarks: Int,
        inspectorMarks: Int,
        inspectorClueTokens: Int,
        courierPassport: PassportPortraitSpec,
        courierCountry: CountryAllegiance,
        courierStamps: [PassportStampRecord],
        declaration: Declaration?,
        remainingSeconds: Int?,
        isIncompleteSealWarningVisible: Bool = false,
        isNoClueTokensWarningVisible: Bool = false,
        nervometerReading: NervometerPublicReading? = nil,
        verdictBanner: InspectionVerdictBanner? = nil,
        resolutionSummary: RoundResolutionSummary? = nil,
        captainLineText: String = ""
    ) {
        self.roundNumber = roundNumber
        self.totalRounds = totalRounds
        self.phase = phase
        self.hingeZone = hingeZone
        self.courierName = courierName
        self.inspectorName = inspectorName
        self.courierMarks = courierMarks
        self.inspectorMarks = inspectorMarks
        self.inspectorClueTokens = inspectorClueTokens
        self.courierPassport = courierPassport
        self.courierCountry = courierCountry
        self.courierStamps = courierStamps
        self.declaration = declaration
        self.remainingSeconds = remainingSeconds
        self.isIncompleteSealWarningVisible = isIncompleteSealWarningVisible
        self.isNoClueTokensWarningVisible = isNoClueTokensWarningVisible
        self.nervometerReading = nervometerReading
        self.verdictBanner = verdictBanner
        self.resolutionSummary = resolutionSummary
        self.captainLineText = captainLineText
    }
}

public struct NervometerPublicReading: Equatable, Sendable {
    public let value: Double        // 0...100
    public let uncertainty: Double  // ± полоса неопределённости
    public let usedTremorFallback: Bool

    public init(value: Double, uncertainty: Double, usedTremorFallback: Bool) {
        self.value = value
        self.uncertainty = uncertainty
        self.usedTremorFallback = usedTremorFallback
    }
}

/// Что именно разрешено рисовать на внутреннем экране (InnerScene) в зависимости от фазы и угла θ.
public enum InnerScreenDescriptor: Equatable, Sendable {
    /// Экран физически выключен / чёрный (SEALING closed, NEGOTIATION, DECISION, либо θ < 3°)
    case poweredOff
    /// Ожидание полного открытия шарнира до 100° перед началом упаковки
    case promptOpenSuitcaseToPack
    /// Полный интерфейс упаковки для Курьера (рука, чемодан, двойное дно, декларация, взятка)
    case courierPackingInteractive
    /// Щёлочка запрещена из-за отсутствия жетонов «Улики» (внутренний экран остаётся тёмным)
    case slitBlockedNoTokens
    /// Щёлочка Уровень 1 (3° ≤ θ < 10°): только суммарный вес чемодана W (включая скрытый предмет)
    case slitLevel1WeightOnly(totalWeight: Int, expectedCategoryWeightPerUnit: Int, declaredCount: Int)
    /// Щёлочка Уровень 2 (10° ≤ θ < 18°): вес + силуэты видимых предметов (без названий и без скрытого предмета)
    case slitLevel2Silhouettes(totalWeight: Int, visibleSilhouettes: [SilhouetteKind])
    /// Щёлочка Уровень 3 (18° ≤ θ < 25°): силуэты + цветной намёк (зелёный/красный с точностью 0.75)
    case slitLevel3TintedSilhouettes(totalWeight: Int, hintedSilhouettes: [TintedSilhouetteHint])
    /// Официальное вскрытие (θ ≥ 25°): все видимые предметы + окно 6 с на поиск двойного дна наклонами
    case inspectionCommitted(showFalseBottomTiltPrompt: Bool)
    /// Итоговый подробный отчёт раунда на внутреннем экране
    case roundResolutionReport
}

public struct TintedSilhouetteHint: Equatable, Sendable {
    public let silhouette: SilhouetteKind
    /// true = зелёный (намёк «легально»), false = красный (намёк «контрабанда»)
    public let hintedLegalGreen: Bool

    public init(silhouette: SilhouetteKind, hintedLegalGreen: Bool) {
        self.silhouette = silhouette
        self.hintedLegalGreen = hintedLegalGreen
    }
}

/// Что именно рисуется на внешнем экране (OuterScene) по таблице 6.2.
public enum OuterScreenDescriptor: Equatable, Sendable {
    /// DEAL/PACKING: «Курьер оформляет груз…», паспорт, табло, таймер (или предупреждение «Оформление не закончено, откройте чемодан»)
    case courierPackingStatus(incompleteSealWarning: Bool)
    /// SEALING: печать, штамп «ЗАПЕЧАТАНО»
    case sealedStampAnimation
    /// NEGOTIATION: публичная декларация, взятка, таймер, кнопка «Рентген», нервомер после сканирования
    case negotiationPublicDossier
    /// DECISION: кнопки «ПРОПУСТИТЬ» / «ВСКРЫТЬ» / «ПРИНЯТЬ ВЗЯТКУ»
    case inspectorDecisionControls(hasBribe: Bool, noTokensWarning: Bool)
    /// INSPECTION slit (3–25°): глаз и мигающая надпись «ВАС ПРОВЕРЯЮТ» (или предупреждение о нехватке жетонов)
    case slitBeingWatchedEye(noTokensWarning: Bool)
    /// INSPECTION committed: вердикт для Курьера «ЧИСТО» / «ПОЙМАН»
    case inspectionVerdictBanner(InspectionVerdictBanner)
    /// RESOLUTION / ROUND_END: паспорт со штампом, реплика капитана Веры Лисицыной
    case roundEndPassportAndCaptain
}

public struct DualScreenPresentation: Equatable, Sendable {
    public let inner: InnerScreenDescriptor
    public let outer: OuterScreenDescriptor
    public let publicProjection: PublicProjection
}

/// Чистая функция политики показа (Раздел 6.1, 6.2).
/// Гарантирует отсутствие утечек SecretState на внешний экран в любой фазе и при любом угле шарнира.
public enum PresentationPolicy {
    public static func evaluate(
        projection: PublicProjection,
        activeRole: PlayerRole,
        slitUnlockedWithToken: Bool,
        totalCaseWeight: Int,
        expectedUnitWeight: Int,
        visibleSilhouettes: [SilhouetteKind],
        tintedHints: [TintedSilhouetteHint],
        falseBottomSearchActive: Bool
    ) -> DualScreenPresentation {
        let outer: OuterScreenDescriptor
        let inner: InnerScreenDescriptor

        switch projection.phase {
        case .deal:
            outer = .courierPackingStatus(incompleteSealWarning: false)
            if case .open = projection.hingeZone {
                inner = .courierPackingInteractive
            } else {
                inner = .promptOpenSuitcaseToPack
            }

        case .packing:
            outer = .courierPackingStatus(incompleteSealWarning: projection.isIncompleteSealWarningVisible)
            if case .closed = projection.hingeZone {
                inner = .poweredOff
            } else {
                inner = .courierPackingInteractive
            }

        case .sealing:
            outer = .sealedStampAnimation
            inner = .poweredOff

        case .negotiation:
            outer = .negotiationPublicDossier
            inner = .poweredOff

        case .decision:
            let hasBribe = (projection.declaration?.bribeMarks ?? 0) > 0
            outer = .inspectorDecisionControls(
                hasBribe: hasBribe,
                noTokensWarning: projection.isNoClueTokensWarningVisible
            )
            inner = .poweredOff

        case .pass:
            outer = .roundEndPassportAndCaptain
            inner = .roundResolutionReport

        case .inspection:
            switch projection.hingeZone {
            case .closed:
                let hasBribe = (projection.declaration?.bribeMarks ?? 0) > 0
                outer = .inspectorDecisionControls(
                    hasBribe: hasBribe,
                    noTokensWarning: projection.isNoClueTokensWarningVisible
                )
                inner = .poweredOff

            case .slit(let level):
                outer = .slitBeingWatchedEye(noTokensWarning: !slitUnlockedWithToken)
                guard slitUnlockedWithToken else {
                    inner = .slitBlockedNoTokens
                    break
                }
                let declaredCount = projection.declaration?.declaredCount ?? 0
                switch level {
                case .none:
                    inner = .poweredOff
                case .level1:
                    inner = .slitLevel1WeightOnly(
                        totalWeight: totalCaseWeight,
                        expectedCategoryWeightPerUnit: expectedUnitWeight,
                        declaredCount: declaredCount
                    )
                case .level2:
                    inner = .slitLevel2Silhouettes(
                        totalWeight: totalCaseWeight,
                        visibleSilhouettes: visibleSilhouettes
                    )
                case .level3:
                    inner = .slitLevel3TintedSilhouettes(
                        totalWeight: totalCaseWeight,
                        hintedSilhouettes: tintedHints
                    )
                }

            case .committed, .open:
                let banner = projection.verdictBanner ?? .clean
                outer = .inspectionVerdictBanner(banner)
                inner = .inspectionCommitted(showFalseBottomTiltPrompt: falseBottomSearchActive)
            }

        case .resolution, .roundEnd:
            outer = .roundEndPassportAndCaptain
            inner = .roundResolutionReport
        }

        return DualScreenPresentation(
            inner: inner,
            outer: outer,
            publicProjection: projection
        )
    }
}
