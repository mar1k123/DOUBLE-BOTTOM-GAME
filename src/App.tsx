import React, { useEffect, useMemo, useRef, useState } from 'react';
import { BALANCED_DECK_DATA, CategoryID, INITIAL_DECK_DATA } from './game/deckData';
import { BALANCED_TUNING } from './game/tuning';
import {
  buildShuffledDeck,
  buildSlitLevel3Hints,
  calculateTotalCaseWeight,
  canCompleteSealing,
  CardInstance,
  computeHingeZone,
  Declaration,
  HingeZoneKind,
  InspectionVerdict,
  PackedCase,
  resolveInspection,
  resolvePass,
  RoundPhase,
  RoundResolutionSummary,
} from './game/rules';
import { evaluatePresentationPolicy, PublicProjection } from './game/presentationPolicy';
import { CaptainCueCategory, getCaptainLineText } from './game/captainLines';
import { GameLanguage, LANGUAGE_LABELS } from './game/i18n';
import { NeuralVoiceTimbre, noirAudio, VOICE_TIMBRE_LABELS } from './game/audioSynth';
import { OuterScreenView } from './components/OuterScreenView';
import { InnerScreenView } from './components/InnerScreenView';
import { ArchitectAndBalanceModal } from './components/ArchitectAndBalanceModal';

type AppShellState = 'title' | 'playing' | 'paused' | 'gameover';
type GameMode = 'pass_and_play' | 'solo_vs_captain' | 'storefront_demo';
type HingeProviderKind = 'simulated' | 'duo_hardware' | 'accessibility';

interface PlayerRecord {
  id: string;
  name: string;
  country: 'altavia' | 'nordmark';
  portraitIndex: number;
  marks: number;
  clueTokens: number;
  inspectionsWon: number;
  isBot: boolean;
}

export function App() {
  const [lang, setLang] = useState<GameLanguage>('en');
  const fr = lang === 'fr';

  const [shellState, setShellState] = useState<AppShellState>(() => {
    if (typeof window !== 'undefined') {
      const params = new URLSearchParams(window.location.search);
      if (params.get('autostart') === '1') return 'playing';
    }
    return 'title';
  });

  const [gameMode, setGameMode] = useState<GameMode>('pass_and_play');
  const [hingeProviderKind, setHingeProviderKind] = useState<HingeProviderKind>('simulated');
  const [colorblindMode, setColorblindMode] = useState<boolean>(false);
  const [cameraConsentGranted, setCameraConsentGranted] = useState<boolean>(false);
  const [thermalState, setThermalState] = useState<'nominal' | 'fair' | 'serious'>('nominal');
  const [isMuted, setIsMuted] = useState<boolean>(false);
  const [voiceTimbre, setVoiceTimbre] = useState<NeuralVoiceTimbre>('Zephyr');
  const [architectModalTab, setArchitectModalTab] = useState<'balance' | 'swift' | null>(null);

  // Match & Round state
  const [players, setPlayers] = useState<PlayerRecord[]>([
    {
      id: 'p1',
      name: 'Martin Vogel',
      country: 'altavia',
      portraitIndex: 2,
      marks: BALANCED_TUNING.startingMarks,
      clueTokens: BALANCED_TUNING.startingClueTokens,
      inspectionsWon: 0,
      isBot: false,
    },
    {
      id: 'p2',
      name: 'Inspector Kreutz',
      country: 'nordmark',
      portraitIndex: 7,
      marks: BALANCED_TUNING.startingMarks,
      clueTokens: BALANCED_TUNING.startingClueTokens,
      inspectionsWon: 0,
      isBot: false,
    },
  ]);

  const [roundNumber, setRoundNumber] = useState<number>(1);
  const [totalRounds, setTotalRounds] = useState<number>(4);
  const [courierIndex, setCourierIndex] = useState<number>(0);
  const [phase, setPhase] = useState<RoundPhase>('PACKING');

  // Hinge angle θ (0° — closed, 180° — flat open)
  const [hingeAngleDeg, setHingeAngleDeg] = useState<number>(120);
  const [previousZone, setPreviousZone] = useState<HingeZoneKind>('OPEN');
  const [isCommittedInInspection, setIsCommittedInInspection] = useState<boolean>(false);

  // Deck and Courier Hand (SecretState)
  const [deck, setDeck] = useState<CardInstance[]>(() => buildShuffledDeck(BALANCED_DECK_DATA, 19641101));
  const [deckCursor, setDeckCursor] = useState<number>(6);
  const [hand, setHand] = useState<CardInstance[]>(() => {
    const initial = buildShuffledDeck(BALANCED_DECK_DATA, 19641101).slice(0, 6);
    const starter = initial.filter((c) => c.kind === 'item' && c.itemDef).slice(0, 2);
    return initial.filter((c) => !starter.some((s) => s.uid === c.uid));
  });
  const [selectedDiscardUids, setSelectedDiscardUids] = useState<string[]>([]);
  const [hasUsedMulligan, setHasUsedMulligan] = useState<boolean>(false);

  const [packedCase, setPackedCase] = useState<PackedCase>(() => {
    const initialCards = buildShuffledDeck(BALANCED_DECK_DATA, 19641101).slice(0, 6);
    const firstItems = initialCards.filter((c) => c.kind === 'item' && c.itemDef).slice(0, 2);
    return {
      visibleItems: firstItems.map((c) => c.itemDef!),
      hasFalseBottomCard: false,
      hiddenItem: null,
    };
  });

  const [declaration, setDeclaration] = useState<Declaration>({
    category: 'oranges',
    declaredCount: 2,
    bribeMarks: 0,
  });

  const [remainingSeconds, setRemainingSeconds] = useState<number>(BALANCED_TUNING.packingSeconds);
  const [incompleteSealWarning, setIncompleteSealWarning] = useState<boolean>(false);
  const [noClueTokensWarning, setNoClueTokensWarning] = useState<boolean>(false);
  const [slitUnlockedInCurrentRound, setSlitUnlockedInCurrentRound] = useState<boolean>(false);

  // Nervometer & X-Ray
  const [isScanningXray, setIsScanningXray] = useState<boolean>(false);
  const [xrayScanProgress, setXrayScanProgress] = useState<number>(0);
  const [nervometerReading, setNervometerReading] = useState<{
    value: number;
    uncertainty: number;
    usedTremorFallback: boolean;
  } | null>(null);

  // Inspection & False Bottom tilt search
  const [falseBottomTiltCount, setFalseBottomTiltCount] = useState<number>(0);
  const [falseBottomTimeLeft, setFalseBottomTimeLeft] = useState<number>(BALANCED_TUNING.falseBottomSearchSeconds);
  const [verdictBanner, setVerdictBanner] = useState<InspectionVerdict | null>(null);
  const [resolutionSummary, setResolutionSummary] = useState<RoundResolutionSummary | null>(null);
  const [lastCaptainCue, setLastCaptainCue] = useState<{ category: CaptainCueCategory; seed: number }>({
    category: 'packing',
    seed: 1,
  });
  const [customCaptainOverride, setCustomCaptainOverride] = useState<{ en: string; fr: string } | null>(null);
  const [protocolSavedCount, setProtocolSavedCount] = useState<number>(0);
  const [demoStepIndex, setDemoStepIndex] = useState<number>(0);

  const lastSlitTickBucketRef = useRef<number>(-1);
  const sealHoldTimerRef = useRef<number | null>(null);

  // Sync data-state and document language
  useEffect(() => {
    document.body.dataset.state = shellState;
    document.documentElement.lang = lang;
  }, [shellState, lang]);

  const captainLine = useMemo(() => {
    if (customCaptainOverride) {
      return lang === 'fr' ? customCaptainOverride.fr : customCaptainOverride.en;
    }
    return getCaptainLineText(lastCaptainCue.category, lastCaptainCue.seed, lang);
  }, [customCaptainOverride, lastCaptainCue, lang]);

  const triggerCaptainCue = (category: CaptainCueCategory, seed: number, speakNow: boolean = false) => {
    setCustomCaptainOverride(null);
    setLastCaptainCue({ category, seed });
    if (speakNow) {
      const lineText = getCaptainLineText(category, seed, lang);
      noirAudio.speakCaptainLine(lineText, lang);
    }
  };

  const handleSwitchLanguage = (nextLang: GameLanguage) => {
    setLang(nextLang);
    // Update bot name if in solo mode
    setPlayers((prev) =>
      prev.map((p) => {
        if (!p.isBot) return p;
        return {
          ...p,
          name: nextLang === 'fr' ? 'Capitaine Vera (IA)' : 'Captain Vera (AI)',
        };
      })
    );
    const spokenText = customCaptainOverride
      ? nextLang === 'fr'
        ? customCaptainOverride.fr
        : customCaptainOverride.en
      : getCaptainLineText(lastCaptainCue.category, lastCaptainCue.seed, nextLang);
    noirAudio.speakCaptainLine(spokenText, nextLang);
  };

  const courier = players[courierIndex] ?? players[0];
  const inspectorIndex = (courierIndex + 1) % players.length;
  const inspector = players[inspectorIndex] ?? players[1];

  const currentHingeZone = useMemo(
    () => computeHingeZone(hingeAngleDeg, previousZone, isCommittedInInspection, BALANCED_TUNING),
    [hingeAngleDeg, previousZone, isCommittedInInspection]
  );

  useEffect(() => {
    setPreviousZone(currentHingeZone);
  }, [currentHingeZone]);

  // Initialize a round
  const setupRound = (nextRoundNum: number, nextCourierIdx: number, currentPlayers: PlayerRecord[], mode: GameMode) => {
    const freshDeck = buildShuffledDeck(BALANCED_DECK_DATA, 19641101 + nextRoundNum * 97);
    const initialHand = freshDeck.slice(0, BALANCED_TUNING.handSize);

    // At the start of a round, the Inspector receives +1 Clue Token (up to max 5 — Section 4.1)
    const nextInspectorIdx = (nextCourierIdx + 1) % currentPlayers.length;
    const updatedPlayers = currentPlayers.map((p, idx) =>
      idx === nextInspectorIdx
        ? { ...p, clueTokens: Math.min(BALANCED_TUNING.maxClueTokens, p.clueTokens + BALANCED_TUNING.inspectorRoundClueBonus) }
        : p
    );
    setPlayers(updatedPlayers);

    setDeck(freshDeck);
    setDeckCursor(BALANCED_TUNING.handSize);
    setHand(initialHand);
    setSelectedDiscardUids([]);
    setHasUsedMulligan(false);
    setIsCommittedInInspection(false);
    setSlitUnlockedInCurrentRound(false);
    setNoClueTokensWarning(false);
    setIncompleteSealWarning(false);
    setNervometerReading(null);
    setIsScanningXray(false);
    setXrayScanProgress(0);
    setFalseBottomTiltCount(0);
    setFalseBottomTimeLeft(BALANCED_TUNING.falseBottomSearchSeconds);
    setVerdictBanner(null);
    setResolutionSummary(null);

    if (mode === 'storefront_demo') {
      const orange = BALANCED_DECK_DATA.items.find((i) => i.id === 'orange')!;
      const microfilm = BALANCED_DECK_DATA.items.find((i) => i.id === 'microfilm')!;
      const gold = BALANCED_DECK_DATA.items.find((i) => i.id === 'gold')!;
      setPackedCase({
        visibleItems: [orange, microfilm, gold],
        hasFalseBottomCard: false,
        hiddenItem: null,
      });
      setDeclaration({ category: 'oranges', declaredCount: 3, bribeMarks: 3 });
      setHingeAngleDeg(120);
      setPhase('PACKING');
      setRemainingSeconds(BALANCED_TUNING.demoRoundSeconds);
      setDemoStepIndex(1);
      setCustomCaptainOverride({
        en: 'Storefront Demo Round (40 s): close the iPhone Duo (θ ≤ 3°) to seal the contraband cargo.',
        fr: 'Manche démo vitrine (40 s) : fermez l’iPhone Duo (θ ≤ 3°) pour sceller la contrebande.',
      });
      return;
    }

    // If Courier is AI bot (in "Solo vs Captain" mode), it automatically packs and seals the suitcase
    const activeCourier = updatedPlayers[nextCourierIdx];
    if (activeCourier?.isBot) {
      const itemCards = initialHand.filter((c) => c.kind === 'item' && c.itemDef).map((c) => c.itemDef!);
      const chosen = itemCards.slice(0, 3);
      setPackedCase({
        visibleItems: chosen,
        hasFalseBottomCard: false,
        hiddenItem: null,
      });
      setDeclaration({
        category: 'cheese',
        declaredCount: chosen.length,
        bribeMarks: 2,
      });
      setHingeAngleDeg(0);
      setPhase('NEGOTIATION');
      setRemainingSeconds(BALANCED_TUNING.negotiationSeconds);
      triggerCaptainCue('negotiation', nextRoundNum, true);
      return;
    }

    // For human Courier, pre-place 2 starter items from hand so hand(4) + case(2) = 6 cards dealt
    const starterItems = initialHand.filter((c) => c.kind === 'item' && c.itemDef).slice(0, 2);
    const remainingHand = initialHand.filter((c) => !starterItems.some((s) => s.uid === c.uid));
    setHand(remainingHand);
    setPackedCase({
      visibleItems: starterItems.map((c) => c.itemDef!),
      hasFalseBottomCard: false,
      hiddenItem: null,
    });
    const defaultCategory: CategoryID = starterItems[0]?.itemDef?.category ?? 'oranges';
    setDeclaration({
      category: defaultCategory,
      declaredCount: starterItems.length,
      bribeMarks: 0,
    });
    setHingeAngleDeg(120);
    setPhase('PACKING');
    setRemainingSeconds(BALANCED_TUNING.packingSeconds);
    triggerCaptainCue('packing', nextRoundNum, false);
  };

  const startGameWithMode = (mode: GameMode) => {
    setGameMode(mode);
    const initialPlayers: PlayerRecord[] = [
      {
        id: 'p1',
        name: 'Martin Vogel',
        country: 'altavia',
        portraitIndex: 2,
        marks: BALANCED_TUNING.startingMarks,
        clueTokens: BALANCED_TUNING.startingClueTokens,
        inspectionsWon: 0,
        isBot: false,
      },
      {
        id: 'p2',
        name:
          mode === 'solo_vs_captain'
            ? lang === 'fr'
              ? 'Capitaine Vera (IA)'
              : 'Captain Vera (AI)'
            : 'Inspector Kreutz',
        country: 'nordmark',
        portraitIndex: 7,
        marks: BALANCED_TUNING.startingMarks,
        clueTokens: BALANCED_TUNING.startingClueTokens,
        inspectionsWon: 0,
        isBot: mode === 'solo_vs_captain',
      },
    ];
    setPlayers(initialPlayers);
    setRoundNumber(1);
    setCourierIndex(0);
    setShellState('playing');
    setupRound(1, 0, initialPlayers, mode);
    const openingLine = getCaptainLineText('deal', 1, lang);
    noirAudio.speakCaptainLine(openingLine, lang);
    if (document.activeElement instanceof HTMLElement) {
      document.activeElement.blur();
    }
  };

  // Hinge angle θ handler (SEALING 250ms debounce, SLIT 3..25°, COMMIT ≥ 25°)
  const handleSetHingeAngle = (newAngle: number) => {
    const clamped = Math.max(0, Math.min(180, newAngle));
    setHingeAngleDeg(clamped);

    // Haptic/audio spring tick every 5° inside SLIT (3°..25°)
    if (clamped > 3 && clamped < 25) {
      const bucket = Math.floor(clamped / BALANCED_TUNING.slitHapticTickStepDeg);
      if (bucket !== lastSlitTickBucketRef.current) {
        lastSlitTickBucketRef.current = bucket;
        noirAudio.playSlitTick();
      }
    }

    // 1. In DEAL phase: unfolding ≥ 100° transitions to PACKING
    if (phase === 'DEAL' && clamped >= BALANCED_TUNING.openAngleDeg) {
      setPhase('PACKING');
    }

    // 2. In PACKING phase: closing θ ≤ 3° starts 250ms debounce timer for SEALED
    if (phase === 'PACKING') {
      if (clamped <= BALANCED_TUNING.sealAngleDeg) {
        const check = canCompleteSealing(clamped, 250, packedCase, declaration, BALANCED_TUNING);
        if (!check.sealed && check.reason === 'incomplete_cargo') {
          setIncompleteSealWarning(true);
          return;
        }
        setIncompleteSealWarning(false);
        if (sealHoldTimerRef.current) window.clearTimeout(sealHoldTimerRef.current);
        sealHoldTimerRef.current = window.setTimeout(() => {
          noirAudio.playLatchSeal();
          setPhase('NEGOTIATION');
          setRemainingSeconds(BALANCED_TUNING.negotiationSeconds);
          triggerCaptainCue('sealed', roundNumber, true);
          if (gameMode === 'storefront_demo') {
            setDemoStepIndex(2);
          }
        }, BALANCED_TUNING.sealHoldMs);
      } else {
        if (sealHoldTimerRef.current) {
          window.clearTimeout(sealHoldTimerRef.current);
          sealHoldTimerRef.current = null;
        }
        if (clamped > 15) setIncompleteSealWarning(false);
      }
    }

    // 3. In NEGOTIATION, DECISION, or INSPECTION phases: entering SLIT (3° < θ < 25°) or COMMIT (θ ≥ 25°)
    if (phase === 'NEGOTIATION' || phase === 'DECISION' || phase === 'INSPECTION') {
      if (clamped >= BALANCED_TUNING.commitAngleDeg && !isCommittedInInspection) {
        noirAudio.playCommitSnap();
        setIsCommittedInInspection(true);
        setPhase('INSPECTION');
        const hasViolation =
          packedCase.visibleItems.some((i) => i.category !== declaration.category) ||
          Boolean(packedCase.hiddenItem && packedCase.hiddenItem.category !== declaration.category);
        setVerdictBanner(hasViolation ? 'BUSTED' : 'CLEAN');
        triggerCaptainCue(hasViolation ? 'caught_contraband' : 'inspected_honest', roundNumber, true);
        if (gameMode === 'storefront_demo') {
          setDemoStepIndex(4);
        }
      } else if (clamped >= BALANCED_TUNING.peekMinAngleDeg && clamped < BALANCED_TUNING.commitAngleDeg) {
        if (phase !== 'INSPECTION') {
          setPhase('INSPECTION');
        }
        if (!slitUnlockedInCurrentRound) {
          if (inspector.clueTokens >= BALANCED_TUNING.slitClueCost) {
            setSlitUnlockedInCurrentRound(true);
            setNoClueTokensWarning(false);
            setPlayers((prev) =>
              prev.map((p, idx) =>
                idx === inspectorIndex ? { ...p, clueTokens: Math.max(0, p.clueTokens - 1) } : p
              )
            );
            triggerCaptainCue('slit_peek', roundNumber, true);
            if (gameMode === 'storefront_demo') {
              setDemoStepIndex(3);
            }
          } else {
            setNoClueTokensWarning(true);
          }
        }
      }
    }
  };

  // Keyboard hotkeys: [ and ] for hinge angle, P/Escape for pause, Enter/Space on title screen
  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      if (shellState === 'title') {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          startGameWithMode('pass_and_play');
        }
        return;
      }
      if (e.key === 'Escape' || e.key === 'p' || e.key === 'P') {
        if (!architectModalTab) {
          setShellState((s) => (s === 'playing' ? 'paused' : s === 'paused' ? 'playing' : s));
        }
        return;
      }
      if (shellState !== 'playing') return;
      if (e.key === '[') {
        handleSetHingeAngle(hingeAngleDeg - 6);
      } else if (e.key === ']') {
        handleSetHingeAngle(hingeAngleDeg + 6);
      }
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  });

  // Round timer (1 Hz)
  useEffect(() => {
    if (shellState !== 'playing') return;
    const timer = window.setInterval(() => {
      setRemainingSeconds((sec) => (sec > 0 ? sec - 1 : 0));
      if (phase === 'INSPECTION' && isCommittedInInspection) {
        setFalseBottomTimeLeft((t) => (t > 0 ? t - 1 : 0));
      }
    }, 1000);
    return () => window.clearInterval(timer);
  }, [shellState, phase, isCommittedInInspection]);

  // Courier packing actions
  const handleTogglePackVisibleItem = (card: CardInstance) => {
    if (!card.itemDef || packedCase.visibleItems.length >= BALANCED_TUNING.maxVisibleSlots) return;
    const nextVisible = [...packedCase.visibleItems, card.itemDef];
    setPackedCase((prev) => ({ ...prev, visibleItems: nextVisible }));
    setHand((prev) => prev.filter((c) => c.uid !== card.uid));
    setDeclaration((prev) => ({ ...prev, declaredCount: nextVisible.length }));
  };

  const handleAssignHiddenFalseBottomItem = (card: CardInstance) => {
    if (!card.itemDef) return;
    setPackedCase((prev) => {
      const restored = prev.hiddenItem
        ? [
            ...hand.filter((c) => c.uid !== card.uid && c.kind !== 'false_bottom'),
            { uid: `restored_${Date.now()}`, kind: 'item' as const, itemDef: prev.hiddenItem },
          ]
        : hand.filter((c) => c.uid !== card.uid && c.kind !== 'false_bottom');
      setHand(restored);
      return {
        ...prev,
        hasFalseBottomCard: true,
        hiddenItem: card.itemDef!,
      };
    });
  };

  const handleClearCase = () => {
    const returnedCards: CardInstance[] = packedCase.visibleItems.map((item, i) => ({
      uid: `ret_${Date.now()}_${i}`,
      kind: 'item',
      itemDef: item,
    }));
    if (packedCase.hiddenItem) {
      returnedCards.push({
        uid: `ret_hid_${Date.now()}`,
        kind: 'item',
        itemDef: packedCase.hiddenItem,
      });
    }
    if (packedCase.hasFalseBottomCard) {
      returnedCards.push({
        uid: `ret_fb_${Date.now()}`,
        kind: 'false_bottom',
      });
    }
    setHand((prev) => [...prev, ...returnedCards]);
    setPackedCase({ visibleItems: [], hasFalseBottomCard: false, hiddenItem: null });
    setDeclaration((prev) => ({ ...prev, declaredCount: 0 }));
  };

  const handleToggleDiscardSelect = (uid: string) => {
    setSelectedDiscardUids((prev) => {
      if (prev.includes(uid)) return prev.filter((id) => id !== uid);
      if (prev.length >= BALANCED_TUNING.maxMulliganCards) return prev;
      return [...prev, uid];
    });
  };

  const handleExecuteMulligan = () => {
    if (hasUsedMulligan || selectedDiscardUids.length === 0) return;
    const count = selectedDiscardUids.length;
    const drawn = deck.slice(deckCursor, deckCursor + count);
    setDeckCursor((c) => c + count);
    setHand((prev) => [...prev.filter((c) => !selectedDiscardUids.includes(c.uid)), ...drawn]);
    setSelectedDiscardUids([]);
    setHasUsedMulligan(true);
  };

  // X-Ray / Nervometer action (Section 7)
  const handleTriggerXrayScan = () => {
    if (inspector.clueTokens < 1 || isScanningXray) return;
    setPlayers((prev) =>
      prev.map((p, idx) => (idx === inspectorIndex ? { ...p, clueTokens: p.clueTokens - 1 } : p))
    );
    setIsScanningXray(true);
    setXrayScanProgress(20);

    const hasContraband =
      packedCase.visibleItems.some((i) => i.category !== declaration.category) ||
      Boolean(packedCase.hiddenItem);
    const usedTremor = !cameraConsentGranted || thermalState === 'serious';

    window.setTimeout(() => setXrayScanProgress(65), 250);
    window.setTimeout(() => {
      setIsScanningXray(false);
      setXrayScanProgress(100);
      const base = hasContraband ? 66 : 47;
      const jitter = Math.floor((Math.random() * 2 - 1) * BALANCED_TUNING.nervometerNoiseAmplitude);
      setNervometerReading({
        value: Math.max(12, Math.min(94, base + jitter)),
        uncertainty: BALANCED_TUNING.nervometerUncertaintyBandWidth,
        usedTremorFallback: usedTremor,
      });
      triggerCaptainCue('xray_scan', roundNumber, true);
    }, 600);
  };

  // Inspector decisions: PASS, ACCEPT BRIBE, COMMIT INSPECTION
  const finalizeRoundWithSummary = (
    summary: RoundResolutionSummary,
    cue: 'pass_clean' | 'bribe_accepted' | 'inspected_honest' | 'caught_contraband'
  ) => {
    setResolutionSummary(summary);
    setVerdictBanner(summary.verdictBanner);
    setPhase('RESOLUTION');
    setHingeAngleDeg(120);
    noirAudio.playStampThud(summary.verdictBanner === 'CLEAN');
    triggerCaptainCue(cue, roundNumber, true);

    setPlayers((prev) =>
      prev.map((p, idx) => {
        if (idx === courierIndex) {
          return { ...p, marks: summary.courierFinalMarks };
        }
        if (idx === inspectorIndex) {
          return {
            ...p,
            marks: summary.inspectorFinalMarks,
            inspectionsWon: summary.inspectorWonInspection ? p.inspectionsWon + 1 : p.inspectionsWon,
          };
        }
        return p;
      })
    );
  };

  const handleDecisionPass = () => {
    const summary = resolvePass(packedCase, declaration, false, courier.marks, inspector.marks);
    finalizeRoundWithSummary(summary, 'pass_clean');
  };

  const handleDecisionAcceptBribe = () => {
    const summary = resolvePass(packedCase, declaration, true, courier.marks, inspector.marks);
    finalizeRoundWithSummary(summary, 'bribe_accepted');
  };

  const handleFinishInspectionToResolution = () => {
    const fbFound = falseBottomTiltCount >= BALANCED_TUNING.falseBottomRequiredTilts;
    const summary = resolveInspection(
      packedCase,
      declaration,
      fbFound,
      courier.marks,
      inspector.marks,
      BALANCED_TUNING
    );
    finalizeRoundWithSummary(
      summary,
      summary.verdictBanner === 'BUSTED' ? 'caught_contraband' : 'inspected_honest'
    );
  };

  const handleNextRound = () => {
    if (roundNumber >= totalRounds) {
      setShellState('gameover');
      return;
    }
    const nextR = roundNumber + 1;
    const nextCourier = (courierIndex + 1) % players.length;
    setRoundNumber(nextR);
    setCourierIndex(nextCourier);
    setupRound(nextR, nextCourier, players, gameMode);
  };

  // Compute PublicProjection & PresentationPolicy (Sections 6.1, 6.2)
  const expectedUnitWeight =
    INITIAL_DECK_DATA.categories.find((c) => c.id === declaration.category)?.expectedWeight ?? 1;
  const totalCaseWeight = calculateTotalCaseWeight(packedCase);
  const visibleSilhouettes = packedCase.visibleItems.map((i) => i.silhouette);
  const tintedHints = useMemo(
    () => buildSlitLevel3Hints(packedCase, declaration.category, roundNumber * 101 + courierIndex, BALANCED_TUNING),
    [packedCase, declaration.category, roundNumber, courierIndex]
  );

  const publicProjection: PublicProjection = {
    roundNumber,
    totalRounds,
    phase,
    hingeZone: currentHingeZone,
    courierName: courier.name,
    inspectorName: inspector.name,
    courierMarks: courier.marks,
    inspectorMarks: inspector.marks,
    inspectorClueTokens: inspector.clueTokens,
    courierCountry: courier.country,
    courierPortraitIndex: courier.portraitIndex,
    declaration,
    remainingSeconds,
    incompleteSealWarning,
    noClueTokensWarning,
    nervometerReading,
    verdictBanner,
    resolutionSummary,
    captainLine,
  };

  const presentation = evaluatePresentationPolicy({
    projection: publicProjection,
    slitUnlockedWithToken: slitUnlockedInCurrentRound,
    totalCaseWeight,
    expectedUnitWeight,
    visibleSilhouettes,
    tintedHints,
    falseBottomSearchActive: phase === 'INSPECTION' && isCommittedInInspection,
  });

  const demoHintText = useMemo(() => {
    if (gameMode !== 'storefront_demo') return null;
    if (demoStepIndex === 1) {
      return fr
        ? 'Étape 1/4 : Cliquez sur « Fermer Duo et sceller (θ → 0°) » pour verrouiller la cargaison.'
        : 'Step 1/4: Click "Close Duo & Seal Case (θ → 0°)" to seal the cargo.';
    }
    if (demoStepIndex === 2) {
      return fr
        ? 'Étape 2/4 : Passez le téléphone à l’Inspecteur. Cliquez sur « Entrebâiller (6°) » sur l’écran externe.'
        : 'Step 2/4: Pass the phone to the Inspector. Click "Peek Slit (6°)" on the Outer Screen.';
    }
    if (demoStepIndex === 3) {
      return fr
        ? 'Étape 3/4 : Glissez la charnière de 6° vers 14° (silhouettes) et 21° (contre-jour), puis ouvrez à ≥ 25° !'
        : 'Step 3/4: Slide the hinge from 6° to 14° (silhouettes) and 21° (backlit tint), then swing open ≥ 25°!';
    }
    return fr
      ? 'Étape 4/4 : Contrebande découverte ! Inclinez la valise pour vérifier le double fond et signez le procès-verbal.'
      : 'Step 4/4: Contraband exposed! Tilt the suitcase to check the false bottom and sign the Inspection Protocol.';
  }, [gameMode, demoStepIndex, fr]);

  // Language Switcher Pill Component (English & French ONLY)
  const renderLanguageSelector = () => (
    <div
      role="group"
      aria-label="Language selection"
      className="inline-flex items-center rounded-xl border border-[#d4a853]/45 bg-[#18130e] p-1 gap-1"
    >
      {(['en', 'fr'] as GameLanguage[]).map((code) => {
        const active = lang === code;
        return (
          <button
            key={code}
            type="button"
            onClick={() => handleSwitchLanguage(code)}
            className={`px-3 py-1 rounded-lg text-xs font-mono-tabular font-bold transition-colors whitespace-nowrap ${
              active
                ? 'bg-[#d4a853] text-[#14110e] shadow'
                : 'text-[#c8b99e] hover:text-[#f3ead8] hover:bg-[#241c14]'
            }`}
          >
            {LANGUAGE_LABELS[code].flag} {LANGUAGE_LABELS[code].full}
          </button>
        );
      })}
    </div>
  );

  const handleSelectVoiceTimbre = (timbre: NeuralVoiceTimbre) => {
    setVoiceTimbre(timbre);
    noirAudio.voiceTimbre = timbre;
    const spokenText =
      shellState === 'title' ? getCaptainLineText('deal', 2, lang) : captainLine;
    noirAudio.speakCaptainLine(spokenText, lang, timbre);
  };

  const renderVoiceTimbreSelector = () => (
    <div
      role="group"
      aria-label="Neural Voice Timbre"
      className="inline-flex items-center rounded-xl border border-[#d4a853]/35 bg-[#18130e] p-1 gap-1"
    >
      {(['Zephyr', 'Kore', 'Charon'] as NeuralVoiceTimbre[]).map((timbre) => {
        const active = voiceTimbre === timbre;
        return (
          <button
            key={timbre}
            type="button"
            onClick={() => handleSelectVoiceTimbre(timbre)}
            title={fr ? VOICE_TIMBRE_LABELS[timbre].descFr : VOICE_TIMBRE_LABELS[timbre].descEn}
            className={`px-2.5 py-1 rounded-lg text-[11px] font-mono-tabular font-semibold transition-colors whitespace-nowrap ${
              active
                ? 'bg-[#2e241b] text-[#d4a853] border border-[#d4a853]/60'
                : 'text-[#a8997f] hover:text-[#f3ead8]'
            }`}
          >
            🎙️ {timbre}
          </button>
        );
      })}
    </div>
  );

  // 1. TITLE SCREEN (Game Shell: Title Screen without web nav header — per game_title_and_hud.md)
  if (shellState === 'title') {
    return (
      <main className="relative min-h-screen w-full bg-[#0e0d0b] text-[#f3ead8] flex flex-col justify-between p-6 md:p-12 overflow-hidden">
        {/* Atmospheric background of Swallow Checkpoint with >40% calm negative space */}
        <div
          aria-hidden="true"
          className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_72%_40%,rgba(212,168,83,0.16),transparent_58%)]"
        />

        {/* Top-right Language Selector (English / Français) + Neural Voice Timbre + Voiceover Test */}
        <div className="relative z-10 max-w-6xl mx-auto w-full flex flex-wrap items-center justify-between gap-3">
          <div className="text-xs font-mono-tabular text-[#b8a98d]">
            {fr ? 'POSTE-FRONTIÈRE « HIRONDELLE » · 1964' : 'SWALLOW BORDER CHECKPOINT · 1964'}
          </div>
          <div className="flex flex-wrap items-center gap-2">
            {renderLanguageSelector()}
            {renderVoiceTimbreSelector()}
            <button
              type="button"
              onClick={() => {
                const sample = getCaptainLineText('deal', 2, lang);
                noirAudio.speakCaptainLine(sample, lang, voiceTimbre);
              }}
              className="px-3 py-1.5 rounded-xl border border-[#d4a853]/40 bg-[#211a14] hover:bg-[#2e241b] text-xs font-mono-tabular font-semibold text-[#d4a853] whitespace-nowrap"
            >
              {fr ? '🔊 Tester la voix (FR)' : '🔊 Test Voiceover (EN)'}
            </button>
          </div>
        </div>

        <div className="relative z-10 max-w-6xl mx-auto w-full my-auto grid grid-cols-1 lg:grid-cols-12 gap-8 items-center">
          {/* Left column: Bespoke SVG crest & primary launch actions (<= 3 primary buttons) */}
          <div className="lg:col-span-7 space-y-6">
            <svg
              viewBox="0 0 580 150"
              className="w-full max-w-xl h-auto"
              aria-label={fr ? 'DOUBLE FOND — Poste Hirondelle' : 'DOUBLE BOTTOM — Swallow Checkpoint'}
            >
              <rect x="4" y="8" width="572" height="134" rx="14" fill="#18130e" stroke="#d4a853" strokeWidth="2.5" />
              <rect
                x="12"
                y="16"
                width="556"
                height="118"
                rx="10"
                fill="none"
                stroke="#d4a853"
                strokeWidth="1"
                strokeDasharray="6 4"
                opacity="0.55"
              />
              {/* Swallow emblem and customs key */}
              <path d="M58 75 L34 55 L46 75 L34 95 Z" fill="#d4a853" />
              <circle cx="66" cy="75" r="18" fill="none" stroke="#d4a853" strokeWidth="2.5" />
              <text x="104" y="42" fill="#d4a853" fontSize="13" fontFamily="IBM Plex Mono, monospace" letterSpacing="2.2">
                {fr ? 'POSTE « HIRONDELLE » · iPHONE DUO (iOS 27.1)' : 'SWALLOW CHECKPOINT · iPHONE DUO (iOS 27.1)'}
              </text>
              <text
                x="104"
                y="92"
                fill="#f3ead8"
                fontSize="44"
                fontWeight="700"
                fontFamily="Cormorant Garamond, Georgia, serif"
                letterSpacing="2"
              >
                {fr ? 'DOUBLE FOND' : 'DOUBLE BOTTOM'}
              </text>
              <text x="104" y="118" fill="#c8b99e" fontSize="13" fontFamily="Plus Jakarta Sans, sans-serif">
                {fr
                  ? 'Dehors : passeport et déclaration. Dedans : valise et contrebande.'
                  : 'Outside: passport & declaration. Inside: suitcase & contraband.'}
              </text>
            </svg>

            <p className="text-sm md:text-base text-[#d6c7ad] max-w-xl leading-relaxed">
              {fr ? (
                <>
                  Jeu de bluff et de déduction pour 2 à 6 joueurs conçu sur mesure pour l’<strong>iPhone Duo</strong> pliable : deux écrans simultanés (5.4″ externe et 7.6″ interne), charnière physique servant de capteur d’inspection et caméras double face pour le « Nervomètre » et le « Protocole d’inspection ».
                </>
              ) : (
                <>
                  A tabletop bluffing party game for 2–6 players engineered specifically for the foldable <strong>iPhone Duo</strong>: dual simultaneous displays (5.4″ Outer & 7.6″ Inner), the physical hinge as a live inspection sensor, and dual-facing cameras for the Nervometer and Inspection Protocol.
                </>
              )}
            </p>

            <div className="flex flex-wrap items-center gap-3 pt-2">
              <button
                type="button"
                data-start="true"
                onClick={() => startGameWithMode('pass_and_play')}
                className="px-6 py-3.5 rounded-xl text-sm font-bold bg-[#d4a853] hover:bg-[#e2b964] text-[#14110e] shadow-lg transition-transform active:scale-95 whitespace-nowrap"
              >
                {fr ? 'Démarrer le service (2 joueurs)' : 'Start Shift (2-Player Pass & Play)'}
              </button>

              <button
                type="button"
                onClick={() => startGameWithMode('solo_vs_captain')}
                className="px-5 py-3.5 rounded-xl text-sm font-semibold bg-[#211a14] hover:bg-[#2c231b] text-[#f3ead8] border border-[#d4a853]/40 transition-colors whitespace-nowrap"
              >
                {fr ? 'Solo « Contre le Capitaine »' : 'Solo "Vs. Captain Vera"'}
              </button>

              <button
                type="button"
                onClick={() => startGameWithMode('storefront_demo')}
                className="px-5 py-3.5 rounded-xl text-sm font-semibold bg-[#182921] hover:bg-[#20382d] text-[#d8f3e5] border border-[#4ade80]/35 transition-colors whitespace-nowrap"
              >
                {fr ? 'Démo Vitrine (40 s)' : 'Storefront Demo (40 s)'}
              </button>
            </div>

            <div className="pt-2 flex flex-wrap items-center gap-4 text-xs text-[#b8a98d]">
              <button
                type="button"
                onClick={() => setArchitectModalTab('balance')}
                className="underline hover:text-[#d4a853] whitespace-nowrap"
              >
                {fr ? 'Ouvrir BalanceSimulator (10 000 parties)' : 'Open BalanceSimulator (10,000 matches)'}
              </button>
              <span>·</span>
              <button
                type="button"
                onClick={() => setArchitectModalTab('swift')}
                className="underline hover:text-[#d4a853] whitespace-nowrap"
              >
                {fr ? 'Inspecteur de code Swift / Xcode 27.1' : 'Swift / Xcode 27.1 Code Inspector'}
              </button>
            </div>
          </div>

          {/* Right column: Interactive iPhone Duo hardware rig overview */}
          <div className="lg:col-span-5 rounded-3xl border border-[#d4a853]/35 bg-[#16120e] p-6 space-y-4 shadow-2xl">
            <div className="flex items-center justify-between text-xs font-mono-tabular text-[#d4a853]">
              <span>{fr ? 'BANC MATÉRIEL iPHONE DUO' : 'iPHONE DUO HARDWARE RIG'}</span>
              <span>{fr ? '3 NIVEAUX DE FENTE' : '3 SLIT PEEK LEVELS'}</span>
            </div>

            <div className="grid grid-cols-2 gap-3 text-xs">
              <div className="rounded-xl bg-passport-cover border border-[#d4a853]/30 p-3.5 space-y-1.5">
                <div className="font-mono-tabular text-[10px] text-[#d4a853]">
                  {fr ? 'ÉCRAN EXTERNE (5.4″)' : 'OUTER SCREEN (5.4″)'}
                </div>
                <div className="font-serif-display font-bold text-base">
                  {fr ? 'Passeport public' : 'Public Passport'}
                </div>
                <p className="text-[#b8a98d] text-[11px]">
                  {fr
                    ? 'Déclaration, pourboire, « Nervomètre » et œil « SOUS SURVEILLANCE ». Zéro fuite de secret.'
                    : 'Declaration, gratuity, Nervometer, and "UNDER INSPECTION" eye. Zero secret leakage by type.'}
                </p>
              </div>
              <div className="rounded-xl bg-felt-green border border-[#d4a853]/30 p-3.5 space-y-1.5">
                <div className="font-mono-tabular text-[10px] text-[#d4a853]">
                  {fr ? 'ÉCRAN INTERNE (7.6″)' : 'INNER SCREEN (7.6″)'}
                </div>
                <div className="font-serif-display font-bold text-base">
                  {fr ? 'Valise secrète' : 'Secret Valise'}
                </div>
                <p className="text-[#b8a98d] text-[11px]">
                  {fr
                    ? '3–10° Poids brut · 10–18° Silhouettes · 18–25° Teinte (75%) · ≥25° Fouille officielle.'
                    : '3–10° Gross weight · 10–18° Silhouettes · 18–25° Tint (75%) · ≥25° Official search.'}
                </p>
              </div>
            </div>

            {/* Camera Privacy Consent toggle (Sections 7.6 & 8) */}
            <div className="rounded-xl border border-[#d4a853]/25 bg-[#100d0a] p-3 text-xs flex items-center justify-between gap-3">
              <div>
                <div className="font-semibold text-[#e6d5b8]">
                  {fr ? 'Confidentialité Caméra (Vision RGB)' : 'Camera Privacy (Vision RGB)'}
                </div>
                <div className="text-[11px] text-[#9c8c72]">
                  {cameraConsentGranted
                    ? fr
                      ? 'Analyse faciale locale activée (aucune image enregistrée sur disque)'
                      : 'On-device facial landmark gauge enabled (no frames saved to disk)'
                    : fr
                    ? 'Désactivée par défaut : mode « Tremblement » par gyroscope actif'
                    : 'Off by default: X-Ray uses CoreMotion hand-tremor fallback'}
                </div>
              </div>
              <button
                type="button"
                onClick={() => setCameraConsentGranted((v) => !v)}
                className={`px-3 py-1.5 rounded-lg font-mono-tabular text-xs font-semibold whitespace-nowrap ${
                  cameraConsentGranted
                    ? 'bg-[#1f5138] text-[#bbf7d0]'
                    : 'bg-[#2a2118] text-[#c8b99e]'
                }`}
              >
                {cameraConsentGranted
                  ? fr
                    ? 'Caméra : OUI'
                    : 'Camera: ON'
                  : fr
                  ? 'Sans caméra'
                  : 'Camera: OFF'}
              </button>
            </div>
          </div>
        </div>

        {/* Bottom flat control hint bar */}
        <div className="relative z-10 text-center text-xs font-mono-tabular text-[#8f8068]">
          {fr
            ? 'Entrée / Espace Démarrer · [ et ] Angle charnière θ · P Pause · 100% jouable sans caméra'
            : 'Enter / Space Start Shift · [ and ] Hinge Angle θ · P Pause · 100% playable without camera'}
        </div>

        {architectModalTab && (
          <ArchitectAndBalanceModal
            lang={lang}
            activeTab={architectModalTab}
            onClose={() => setArchitectModalTab(null)}
            onSwitchTab={(t) => setArchitectModalTab(t)}
          />
        )}
      </main>
    );
  }

  // 2. IN-GAME SHELL: DUAL-SCREEN iPHONE DUO SIMULATOR (DuoSimulatorView)
  return (
    <main className="min-h-screen w-full bg-[#0e0d0b] text-[#f3ead8] flex flex-col justify-between p-3 md:p-5">
      {/* Compact perimeter control bar */}
      <div className="max-w-[1380px] mx-auto w-full flex flex-wrap items-center justify-between gap-3 rounded-2xl border border-[#d4a853]/30 bg-[#16120e] px-4 py-2.5">
        <div className="flex flex-wrap items-center gap-3">
          <span className="font-serif-display font-bold text-lg text-[#d4a853] whitespace-nowrap">
            {fr ? 'DOUBLE FOND' : 'DOUBLE BOTTOM'}
          </span>
          <span className="text-xs font-mono-tabular text-[#c8b99e]">
            PHASE: <strong className="text-[#f3ead8]">{phase}</strong> · ZONE:{' '}
            <strong className="text-[#d4a853]">{currentHingeZone}</strong>
          </span>
        </div>

        {/* Physical hinge slider θ (0°..180°) & quick preset buttons */}
        <div className="flex flex-wrap items-center gap-2">
          <label htmlFor="hinge-slider" className="text-xs font-mono-tabular text-[#e6d5b8] whitespace-nowrap">
            {fr ? 'Charnière' : 'Hinge'} θ = <strong>{Math.round(hingeAngleDeg)}°</strong>
          </label>
          <input
            id="hinge-slider"
            aria-label={fr ? 'Angle de la charnière iPhone Duo' : 'iPhone Duo Hinge Angle'}
            type="range"
            min={0}
            max={180}
            value={hingeAngleDeg}
            onChange={(e) => handleSetHingeAngle(Number(e.target.value))}
            className="w-32 md:w-40 accent-[#d4a853]"
          />
          <div className="flex flex-wrap items-center gap-1">
            {[
              { label: fr ? '0° Fermer' : '0° Close', deg: 0 },
              { label: fr ? '6° Poids' : '6° Weight', deg: 6 },
              { label: fr ? '14° Silhouettes' : '14° Outline', deg: 14 },
              { label: fr ? '21° Teinte' : '21° Tint', deg: 21 },
              { label: fr ? '30° Fouiller' : '30° Inspect', deg: 30 },
              { label: fr ? '120° Ouvrir' : '120° Unfold', deg: 120 },
            ].map((preset) => (
              <button
                key={preset.deg}
                type="button"
                onClick={() => handleSetHingeAngle(preset.deg)}
                className={`px-2 py-1 rounded text-[11px] font-mono-tabular transition-colors whitespace-nowrap ${
                  Math.abs(hingeAngleDeg - preset.deg) <= 2
                    ? 'bg-[#d4a853] text-[#14110e] font-bold'
                    : 'bg-[#241d16] hover:bg-[#33291f] text-[#d6c7ad]'
                }`}
              >
                {preset.label}
              </button>
            ))}
          </div>
        </div>

        {/* Utility & Language controls on right */}
        <div className="flex flex-wrap items-center gap-1.5">
          {renderLanguageSelector()}
          {renderVoiceTimbreSelector()}
          <button
            type="button"
            onClick={() => setColorblindMode((v) => !v)}
            className={`px-2.5 py-1.5 rounded-lg text-[11px] font-medium border border-[#d4a853]/30 whitespace-nowrap ${
              colorblindMode ? 'bg-[#d4a853] text-[#14110e] font-semibold' : 'bg-[#211a14] text-[#c8b99e]'
            }`}
          >
            {fr
              ? `Motifs : ${colorblindMode ? 'OUI' : 'STD'}`
              : `Patterns: ${colorblindMode ? 'ON' : 'STD'}`}
          </button>
          <button
            type="button"
            onClick={() => setArchitectModalTab('balance')}
            className="px-2.5 py-1.5 rounded-lg text-[11px] font-medium bg-[#211a14] hover:bg-[#2e241c] text-[#e6d5b8] border border-[#d4a853]/30 whitespace-nowrap"
          >
            {fr ? 'Équilibrage / Swift' : 'Balance / Swift'}
          </button>
          <button
            type="button"
            tabIndex={-1}
            aria-label={fr ? 'Son [M]' : 'Audio [M]'}
            onClick={(e) => {
              e.currentTarget.blur();
              const next = !isMuted;
              setIsMuted(next);
              noirAudio.isMuted = next;
            }}
            className="px-2.5 py-1.5 rounded-lg text-[11px] font-mono-tabular bg-[#211a14] hover:bg-[#2e241c] text-[#c8b99e] border border-[#d4a853]/30 whitespace-nowrap"
          >
            {isMuted ? (fr ? 'Son : NON' : 'Audio: OFF') : fr ? 'Son : OUI' : 'Audio: ON'}
          </button>
          <button
            type="button"
            tabIndex={-1}
            aria-label="Pause [P]"
            onClick={(e) => {
              e.currentTarget.blur();
              setShellState('paused');
            }}
            className="px-2.5 py-1.5 rounded-lg text-[11px] font-mono-tabular bg-[#211a14] hover:bg-[#2e241c] text-[#c8b99e] border border-[#d4a853]/30 whitespace-nowrap"
          >
            Pause [P]
          </button>
        </div>
      </div>

      {/* Main Stage: Both iPhone Duo Screens side-by-side (OuterScene 5.4″ + Hinge + InnerScene 7.6″) */}
      <div className="max-w-[1380px] mx-auto w-full my-auto py-3 flex flex-col lg:flex-row items-stretch gap-4">
        <OuterScreenView
          lang={lang}
          payload={presentation.outer}
          isScanningXray={isScanningXray}
          xrayScanProgress={xrayScanProgress}
          demoHintText={demoHintText}
          onTriggerXrayScan={handleTriggerXrayScan}
          onProceedToDecision={() => setPhase('DECISION')}
          onDecisionPass={handleDecisionPass}
          onDecisionAcceptBribe={handleDecisionAcceptBribe}
          onDecisionArmInspection={() => handleSetHingeAngle(30)}
          onQuickPeekSlit={(deg) => handleSetHingeAngle(deg)}
          onNextRound={handleNextRound}
          onReplayCaptainVoice={() => noirAudio.speakCaptainLine(captainLine, lang)}
        />

        {/* Visual mechanical hinge spine between the two displays */}
        <div className="hidden lg:flex flex-col items-center justify-center w-9 shrink-0 select-none">
          <div className="h-full w-3 rounded-full bg-gradient-to-b from-[#3d3020] via-[#d4a853] to-[#3d3020] border border-[#6e5233] flex flex-col items-center justify-between py-6">
            <span className="w-2 h-2 rounded-full bg-[#14110e]" />
            <span className="-rotate-90 font-mono-tabular text-[10px] font-bold text-[#14110e] whitespace-nowrap">
              {fr ? 'CHARNIÈRE' : 'HINGE'} {Math.round(hingeAngleDeg)}°
            </span>
            <span className="w-2 h-2 rounded-full bg-[#14110e]" />
          </div>
        </div>

        <InnerScreenView
          lang={lang}
          payload={presentation.inner}
          hingeAngleDeg={hingeAngleDeg}
          hand={hand}
          selectedDiscardUids={selectedDiscardUids}
          hasUsedMulligan={hasUsedMulligan}
          packedCase={packedCase}
          declaration={declaration}
          courierMarks={courier.marks}
          falseBottomTiltCount={falseBottomTiltCount}
          falseBottomTimeLeft={falseBottomTimeLeft}
          resolutionSummary={resolutionSummary}
          colorblindMode={colorblindMode}
          protocolSavedCount={protocolSavedCount}
          onToggleDiscardSelect={handleToggleDiscardSelect}
          onExecuteMulligan={handleExecuteMulligan}
          onTogglePackVisibleItem={handleTogglePackVisibleItem}
          onAssignHiddenFalseBottomItem={handleAssignHiddenFalseBottomItem}
          onClearCase={handleClearCase}
          onSelectCategory={(cat) => setDeclaration((prev) => ({ ...prev, category: cat }))}
          onChangeBribe={(bribe) => setDeclaration((prev) => ({ ...prev, bribeMarks: bribe }))}
          onQuickSealSuitcase={() => handleSetHingeAngle(0)}
          onQuickOpenSuitcase={() => handleSetHingeAngle(120)}
          onPerformSmoothTilt={() => setFalseBottomTiltCount((c) => Math.min(2, c + 1))}
          onFinishInspectionToResolution={handleFinishInspectionToResolution}
          onSaveProtocolToGallery={() => setProtocolSavedCount((c) => c + 1)}
          onNextRound={handleNextRound}
        />
      </div>

      {/* Bottom footer: Hinge provider & Thermal state selector (Sections 11, 13) */}
      <div className="max-w-[1380px] mx-auto w-full flex flex-wrap items-center justify-between gap-2 text-xs text-[#9c8c72] px-2">
        <div className="flex flex-wrap items-center gap-2">
          <span>{fr ? 'Source charnière :' : 'Hinge provider:'}</span>
          {(['simulated', 'duo_hardware', 'accessibility'] as HingeProviderKind[]).map((prov) => (
            <button
              key={prov}
              type="button"
              onClick={() => setHingeProviderKind(prov)}
              className={`px-2 py-0.5 rounded font-mono-tabular text-[11px] ${
                hingeProviderKind === prov
                  ? 'bg-[#2e241b] text-[#d4a853] border border-[#d4a853]/40'
                  : 'text-[#8a7c66]'
              }`}
            >
              {prov === 'simulated'
                ? 'SimulatedHingeProvider'
                : prov === 'duo_hardware'
                ? 'DuoHingeProvider'
                : 'AccessibilityHingeProvider'}
            </button>
          ))}
        </div>

        <div className="flex flex-wrap items-center gap-2">
          <span>{fr ? 'Profil thermique (ProcessInfo.thermalState) :' : 'Thermal profile (ProcessInfo.thermalState):'}</span>
          {(['nominal', 'fair', 'serious'] as const).map((th) => (
            <button
              key={th}
              type="button"
              onClick={() => setThermalState(th)}
              className={`px-2 py-0.5 rounded font-mono-tabular text-[11px] ${
                thermalState === th
                  ? 'bg-[#2e241b] text-[#d4a853] border border-[#d4a853]/40'
                  : 'text-[#8a7c66]'
              }`}
            >
              .{th}{' '}
              {th === 'fair'
                ? '(9 FPS)'
                : th === 'serious'
                ? fr
                  ? '(Tremblement sans caméra)'
                  : '(Tremor Fallback)'
                : '(14 FPS)'}
            </button>
          ))}
        </div>
      </div>

      {/* PAUSE MODAL (data-state="paused") */}
      {shellState === 'paused' && (
        <div
          role="dialog"
          aria-modal="true"
          aria-label="Pause"
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 p-4"
        >
          <div className="w-full max-w-md rounded-2xl border border-[#d4a853] bg-[#16120e] p-6 text-center space-y-4 shadow-2xl">
            <h2 className="text-2xl font-serif-display font-bold text-[#f3ead8]">
              {fr ? 'Service en pause' : 'Shift Paused'}
            </h2>
            <div className="flex flex-wrap justify-center gap-2">
              {renderLanguageSelector()}
              {renderVoiceTimbreSelector()}
            </div>
            <div className="grid grid-cols-3 gap-2 font-mono-tabular text-xs">
              <div className="rounded-lg bg-[#211a14] p-2.5">
                <div className="text-[10px] text-[#a7987e]">{fr ? 'MANCHE' : 'ROUND'}</div>
                <div className="text-base font-bold text-[#d4a853]">
                  {roundNumber}/{totalRounds}
                </div>
              </div>
              <div className="rounded-lg bg-[#211a14] p-2.5">
                <div className="text-[10px] text-[#a7987e]">{players[0].name}</div>
                <div className="text-base font-bold">{players[0].marks} MK</div>
              </div>
              <div className="rounded-lg bg-[#211a14] p-2.5">
                <div className="text-[10px] text-[#a7987e]">{players[1].name}</div>
                <div className="text-base font-bold">{players[1].marks} MK</div>
              </div>
            </div>
            <div className="flex flex-col gap-2">
              <button
                type="button"
                onClick={() => setShellState('playing')}
                className="w-full py-2.5 rounded-xl text-xs font-bold bg-[#d4a853] text-[#14110e]"
              >
                {fr ? 'Reprendre le service' : 'Resume Shift'}
              </button>
              <button
                type="button"
                onClick={() => startGameWithMode(gameMode)}
                className="w-full py-2.5 rounded-xl text-xs font-semibold bg-[#241d16] text-[#f3ead8]"
              >
                {fr ? 'Recommencer la partie' : 'Restart Match'}
              </button>
              <button
                type="button"
                onClick={() => setShellState('title')}
                className="w-full py-2.5 rounded-xl text-xs font-medium text-[#b8a98d] hover:text-[#f3ead8]"
              >
                {fr ? 'Retour à l’écran titre' : 'Return to Title Screen'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* GAME OVER MODAL (data-state="gameover") */}
      {shellState === 'gameover' && (
        <div
          role="dialog"
          aria-modal="true"
          aria-label={fr ? 'Résultats du service' : 'Shift Results'}
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/85 p-4"
        >
          <div className="w-full max-w-lg rounded-2xl border border-[#d4a853] bg-[#16120e] p-6 text-center space-y-4 shadow-2xl">
            <div className="text-xs font-mono-tabular text-[#d4a853]">
              {fr ? 'FIN DE SERVICE · PROTOCOLE FINAL' : 'SHIFT COMPLETE · FINAL LEDGER'}
            </div>
            <h2 className="text-3xl font-serif-display font-bold text-[#f3ead8]">
              {players[0].marks >= players[1].marks
                ? `${fr ? 'Vainqueur' : 'Winner'}: ${players[0].name}`
                : `${fr ? 'Vainqueur' : 'Winner'}: ${players[1].name}`}
            </h2>
            <div className="grid grid-cols-2 gap-3 font-mono-tabular text-xs">
              {players.map((p) => (
                <div key={p.id} className="rounded-xl border border-[#d4a853]/30 bg-[#211a14] p-3">
                  <div className="font-sans font-semibold text-sm text-[#f3ead8]">{p.name}</div>
                  <div className="text-xl font-bold text-[#d4a853] mt-1">{p.marks} MK</div>
                  <div className="text-[10px] text-[#a7987e] mt-0.5">
                    {fr ? 'Fouilles réussies :' : 'Inspections won:'} {p.inspectionsWon}
                  </div>
                </div>
              ))}
            </div>
            <button
              type="button"
              data-start="true"
              onClick={() => startGameWithMode(gameMode)}
              className="w-full py-3 rounded-xl text-sm font-bold bg-[#d4a853] hover:bg-[#e0b865] text-[#14110e]"
            >
              {fr ? 'Jouer une nouvelle partie' : 'Play New Match'}
            </button>
          </div>
        </div>
      )}

      {architectModalTab && (
        <ArchitectAndBalanceModal
          lang={lang}
          activeTab={architectModalTab}
          onClose={() => setArchitectModalTab(null)}
          onSwitchTab={(t) => setArchitectModalTab(t)}
        />
      )}
    </main>
  );
}
export default App;
