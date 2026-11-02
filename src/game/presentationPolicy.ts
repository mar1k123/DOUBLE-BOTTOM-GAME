import { CategoryID, SilhouetteKind } from './deckData';
import {
  Declaration,
  HingeZoneKind,
  InspectionVerdict,
  RoundPhase,
  RoundResolutionSummary,
  SlitSilhouetteHint,
} from './rules';

// Публичная проекция для внешнего экрана (Раздел 6.1):
// На уровне типов НЕ содержит реальных предметов чемодана, руки Курьера, скрытого предмета или колоды.
export interface PublicProjection {
  roundNumber: number;
  totalRounds: number;
  phase: RoundPhase;
  hingeZone: HingeZoneKind;
  courierName: string;
  inspectorName: string;
  courierMarks: number;
  inspectorMarks: number;
  inspectorClueTokens: number;
  courierCountry: 'altavia' | 'nordmark';
  courierPortraitIndex: number;
  declaration: Declaration | null;
  remainingSeconds: number;
  incompleteSealWarning: boolean;
  noClueTokensWarning: boolean;
  nervometerReading: {
    value: number;
    uncertainty: number;
    usedTremorFallback: boolean;
  } | null;
  verdictBanner: InspectionVerdict | null;
  resolutionSummary: RoundResolutionSummary | null;
  captainLine: string;
}

export type OuterScreenViewKind =
  | 'COURIER_PACKING_PUBLIC'
  | 'SEALED_STAMP'
  | 'NEGOTIATION_DOSSIER'
  | 'DECISION_BUTTONS'
  | 'SLIT_EYE_WATCHING'
  | 'INSPECTION_VERDICT_BANNER'
  | 'ROUND_END_SUMMARY';

export type InnerScreenViewKind =
  | 'POWERED_OFF'
  | 'PROMPT_OPEN_SUITCASE'
  | 'PACKING_INTERACTIVE'
  | 'SLIT_BLOCKED_NO_TOKENS'
  | 'SLIT_LEVEL_1_WEIGHT'
  | 'SLIT_LEVEL_2_SILHOUETTES'
  | 'SLIT_LEVEL_3_TINTED'
  | 'INSPECTION_COMMITTED_FULL'
  | 'ROUND_RESOLUTION_REPORT';

export interface InnerPresentationPayload {
  viewKind: InnerScreenViewKind;
  // Доступно только на уровнях 1-3 щёлочки:
  totalWeight?: number;
  expectedCategoryUnitWeight?: number;
  declaredCount?: number;
  visibleSilhouettes?: SilhouetteKind[];
  tintedHints?: SlitSilhouetteHint[];
  showFalseBottomTiltPrompt?: boolean;
}

export interface OuterPresentationPayload {
  viewKind: OuterScreenViewKind;
  projection: PublicProjection;
}

export interface DualScreenPolicyOutput {
  inner: InnerPresentationPayload;
  outer: OuterPresentationPayload;
}

/**
 * Чистая функция PresentationPolicy(phase, hingeZone, role) -> (innerContent, outerContent)
 * Строго соответствует матрице показа Раздела 6.2.
 * Внешний экран получает ТОЛЬКО PublicProjection и никогда не получает ничего из SecretState.
 */
export function evaluatePresentationPolicy(params: {
  projection: PublicProjection;
  slitUnlockedWithToken: boolean;
  totalCaseWeight: number;
  expectedUnitWeight: number;
  visibleSilhouettes: SilhouetteKind[];
  tintedHints: SlitSilhouetteHint[];
  falseBottomSearchActive: boolean;
}): DualScreenPolicyOutput {
  const {
    projection,
    slitUnlockedWithToken,
    totalCaseWeight,
    expectedUnitWeight,
    visibleSilhouettes,
    tintedHints,
    falseBottomSearchActive,
  } = params;

  let outerView: OuterScreenViewKind = 'COURIER_PACKING_PUBLIC';
  let innerPayload: InnerPresentationPayload = { viewKind: 'POWERED_OFF' };

  switch (projection.phase) {
    case 'DEAL':
      outerView = 'COURIER_PACKING_PUBLIC';
      innerPayload =
        projection.hingeZone === 'OPEN'
          ? { viewKind: 'PACKING_INTERACTIVE' }
          : { viewKind: 'PROMPT_OPEN_SUITCASE' };
      break;

    case 'PACKING':
      outerView = 'COURIER_PACKING_PUBLIC';
      innerPayload =
        projection.hingeZone === 'CLOSED'
          ? { viewKind: 'POWERED_OFF' }
          : { viewKind: 'PACKING_INTERACTIVE' };
      break;

    case 'SEALING':
      outerView = 'SEALED_STAMP';
      innerPayload = { viewKind: 'POWERED_OFF' };
      break;

    case 'NEGOTIATION':
      outerView = 'NEGOTIATION_DOSSIER';
      innerPayload = { viewKind: 'POWERED_OFF' };
      break;

    case 'DECISION':
      outerView = 'DECISION_BUTTONS';
      innerPayload = { viewKind: 'POWERED_OFF' };
      break;

    case 'PASS':
      outerView = 'ROUND_END_SUMMARY';
      innerPayload = { viewKind: 'ROUND_RESOLUTION_REPORT' };
      break;

    case 'INSPECTION':
      if (projection.hingeZone === 'CLOSED') {
        outerView = 'DECISION_BUTTONS';
        innerPayload = { viewKind: 'POWERED_OFF' };
      } else if (
        projection.hingeZone === 'SLIT_1' ||
        projection.hingeZone === 'SLIT_2' ||
        projection.hingeZone === 'SLIT_3'
      ) {
        outerView = 'SLIT_EYE_WATCHING';
        if (!slitUnlockedWithToken) {
          innerPayload = { viewKind: 'SLIT_BLOCKED_NO_TOKENS' };
        } else if (projection.hingeZone === 'SLIT_1') {
          innerPayload = {
            viewKind: 'SLIT_LEVEL_1_WEIGHT',
            totalWeight: totalCaseWeight,
            expectedCategoryUnitWeight: expectedUnitWeight,
            declaredCount: projection.declaration?.declaredCount ?? 0,
          };
        } else if (projection.hingeZone === 'SLIT_2') {
          innerPayload = {
            viewKind: 'SLIT_LEVEL_2_SILHOUETTES',
            totalWeight: totalCaseWeight,
            visibleSilhouettes,
          };
        } else {
          innerPayload = {
            viewKind: 'SLIT_LEVEL_3_TINTED',
            totalWeight: totalCaseWeight,
            tintedHints,
          };
        }
      } else {
        outerView = 'INSPECTION_VERDICT_BANNER';
        innerPayload = {
          viewKind: 'INSPECTION_COMMITTED_FULL',
          showFalseBottomTiltPrompt: falseBottomSearchActive,
        };
      }
      break;

    case 'RESOLUTION':
    case 'ROUND_END':
      outerView = 'ROUND_END_SUMMARY';
      innerPayload = { viewKind: 'ROUND_RESOLUTION_REPORT' };
      break;
  }

  return {
    inner: innerPayload,
    outer: {
      viewKind: outerView,
      projection,
    },
  };
}
