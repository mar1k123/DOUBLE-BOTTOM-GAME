import Foundation
import Core

/// Параметры ИИ-бота (Раздел 10 и 12).
public struct BotPolicy: Sendable, Codable, Equatable {
    public let id: String
    public let displayName: String
    public let riskAppetite: Double          // 0.0 (всегда честный) ... 1.0 (всегда контрабанда)
    public let bluffRate: Double             // частота провокационного блефа или использования двойного дна
    public let baseInspectRate: Double       // базовая склонность вскрывать (0.0 — никогда, 1.0 — всегда)
    public let clueUsageSkill: Double        // вероятность грамотно использовать щёлочку / рентген при наличии жетонов
    public let bribeAcceptanceReadiness: Double // готовность принять выгодную взятку

    public init(
        id: String,
        displayName: String,
        riskAppetite: Double,
        bluffRate: Double,
        baseInspectRate: Double,
        clueUsageSkill: Double,
        bribeAcceptanceReadiness: Double
    ) {
        self.id = id
        self.displayName = displayName
        self.riskAppetite = riskAppetite
        self.bluffRate = bluffRate
        self.baseInspectRate = baseInspectRate
        self.clueUsageSkill = clueUsageSkill
        self.bribeAcceptanceReadiness = bribeAcceptanceReadiness
    }

    // MARK: - 4 эталонные политики Курьера из Раздела 12
    public static let courierAlwaysHonest = BotPolicy(
        id: "always_honest",
        displayName: "Всегда честный",
        riskAppetite: 0.0,
        bluffRate: 0.0,
        baseInspectRate: 0.45,
        clueUsageSkill: 0.7,
        bribeAcceptanceReadiness: 0.4
    )

    public static let courierAlwaysSmuggler = BotPolicy(
        id: "always_smuggler",
        displayName: "Всегда контрабандист",
        riskAppetite: 1.0,
        bluffRate: 0.9,
        baseInspectRate: 0.45,
        clueUsageSkill: 0.7,
        bribeAcceptanceReadiness: 0.4
    )

    public static let courierMixedBluffer = BotPolicy(
        id: "mixed_bluffer",
        displayName: "Смешанная (блеф + дно)",
        riskAppetite: 0.48,
        bluffRate: 0.45,
        baseInspectRate: 0.45,
        clueUsageSkill: 0.8,
        bribeAcceptanceReadiness: 0.5
    )

    public static let courierBriber = BotPolicy(
        id: "briber",
        displayName: "Взяточник",
        riskAppetite: 0.68,
        bluffRate: 0.60,
        baseInspectRate: 0.45,
        clueUsageSkill: 0.7,
        bribeAcceptanceReadiness: 0.75
    )

    // MARK: - 4 эталонные политики Инспектора из Раздела 12
    public static let inspectorAlwaysInspect = BotPolicy(
        id: "always_inspect",
        displayName: "Всегда вскрывать",
        riskAppetite: 0.48,
        bluffRate: 0.4,
        baseInspectRate: 1.0,
        clueUsageSkill: 0.0,
        bribeAcceptanceReadiness: 0.0
    )

    public static let inspectorNeverInspect = BotPolicy(
        id: "never_inspect",
        displayName: "Никогда не вскрывать",
        riskAppetite: 0.48,
        bluffRate: 0.4,
        baseInspectRate: 0.0,
        clueUsageSkill: 0.0,
        bribeAcceptanceReadiness: 1.0
    )

    public static let inspectorNervometerReader = BotPolicy(
        id: "nervometer_reader",
        displayName: "По нервомеру",
        riskAppetite: 0.48,
        bluffRate: 0.4,
        baseInspectRate: 0.35,
        clueUsageSkill: 0.95,
        bribeAcceptanceReadiness: 0.35
    )

    public static let inspectorMixedDetective = BotPolicy(
        id: "mixed_detective",
        displayName: "Смешанный детектив",
        riskAppetite: 0.48,
        bluffRate: 0.45,
        baseInspectRate: 0.42,
        clueUsageSkill: 0.82,
        bribeAcceptanceReadiness: 0.48
    )

    /// Профиль Капитана Веры Лисицыной для солитёрного режима «Против капитана» (Раздел 10)
    public static let captainVeraSoloBot = BotPolicy(
        id: "captain_vera",
        displayName: "Капитан Вера Лисицына",
        riskAppetite: 0.52,
        bluffRate: 0.55,
        baseInspectRate: 0.44,
        clueUsageSkill: 0.88,
        bribeAcceptanceReadiness: 0.42
    )
}
