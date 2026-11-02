import 'dotenv/config';
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import { createServer as createViteServer } from 'vite';
import { GoogleGenAI } from '@google/genai';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const PORT = 3000;

// In-memory LRU cache for synthesized neural WAV clips so repeated lines play with zero latency
const ttsCache = new Map<string, string>();
const MAX_CACHE_ENTRIES = 160;

const ALLOWED_VOICES = new Set(['Kore', 'Zephyr', 'Charon', 'Puck', 'Fenrir']);

function getGenAIClient(): GoogleGenAI | null {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) return null;
  return new GoogleGenAI({
    apiKey,
    httpOptions: {
      headers: {
        'User-Agent': 'aistudio-build',
      },
    },
  });
}

async function startServer() {
  const app = express();
  app.use(express.json({ limit: '1mb' }));

  // Neural Text-to-Speech endpoint powered by Gemini 3.8 Flash Lite TTS
  app.post('/api/tts', async (req, res) => {
    try {
      const rawText = typeof req.body?.text === 'string' ? req.body.text.trim() : '';
      const lang = req.body?.lang === 'fr' ? 'fr' : 'en';
      const requestedVoice = typeof req.body?.voiceName === 'string' ? req.body.voiceName : '';
      const voiceName = ALLOWED_VOICES.has(requestedVoice)
        ? requestedVoice
        : lang === 'fr'
        ? 'Zephyr'
        : 'Kore';

      if (!rawText) {
        res.status(400).json({ error: 'Missing text for speech synthesis' });
        return;
      }

      const cleanText = rawText
        .replace(/[«»"""]/g, '')
        .replace(/\s+/g, ' ')
        .trim()
        .slice(0, 600);

      const cacheKey = `${lang}:${voiceName}:${cleanText}`;
      const cachedWav = ttsCache.get(cacheKey);
      if (cachedWav) {
        res.json({
          audioBase64: cachedWav,
          mimeType: 'audio/wav',
          voiceName,
          cached: true,
        });
        return;
      }

      const ai = getGenAIClient();
      if (!ai) {
        res.status(503).json({
          error: 'GEMINI_API_KEY is not configured on the server',
        });
        return;
      }

      const stylePrompt =
        lang === 'fr'
          ? 'Warm, natural, velvet-voiced French cinema actress from the 1960s, speaking French smoothly, expressively, and conversationally without any robotic cadence'
          : 'Warm, natural, velvet-voiced 1960s European cinema actress, speaking English smoothly, expressively, and conversationally without any robotic cadence';

      const response = await ai.models.generateContent({
        model: 'gemini-3.8-flash-lite-tts',
        contents: [
          {
            role: 'user',
            parts: [
              {
                text: cleanText,
                speechMetadata: {
                  style: stylePrompt,
                },
              },
            ],
          },
        ],
        config: {
          responseModalities: ['AUDIO'],
          speechConfig: {
            voiceConfig: {
              prebuiltVoiceConfig: {
                voiceName,
              },
            },
          },
        },
      });

      const base64Audio =
        response.candidates?.[0]?.content?.parts?.[0]?.inlineData?.data;

      if (!base64Audio) {
        res.status(502).json({ error: 'No audio data returned from Gemini TTS' });
        return;
      }

      if (ttsCache.size >= MAX_CACHE_ENTRIES) {
        const oldestKey = ttsCache.keys().next().value;
        if (oldestKey) ttsCache.delete(oldestKey);
      }
      ttsCache.set(cacheKey, base64Audio);

      res.json({
        audioBase64: base64Audio,
        mimeType: 'audio/wav',
        voiceName,
        cached: false,
      });
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : 'TTS synthesis failed';
      res.status(500).json({ error: message });
    }
  });

  if (process.env.NODE_ENV !== 'production') {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: 'spa',
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(__dirname, 'dist');
    app.use(express.static(distPath));
    app.get('*', (_req, res) => {
      res.sendFile(path.join(distPath, 'index.html'));
    });
  }

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on http://0.0.0.0:${PORT}`);
  });
}

startServer();
