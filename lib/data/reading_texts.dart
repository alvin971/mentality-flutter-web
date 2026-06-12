// lib/data/reading_texts.dart
// Corpus de 5 textes pour la collecte audio STT, disponible par langue.
// Chaque texte : ~130 mots, niveau B1-B2, registre narratif/informatif.
//
// Les textes sont des STIMULI psychométriques (données), pas de l'UI : ils ne
// passent donc pas par l10n/.arb mais par une sélection FR/EN basée sur la
// langue courante de [localeNotifier].

import '../core/l10n/locale_notifier.dart';

class ReadingText {
  final String id;
  final String title;
  final String body;
  final int approximateWordCount;

  const ReadingText({
    required this.id,
    required this.title,
    required this.body,
    required this.approximateWordCount,
  });
}

// ─── Corpus français ────────────────────────────────────────────────────────

const List<ReadingText> _kReadingTextsFr = [
  ReadingText(
    id: 'text_01',
    title: 'La forêt au crépuscule',
    // Phonèmes ciblés : r roulé, nasales (an/en/on), ou/eau/au
    body:
        'Au crépuscule, la forêt se transforme doucement. Les branches des grands '
        'chênes projettent leurs ombres allongées sur le sol couvert de mousse. On '
        'entend au loin le ruisseau qui coule entre les rochers, produisant un '
        'murmure constant et apaisant. Les oiseaux commencent à rentrer dans leurs '
        'nids, tandis que les premiers insectes nocturnes s\'éveillent. L\'air frais '
        'porte l\'odeur douce des fougères mouillées et de la terre humide. En '
        'avançant sur le sentier, on remarque que la lumière dorée du soleil '
        'couchant traverse les feuillages et crée des taches brillantes sur le '
        'chemin. Ce moment particulier, entre le jour et la nuit, est l\'un des '
        'plus beaux spectacles que la nature puisse offrir à ceux qui savent '
        'prendre le temps de s\'arrêter et d\'observer.',
    approximateWordCount: 130,
  ),
  ReadingText(
    id: 'text_02',
    title: 'Une matinée en ville',
    // Phonèmes ciblés : liaisons, u vs ou, ch/j, é/è
    body: 'Chaque matin, les rues de la ville s\'animent progressivement. Les '
        'boulangeries ouvrent leurs portes bien avant l\'aube, et une odeur '
        'chaude de pain frais se répand dans les ruelles. Les premiers passants '
        'pressés traversent les avenues en jetant un coup d\'œil distrait aux '
        'vitrines encore éteintes. Un peu plus loin, le marché s\'installe : les '
        'marchands déchargent leurs camionnettes et arrangent leurs fruits et '
        'légumes avec soin. Les enfants en chemin vers l\'école bavardent joyeusement '
        'sur les trottoirs. Des cyclistes faufilent leur vélo entre les voitures à '
        'l\'arrêt. Les cafés commencent à accueillir leurs habitués, qui s\'attardent '
        'quelques minutes autour d\'un café chaud. Cette routine quotidienne, '
        'bien que banale, révèle une énergie collective que l\'on ne trouve '
        'nulle part ailleurs qu\'en ville.',
    approximateWordCount: 131,
  ),
  ReadingText(
    id: 'text_03',
    title: 'Le cycle de l\'eau',
    // Phonèmes ciblés : eu/œu, clusters consonantiques, accents circonflexes
    body:
        'L\'eau suit un cycle extraordinaire qui permet la vie sur notre planète. '
        'Sous l\'effet de la chaleur du soleil, l\'eau des océans s\'évapore et '
        'monte dans l\'atmosphère sous forme de vapeur. En s\'élevant, cette '
        'vapeur se refroidit et se transforme en minuscules gouttelettes qui '
        'forment les nuages. Lorsque ces gouttelettes s\'accumulent en quantité '
        'suffisante, elles retombent sur la terre sous forme de pluie ou de neige. '
        'Une partie de cette eau s\'infiltre dans le sol et alimente les nappes '
        'souterraines, tandis que le reste rejoint les fleuves et les rivières. '
        'Ces cours d\'eau transportent l\'eau vers les mers et les océans, '
        'bouclant ainsi le cycle. Ce phénomène naturel, millénaire et perpétuel, '
        'régule le climat de la Terre et rend possible l\'existence de tous '
        'les êtres vivants.',
    approximateWordCount: 130,
  ),
  ReadingText(
    id: 'text_04',
    title: 'L\'art de la cuisine',
    // Phonèmes ciblés : consonnes finales prononcées, é/è/ê, gn, oi
    body:
        'Cuisiner est bien plus qu\'une simple nécessité quotidienne. C\'est un '
        'art qui exige de la patience, de la précision et une certaine sensibilité. '
        'Lorsqu\'on prépare un repas, chaque ingrédient joue un rôle précis : '
        'le sel rehausse les saveurs, les herbes aromatiques apportent de la '
        'fraîcheur, et la cuisson transforme les textures. Un bon cuisinier sait '
        'reconnaître l\'odeur d\'une viande parfaitement saisie ou le moment exact '
        'où une sauce a réduit comme il faut. La cuisine régionale française '
        'témoigne d\'un savoir-faire ancestral transmis de génération en génération. '
        'Que ce soit une soupe rustique mijotée longuement, un gratin doré et '
        'croustillant, ou une tarte aux pommes dont le parfum envahit toute la '
        'maison, chaque plat raconte une histoire et rassemble les gens autour '
        'd\'une table partagée.',
    approximateWordCount: 130,
  ),
  ReadingText(
    id: 'text_05',
    title: 'Les souvenirs d\'enfance',
    // Phonèmes ciblés : si/ce/ci, oi, tion/sion, nasales complexes
    body: 'Certains souvenirs d\'enfance s\'impriment dans la mémoire avec une '
        'précision étonnante. On se rappelle l\'odeur particulière de la maison '
        'de ses grands-parents, la sensation du sable chaud sous les pieds lors '
        'des vacances d\'été, ou le goût d\'une glace à la fraise dégustée par '
        'une journée ensoleillée. Ces impressions sensorielles traversent les '
        'années sans perdre de leur intensité. Certaines images resurgissent '
        'spontanément : une balançoire dans un jardin, une vieille boîte à '
        'biscuits décorée de motifs floraux, ou la voix douce d\'un parent qui '
        'raconte une histoire le soir. La psychologie explique cette persistance '
        'par l\'association entre émotions et mémoire. Les moments vécus avec '
        'une forte émotion positive laissent des traces durables. C\'est pourquoi '
        'l\'enfance, malgré sa brièveté, continue d\'influencer nos perceptions '
        'et nos décisions bien longtemps après.',
    approximateWordCount: 131,
  ),
];

// ─── English corpus ─────────────────────────────────────────────────────────

const List<ReadingText> _kReadingTextsEn = [
  ReadingText(
    id: 'text_01',
    title: 'The forest at dusk',
    body:
        'At dusk, the forest slowly transforms. The branches of the tall oaks '
        'cast their long shadows across the moss-covered ground. Far away, you '
        'can hear the stream flowing between the rocks, producing a constant and '
        'soothing murmur. The birds begin to return to their nests, while the '
        'first nocturnal insects awaken. The cool air carries the gentle scent of '
        'damp ferns and moist earth. As you walk along the path, you notice that '
        'the golden light of the setting sun filters through the leaves and '
        'creates bright patches on the trail. This particular moment, between day '
        'and night, is one of the most beautiful sights that nature can offer to '
        'those who know how to take the time to stop and observe.',
    approximateWordCount: 130,
  ),
  ReadingText(
    id: 'text_02',
    title: 'A morning in the city',
    body: 'Every morning, the streets of the city gradually come to life. The '
        'bakeries open their doors well before dawn, and a warm smell of fresh '
        'bread spreads through the alleys. The first hurried passers-by cross the '
        'avenues, casting a distracted glance at the still-dark shop windows. A '
        'little further on, the market sets up: the vendors unload their vans and '
        'arrange their fruit and vegetables with care. Children on their way to '
        'school chatter cheerfully on the sidewalks. Cyclists weave their bikes '
        'between the stopped cars. The cafés begin to welcome their regulars, who '
        'linger for a few minutes over a hot coffee. This daily routine, however '
        'ordinary, reveals a collective energy that can be found nowhere else but '
        'in the city.',
    approximateWordCount: 131,
  ),
  ReadingText(
    id: 'text_03',
    title: 'The water cycle',
    body:
        'Water follows an extraordinary cycle that makes life possible on our '
        'planet. Under the effect of the sun\'s heat, the water of the oceans '
        'evaporates and rises into the atmosphere as vapor. As it rises, this '
        'vapor cools and turns into tiny droplets that form the clouds. When these '
        'droplets gather in sufficient quantity, they fall back to the earth as '
        'rain or snow. Part of this water seeps into the ground and feeds the '
        'underground water tables, while the rest joins the rivers and streams. '
        'These waterways carry the water toward the seas and the oceans, thus '
        'closing the cycle. This natural phenomenon, ancient and perpetual, '
        'regulates the climate of the Earth and makes possible the existence of '
        'all living beings.',
    approximateWordCount: 130,
  ),
  ReadingText(
    id: 'text_04',
    title: 'The art of cooking',
    body:
        'Cooking is far more than a simple daily necessity. It is an art that '
        'demands patience, precision and a certain sensitivity. When you prepare '
        'a meal, each ingredient plays a precise role: salt enhances the flavors, '
        'aromatic herbs bring freshness, and cooking transforms the textures. A '
        'good cook knows how to recognize the smell of a perfectly seared piece of '
        'meat or the exact moment when a sauce has reduced just right. Regional '
        'cooking bears witness to ancestral know-how passed down from generation '
        'to generation. Whether it is a rustic soup simmered slowly, a golden and '
        'crisp gratin, or an apple tart whose aroma fills the whole house, each '
        'dish tells a story and gathers people around a shared table.',
    approximateWordCount: 130,
  ),
  ReadingText(
    id: 'text_05',
    title: 'Childhood memories',
    body:
        'Some childhood memories imprint themselves on the mind with astonishing '
        'precision. You remember the particular smell of your grandparents\' '
        'house, the feeling of hot sand under your feet during the summer '
        'holidays, or the taste of a strawberry ice cream enjoyed on a sunny day. '
        'These sensory impressions travel through the years without losing their '
        'intensity. Certain images resurface spontaneously: a swing in a garden, '
        'an old biscuit tin decorated with floral patterns, or the soft voice of a '
        'parent telling a story in the evening. Psychology explains this '
        'persistence by the association between emotions and memory. The moments '
        'lived with strong positive emotion leave lasting traces. That is why '
        'childhood, despite its brevity, continues to influence our perceptions '
        'and our decisions long afterward.',
    approximateWordCount: 131,
  ),
];

// ─── Sélection par langue ────────────────────────────────────────────────────

/// Corpus de textes pour la langue courante de l'application
/// ('fr' ou 'en', d'après [localeNotifier]).
List<ReadingText> get kReadingTexts =>
    localeNotifier.languageCode == 'en' ? _kReadingTextsEn : _kReadingTextsFr;

/// Retourne un texte par son identifiant (dans la langue courante),
/// ou null si introuvable.
ReadingText? findTextById(String id) {
  try {
    return kReadingTexts.firstWhere((t) => t.id == id);
  } catch (_) {
    return null;
  }
}
