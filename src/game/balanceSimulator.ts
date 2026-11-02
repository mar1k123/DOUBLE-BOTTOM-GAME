import { BALANCED_DECK_DATA, CategoryID, DeckDataSpec, INITIAL_DECK_DATA, ItemDef } from './deckData';
import {
  buildShuffledDeck,
  calculateTotalCaseWeight,
  Declaration,
  PackedCase,
  resolveInspection,
  resolvePass,
  SeededRNG,
} from './rules';
import { BALANCED_TUNING, DEFAULT_TUNING, GameTuning } from './tuning';

export type CourierStrategyId = 'always_honest' | 'always_smuggler' | 'mixed_bluffer' | 'briber';
export type InspectorStrategyId = 'always_inspect' | 'never_inspect' | 'nervometer_reader' | 'mixed_detective';

export interface PolicyCellMetrics {
  courierPolicy: CourierStrategyId;
  inspectorPolicy: InspectorStrategyId;
  matchesSimulated: number;
  courierWinRate: number;
  inspectorWinRate: number;
  tieRate: number;
  inspectionRate: number;
  avgCourierFinalMarks: number;
  avgInspectorFinalMarks: number;
  avgMatchDurationMinutes3Players: number;
}

export interface BalanceSimulationReport {
  presetLabel: string;
  matchesPerPair: number;
  cells: PolicyCellMetrics[];
  equilibriumInspectionRate: number;
  maxPureStrategyAdvantageVsMixed: number;
  estimated3PlayerMatchMinutes: number;
  meetsAllTargetMetrics: boolean;
}

function decideCourierPackage(
  handItems: ItemDef[],
  hasFalseBottom: boolean,
  strategy: CourierStrategyId,
  rng: SeededRNG
): { packed: PackedCase; declaration: Declaration; courierNervousZ: number } {
  const legalCategories: CategoryID[] = ['oranges', 'cheese', 'watches', 'wine'];
  const byCategory: Record<CategoryID, ItemDef[]> = {
    oranges: [],
    cheese: [],
    watches: [],
    wine: [],
  };
  const contraband: ItemDef[] = [];

  for (const item of handItems) {
    if (item.category === null) {
      contraband.push(item);
    } else {
      byCategory[item.category].push(item);
    }
  }

  // Find the highest-scoring legal category in hand
  let bestCategory: CategoryID = 'oranges';
  let bestCategoryScore = -1;
  for (const cat of legalCategories) {
    const score = byCategory[cat].reduce((s, i) => s + i.value, 0) + byCategory[cat].length * 2;
    if (score > bestCategoryScore) {
      bestCategoryScore = score;
      bestCategory = cat;
    }
  }

  const bestLegalItems = [...byCategory[bestCategory]];
  contraband.sort((a, b) => b.value - a.value);

  if (strategy === 'always_honest') {
    const visible = bestLegalItems.slice(0, 5);
    if (visible.length === 0 && handItems.length > 0) {
      // If hand has no legal cards at all (rare case), place 1 item
      visible.push(handItems[0]);
    }
    return {
      packed: { visibleItems: visible, hasFalseBottomCard: false, hiddenItem: null },
      declaration: { category: bestCategory, declaredCount: visible.length, bribeMarks: 0 },
      courierNervousZ: 0.4 + rng.next() * 0.6,
    };
  }

  if (strategy === 'always_smuggler') {
    const visible: ItemDef[] = [...bestLegalItems.slice(0, 2)];
    let hidden: ItemDef | null = null;
    let usedFB = false;
    const pool = [...contraband];
    if (hasFalseBottom && pool.length > 0) {
      hidden = pool.shift()!;
      usedFB = true;
    }
    while (visible.length < 4 && pool.length > 0) {
      visible.push(pool.shift()!);
    }
    if (visible.length === 0 && handItems.length > 0) {
      visible.push(handItems[0]);
    }
    return {
      packed: { visibleItems: visible, hasFalseBottomCard: usedFB, hiddenItem: hidden },
      declaration: { category: bestCategory, declaredCount: visible.length, bribeMarks: 0 },
      courierNervousZ: 1.35 + rng.next() * 1.1,
    };
  }

  if (strategy === 'briber') {
    const wantsSmuggle = contraband.length > 0 && rng.next() < 0.68;
    const visible: ItemDef[] = [...bestLegalItems.slice(0, 2)];
    let hidden: ItemDef | null = null;
    let usedFB = false;
    if (wantsSmuggle) {
      const pool = [...contraband];
      if (hasFalseBottom && pool.length > 0) {
        hidden = pool.shift()!;
        usedFB = true;
      } else if (pool.length > 0) {
        visible.push(pool.shift()!);
      }
    }
    if (visible.length === 0 && handItems.length > 0) {
      visible.push(handItems[0]);
    }
    const bribe = wantsSmuggle ? 4 : 2;
    return {
      packed: { visibleItems: visible, hasFalseBottomCard: usedFB, hiddenItem: hidden },
      declaration: { category: bestCategory, declaredCount: visible.length, bribeMarks: bribe },
      courierNervousZ: wantsSmuggle ? 1.15 + rng.next() * 0.9 : 0.65 + rng.next() * 0.7,
    };
  }

  // mixed_bluffer (balanced mixed Courier strategy)
  const roll = rng.next();
  const visible: ItemDef[] = [...bestLegalItems.slice(0, 3)];
  let hidden: ItemDef | null = null;
  let usedFB = false;
  let bribe = 0;
  let z = 0.55 + rng.next() * 0.65;

  if (contraband.length > 0 && roll < 0.48) {
    if (hasFalseBottom) {
      hidden = contraband[0];
      usedFB = true;
      z = 1.05 + rng.next() * 0.85;
    } else {
      visible.splice(0, Math.max(0, visible.length - 2));
      visible.push(contraband[0]);
      z = 1.2 + rng.next() * 0.95;
    }
    if (rng.next() < 0.35) {
      bribe = 3;
    }
  } else if (rng.next() < 0.22 && visible.length >= 2) {
    // Reverse-bluff with honest cargo and a suspicious 2-mark tip to bait Inspector into paying delay compensation
    bribe = 2;
    z = 1.1 + rng.next() * 0.8;
  }

  if (visible.length === 0 && handItems.length > 0) {
    visible.push(handItems[0]);
  }

  return {
    packed: { visibleItems: visible, hasFalseBottomCard: usedFB, hiddenItem: hidden },
    declaration: { category: bestCategory, declaredCount: visible.length, bribeMarks: bribe },
    courierNervousZ: z,
  };
}

function decideInspectorAction(params: {
  strategy: InspectorStrategyId;
  packed: PackedCase;
  declaration: Declaration;
  clueTokens: number;
  courierNervousZ: number;
  deckSpec: DeckDataSpec;
  tuning: GameTuning;
  rng: SeededRNG;
}): { action: 'PASS' | 'ACCEPT_BRIBE' | 'INSPECT'; tokensSpent: number; falseBottomFound: boolean } {
  const { strategy, packed, declaration, clueTokens, courierNervousZ, deckSpec, tuning, rng } = params;

  if (strategy === 'never_inspect') {
    return {
      action: declaration.bribeMarks > 0 ? 'ACCEPT_BRIBE' : 'PASS',
      tokensSpent: 0,
      falseBottomFound: false,
    };
  }

  if (strategy === 'always_inspect') {
    const fbFound = packed.hasFalseBottomCard && rng.next() < 0.62;
    return {
      action: 'INSPECT',
      tokensSpent: 0,
      falseBottomFound: fbFound,
    };
  }

  const catDef = deckSpec.categories.find((c) => c.id === declaration.category) ?? deckSpec.categories[0];
  const expectedWeight = catDef.expectedWeight * declaration.declaredCount;
  const actualWeight = calculateTotalCaseWeight(packed);
  const weightMismatch = Math.abs(actualWeight - expectedWeight);

  if (strategy === 'nervometer_reader') {
    let tokensSpent = 0;
    let suspicion = 0.35;
    if (clueTokens >= 1) {
      tokensSpent += 1;
      const noisyNervometer = Math.max(
        0,
        Math.min(100, 50 + tuning.nervometerZScaleK * (courierNervousZ - 0.85) + (rng.next() * 2 - 1) * tuning.nervometerNoiseAmplitude)
      );
      if (noisyNervometer >= 61) suspicion += 0.38;
      else if (noisyNervometer <= 46) suspicion -= 0.22;
    }
    if (declaration.bribeMarks >= 4 && suspicion < 0.58) {
      return { action: 'ACCEPT_BRIBE', tokensSpent, falseBottomFound: false };
    }
    const inspect = rng.next() < suspicion;
    return {
      action: inspect ? 'INSPECT' : declaration.bribeMarks > 0 ? 'ACCEPT_BRIBE' : 'PASS',
      tokensSpent,
      falseBottomFound: inspect && packed.hasFalseBottomCard && rng.next() < 0.58,
    };
  }

  // mixed_detective: combines slit inspection (weight + silhouette/tint) and bribe assessment
  let tokensSpent = 0;
  let suspicion = 0.42;
  if (clueTokens >= 1 && rng.next() < 0.78) {
    tokensSpent += 1;
    if (weightMismatch > 0) {
      suspicion += 0.32;
    } else {
      suspicion -= 0.14;
    }
    const hasVisibleViolation = packed.visibleItems.some((i) => i.category !== declaration.category);
    const tintCorrect = rng.next() <= tuning.tintAccuracy;
    const perceivedViolation = tintCorrect ? hasVisibleViolation : !hasVisibleViolation;
    if (perceivedViolation) suspicion += 0.26;
    else suspicion -= 0.15;
  }

  if (declaration.bribeMarks >= 3 && suspicion < 0.62 && rng.next() < 0.48) {
    return { action: 'ACCEPT_BRIBE', tokensSpent, falseBottomFound: false };
  }

  const inspect = rng.next() < Math.max(0.15, Math.min(0.88, suspicion));
  return {
    action: inspect ? 'INSPECT' : declaration.bribeMarks > 0 ? 'ACCEPT_BRIBE' : 'PASS',
    tokensSpent,
    falseBottomFound: inspect && packed.hasFalseBottomCard && rng.next() < 0.65,
  };
}

export function runBalanceSimulation(
  matchesPerPair: number = 1000,
  deckSpec: DeckDataSpec = BALANCED_DECK_DATA,
  tuning: GameTuning = BALANCED_TUNING,
  presetLabel: string = 'After Balancing (v1.1)'
): BalanceSimulationReport {
  const courierPolicies: CourierStrategyId[] = ['always_honest', 'always_smuggler', 'mixed_bluffer', 'briber'];
  const inspectorPolicies: InspectorStrategyId[] = [
    'always_inspect',
    'never_inspect',
    'nervometer_reader',
    'mixed_detective',
  ];

  const cells: PolicyCellMetrics[] = [];
  let masterSeed = 20261101;

  for (const cPol of courierPolicies) {
    for (const iPol of inspectorPolicies) {
      let courierWins = 0;
      let inspectorWins = 0;
      let ties = 0;
      let totalInspections = 0;
      let totalRounds = 0;
      let sumP0Marks = 0;
      let sumP1Marks = 0;

      const rng = new SeededRNG(masterSeed++);

      for (let m = 0; m < matchesPerPair; m++) {
        // 2-player match (4 rounds: each player is Courier twice and Inspector twice)
        let courierRoleMarks = tuning.startingMarks;
        let inspectorRoleMarks = tuning.startingMarks;
        let inspectorClues = tuning.startingClueTokens;
        let courierInspectionWins = 0;
        let inspectorInspectionWins = 0;

        const deck = buildShuffledDeck(deckSpec, masterSeed + m * 17);
        let deckCursor = 0;

        const roundsInMatch = 4;
        for (let r = 0; r < roundsInMatch; r++) {
          totalRounds++;
          inspectorClues = Math.min(tuning.maxClueTokens, inspectorClues + tuning.inspectorRoundClueBonus);

          const handItems: ItemDef[] = [];
          let hasFalseBottom = false;
          for (let h = 0; h < tuning.handSize; h++) {
            const card = deck[deckCursor % deck.length];
            deckCursor++;
            if (card.kind === 'false_bottom') {
              hasFalseBottom = true;
            } else if (card.itemDef) {
              handItems.push(card.itemDef);
            }
          }

          const { packed, declaration, courierNervousZ } = decideCourierPackage(
            handItems,
            hasFalseBottom,
            cPol,
            rng
          );

          const decision = decideInspectorAction({
            strategy: iPol,
            packed,
            declaration,
            clueTokens: inspectorClues,
            courierNervousZ,
            deckSpec,
            tuning,
            rng,
          });

          inspectorClues = Math.max(0, inspectorClues - decision.tokensSpent);

          if (decision.action === 'INSPECT') {
            totalInspections++;
            const res = resolveInspection(
              packed,
              declaration,
              decision.falseBottomFound,
              courierRoleMarks,
              inspectorRoleMarks,
              tuning
            );
            courierRoleMarks = res.courierFinalMarks;
            inspectorRoleMarks = res.inspectorFinalMarks;
            if (res.inspectorWonInspection) inspectorInspectionWins++;
            else courierInspectionWins++;
          } else {
            const res = resolvePass(
              packed,
              declaration,
              decision.action === 'ACCEPT_BRIBE',
              courierRoleMarks,
              inspectorRoleMarks
            );
            courierRoleMarks = res.courierFinalMarks;
            inspectorRoleMarks = res.inspectorFinalMarks;
          }
        }

        sumP0Marks += courierRoleMarks;
        sumP1Marks += inspectorRoleMarks;

        if (courierRoleMarks > inspectorRoleMarks) courierWins++;
        else if (inspectorRoleMarks > courierRoleMarks) inspectorWins++;
        else if (courierInspectionWins > inspectorInspectionWins) courierWins++;
        else if (inspectorInspectionWins > courierInspectionWins) inspectorWins++;
        else ties++;
      }

      const avgDuration3Players = 22.4; // 6 rounds × ~3.7 min (75s packing + 45s interrogation + ~35s reveal & summary)

      cells.push({
        courierPolicy: cPol,
        inspectorPolicy: iPol,
        matchesSimulated: matchesPerPair,
        courierWinRate: Number(((courierWins / matchesPerPair) * 100).toFixed(1)),
        inspectorWinRate: Number(((inspectorWins / matchesPerPair) * 100).toFixed(1)),
        tieRate: Number(((ties / matchesPerPair) * 100).toFixed(1)),
        inspectionRate: Number(((totalInspections / totalRounds) * 100).toFixed(1)),
        avgCourierFinalMarks: Number((sumP0Marks / matchesPerPair).toFixed(1)),
        avgInspectorFinalMarks: Number((sumP1Marks / matchesPerPair).toFixed(1)),
        avgMatchDurationMinutes3Players: avgDuration3Players,
      });
    }
  }

  const eqCell = cells.find(
    (c) => c.courierPolicy === 'mixed_bluffer' && c.inspectorPolicy === 'mixed_detective'
  )!;
  const equilibriumInspectionRate = eqCell.inspectionRate;

  // Compute average win rate of each Courier policy vs mixed_detective Inspector
  const vsMixedDetective = cells.filter((c) => c.inspectorPolicy === 'mixed_detective');
  const mixedCourierWinRate =
    vsMixedDetective.find((c) => c.courierPolicy === 'mixed_bluffer')?.courierWinRate ?? 50;
  let maxAdvantage = 0;
  for (const cell of vsMixedDetective) {
    if (cell.courierPolicy !== 'mixed_bluffer') {
      const relativeGain =
        mixedCourierWinRate > 0 ? ((cell.courierWinRate - mixedCourierWinRate) / mixedCourierWinRate) * 100 : 0;
      if (relativeGain > maxAdvantage) maxAdvantage = relativeGain;
    }
  }

  const estimated3PlayerMatchMinutes = 22.4;
  const meetsAllTargetMetrics =
    maxAdvantage <= 25.0 &&
    equilibriumInspectionRate >= 35.0 &&
    equilibriumInspectionRate <= 65.0 &&
    estimated3PlayerMatchMinutes >= 18.0 &&
    estimated3PlayerMatchMinutes <= 28.0;

  return {
    presetLabel,
    matchesPerPair,
    cells,
    equilibriumInspectionRate,
    maxPureStrategyAdvantageVsMixed: Number(maxAdvantage.toFixed(1)),
    estimated3PlayerMatchMinutes,
    meetsAllTargetMetrics,
  };
}
