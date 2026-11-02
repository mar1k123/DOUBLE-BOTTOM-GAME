import Foundation
import CoreGraphics
#if canImport(Photos)
import Photos
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Состояние раздельного согласия обоих игроков на создание карточек «Протокол вскрытия» (раздел 7.4).
public struct ProtocolConsentState: Equatable, Sendable {
    public var smugglerPhotoConsentGranted: Bool
    public var inspectorPhotoConsentGranted: Bool

    public init(
        smugglerPhotoConsentGranted: Bool = false,
        inspectorPhotoConsentGranted: Bool = false
    ) {
        self.smugglerPhotoConsentGranted = smugglerPhotoConsentGranted
        self.inspectorPhotoConsentGranted = inspectorPhotoConsentGranted
    }
}

/// Менеджер приватности, жизненного цикла карточек в оперативной памяти и сохранения в `PHPhotoLibrary`
/// только по явному нажатию кнопки «Сохранить в Фото» (раздел 7.4).
@MainActor
public final class ProtocolExportManager: ObservableObject {
    @Published public var consentState = ProtocolConsentState()
    @Published public private(set) var matchProtocolCards: [InspectionProtocolCard] = []
    @Published public private(set) var lastSaveStatusMessageRu: String?

    public init() {}

    public func appendCard(_ card: InspectionProtocolCard) {
        matchProtocolCards.append(card)
    }

    /// Полное удаление всех карточек и кадров из оперативной памяти при выходе из матча.
    public func purgeMatchGalleryFromRAM() {
        matchProtocolCards.removeAll()
        lastSaveStatusMessageRu = nil
    }

    /// Сохраняет выбранную карточку в системную медиатеку «Фото» только по явному действию пользователя.
    public func saveCardToPhotoLibrary(_ card: InspectionProtocolCard) async -> Bool {
        #if canImport(Photos) && canImport(UIKit)
        guard let cgImage = card.renderedCGImage else {
            lastSaveStatusMessageRu = "Не удалось подготовить изображение протокола."
            return false
        }

        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            lastSaveStatusMessageRu = "Доступ к медиатеке «Фото» не предоставлен."
            return false
        }

        let uiImage = UIImage(cgImage: cgImage)
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: uiImage)
            }
            lastSaveStatusMessageRu = "Протокол раунда №\(card.roundNumber) сохранён в «Фото»."
            return true
        } catch {
            lastSaveStatusMessageRu = "Ошибка сохранения в «Фото»: \(error.localizedDescription)"
            return false
        }
        #else
        lastSaveStatusMessageRu = "Сохранение в медиатеку доступно на устройстве iOS."
        return false
        #endif
    }
}
