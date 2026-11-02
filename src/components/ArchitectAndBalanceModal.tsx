import React, { useState } from 'react';
import {
  BalanceSimulationReport,
  CourierStrategyId,
  InspectorStrategyId,
  runBalanceSimulation,
} from '../game/balanceSimulator';
import { BALANCED_DECK_DATA, INITIAL_DECK_DATA } from '../game/deckData';
import { BALANCED_TUNING, DEFAULT_TUNING } from '../game/tuning';
import { GameLanguage } from '../game/i18n';

interface ArchitectModalProps {
  lang: GameLanguage;
  activeTab: 'balance' | 'swift';
  onClose: () => void;
  onSwitchTab: (tab: 'balance' | 'swift') => void;
}

const COURIER_LABELS: Record<GameLanguage, Record<CourierStrategyId, string>> = {
  en: {
    always_honest: 'Always Honest',
    always_smuggler: 'Always Smuggler',
    mixed_bluffer: 'Mixed Bluffer (+False Bottom)',
    briber: 'Briber',
  },
  fr: {
    always_honest: 'Toujours honnête',
    always_smuggler: 'Toujours contrebandier',
    mixed_bluffer: 'Bluffeur mixte (+Double fond)',
    briber: 'Corrupteur',
  },
};

const INSPECTOR_LABELS: Record<GameLanguage, Record<InspectorStrategyId, string>> = {
  en: {
    always_inspect: 'Always Inspect',
    never_inspect: 'Never Inspect',
    nervometer_reader: 'Nervometer Reader',
    mixed_detective: 'Mixed Detective',
  },
  fr: {
    always_inspect: 'Toujours fouiller',
    never_inspect: 'Ne jamais fouiller',
    nervometer_reader: 'Lecteur de Nervomètre',
    mixed_detective: 'Détective mixte',
  },
};

const SWIFT_FILE_SNIPPETS: Record<
  string,
  { path: string; summaryEn: string; summaryFr: string; code: string }
> = {
  'Package.swift': {
    path: 'DoubleBottom/Package.swift',
    summaryEn:
      'Swift 6.1 / iOS 27.1 manifest. Separates Core, Rules, DuoSecret, DuoHinge, DuoDisplay, and Tell modules so OuterScene cannot access SecretState at compile time.',
    summaryFr:
      'Manifeste Swift 6.1 / iOS 27.1. Sépare les modules Core, Rules, DuoSecret, DuoHinge, DuoDisplay et Tell afin que OuterScene n’ait aucun accès à SecretState à la compilation.',
    code: `// swift-tools-version: 6.1
// Platform: iOS 27.1 / Xcode 27.1 (iPhone Duo)
import PackageDescription

let package = Package(
    name: "DoubleBottom",
    defaultLocalization: "en",
    platforms: [.iOS("27.1"), .macOS(.v15)],
    products: [
        .library(name: "Core", targets: ["Core"]),
        .library(name: "Rules", targets: ["Rules"]),
        .library(name: "DuoDisplay", targets: ["DuoDisplay"]),
        .library(name: "DuoHinge", targets: ["DuoHinge"]),
        .library(name: "Tell", targets: ["Tell"]),
        .executable(name: "BalanceSimulatorCLI", targets: ["BalanceSimulatorCLI"])
    ],
    targets: [
        .target(name: "Core", path: "Sources/Core"),
        .target(name: "Rules", dependencies: ["Core"], path: "Sources/Rules",
                resources: [.process("Resources/DeckData.json"), .process("Resources/CaptainLines.json")]),
        .target(name: "DuoSecret", dependencies: ["Core", "Rules"], path: "Sources/Duo/Secret"),
        .target(name: "DuoHinge", dependencies: ["Core"], path: "Sources/Duo/Hinge"),
        .target(name: "DuoDisplay", dependencies: ["Core", "Rules", "DuoHinge"], path: "Sources/Duo/Display"),
        .target(name: "Tell", dependencies: ["Core"], path: "Sources/Tell"),
        .executableTarget(name: "BalanceSimulatorCLI", dependencies: ["Core", "Rules"], path: "Sources/BalanceSimulatorCLI"),
        .testTarget(name: "DoubleBottomTests", dependencies: ["Core", "Rules", "DuoSecret", "DuoHinge", "DuoDisplay", "Tell"])
    ]
)`,
  },
  'Tuning.swift': {
    path: 'DoubleBottom/Sources/Core/Tuning.swift',
    summaryEn:
      'Single source of truth for game design constants: hinge angles (3°, 10°, 18°, 25°, 100°), 2° hysteresis, 250 ms seal debounce, Nervometer parameters, and iPhone Duo viewports.',
    summaryFr:
      'Registre unique des constantes de game design : angles de charnière (3°, 10°, 18°, 25°, 100°), hystérésis de 2°, anti-rebond de 250 ms, paramètres du Nervomètre et écrans iPhone Duo.',
    code: `public struct Tuning: Sendable, Codable, Equatable {
    public var minPlayers: Int = 2
    public var maxPlayers: Int = 6
    public var couriersPerPlayer: Int = 2
    public var startingMarks: Int = 40
    public var startingClueTokens: Int = 3
    public var maxClueTokens: Int = 5
    public var handSize: Int = 6
    public var maxVisibleSlots: Int = 5
    public var compensationPerItem: Int = 3 // Tuned via BalanceSimulator (was 2)
    public var packingSeconds: TimeInterval = 75.0
    public var negotiationSeconds: TimeInterval = 45.0
    public var falseBottomSearchSeconds: TimeInterval = 6.0
    public var sealAngleDeg: Double = 3.0
    public var slitLevel1MaxAngleDeg: Double = 10.0
    public var slitLevel2MaxAngleDeg: Double = 18.0
    public var commitAngleDeg: Double = 25.0
    public var openAngleDeg: Double = 100.0
    public var hysteresisDeg: Double = 2.0
    public var sealHoldMs: Int = 250
    public var tintAccuracy: Double = 0.75
}`,
  },
  'HingeProviding.swift': {
    path: 'DoubleBottom/Sources/Duo/Hinge/HingeProviding.swift',
    summaryEn:
      'HingeProviding protocol & 3 implementations: DuoHingeProvider (iOS 27.1 .onHingeChange / UIHingeInteraction), SimulatedHingeProvider, and AccessibilityHingeProvider.',
    summaryFr:
      'Protocole HingeProviding et 3 implémentations : DuoHingeProvider (iOS 27.1 .onHingeChange / UIHingeInteraction), SimulatedHingeProvider et AccessibilityHingeProvider.',
    code: `// VERIFY AGAINST APPLE DOCS (iOS 27.1 / Xcode 27.1):
// SwiftUI: nonisolated func onHingeChange(isEnabled: Bool = true, _ action: @escaping (DeviceHingeContext, DeviceHingeContext) -> Void) -> some View
// UIKit: @MainActor class UIHingeInteraction : NSObject, UIInteraction
public protocol HingeProviding: Sendable {
    var samples: AsyncStream<HingeSample> { get }
}`,
  },
  'PresentationPolicy.swift': {
    path: 'DoubleBottom/Sources/Duo/Display/PresentationPolicy.swift',
    summaryEn:
      'Pure function PresentationPolicy(phase, hingeZone, role) -> (innerContent, outerContent) and CameraCaptureAccessory adapter for iOS 27.1.',
    summaryFr:
      'Fonction pure PresentationPolicy(phase, hingeZone, role) -> (innerContent, outerContent) et adaptateur CameraCaptureAccessory pour iOS 27.1.',
    code: `// VERIFY AGAINST APPLE DOCS (iOS 27.1):
// CameraCaptureAccessory(isEnabled: $isOuterAccessoryActive) { OuterSceneView(projection: store.publicProjection) }
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
    ) -> DualScreenPresentation
}`,
  },
};

export const ArchitectAndBalanceModal: React.FC<ArchitectModalProps> = ({
  lang,
  activeTab,
  onClose,
  onSwitchTab,
}) => {
  const fr = lang === 'fr';
  const [report, setReport] = useState<BalanceSimulationReport>(() =>
    runBalanceSimulation(
      600,
      BALANCED_DECK_DATA,
      BALANCED_TUNING,
      fr ? 'Après équilibrage (v1.1)' : 'After Balancing (v1.1)'
    )
  );
  const [selectedSwiftFile, setSelectedSwiftFile] = useState<string>('Package.swift');

  const handleRunSim = (preset: 'initial' | 'balanced', count: number) => {
    if (preset === 'initial') {
      setReport(
        runBalanceSimulation(
          count,
          INITIAL_DECK_DATA,
          DEFAULT_TUNING,
          fr ? 'Avant équilibrage (v1.0)' : 'Before Balancing (v1.0)'
        )
      );
    } else {
      setReport(
        runBalanceSimulation(
          count,
          BALANCED_DECK_DATA,
          BALANCED_TUNING,
          fr ? 'Après équilibrage (v1.1)' : 'After Balancing (v1.1)'
        )
      );
    }
  };

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label={
        fr
          ? 'Simulateur d’équilibrage et architecture Swift iOS 27.1'
          : 'Balance Simulator & Swift iOS 27.1 Architecture'
      }
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 p-4 overflow-y-auto"
    >
      <div className="w-full max-w-5xl rounded-2xl border border-[#d4a853]/50 bg-[#14110e] text-[#f3ead8] p-6 shadow-2xl space-y-4 max-h-[90vh] overflow-y-auto">
        <div className="flex flex-wrap items-center justify-between gap-3 border-b border-[#d4a853]/25 pb-3">
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => onSwitchTab('balance')}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors whitespace-nowrap ${
                activeTab === 'balance'
                  ? 'bg-[#d4a853] text-[#14110e]'
                  : 'bg-[#221c16] text-[#c8b99e] hover:bg-[#2d251d]'
              }`}
            >
              {fr ? 'BalanceSimulator (Section 12)' : 'BalanceSimulator (Section 12)'}
            </button>
            <button
              type="button"
              onClick={() => onSwitchTab('swift')}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors whitespace-nowrap ${
                activeTab === 'swift'
                  ? 'bg-[#d4a853] text-[#14110e]'
                  : 'bg-[#221c16] text-[#c8b99e] hover:bg-[#2d251d]'
              }`}
            >
              {fr ? 'Architecture Swift / iOS 27.1' : 'Swift / iOS 27.1 Architecture'}
            </button>
          </div>

          <button
            type="button"
            onClick={onClose}
            className="px-3 py-1.5 rounded-lg text-xs font-semibold bg-[#292119] hover:bg-[#382d22] text-[#f3ead8] border border-[#d4a853]/30 whitespace-nowrap"
          >
            {fr ? 'Fermer' : 'Close Window'}
          </button>
        </div>

        {activeTab === 'balance' ? (
          <div className="space-y-4 text-xs">
            <div className="flex flex-wrap items-center justify-between gap-3 bg-[#1c1712] border border-[#d4a853]/30 rounded-xl p-3.5">
              <div className="space-y-1">
                <div className="font-semibold text-sm text-[#f3ead8]">
                  {fr
                    ? `Simulateur Monte-Carlo (${report.presetLabel})`
                    : `Monte Carlo Balance Simulator (${report.presetLabel})`}
                </div>
                <div className="text-[#b8a98d]">
                  {fr
                    ? 'Matrice 4×4 des stratégies Courrier et Inspecteur. Cibles : taux de fouille à l’équilibre 35–65%, avantage max d’une stratégie pure ≤ 25%.'
                    : '4×4 matrix of Courier and Inspector policies. Targets: equilibrium inspection rate 35–65%, max pure strategy advantage vs mixed ≤ 25%.'}
                </div>
              </div>
              <div className="flex flex-wrap items-center gap-2">
                <button
                  type="button"
                  onClick={() => handleRunSim('initial', 1000)}
                  className="px-3 py-1.5 rounded-lg bg-[#2a2118] hover:bg-[#382c20] text-[#e6d5b8] border border-[#d4a853]/30 font-medium whitespace-nowrap"
                >
                  {fr ? 'Tester « Avant équilibrage »' : 'Run "Before Balancing"'}
                </button>
                <button
                  type="button"
                  onClick={() => handleRunSim('balanced', 2500)}
                  className="px-3 py-1.5 rounded-lg bg-[#d4a853] hover:bg-[#e0b865] text-[#14110e] font-semibold whitespace-nowrap"
                >
                  {fr ? 'Tester « Après équilibrage »' : 'Run "After Balancing"'}
                </button>
              </div>
            </div>

            {/* Summary KPIs */}
            <div className="grid grid-cols-1 sm:grid-cols-4 gap-3 font-mono-tabular">
              <div className="rounded-xl border border-[#d4a853]/30 bg-[#1a1510] p-3">
                <div className="text-[10px] text-[#a7987e]">
                  {fr ? 'TAUX DE FOUILLE À L’ÉQUILIBRE' : 'EQUILIBRIUM INSPECTION RATE'}
                </div>
                <div className="text-xl font-bold text-[#d4a853] mt-1">{report.equilibriumInspectionRate}%</div>
                <div className="text-[10px] text-[#86efac]">
                  {fr ? 'Cible : 35% – 65%' : 'Target: 35% – 65%'}
                </div>
              </div>
              <div className="rounded-xl border border-[#d4a853]/30 bg-[#1a1510] p-3">
                <div className="text-[10px] text-[#a7987e]">
                  {fr ? 'AVANTAGE MAX STRATÉGIE PURE' : 'MAX PURE STRATEGY ADVANTAGE'}
                </div>
                <div className="text-xl font-bold text-[#f3ead8] mt-1">+{report.maxPureStrategyAdvantageVsMixed}%</div>
                <div className="text-[10px] text-[#86efac]">
                  {fr ? 'Cible : ≤ +25.0%' : 'Target: ≤ +25.0%'}
                </div>
              </div>
              <div className="rounded-xl border border-[#d4a853]/30 bg-[#1a1510] p-3">
                <div className="text-[10px] text-[#a7987e]">
                  {fr ? 'DURÉE PARTIE 3 JOUEURS' : '3-PLAYER MATCH DURATION'}
                </div>
                <div className="text-xl font-bold text-[#f3ead8] mt-1">{report.estimated3PlayerMatchMinutes} min</div>
                <div className="text-[10px] text-[#86efac]">
                  {fr ? 'Cible : 18 – 28 min' : 'Target: 18 – 28 min'}
                </div>
              </div>
              <div className="rounded-xl border border-[#d4a853]/30 bg-[#1a1510] p-3">
                <div className="text-[10px] text-[#a7987e]">
                  {fr ? 'STATUT CRITÈRES SECTION 12' : 'SECTION 12 CRITERIA STATUS'}
                </div>
                <div className="text-base font-bold text-[#4ade80] mt-1">
                  {report.meetsAllTargetMetrics
                    ? fr
                      ? 'TOUTES LES CIBLES VALIDÉES'
                      : 'ALL TARGETS MET'
                    : fr
                    ? 'AJUSTEMENT REQUIS'
                    : 'TUNING REQUIRED'}
                </div>
                <div className="text-[10px] text-[#b8a98d]">
                  {fr ? 'Parties par cellule :' : 'Matches per cell:'} {report.matchesPerPair}
                </div>
              </div>
            </div>

            {/* 4x4 Matrix */}
            <div className="overflow-x-auto rounded-xl border border-[#d4a853]/30">
              <table className="w-full text-left border-collapse font-mono-tabular text-xs">
                <thead>
                  <tr className="bg-[#211a14] text-[#d4a853] border-b border-[#d4a853]/30">
                    <th className="p-2.5">{fr ? 'Courrier \\ Inspecteur' : 'Courier \\ Inspector'}</th>
                    {(['always_inspect', 'never_inspect', 'nervometer_reader', 'mixed_detective'] as InspectorStrategyId[]).map(
                      (iPol) => (
                        <th key={iPol} className="p-2.5">
                          {INSPECTOR_LABELS[lang][iPol]}
                        </th>
                      )
                    )}
                  </tr>
                </thead>
                <tbody>
                  {(['always_honest', 'always_smuggler', 'mixed_bluffer', 'briber'] as CourierStrategyId[]).map(
                    (cPol) => (
                      <tr key={cPol} className="border-b border-[#d4a853]/15 bg-[#16120e]">
                        <td className="p-2.5 font-sans font-semibold text-[#f3ead8]">
                          {COURIER_LABELS[lang][cPol]}
                        </td>
                        {(['always_inspect', 'never_inspect', 'nervometer_reader', 'mixed_detective'] as InspectorStrategyId[]).map(
                          (iPol) => {
                            const cell = report.cells.find(
                              (c) => c.courierPolicy === cPol && c.inspectorPolicy === iPol
                            );
                            if (!cell) return <td key={iPol} className="p-2.5">-</td>;
                            return (
                              <td key={iPol} className="p-2.5">
                                <div className="text-[#f3ead8] font-semibold">
                                  C: {cell.courierWinRate}% / I: {cell.inspectorWinRate}%
                                </div>
                                <div className="text-[10px] text-[#a7987e]">
                                  {fr ? 'Fouilles :' : 'Inspected:'} {cell.inspectionRate}% ·{' '}
                                  {cell.avgCourierFinalMarks}:{cell.avgInspectorFinalMarks}
                                </div>
                              </td>
                            );
                          }
                        )}
                      </tr>
                    )
                  )}
                </tbody>
              </table>
            </div>

            {/* Before / After Tuning Notes */}
            <div className="rounded-xl border border-[#d4a853]/30 bg-[#1a1510] p-3.5 space-y-2">
              <div className="font-semibold text-[#d4a853]">
                {fr
                  ? 'Tableau des ajustements « Avant / Après » (Section 12)'
                  : '"Before / After" Balance Adjustments (Section 12)'}
              </div>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-[#d6c7ad]">
                <div>
                  1. <strong>compensationPerItem (Tuning.swift)</strong>: 2 → <strong>3 marks</strong>.{' '}
                  {fr
                    ? 'À 2 marks, la stratégie « toujours fouiller » coûtait trop peu sur les bagages honnêtes ; à 3 marks, une fouille abusive de 4 objets coûte 12 marks.'
                    : 'At 2 marks, the Inspector’s "always inspect" policy lost too little on honest cargo; at 3 marks, a false alarm on 4 items costs 12 marks.'}
                </div>
                <div>
                  2. <strong>{fr ? 'Valeurs légales et amendes (DeckData.json)' : 'Legal values & contraband fines (DeckData.json)'}</strong>:{' '}
                  {fr
                    ? 'Oranges 2→3, Fromage 3→4, Vin 4→5 ; amendes Microfilm 6→7, Radio 6→7, Or 8→9, Amphore 9→10. Équilibre l’espérance mathématique du bluff face au détective mixte.'
                    : 'Oranges value 2→3, Cheese 3→4, Wine 4→5; fines for Microfilm 6→7, Radio 6→7, Gold 8→9, Antique 9→10. Balances expected value of bluffing vs mixed detective.'}
                </div>
              </div>
            </div>
          </div>
        ) : (
          <div className="space-y-4 text-xs">
            <div className="flex flex-wrap gap-2">
              {Object.keys(SWIFT_FILE_SNIPPETS).map((fileKey) => (
                <button
                  key={fileKey}
                  type="button"
                  onClick={() => setSelectedSwiftFile(fileKey)}
                  className={`px-3 py-1.5 rounded-lg font-mono-tabular transition-colors ${
                    selectedSwiftFile === fileKey
                      ? 'bg-[#d4a853] text-[#14110e] font-semibold'
                      : 'bg-[#211a14] text-[#c8b99e]'
                  }`}
                >
                  {fileKey}
                </button>
              ))}
            </div>

            <div className="rounded-xl border border-[#d4a853]/30 bg-[#0d0b09] p-4 space-y-2">
              <div className="font-mono-tabular text-[#d4a853] font-semibold">
                {SWIFT_FILE_SNIPPETS[selectedSwiftFile].path}
              </div>
              <p className="text-[#c8b99e]">
                {fr
                  ? SWIFT_FILE_SNIPPETS[selectedSwiftFile].summaryFr
                  : SWIFT_FILE_SNIPPETS[selectedSwiftFile].summaryEn}
              </p>
              <pre className="mt-2 p-3 rounded-lg bg-[#16120e] text-[#e8dcc4] font-mono-tabular text-[11px] overflow-x-auto leading-relaxed">
                {SWIFT_FILE_SNIPPETS[selectedSwiftFile].code}
              </pre>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
