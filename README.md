<div align="center">

# 🧳 DOUBLE BOTTOM · DOUBLE FOND
### *Outside: Passport & Declaration. Inside: Suitcase & Contraband.*

**A Asymmetric Social Deduction & Bluffing Party Game Engineered for the Foldable iPhone Duo**

[![Platform](https://img.shields.io/badge/Platform-iOS%2027.1%20%7C%20Web%20Simulator-d4a853?style=for-the-badge)](#)
[![Swift](https://img.shields.io/badge/Swift-6.0%20Strict%20Concurrency-F05138?style=for-the-badge&logo=swift&logoColor=white)](#)
[![React](https://img.shields.io/badge/Web%20Rig-React%2019%20%2B%20TypeScript-61DAFB?style=for-the-badge&logo=react&logoColor=14110e)](#)
[![Voiceover](https://img.shields.io/badge/Voiceover-Gemini%203.8%20Neural%20TTS-4ade80?style=for-the-badge)](#)
[![Languages](https://img.shields.io/badge/Languages-English%20%F0%9F%87%AC%F0%9F%87%A7%20%7C%20Fran%C3%A7ais%20%F0%9F%87%AB%F0%9F%87%B7-e6d5b8?style=for-the-badge)](#)

---

*1964. The rain-slicked Alpine border crossing at **Checkpoint "Swallow"** between Sunny Altavia and the Northern Directorate of Nordmark. One device. Two simultaneous screens. A physical brass hinge that turns every degree of opening into a high-stakes game of nerve.*

</div>

---

## 📖 Table of Contents

- [Overview & Core Concept](#-overview--core-concept)
- [Why Foldable Hardware Matters (`iPhone Duo`)](#-why-foldable-hardware-matters-iphone-duo)
- [Complete Round Loop & Mechanics](#-complete-round-loop--mechanics)
- [Hinge State Machine & Hysteresis](#-hinge-state-machine--hysteresis)
- [Type-Level Zero Secret Leakage](#-type-level-zero-secret-leakage)
- [Nervometer-64 & Thermal-Aware Fallback](#-nervometer-64--thermal-aware-fallback)
- [Neural Voiceover Engine (`EN` / `FR`)](#-neural-voiceover-engine-en--fr)
- [Monte Carlo Balance Verification (10,000 Matches)](#-monte-carlo-balance-verification-10000-matches)
- [Repository Structure](#-repository-structure)
- [Getting Started (Web Simulator & Native iOS)](#-getting-started-web-simulator--native-ios)
- [Testing & Verification](#-testing--verification)

---

## 🕵️ Overview & Core Concept

**DOUBLE BOTTOM** (*French title:* **DOUBLE FOND**) is a local pass-and-play bluffing party game for **2–6 players** (plus a **Solo vs. Captain Vera AI** mode and a **40-second Storefront Demo**) designed around the physical geometry of a book-style foldable smartphone (**iPhone Duo**):

- **Outer Screen (`5.4″` Portrait — Public Passport & Customs Desk)**: Always visible to the table. Displays the Courier's passport, official cargo declaration, passport gratuity ("bribe"), the **Nervometer-64** stress gauge, and the **UNDER INSPECTION** warning eye.
- **Inner Screen (`7.6″` Landscape — Secret Diplomatic Valise)**: Visible only when the device is unfolded or cracked open. Acts as the physical interior of the Courier's leather suitcase, complete with velvet compartments, contraband items, and a gyroscopic **False Bottom** hidden compartment.
- **Physical Hinge (`θ = 0°..180°`)**: Replaces abstract UI buttons with tactile physical tension. Peeking inside the suitcase through a narrow **`3°–25°` slit** reveals progressive clues, while opening the lid past **`25°`** irreversibly breaks the lead customs seal and commits the Inspector to an official search.

---

## 📱 Why Foldable Hardware Matters (`iPhone Duo`)

| Hardware Capability | Gameplay Role in **DOUBLE BOTTOM** |
| :--- | :--- |
| **Dual Simultaneous Displays (`OuterScene` + `InnerScene`)** | Enforces physical information asymmetry on a single device without requiring multiple phones or companion apps. |
| **Continuous Hinge Angle Sensor (`0°–180°`)** | Powers the 3-level **Slit Peek (`SLIT`)** mechanic (`3°–10°` Gross Weight, `10°–18°` Silhouettes, `18°–25°` Backlit Tint) and the **`25°` Point of No Return**. |
| **Core Haptics + Procedural Audio** | Emits brass latch clicks on sealing (`≤ 3°`), spring tension ticks every `5°` inside the slit, and a sharp lead-seal snap at `25°`. |
| **CoreMotion Gyroscope (`CMDeviceMotion`)** | Powers the **False Bottom Search** mini-game (two smooth `±25°` tilts within 6 seconds to hear hidden cargo slide) and the **Hand-Tremor Fallback** when the camera is off. |
| **Dual-Facing Cameras (`Vision` RGB)** | Optional on-device facial micro-jitter gauge for the **Nervometer-64** and dual-camera **Inspection Protocol** souvenir stamp card. |

---

## 🎲 Complete Round Loop & Mechanics

### 1. Deck Composition (`67 Cards`)
- **4 Legal Goods Categories (`44 cards`)**:
  - 🍊 **Solana Oranges / Oranges de Solana** (`12 cards` · Value `3` · Fine `2` · Weight `1 kg`)
  - 🧀 **Alpine Cheese / Fromage alpin** (`12 cards` · Value `4` · Fine `3` · Weight `2 kg`)
  - ⌚ **Brass Watches / Montres en laiton** (`10 cards` · Value `5` · Fine `4` · Weight `1 kg`)
  - 🍷 **Ruby Wine / Vin rubis** (`10 cards` · Value `5` · Fine `3` · Weight `3 kg`)
- **Contraband Items (`21 cards`, `category = null`)**:
  - 📻 **Tube Radio** (`6` · V:`8` · F:`7` · W:`2 kg`)
  - 🎞️ **Microfilm** (`6` · V:`9` · F:`8` · W:`1 kg`)
  - 🪙 **Gold Ingots** (`4` · V:`12` · F:`11` · W:`4 kg`)
  - 💎 **Diamond Brooch** (`3` · V:`13` · F:`11` · W:`1 kg`)
  - 🏺 **Ancient Relic** (`2` · V:`15` · F:`13` · W:`3 kg`)
- **Special Cards (`2 cards`)**:
  - 🧳 **False Bottom / Double fond**: Unlocks 1 secret compartment underneath the velvet tray.

### 2. Phase-by-Phase Flow
1. **`DEAL` & Mulligan**: The Courier draws 6 cards and may discard up to 2 cards once to redraw. The Inspector receives `+1` Clue Token (up to a maximum of `5`).
2. **`PACKING` (`θ ≥ 100°`)**:
   - The Courier packs **`1–5` visible items** into the suitcase slots (and optionally `1` secret item into the **False Bottom** if holding the card).
   - Selects **one declared legal category** (the count `n` automatically equals the number of visible items) and optionally slips a **Passport Gratuity (`0–15 MK`)** inside the passport.
   - Folds the iPhone Duo shut (`θ ≤ 3°` held for `250 ms`) to engage the lead seal.
3. **`SEALED` & `INTERROGATION` (`θ ≤ 3°`)**:
   - The Courier hands the closed phone to the Inspector.
   - On the Outer Screen, the Inspector reviews the passport declaration and may spend **`1 Clue Token`** to run the **X-Ray & Nervometer-64** scan.
4. **`SLIT` Peek (`3° < θ < 25°`, costs `1 Clue Token` per round)**:
   - **Level 1 (`3°–10°`)**: Spring scale reveals total gross weight vs. expected declared weight (`expectedWeight × n`), including any hidden False Bottom weight.
   - **Level 2 (`10°–18°`)**: Narrow optical slit reveals grayscale geometric silhouettes of visible items (`circle`, `square`, `tall`, `flat`) in shuffled order.
   - **Level 3 (`18°–25°`)**: Backlit customs lamp tints each silhouette **Green (Legal)** or **Red (Suspect)** with **75% accuracy** (plus colorblind hatching patterns).
5. **`DECISION` & `INSPECTION` (`θ ≥ 25°`)**:
   - **Clear & Pass**: All items (including contraband) pass; Courier earns their full value.
   - **Accept Gratuity & Pass**: Cargo passes; Inspector pockets the passport tip from the Courier.
   - **Open & Inspect (`θ ≥ 25°`)**: Irreversibly breaks the lead seal (any gratuity is immediately returned to the Courier):
     - **Branch 1 — 100% Honest Cargo**: Courier earns item values **plus `3 × n MK` moral compensation** paid by the Inspector.
     - **Branch 2 — Visible Contraband / Undeclared Goods**: Honest items pass; illegal items are confiscated; Courier pays their fine to the Inspector (`+50%` bonus if the Inspector never used the Slit).
     - **Branch 3 & 4 — False Bottom Tilt Search (`6 s`)**: Inspector tilts the phone twice (`±25°`) to listen for a sliding compartment. If found, the hidden item is confiscated and fined; if missed under an honest top tray, the hidden contraband slips through, though the Courier forfeits moral compensation.

---

## ⚙️ Hinge State Machine & Hysteresis

```text
  0°          3°           10°            18°            25°                 100°        180°
  ├───────────┼─────────────┼──────────────┼──────────────┼────────────────────┼───────────┤
  │  SEALED   │ SLIT LVL 1  │  SLIT LVL 2  │  SLIT LVL 3  │     COMMITTED      │   OPEN    │
  │ (Locked)  │ Gross Weight│ Silhouettes  │ 75% Backlight│ Point of No Return │ Full View │
```

- **250 ms Seal Debounce**: Prevents accidental sealing from brief hinge bounce.
- **2° Anti-Flicker Hysteresis**: Downward transitions require crossing `threshold - 2°` (`8°`, `16°`, `1°`) so hand tremor never causes UI flicker between Slit levels.
- **Irreversible Commit Latch**: Once `θ ≥ 25°` is crossed during `DECISION` / `SLIT`, `isCommittedInInspection` latches to `true`. Folding the phone back below `15°` triggers a `POST_COMMIT_LOCK` warning instead of re-sealing the suitcase.

---

## 🔒 Type-Level Zero Secret Leakage

The architecture enforces strict separation between **Secret State** and **Public Projection** (`src/game/presentationPolicy.ts` & `Sources/Presentation/PresentationPolicy.swift`):

- `PublicProjection` — the only data structure passed to `OuterScreenView` — **physically lacks fields** for `hand`, `packedCase.visibleItems`, `packedCase.hiddenItem`, or `hasFalseBottomCard`.
- Automated unit tests verify across every phase and hinge angle (`0°..180°`) that the Outer Screen never leaks secret card identities, silhouettes, or false-bottom presence.

---

## 📈 Nervometer-64 & Thermal-Aware Fallback

- **Multi-Modal Biometric Prop**: Combines normalized facial landmark micro-jitter (`Vision` at 14 FPS) and gyroscope hand-tremor variance (`CoreMotion` at 50 Hz) into an EMA-smoothed score (`0..100 ± 12`).
- **Privacy & Thermal Safety**:
  - **Camera OFF by default**: Operates seamlessly on gyroscope hand-tremor alone (`100% playable without camera`).
  - **Zero disk writes**: Camera frames are processed strictly in RAM (`CVPixelBuffer`) and discarded immediately.
  - **Thermal throttling (`ProcessInfo.thermalState`)**: Automatically steps down Vision from `14 FPS` (`.nominal`) to `9 FPS` (`.fair`) and disables camera capture altogether in `.serious` / `.critical` states.

---

## 🎙️ Neural Voiceover Engine (`EN` / `FR`)

Captain Vera Lisitsyna's **61 border-noir voice lines** are fully localized in **English (`🇬🇧 EN`)** and **French (`🇫🇷 FR`)** and powered by a hybrid audio architecture:

1. **Server-Side Gemini 3.8 Neural TTS (`gemini-3.8-flash-lite-tts`)**:
   - Generates 24 kHz mono WAV speech on demand via `/api/tts` with 1960s cinema persona styling.
   - **3 Selectable Voice Timbres** in the live UI:
     - `🎙️ Zephyr` — Soft, expressive, melodic narration *(default)*
     - `🎙️ Kore` — Composed, velvet contrabass cinema tone
     - `🎙️ Charon` — Deep, smoky midnight radio voice
   - **Two-Tier LRU Caching**: Both the Express backend and the browser Web Audio engine cache synthesized buffers in RAM for zero-latency replay.
2. **Web Audio Studio Warmth Chain**:
   - Routes neural speech through a two-stage Biquad EQ (`+2.5 dB` low-shelf warmth at `185 Hz` and `-2.5 dB` silky roll-off above `6.8 kHz`) preceded by a soft acoustic tube chime.
3. **Offline Fallback**:
   - Gracefully falls back to smooth, single-utterance Web Speech synthesis (`AVSpeechSynthesizer` with `.premium` / `.enhanced` voice ranking on iOS) when offline.

---

## 📊 Monte Carlo Balance Verification (10,000 Matches)

The repository includes a deterministic **Monte Carlo Balance Simulator** (`src/game/balanceSimulator.ts` & `Sources/Simulation/BalanceSimulator.swift`) that pits **4 Courier policies** (`always_honest`, `always_smuggler`, `mixed_bluffer`, `briber`) against **4 Inspector policies** (`always_inspect`, `never_inspect`, `nervometer_reader`, `mixed_detective`):

| Metric | Target | Verified Result (`v1.1 Balanced`) |
| :--- | :---: | :---: |
| **Pure Strategy Dominance vs. Mixed** | `≤ 25%` | **`+0.0%` (`PASS`)** |
| **Equilibrium Inspection Rate** | `35% – 65%` | **`49.6%` (`PASS`)** |
| **3-Player Match Duration (6 Rounds)** | `18 – 28 min` | **`22.4 min` (`PASS`)** |

---

## 🗂️ Repository Structure

```text
├── server.ts                         # Express + Vite server & /api/tts Gemini 3.8 Neural TTS endpoint
├── src/
│   ├── App.tsx                       # Dual-screen iPhone Duo simulator shell, EN/FR & Voice Timbre controls
│   ├── components/
│   │   ├── OuterScreenView.tsx       # 5.4" Public Passport, Nervometer-64 & Inspector controls
│   │   ├── InnerScreenView.tsx       # 7.6" Secret Valise, 3-level Slit Peek, Gyro Tilt & Ledger
│   │   ├── ProceduralArt.tsx         # 100% procedural SVG crests, stamps, card icons & hatching patterns
│   │   └── ArchitectAndBalanceModal.tsx # Interactive 4×4 Monte Carlo simulator & Swift code inspector
│   └── game/
│       ├── i18n.ts                   # English (en) & French (fr) language definitions
│       ├── tuning.ts                 # Centralized game-design & hinge angle constants
│       ├── deckData.ts               # 67-card deck specification (EN/FR localized)
│       ├── rules.ts                  # Pure deterministic state machine, scoring & slit hint generator
│       ├── presentationPolicy.ts     # Pure projection router guaranteeing zero secret leakage
│       ├── captainLines.ts           # 61 bilingual (EN/FR) Captain Vera Lisitsyna lines
│       ├── audioSynth.ts             # Web Audio synthesizer + Gemini 3.8 Neural TTS client
│       ├── balanceSimulator.ts       # 10,000-match Monte Carlo policy matrix simulator
│       └── rules.test.ts             # 11 deterministic unit tests (node:test)
└── ios/DoubleBottom/                 # Native iOS 27.1 / Swift 6 / Xcode 27.1 package
    ├── Package.swift
    ├── DoubleBottom.xcodeproj/
    ├── Sources/
    │   ├── App/                      # Multi-scene UIWindowSceneDelegate + DuoSimulatorView
    │   ├── Core/                     # Tuning, DeckData, GameRules, GameStateMachine & EN/FR xcstrings
    │   ├── Sensors/                  # HingeSensorProvider, MotionTiltDetector & NervometerEngine
    │   ├── Presentation/             # PresentationPolicy, OuterScreenView, InnerScreenView, SlitPeekView
    │   ├── Rendering3D/              # RealityKit procedural suitcase meshes & Metal slit shader
    │   ├── Audio/                    # ProceduralAudioEngine, HapticManager & CaptainVoiceService (EN/FR)
    │   └── Simulation/               # Swift Monte Carlo BalanceSimulator CLI & report generator
    └── Tests/DoubleBottomTests/      # XCTest suite covering all 5 inspection branches & privacy invariants
```

---

## 🚀 Getting Started (Web Simulator & Native iOS)

### 1. Interactive Web Simulator (React + Express + Gemini Neural TTS)

```bash
# 1. Install dependencies
npm install

# 2. Configure your Gemini API key for neural voiceover (optional — falls back to browser TTS if omitted)
export GEMINI_API_KEY="your_api_key_here"

# 3. Start the full-stack server on http://localhost:3000
npm run dev
```

#### Keyboard Shortcuts in the Web Simulator
- **`[` / `]`**: Decrease / Increase physical hinge angle `θ` (`0°..180°`)
- **`Enter` / `Space`**: Start shift from the Title Screen
- **`P`**: Toggle Pause modal
- **`?autostart=1`**: URL query parameter to jump straight into an active shift

### 2. Native iOS 27.1 / Swift 6 Package (`ios/DoubleBottom`)

1. Open `ios/DoubleBottom/DoubleBottom.xcodeproj` or `ios/DoubleBottom/Package.swift` in **Xcode 27.1+**.
2. Select the **`DoubleBottom`** scheme and target **iPhone Duo (iOS 27.1 Simulator)** or any standard iPhone / iPad (automatically activates the side-by-side `DuoSimulatorView` rig).
3. Press **`Cmd + R`** to build and run, or **`Cmd + U`** to execute the `DoubleBottomTests` suite.

---

## 🧪 Testing & Verification

Run the deterministic unit test suite (covering deck invariants, all 5 inspection scoring branches, zero-balance floor, hinge hysteresis, zero secret leakage, synthetic Nervometer profiles, and the 16-cell Monte Carlo balance simulation):

```bash
npx tsx --test src/game/rules.test.ts
```

Type-check and build the production bundle:

```bash
npm run lint
npm run build
```

---

<div align="center">
  <sub>Built with zero external binary assets · 100% Procedural Vector & Shader Graphics · Bilingual English & French Edition</sub>
</div>
