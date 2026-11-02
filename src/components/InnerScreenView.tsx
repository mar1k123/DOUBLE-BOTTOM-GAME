import React from 'react';
import { InnerPresentationPayload } from '../game/presentationPolicy';
import { CardInstance, Declaration, PackedCase, RoundResolutionSummary } from '../game/rules';
import { CategoryID, getCategoryTitle, getItemTitle, INITIAL_DECK_DATA } from '../game/deckData';
import { GameLanguage } from '../game/i18n';
import { ItemEngravingIcon, SilhouetteShape } from './ProceduralArt';

interface InnerScreenProps {
  lang: GameLanguage;
  payload: InnerPresentationPayload;
  hingeAngleDeg: number;
  hand: CardInstance[];
  selectedDiscardUids: string[];
  hasUsedMulligan: boolean;
  packedCase: PackedCase;
  declaration: Declaration;
  courierMarks: number;
  falseBottomTiltCount: number;
  falseBottomTimeLeft: number;
  resolutionSummary: RoundResolutionSummary | null;
  colorblindMode: boolean;
  protocolSavedCount: number;
  onToggleDiscardSelect: (uid: string) => void;
  onExecuteMulligan: () => void;
  onTogglePackVisibleItem: (card: CardInstance) => void;
  onAssignHiddenFalseBottomItem: (card: CardInstance) => void;
  onClearCase: () => void;
  onSelectCategory: (cat: CategoryID) => void;
  onChangeBribe: (bribe: number) => void;
  onQuickSealSuitcase: () => void;
  onQuickOpenSuitcase: () => void;
  onPerformSmoothTilt: () => void;
  onFinishInspectionToResolution: () => void;
  onSaveProtocolToGallery: () => void;
  onNextRound: () => void;
}

/**
 * InnerScene (iPhone Duo Inner Screen — 7.6", Landscape, ~890×626 pt, Regular Size Classes).
 * Displays the leather suitcase interior, Courier hand, Slit Levels 1–3, or full committed inspection.
 */
export const InnerScreenView: React.FC<InnerScreenProps> = ({
  lang,
  payload,
  hingeAngleDeg,
  hand,
  selectedDiscardUids,
  hasUsedMulligan,
  packedCase,
  declaration,
  courierMarks,
  falseBottomTiltCount,
  falseBottomTimeLeft,
  resolutionSummary,
  colorblindMode,
  protocolSavedCount,
  onToggleDiscardSelect,
  onExecuteMulligan,
  onTogglePackVisibleItem,
  onAssignHiddenFalseBottomItem,
  onClearCase,
  onSelectCategory,
  onChangeBribe,
  onQuickSealSuitcase,
  onQuickOpenSuitcase,
  onPerformSmoothTilt,
  onFinishInspectionToResolution,
  onSaveProtocolToGallery,
  onNextRound,
}) => {
  const { viewKind } = payload;
  const fr = lang === 'fr';
  const hasFalseBottomInHandOrCase =
    packedCase.hasFalseBottomCard || hand.some((c) => c.kind === 'false_bottom');

  return (
    <section
      aria-label={fr ? 'Écran interne iPhone Duo (Valise secrète)' : 'iPhone Duo Inner Screen (Secret Suitcase)'}
      data-testid="inner-screen"
      className="relative flex-1 min-h-[520px] rounded-[32px] border-2 border-[#6e5233] bg-leather-case p-5 pr-8 text-[#f3ead8] shadow-2xl overflow-hidden flex flex-col justify-between"
    >
      {/* Center hinge fold crease (reservedRegions: .division) */}
      <div
        aria-hidden="true"
        className="pointer-events-none absolute inset-y-0 left-1/2 -translate-x-1/2 w-[2px] bg-gradient-to-b from-transparent via-[#d4a853]/15 to-transparent"
      />

      {/* Vertical Side Dynamic Island & under-display camera on right edge */}
      <div
        aria-hidden="true"
        title={
          fr
            ? 'Dynamic Island vertical latéral et caméra sous l’écran (7.6″)'
            : 'Vertical Side Dynamic Island & Under-Display Camera (7.6″ Inner Screen)'
        }
        className="absolute right-2 top-1/2 -translate-y-1/2 w-2.5 h-24 rounded-full bg-[#050505] border border-[#3a2a1d] flex flex-col items-center justify-between py-2.5"
      >
        <span className="w-1.5 h-1.5 rounded-full bg-[#192822]" />
        <span className="w-1 h-8 rounded-full bg-[#121212]" />
      </div>

      {/* Top status bar of the Inner Screen */}
      <div className="flex flex-wrap items-center justify-between gap-2 border-b border-[#d4a853]/25 pb-2.5">
        <div className="flex items-center gap-2 text-xs font-mono-tabular text-[#d4a853]">
          <span>{fr ? 'ÉCRAN INTERNE · 7.6″ PAYSAGE' : 'INNER SCREEN · 7.6″ LANDSCAPE'}</span>
          <span>·</span>
          <span>{fr ? 'ANGLE' : 'ANGLE'} θ = {Math.round(hingeAngleDeg)}°</span>
        </div>
        <div className="text-xs font-mono-tabular text-[#c8b99e]">
          {viewKind === 'POWERED_OFF'
            ? fr
              ? 'ÉCRAN ÉTEINT (FERMÉ)'
              : 'SCREEN BLACKED OUT (CLOSED)'
            : fr
            ? 'VALISE DIPLOMATIQUE'
            : 'DIPLOMATIC VALISE'}
        </div>
      </div>

      {/* Inner Screen content controlled strictly by PresentationPolicy */}
      <div className="my-auto py-3">
        {viewKind === 'POWERED_OFF' && (
          <div className="h-80 rounded-2xl bg-[#070707] border border-[#26201a] flex flex-col items-center justify-center p-6 text-center space-y-3">
            <div className="w-12 h-12 rounded-full border border-[#d4a853]/30 flex items-center justify-center text-[#d4a853] font-mono-tabular text-xs">
              {Math.round(hingeAngleDeg)}°
            </div>
            <div className="text-sm font-semibold text-[#b8a98d]">
              {fr ? 'Écran interne physiquement éteint' : 'Inner Screen Physically Powered Off'}
            </div>
            <p className="text-xs text-[#8a7c66] max-w-md">
              {fr
                ? 'La valise est scellée et remise à l’Inspecteur. Toutes les négociations et décisions se font sur l’écran externe. Entrebâillez la charnière à 3–25° pour la fente ou ouvrez à ≥ 25° pour fouiller.'
                : 'The suitcase is sealed and handed to the Inspector. All questioning and decision buttons are on the Outer Screen. Crack the hinge to 3–25° to peek or open ≥ 25° to inspect.'}
            </p>
          </div>
        )}

        {viewKind === 'PROMPT_OPEN_SUITCASE' && (
          <div className="h-80 rounded-2xl bg-felt-green border border-[#d4a853]/30 flex flex-col items-center justify-center p-6 text-center space-y-4">
            <div className="text-lg font-serif-display font-bold text-[#f3ead8]">
              {fr
                ? 'Dépliez l’iPhone Duo (θ ≥ 100°) pour ouvrir la valise'
                : 'Unfold iPhone Duo (θ ≥ 100°) to lay open the suitcase'}
            </div>
            <button
              type="button"
              onClick={onQuickOpenSuitcase}
              className="px-4 py-2.5 rounded-lg text-xs font-semibold bg-[#d4a853] hover:bg-[#e0b865] text-[#14110e] transition-colors whitespace-nowrap"
            >
              {fr ? 'Ouvrir la valise (120°)' : 'Unfold Suitcase (120°)'}
            </button>
          </div>
        )}

        {viewKind === 'PACKING_INTERACTIVE' && (
          <div className="space-y-3">
            {/* Velvet suitcase tray: 5 visible slots + False Bottom slot */}
            <div className="rounded-2xl bg-felt-green brass-stitch border border-[#d4a853]/40 p-3.5 space-y-2.5">
              <div className="flex flex-wrap items-center justify-between gap-2 text-xs">
                <span className="font-semibold text-[#f3ead8]">
                  {fr ? 'Compartiments visibles' : 'Visible Suitcase Slots'} ({packedCase.visibleItems.length}/5) ·{' '}
                  {fr ? 'Poids brut :' : 'Gross Weight:'}{' '}
                  <strong className="font-mono-tabular text-[#d4a853]">
                    {packedCase.visibleItems.reduce((s, i) => s + i.weight, 0) +
                      (packedCase.hiddenItem?.weight ?? 0)}{' '}
                    kg
                  </strong>
                </span>
                <button
                  type="button"
                  onClick={onClearCase}
                  className="text-[11px] text-[#e0b865] hover:underline whitespace-nowrap"
                >
                  {fr ? 'Vider la valise' : 'Clear Suitcase'}
                </button>
              </div>

              <div className="grid grid-cols-5 gap-2">
                {[0, 1, 2, 3, 4].map((slotIdx) => {
                  const item = packedCase.visibleItems[slotIdx];
                  return (
                    <div
                      key={slotIdx}
                      className={`h-24 rounded-xl border flex flex-col items-center justify-center p-1.5 text-center ${
                        item
                          ? 'border-[#d4a853] bg-[#1a3829]'
                          : 'border-dashed border-[#d4a853]/30 bg-[#0d1f16]/70'
                      }`}
                    >
                      {item ? (
                        <>
                          <ItemEngravingIcon itemId={item.id} className="w-10 h-10" />
                          <span className="text-[10px] font-medium leading-tight truncate w-full mt-1">
                            {getItemTitle(item, lang)}
                          </span>
                          <span className="text-[9px] font-mono-tabular text-[#d4a853]">
                            V:{item.value} · F:{item.fine} · W:{item.weight}
                          </span>
                        </>
                      ) : (
                        <span className="text-[10px] text-[#7c9988] font-mono-tabular">
                          {fr ? `Empl. ${slotIdx + 1}` : `Slot ${slotIdx + 1}`}
                        </span>
                      )}
                    </div>
                  );
                })}
              </div>

              {/* Hidden "False Bottom" compartment */}
              {hasFalseBottomInHandOrCase && (
                <div className="flex items-center justify-between rounded-lg border border-[#d4a853]/45 bg-[#1b140e]/90 px-3 py-2 text-xs">
                  <div>
                    <span className="font-semibold text-[#d4a853]">
                      {fr ? 'Cache « Double fond » : ' : 'Hidden "False Bottom": '}
                    </span>
                    {packedCase.hiddenItem ? (
                      <span className="text-[#f3ead8]">
                        {fr ? 'Caché' : 'Stashed'} “{getItemTitle(packedCase.hiddenItem, lang)}” (V:
                        {packedCase.hiddenItem.value}, W:{packedCase.hiddenItem.weight} kg —{' '}
                        {fr ? 'hors compte n' : 'excluded from n'})
                      </span>
                    ) : (
                      <span className="text-[#b8a98d]">
                        {fr
                          ? 'Cliquez sur « Sous le fond » sur une carte en main pour dissimuler 1 objet'
                          : 'Click "Under False Bottom" on any hand card to conceal 1 item'}
                      </span>
                    )}
                  </div>
                </div>
              )}
            </div>

            {/* Courier Hand (6 cards) + Mulligan up to 2 cards (once) */}
            <div className="space-y-1.5">
              <div className="flex flex-wrap items-center justify-between gap-2 text-xs">
                <span className="font-semibold text-[#e6d5b8]">
                  {fr
                    ? `Main du Courrier (${hand.length} cartes) : cliquez pour placer dans la valise`
                    : `Courier’s Hand (${hand.length} cards): click a card to pack it`}
                </span>
                {!hasUsedMulligan && (
                  <button
                    type="button"
                    onClick={onExecuteMulligan}
                    disabled={selectedDiscardUids.length === 0}
                    className="px-2.5 py-1 rounded bg-[#38291b] hover:bg-[#4c3724] disabled:opacity-40 text-[11px] font-medium text-[#f3ead8] border border-[#d4a853]/30 whitespace-nowrap"
                  >
                    {fr
                      ? `Défausser (${selectedDiscardUids.length}/2) et piocher`
                      : `Mulligan Selected (${selectedDiscardUids.length}/2) & Redraw`}
                  </button>
                )}
              </div>

              <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-2">
                {hand.map((card) => {
                  if (card.kind === 'false_bottom') {
                    return (
                      <div
                        key={card.uid}
                        className="rounded-xl border border-[#d4a853] bg-[#2a1d12] p-2 flex flex-col justify-between text-xs"
                      >
                        <div>
                          <div className="text-[10px] font-mono-tabular text-[#d4a853]">
                            {fr ? 'CARTE SPÉCIALE' : 'SPECIAL CARD'}
                          </div>
                          <div className="font-semibold text-[#f3ead8] mt-0.5">
                            {fr ? 'Double fond' : 'False Bottom'}
                          </div>
                        </div>
                        <p className="text-[10px] text-[#c8b99e] leading-tight mt-1">
                          {fr
                            ? 'Débloque 1 cache secrète sous le feutre (hors compte n).'
                            : 'Unlocks 1 secret compartment under the felt (excluded from n).'}
                        </p>
                      </div>
                    );
                  }

                  const item = card.itemDef!;
                  const itemTitle = getItemTitle(item, lang);
                  const isDiscardChecked = selectedDiscardUids.includes(card.uid);
                  const isContraband = item.category === null;

                  return (
                    <div
                      key={card.uid}
                      className={`rounded-xl border p-2 flex flex-col justify-between text-xs transition-colors ${
                        isContraband
                          ? 'border-[#b91c1c]/70 bg-[#2d1614]'
                          : 'border-[#d4a853]/35 bg-[#1f1812]'
                      }`}
                    >
                      <div className="flex items-start justify-between gap-1">
                        <ItemEngravingIcon itemId={item.id} className="w-8 h-8 shrink-0" />
                        <span
                          className={`text-[9px] font-mono-tabular px-1 rounded ${
                            isContraband ? 'text-[#fca5a5]' : 'text-[#86efac]'
                          }`}
                        >
                          {isContraband
                            ? fr
                              ? 'CONTREB.'
                              : 'CONTRAB.'
                            : fr
                            ? 'LÉGAL'
                            : 'LEGAL'}
                        </span>
                      </div>

                      <div className="mt-1">
                        <div className="font-semibold text-[11px] leading-tight truncate" title={itemTitle}>
                          {itemTitle}
                        </div>
                        <div className="text-[10px] font-mono-tabular text-[#d4a853] mt-0.5">
                          V:{item.value} · F:{item.fine} · W:{item.weight}
                        </div>
                      </div>

                      <div className="mt-1.5 flex flex-col gap-1">
                        <button
                          type="button"
                          onClick={() => onTogglePackVisibleItem(card)}
                          className="w-full py-1 px-1.5 rounded bg-[#d4a853] hover:bg-[#e0b865] text-[#14110e] font-semibold text-[10px] whitespace-nowrap"
                        >
                          {fr ? 'Dans la valise' : 'Pack in Case'}
                        </button>
                        {hasFalseBottomInHandOrCase && (
                          <button
                            type="button"
                            onClick={() => onAssignHiddenFalseBottomItem(card)}
                            className="w-full py-0.5 px-1.5 rounded bg-[#3b2a1a] hover:bg-[#4e3824] text-[#e8d5a7] border border-[#d4a853]/30 text-[10px] whitespace-nowrap"
                          >
                            {fr ? 'Sous le fond' : 'Under False Bottom'}
                          </button>
                        )}
                        {!hasUsedMulligan && (
                          <button
                            type="button"
                            onClick={() => onToggleDiscardSelect(card.uid)}
                            className={`w-full py-0.5 px-1.5 rounded text-[10px] whitespace-nowrap ${
                              isDiscardChecked
                                ? 'bg-[#7c2d12] text-[#f3ead8]'
                                : 'bg-[#14110e]/70 text-[#a7987e]'
                            }`}
                          >
                            {isDiscardChecked
                              ? fr
                                ? 'À défausser ✓'
                                : 'Discard ✓'
                              : fr
                              ? 'Sélect. défausse'
                              : 'Mark Discard'}
                          </button>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>

            {/* Public declaration form L, count n, gratuity & Sealing button */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-2.5 items-center rounded-xl border border-[#d4a853]/35 bg-[#18120d] p-3">
              <div>
                <div className="text-[10px] font-mono-tabular text-[#b8a98d]">
                  {fr
                    ? `1. CATÉGORIE DÉCLARÉE (n = ${packedCase.visibleItems.length} pces)`
                    : `1. DECLARED CATEGORY (n = ${packedCase.visibleItems.length} pcs)`}
                </div>
                <div className="mt-1 grid grid-cols-2 gap-1">
                  {INITIAL_DECK_DATA.categories.map((cat) => (
                    <button
                      key={cat.id}
                      type="button"
                      onClick={() => onSelectCategory(cat.id)}
                      className={`py-1 px-2 rounded text-xs font-medium transition-colors whitespace-nowrap ${
                        declaration.category === cat.id
                          ? 'bg-[#d4a853] text-[#14110e] font-semibold'
                          : 'bg-[#261d15] text-[#e3d6be] hover:bg-[#33271c]'
                      }`}
                    >
                      {getCategoryTitle(cat, lang)} (W:{cat.expectedWeight})
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label
                  htmlFor="bribe-range"
                  className="block text-[10px] font-mono-tabular text-[#b8a98d]"
                >
                  {fr ? '2. POURBOIRE PASSEPORT :' : '2. PASSPORT GRATUITY:'}{' '}
                  <strong className="text-[#d4a853]">{declaration.bribeMarks} MK</strong>
                </label>
                <input
                  id="bribe-range"
                  type="range"
                  min={0}
                  max={Math.min(15, courierMarks)}
                  value={declaration.bribeMarks}
                  onChange={(e) => onChangeBribe(Number(e.target.value))}
                  className="w-full mt-2 accent-[#d4a853]"
                />
                <div className="text-[10px] text-[#9c8c72]">
                  {fr
                    ? 'Remboursé si l’Inspecteur décide malgré tout d’ouvrir la valise.'
                    : 'Returned to you if the Inspector still opens the suitcase.'}
                </div>
              </div>

              <div className="flex flex-col justify-end">
                <button
                  type="button"
                  onClick={onQuickSealSuitcase}
                  disabled={packedCase.visibleItems.length === 0}
                  className="w-full py-2.5 px-3 rounded-lg text-xs font-semibold bg-[#d4a853] hover:bg-[#e0b865] disabled:opacity-40 text-[#14110e] transition-colors whitespace-nowrap"
                >
                  {fr ? 'Fermer Duo et sceller (θ → 0°)' : 'Close Duo & Seal Case (θ → 0°)'}
                </button>
                <span className="text-[10px] text-[#a7987e] text-center mt-1">
                  {fr
                    ? 'Maintenir θ ≤ 3° pendant 250 ms verrouille le scellé'
                    : 'Holding θ ≤ 3° for 250 ms locks the lead seal'}
                </span>
              </div>
            </div>
          </div>
        )}

        {viewKind === 'SLIT_BLOCKED_NO_TOKENS' && (
          <div className="h-80 rounded-2xl bg-[#070707] border border-[#7f1d1d] flex flex-col items-center justify-center p-6 text-center space-y-2">
            <div className="text-base font-semibold text-[#fca5a5]">
              {fr ? 'Aucun jeton d’indice : fente verrouillée' : 'No Clue Tokens: Slit Peek Blocked'}
            </div>
            <p className="text-xs text-[#a7987e] max-w-md">
              {fr
                ? 'L’écran interne reste éteint (Section 4.5). Vous pouvez refermer le couvercle et laisser passer, ou ouvrir au-delà de 25° pour une fouille officielle.'
                : 'The Inner Screen remains blacked out (Section 4.5). Close the lid to clear the cargo, or swing the hinge past 25° for an official search.'}
            </p>
          </div>
        )}

        {viewKind === 'SLIT_LEVEL_1_WEIGHT' && (
          <div className="h-80 rounded-2xl bg-[#0b0e0c] border border-[#d4a853]/50 flex flex-col items-center justify-center p-6 text-center space-y-3">
            <div className="text-xs font-mono-tabular text-[#d4a853]">
              {fr
                ? 'FENTE · NIVEAU 1 « SOUPESÉE » (3° ≤ θ < 10°)'
                : 'SLIT PEEK · LEVEL 1 "BY WEIGHT" (3° ≤ θ < 10°)'}
            </div>
            <div className="text-3xl font-mono-tabular font-bold text-[#f3ead8]">
              {fr
                ? `Poids réel de la valise W = ${payload.totalWeight ?? 0} kg`
                : `Actual Suitcase Weight W = ${payload.totalWeight ?? 0} kg`}
            </div>
            <div className="text-xs text-[#c8b99e]">
              {fr ? 'Poids attendu selon déclaration' : 'Expected weight from declaration'} (
              {payload.declaredCount ?? 0} × {payload.expectedCategoryUnitWeight ?? 1} kg) ={' '}
              <strong className="font-mono-tabular text-[#d4a853]">
                {(payload.declaredCount ?? 0) * (payload.expectedCategoryUnitWeight ?? 1)} kg
              </strong>
            </div>
            <p className="text-xs text-[#988a70] max-w-md">
              {fr
                ? 'Ouvrez à 10–17° pour le Niveau 2 (silhouettes) ou à 18–24° pour le Niveau 3 (teinte à 75% de précision).'
                : 'Widen hinge to 10–17° for Level 2 (item silhouettes) or 18–24° for Level 3 (75% accuracy color tint).'}
            </p>
          </div>
        )}

        {viewKind === 'SLIT_LEVEL_2_SILHOUETTES' && (
          <div className="h-80 rounded-2xl bg-[#0d120f] border border-[#d4a853]/60 flex flex-col items-center justify-center p-6 space-y-4">
            <div className="text-xs font-mono-tabular text-[#d4a853]">
              {fr
                ? `FENTE · NIVEAU 2 « SILHOUETTES » (10° ≤ θ < 18°) · Poids total W = ${payload.totalWeight} kg`
                : `SLIT PEEK · LEVEL 2 "SILHOUETTES" (10° ≤ θ < 18°) · Total Weight W = ${payload.totalWeight} kg`}
            </div>
            <div className="flex flex-wrap items-center justify-center gap-3">
              {(payload.visibleSilhouettes ?? []).map((sil, idx) => (
                <SilhouetteShape
                  key={idx}
                  silhouette={sil}
                  tint="neutral"
                  colorblindMode={colorblindMode}
                  lang={lang}
                />
              ))}
            </div>
            <p className="text-xs text-[#988a70] text-center">
              {fr
                ? 'Seules les silhouettes des objets visibles apparaissent. Le double fond reste indétectable par la fente.'
                : 'Only outlines of visible items are shown. Any item hidden under the False Bottom is invisible to the slit.'}
            </p>
          </div>
        )}

        {viewKind === 'SLIT_LEVEL_3_TINTED' && (
          <div className="h-80 rounded-2xl bg-[#111713] border border-[#d4a853] flex flex-col items-center justify-center p-6 space-y-4">
            <div className="text-xs font-mono-tabular text-[#d4a853]">
              {fr
                ? 'FENTE · NIVEAU 3 « CONTRE-JOUR » (18° ≤ θ < 25°) · Fiabilité 75%'
                : 'SLIT PEEK · LEVEL 3 "BACKLIT TINT" (18° ≤ θ < 25°) · 75% Hint Accuracy'}
            </div>
            <div className="flex flex-wrap items-center justify-center gap-3">
              {(payload.tintedHints ?? []).map((hint, idx) => (
                <SilhouetteShape
                  key={idx}
                  silhouette={hint.silhouette}
                  tint={hint.hintedLegalGreen ? 'legal_green' : 'contraband_red'}
                  colorblindMode={colorblindMode}
                  lang={lang}
                />
              ))}
            </div>
            <p className="text-xs text-[#c8b99e] text-center">
              {fr
                ? 'Vert (points) = indice « conforme », Rouge (hachures) = indice « contrebande ». Attention : à θ ≥ 25°, l’ouverture devient irréversible !'
                : 'Green (dots) = "likely legal", Red (stripes) = "suspicious/contraband". Careful: crossing θ ≥ 25° commits to an official search!'}
            </p>
          </div>
        )}

        {viewKind === 'INSPECTION_COMMITTED_FULL' && (
          <div className="space-y-4">
            <div className="rounded-2xl bg-felt-green brass-stitch border border-[#d4a853] p-4 space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-xs font-mono-tabular font-bold text-[#d4a853]">
                  {fr
                    ? 'VALISE OFFICIELLEMENT OUVERTE (θ ≥ 25°)'
                    : 'SUITCASE OFFICIALLY OPENED (θ ≥ 25°)'}
                </span>
                <span className="text-xs font-mono-tabular text-[#e6d5b8]">
                  {fr ? 'Objets visibles :' : 'Visible items:'} {packedCase.visibleItems.length}
                </span>
              </div>

              <div className="grid grid-cols-5 gap-2">
                {packedCase.visibleItems.map((item, idx) => {
                  const isHonest = item.category !== null && item.category === declaration.category;
                  return (
                    <div
                      key={idx}
                      className={`rounded-xl border p-2 flex flex-col items-center text-center ${
                        isHonest
                          ? 'border-[#4ade80] bg-[#143322]'
                          : 'border-[#f87171] bg-[#3b1515]'
                      }`}
                    >
                      <ItemEngravingIcon itemId={item.id} className="w-10 h-10" />
                      <span className="text-xs font-semibold mt-1">{getItemTitle(item, lang)}</span>
                      <span className="text-[10px] font-mono-tabular mt-0.5">
                        {isHonest
                          ? `${fr ? 'CONFORME' : 'PASSES'} (+${item.value})`
                          : `${fr ? 'AMENDE' : 'FINE'} (-${item.fine})`}
                      </span>
                    </div>
                  );
                })}
              </div>

              {/* Gyro tilt search for False Bottom (6 seconds — Section 4.5) */}
              <div className="rounded-xl border border-[#d4a853]/50 bg-[#14110e]/90 p-3 flex flex-wrap items-center justify-between gap-3">
                <div className="text-xs space-y-0.5">
                  <div className="font-semibold text-[#d4a853]">
                    {fr
                      ? `Fouille du « Double fond » (gyroscope : 2 inclinaisons ≥ 25° sous ${falseBottomTimeLeft} s)`
                      : `"False Bottom" Search (Gyroscope: 2 smooth tilts ≥ 25° within ${falseBottomTimeLeft} s)`}
                  </div>
                  <div className="text-[#c8b99e]">
                    {fr ? 'Inclinaisons effectuées :' : 'Tilts completed:'}{' '}
                    <strong className="font-mono-tabular">{falseBottomTiltCount}/2</strong>
                    {falseBottomTiltCount >= 2 && packedCase.hiddenItem
                      ? fr
                        ? ` — CACHE DÉCOUVERTE : ${getItemTitle(packedCase.hiddenItem, lang)} !`
                        : ` — HIDDEN STASH FOUND: ${getItemTitle(packedCase.hiddenItem, lang)}!`
                      : falseBottomTiltCount >= 2
                      ? fr
                        ? ' — doublure vérifiée (aucune cache).'
                        : ' — lining checked (no hidden item).'
                      : ''}
                  </div>
                </div>

                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    onClick={onPerformSmoothTilt}
                    disabled={falseBottomTiltCount >= 2}
                    className="px-3 py-2 rounded-lg text-xs font-semibold bg-[#38291b] hover:bg-[#4d3926] disabled:opacity-40 text-[#f3ead8] border border-[#d4a853]/40 whitespace-nowrap"
                  >
                    {fr ? 'Incliner la valise (±25°)' : 'Tilt Suitcase (±25°)'}
                  </button>
                  <button
                    type="button"
                    onClick={onFinishInspectionToResolution}
                    className="px-3 py-2 rounded-lg text-xs font-semibold bg-[#d4a853] hover:bg-[#e0b865] text-[#14110e] whitespace-nowrap"
                  >
                    {fr ? 'Signer le procès-verbal' : 'Sign Inspection Protocol'}
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}

        {viewKind === 'ROUND_RESOLUTION_REPORT' && resolutionSummary && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {/* Detailed customs accounting report per Section 4.6 */}
            <div className="rounded-2xl bg-felt-green border border-[#d4a853]/40 p-4 space-y-2 text-xs">
              <div className="text-xs font-mono-tabular font-bold text-[#d4a853]">
                {fr ? 'BILAN DOUANIER DE LA MANCHE (SECTION 4.6)' : 'CUSTOMS ROUND LEDGER (SECTION 4.6)'}
              </div>
              <div className="flex justify-between py-1 border-b border-[#d4a853]/15">
                <span>{fr ? 'Statut du contrôle :' : 'Inspection status:'}</span>
                <strong className="font-mono-tabular">
                  {resolutionSummary.wasInspected
                    ? fr
                      ? `OUVERT (${resolutionSummary.verdictBanner === 'BUSTED' ? 'CONFISQUÉ' : 'CONFORME'})`
                      : `INSPECTED (${resolutionSummary.verdictBanner})`
                    : resolutionSummary.bribeAccepted
                    ? fr
                      ? 'ADMIS AVEC POURBOIRE'
                      : 'PASSED VIA GRATUITY'
                    : fr
                    ? 'ADMIS SANS FOUILLE'
                    : 'CLEARED WITHOUT SEARCH'}
                </strong>
              </div>
              <div className="flex justify-between py-1 border-b border-[#d4a853]/15">
                <span>{fr ? 'Valeur des marchandises admises :' : 'Passed goods payout:'}</span>
                <strong className="font-mono-tabular text-[#4ade80]">+{resolutionSummary.passedItemsValue} MK</strong>
              </div>
              <div className="flex justify-between py-1 border-b border-[#d4a853]/15">
                <span>{fr ? 'Amendes de confiscation :' : 'Confiscation fines paid:'}</span>
                <strong className="font-mono-tabular text-[#f87171]">-{resolutionSummary.confiscatedFinesPaid} MK</strong>
              </div>
              <div className="flex justify-between py-1 border-b border-[#d4a853]/15">
                <span>{fr ? 'Indemnité fouille abusive (3×n) :' : 'Wrongful search compensation (3×n):'}</span>
                <strong className="font-mono-tabular text-[#e0b865]">
                  +{resolutionSummary.compensationPaidByInspector} MK
                </strong>
              </div>
              <div className="flex justify-between py-1 border-b border-[#d4a853]/15">
                <span>{fr ? 'Pourboire transféré :' : 'Gratuity transferred:'}</span>
                <strong className="font-mono-tabular">{resolutionSummary.bribeTransferred} MK</strong>
              </div>
              <div className="flex justify-between pt-2 text-sm font-bold font-mono-tabular">
                <span>{fr ? 'Solde Courrier / Inspecteur :' : 'Total Courier / Inspector:'}</span>
                <span>
                  {resolutionSummary.courierFinalMarks} MK / {resolutionSummary.inspectorFinalMarks} MK
                </span>
              </div>
            </div>

            {/* "Inspection Protocol" card (Section 8: dual-camera Core Image / Metal composite) */}
            <div className="rounded-2xl border border-[#d4a853]/45 bg-[#171310] p-4 flex flex-col justify-between space-y-3">
              <div>
                <div className="flex items-center justify-between text-[10px] font-mono-tabular text-[#d4a853]">
                  <span>
                    {fr ? 'PROTOCOLE D’INSPECTION (DUAL CAM)' : 'INSPECTION PROTOCOL (DUAL CAM COMPOSITE)'}
                  </span>
                  <span>
                    {fr ? 'EN GALERIE :' : 'IN GALLERY:'} {protocolSavedCount}
                  </span>
                </div>
                <div className="mt-2 grid grid-cols-2 gap-2 bg-[#0e0c0a] p-2.5 rounded-xl border border-[#3a3024]">
                  <div className="text-center space-y-1">
                    <div className="h-20 rounded bg-[#1f1b17] flex items-center justify-center text-[10px] font-mono-tabular text-[#c8b99e] border border-[#3d3327]">
                      {fr ? 'CLICHÉ INSPECTEUR' : 'INSPECTOR FRAME'}
                      <br />
                      {fr ? '(Sous l’écran 7.6″)' : '(7.6″ Under-Display)'}
                    </div>
                    <div className="text-[10px] text-[#a7987e]">
                      {fr ? 'Pic d’émotion : +0.4s' : 'Emotion peak: +0.4s'}
                    </div>
                  </div>
                  <div className="text-center space-y-1">
                    <div className="h-20 rounded bg-[#1f1b17] flex items-center justify-center text-[10px] font-mono-tabular text-[#c8b99e] border border-[#3d3327]">
                      {fr ? 'CLICHÉ COURRIER' : 'COURIER FRAME'}
                      <br />
                      {fr ? '(Caméra 48 MP)' : '(48 MP Outer Cam)'}
                    </div>
                    <div className="text-[10px] text-[#a7987e]">
                      {fr ? 'Pic d’émotion : +0.6s' : 'Emotion peak: +0.6s'}
                    </div>
                  </div>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={onSaveProtocolToGallery}
                  className="flex-1 py-2 px-3 rounded-lg text-xs font-medium bg-[#2a2118] hover:bg-[#3a2e22] text-[#e6d5b8] border border-[#d4a853]/35 whitespace-nowrap"
                >
                  {fr ? 'Enregistrer dans la galerie' : 'Save to Match Gallery'}
                </button>
                <button
                  type="button"
                  onClick={onNextRound}
                  className="flex-1 py-2 px-3 rounded-lg text-xs font-semibold bg-[#d4a853] hover:bg-[#e0b865] text-[#14110e] whitespace-nowrap"
                >
                  {fr ? 'Manche suivante' : 'Next Round'}
                </button>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Bottom hinge shortcut bar */}
      <div className="border-t border-[#d4a853]/20 pt-2 flex flex-wrap items-center justify-between gap-2 text-[11px] text-[#a7987e]">
        <span>
          {fr
            ? 'Touches : [ réduire l’angle θ · ] augmenter l’angle θ · P Pause'
            : 'Hotkeys: [ decrease angle θ · ] increase angle θ · P Pause'}
        </span>
        <span className="font-mono-tabular">
          {fr ? 'Cible : 120 Hz ProMotion · 100% procédural' : 'Target: 120 Hz ProMotion · Zero external assets'}
        </span>
      </div>
    </section>
  );
};
