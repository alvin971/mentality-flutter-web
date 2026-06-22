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

// ─── BEGIN generated multilingual corpora ───

const List<ReadingText> _kReadingTextsEs = [
  ReadingText(
    id: 'text_01',
    title: 'El bosque en otoño',
    body: 'Cada año, cuando el frío comienza a asentarse sobre la sierra, los bosques de robles y castaños se transforman en un espectáculo difícil de olvidar. Las hojas pasan del verde intenso del verano a una paleta de ocres, dorados y rojizos que cubre el suelo como una alfombra mullida. El olor a tierra húmeda y a madera vieja impregna el aire, y el silencio solo se rompe por el crujido de las ramas bajo el peso del viento. Los animales del bosque se preparan para los meses más duros: las ardillas entierran bellotas cerca de los troncos, y los jabalíes hocican entre la hojarasca en busca de las últimas setas. Es una estación que invita a caminar despacio, a mirar con atención y a agradecer la generosidad silenciosa de la naturaleza.',
    approximateWordCount: 131,
  ),
  ReadingText(
    id: 'text_02',
    title: 'Un barrio de Madrid',
    body: 'El barrio de Lavapiés ha cambiado mucho en las últimas décadas, aunque conserva ese carácter particular que lo distingue del resto de la ciudad. Sus calles empinadas y sus fachadas desgastadas conviven hoy con tiendas de especias, pequeños teatros y bares donde se mezclan vecinos de toda la vida con recién llegados de distintos países. Por las mañanas, los mercados ambulantes llenan las aceras de color y de voces en varios idiomas, mientras el aroma del café recién hecho se escapa por las ventanas abiertas. Por las tardes, las terrazas se llenan de gente que lee, conversa o simplemente observa el ritmo incesante de la calle. Vivir en Lavapiés es aceptar el ruido, la diversidad y la imprevisibilidad como parte del día a día.',
    approximateWordCount: 124,
  ),
  ReadingText(
    id: 'text_03',
    title: 'Por qué el cielo es azul',
    body: 'La luz del sol parece blanca a simple vista, pero en realidad está formada por todos los colores del arco iris. Cuando esa luz atraviesa la atmósfera terrestre, choca con las pequeñísimas moléculas de aire que la componen. No todos los colores reaccionan de la misma manera: el azul, al tener una longitud de onda más corta, se dispersa con mucha mayor facilidad en todas direcciones. Así, cuando miramos al cielo en un día despejado, estamos viendo ese azul disperso que llega a nuestros ojos desde múltiples ángulos al mismo tiempo. Al amanecer y al atardecer, la luz solar recorre una distancia mucho mayor dentro de la atmósfera, y los tonos cálidos, como el naranja y el rojo, son los que logran llegar hasta nosotros. La física cotidiana nos regala así uno de los espectáculos más hermosos del día.',
    approximateWordCount: 139,
  ),
  ReadingText(
    id: 'text_04',
    title: 'La cocina de la abuela',
    body: 'En muchas casas españolas, la cocina de la abuela era el verdadero centro del hogar. Era el lugar donde se guardaban los secretos de recetas transmitidas de generación en generación, escritas a mano en cuadernos de hojas amarillentas o simplemente aprendidas de memoria con los años. El olor a sofrito de ajo y cebolla, a caldo de cocido burbujeando en la olla, o a bizcocho recién horneado era capaz de despertar a toda la casa sin necesidad de ningún otro aviso. La abuela cocinaba con paciencia y con medidas imprecisas: un puñado de esto, un chorro de aquello, hasta que el guiso quedaba a su gusto. Aquellas comidas lentas del domingo, en torno a una mesa grande y ruidosa, siguen siendo para muchos el recuerdo más vívido de la infancia.',
    approximateWordCount: 130,
  ),
  ReadingText(
    id: 'text_05',
    title: 'El tren de cercanías',
    body: 'Miles de personas cruzan cada día las ciudades españolas a bordo de los trenes de cercanías, esa red de líneas que conecta los municipios del extrarradio con el corazón urbano. Son trayectos cortos, de veinte o treinta minutos, que los viajeros habituales aprovechan para leer, escuchar música o simplemente mirar por la ventanilla el paisaje que cambia de lo rural a lo urbano en pocos kilómetros. En las horas punta, los vagones se llenan de estudiantes con mochilas, trabajadores con el maletín sobre las rodillas y personas mayores que van a visitar a sus familias. Hay algo particular en ese silencio compartido entre desconocidos que se ven cada mañana sin llegar a conocerse nunca del todo. El tren de cercanías es, a su manera discreta, uno de los grandes nudos del tejido social de nuestras ciudades.',
    approximateWordCount: 136,
  ),
];

const List<ReadingText> _kReadingTextsPt = [
  ReadingText(
    id: 'text_01',
    title: 'A Maré Baixa',
    body: 'Quando a maré baixa, a praia transforma-se num mundo diferente. As rochas, cobertas de algas escuras e húmidas, ficam expostas ao sol da manhã. Entre elas formam-se pequenas poças de água salgada onde vivem caranguejos, lapas e minúsculos peixes que ficaram retidos pela vaga. As crianças aproximam-se devagar, curvadas sobre essas poças como se espiassem um aquário ao contrário. O cheiro a maresia envolve tudo. À distância, os pescadores aproveitam o recuo das águas para apanhar berbigão e amêijoa, que mais tarde venderão no mercado local. No fim da tarde, o mar volta a subir, devagarinho, cobrindo outra vez as rochas e os seus habitantes secretos, como se tivesse decidido guardar de novo aquilo que por breves horas quis mostrar.',
    approximateWordCount: 122,
  ),
  ReadingText(
    id: 'text_02',
    title: 'O Eléctrico da Baixa',
    body: 'Em Lisboa, o eléctrico amarelo ainda percorre as ruas mais antigas da cidade com uma lentidão que parece propositada. Sobe as calçadas íngremes de pedra miúda, inclina-se nas curvas e anuncia a sua passagem com um tilintар suave. Dentro, os lugares são escassos e os passageiros mais velhos raramente se levantam antes da paragem certa. Há quem leia o jornal dobrado ao meio, quem olhe pela janela embaciada para as fachadas de azulejo que passam. A cidade lá fora tem pressa, mas o eléctrico não. Ele segue o seu caminho entre o trânsito moderno como quem sabe que o tempo não é bem o que parece. Para muitos lisboetas, apanhar o eléctrico continua a ser um acto quase ritual, ligado à memória e ao cheiro particular do metal aquecido.',
    approximateWordCount: 130,
  ),
  ReadingText(
    id: 'text_03',
    title: 'Por que o Pão Cresce',
    body: 'O pão que sai do forno com uma côdea dourada e crocante deve a sua leveza a um processo silencioso que acontece muito antes de qualquer calor. Quando a farinha e a água se misturam com fermento, os microrganismos presentes nesse fermento começam a consumir os açúcares da mistura e a libertar dióxido de carbono. São essas bolhas de gás que ficam presas na massa e a fazem crescer de forma visível. Quanto mais tempo a massa repousa, mais complexos se tornam os aromas, porque as bactérias acrescentam ácidos que dão ao pão o seu sabor característico. O calor do forno coze a estrutura em torno dessas bolhas e fixa a forma final. É um fenómeno ao mesmo tempo biológico e químico que as padarias artesanais conhecem bem e que resulta, no fundo, numa das mais antigas tecnologias da humanidade.',
    approximateWordCount: 138,
  ),
  ReadingText(
    id: 'text_04',
    title: 'A Tasca do Domingo',
    body: 'Ao domingo a meio-dia, a tasca da esquina enche-se de um barulho familiar: o tinido dos copos, as conversas sobrepostas, o cheiro a caldo verde que vem da cozinha. As mesas não têm toalha de papel como nos restaurantes da moda, mas têm garrafas de vinho tinto que passam de mão em mão sem cerimónia. O dono conhece a maioria dos clientes pelo nome e sabe de cor quem prefere a sopa e quem vai directo ao bacalhau assado. As famílias juntam-se ali depois da missa ou do futebol, e a refeição estende-se durante horas sem que ninguém pareça ter pressa. Fora, o sol de inverno aquece a calçada. Dentro, o tempo parece suspenso entre uma travessa e outra, como se o almoço do domingo fosse também uma forma discreta de resistência ao mundo que nunca para.',
    approximateWordCount: 133,
  ),
  ReadingText(
    id: 'text_05',
    title: 'O Quintal da Avó',
    body: 'Lembro-me do quintal da minha avó como de um lugar onde tudo tinha cheiro. As tomateiros encostados à parede sul aqueciam ao longo do dia e ao entardecer libertavam um perfume verde e ligeiramente ácido. Havia um tanque de pedra com musgo nas bordas onde ela lavava a roupa a torcer com as mãos, e uma figueira velha cuja sombra cobria quase metade do espaço. No verão, a fruta caía sozinha e fermentava no chão quente antes que alguém a apanhasse. A minha avó andava descalça entre as plantas, aparando aqui e ali com uma tesoura de cabo vermelho que guardava no avental. Nunca percebi bem como ela sabia exactamente o que cada planta precisava, mas raramente lhe morria alguma coisa. Aquele quintal era pequeno, mas parecia conter o mundo inteiro quando eu tinha sete anos.',
    approximateWordCount: 132,
  ),
];

const List<ReadingText> _kReadingTextsDe = [
  ReadingText(
    id: 'text_01',
    title: 'Der erste Schnee',
    body: 'In der Nacht hatte es geschneit, und als die Kinder am Morgen die Vorhänge aufzogen, lag die ganze Straße unter einer weißen, stillen Decke. Selbst die alten Kastanienbäume am Gehweg trugen dicke Schneehauben auf ihren kahlen Ästen. Der Brunnen auf dem kleinen Marktplatz war zugefroren, und das Eis schimmerte in der frühen Wintersonne. Krähen saßen auf dem Kirchendach und riefen laut in die kalte Luft. Der Bäcker hatte schon geöffnet; durch die beschlagenen Scheiben seiner Auslage sah man die frischen Brote aufgereiht. Die Kinder zogen sich eilig an, griffen nach ihren Schals und liefen hinaus. Ihre Atemwolken hingen wie kleine Fahnen in der Kälte. Der erste Schnee des Jahres brachte immer diese besondere Stille mit sich, die selbst die lauteste Stadt für einen Augenblick in etwas Unwirkliches verwandelt.',
    approximateWordCount: 128,
  ),
  ReadingText(
    id: 'text_02',
    title: 'Das Leben in der Großstadt',
    body: 'Wer in einer Großstadt lebt, kennt den Rhythmus, der sich von früh bis spät durch die Straßen zieht. Morgens drängen sich die Menschen in Zügen und Bussen, Kaffeebecher in der Hand, Kopfhörer in den Ohren. Die U-Bahn-Schächte atmen warme Luft aus, und auf den Bürgersteigen bilden sich kleine Staus vor den Bäckereien. Mittags füllen sich die Innenhöfe und Plätze, die Parkbänke werden knapp, und die Terrassen der Restaurants sind selbst bei trübem Wetter besetzt. Am Abend verlagert sich das Geschehen: Die Bürogebäude leeren sich, die Kneipen und Kinos füllen sich. Eine Großstadt schläft nie wirklich, sie verändert nur ihre Gesichter. Wer gelernt hat hinzuhören, erkennt in diesem dauerhaften Rauschen eine Art Melodie, unfertig und nie ganz gleich, aber immer vertraut.',
    approximateWordCount: 127,
  ),
  ReadingText(
    id: 'text_03',
    title: 'Warum der Himmel blau ist',
    body: 'Das Sonnenlicht, das uns täglich erreicht, besteht aus einem ganzen Farbspektrum, von Rot bis Violett. Auf seinem Weg durch die Erdatmosphäre trifft es auf winzige Gasmoleküle, vor allem Stickstoff und Sauerstoff. Diese Moleküle streuen das Licht, aber nicht gleichmäßig: Kurzwelliges blaues Licht wird dabei viel stärker abgelenkt als das langwellige rote. So gelangt das blaue Licht aus allen möglichen Richtungen in unsere Augen, während das rote Licht weitgehend geradeaus zieht. Der Himmel erscheint daher über uns blau. Bei Sonnenauf- und Sonnenuntergang steht die Sonne flach am Horizont, das Licht legt einen wesentlich längeren Weg durch die Atmosphäre zurück, das Blau wird herausgefiltert, und übrig bleiben die warmen Rot- und Orangetöne. Dieses einfache physikalische Prinzip, entdeckt im neunzehnten Jahrhundert, erklärt eine der schönsten Erscheinungen unseres Alltags.',
    approximateWordCount: 130,
  ),
  ReadingText(
    id: 'text_04',
    title: 'Brot und seine Geschichte',
    body: 'Kaum ein Lebensmittel ist so tief in der deutschen Alltagskultur verwurzelt wie das Brot. Über dreihundert verschiedene Sorten werden hierzulande gebacken, von hellem Weizenbrot über kräftiges Roggenbrot bis hin zu dunklem Pumpernickel aus Westfalen. Die Geschichte des Brotes reicht weit zurück: Schon vor Jahrtausenden mahlten Menschen Getreidekörner zwischen Steinen und buken flache Fladen auf heißen Platten. Die Zugabe von Sauerteig war eine der bedeutendsten Entdeckungen der Ernährungsgeschichte, denn sie ließ das Brot aufgehen und machte es bekömmlicher. Heute kaufen viele Menschen ihr Brot beim Bäcker um die Ecke, andere backen es selbst zu Hause. Dabei geht es längst nicht nur um den Geschmack: Ein frisches Brot am Morgen gehört für viele zur Vorstellung eines guten Tages, ganz unabhängig davon, was sonst noch auf dem Tisch steht.',
    approximateWordCount: 131,
  ),
  ReadingText(
    id: 'text_05',
    title: 'Kindheitserinnerungen an den Sommer',
    body: 'Früher schienen die Sommer endlos zu sein. Man erinnert sich an lange Nachmittage auf dem Hof der Großeltern, an den Geruch von frisch gemähtem Gras und an das leise Summen der Bienen im Lavendelgebüsch. Die Hände wurden klebrig von Kirschsaft, und abends saß die ganze Familie draußen, bis die Fledermäuse auftauchten und über den Garten jagten. Das Einschlafen fiel schwer, weil die Luft so warm blieb und durchs offene Fenster das Zirpen der Grillen hereindrang. Solche Erinnerungen haben eine eigene Qualität: Sie sind weniger präzise als ein Foto, aber dafür voll von Empfindungen, von Wärme und Geborgenheit. Mit zunehmendem Alter versteht man, dass diese Sommer nicht wirklich länger waren. Die Zeit dehnte sich, weil jeder Tag noch neu und unverbraucht war. Das ist etwas, das sich kein Geld der Welt zurückkaufen lässt.',
    approximateWordCount: 135,
  ),
];

const List<ReadingText> _kReadingTextsEnGb = [
  ReadingText(
    id: 'text_01',
    title: 'The Turning of the Tide',
    body: 'Twice a day, without fail, the sea reclaims the shore. The tide pulls back in the early morning, leaving behind a glistening expanse of wet sand and stranded pools teeming with tiny creatures. Crabs pick their way between pebbles, and lugworms leave their telltale casts at the water\'s edge. Children who grow up near the coast learn to read these rhythms instinctively, knowing when it is safe to wade out to the sandbar and when the channel will fill again. The tidal cycle is governed by the gravitational pull of the moon, which draws the oceans towards it as the Earth rotates beneath. Coastal communities have depended on this reliable pulse for centuries, timing their fishing boats, their harbour works, and their daily routines entirely around the sea\'s steady, unhurried breathing.',
    approximateWordCount: 131,
  ),
  ReadingText(
    id: 'text_02',
    title: 'A Market Morning',
    body: 'Every Saturday, the square at the centre of town fills long before most people have finished their breakfast. Traders arrive in the grey half-light, pulling tarpaulins off wooden frames and arranging their wares with the practised ease of people who have done this a thousand times. The smell of fresh bread mingles with the sharp tang of citrus and the earthier scent of root vegetables still dusted with soil. A fishmonger at the far end bellows the morning\'s catch in a voice meant to carry above the crowd, his prices chalked on a small blackboard and amended freely as the hours pass. By half past ten the aisles are busy and the chatter is constant, coins changing hands and old acquaintances stopping one another to share a few words. The market has been held here, without interruption, for well over two hundred years.',
    approximateWordCount: 140,
  ),
  ReadingText(
    id: 'text_03',
    title: 'Why Bread Rises',
    body: 'Bread owes its soft, airy texture to one of the most ancient partnerships in human cookery. When yeast — a single-celled fungus — is mixed into dough, it begins to consume the sugars present in the flour. As it feeds, it releases carbon dioxide gas, which becomes trapped in tiny pockets throughout the stretchy gluten network. The dough swells steadily during its proving time, often doubling in size in a warm kitchen. When the loaf enters the oven, the heat kills the yeast and sets the gluten structure permanently, locking all those little air bubbles in place. The result is the familiar open crumb of a well-made loaf. Bakers have understood this process intuitively for thousands of years, long before scientists gave it a name. Today, sourdough enthusiasts keep their starters alive with the same daily care that earlier generations devoted to the hearth fire.',
    approximateWordCount: 143,
  ),
  ReadingText(
    id: 'text_04',
    title: 'Fog over the Fens',
    body: 'There are mornings in late October when the flat country east of Cambridge disappears entirely behind a white wall of fog. The roads are empty, the distant pylons vanish, and even the silhouettes of the bare willows along the drainage ditches grow faint within thirty metres. Sound carries strangely in these conditions: a pheasant calling from an unseen field, the muffled rumble of a lorry on the main road, the creak of a gate somewhere to the left. The Fens were drained by Dutch engineers in the seventeenth century, and the landscape still bears their influence in the long straight cuts that carry rainwater out to the Wash. On mornings like this, though, the land seems to be reclaiming something of its older, waterlogged self, lying quiet beneath the mist as though it has simply forgotten the centuries of toil spent taming it.',
    approximateWordCount: 143,
  ),
  ReadingText(
    id: 'text_05',
    title: 'The Smell of a Library',
    body: 'There is a particular smell that belongs to old libraries and to nowhere else — a blend of aged paper, leather bindings, and the faint mustiness of rooms that have been kept just slightly too cool for comfort. Scientists have traced it to a cocktail of compounds released as paper breaks down over time, including vanilla-scented aldehydes and the sharper notes of organic acids. Yet for most people who grew up spending Saturday mornings among the stacks, the chemistry matters far less than the memory the smell unlocks. It speaks of wet coats hung over chair backs, of pencils chewed at the end, of the particular quiet that settles when a roomful of people are each absorbed in a separate world. Public libraries were once considered as essential to a neighbourhood as a post office or a park, and many still carry that sense of unhurried civic welcome within their walls.',
    approximateWordCount: 148,
  ),
];

// ─── END generated multilingual corpora ───

// ─── Sélection par langue ────────────────────────────────────────────────────

/// Corpus de textes pour la langue de contenu courante (d'après
/// [localeNotifier]). en-GB partage le corpus anglais ; es/pt/de retombent sur
/// le français tant que leurs textes ne sont pas ajoutés (Phase 2).
List<ReadingText> get kReadingTexts => switch (localeNotifier.contentTag) {
      'en' => _kReadingTextsEn,
      'en-GB' => _kReadingTextsEnGb,
      'es' => _kReadingTextsEs,
      'pt' => _kReadingTextsPt,
      'de' => _kReadingTextsDe,
      _ => _kReadingTextsFr,
    };

/// Retourne un texte par son identifiant (dans la langue courante),
/// ou null si introuvable.
ReadingText? findTextById(String id) {
  try {
    return kReadingTexts.firstWhere((t) => t.id == id);
  } catch (_) {
    return null;
  }
}
