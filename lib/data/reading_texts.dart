// lib/data/reading_texts.dart
// Corpus de 5 textes en français pour la collecte audio STT.
// Chaque texte : ~130 mots, niveau B1-B2, phonèmes difficiles ciblés.

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

const List<ReadingText> kReadingTexts = [
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
    body:
        'Chaque matin, les rues de la ville s\'animent progressivement. Les '
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
    body:
        'Certains souvenirs d\'enfance s\'impriment dans la mémoire avec une '
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

/// Retourne un texte par son identifiant, ou null si introuvable.
ReadingText? findTextById(String id) {
  try {
    return kReadingTexts.firstWhere((t) => t.id == id);
  } catch (_) {
    return null;
  }
}
