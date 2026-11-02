import { GameLanguage } from './i18n';

export type CategoryID = 'oranges' | 'cheese' | 'watches' | 'wine';

export type SilhouetteKind =
  | 'small_round'
  | 'medium_wedge'
  | 'small_flat'
  | 'tall_bottle'
  | 'small_spool'
  | 'medium_box'
  | 'heavy_bar'
  | 'tall_vase';

export interface CategoryDef {
  id: CategoryID;
  name: string;
  nameEn: string;
  nameFr: string;
  legal: boolean;
  expectedWeight: number;
}

export interface ItemDef {
  id: string;
  name: string;
  nameEn: string;
  nameFr: string;
  category: CategoryID | null; // null = contraband (Section 4.2)
  value: number;
  fine: number;
  weight: number;
  count: number;
  silhouette: SilhouetteKind;
}

export interface SpecialDef {
  id: 'false_bottom';
  name: string;
  nameEn: string;
  nameFr: string;
  count: number;
}

export interface DeckDataSpec {
  version: string;
  categories: CategoryDef[];
  items: ItemDef[];
  specials: SpecialDef[];
}

export function getCategoryTitle(cat: CategoryDef | undefined, lang: GameLanguage): string {
  if (!cat) return lang === 'fr' ? 'Non déclaré' : 'Undeclared';
  return lang === 'fr' ? cat.nameFr : cat.nameEn;
}

export function getItemTitle(item: ItemDef, lang: GameLanguage): string {
  return lang === 'fr' ? item.nameFr : item.nameEn;
}

// Initial deck from Section 4.2 ("Before Balancing")
export const INITIAL_DECK_DATA: DeckDataSpec = {
  version: '1.0-initial',
  categories: [
    { id: 'oranges', name: 'Oranges', nameEn: 'Oranges', nameFr: 'Oranges', legal: true, expectedWeight: 1 },
    { id: 'cheese',  name: 'Cheese',  nameEn: 'Cheese',  nameFr: 'Fromage', legal: true, expectedWeight: 2 },
    { id: 'watches', name: 'Watches', nameEn: 'Watches', nameFr: 'Montres', legal: true, expectedWeight: 1 },
    { id: 'wine',    name: 'Wine',    nameEn: 'Wine',    nameFr: 'Vin',     legal: true, expectedWeight: 3 },
  ],
  items: [
    { id: 'orange',    name: 'Solana Oranges',  nameEn: 'Solana Oranges',  nameFr: 'Oranges de Solana',  category: 'oranges', value: 2,  fine: 2, weight: 1, count: 16, silhouette: 'small_round' },
    { id: 'cheese',    name: 'Nordmark Cheese', nameEn: 'Nordmark Cheese', nameFr: 'Fromage du Nordmark', category: 'cheese',  value: 3,  fine: 3, weight: 2, count: 12, silhouette: 'medium_wedge' },
    { id: 'watch',     name: 'Brass Watch',     nameEn: 'Brass Watch',     nameFr: 'Montre en laiton',    category: 'watches', value: 5,  fine: 4, weight: 1, count: 8,  silhouette: 'small_flat' },
    { id: 'wine',      name: 'Ruby Wine',       nameEn: 'Ruby Wine',       nameFr: 'Vin rubis',           category: 'wine',    value: 4,  fine: 3, weight: 3, count: 10, silhouette: 'tall_bottle' },
    { id: 'microfilm', name: 'Microfilm Spool', nameEn: 'Microfilm Spool', nameFr: 'Bobine microfilm',    category: null,      value: 7,  fine: 6, weight: 1, count: 6,  silhouette: 'small_spool' },
    { id: 'radio',     name: 'Tube Radio',      nameEn: 'Tube Radio',      nameFr: 'Radio à lampes',      category: null,      value: 8,  fine: 6, weight: 2, count: 6,  silhouette: 'medium_box' },
    { id: 'gold',      name: 'Gold Bullion',    nameEn: 'Gold Bullion',    nameFr: 'Lingot d’or',         category: null,      value: 10, fine: 8, weight: 3, count: 4,  silhouette: 'heavy_bar' },
    { id: 'antique',   name: 'Antique Amphora', nameEn: 'Antique Amphora', nameFr: 'Amphore antique',     category: null,      value: 12, fine: 9, weight: 2, count: 3,  silhouette: 'tall_vase' },
  ],
  specials: [
    { id: 'false_bottom', name: 'False Bottom', nameEn: 'False Bottom', nameFr: 'Double fond', count: 2 },
  ],
};

// Balanced deck ("After Balancing" following 10,000 Monte Carlo matches in Section 12)
export const BALANCED_DECK_DATA: DeckDataSpec = {
  version: '1.1-balanced',
  categories: INITIAL_DECK_DATA.categories,
  items: [
    { id: 'orange',    name: 'Solana Oranges',  nameEn: 'Solana Oranges',  nameFr: 'Oranges de Solana',  category: 'oranges', value: 3,  fine: 2, weight: 1, count: 16, silhouette: 'small_round' },
    { id: 'cheese',    name: 'Nordmark Cheese', nameEn: 'Nordmark Cheese', nameFr: 'Fromage du Nordmark', category: 'cheese',  value: 4,  fine: 3, weight: 2, count: 12, silhouette: 'medium_wedge' },
    { id: 'watch',     name: 'Brass Watch',     nameEn: 'Brass Watch',     nameFr: 'Montre en laiton',    category: 'watches', value: 5,  fine: 4, weight: 1, count: 8,  silhouette: 'small_flat' },
    { id: 'wine',      name: 'Ruby Wine',       nameEn: 'Ruby Wine',       nameFr: 'Vin rubis',           category: 'wine',    value: 5,  fine: 3, weight: 3, count: 10, silhouette: 'tall_bottle' },
    { id: 'microfilm', name: 'Microfilm Spool', nameEn: 'Microfilm Spool', nameFr: 'Bobine microfilm',    category: null,      value: 7,  fine: 7, weight: 1, count: 6,  silhouette: 'small_spool' },
    { id: 'radio',     name: 'Tube Radio',      nameEn: 'Tube Radio',      nameFr: 'Radio à lampes',      category: null,      value: 8,  fine: 7, weight: 2, count: 6,  silhouette: 'medium_box' },
    { id: 'gold',      name: 'Gold Bullion',    nameEn: 'Gold Bullion',    nameFr: 'Lingot d’or',         category: null,      value: 10, fine: 9, weight: 3, count: 4,  silhouette: 'heavy_bar' },
    { id: 'antique',   name: 'Antique Amphora', nameEn: 'Antique Amphora', nameFr: 'Amphore antique',     category: null,      value: 11, fine: 10, weight: 2, count: 3, silhouette: 'tall_vase' },
  ],
  specials: [
    { id: 'false_bottom', name: 'False Bottom', nameEn: 'False Bottom', nameFr: 'Double fond', count: 2 },
  ],
};
