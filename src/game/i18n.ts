export type GameLanguage = 'en' | 'fr';

export const LANGUAGE_LABELS: Record<GameLanguage, { short: string; full: string; flag: string }> = {
  en: { short: 'EN', full: 'English', flag: '🇬🇧' },
  fr: { short: 'FR', full: 'Français', flag: '🇫🇷' },
};
