import Foundation

// MARK: - Категории и предметы (Раздел 4.2)

public struct CategoryID: RawRepresentable, Hashable, Codable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: StringLiteralType) { self.rawValue = value }

    public static let oranges: CategoryID = "oranges"
    public static let cheese: CategoryID  = "cheese"
    public static let watches: CategoryID = "watches"
    public static let wine: CategoryID    = "wine"
}

public struct CategoryDefinition: Codable, Hashable, Sendable, Identifiable {
    public let id: CategoryID
    public let name: String
    public let nameEn: String?
    public let legal: Bool

    public init(id: CategoryID, name: String, nameEn: String? = nil, legal: Bool = true) {
        self.id = id
        self.name = name
        self.nameEn = nameEn
        self.legal = legal
    }
}

public enum SilhouetteKind: String, Codable, Hashable, Sendable {
    case smallRound  = "small_round"
    case mediumWedge = "medium_wedge"
    case smallFlat   = "small_flat"
    case tallBottle  = "tall_bottle"
    case smallSpool  = "small_spool"
    case mediumBox   = "medium_box"
    case heavyBar    = "heavy_bar"
    case tallVase    = "tall_vase"
}

public struct ItemDefinition: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let nameEn: String?
    /// nil означает контрабанду (Раздел 4.2)
    public let category: CategoryID?
    public let value: Int
    public let fine: Int
    public let weight: Int
    public let count: Int
    public let silhouetteSize: SilhouetteKind?

    public var isContraband: Bool {
        category == nil
    }

    public init(
        id: String,
        name: String,
        nameEn: String? = nil,
        category: CategoryID?,
        value: Int,
        fine: Int,
        weight: Int,
        count: Int,
        silhouetteSize: SilhouetteKind? = nil
    ) {
        self.id = id
        self.name = name
        self.nameEn = nameEn
        self.category = category
        self.value = value
        self.fine = fine
        self.weight = weight
        self.count = count
        self.silhouetteSize = silhouetteSize
    }
}

public enum SpecialCardID: String, Codable, Hashable, Sendable {
    case falseBottom = "false_bottom"
}

public struct SpecialCardDefinition: Codable, Hashable, Sendable, Identifiable {
    public let id: SpecialCardID
    public let name: String?
    public let nameEn: String?
    public let description: String?
    public let count: Int

    public init(id: SpecialCardID, name: String? = nil, nameEn: String? = nil, description: String? = nil, count: Int) {
        self.id = id
        self.name = name
        self.nameEn = nameEn
        self.description = description
        self.count = count
    }
}

public struct DeckSpecification: Codable, Hashable, Sendable {
    public let version: String?
    public let checkpointName: String?
    public let categories: [CategoryDefinition]
    public let items: [ItemDefinition]
    public let specials: [SpecialCardDefinition]

    public init(
        version: String? = nil,
        checkpointName: String? = nil,
        categories: [CategoryDefinition],
        items: [ItemDefinition],
        specials: [SpecialCardDefinition]
    ) {
        self.version = version
        self.checkpointName = checkpointName
        self.categories = categories
        self.items = items
        self.specials = specials
    }
}

// MARK: - Экземпляр карты в колоде и руке

public struct ItemCardInstance: Hashable, Codable, Sendable, Identifiable {
    public let instanceID: UUID
    public let definitionID: String
    public let name: String
    public let category: CategoryID?
    public let value: Int
    public let fine: Int
    public let weight: Int
    public let silhouette: SilhouetteKind

    public var id: UUID { instanceID }
    public var isContraband: Bool { category == nil }

    public init(
        instanceID: UUID = UUID(),
        definition: ItemDefinition
    ) {
        self.instanceID = instanceID
        self.definitionID = definition.id
        self.name = definition.name
        self.category = definition.category
        self.value = definition.value
        self.fine = definition.fine
        self.weight = definition.weight
        self.silhouette = definition.silhouetteSize ?? .mediumBox
    }
}

public enum HandCard: Hashable, Codable, Sendable, Identifiable {
    case item(ItemCardInstance)
    case special(instanceID: UUID, kind: SpecialCardID)

    public var id: UUID {
        switch self {
        case .item(let card): return card.instanceID
        case .special(let id, _): return id
        }
    }
}

// MARK: - Декларация и Чемодан (Раздел 4.3)

public struct Declaration: Hashable, Codable, Sendable {
    /// Заявленная легальная категория L
    public let category: CategoryID
    /// Заявленное количество видимых предметов n = visibleItems.count
    public let declaredCount: Int
    /// Предложенная взятка Инспектору (0 — без взятки)
    public let bribeMarks: Int

    public init(category: CategoryID, declaredCount: Int, bribeMarks: Int = 0) {
        self.category = category
        self.declaredCount = declaredCount
        self.bribeMarks = max(0, bribeMarks)
    }
}

public struct PackedCase: Hashable, Codable, Sendable {
    /// До maxVisibleSlots (5) видимых предметов
    public var visibleItems: [ItemCardInstance]
    /// Задействована ли карта «Двойное дно»
    public var hasFalseBottomCard: Bool
    /// Скрытый предмет под двойным дном (не входит в n и декларацию)
    public var hiddenItem: ItemCardInstance?

    public init(
        visibleItems: [ItemCardInstance] = [],
        hasFalseBottomCard: Bool = false,
        hiddenItem: ItemCardInstance? = nil
    ) {
        self.visibleItems = visibleItems
        self.hasFalseBottomCard = hasFalseBottomCard
        self.hiddenItem = hiddenItem
    }

    /// Суммарный вес W всех предметов в чемодане, включая скрытый (для Уровня 1 щёлочки, Раздел 4.5)
    public var totalWeightIncludingHidden: Int {
        let visibleW = visibleItems.reduce(0) { $0 + $1.weight }
        let hiddenW = hiddenItem?.weight ?? 0
        return visibleW + hiddenW
    }

    /// Честный ли видимый груз относительно заявленной категории L (Раздел 4.3)
    public func isVisibleCargoHonest(declaredCategory: CategoryID) -> Bool {
        guard !visibleItems.isEmpty else { return false }
        return visibleItems.allSatisfy { $0.category == declaredCategory }
    }
}

// MARK: - Паспорт, Игроки и Роли (Раздел 3, 4.1)

public enum CountryAllegiance: String, Codable, Hashable, Sendable, CaseIterable {
    case altavia  = "altavia"
    case nordmark = "nordmark"
}

public struct PassportPortraitSpec: Codable, Hashable, Sendable {
    /// Силуэт (0..2), шляпа (0..1), шарф (0..1), очки (0..1) -> ≥ 12 комбинаций
    public let combinationIndex: Int
    public let silhouetteIndex: Int
    public let hasHat: Bool
    public let hasScarf: Bool
    public let hasGlasses: Bool

    public init(combinationIndex: Int) {
        let normalized = abs(combinationIndex) % 12
        self.combinationIndex = normalized
        self.silhouetteIndex = normalized % 3
        self.hasHat = (normalized / 3) % 2 == 1
        self.hasScarf = (normalized / 6) % 2 == 1
        self.hasGlasses = normalized % 2 == 1
    }
}

public enum PassportStampKind: String, Codable, Hashable, Sendable {
    case passedClean     = "ПРОПУЩЕНО"
    case bribeAccepted   = "ДОСМОТР ОКОНЧЕН"
    case inspectedHonest = "ПРОВЕРЕНО · ЧИСТО"
    case contrabandFound = "КОНФИСКОВАНО"
}

public struct PassportStampRecord: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public let roundNumber: Int
    public let kind: PassportStampKind
    public let deltaMarks: Int

    public init(id: UUID = UUID(), roundNumber: Int, kind: PassportStampKind, deltaMarks: Int) {
        self.id = id
        self.roundNumber = roundNumber
        self.kind = kind
        self.deltaMarks = deltaMarks
    }
}

public struct PlayerState: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public var name: String
    public var country: CountryAllegiance
    public var portrait: PassportPortraitSpec
    public var marks: Int
    public var clueTokens: Int
    public var timesAsCourier: Int
    public var inspectionsWon: Int
    public var stamps: [PassportStampRecord]
    public var isBot: Bool

    public init(
        id: String,
        name: String,
        country: CountryAllegiance,
        portrait: PassportPortraitSpec,
        marks: Int = 40,
        clueTokens: Int = 3,
        timesAsCourier: Int = 0,
        inspectionsWon: Int = 0,
        stamps: [PassportStampRecord] = [],
        isBot: Bool = false
    ) {
        self.id = id
        self.name = name
        self.country = country
        self.portrait = portrait
        self.marks = marks
        self.clueTokens = clueTokens
        self.timesAsCourier = timesAsCourier
        self.inspectionsWon = inspectionsWon
        self.stamps = stamps
        self.isBot = isBot
    }
}

public enum PlayerRole: String, Codable, Hashable, Sendable {
    case courier   = "courier"
    case inspector = "inspector"
    case spectator = "spectator"
}

// MARK: - Фазы раунда и зоны шарнира (Разделы 4.4, 5.1)

public enum RoundPhase: String, Codable, Hashable, Sendable, CaseIterable {
    case deal        = "DEAL"
    case packing     = "PACKING"
    case sealing     = "SEALING"
    case negotiation = "NEGOTIATION"
    case decision    = "DECISION"
    case pass        = "PASS"
    case inspection  = "INSPECTION"
    case resolution  = "RESOLUTION"
    case roundEnd    = "ROUND_END"
}

public enum SlitPeekLevel: Int, Codable, Hashable, Sendable, Comparable {
    case none   = 0 // θ < 3°
    case level1 = 1 // 3° ≤ θ < 10° («на ощупь» — суммарный вес W)
    case level2 = 2 // 10° ≤ θ < 18° («в щёлку» — силуэты видимых предметов)
    case level3 = 3 // 18° ≤ θ < 25° («на просвет» — цветной намёк с вероятностью tintAccuracy = 0.75)

    public static func < (lhs: SlitPeekLevel, rhs: SlitPeekLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum HingeZone: Hashable, Codable, Sendable {
    case closed                  // θ ≤ 3°
    case slit(SlitPeekLevel)     // 3° < θ < 25°
    case committed               // θ ≥ 25° в фазе INSPECTION (или 25° ≤ θ < 100°)
    case open                    // θ ≥ 100°
}

// MARK: - Вердикт и результат вскрытия (Раздел 4.6)

public enum InspectionVerdictBanner: String, Codable, Hashable, Sendable {
    case clean  = "ЧИСТО"
    case caught = "ПОЙМАН"
}

public struct RoundResolutionSummary: Codable, Hashable, Sendable {
    public let wasInspected: Bool
    public let bribeAccepted: Bool
    public let falseBottomSearchedAndFound: Bool
    public let verdictBanner: InspectionVerdictBanner
    public let passedItemsValue: Int
    public let confiscatedFinesPaid: Int
    public let compensationPaidByInspector: Int
    public let bribeTransferred: Int
    public let courierNetDelta: Int
    public let inspectorNetDelta: Int
    public let courierFinalMarks: Int
    public let inspectorFinalMarks: Int
    public let inspectorWonInspection: Bool
}
