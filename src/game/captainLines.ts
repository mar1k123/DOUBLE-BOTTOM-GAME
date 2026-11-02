// Captain Vera Lisitsyna's 61 Checkpoint Lines in English (EN) & French (FR)
// Synthesized with enhanced neural/natural voice selection + 1960s intercom filter (tagged REPLACE_WITH_VOICEOVER)

import { GameLanguage } from './i18n';

export type CaptainCueCategory =
  | 'deal'
  | 'packing'
  | 'sealed'
  | 'negotiation'
  | 'slit_peek'
  | 'xray_scan'
  | 'pass_clean'
  | 'bribe_accepted'
  | 'inspected_honest'
  | 'caught_contraband'
  | 'false_bottom_found'
  | 'false_bottom_missed'
  | 'round_end';

export interface CaptainLine {
  id: string;
  category: CaptainCueCategory;
  en: string;
  fr: string;
  voiceNote: 'REPLACE_WITH_VOICEOVER';
}

export const CAPTAIN_VERA_LINES: CaptainLine[] = [
  // DEAL (6)
  {
    id: 'deal_01',
    category: 'deal',
    en: 'Another night train from Altavia. Let us see whose hands tremble under the lamp tonight.',
    fr: 'Un autre train de nuit en provenance d’Altavie. Voyons quelles mains trembleront sous la lampe ce soir.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'deal_02',
    category: 'deal',
    en: 'Swallow Checkpoint, night shift. Rain washes away footprints, never customs seals.',
    fr: 'Poste-frontière de l’Hirondelle, service de nuit. La pluie efface les pas, jamais les scellés douaniers.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'deal_03',
    category: 'deal',
    en: 'Courier, unfold your valise. Inspector, keep your eyes strictly on the ledger.',
    fr: 'Courrier, dépliez votre valise. Inspecteur, gardez les yeux fixés sur le registre.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'deal_04',
    category: 'deal',
    en: 'Seventy-five seconds to pack your compartment. Customs has no patience for latecomers.',
    fr: 'Soixante-quinze secondes pour préparer votre bagage. La douane n’attend pas les retardataires.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'deal_05',
    category: 'deal',
    en: 'Fresh declaration forms are on the counter. Print your cargo category clearly.',
    fr: 'Les nouveaux formulaires de déclaration sont sur le comptoir. Inscrivez votre catégorie lisiblement.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'deal_06',
    category: 'deal',
    en: 'The brass lamp hums before a storm. Prepare your luggage for border clearance.',
    fr: 'La lampe en laiton bourdonne avant l’orage. Préparez vos bagages pour le contrôle.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },

  // PACKING (6)
  {
    id: 'pack_01',
    category: 'packing',
    en: 'Pack it tight: a single stray rattle betrays even a seasoned diplomat.',
    fr: 'Serrez bien le contenu : le moindre cliquetis trahit même un diplomate chevronné.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'pack_02',
    category: 'packing',
    en: 'Oranges or microfilm—official paper tolerates any ink until the lid is raised.',
    fr: 'Oranges ou microfilm : le papier officiel tolère toutes les encres jusqu’à l’ouverture du coffre.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'pack_03',
    category: 'packing',
    en: 'Five slots in plain sight. What lies beneath the velvet lining is between you and your conscience.',
    fr: 'Cinq emplacements bien en vue. Ce qui dort sous le velours ne regarde que votre conscience.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'pack_04',
    category: 'packing',
    en: 'Do not forget the customs declaration. Without a category, the brass latch will not catch.',
    fr: 'N’oubliez pas la déclaration douanière. Sans catégorie, le fermoir en laiton ne s’enclenchera pas.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'pack_05',
    category: 'packing',
    en: 'A few crisp marks tucked inside a passport sometimes weigh less than honest cheese.',
    fr: 'Quelques billets glissés dans un passeport pèsent parfois moins lourd qu’un honnête fromage.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'pack_06',
    category: 'packing',
    en: 'Snap the suitcase shut when you are ready to look the Inspector straight in the eye.',
    fr: 'Rabattez le couvercle dès que vous serez prêt à soutenir le regard de l’Inspecteur.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },

  // SEALED (5)
  {
    id: 'seal_01',
    category: 'sealed',
    en: 'Brass latches locked. Nothing inside that valise can be altered now.',
    fr: 'Fermoirs en laiton verrouillés. Plus rien ne peut être modifié dans cette valise.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'seal_02',
    category: 'sealed',
    en: 'Lead seal affixed. Slide the closed passport and suitcase across the desk.',
    fr: 'Scellé de plomb posé. Faites glisser le passeport et la valise fermée de l’autre côté du bureau.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'seal_03',
    category: 'sealed',
    en: 'Cargo sealed. From this second onward, every flinch is circumstantial evidence.',
    fr: 'Bagage scellé. À partir de cet instant, le moindre cillement devient un indice.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'seal_04',
    category: 'sealed',
    en: 'The latch clicked clean. Let us see whether the declaration is half as spotless.',
    fr: 'Le verrou a claqué net. Voyons si la déclaration est aussi irréprochable.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'seal_05',
    category: 'sealed',
    en: 'Documents presented for inspection. Courier, keep a stone face.',
    fr: 'Documents présentés au contrôle. Courrier, gardez un visage de marbre.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },

  // NEGOTIATION (6)
  {
    id: 'neg_01',
    category: 'negotiation',
    en: 'Forty-five seconds for questioning. Watch the Courier’s eyes, not the numbers.',
    fr: 'Quarante-cinq secondes d’interrogatoire. Observez les yeux du Courrier, pas les chiffres.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'neg_02',
    category: 'negotiation',
    en: 'A traveler’s polite smile is always suspicious. Especially when the cargo is legal.',
    fr: 'Le sourire poli d’un voyageur est toujours suspect. Surtout quand la cargaison est légale.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'neg_03',
    category: 'negotiation',
    en: 'Ask them where southern oranges grow in Nordmark in the middle of November.',
    fr: 'Demandez-lui donc où poussent les oranges du sud au Nordmark en plein mois de novembre.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'neg_04',
    category: 'negotiation',
    en: 'Silence in the interrogation booth speaks louder than any signed confession.',
    fr: 'Le silence dans la guérite en dit plus long que n’importe quel aveu signé.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'neg_05',
    category: 'negotiation',
    en: 'A gratuity in the passport is an invitation to friendship—or a formal search warrant.',
    fr: 'Un pourboire dans le passeport est une invitation à l’amitié… ou à une fouille en règle.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'neg_06',
    category: 'negotiation',
    en: 'Time is dripping away, Inspector. Wave them through or break the seal?',
    fr: 'Le temps s’égrène, Inspecteur. Laissez-vous passer ou brisez-vous le scellé ?',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },

  // SLIT PEEK (6)
  {
    id: 'slit_01',
    category: 'slit_peek',
    en: 'Just a narrow slit, Inspector. One degree too far and it becomes an irreversible search.',
    fr: 'Juste un entrebâillement, Inspecteur. Un degré de trop et la fouille devient irréversible.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'slit_02',
    category: 'slit_peek',
    en: 'Rather heavy for brass wristwatches, do you not think? Or is that lead-lined wrapping?',
    fr: 'Un peu lourd pour des montres en laiton, vous ne trouvez pas ? À moins que l’emballage ne soit doublé de plomb.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'slit_03',
    category: 'slit_peek',
    en: 'The flashlight beam grazes the green felt. Careful: shadows sometimes lie.',
    fr: 'Le faisceau de la torche effleure le feutre vert. Méfiez-vous, les ombres mentent parfois.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'slit_04',
    category: 'slit_peek',
    en: 'One Clue Token spent. Study the silhouettes before the hinge crosses twenty-five degrees.',
    fr: 'Un jeton d’indice dépensé. Étudiez les silhouettes avant que la charnière ne dépasse vingt-cinq degrés.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'slit_05',
    category: 'slit_peek',
    en: 'The Courier sees the red eye on the outer cover. Do not be the first to blink.',
    fr: 'Le Courrier voit l’œil rouge clignoter sur la couverture. Ne soyez pas le premier à ciller.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'slit_06',
    category: 'slit_peek',
    en: 'Easy with the hinge: twenty-five degrees snaps the seal and there is no turning back.',
    fr: 'Doucement avec la charnière : à vingt-cinq degrés, le scellé cède et tout retour est impossible.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },

  // XRAY / NERVOMETER (5)
  {
    id: 'xray_01',
    category: 'xray_scan',
    en: 'The Nervometer tubes are warmed up. Let us see what their pulse says under the spotlight.',
    fr: 'Les lampes du Nervomètre sont chaudes. Voyons ce que raconte son pouls sous le projecteur.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'xray_02',
    category: 'xray_scan',
    en: 'The gauge catches every micro-tremor. Though perhaps they only caught a chill on the platform?',
    fr: 'L’appareil capte le moindre tremblement. Mais peut-être a-t-il simplement pris froid sur le quai ?',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'xray_03',
    category: 'xray_scan',
    en: 'The needle jumped! Then again, even innocent diplomats sweat at my checkpoint.',
    fr: 'L’aiguille a bondi ! Cela dit, même les diplomates innocents transpirent à mon poste.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'xray_04',
    category: 'xray_scan',
    en: 'Five seconds under the X-Ray beam. Keep your gaze steady on the brass lens.',
    fr: 'Cinq secondes sous le rayon X. Gardez les yeux rivés sur l’objectif en laiton.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'xray_05',
    category: 'xray_scan',
    en: 'Reading complete. Remember, Inspector: the instrument measures nerves, never guilt.',
    fr: 'Mesure terminée. Souvenez-vous, Inspecteur : l’instrument mesure la nervosité, jamais la culpabilité.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },

  // PASS CLEAN (5)
  {
    id: 'pass_01',
    category: 'pass_clean',
    en: 'Stamped "Cleared". Safe travels to Nordmark, and do not return on the same train.',
    fr: 'Tamponné « Conforme ». Bon voyage vers le Nordmark, et ne revenez pas par le même train.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'pass_02',
    category: 'pass_clean',
    en: 'The border gate is open. The Inspector chose to spare the confiscation forms tonight.',
    fr: 'La barrière est levée. L’Inspecteur a préféré économiser les formulaires de saisie ce soir.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'pass_03',
    category: 'pass_clean',
    en: 'Move along. Whatever you packed under that lining, fortune rode with you tonight.',
    fr: 'Circulez. Quoi que vous ayez caché sous cette doublure, la chance voyageait avec vous.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'pass_04',
    category: 'pass_clean',
    en: 'Cleared without physical search. Fast, quiet, and zero extra paperwork.',
    fr: 'Admis sans fouille physique. Rapide, discret et sans paperasse inutile.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'pass_05',
    category: 'pass_clean',
    en: 'Barrier raised. Next passenger in line, step up to the desk!',
    fr: 'Barrière levée. Passager suivant, avancez jusqu’au comptoir !',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },

  // BRIBE ACCEPTED (5)
  {
    id: 'bribe_01',
    category: 'bribe_accepted',
    en: 'A modest gratuity for expedited customs clearance. Such touching Old World courtesy.',
    fr: 'Une modeste gratification pour traitement accéléré. Quelle touchante courtoisie d’antan.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'bribe_02',
    category: 'bribe_accepted',
    en: 'Marks slipped into an overcoat pocket, and the valise glided across the border. Everyone smiles.',
    fr: 'Les marks ont glissé dans une poche de manteau, et la valise a franchi la frontière. Tout le monde sourit.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'bribe_03',
    category: 'bribe_accepted',
    en: 'I saw nothing, and the desk lamp happened to flicker. Move along before I change my mind.',
    fr: 'Je n’ai rien vu, et la lampe de bureau a justement vacillé. Filez avant que je ne change d’avis.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'bribe_04',
    category: 'bribe_accepted',
    en: 'An amicable arrangement in the neutral zone. Even the lead seal stayed intact.',
    fr: 'Un arrangement à l’amiable en zone neutre. Même le scellé de plomb est resté intact.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'bribe_05',
    category: 'bribe_accepted',
    en: 'The Inspector values a busy traveler’s schedule. Especially a generous one.',
    fr: 'L’Inspecteur respecte l’emploi du temps d’un voyageur pressé. Surtout lorsqu’il est généreux.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },

  // INSPECTED HONEST (6)
  {
    id: 'hon_01',
    category: 'inspected_honest',
    en: 'Clean! Not a single undeclared spool. Inspector, pay compensation for the wrongful delay.',
    fr: 'Conforme ! Pas la moindre bobine suspecte. Inspecteur, versez l’indemnité pour fouille abusive.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'hon_02',
    category: 'inspected_honest',
    en: 'False alarm. Honest merchandise, honest declaration—and a tarnished inspector’s badge.',
    fr: 'Fausse alerte. Marchandise honnête, déclaration exacte… et un insigne d’inspecteur terni.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'hon_03',
    category: 'inspected_honest',
    en: 'You trembled like that over ordinary Nordmark cheese? Magnificent theater, Courier!',
    fr: 'Vous trembliez ainsi pour un simple fromage du Nordmark ? Quel talent d’acteur, Courrier !',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'hon_04',
    category: 'inspected_honest',
    en: 'The manifest matches to the last gram. Customs offers its apologies in hard currency.',
    fr: 'Le manifeste correspond au gramme près. La douane présente ses excuses en espèces sonnantes.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'hon_05',
    category: 'inspected_honest',
    en: 'The Inspector swallowed the bait hook, line, and sinker. Damages come out of your pay!',
    fr: 'L’Inspecteur a mordu à l’hameçon. Les dédommagements seront prélevés sur votre solde !',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'hon_06',
    category: 'inspected_honest',
    en: 'Spotless cargo! A masterclass in reverse psychology at the border desk.',
    fr: 'Cargaison irréprochable ! Une leçon magistrale de bluff inversé au guichet.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },

  // CAUGHT CONTRABAND (6)
  {
    id: 'caught_01',
    category: 'caught_contraband',
    en: 'End of the line! Contraband on the green felt—draw up the confiscation protocol!',
    fr: 'Terminus ! Contrebande sur le tapis vert : rédigez immédiatement le procès-verbal de saisie !',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'caught_02',
    category: 'caught_contraband',
    en: 'What fascinating "Solana oranges" ticking with vacuum tubes inside. Fine to the treasury!',
    fr: 'Quelles fascinantes « oranges de Solana » garnies de lampes radio. Amende au Trésor !',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'caught_03',
    category: 'caught_contraband',
    en: 'Busted! Hold still for the dual-camera Inspection Protocol, citizen smuggler.',
    fr: 'Pris la main dans le sac ! Ne bougez plus pour le cliché du Protocole d’inspection.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'caught_04',
    category: 'caught_contraband',
    en: 'The Inspector read your bluff to perfection. Undeclared contraband seized!',
    fr: 'L’Inspecteur a percé votre jeu à jour. Marchandise non déclarée confisquée !',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'caught_05',
    category: 'caught_contraband',
    en: 'A crimson confiscation stamp in the passport and a hefty bounty for the Inspector.',
    fr: 'Un tampon rouge de saisie dans le passeport et une belle prime de vigilance pour l’Inspecteur.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'caught_06',
    category: 'caught_contraband',
    en: 'At Swallow Checkpoint, sleight of hand costs dearly. Empty your pockets onto the tray.',
    fr: 'Au poste de l’Hirondelle, les tours de passe-passe coûtent cher. Videz vos poches sur le plateau.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },

  // FALSE BOTTOM FOUND / MISSED (5)
  {
    id: 'fb_01',
    category: 'false_bottom_found',
    en: 'Hold on… The inner partition shifted when tilted! The false bottom under the felt is exposed!',
    fr: 'Un instant… La cloison intérieure a bougé à l’inclinaison ! Le double fond sous le feutre est découvert !',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'fb_02',
    category: 'false_bottom_found',
    en: 'A false bottom! And the top tray looked so remarkably respectable.',
    fr: 'Un double fond ! Et dire que le compartiment supérieur avait l’air si respectable.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'fb_03',
    category: 'false_bottom_missed',
    en: 'The Inspector checked the top tray without tilting the frame. The secret compartment slipped across!',
    fr: 'L’Inspecteur a fouillé le dessus sans incliner le châssis. La cache secrète a franchi la frontière !',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'fb_04',
    category: 'false_bottom_missed',
    en: 'The hidden cavity stayed silent. What lies beneath the felt remains the Courier’s secret.',
    fr: 'La cavité secrète est restée muette. Ce qui dort sous le feutre demeure le secret du Courrier.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'fb_05',
    category: 'false_bottom_found',
    en: 'A dull metallic shift inside the lining gave away the secret stash. Brilliant work, Inspector!',
    fr: 'Un glissement sourd dans la doublure a trahi la cachette. Excellent travail, Inspecteur !',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },

  // ROUND END (5)
  {
    id: 'end_01',
    category: 'round_end',
    en: 'Entry logged in the night ledger. Pass the iPhone Duo to the next traveler.',
    fr: 'Mention inscrite au registre de nuit. Passez l’iPhone Duo au voyageur suivant.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'end_02',
    category: 'round_end',
    en: 'The border night is long and the treasury grows thin. Rotate roles at the desk.',
    fr: 'La nuit est longue à la frontière et la caisse s’épuise. Échangez vos rôles au guichet.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'end_03',
    category: 'round_end',
    en: 'The stamp ink is dry. Who is next to test their nerves at Swallow Checkpoint?',
    fr: 'L’encre du tampon est sèche. Qui sera le prochain à tester ses nerfs au poste de l’Hirondelle ?',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'end_04',
    category: 'round_end',
    en: 'Change of guard at the booth. Yesterday’s smuggler puts on the customs cap.',
    fr: 'Relève de la garde à la guérite. Le contrebandier d’hier coiffe la casquette des douanes.',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
  {
    id: 'end_05',
    category: 'round_end',
    en: 'Accounts settled. Next passenger, step forward to the yellow line!',
    fr: 'Les comptes sont réglés. Passager suivant, avancez jusqu’à la ligne jaune !',
    voiceNote: 'REPLACE_WITH_VOICEOVER',
  },
];

export function pickCaptainLine(category: CaptainCueCategory, seed: number): CaptainLine {
  const matching = CAPTAIN_VERA_LINES.filter((l) => l.category === category);
  const pool = matching.length > 0 ? matching : CAPTAIN_VERA_LINES;
  const idx = Math.abs(Math.floor(seed)) % pool.length;
  return pool[idx];
}

export function getCaptainLineText(category: CaptainCueCategory, seed: number, lang: GameLanguage): string {
  const line = pickCaptainLine(category, seed);
  return lang === 'fr' ? line.fr : line.en;
}
