import SwiftUI

/// Настройки доступности и адаптации интерфейса (раздел 10.4):
/// - Полная поддержка `VoiceOver` с раздельными подсказками для внешнего (`OuterScene`) и внутреннего (`InnerScene`) экранов.
/// - Режим для дальтонизма: каждый цветовой сигнал (зелёный/красный намёк в щели 3-го уровня, штампы, категории)
///   дублируется геометрическим паттерном (точки / диагональная штриховка) и иконкой (`✓` / `⚠️`).
/// - Уважение `accessibilityReduceMotion` (замена пружинных и пульсирующих анимаций на плавный кроссфейд).
/// - Минимальный размер интерактивных целей `44x44 pt`.
public struct AccessibilitySettings: Equatable, Sendable {
    public var colorblindPatternsEnabled: Bool
    public var voiceOverHintsEnabled: Bool
    public var reduceMotionOverride: Bool

    public init(
        colorblindPatternsEnabled: Bool = true,
        voiceOverHintsEnabled: Bool = true,
        reduceMotionOverride: Bool = false
    ) {
        self.colorblindPatternsEnabled = colorblindPatternsEnabled
        self.voiceOverHintsEnabled = voiceOverHintsEnabled
        self.reduceMotionOverride = reduceMotionOverride
    }
}

/// Модификатор гарантированного минимального тач-таргета `44x44 pt` (Apple HIG) с VoiceOver-описанием.
public struct AccessibleCustomsControlModifier: ViewModifier {
    public let labelRu: String
    public let hintRu: String

    public func body(content: Content) -> some View {
        content
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .accessibilityLabel(Text(labelRu))
            .accessibilityHint(Text(hintRu))
    }
}

extension View {
    public func accessibleCustomsControl(labelRu: String, hintRu: String) -> some View {
        modifier(AccessibleCustomsControlModifier(labelRu: labelRu, hintRu: hintRu))
    }
}
