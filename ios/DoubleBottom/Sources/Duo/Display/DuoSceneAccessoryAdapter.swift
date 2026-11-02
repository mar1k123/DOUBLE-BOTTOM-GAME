import Foundation
import SwiftUI
import Core
import Rules
import DuoHinge

/// Адаптер к новым API двух экранов и безопасных зон iOS 27.1 (Раздел 1, 6.1, 6.3).
/// ПРОВЕРИТЬ ПО ДОКУМЕНТАЦИИ APPLE (iOS 27.1 / Xcode 27.1):
/// 1. В iOS 27.1 модификатор `.sceneAccessory` принимает `CameraCaptureAccessory(isEnabled:content:)`,
///    который выводит вспомогательный SwiftUI View на внешний экран (5.4"), пока на внутреннем (7.6")
///    работает активная сцена.
/// 2. Окружение `reservedRegions` (`.division` для сгиба шарнира, `.occlusion` для бокового вертикального Dynamic Island
///    и подэкранной камеры) позволяет сдвинуть важные элементы интерфейса в безопасную зону.
public protocol DuoDualScreenPresenting: Sendable {
    @MainActor func setOuterAccessoryEnabled(_ enabled: Bool)
}

@MainActor
public final class DuoSceneAccessoryCoordinator: ObservableObject, DuoDualScreenPresenting {
    @Published public var isOuterAccessoryEnabled: Bool = true
    @Published public var isHardwareFoldedClosed: Bool = false

    public init() {}

    public func setOuterAccessoryEnabled(_ enabled: Bool) {
        self.isOuterAccessoryEnabled = enabled
    }

    public func handleHingeSample(_ sample: HingeSample, tuning: Tuning = .standard) {
        let angle = sample.angleDegrees ?? (sample.discretePosture == .closed ? 0.0 : 120.0)
        self.isHardwareFoldedClosed = angle <= tuning.sealAngleDeg
    }
}

/// Безопасный контейнер, учитывающий вертикальный Dynamic Island сбоку и линию сгиба iPhone Duo (Раздел 6.3).
public struct DuoSafeAreaContainer<Content: View>: View {
    public enum ScreenTarget {
        case innerLandscape // 7.6" (~890×626 pt, regular width & height)
        case outerPortrait  // 5.4" (~466×678 pt, compact width)
    }

    private let screenTarget: ScreenTarget
    private let tuning: Tuning
    private let content: () -> Content

    public init(
        screenTarget: ScreenTarget,
        tuning: Tuning = .standard,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.screenTarget = screenTarget
        self.tuning = tuning
        self.content = content
    }

    public var body: some View {
        content()
            .padding(
                screenTarget == .outerPortrait ? .leading : .trailing,
                tuning.dynamicIslandSideSafeInsetPt
            )
    }
}
