import { DEFAULT_TUNING, GameTuning } from './tuning';
import { CategoryID, DeckDataSpec, INITIAL_DECK_DATA, ItemDef, SilhouetteKind } from './deckData';

export type RoundPhase =
  | 'DEAL'
  | 'PACKING'
  | 'SEALING'
  | 'NEGOTIATION'
  | 'DECISION'
  | 'PASS'
  | 'INSPECTION'
  | 'RESOLUTION'
  | 'ROUND_END';

export type SlitPeekLevel = 0 | 1 | 2 | 3;

export type HingeZoneKind = 'CLOSED' | 'SLIT_1' | 'SLIT_2' | 'SLIT_3' | 'COMMITTED' | 'OPEN';

export interface CardInstance {
  uid: string;
  kind: 'item' | 'false_bottom';
  itemDef?: ItemDef;
}

export interface Declaration {
  category: CategoryID;
  declaredCount: number;
  bribeMarks: number;
}

export interface PackedCase {
  visibleItems: ItemDef[];
  hasFalseBottomCard: boolean;
  hiddenItem: ItemDef | null;
}

export type InspectionVerdict = 'CLEAN' | 'BUSTED';

export interface RoundResolutionSummary {
  wasInspected: boolean;
  bribeAccepted: boolean;
  falseBottomSearchedAndFound: boolean;
  verdictBanner: InspectionVerdict;
  passedItemsValue: number;
  confiscatedFinesPaid: number;
  compensationPaidByInspector: number;
  bribeTransferred: number;
  courierNetDelta: number;
  inspectorNetDelta: number;
  courierFinalMarks: number;
  inspectorFinalMarks: number;
  inspectorWonInspection: boolean;
}

// Deterministic PRNG (Mulberry32) with seed support (Section 11)
export class SeededRNG {
  private state: number;

  constructor(seed: number = 19641101) {
    this.state = seed >>> 0;
  }

  next(): number {
    let t = (this.state += 0x6d2b79f5);
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  }

  nextInt(maxExclusive: number): number {
    return Math.floor(this.next() * maxExclusive);
  }
}

export function buildShuffledDeck(spec: DeckDataSpec = INITIAL_DECK_DATA, seed: number = 19641101): CardInstance[] {
  const rng = new SeededRNG(seed);
  const deck: CardInstance[] = [];
  let seq = 1;

  for (const item of spec.items) {
    for (let i = 0; i < item.count; i++) {
      deck.push({
        uid: `card_${seq++}_${item.id}`,
        kind: 'item',
        itemDef: item,
      });
    }
  }

  for (const sp of spec.specials) {
    for (let i = 0; i < sp.count; i++) {
      deck.push({
        uid: `card_${seq++}_${sp.id}`,
        kind: 'false_bottom',
      });
    }
  }

  // Fisher-Yates shuffle
  for (let i = deck.length - 1; i > 0; i--) {
    const j = rng.nextInt(i + 1);
    const tmp = deck[i];
    deck[i] = deck[j];
    deck[j] = tmp;
  }

  return deck;
}

export function calculateTotalCaseWeight(packed: PackedCase): number {
  const visibleW = packed.visibleItems.reduce((acc, item) => acc + item.weight, 0);
  const hiddenW = packed.hiddenItem ? packed.hiddenItem.weight : 0;
  return visibleW + hiddenW;
}

export function isVisibleCargoHonest(packed: PackedCase, declaredCategory: CategoryID): boolean {
  if (packed.visibleItems.length === 0) return false;
  return packed.visibleItems.every((item) => item.category === declaredCategory);
}

// Hinge zones with hysteresis and irreversible commit (Sections 4.5, 5.1)
export function computeHingeZone(
  angleDeg: number,
  previousZone: HingeZoneKind,
  isCommittedInInspection: boolean,
  tuning: GameTuning = DEFAULT_TUNING
): HingeZoneKind {
  const clamped = Math.max(0, Math.min(tuning.maxHingeAngleDeg, angleDeg));
  const h = tuning.hysteresisDeg;

  // Section 4.5: "θ >= commitAngle (25°): inspection is official... Closing back below 15° does not cancel the inspection."
  if (isCommittedInInspection) {
    if (clamped >= tuning.openAngleDeg) return 'OPEN';
    return 'COMMITTED';
  }

  if (clamped >= tuning.openAngleDeg) {
    return 'OPEN';
  }
  if (previousZone === 'OPEN' && clamped >= tuning.openAngleDeg - h) {
    return 'OPEN';
  }

  if (clamped >= tuning.commitAngleDeg) {
    return 'COMMITTED';
  }
  if (previousZone === 'COMMITTED' && clamped >= tuning.commitAngleDeg - h) {
    return 'COMMITTED';
  }

  if (clamped < tuning.peekMinAngleDeg) {
    return 'CLOSED';
  }
  if (previousZone === 'CLOSED' && clamped <= tuning.peekMinAngleDeg + 0.5) {
    return 'CLOSED';
  }

  if (clamped < tuning.slitLevel1MaxAngleDeg) {
    return 'SLIT_1';
  }
  if (clamped < tuning.slitLevel2MaxAngleDeg) {
    return 'SLIT_2';
  }
  return 'SLIT_3';
}

export function slitLevelFromZone(zone: HingeZoneKind): SlitPeekLevel {
  switch (zone) {
    case 'SLIT_1':
      return 1;
    case 'SLIT_2':
      return 2;
    case 'SLIT_3':
      return 3;
    default:
      return 0;
  }
}

// Seal debounce protection (Section 4.4.3 and 5.4: holding θ <= 3° for 250 ms)
export function canCompleteSealing(
  angleDeg: number,
  holdDurationMs: number,
  packed: PackedCase,
  declaration: Declaration | null,
  tuning: GameTuning = DEFAULT_TUNING
): { sealed: boolean; reason?: 'incomplete_cargo' | 'angle_too_wide' | 'debounce_pending' } {
  if (angleDeg > tuning.sealAngleDeg) {
    return { sealed: false, reason: 'angle_too_wide' };
  }
  if (packed.visibleItems.length === 0 || !declaration || declaration.declaredCount !== packed.visibleItems.length) {
    return { sealed: false, reason: 'incomplete_cargo' };
  }
  if (holdDurationMs < tuning.sealHoldMs) {
    return { sealed: false, reason: 'debounce_pending' };
  }
  return { sealed: true };
}

// PASS phase (Section 4.4.6)
export function resolvePass(
  packed: PackedCase,
  declaration: Declaration,
  bribeAccepted: boolean,
  courierMarks: number,
  inspectorMarks: number
): RoundResolutionSummary {
  const visibleValue = packed.visibleItems.reduce((sum, item) => sum + item.value, 0);
  const hiddenValue = packed.hiddenItem ? packed.hiddenItem.value : 0;
  const totalPassedValue = visibleValue + hiddenValue;

  const effectiveBribe = bribeAccepted ? Math.min(courierMarks + totalPassedValue, Math.max(0, declaration.bribeMarks)) : 0;
  const courierFinal = Math.max(0, courierMarks + totalPassedValue - effectiveBribe);
  const inspectorFinal = Math.max(0, inspectorMarks + effectiveBribe);

  return {
    wasInspected: false,
    bribeAccepted,
    falseBottomSearchedAndFound: false,
    verdictBanner: 'CLEAN',
    passedItemsValue: totalPassedValue,
    confiscatedFinesPaid: 0,
    compensationPaidByInspector: 0,
    bribeTransferred: effectiveBribe,
    courierNetDelta: courierFinal - courierMarks,
    inspectorNetDelta: inspectorFinal - inspectorMarks,
    courierFinalMarks: courierFinal,
    inspectorFinalMarks: inspectorFinal,
    inspectorWonInspection: false,
  };
}

// INSPECTION -> RESOLUTION phase (Section 4.6)
export function resolveInspection(
  packed: PackedCase,
  declaration: Declaration,
  falseBottomFound: boolean,
  courierMarks: number,
  inspectorMarks: number,
  tuning: GameTuning = DEFAULT_TUNING
): RoundResolutionSummary {
  let passedValue = 0;
  let rawFines = 0;
  let anyViolationFound = false;

  for (const item of packed.visibleItems) {
    if (item.category !== null && item.category === declaration.category) {
      passedValue += item.value;
    } else {
      rawFines += item.fine;
      anyViolationFound = true;
    }
  }

  if (packed.hiddenItem) {
    if (falseBottomFound) {
      rawFines += packed.hiddenItem.fine;
      anyViolationFound = true;
    } else {
      passedValue += packed.hiddenItem.value;
    }
  }

  const allVisibleHonest = isVisibleCargoHonest(packed, declaration.category);
  let shouldPayCompensation = false;
  if (allVisibleHonest) {
    if (!packed.hiddenItem) {
      shouldPayCompensation = true;
    } else if (!falseBottomFound && packed.hiddenItem.category !== null) {
      // "or it is not found, and the item inside it is legal"
      shouldPayCompensation = true;
    }
  }

  const n = packed.visibleItems.length;
  const rawCompensation = shouldPayCompensation ? tuning.compensationPerItem * n : 0;

  // Marks never drop below zero; unpaid remainder is forgiven
  const courierAvailableBeforeFine = courierMarks + passedValue;
  const effectiveFinePaid = Math.min(courierAvailableBeforeFine, rawFines);

  const inspectorAvailableBeforeComp = inspectorMarks + effectiveFinePaid;
  const effectiveCompensationPaid = Math.min(inspectorAvailableBeforeComp, rawCompensation);

  const courierFinal = Math.max(0, courierAvailableBeforeFine - effectiveFinePaid + effectiveCompensationPaid);
  const inspectorFinal = Math.max(0, inspectorAvailableBeforeComp - effectiveCompensationPaid);

  const verdictBanner: InspectionVerdict = anyViolationFound ? 'BUSTED' : 'CLEAN';

  return {
    wasInspected: true,
    bribeAccepted: false,
    falseBottomSearchedAndFound: Boolean(falseBottomFound && packed.hiddenItem),
    verdictBanner,
    passedItemsValue: passedValue,
    confiscatedFinesPaid: effectiveFinePaid,
    compensationPaidByInspector: effectiveCompensationPaid,
    bribeTransferred: 0,
    courierNetDelta: courierFinal - courierMarks,
    inspectorNetDelta: inspectorFinal - inspectorMarks,
    courierFinalMarks: courierFinal,
    inspectorFinalMarks: inspectorFinal,
    inspectorWonInspection: anyViolationFound,
  };
}

// Nervometer formula (Section 7.3):
// N = clamp(50 + k * mean(|z|), 0, 100), EMA smoothing, plus random ±noiseAmplitude
export interface FaceFeatureVector {
  earBlinkRate: number;
  mouthCornerLift: number;
  marMouthOpen: number;
  browEyeDistance: number;
  headMotionAmplitude: number;
  gazeShiftProxy: number;
}

export interface FaceCalibrationBaseline {
  mean: FaceFeatureVector;
  std: FaceFeatureVector;
}

export function computeNervometerScore(
  sample: FaceFeatureVector,
  baseline: FaceCalibrationBaseline,
  previousEma: number | null,
  noiseSampleMinus1To1: number, // in range [-1, 1]
  tuning: GameTuning = DEFAULT_TUNING
): { rawScore: number; smoothedEma: number; displayedScore: number; meanAbsZ: number } {
  const keys: (keyof FaceFeatureVector)[] = [
    'earBlinkRate',
    'mouthCornerLift',
    'marMouthOpen',
    'browEyeDistance',
    'headMotionAmplitude',
    'gazeShiftProxy',
  ];

  let sumAbsZ = 0;
  for (const key of keys) {
    const sigma = Math.max(0.001, baseline.std[key]);
    const z = (sample[key] - baseline.mean[key]) / sigma;
    sumAbsZ += Math.abs(z);
  }

  const meanAbsZ = sumAbsZ / keys.length;
  const centeredZ = meanAbsZ - 0.85;
  const rawScore = Math.max(0, Math.min(100, tuning.nervometerBaseValue + tuning.nervometerZScaleK * centeredZ));

  const alpha = tuning.nervometerEmaAlpha;
  const smoothedEma = previousEma === null ? rawScore : previousEma * (1 - alpha) + rawScore * alpha;
  const noise = noiseSampleMinus1To1 * tuning.nervometerNoiseAmplitude;
  const displayedScore = Math.round(Math.max(0, Math.min(100, smoothedEma + noise)));

  return { rawScore, smoothedEma, displayedScore, meanAbsZ };
}

// Slit Level 3 color hints (18°–25°) with tintAccuracy = 0.75
export interface SlitSilhouetteHint {
  silhouette: SilhouetteKind;
  hintedLegalGreen: boolean;
}

export function buildSlitLevel3Hints(
  packed: PackedCase,
  declaredCategory: CategoryID,
  seed: number,
  tuning: GameTuning = DEFAULT_TUNING
): SlitSilhouetteHint[] {
  const rng = new SeededRNG(seed);
  return packed.visibleItems.map((item) => {
    const actuallyLegalInDeclared = item.category !== null && item.category === declaredCategory;
    const isAccurate = rng.next() <= tuning.tintAccuracy;
    const hintedLegalGreen = isAccurate ? actuallyLegalInDeclared : !actuallyLegalInDeclared;
    return {
      silhouette: item.silhouette,
      hintedLegalGreen,
    };
  });
}
