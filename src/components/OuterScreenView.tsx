import React from 'react';
import { OuterPresentationPayload } from '../game/presentationPolicy';
import { getCategoryTitle, INITIAL_DECK_DATA } from '../game/deckData';
import { GameLanguage } from '../game/i18n';
import { ProceduralPassportPortrait } from './ProceduralArt';

interface OuterScreenProps {
  lang: GameLanguage;
  payload: OuterPresentationPayload;
  isScanningXray: boolean;
  xrayScanProgress: number;
  demoHintText?: string | null;
  onTriggerXrayScan: () => void;
  onProceedToDecision: () => void;
  onDecisionPass: () => void;
  onDecisionAcceptBribe: () => void;
  onDecisionArmInspection: () => void;
  onQuickPeekSlit: (targetAngle: number) => void;
  onNextRound: () => void;
  onReplayCaptainVoice: () => void;
}

/**
 * OuterScene (iPhone Duo Outer Screen — 5.4", Portrait, ~466×678 pt, Compact Width).
 * Strictly receives ONLY OuterPresentationPayload (PublicProjection) at the type level.
 * SecretState (hand, suitcase items, false bottom) is physically inaccessible here.
 */
export const OuterScreenView: React.FC<OuterScreenProps> = ({
  lang,
  payload,
  isScanningXray,
  xrayScanProgress,
  demoHintText,
  onTriggerXrayScan,
  onProceedToDecision,
  onDecisionPass,
  onDecisionAcceptBribe,
  onDecisionArmInspection,
  onQuickPeekSlit,
  onNextRound,
  onReplayCaptainVoice,
}) => {
  const { viewKind, projection } = payload;
  const fr = lang === 'fr';
  const catObj = INITIAL_DECK_DATA.categories.find((c) => c.id === projection.declaration?.category);
  const categoryName = getCategoryTitle(catObj, lang);

  const formatVerdict = (v: 'CLEAN' | 'BUSTED' | null | undefined) => {
    if (v === 'BUSTED') return fr ? 'CONFISQUÉ' : 'BUSTED';
    return fr ? 'CONFORME' : 'CLEAN';
  };

  return (
    <section
      aria-label={fr ? 'Écran externe iPhone Duo (Public)' : 'iPhone Duo Outer Screen (Public)'}
      data-testid="outer-screen"
      className="relative flex flex-col justify-between w-full lg:w-[340px] min-h-[520px] rounded-[28px] border-2 border-[#5c4928] bg-passport-cover p-4 pl-7 text-[#f3ead8] shadow-2xl overflow-hidden shrink-0"
    >
      {/* Vertical Side Dynamic Island (Sections 1 & 6.3: left safe inset) */}
      <div
        aria-hidden="true"
        title={fr ? 'Dynamic Island vertical latéral (écran 5.4″)' : 'Vertical Side Dynamic Island (5.4″ Outer Screen)'}
        className="absolute left-1.5 top-1/2 -translate-y-1/2 w-2.5 h-24 rounded-full bg-[#050505] border border-[#2d251b] flex flex-col items-center justify-between py-2.5"
      >
        <span className="w-1.5 h-1.5 rounded-full bg-[#1a2430]" />
        <span className="w-1 h-8 rounded-full bg-[#121212]" />
      </div>

      {/* Top passport header / scoreboard */}
      <div className="border-b border-[#d4a853]/25 pb-2.5">
        <div className="flex items-center justify-between text-[11px] font-mono-tabular text-[#c8b99e]">
          <span>{fr ? 'ÉCRAN EXTERNE · 5.4″' : 'OUTER SCREEN · 5.4″'}</span>
          <span>
            {fr ? 'MANCHE' : 'ROUND'} {projection.roundNumber}/{projection.totalRounds} · {projection.remainingSeconds}s
          </span>
        </div>

        <div className="mt-2 grid grid-cols-2 gap-2 text-xs bg-[#11181f]/90 border border-[#d4a853]/25 rounded-lg p-2">
          <div>
            <div className="text-[10px] text-[#a7987e]">{fr ? 'COURRIER' : 'COURIER'}</div>
            <div className="font-semibold truncate text-[#f3ead8]">{projection.courierName}</div>
            <div className="font-mono-tabular text-[#d4a853] font-semibold">{projection.courierMarks} MK</div>
          </div>
          <div className="border-l border-[#d4a853]/20 pl-2">
            <div className="text-[10px] text-[#a7987e]">{fr ? 'INSPECTEUR' : 'INSPECTOR'}</div>
            <div className="font-semibold truncate text-[#f3ead8]">{projection.inspectorName}</div>
            <div className="font-mono-tabular text-[#e2c178]">
              {projection.inspectorMarks} MK · {fr ? 'Indices' : 'Clues'}: {projection.inspectorClueTokens}
            </div>
          </div>
        </div>
      </div>

      {/* Storefront demo guided hint */}
      {demoHintText && (
        <div className="my-2 rounded-lg border border-[#d4a853] bg-[#2c2112] px-3 py-2 text-xs text-[#f8e7c1]">
          <div className="font-mono-tabular text-[10px] text-[#d4a853]">
            {fr ? 'DÉMO VITRINE (40 S)' : 'STOREFRONT DEMO (40 S)'}
          </div>
          <div className="font-medium mt-0.5">{demoHintText}</div>
        </div>
      )}

      {/* Main Outer Screen body per Section 6.2 Presentation Matrix */}
      <div className="my-auto py-3 flex flex-col justify-center">
        {viewKind === 'COURIER_PACKING_PUBLIC' && (
          <div className="space-y-3">
            <div className="flex items-center gap-3 bg-[#121a21] border border-[#d4a853]/30 rounded-xl p-3">
              <ProceduralPassportPortrait
                index={projection.courierPortraitIndex}
                country={projection.courierCountry}
              />
              <div className="text-xs space-y-1">
                <div className="text-[10px] font-mono-tabular text-[#d4a853]">
                  {fr
                    ? `PASSEPORT ${projection.courierCountry === 'altavia' ? 'D’ALTAVIE' : 'DU NORDMARK'}`
                    : `${projection.courierCountry === 'altavia' ? 'ALTAVIA' : 'NORDMARK'} PASSPORT`}
                </div>
                <div className="text-sm font-serif-display font-bold text-[#f3ead8]">
                  {projection.courierName}
                </div>
                <div className="text-[#bfb093]">
                  {fr
                    ? 'Le Courrier prépare son bagage sur l’écran interne…'
                    : 'Courier is packing luggage on the inner screen…'}
                </div>
              </div>
            </div>

            {projection.incompleteSealWarning ? (
              <div
                role="alert"
                className="rounded-lg border border-[#dc2626] bg-[#451212] p-3 text-xs text-[#fecaca] font-medium"
              >
                {fr
                  ? 'Déclaration incomplète : rouvrez la valise (au moins 1 objet et une catégorie requise).'
                  : 'Packing incomplete: unfold the suitcase (at least 1 item and a declared category required).'}
              </div>
            ) : (
              <div className="rounded-lg border border-[#d4a853]/20 bg-[#0f161c] p-3 text-xs text-[#b8a98d]">
                {fr
                  ? 'Contenu secret masqué. Lorsque le Courrier ferme le Duo à ≤ 3° pendant 250 ms, le scellé « SCELLÉ » est apposé.'
                  : 'Suitcase contents hidden. Once the Courier closes the Duo to ≤ 3° for 250 ms, the "SEALED" lock engages.'}
              </div>
            )}
          </div>
        )}

        {viewKind === 'SEALED_STAMP' && (
          <div className="text-center py-6 space-y-3">
            <div className="inline-block border-2 border-[#d4a853] text-[#d4a853] px-4 py-2 rounded font-mono-tabular font-bold tracking-widest text-lg -rotate-3">
              {fr ? 'SCELLÉ' : 'SEALED'}
            </div>
            <p className="text-xs text-[#c8b99e]">
              {fr
                ? 'Scellé verrouillé (θ ≤ 3°, 250 ms). Remettez l’iPhone Duo fermé à l’Inspecteur.'
                : 'Lead seal locked (θ ≤ 3°, 250 ms). Hand the closed iPhone Duo to the Inspector.'}
            </p>
          </div>
        )}

        {viewKind === 'NEGOTIATION_DOSSIER' && (
          <div className="space-y-3">
            <div className="rounded-xl border border-[#d4a853]/40 bg-[#e8dcc4] text-[#1c1611] p-3.5 shadow-inner">
              <div className="flex items-center justify-between border-b border-[#1c1611]/20 pb-1.5">
                <span className="text-[10px] font-mono-tabular font-semibold">
                  {fr ? 'DÉCLARATION EN DOUANE' : 'CUSTOMS DECLARATION'}
                </span>
                <span className="text-[10px] font-mono-tabular">
                  {fr ? 'POSTE « HIRONDELLE »' : 'SWALLOW CHECKPOINT'}
                </span>
              </div>
              <div className="mt-2 flex items-baseline justify-between">
                <span className="text-xs text-[#4a3e2e]">
                  {fr ? 'Marchandise déclarée :' : 'Declared cargo:'}
                </span>
                <span className="text-base font-serif-display font-bold">
                  {projection.declaration?.declaredCount ?? 0} {fr ? 'pces' : 'pcs'} · {categoryName}
                </span>
              </div>
              <div className="mt-1 flex items-baseline justify-between">
                <span className="text-xs text-[#4a3e2e]">
                  {fr ? 'Pourboire proposé :' : 'Offered gratuity:'}
                </span>
                <span className="text-sm font-mono-tabular font-bold text-[#7c2d12]">
                  {projection.declaration?.bribeMarks
                    ? `${projection.declaration.bribeMarks} ${fr ? 'marks' : 'marks'}`
                    : fr
                    ? '0 mark (aucun)'
                    : '0 marks (none)'}
                </span>
              </div>
            </div>

            {/* Nervometer / X-Ray Scanner (Section 7) */}
            <div className="rounded-xl border border-[#d4a853]/25 bg-[#10171e] p-3 space-y-2">
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold text-[#e6d5b8]">
                  {fr ? 'Appareil « Nervomètre »' : 'Nervometer-64 Gauge'}
                </span>
                <span className="text-[10px] font-mono-tabular text-[#a7987e]">
                  {fr ? 'Coût : 1 Indice' : 'Cost: 1 Clue'}
                </span>
              </div>

              {isScanningXray ? (
                <div className="space-y-1.5">
                  <div className="text-xs text-[#d4a853] font-mono-tabular">
                    {fr ? 'Scan Rayon X (5 s)…' : 'X-Ray Scanning (5 s)…'} {Math.round(xrayScanProgress)}%
                  </div>
                  <div className="w-full h-2 bg-[#1c2630] rounded overflow-hidden">
                    <div
                      className="h-full bg-[#d4a853] transition-all duration-150"
                      style={{ width: `${xrayScanProgress}%` }}
                    />
                  </div>
                </div>
              ) : projection.nervometerReading ? (
                <div className="space-y-1.5">
                  <div className="flex items-baseline justify-between text-xs">
                    <span className="text-[#bfb093]">
                      {fr ? 'Agitation' : 'Agitation'} (
                      {projection.nervometerReading.usedTremorFallback
                        ? fr
                          ? 'Tremblement châssis'
                          : 'Hand Tremor'
                        : 'Vision RGB'}
                      ):
                    </span>
                    <span className="font-mono-tabular font-bold text-[#f59e0b]">
                      {projection.nervometerReading.value} ± {projection.nervometerReading.uncertainty}
                    </span>
                  </div>
                  <div className="relative w-full h-3 rounded bg-[#1d2731] overflow-hidden border border-[#3a4654]">
                    <div
                      className="absolute top-0 bottom-0 bg-[#f59e0b]/30 border-x border-[#f59e0b]"
                      style={{
                        left: `${Math.max(0, projection.nervometerReading.value - projection.nervometerReading.uncertainty)}%`,
                        width: `${Math.min(100, projection.nervometerReading.uncertainty * 2)}%`,
                      }}
                    />
                    <div
                      className="absolute top-0 bottom-0 w-1 bg-[#f3ead8]"
                      style={{ left: `${projection.nervometerReading.value}%` }}
                    />
                  </div>
                  <p className="text-[10px] text-[#988a70]">
                    {fr
                      ? 'Indicateur de nervosité (ne constitue pas un détecteur de mensonge).'
                      : 'Interrogation stress gauge (game prop — not a lie detector).'}
                  </p>
                </div>
              ) : (
                <button
                  type="button"
                  onClick={onTriggerXrayScan}
                  disabled={projection.inspectorClueTokens < 1}
                  className="w-full py-2 px-3 rounded-lg text-xs font-semibold bg-[#23313f] hover:bg-[#2c3e50] disabled:opacity-40 text-[#f3ead8] border border-[#d4a853]/35 transition-colors whitespace-nowrap"
                >
                  {fr ? 'Activer le « Rayon X » (1 Indice)' : 'Activate "X-Ray & Nervometer" (1 Clue)'}
                </button>
              )}
            </div>

            <div className="grid grid-cols-2 gap-2">
              <button
                type="button"
                onClick={() => onQuickPeekSlit(6)}
                className="py-2 px-2.5 rounded-lg text-xs font-medium bg-[#1a2530] hover:bg-[#243342] text-[#e6d5b8] border border-[#d4a853]/30 transition-colors whitespace-nowrap"
              >
                {fr ? 'Entrebâiller (6° · 1 Ind.)' : 'Peek Slit (6° · 1 Clue)'}
              </button>
              <button
                type="button"
                onClick={onProceedToDecision}
                className="py-2 px-2.5 rounded-lg text-xs font-semibold bg-[#d4a853] hover:bg-[#e0b865] text-[#14110e] transition-colors whitespace-nowrap"
              >
                {fr ? 'Décision Inspecteur' : 'Inspector Decision'}
              </button>
            </div>
          </div>
        )}

        {viewKind === 'DECISION_BUTTONS' && (
          <div className="space-y-2.5">
            <div className="rounded-lg bg-[#111921] border border-[#d4a853]/30 p-3 text-xs">
              <div className="font-mono-tabular text-[10px] text-[#d4a853]">
                {fr ? 'PHASE DE DÉCISION (DECISION)' : 'DECISION PHASE (DECISION)'}
              </div>
              <div className="mt-1 font-medium text-[#f3ead8]">
                {fr ? 'Déclaration :' : 'Declaration:'} {projection.declaration?.declaredCount ?? 0}{' '}
                {fr ? 'pces' : 'pcs'} “{categoryName}”
              </div>
              <div className="text-[#b8a98d] mt-0.5">
                {fr
                  ? 'Entrebâillez la charnière à 3–24° (fente pour 1 jeton) ou ouvrez à ≥ 25° pour une fouille officielle.'
                  : 'Crack the hinge to 3–24° (slit peek for 1 Clue) or open ≥ 25° for an official search.'}
              </div>
            </div>

            {projection.noClueTokensWarning && (
              <div role="alert" className="rounded-lg border border-[#dc2626] bg-[#451212] p-2.5 text-xs text-[#fecaca]">
                {fr ? 'Aucun jeton d’indice : fente verrouillée' : 'No Clue Tokens left: slit peek locked'}
              </div>
            )}

            <button
              type="button"
              onClick={onDecisionPass}
              className="w-full py-2.5 px-4 rounded-lg text-xs font-semibold bg-[#1f5138] hover:bg-[#276345] text-[#f3ead8] border border-[#4ade80]/30 transition-colors whitespace-nowrap"
            >
              {fr ? 'LAISSER PASSER' : 'CLEAR & PASS CARGO'}
            </button>

            {(projection.declaration?.bribeMarks ?? 0) > 0 && (
              <button
                type="button"
                onClick={onDecisionAcceptBribe}
                className="w-full py-2.5 px-4 rounded-lg text-xs font-semibold bg-[#784917] hover:bg-[#8f581d] text-[#f8e7c1] border border-[#f59e0b]/40 transition-colors whitespace-nowrap"
              >
                {fr
                  ? `ACCEPTER LE POURBOIRE (+${projection.declaration?.bribeMarks} MK)`
                  : `ACCEPT GRATUITY (+${projection.declaration?.bribeMarks} MK)`}
              </button>
            )}

            <button
              type="button"
              onClick={onDecisionArmInspection}
              className="w-full py-2.5 px-4 rounded-lg text-xs font-semibold bg-[#7f1d1d] hover:bg-[#991b1b] text-[#fecaca] border border-[#f87171]/40 transition-colors whitespace-nowrap"
            >
              {fr ? 'OUVRIR LA VALISE (θ ≥ 25°)' : 'OPEN & INSPECT CASE (θ ≥ 25°)'}
            </button>
          </div>
        )}

        {viewKind === 'SLIT_EYE_WATCHING' && (
          <div className="text-center py-5 px-3 rounded-xl border border-[#f59e0b]/50 bg-[#1c140d] space-y-3">
            {/* Customs Inspection Eye (Sections 4.5 & 6.2) */}
            <svg viewBox="0 0 120 60" className="w-28 h-14 mx-auto" aria-hidden="true">
              <path
                d="M10 30 Q60 4 110 30 Q60 56 10 30 Z"
                fill="#14110e"
                stroke="#d4a853"
                strokeWidth="3"
              />
              <circle cx="60" cy="30" r="13" fill="#d4a853" />
              <circle cx="60" cy="30" r="6" fill="#14110e" />
              <circle cx="56" cy="26" r="2.2" fill="#f3ead8" />
            </svg>
            <div className="font-mono-tabular text-sm font-bold tracking-widest text-[#f59e0b]">
              {fr ? 'SOUS SURVEILLANCE' : 'UNDER INSPECTION'}
            </div>
            {projection.noClueTokensWarning ? (
              <div className="text-xs text-[#fca5a5] font-medium">
                {fr
                  ? 'Aucun jeton d’indice : l’écran interne reste éteint'
                  : 'No Clue Tokens: inner screen remains blacked out'}
              </div>
            ) : (
              <p className="text-xs text-[#c8b99e]">
                {fr
                  ? 'L’Inspecteur a entrouvert le couvercle (3°–25°) et examine votre valise.'
                  : 'The Inspector has cracked the lid (3°–25°) and is peering inside your valise.'}
              </p>
            )}
          </div>
        )}

        {viewKind === 'INSPECTION_VERDICT_BANNER' && (
          <div className="text-center py-6 space-y-3">
            <div
              className={`inline-block border-4 px-5 py-2.5 rounded-lg font-mono-tabular text-2xl font-bold tracking-widest -rotate-3 ${
                projection.verdictBanner === 'BUSTED'
                  ? 'border-[#ef4444] text-[#fca5a5] bg-[#451212]'
                  : 'border-[#22c55e] text-[#bbf7d0] bg-[#103822]'
              }`}
            >
              {formatVerdict(projection.verdictBanner)}
            </div>
            <p className="text-xs text-[#c8b99e]">
              {fr
                ? 'Valise officiellement ouverte (θ ≥ 25°). Vérification du double fond et calcul des droits en cours.'
                : 'Suitcase officially opened (θ ≥ 25°). Checking false bottom and calculating customs duties.'}
            </p>
          </div>
        )}

        {viewKind === 'ROUND_END_SUMMARY' && (
          <div className="space-y-3">
            <div className="rounded-xl border border-[#d4a853]/40 bg-[#121a22] p-3 text-xs space-y-1.5">
              <div className="flex items-center justify-between">
                <span className="font-mono-tabular text-[10px] text-[#d4a853]">
                  {fr ? 'TAMPON PASSEPORT' : 'PASSPORT STAMP'}
                </span>
                <span className="font-mono-tabular font-bold text-[#f3ead8]">
                  {projection.resolutionSummary
                    ? formatVerdict(projection.resolutionSummary.verdictBanner)
                    : fr
                    ? 'ADMIS'
                    : 'CLEARED'}
                </span>
              </div>
              {projection.resolutionSummary && (
                <div className="grid grid-cols-2 gap-2 pt-1 border-t border-[#d4a853]/20 font-mono-tabular">
                  <div>
                    {fr ? 'Courrier :' : 'Courier:'}{' '}
                    <span className={projection.resolutionSummary.courierNetDelta >= 0 ? 'text-[#4ade80]' : 'text-[#f87171]'}>
                      {projection.resolutionSummary.courierNetDelta >= 0 ? '+' : ''}
                      {projection.resolutionSummary.courierNetDelta} MK
                    </span>
                  </div>
                  <div>
                    {fr ? 'Inspecteur :' : 'Inspector:'}{' '}
                    <span className={projection.resolutionSummary.inspectorNetDelta >= 0 ? 'text-[#4ade80]' : 'text-[#f87171]'}>
                      {projection.resolutionSummary.inspectorNetDelta >= 0 ? '+' : ''}
                      {projection.resolutionSummary.inspectorNetDelta} MK
                    </span>
                  </div>
                </div>
              )}
            </div>

            <button
              type="button"
              onClick={onNextRound}
              className="w-full py-2.5 px-4 rounded-lg text-xs font-semibold bg-[#d4a853] hover:bg-[#e0b865] text-[#14110e] transition-colors whitespace-nowrap"
            >
              {fr ? 'Manche suivante' : 'Next Round'}
            </button>
          </div>
        )}
      </div>

      {/* Bottom bar: Captain Vera Lisitsyna quote + interactive Voiceover replay button */}
      <div className="border-t border-[#d4a853]/25 pt-2.5 text-xs">
        <div className="flex items-center justify-between gap-2">
          <div className="text-[10px] font-mono-tabular text-[#d4a853]">
            {fr ? 'CAPITAINE VERA LISITSYNA' : 'CAPTAIN VERA LISITSYNA'}
          </div>
          <button
            type="button"
            onClick={onReplayCaptainVoice}
            title={fr ? 'Écouter la voix du Capitaine (Interphone)' : 'Listen to Captain Voiceover (Intercom)'}
            className="px-2 py-0.5 rounded bg-[#211a14] hover:bg-[#30251c] text-[10px] font-mono-tabular text-[#d4a853] border border-[#d4a853]/35 transition-colors whitespace-nowrap"
          >
            {fr ? '🔊 Voix FR' : '🔊 Voice EN'}
          </button>
        </div>
        <p className="mt-1 italic text-[#e3d6be] leading-snug">
          “{projection.captainLine}”
        </p>
      </div>
    </section>
  );
};
