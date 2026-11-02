import Foundation
import CoreGraphics
#if canImport(CoreImage)
import CoreImage
import CoreImage.CIFilterBuiltins
#endif

/// Данные одной готовой карточки «Протокол вскрытия» (раздел 7.3).
public struct InspectionProtocolCard: Identifiable, Sendable {
    public let id: UUID
    public let roundNumber: Int
    public let smugglerName: String
    public let inspectorName: String
    public let smugglerConsentGranted: Bool
    public let inspectorConsentGranted: Bool
    public let discoveredItemTitlesRu: [String]
    public let falseBottomDiscovered: Bool
    public let stampTextRu: String
    public let coinSettlementSummaryRu: String
    public let renderedCGImage: CGImage?

    public init(
        id: UUID = UUID(),
        roundNumber: Int,
        smugglerName: String,
        inspectorName: String,
        smugglerConsentGranted: Bool,
        inspectorConsentGranted: Bool,
        discoveredItemTitlesRu: [String],
        falseBottomDiscovered: Bool,
        stampTextRu: String,
        coinSettlementSummaryRu: String,
        renderedCGImage: CGImage? = nil
    ) {
        self.id = id
        self.roundNumber = roundNumber
        self.smugglerName = smugglerName
        self.inspectorName = inspectorName
        self.smugglerConsentGranted = smugglerConsentGranted
        self.inspectorConsentGranted = inspectorConsentGranted
        self.discoveredItemTitlesRu = discoveredItemTitlesRu
        self.falseBottomDiscovered = falseBottomDiscovered
        self.stampTextRu = stampTextRu
        self.coinSettlementSummaryRu = coinSettlementSummaryRu
        self.renderedCGImage = renderedCGImage
    }
}

/// Композитор карточки «Протокол вскрытия» на `CoreGraphics` + `CoreImage` (раздел 7.3).
/// Накладывает нуар-фильтр с зерном и виньеткой на портреты (либо рисует стилизованный силуэт со штампом «СЕКРЕТНО»,
/// если игрок не дал согласия на фото), список найденных улик, штамп «ВСКРЫТО» и расчёт монет.
public final class ProtocolComposer {
    #if canImport(CoreImage)
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    #endif

    public init() {}

    public func composeProtocolCard(
        roundNumber: Int,
        smugglerName: String,
        inspectorName: String,
        smugglerFrame: BufferedProtocolFrame?,
        inspectorFrame: BufferedProtocolFrame?,
        smugglerConsent: Bool,
        inspectorConsent: Bool,
        packedCase: PackedSuitcase,
        outcome: RoundResolutionOutcome
    ) -> InspectionProtocolCard {
        let itemTitles = packedCase.visibleItems.map(\.titleRu)
            + (outcome.falseBottomDiscovered ? [packedCase.falseBottomItem?.titleRu].compactMap { $0 } : [])

        let stampText = outcome.contrabandFound ? "ВСКРЫТО • КОНФИСКОВАНО" : "ВСКРЫТО • ДОСМОТРЕНО"
        let settlement = "Пассажир: \(outcome.smugglerDeltaCoins >= 0 ? "+" : "")\(outcome.smugglerDeltaCoins) м. | Инспектор: \(outcome.inspectorDeltaCoins >= 0 ? "+" : "")\(outcome.inspectorDeltaCoins) м."

        let cgImage = renderNoirCompositeCGImage(
            smugglerFrame: smugglerConsent ? smugglerFrame?.cgImage : nil,
            inspectorFrame: inspectorConsent ? inspectorFrame?.cgImage : nil,
            smugglerConsent: smugglerConsent,
            inspectorConsent: inspectorConsent,
            contrabandFound: outcome.contrabandFound
        )

        return InspectionProtocolCard(
            roundNumber: roundNumber,
            smugglerName: smugglerName,
            inspectorName: inspectorName,
            smugglerConsentGranted: smugglerConsent,
            inspectorConsentGranted: inspectorConsent,
            discoveredItemTitlesRu: itemTitles,
            falseBottomDiscovered: outcome.falseBottomDiscovered,
            stampTextRu: stampText,
            coinSettlementSummaryRu: settlement,
            renderedCGImage: cgImage
        )
    }

    /// Рендерит композитное изображение 720x480 с нуар-обработкой `CoreImage` (`CIPhotoEffectNoir` + `CIVignette`).
    public func renderNoirCompositeCGImage(
        smugglerFrame: CGImage?,
        inspectorFrame: CGImage?,
        smugglerConsent: Bool,
        inspectorConsent: Bool,
        contrabandFound: Bool
    ) -> CGImage? {
        let width = 720
        let height = 480
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        // Бумажный фон архивного дела КПП «Ласточка»
        ctx.setFillColor(red: 0.89, green: 0.84, blue: 0.73, alpha: 1.0)
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Внутренняя рамка бланка
        ctx.setStrokeColor(red: 0.16, green: 0.13, blue: 0.10, alpha: 0.85)
        ctx.setLineWidth(3.0)
        ctx.stroke(CGRect(x: 16, y: 16, width: width - 32, height: height - 32))

        // Левый портрет (Контрабандист) и правый портрет (Инспектор)
        let leftRect = CGRect(x: 42, y: 120, width: 280, height: 280)
        let rightRect = CGRect(x: 398, y: 120, width: 280, height: 280)

        drawPortraitBox(in: ctx, rect: leftRect, image: smugglerFrame, consentGranted: smugglerConsent)
        drawPortraitBox(in: ctx, rect: rightRect, image: inspectorFrame, consentGranted: inspectorConsent)

        // Диагональная полоса штампа «ВСКРЫТО»
        ctx.saveGState()
        ctx.translateBy(x: CGFloat(width) * 0.5, y: 74)
        ctx.rotate(by: -0.06)
        if contrabandFound {
            ctx.setStrokeColor(red: 0.72, green: 0.14, blue: 0.12, alpha: 0.9)
        } else {
            ctx.setStrokeColor(red: 0.14, green: 0.48, blue: 0.22, alpha: 0.9)
        }
        ctx.setLineWidth(4.0)
        ctx.stroke(CGRect(x: -180, y: -24, width: 360, height: 48))
        ctx.restoreGState()

        guard let baseCG = ctx.makeImage() else { return nil }
        return applyNoirFilterIfAvailable(to: baseCG)
    }

    private func drawPortraitBox(
        in ctx: CGContext,
        rect: CGRect,
        image: CGImage?,
        consentGranted: Bool
    ) {
        ctx.setFillColor(red: 0.14, green: 0.13, blue: 0.12, alpha: 1.0)
        ctx.fill(rect)

        if consentGranted, let img = image {
            ctx.draw(img, in: rect.insetBy(dx: 6, dy: 6))
        } else {
            // Стилизованный силуэт со штампом «СЕКРЕТНО» (раздел 7.4)
            ctx.setFillColor(red: 0.25, green: 0.23, blue: 0.20, alpha: 1.0)
            let head = CGRect(
                x: rect.midX - 42,
                y: rect.midY - 10,
                width: 84,
                height: 96
            )
            ctx.fillEllipse(in: head)

            let shoulders = CGRect(
                x: rect.midX - 88,
                y: rect.minY + 18,
                width: 176,
                height: 92
            )
            ctx.fillEllipse(in: shoulders)

            ctx.setStrokeColor(red: 0.78, green: 0.18, blue: 0.16, alpha: 0.85)
            ctx.setLineWidth(3.0)
            ctx.stroke(rect.insetBy(dx: 28, dy: 105))
        }

        ctx.setStrokeColor(red: 0.78, green: 0.64, blue: 0.35, alpha: 0.9)
        ctx.setLineWidth(2.0)
        ctx.stroke(rect)
    }

    private func applyNoirFilterIfAvailable(to cgImage: CGImage) -> CGImage {
        #if canImport(CoreImage)
        let inputImage = CIImage(cgImage: cgImage)
        let noir = CIFilter.photoEffectNoir()
        noir.inputImage = inputImage
        guard let noirOutput = noir.outputImage else { return cgImage }

        let vignette = CIFilter.vignette()
        vignette.inputImage = noirOutput
        vignette.intensity = 0.85
        vignette.radius = 1.6

        let finalCI = vignette.outputImage ?? noirOutput
        return ciContext.createCGImage(finalCI, from: inputImage.extent) ?? cgImage
        #else
        return cgImage
        #endif
    }
}
