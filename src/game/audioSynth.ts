import { GameLanguage } from './i18n';

export type NeuralVoiceTimbre = 'Kore' | 'Zephyr' | 'Charon';

export const VOICE_TIMBRE_LABELS: Record<
  NeuralVoiceTimbre,
  { en: string; fr: string; descEn: string; descFr: string }
> = {
  Kore: {
    en: 'Kore (Velvet Contrabass)',
    fr: 'Kore (Velours posé)',
    descEn: 'Warm, composed 1960s cinema voice',
    descFr: 'Voix de cinéma chaleureuse et posée',
  },
  Zephyr: {
    en: 'Zephyr (Soft & Expressive)',
    fr: 'Zephyr (Douce & Naturelle)',
    descEn: 'Bright, silky, melodic narration',
    descFr: 'Timbre doux, fluide et mélodieux',
  },
  Charon: {
    en: 'Charon (Deep Noir)',
    fr: 'Charon (Noir profond)',
    descEn: 'Low, smoky midnight radio tone',
    descFr: 'Timbre grave de radio nocturne',
  },
};

// Procedural Audio Synthesizer + Gemini Neural TTS Voiceover Engine
// Uses server-side `gemini-3.8-flash-lite-tts` for warm, lifelike human speech in English & French
// with Web Audio studio warmth filtering and smooth fallback.
class NoirAudioEngine {
  private ctx: AudioContext | null = null;
  public isMuted: boolean = false;
  public voiceTimbre: NeuralVoiceTimbre = 'Zephyr';
  private cachedVoices: SpeechSynthesisVoice[] = [];
  private audioBufferCache = new Map<string, AudioBuffer>();
  private currentSource: AudioBufferSourceNode | null = null;
  private activeRequestId: number = 0;

  constructor() {
    if (typeof window !== 'undefined' && 'speechSynthesis' in window) {
      const loadVoices = () => {
        try {
          this.cachedVoices = window.speechSynthesis.getVoices();
        } catch {
          // Ignore in restricted environments
        }
      };
      loadVoices();
      if ('onvoiceschanged' in window.speechSynthesis) {
        window.speechSynthesis.onvoiceschanged = loadVoices;
      }
    }
  }

  private ensureContext(): AudioContext | null {
    if (this.isMuted || typeof window === 'undefined') return null;
    if (!this.ctx) {
      const AudioCtx =
        window.AudioContext ||
        (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      if (AudioCtx) {
        this.ctx = new AudioCtx();
      }
    }
    if (this.ctx && this.ctx.state === 'suspended') {
      this.ctx.resume().catch(() => {});
    }
    return this.ctx;
  }

  public stopCurrentSpeech(): void {
    this.activeRequestId++;
    if (this.currentSource) {
      try {
        this.currentSource.stop();
        this.currentSource.disconnect();
      } catch {
        // Ignore if already stopped
      }
      this.currentSource = null;
    }
    if (typeof window !== 'undefined' && 'speechSynthesis' in window) {
      try {
        window.speechSynthesis.cancel();
      } catch {
        // Ignore
      }
    }
  }

  // Brass latch click when sealing suitcase (SEALED)
  playLatchSeal(): void {
    const ctx = this.ensureContext();
    if (!ctx) return;
    const now = ctx.currentTime;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(190, now);
    osc.frequency.exponentialRampToValueAtTime(68, now + 0.09);
    gain.gain.setValueAtTime(0.22, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.11);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start(now);
    osc.stop(now + 0.12);
  }

  // Subtle spring tick every 5° inside SLIT (3°..25°)
  playSlitTick(): void {
    const ctx = this.ensureContext();
    if (!ctx) return;
    const now = ctx.currentTime;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(580, now);
    osc.frequency.exponentialRampToValueAtTime(220, now + 0.025);
    gain.gain.setValueAtTime(0.08, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.03);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start(now);
    osc.stop(now + 0.035);
  }

  // Seal-break snap when crossing commitAngle (25°)
  playCommitSnap(): void {
    const ctx = this.ensureContext();
    if (!ctx) return;
    const now = ctx.currentTime;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(420, now);
    osc.frequency.exponentialRampToValueAtTime(110, now + 0.14);
    gain.gain.setValueAtTime(0.22, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.16);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start(now);
    osc.stop(now + 0.17);
  }

  // Heavy ink stamp thud on passport
  playStampThud(isClean: boolean): void {
    const ctx = this.ensureContext();
    if (!ctx) return;
    const now = ctx.currentTime;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(isClean ? 280 : 145, now);
    osc.frequency.exponentialRampToValueAtTime(isClean ? 390 : 72, now + 0.18);
    gain.gain.setValueAtTime(0.2, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.2);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start(now);
    osc.stop(now + 0.21);
  }

  // Gentle, warm acoustic chime before Captain Vera speaks (no harsh square wave clicks)
  playWarmChime(): void {
    const ctx = this.ensureContext();
    if (!ctx) return;
    const now = ctx.currentTime;

    const tone = ctx.createOscillator();
    const toneGain = ctx.createGain();
    tone.type = 'sine';
    tone.frequency.setValueAtTime(528.0, now);
    tone.frequency.exponentialRampToValueAtTime(660.0, now + 0.09);
    toneGain.gain.setValueAtTime(0.035, now);
    toneGain.gain.exponentialRampToValueAtTime(0.001, now + 0.16);
    tone.connect(toneGain);
    toneGain.connect(ctx.destination);
    tone.start(now);
    tone.stop(now + 0.17);
  }

  // Plays an AudioBuffer through a warm studio EQ chain (velvet low-mid boost + smooth high-shelf)
  private playBufferWithStudioWarmth(buffer: AudioBuffer, requestId: number): void {
    if (this.isMuted || requestId !== this.activeRequestId) return;
    const ctx = this.ensureContext();
    if (!ctx) return;

    const source = ctx.createBufferSource();
    source.buffer = buffer;

    // 1. Warm chest resonance (+2.5 dB at 185 Hz)
    const warmthFilter = ctx.createBiquadFilter();
    warmthFilter.type = 'lowshelf';
    warmthFilter.frequency.value = 185;
    warmthFilter.gain.value = 2.5;

    // 2. Silky de-esser / anti-metallic roll-off (-2.5 dB above 6.8 kHz)
    const silkFilter = ctx.createBiquadFilter();
    silkFilter.type = 'highshelf';
    silkFilter.frequency.value = 6800;
    silkFilter.gain.value = -2.5;

    const masterGain = ctx.createGain();
    masterGain.gain.value = 0.95;

    source.connect(warmthFilter);
    warmthFilter.connect(silkFilter);
    silkFilter.connect(masterGain);
    masterGain.connect(ctx.destination);

    this.currentSource = source;
    source.onended = () => {
      if (this.currentSource === source) {
        this.currentSource = null;
      }
    };
    source.start(0);
  }

  // Decodes base64 WAV returned by Gemini 3.8 TTS into a Web Audio AudioBuffer
  private async decodeBase64Wav(base64Audio: string): Promise<AudioBuffer | null> {
    const ctx = this.ensureContext();
    if (!ctx) return null;
    const binaryStr = window.atob(base64Audio);
    const len = binaryStr.length;
    const bytes = new Uint8Array(len);
    for (let i = 0; i < len; i++) {
      bytes[i] = binaryStr.charCodeAt(i);
    }
    return await ctx.decodeAudioData(bytes.buffer.slice(0));
  }

  // Selects the most natural browser voice if offline fallback is needed
  public selectBestFallbackVoice(lang: GameLanguage): SpeechSynthesisVoice | null {
    if (typeof window === 'undefined' || !('speechSynthesis' in window)) return null;
    const voices =
      this.cachedVoices.length > 0 ? this.cachedVoices : window.speechSynthesis.getVoices();
    if (!voices || voices.length === 0) return null;

    const prefix = lang === 'fr' ? 'fr' : 'en';
    const matching = voices.filter((v) => v.lang.toLowerCase().startsWith(prefix));
    const pool = matching.length > 0 ? matching : voices;

    const preferredKeywords =
      lang === 'fr'
        ? ['natural', 'online', 'neural', 'google français', 'denise', 'eloise', 'amélie', 'audrey', 'aurélie', 'marie']
        : ['natural', 'online', 'neural', 'google uk english female', 'sonia', 'libby', 'serena', 'samantha', 'ava', 'allison', 'karen'];

    let bestVoice = pool[0];
    let bestScore = -100;

    for (const v of pool) {
      const nameLower = v.name.toLowerCase();
      let score = 0;
      for (let i = 0; i < preferredKeywords.length; i++) {
        if (nameLower.includes(preferredKeywords[i])) {
          score += (preferredKeywords.length - i) * 5;
        }
      }
      if (!v.localService) score += 15;
      if (nameLower.includes('espeak') || nameLower.includes('compact')) score -= 50;
      if (score > bestScore) {
        bestScore = score;
        bestVoice = v;
      }
    }
    return bestVoice ?? null;
  }

  // Smooth single-utterance fallback (only used if server neural TTS is unreachable)
  private speakSmoothFallback(text: string, lang: GameLanguage, requestId: number): void {
    if (
      this.isMuted ||
      requestId !== this.activeRequestId ||
      typeof window === 'undefined' ||
      !('speechSynthesis' in window)
    ) {
      return;
    }
    try {
      window.speechSynthesis.cancel();
      const cleanText = text
        .replace(/[«»"""]/g, '')
        .replace(/\s*—\s*/g, ', ')
        .trim();

      const utter = new SpeechSynthesisUtterance(cleanText);
      const selectedVoice = this.selectBestFallbackVoice(lang);
      if (selectedVoice) {
        utter.voice = selectedVoice;
        utter.lang = selectedVoice.lang;
      } else {
        utter.lang = lang === 'fr' ? 'fr-FR' : 'en-GB';
      }
      // Natural pitch (1.0) and smooth conversational rate (0.97) to avoid robotic artifacts
      utter.pitch = 1.0;
      utter.rate = 0.97;
      utter.volume = 0.9;
      window.speechSynthesis.speak(utter);
    } catch {
      // Ignore in headless environments
    }
  }

  // Speaks Captain Vera Lisitsyna's line using Gemini Neural TTS (`gemini-3.8-flash-lite-tts`)
  // with studio warmth EQ, instant memory caching, and smooth fallback
  async speakCaptainLine(
    text: string,
    lang: GameLanguage = 'en',
    overrideTimbre?: NeuralVoiceTimbre
  ): Promise<void> {
    if (this.isMuted || typeof window === 'undefined') return;
    this.stopCurrentSpeech();
    const requestId = ++this.activeRequestId;
    const voiceName = overrideTimbre ?? this.voiceTimbre;

    const cleanText = text
      .replace(/[«»"""]/g, '')
      .replace(/\s+/g, ' ')
      .trim();
    if (!cleanText) return;

    this.playWarmChime();

    const cacheKey = `${lang}:${voiceName}:${cleanText}`;
    const cachedBuffer = this.audioBufferCache.get(cacheKey);
    if (cachedBuffer) {
      this.playBufferWithStudioWarmth(cachedBuffer, requestId);
      return;
    }

    try {
      const response = await fetch('/api/tts', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          text: cleanText,
          lang,
          voiceName,
        }),
      });

      if (!response.ok) {
        throw new Error(`TTS HTTP ${response.status}`);
      }

      const data = (await response.json()) as { audioBase64?: string };
      if (!data.audioBase64) {
        throw new Error('Empty audio payload');
      }

      const decodedBuffer = await this.decodeBase64Wav(data.audioBase64);
      if (decodedBuffer) {
        this.audioBufferCache.set(cacheKey, decodedBuffer);
        this.playBufferWithStudioWarmth(decodedBuffer, requestId);
        return;
      }
    } catch {
      // Fall back gracefully to smooth single-utterance Web Speech if offline
      this.speakSmoothFallback(cleanText, lang, requestId);
    }
  }
}

export const noirAudio = new NoirAudioEngine();
