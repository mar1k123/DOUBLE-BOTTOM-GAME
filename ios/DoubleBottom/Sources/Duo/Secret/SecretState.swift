import Foundation
import Core
import Rules

/// Секретное состояние раунда (Раздел 6.1).
/// Находится в изолированном модуле `DuoSecret`, который НЕ импортируется в `DuoDisplay` / `OuterScene`.
/// Благодаря этому любая попытка передать `SecretState` во внешний экран приводит к ошибке компиляции Swift.
public struct SecretState: Sendable, Codable, Equatable {
    /// Оставшаяся колода раунда/партии
    public var deck: [HandCard]
    /// Текущая закрытая рука Курьера (до 6 карт)
    public var courierHand: [HandCard]
    /// Реальное содержимое чемодана (видимые предметы + скрытый предмет под двойным дном)
    public var packedCase: PackedCase
    /// Сгенерированные с точностью tintAccuracy (0.75) цветовые намёки для Уровня 3 щёлочки
    public var slitLevel3Hints: [SecretTintHint]

    public init(
        deck: [HandCard] = [],
        courierHand: [HandCard] = [],
        packedCase: PackedCase = PackedCase(),
        slitLevel3Hints: [SecretTintHint] = []
    ) {
        self.deck = deck
        self.courierHand = courierHand
        self.packedCase = packedCase
        self.slitLevel3Hints = slitLevel3Hints
    }

    /// Генерирует намёки Уровня 3 щёлочки (18° ≤ θ < 25°) с вероятностью верного ответа tintAccuracy = 0.75.
    public static func generateLevel3Hints(
        for packedCase: PackedCase,
        declaredCategory: CategoryID,
        tuning: Tuning = .standard,
        rng: inout SeededRNG
    ) -> [SecretTintHint] {
        packedCase.visibleItems.map { item in
            let isActuallyLegalInDeclared = (!item.isContraband && item.category == declaredCategory)
            let isAccurateRoll = rng.nextUnitDouble() <= tuning.tintAccuracy
            let hintedLegalGreen = isAccurateRoll ? isActuallyLegalInDeclared : !isActuallyLegalInDeclared
            return SecretTintHint(
                silhouette: item.silhouette,
                hintedLegalGreen: hintedLegalGreen
            )
        }
    }
}

public struct SecretTintHint: Sendable, Codable, Equatable {
    public let silhouette: SilhouetteKind
    public let hintedLegalGreen: Bool

    public init(silhouette: SilhouetteKind, hintedLegalGreen: Bool) {
        self.silhouette = silhouette
        self.hintedLegalGreen = hintedLegalGreen
    }
}
