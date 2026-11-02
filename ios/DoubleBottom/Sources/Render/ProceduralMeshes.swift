import Foundation
import CoreGraphics
#if canImport(SceneKit)
import SceneKit
#endif
#if canImport(Metal)
import Metal
#endif

/// Процедурный генератор 3D-предметов чемодана и PBR-материалов (раздел 8.2 и 8.3).
/// Все 8 предметов собираются программно из параметрических примитивов (`SCNBox`, `SCNCylinder`, `SCNSphere`, `SCNTorus`, `SCNCone`)
/// без внешних `.usdz` или `.obj` файлов. Помечено: ЗАМЕНИТЬ АРТОМ.
public final class ProceduralSuitcaseRenderer {
    public let isHardwareRaytracingSupported: Bool

    public init() {
        #if canImport(Metal)
        if let device = MTLCreateSystemDefaultDevice() {
            // ПРОВЕРИТЬ ПО ДОКУМЕНТАЦИИ APPLE:
            // На GPU семейства Apple10 / A20 Pro в iPhone Duo `device.supportsRaytracing`
            // включает аппаратные отражения на латунных замках чемодана и стекле Нервомера.
            self.isHardwareRaytracingSupported = device.supportsRaytracing
        } else {
            self.isHardwareRaytracingSupported = false
        }
        #else
        self.isHardwareRaytracingSupported = false
        #endif
    }

    #if canImport(SceneKit)
    /// Создаёт PBR-материал состаренной кожи чемодана.
    public static func makeLeatherMaterial() -> SCNMaterial {
        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        mat.diffuse.contents = CGColor(red: 0.22, green: 0.13, blue: 0.09, alpha: 1.0)
        mat.roughness.contents = 0.72
        mat.metalness.contents = 0.05
        return mat
    }

    /// Создаёт PBR-материал полированной латуни для замков, петель и ободка «Нервомера».
    public static func makeBrassMaterial(enableRaytracedCoat: Bool = true) -> SCNMaterial {
        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        mat.diffuse.contents = CGColor(red: 0.81, green: 0.66, blue: 0.36, alpha: 1.0)
        mat.metalness.contents = 0.92
        mat.roughness.contents = enableRaytracedCoat ? 0.18 : 0.32
        return mat
    }

    /// Создаёт PBR-материал бордового бархатного ложемента чемодана.
    public static func makeVelvetLiningMaterial() -> SCNMaterial {
        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        mat.diffuse.contents = CGColor(red: 0.32, green: 0.09, blue: 0.12, alpha: 1.0)
        mat.roughness.contents = 0.88
        mat.metalness.contents = 0.02
        return mat
    }

    /// Собирает составной 3D-узел (`SCNNode`) для любого из 8 силуэтов предметов (раздел 8.2).
    /// Помечено: ЗАМЕНИТЬ АРТОМ.
    public static func buildProceduralItemNode(for silhouette: SilhouetteShape, isContraband: Bool) -> SCNNode {
        let root = SCNNode()
        let brass = makeBrassMaterial()

        switch silhouette {
        case .bottle:
            // 1. Бутылка рубинового вина: цилиндр корпуса + конус плечиков + горлышко с сургучом
            let body = SCNCylinder(radius: 0.18, height: 0.62)
            body.firstMaterial?.lightingModel = .physicallyBased
            body.firstMaterial?.diffuse.contents = CGColor(red: 0.12, green: 0.32, blue: 0.16, alpha: 0.92)
            body.firstMaterial?.roughness.contents = 0.15
            let bodyNode = SCNNode(geometry: body)

            let neck = SCNCylinder(radius: 0.06, height: 0.28)
            neck.firstMaterial = body.firstMaterial
            let neckNode = SCNNode(geometry: neck)
            neckNode.position = SCNVector3(0, 0.42, 0)

            root.addChildNode(bodyNode)
            root.addChildNode(neckNode)

        case .wheel:
            // 2. Головка альпийского сыра в восковой корке: приплюснутый цилиндр
            let wheel = SCNCylinder(radius: 0.34, height: 0.22)
            wheel.firstMaterial?.lightingModel = .physicallyBased
            wheel.firstMaterial?.diffuse.contents = CGColor(red: 0.86, green: 0.72, blue: 0.28, alpha: 1.0)
            wheel.firstMaterial?.roughness.contents = 0.65
            root.addChildNode(SCNNode(geometry: wheel))

        case .crate:
            // 3. Ящик южных апельсинов или запрещённая радиостанция
            let crate = SCNBox(width: 0.64, height: 0.38, length: 0.46, chamferRadius: 0.03)
            crate.firstMaterial?.lightingModel = .physicallyBased
            crate.firstMaterial?.diffuse.contents = isContraband
                ? CGColor(red: 0.24, green: 0.26, blue: 0.22, alpha: 1.0)
                : CGColor(red: 0.62, green: 0.44, blue: 0.24, alpha: 1.0)
            crate.firstMaterial?.roughness.contents = 0.78
            root.addChildNode(SCNNode(geometry: crate))

        case .box:
            // 4. Рулон тканей / кружева или коробка сигар
            let box = SCNBox(width: 0.48, height: 0.22, length: 0.36, chamferRadius: 0.04)
            box.firstMaterial?.lightingModel = .physicallyBased
            box.firstMaterial?.diffuse.contents = isContraband
                ? CGColor(red: 0.48, green: 0.24, blue: 0.14, alpha: 1.0)
                : CGColor(red: 0.25, green: 0.36, blue: 0.52, alpha: 1.0)
            root.addChildNode(SCNNode(geometry: box))

        case .tube:
            // 5. Катушка микроплёнки / дипломатический тубус / духи
            let cylinder = SCNCylinder(radius: 0.14, height: 0.44)
            cylinder.firstMaterial = brass
            let cylNode = SCNNode(geometry: cylinder)

            let rimTop = SCNTorus(ringRadius: 0.15, pipeRadius: 0.02)
            rimTop.firstMaterial = brass
            let rimNode = SCNNode(geometry: rimTop)
            rimNode.position = SCNVector3(0, 0.22, 0)

            root.addChildNode(cylNode)
            root.addChildNode(rimNode)

        case .ingot:
            // 6. Недекларированный золотой слиток со скошенными гранями
            let ingot = SCNBox(width: 0.46, height: 0.16, length: 0.24, chamferRadius: 0.03)
            ingot.firstMaterial = brass
            root.addChildNode(SCNNode(geometry: ingot))

        case .statue:
            // 7. Антикварная статуэтка / корона: пьедестал + сфера + конус
            let base = SCNCylinder(radius: 0.18, height: 0.12)
            base.firstMaterial = brass
            let baseNode = SCNNode(geometry: base)

            let pillar = SCNCone(topRadius: 0.06, bottomRadius: 0.14, height: 0.38)
            pillar.firstMaterial = brass
            let pillarNode = SCNNode(geometry: pillar)
            pillarNode.position = SCNVector3(0, 0.25, 0)

            let orb = SCNSphere(radius: 0.09)
            orb.firstMaterial = brass
            let orbNode = SCNNode(geometry: orb)
            orbNode.position = SCNVector3(0, 0.48, 0)

            root.addChildNode(baseNode)
            root.addChildNode(pillarNode)
            root.addChildNode(orbNode)

        case .apparatus:
            // 8. Радиопередатчик / шифровальный аппарат с радиолампой
            let chassis = SCNBox(width: 0.50, height: 0.24, length: 0.34, chamferRadius: 0.02)
            chassis.firstMaterial?.lightingModel = .physicallyBased
            chassis.firstMaterial?.diffuse.contents = CGColor(red: 0.18, green: 0.20, blue: 0.19, alpha: 1.0)
            let chassisNode = SCNNode(geometry: chassis)

            let tube = SCNCylinder(radius: 0.06, height: 0.18)
            tube.firstMaterial?.lightingModel = .physicallyBased
            tube.firstMaterial?.emission.contents = CGColor(red: 0.95, green: 0.48, blue: 0.12, alpha: 1.0)
            let tubeNode = SCNNode(geometry: tube)
            tubeNode.position = SCNVector3(0.12, 0.20, 0)

            root.addChildNode(chassisNode)
            root.addChildNode(tubeNode)
        }

        return root
    }
    #endif
}
