// Single registry of numeric game-design constants (mirrors Sources/Core/Tuning.swift)
export interface GameTuning {
  minPlayers: number;
  maxPlayers: number;
  couriersPerPlayer: number;
  startingMarks: number;
  startingClueTokens: number;
  maxClueTokens: number;
  inspectorRoundClueBonus: number;
  handSize: number;
  maxMulliganCards: number;
  maxVisibleSlots: number;
  maxHiddenSlotsWithFalseBottom: number;
  compensationPerItem: number;
  packingSeconds: number;
  negotiationSeconds: number;
  falseBottomSearchSeconds: number;
  demoRoundSeconds: number;
  sealAngleDeg: number;
  peekMinAngleDeg: number;
  slitLevel1MaxAngleDeg: number;
  slitLevel2MaxAngleDeg: number;
  commitAngleDeg: number;
  postCommitLockAngleDeg: number;
  openAngleDeg: number;
  maxHingeAngleDeg: number;
  hysteresisDeg: number;
  sealHoldMs: number;
  slitHapticTickStepDeg: number;
  slitClueCost: number;
  tintAccuracy: number;
  falseBottomRequiredTilts: number;
  falseBottomTiltAmplitudeDeg: number;
  xrayClueCost: number;
  calibrationSeconds: number;
  scanSeconds: number;
  nervometerBaseValue: number;
  nervometerZScaleK: number;
  nervometerEmaAlpha: number;
  nervometerNoiseAmplitude: number;
  nervometerUncertaintyBandWidth: number;
  innerScreenWidthPt: number;
  innerScreenHeightPt: number;
  outerScreenWidthPt: number;
  outerScreenHeightPt: number;
  dynamicIslandSideSafeInsetPt: number;
}

export const DEFAULT_TUNING: GameTuning = {
  minPlayers: 2,
  maxPlayers: 6,
  couriersPerPlayer: 2,
  startingMarks: 40,
  startingClueTokens: 3,
  maxClueTokens: 5,
  inspectorRoundClueBonus: 1,
  handSize: 6,
  maxMulliganCards: 2,
  maxVisibleSlots: 5,
  maxHiddenSlotsWithFalseBottom: 1,
  compensationPerItem: 2,
  packingSeconds: 75,
  negotiationSeconds: 45,
  falseBottomSearchSeconds: 6,
  demoRoundSeconds: 40,
  sealAngleDeg: 3,
  peekMinAngleDeg: 3,
  slitLevel1MaxAngleDeg: 10,
  slitLevel2MaxAngleDeg: 18,
  commitAngleDeg: 25,
  postCommitLockAngleDeg: 15,
  openAngleDeg: 100,
  maxHingeAngleDeg: 180,
  hysteresisDeg: 2,
  sealHoldMs: 250,
  slitHapticTickStepDeg: 5,
  slitClueCost: 1,
  tintAccuracy: 0.75,
  falseBottomRequiredTilts: 2,
  falseBottomTiltAmplitudeDeg: 25,
  xrayClueCost: 1,
  calibrationSeconds: 6,
  scanSeconds: 5,
  nervometerBaseValue: 50,
  nervometerZScaleK: 18.5,
  nervometerEmaAlpha: 0.25,
  nervometerNoiseAmplitude: 8,
  nervometerUncertaintyBandWidth: 12,
  innerScreenWidthPt: 890,
  innerScreenHeightPt: 626,
  outerScreenWidthPt: 466,
  outerScreenHeightPt: 678,
  dynamicIslandSideSafeInsetPt: 34,
};

// Balanced constants after 10,000-match Monte Carlo simulation (Section 12)
export const BALANCED_TUNING: GameTuning = {
  ...DEFAULT_TUNING,
  compensationPerItem: 3, // Raised from 2 to 3 marks per item so Inspector "always inspect" does not dominate
  tintAccuracy: 0.75,
};
