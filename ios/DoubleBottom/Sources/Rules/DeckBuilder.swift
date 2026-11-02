import Foundation
import Core

/// Детерминированный генератор псевдослучайных чисел (SplitMix64) с фиксированным seed (Раздел 11).
/// Гарантирует 100% воспроизводимость раздач, намёков щёлочки и симуляций баланса.
public struct SeededRNG: RandomNumberGenerator, Sendable, Codable, Equatable {
    private var state: UInt64

    public init(seed: UInt64 = 1964_11_01) {
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// Равномерное число с плавающей точкой в полуинтервале [0.0, 1.0)
    public mutating func nextUnitDouble() -> Double {
        let upper53 = next() >> 11
        return Double(upper53) / Double(1 << 53)
    }

    /// Случайное целое в диапазоне [0, upperBound)
    public mutating func nextInt(upperBound: Int) -> Int {
        guard upperBound > 1 else { return 0 }
        return Int(next() % UInt64(upperBound))
    }

    /// Детерминированный UUID на основе текущего состояния ГСЧ
    public mutating func nextDeterministicUUID() -> UUID {
        let a = next()
        let b = next()
        var bytes: uuid_t = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        withUnsafeMutableBytes(of: &bytes) { ptr in
            ptr.storeBytes(of: a.bigEndian, toByteOffset: 0, as: UInt64.self)
            ptr.storeBytes(of: b.bigEndian, toByteOffset: 8, as: UInt64.self)
        }
        return UUID(uuid: bytes)
    }
}

public enum DeckBuilder {

    /// Стартовая спецификация колоды из Раздела 4.2 («До балансировки»)
    public static let initialSpec = DeckSpecification(
        version: "1.0.0-initial",
        checkpointName: "КПП «Ласточка» (Альтавия — Нордмарк)",
        categories: [
            CategoryDefinition(id: .oranges, name: "Апельсины", nameEn: "Oranges", legal: true),
            CategoryDefinition(id: .cheese,  name: "Сыр",       nameEn: "Cheese",  legal: true),
            CategoryDefinition(id: .watches, name: "Часы",      nameEn: "Watches", legal: true),
            CategoryDefinition(id: .wine,    name: "Вино",      nameEn: "Wine",    legal: true)
        ],
        items: [
            ItemDefinition(id: "orange",    name: "Апельсины из Соланы",               nameEn: "Solana Oranges",        category: .oranges, value: 2,  fine: 2, weight: 1, count: 16, silhouetteSize: .smallRound),
            ItemDefinition(id: "cheese",    name: "Нордмаркский выдержанный сыр",      nameEn: "Nordmark Aged Cheese",  category: .cheese,  value: 3,  fine: 3, weight: 2, count: 12, silhouetteSize: .mediumWedge),
            ItemDefinition(id: "watch",     name: "Латунный хронометр",                nameEn: "Brass Chronometer",     category: .watches, value: 5,  fine: 4, weight: 1, count: 8,  silhouetteSize: .smallFlat),
            ItemDefinition(id: "wine",      name: "Рубиновое вино долины Крейг",       nameEn: "Craig Valley Ruby Wine",category: .wine,    value: 4,  fine: 3, weight: 3, count: 10, silhouetteSize: .tallBottle),
            ItemDefinition(id: "microfilm", name: "Микроплёнка в латунной катушке",    nameEn: "Microfilm Spool",       category: nil,      value: 7,  fine: 6, weight: 1, count: 6,  silhouetteSize: .smallSpool),
            ItemDefinition(id: "radio",     name: "Ламповый коротковолновый приёмник", nameEn: "Shortwave Tube Radio",  category: nil,      value: 8,  fine: 6, weight: 2, count: 6,  silhouetteSize: .mediumBox),
            ItemDefinition(id: "gold",      name: "Слиток банковского золота",         nameEn: "Bank Gold Bullion",     category: nil,      value: 10, fine: 8, weight: 3, count: 4,  silhouetteSize: .heavyBar),
            ItemDefinition(id: "antique",   name: "Антикварная амфора Альтавии",       nameEn: "Altavian Amphora",      category: nil,      value: 12, fine: 9, weight: 2, count: 3,  silhouetteSize: .tallVase)
        ],
        specials: [
            SpecialCardDefinition(id: .falseBottom, name: "Двойное дно", nameEn: "False Bottom", count: 2)
        ]
    )

    /// Сбалансированная спецификация колоды («После балансировки» по итогам 10 000 симуляций Раздела 12)
    public static let balancedSpec = DeckSpecification(
        version: "1.1.0-balanced",
        checkpointName: "КПП «Ласточка» (Альтавия — Нордмарк)",
        categories: initialSpec.categories,
        items: [
            ItemDefinition(id: "orange",    name: "Апельсины из Соланы",               nameEn: "Solana Oranges",        category: .oranges, value: 3,  fine: 2, weight: 1, count: 16, silhouetteSize: .smallRound),
            ItemDefinition(id: "cheese",    name: "Нордмаркский выдержанный сыр",      nameEn: "Nordmark Aged Cheese",  category: .cheese,  value: 4,  fine: 3, weight: 2, count: 12, silhouetteSize: .mediumWedge),
            ItemDefinition(id: "watch",     name: "Латунный хронометр",                nameEn: "Brass Chronometer",     category: .watches, value: 5,  fine: 4, weight: 1, count: 8,  silhouetteSize: .smallFlat),
            ItemDefinition(id: "wine",      name: "Рубиновое вино долины Крейг",       nameEn: "Craig Valley Ruby Wine",category: .wine,    value: 5,  fine: 3, weight: 3, count: 10, silhouetteSize: .tallBottle),
            ItemDefinition(id: "microfilm", name: "Микроплёнка в латунной катушке",    nameEn: "Microfilm Spool",       category: nil,      value: 7,  fine: 7, weight: 1, count: 6,  silhouetteSize: .smallSpool),
            ItemDefinition(id: "radio",     name: "Ламповый коротковолновый приёмник", nameEn: "Shortwave Tube Radio",  category: nil,      value: 8,  fine: 7, weight: 2, count: 6,  silhouetteSize: .mediumBox),
            ItemDefinition(id: "gold",      name: "Слиток банковского золота",         nameEn: "Bank Gold Bullion",     category: nil,      value: 10, fine: 9, weight: 3, count: 4,  silhouetteSize: .heavyBar),
            ItemDefinition(id: "antique",   name: "Антикварная амфора Альтавии",       nameEn: "Altavian Amphora",      category: nil,      value: 11, fine: 10, weight: 2, count: 3, silhouetteSize: .tallVase)
        ],
        specials: initialSpec.specials
    )

    /// Строит и тасует колоду алгоритмом Фишера-Йетса с детерминированным seed.
    public static func buildShuffledDeck(
        from spec: DeckSpecification = balancedSpec,
        rng: inout SeededRNG
    ) -> [HandCard] {
        var cards: [HandCard] = []
        cards.reserveCapacity(67)

        for itemDef in spec.items {
            for _ in 0..<itemDef.count {
                let instance = ItemCardInstance(
                    instanceID: rng.nextDeterministicUUID(),
                    definition: itemDef
                )
                cards.append(.item(instance))
            }
        }

        for specialDef in spec.specials {
            for _ in 0..<specialDef.count {
                cards.append(.special(instanceID: rng.nextDeterministicUUID(), kind: specialDef.id))
            }
        }

        if cards.count > 1 {
            for i in stride(from: cards.count - 1, through: 1, by: -1) {
                let j = rng.nextInt(upperBound: i + 1)
                if i != j {
                    cards.swapAt(i, j)
                }
            }
        }

        return cards
    }

    /// Ожидаемый вес одной единицы заявленной легальной категории (для сравнения на Уровне 1 щёлочки)
    public static func expectedUnitWeight(for category: CategoryID, in spec: DeckSpecification = balancedSpec) -> Int {
        spec.items.first(where: { $0.category == category })?.weight ?? 1
    }
}
