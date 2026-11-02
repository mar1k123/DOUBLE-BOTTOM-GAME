import React from 'react';
import { SilhouetteKind } from '../game/deckData';
import { GameLanguage } from '../game/i18n';

export const ItemEngravingIcon: React.FC<{
  itemId: string;
  className?: string;
}> = ({ itemId, className = 'w-12 h-12' }) => {
  switch (itemId) {
    case 'orange':
      return (
        <svg viewBox="0 0 64 64" className={className} aria-hidden="true">
          <circle cx="32" cy="36" r="19" fill="#d97724" stroke="#18120e" strokeWidth="2.5" />
          <path d="M32 17 C36 9, 46 9, 48 16 C41 19, 36 19, 32 17 Z" fill="#4d7c43" stroke="#18120e" strokeWidth="2" />
          <circle cx="25" cy="30" r="2" fill="#f7c873" />
          <circle cx="38" cy="42" r="1.8" fill="#9c4211" />
          <path d="M20 36 A12 12 0 0 0 32 48" fill="none" stroke="#f7c873" strokeWidth="1.5" strokeDasharray="2 2" />
        </svg>
      );
    case 'cheese':
      return (
        <svg viewBox="0 0 64 64" className={className} aria-hidden="true">
          <polygon points="10,44 54,44 46,20 18,26" fill="#e0a938" stroke="#18120e" strokeWidth="2.5" />
          <polygon points="10,44 18,26 46,20 54,28 54,44" fill="#d4962a" stroke="#18120e" strokeWidth="2" />
          <circle cx="26" cy="36" r="3.5" fill="#8f5f14" />
          <circle cx="39" cy="33" r="2.5" fill="#8f5f14" />
          <circle cx="45" cy="39" r="2" fill="#8f5f14" />
        </svg>
      );
    case 'watch':
      return (
        <svg viewBox="0 0 64 64" className={className} aria-hidden="true">
          <rect x="26" y="6" width="12" height="52" rx="3" fill="#6b3e26" stroke="#18120e" strokeWidth="2" />
          <circle cx="32" cy="32" r="15" fill="#d4a853" stroke="#18120e" strokeWidth="2.5" />
          <circle cx="32" cy="32" r="11" fill="#f3ead8" stroke="#18120e" strokeWidth="1.5" />
          <line x1="32" y1="32" x2="32" y2="24" stroke="#18120e" strokeWidth="2" strokeLinecap="round" />
          <line x1="32" y1="32" x2="39" y2="32" stroke="#991b1b" strokeWidth="1.8" strokeLinecap="round" />
        </svg>
      );
    case 'wine':
      return (
        <svg viewBox="0 0 64 64" className={className} aria-hidden="true">
          <path d="M27 8 H37 V18 L43 27 V54 C43 56 41 58 39 58 H25 C23 58 21 56 21 54 V27 L27 18 Z" fill="#681823" stroke="#18120e" strokeWidth="2.5" />
          <rect x="24" y="31" width="16" height="14" fill="#e8dcc4" stroke="#18120e" strokeWidth="1.5" />
          <rect x="28" y="6" width="8" height="5" fill="#b45309" />
        </svg>
      );
    case 'microfilm':
      return (
        <svg viewBox="0 0 64 64" className={className} aria-hidden="true">
          <circle cx="28" cy="32" r="16" fill="#b8862d" stroke="#18120e" strokeWidth="2.5" />
          <circle cx="28" cy="32" r="6" fill="#29221c" stroke="#18120e" strokeWidth="2" />
          <circle cx="28" cy="21" r="2.5" fill="#18120e" />
          <circle cx="28" cy="43" r="2.5" fill="#18120e" />
          <circle cx="17" cy="32" r="2.5" fill="#18120e" />
          <path d="M40 24 H56 V40 H40" fill="#3b332b" stroke="#18120e" strokeWidth="2" />
          <line x1="44" y1="27" x2="53" y2="27" stroke="#f3ead8" strokeWidth="1.5" strokeDasharray="2 2" />
          <line x1="44" y1="37" x2="53" y2="37" stroke="#f3ead8" strokeWidth="1.5" strokeDasharray="2 2" />
        </svg>
      );
    case 'radio':
      return (
        <svg viewBox="0 0 64 64" className={className} aria-hidden="true">
          <rect x="10" y="20" width="44" height="32" rx="4" fill="#4a3525" stroke="#18120e" strokeWidth="2.5" />
          <line x1="18" y1="20" x2="32" y2="6" stroke="#d4a853" strokeWidth="2.5" strokeLinecap="round" />
          <rect x="15" y="25" width="20" height="12" fill="#e8d5a7" stroke="#18120e" strokeWidth="1.5" />
          <circle cx="44" cy="31" r="4" fill="#d4a853" stroke="#18120e" strokeWidth="1.5" />
          <circle cx="44" cy="43" r="4" fill="#b8862d" stroke="#18120e" strokeWidth="1.5" />
          <line x1="15" y1="43" x2="35" y2="43" stroke="#d4a853" strokeWidth="2" />
        </svg>
      );
    case 'gold':
      return (
        <svg viewBox="0 0 64 64" className={className} aria-hidden="true">
          <polygon points="8,46 56,46 48,22 16,22" fill="#eab308" stroke="#18120e" strokeWidth="2.5" />
          <polygon points="14,40 50,40 44,26 20,26" fill="#facc15" stroke="#854d0e" strokeWidth="1.5" />
          <text x="32" y="36" textAnchor="middle" fontSize="9" fontWeight="bold" fill="#422006">999.9</text>
        </svg>
      );
    case 'antique':
      return (
        <svg viewBox="0 0 64 64" className={className} aria-hidden="true">
          <path d="M24 10 H40 L37 20 C45 26 46 40 38 48 L41 56 H23 L26 48 C18 40 19 26 27 20 Z" fill="#b45309" stroke="#18120e" strokeWidth="2.5" />
          <path d="M24 16 C14 18 14 32 23 34" fill="none" stroke="#d4a853" strokeWidth="2.5" />
          <path d="M40 16 C50 18 50 32 41 34" fill="none" stroke="#d4a853" strokeWidth="2.5" />
          <line x1="22" y1="34" x2="42" y2="34" stroke="#18120e" strokeWidth="2" strokeDasharray="3 2" />
        </svg>
      );
    default:
      return (
        <svg viewBox="0 0 64 64" className={className} aria-hidden="true">
          <rect x="10" y="16" width="44" height="32" rx="4" fill="#3a2618" stroke="#d4a853" strokeWidth="2" strokeDasharray="4 3" />
          <path d="M18 32 H46" stroke="#d4a853" strokeWidth="2" />
        </svg>
      );
  }
};

// Silhouettes for Slit Levels 2 and 3 (with colorblind pattern support — Section 13)
export const SilhouetteShape: React.FC<{
  silhouette: SilhouetteKind;
  tint?: 'neutral' | 'legal_green' | 'contraband_red';
  colorblindMode?: boolean;
  lang?: GameLanguage;
}> = ({ silhouette, tint = 'neutral', colorblindMode = false, lang = 'en' }) => {
  const fill =
    tint === 'legal_green'
      ? '#15803d'
      : tint === 'contraband_red'
      ? '#b91c1c'
      : '#1a1714';
  const stroke =
    tint === 'legal_green'
      ? '#4ade80'
      : tint === 'contraband_red'
      ? '#f87171'
      : '#a89878';

  const patternId = `pat_${silhouette}_${tint}`;

  return (
    <div className="relative flex flex-col items-center justify-center p-2 rounded-lg bg-[#0d0c0a] border border-[#3a3227]">
      <svg viewBox="0 0 64 64" className="w-14 h-14" aria-hidden="true">
        <defs>
          <pattern id={`${patternId}_dots`} width="8" height="8" patternUnits="userSpaceOnUse">
            <circle cx="4" cy="4" r="1.5" fill="rgba(255,255,255,0.45)" />
          </pattern>
          <pattern id={`${patternId}_stripes`} width="8" height="8" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
            <line x1="0" y1="0" x2="0" y2="8" stroke="rgba(255,255,255,0.5)" strokeWidth="2.5" />
          </pattern>
        </defs>

        {silhouette === 'small_round' || silhouette === 'small_spool' ? (
          <circle cx="32" cy="32" r="17" fill={fill} stroke={stroke} strokeWidth="2.5" />
        ) : silhouette === 'small_flat' ? (
          <g>
            <rect x="26" y="8" width="12" height="48" rx="3" fill={fill} stroke={stroke} strokeWidth="2" />
            <circle cx="32" cy="32" r="14" fill={fill} stroke={stroke} strokeWidth="2.5" />
          </g>
        ) : silhouette === 'medium_wedge' ? (
          <polygon points="10,44 54,44 46,20 16,26" fill={fill} stroke={stroke} strokeWidth="2.5" />
        ) : silhouette === 'tall_bottle' || silhouette === 'tall_vase' ? (
          <path d="M25 10 H39 L37 22 L44 30 V54 H20 V30 L27 22 Z" fill={fill} stroke={stroke} strokeWidth="2.5" />
        ) : silhouette === 'heavy_bar' ? (
          <polygon points="8,46 56,46 48,22 16,22" fill={fill} stroke={stroke} strokeWidth="2.5" />
        ) : (
          <rect x="12" y="20" width="40" height="28" rx="4" fill={fill} stroke={stroke} strokeWidth="2.5" />
        )}

        {colorblindMode && tint === 'legal_green' && (
          <rect x="8" y="8" width="48" height="48" fill={`url(#${patternId}_dots)`} pointerEvents="none" />
        )}
        {colorblindMode && tint === 'contraband_red' && (
          <rect x="8" y="8" width="48" height="48" fill={`url(#${patternId}_stripes)`} pointerEvents="none" />
        )}
      </svg>

      {tint !== 'neutral' && (
        <span className="mt-1 text-[10px] font-mono-tabular tracking-wider text-[#e8dcc4]">
          {tint === 'legal_green'
            ? lang === 'fr'
              ? 'VERT · CONFORME'
              : 'GRN · LEGAL'
            : lang === 'fr'
            ? 'ROUGE · SUSPECT'
            : 'RED · SUSPECT'}
        </span>
      )}
    </div>
  );
};

// Procedural Passport Portrait (Section 3: silhouette, hat, scarf, glasses — 12 combinations)
export const ProceduralPassportPortrait: React.FC<{
  index: number;
  country: 'altavia' | 'nordmark';
  className?: string;
}> = ({ index, country, className = 'w-20 h-24' }) => {
  const norm = Math.abs(index) % 12;
  const hasHat = Math.floor(norm / 3) % 2 === 1 || norm % 2 === 0;
  const hasScarf = Math.floor(norm / 2) % 2 === 1;
  const hasGlasses = norm % 3 === 1;

  return (
    <div
      className={`relative overflow-hidden rounded border border-[#8c734b] bg-[#dfd3bc] text-[#1c1814] shadow-inner ${className}`}
    >
      <svg viewBox="0 0 80 96" className="w-full h-full" aria-hidden="true">
        <rect width="80" height="96" fill="#dfd3bc" />
        <circle cx="40" cy="40" r="34" fill={country === 'altavia' ? '#c9b896' : '#bfc8c2'} opacity="0.55" />

        <path d="M10 96 C12 70, 68 70, 70 96 Z" fill="#26211d" />
        <polygon points="30,72 40,88 50,72" fill="#efe6d5" />

        <rect x="35" y="54" width="10" height="16" fill="#3b322c" />
        <ellipse cx="40" cy="42" rx="14" ry="17" fill="#302822" />

        {hasGlasses && (
          <g stroke="#d4a853" strokeWidth="2" fill="#14110e">
            <circle cx="34" cy="41" r="4.5" />
            <circle cx="46" cy="41" r="4.5" />
            <line x1="38.5" y1="41" x2="41.5" y2="41" />
          </g>
        )}

        {hasHat && (
          <g>
            <ellipse cx="40" cy="27" rx="24" ry="4.5" fill="#181411" />
            <path d="M24 27 L28 13 H52 L56 27 Z" fill="#231d18" />
            <rect x="26" y="23" width="28" height="3" fill="#8c6d32" />
          </g>
        )}

        {hasScarf && (
          <g>
            <rect x="27" y="60" width="26" height="9" rx="3" fill="#7c2d12" stroke="#181411" strokeWidth="1.2" />
            <path d="M44 68 L48 86 L39 86 L40 68 Z" fill="#7c2d12" />
          </g>
        )}
      </svg>
      <div className="absolute bottom-0.5 right-1 text-[9px] font-mono-tabular text-[#4a3e2e]">
        #0{norm + 1}
      </div>
    </div>
  );
};
