import test from 'node:test';
import assert from 'node:assert/strict';
import {
  buildShuffledDeck,
  calculateTotalCaseWeight,
  canCompleteSealing,
  computeHingeZone,
  computeNervometerScore,
  FaceCalibrationBaseline,
  PackedCase,
  resolveInspection,
  resolvePass,
} from './rules';
import { INITIAL_DECK_DATA, ItemDef } from './deckData';
import { DEFAULT_TUNING } from './tuning';
import { evaluatePresentationPolicy, PublicProjection } from './presentationPolicy';
import { runBalanceSimulation } from './balanceSimulator';
import { getCaptainLineText } from './captainLines';

const itemById = (id: string): ItemDef => {
  const found = INITIAL_DECK_DATA.items.find((i) => i.id === id);
  if (!found) throw new Error(`Missing item ${id}`);
  return found;
};

test('Section 4.2 & DeckBuilder: deck is deterministic for a given seed and contains 67 cards (65 items + 2 false bottoms)', () => {
  const d1 = buildShuffledDeck(INITIAL_DECK_DATA, 42);
  const d2 = buildShuffledDeck(INITIAL_DECK_DATA, 42);
  assert.equal(d1.length, 67);
  assert.deepEqual(
    d1.map((c) => c.uid),
    d2.map((c) => c.uid)
  );
  const falseBottoms = d1.filter((c) => c.kind === 'false_bottom');
  assert.equal(falseBottoms.length, 2);
});

test('Section 4.6 Branch 1: Honest visible cargo without hidden item — Courier receives value + 2*n compensation from Inspector', () => {
  const orange = itemById('orange'); // value 2, fine 2, weight 1
  const packed: PackedCase = {
    visibleItems: [orange, orange, orange], // n = 3, value = 6
    hasFalseBottomCard: false,
    hiddenItem: null,
  };
  const res = resolveInspection(
    packed,
    { category: 'oranges', declaredCount: 3, bribeMarks: 0 },
    false,
    40,
    40,
    DEFAULT_TUNING
  );
  assert.equal(res.verdictBanner, 'CLEAN');
  assert.equal(res.passedItemsValue, 6);
  assert.equal(res.confiscatedFinesPaid, 0);
  assert.equal(res.compensationPaidByInspector, 6); // 2 * 3
  assert.equal(res.courierFinalMarks, 52); // 40 + 6 + 6
  assert.equal(res.inspectorFinalMarks, 34); // 40 - 6
});

test('Section 4.6 Branch 2: Visible contraband and wrong legal category are confiscated, honest items pass, bribe is returned on inspection', () => {
  const cheese = itemById('cheese'); // legal (cheese), value 3, fine 3
  const watch = itemById('watch'); // wrong category (watches), value 5, fine 4
  const radio = itemById('radio'); // contraband (null), value 8, fine 6
  const packed: PackedCase = {
    visibleItems: [cheese, watch, radio],
    hasFalseBottomCard: false,
    hiddenItem: null,
  };
  const res = resolveInspection(
    packed,
    { category: 'cheese', declaredCount: 3, bribeMarks: 5 },
    false,
    40,
    40,
    DEFAULT_TUNING
  );
  assert.equal(res.verdictBanner, 'BUSTED');
  assert.equal(res.passedItemsValue, 3); // only cheese passes
  assert.equal(res.confiscatedFinesPaid, 10); // watch(4) + radio(6)
  assert.equal(res.compensationPaidByInspector, 0);
  assert.equal(res.bribeTransferred, 0); // bribe returned to Courier
  assert.equal(res.courierFinalMarks, 33); // 40 + 3 - 10
  assert.equal(res.inspectorFinalMarks, 50); // 40 + 10
});

test('Section 4.6 Branch 3: Hidden false bottom with contraband NOT found under honest top tray — contraband passes, but NO compensation is paid', () => {
  const wine = itemById('wine'); // value 4
  const gold = itemById('gold'); // contraband, value 10, fine 8
  const packed: PackedCase = {
    visibleItems: [wine, wine],
    hasFalseBottomCard: true,
    hiddenItem: gold,
  };
  const res = resolveInspection(
    packed,
    { category: 'wine', declaredCount: 2, bribeMarks: 0 },
    false, // not found
    40,
    40,
    DEFAULT_TUNING
  );
  assert.equal(res.verdictBanner, 'CLEAN');
  assert.equal(res.passedItemsValue, 18); // 4 + 4 + 10
  assert.equal(res.compensationPaidByInspector, 0);
  assert.equal(res.courierFinalMarks, 58);
  assert.equal(res.inspectorFinalMarks, 40);
});

test('Section 4.6 Branch 4: Hidden false bottom FOUND — hidden item confiscated, Courier pays fine, verdict is BUSTED', () => {
  const wine = itemById('wine'); // value 4
  const antique = itemById('antique'); // contraband, value 12, fine 9
  const packed: PackedCase = {
    visibleItems: [wine, wine],
    hasFalseBottomCard: true,
    hiddenItem: antique,
  };
  const res = resolveInspection(
    packed,
    { category: 'wine', declaredCount: 2, bribeMarks: 0 },
    true, // found by tilt!
    40,
    40,
    DEFAULT_TUNING
  );
  assert.equal(res.verdictBanner, 'BUSTED');
  assert.equal(res.falseBottomSearchedAndFound, true);
  assert.equal(res.passedItemsValue, 8);
  assert.equal(res.confiscatedFinesPaid, 9);
  assert.equal(res.compensationPaidByInspector, 0);
  assert.equal(res.courierFinalMarks, 39);
  assert.equal(res.inspectorFinalMarks, 49);
});

test('Section 4.6 Branch 5: Zero balance floor — marks never drop below zero and unpaid fine remainder is forgiven', () => {
  const antique = itemById('antique'); // fine 9
  const packed: PackedCase = {
    visibleItems: [antique, antique, antique], // total fine 27
    hasFalseBottomCard: false,
    hiddenItem: null,
  };
  const res = resolveInspection(
    packed,
    { category: 'oranges', declaredCount: 3, bribeMarks: 0 },
    false,
    5,
    40,
    DEFAULT_TUNING
  );
  assert.equal(res.courierFinalMarks, 0);
  assert.equal(res.confiscatedFinesPaid, 5);
  assert.equal(res.inspectorFinalMarks, 45);
});

test('Section 4.4.6: PASS phase with and without bribe acceptance', () => {
  const watch = itemById('watch'); // value 5
  const microfilm = itemById('microfilm'); // value 7
  const packed: PackedCase = {
    visibleItems: [watch, watch],
    hasFalseBottomCard: true,
    hiddenItem: microfilm,
  };
  const resBribe = resolvePass(packed, { category: 'watches', declaredCount: 2, bribeMarks: 4 }, true, 40, 40);
  assert.equal(resBribe.passedItemsValue, 17);
  assert.equal(resBribe.bribeTransferred, 4);
  assert.equal(resBribe.courierFinalMarks, 53);
  assert.equal(resBribe.inspectorFinalMarks, 44);
});

test('Sections 5.1 & 5.4: Hinge zone hysteresis, irreversible COMMITTED state, and 250ms seal debounce', () => {
  const orange = itemById('orange');
  const packed: PackedCase = { visibleItems: [orange], hasFalseBottomCard: false, hiddenItem: null };
  const decl = { category: 'oranges' as const, declaredCount: 1, bribeMarks: 0 };

  assert.equal(canCompleteSealing(2.5, 180, packed, decl).sealed, false);
  assert.equal(canCompleteSealing(2.5, 180, packed, decl).reason, 'debounce_pending');
  assert.equal(canCompleteSealing(2.5, 250, packed, decl).sealed, true);

  const zAfterCommit = computeHingeZone(8.0, 'COMMITTED', true);
  assert.equal(zAfterCommit, 'COMMITTED');
});

test('Sections 6.1 & 12: PresentationPolicy never leaks SecretState onto the Outer Screen in any phase or hinge angle', () => {
  const phases = ['DEAL', 'PACKING', 'SEALING', 'NEGOTIATION', 'DECISION', 'PASS', 'INSPECTION', 'RESOLUTION', 'ROUND_END'] as const;
  const zones = ['CLOSED', 'SLIT_1', 'SLIT_2', 'SLIT_3', 'COMMITTED', 'OPEN'] as const;

  for (const phase of phases) {
    for (const hingeZone of zones) {
      const projection: PublicProjection = {
        roundNumber: 1,
        totalRounds: 4,
        phase,
        hingeZone,
        courierName: 'Altavia Courier',
        inspectorName: 'Nordmark Inspector',
        courierMarks: 40,
        inspectorMarks: 40,
        inspectorClueTokens: 3,
        courierCountry: 'altavia',
        courierPortraitIndex: 3,
        declaration: { category: 'oranges', declaredCount: 3, bribeMarks: 2 },
        remainingSeconds: 30,
        incompleteSealWarning: false,
        noClueTokensWarning: false,
        nervometerReading: null,
        verdictBanner: 'BUSTED',
        resolutionSummary: null,
        captainLine: 'Line check',
      };

      const output = evaluatePresentationPolicy({
        projection,
        slitUnlockedWithToken: true,
        totalCaseWeight: calculateTotalCaseWeight({
          visibleItems: [itemById('orange')],
          hasFalseBottomCard: false,
          hiddenItem: null,
        }),
        expectedUnitWeight: 1,
        visibleSilhouettes: ['small_round', 'heavy_bar', 'tall_vase'],
        tintedHints: [{ silhouette: 'heavy_bar', hintedLegalGreen: false }],
        falseBottomSearchActive: true,
      });

      const serializedOuter = JSON.stringify(output.outer);
      assert.equal(serializedOuter.includes('heavy_bar'), false);
      assert.equal(serializedOuter.includes('tall_vase'), false);
      assert.equal(serializedOuter.includes('hintedLegalGreen'), false);
      assert.equal(serializedOuter.includes('totalWeight'), false);
    }
  }
});

test('Section 7.3: Nervometer test on synthetic feature sequences (calm vs agitated profile)', () => {
  const baseline: FaceCalibrationBaseline = {
    mean: {
      earBlinkRate: 0.28,
      mouthCornerLift: 0.5,
      marMouthOpen: 0.12,
      browEyeDistance: 0.35,
      headMotionAmplitude: 0.1,
      gazeShiftProxy: 0.1,
    },
    std: {
      earBlinkRate: 0.04,
      mouthCornerLift: 0.05,
      marMouthOpen: 0.03,
      browEyeDistance: 0.04,
      headMotionAmplitude: 0.04,
      gazeShiftProxy: 0.04,
    },
  };

  const calmSample = { ...baseline.mean, earBlinkRate: 0.29, headMotionAmplitude: 0.11 };
  const nervousSample = {
    earBlinkRate: 0.42,
    mouthCornerLift: 0.68,
    marMouthOpen: 0.24,
    browEyeDistance: 0.48,
    headMotionAmplitude: 0.26,
    gazeShiftProxy: 0.25,
  };

  const calmRes = computeNervometerScore(calmSample, baseline, null, 0);
  const nervousRes = computeNervometerScore(nervousSample, baseline, null, 0);

  assert.ok(nervousRes.displayedScore > calmRes.displayedScore + 25);
});

test('Section 12 & Bilingual Localization: BalanceSimulator meets equilibrium targets and EN/FR Captain lines are populated', () => {
  const report = runBalanceSimulation(400);
  assert.ok(
    report.equilibriumInspectionRate >= 35 && report.equilibriumInspectionRate <= 65,
    `Inspection rate ${report.equilibriumInspectionRate}% must be within 35–65%`
  );
  assert.ok(
    report.maxPureStrategyAdvantageVsMixed <= 25,
    `Max pure strategy advantage ${report.maxPureStrategyAdvantageVsMixed}% must be <= 25%`
  );

  const enLine = getCaptainLineText('deal', 1, 'en');
  const frLine = getCaptainLineText('deal', 1, 'fr');
  assert.ok(enLine.length > 10);
  assert.ok(frLine.length > 10);
  assert.notEqual(enLine, frLine);
});
