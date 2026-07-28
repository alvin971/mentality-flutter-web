// L'écran du Stroop — le jeu du jour 2.
//
// ═══ CE QUE CET ÉCRAN N'AFFICHE JAMAIS ═══
//
// Aucune vitesse brute. Ni pendant la partie (pas de compteur de
// millisecondes qui défile), ni à la fin (les deux médianes ne sont pas
// montrées). Le seul chiffre rendu est l'ÉCART entre les deux conditions.
//
// Ce n'est pas de la pudeur d'affichage : la batterie mesure déjà la vitesse
// de traitement, et un jeu qui l'affiche la remesure sous un autre nom. Le
// raisonnement complet est en tête de `stroop_score.dart` ; ici, la
// conséquence est simplement qu'on ne peint pas ces nombres.
//
// ═══ LES BOUTONS DE RÉPONSE NE SONT PAS COLORÉS ═══
//
// Ils portent les noms des trois couleurs, écrits dans la couleur de texte
// ordinaire. Les peindre chacun dans sa teinte semblerait plus lisible et
// serait une faute : la personne pourrait alors répondre en appariant deux
// couleurs à l'écran, sans jamais nommer quoi que ce soit — l'interférence
// lexicale, qui est tout l'objet de la mesure, disparaîtrait. Une garde de
// test vérifie que ces libellés restent de la couleur du texte.
//
// Leur ORDRE est fixe pour toute la partie (celui de `StroopInk.values`). Des
// boutons qui changeraient de place d'un essai à l'autre mesureraient la
// recherche visuelle du bouton, pas l'inhibition.
//
// ═══ AUCUNE MINUTERIE ═══
//
// Pas de retour visuel temporisé après chaque réponse, pas de délai
// inter-essai, pas de compte à rebours : l'essai suivant s'affiche
// immédiatement. C'est plus simple à jouer, et surtout cela évite qu'un
// `Timer` en vol survive à la fermeture de l'écran. La justesse est rapportée
// à la fin, en une fois.
//
// Le seul garde-fou de saisie est le seuil de « tape parasite » : sous
// [_tapeParasiteMs], l'appui n'est pas une réponse au stimulus qui vient
// d'apparaître — c'est la fin du geste précédent. Il est ignoré, et l'essai
// reste posé. À distinguer de [StroopScore.minPlausibleMs] (150 ms), qui
// écarte du calcul des médianes une réponse ENREGISTRÉE mais trop hâtive pour
// avoir été réfléchie : celle-là compte pour la justesse, elle.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/l10n/l10n_ext.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/kepler_colors.dart';
import '../../../../../core/widgets/kepler_button.dart';
import '../../../../../core/widgets/kepler_card.dart';
import '../../../../../core/widgets/kepler_progress.dart';
import '../../../../../core/widgets/kepler_scaffold.dart';
import '../../data/stroop_material.dart';
import '../../data/stroop_record_store.dart';
import '../../domain/models/stroop_score.dart';
import '../../domain/models/stroop_trial.dart';
import '../../domain/services/stroop_chrono.dart';
import '../../domain/services/stroop_sequence.dart';
import '../widgets/stroop_stimulus.dart';

/// Ce que l'écran montre à un instant donné.
enum _Phase { intro, blockIntro, trial, result }

/// La clé du bouton de réponse d'une encre.
///
/// Le libellé seul ne suffit pas à désigner ce bouton : en condition de
/// conflit, le MOT affiché est lui aussi un nom de couleur, si bien qu'un
/// « appuie sur BLEU » viserait deux textes à l'écran. Un test qui taperait le
/// stimulus au lieu du bouton passerait pour la mauvaise raison.
Key answerKey(StroopInk ink) => ValueKey('stroop_answer_${ink.name}');

class StroopGamePage extends StatefulWidget {
  const StroopGamePage({
    super.key,
    this.store = const StroopRecordStore(),
    this.chrono,
    this.seed,
  });

  /// Où le record est gardé. Injectable pour les tests ; en production, la box
  /// chiffrée du module. Rien n'en sort vers le réseau.
  final StroopRecordStore store;

  /// `null` = un vrai chronomètre.
  final StroopChrono? chrono;

  /// `null` = séquence tirée au hasard. Un test la fixe pour savoir quelle
  /// encre attend à chaque essai.
  final int? seed;

  @override
  State<StroopGamePage> createState() => _StroopGamePageState();
}

class _StroopGamePageState extends State<StroopGamePage> {
  /// Sous ce délai, l'appui appartient au geste précédent, pas au stimulus qui
  /// vient d'apparaître. Il est ignoré — l'essai n'est pas consommé.
  static const int _tapeParasiteMs = 100;

  late final List<StroopTrial> _essais;
  late final StroopChrono _chrono;

  final List<StroopResponse> _reponses = [];

  _Phase _phase = _Phase.intro;
  int _index = 0;

  /// Le record connu — affiché à la fin, et mis à jour par la partie.
  StroopRecord _record = StroopRecord.none;

  /// La partie qui vient d'être jouée a-t-elle amélioré le record ?
  bool _nouveauRecord = false;

  /// Verrou de ré-entrance sur la clôture : le calcul du score et l'écriture
  /// du record sont asynchrones, et les boutons restent tactiles pendant ce
  /// temps. Sans lui, un dernier appui répété compterait la partie deux fois.
  bool _clotureEnCours = false;

  @override
  void initState() {
    super.initState();
    _essais = StroopSequence.build(
      seed: widget.seed ?? Random().nextInt(1 << 31),
    );
    _chrono = widget.chrono ?? RealStroopChrono();
    _lireRecord();
  }

  Future<void> _lireRecord() async {
    final connu = await widget.store.read();
    if (mounted) setState(() => _record = connu);
  }

  StroopTrial get _essai => _essais[_index];

  /// Le premier essai d'un bloc mérite son écran d'annonce : la consigne ne
  /// change pas (on nomme toujours l'encre), mais ce qui est en jeu, si —
  /// l'entraînement s'arrête, puis les mots se mettent à contredire.
  bool _ouvreUnBloc(int index) =>
      index == StroopSequence.practiceCount ||
      index == StroopSequence.practiceCount + StroopSequence.blockLength;

  void _demarrer() {
    setState(() => _phase = _Phase.trial);
    _chrono.start();
  }

  void _repondre(StroopInk choix) {
    if (_phase != _Phase.trial) return;
    final ecoule = _chrono.elapsedMs;
    if (ecoule < _tapeParasiteMs) return; // fin du geste précédent

    _reponses.add(StroopResponse(
      trial: _essai,
      chosen: choix,
      elapsedMs: ecoule,
    ));

    final suivant = _index + 1;
    if (suivant >= _essais.length) {
      _terminer();
      return;
    }

    setState(() {
      _index = suivant;
      _phase = _ouvreUnBloc(suivant) ? _Phase.blockIntro : _Phase.trial;
    });
    if (_phase == _Phase.trial) _chrono.start();
  }

  Future<void> _terminer() async {
    if (_clotureEnCours) return;
    _clotureEnCours = true;

    final score = StroopScore.of(_reponses);
    // Le record d'AVANT se relit ici, et pas dans `_record` : celui-ci a pu
    // n'être pas encore chargé (la lecture est asynchrone) ou avoir vieilli.
    // Annoncer « nouveau record » sur un record inconnu serait une flatterie
    // automatique à la première partie de chaque session.
    final avant = (await widget.store.read()).bestInterferenceMs;
    final apres = await widget.store.record(score);
    if (!mounted) return;
    setState(() {
      _record = apres;
      _nouveauRecord = score.isReliable &&
          (avant == null || score.interferenceMs < avant);
      _phase = _Phase.result;
    });
  }

  void _rejouer() {
    setState(() {
      _essais
        ..clear()
        // Une NOUVELLE séquence à chaque partie : rejouer le même ordre
        // laisserait mémoriser les enchaînements, et l'écart se réduirait
        // pour une raison qui n'est plus l'inhibition. La graine injectée,
        // elle, est respectée — c'est ce qui rend une partie rejouée
        // vérifiable par un test.
        ..addAll(StroopSequence.build(
          seed: widget.seed ?? Random().nextInt(1 << 31),
        ));
      _reponses.clear();
      _index = 0;
      _nouveauRecord = false;
      _clotureEnCours = false;
      _phase = _Phase.trial;
    });
    _chrono.start();
  }

  @override
  Widget build(BuildContext context) => switch (_phase) {
        _Phase.intro => _ecranIntro(),
        _Phase.blockIntro => _ecranBloc(),
        _Phase.trial => _ecranEssai(),
        _Phase.result => _ecranResultat(),
      };

  // ─── Intro ──────────────────────────────────────────────────────────────────

  Widget _ecranIntro() {
    final l10n = context.l10n;
    final colors = KeplerColors.of(context);
    return KeplerScaffold(
      eyebrow: l10n.weStroopEyebrow,
      title: l10n.weStroopTitle,
      bottomBar: _barre(
        principal: KeplerButton(
          label: l10n.weStroopStart,
          expand: true,
          onPressed: _demarrer,
        ),
        secondaire: KeplerButton(
          label: l10n.weStroopLater,
          variant: KeplerButtonVariant.secondary,
          expand: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          Text(l10n.weStroopIntroTitle, style: AppText.of(context).h2()),
          SizedBox(height: 12.h),
          Text(l10n.weStroopIntroBody, style: AppText.of(context).body()),
          SizedBox(height: 16.h),
          Text(
            l10n.weStroopIntroPractice,
            style: AppText.of(context).bodySmall(color: colors.textSecondary),
          ),
          SizedBox(height: 20.h),
          // Un exemple montré plutôt qu'expliqué : la consigne « nomme
          // l'encre » se comprend en une seconde devant un mot contrarié, et
          // en trois phrases sans lui.
          StroopStimulus(
            trial: StroopTrial.conflict(
              ink: StroopInk.bleu,
              word: StroopInk.rouge,
              scored: false,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            l10n.weStroopIntroExample,
            style: AppText.of(context).bodySmall(color: colors.textSecondary),
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  // ─── Annonce de bloc ────────────────────────────────────────────────────────

  Widget _ecranBloc() {
    final l10n = context.l10n;
    final conflit = _essai.condition == StroopCondition.conflict;
    return KeplerScaffold(
      eyebrow: l10n.weStroopEyebrow,
      title: l10n.weStroopTitle,
      bottomBar: _barre(
        principal: KeplerButton(
          label: l10n.weStroopBlockCta,
          expand: true,
          onPressed: _demarrer,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 32.h),
          Text(
            conflit ? l10n.weStroopBlockConflictTitle : l10n.weStroopBlockScoredTitle,
            style: AppText.of(context).h2(),
          ),
          SizedBox(height: 12.h),
          Text(
            conflit ? l10n.weStroopBlockConflictBody : l10n.weStroopBlockScoredBody,
            style: AppText.of(context).body(),
          ),
        ],
      ),
    );
  }

  // ─── Essai ──────────────────────────────────────────────────────────────────

  Widget _ecranEssai() {
    final l10n = context.l10n;
    final colors = KeplerColors.of(context);
    final locale = Localizations.localeOf(context);
    final entrainement = !_essai.scored;

    return KeplerScaffold(
      eyebrow: l10n.weStroopEyebrow,
      title: l10n.weStroopTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8.h),
          KeplerProgress(
            value: (_index + 1) / _essais.length,
            current: _index + 1,
            total: _essais.length,
            label: entrainement
                ? l10n.weStroopPracticeTag
                : l10n.weStroopScoredTag,
          ),
          SizedBox(height: 24.h),
          Text(
            l10n.weStroopPrompt,
            style: AppText.of(context).bodySmall(color: colors.textSecondary),
          ),
          SizedBox(height: 16.h),
          StroopStimulus(trial: _essai),
          SizedBox(height: 28.h),
          // Ordre FIXE, libellés NON colorés — voir l'en-tête du fichier.
          for (final encre in StroopInk.values) ...[
            _BoutonReponse(
              key: answerKey(encre),
              label: StroopMaterial.nameOf(encre).resolve(locale),
              onTap: () => _repondre(encre),
            ),
            SizedBox(height: 10.h),
          ],
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  // ─── Résultat ───────────────────────────────────────────────────────────────

  Widget _ecranResultat() {
    final l10n = context.l10n;
    final colors = KeplerColors.of(context);
    final score = StroopScore.of(_reponses);

    return KeplerScaffold(
      eyebrow: l10n.weStroopEyebrow,
      title: l10n.weStroopTitle,
      bottomBar: _barre(
        principal: KeplerButton(
          label: l10n.weStroopDone,
          expand: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
        secondaire: KeplerButton(
          label: l10n.weStroopReplay,
          variant: KeplerButtonVariant.secondary,
          expand: true,
          onPressed: _rejouer,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 24.h),
          if (!score.isReliable) ...[
            // Rien n'est annoncé plutôt qu'un chiffre qu'on devrait aussitôt
            // nuancer. Le record précédent, lui, reste intact.
            Text(l10n.weStroopUnreliableTitle, style: AppText.of(context).h2()),
            SizedBox(height: 12.h),
            Text(l10n.weStroopUnreliableBody, style: AppText.of(context).body()),
          ] else ...[
            Text(l10n.weStroopResultTitle, style: AppText.of(context).h2()),
            SizedBox(height: 16.h),
            Text(
              l10n.weStroopMilliseconds(score.interferenceMs),
              style: AppText.of(context).monoScore(color: colors.primary),
            ),
            SizedBox(height: 12.h),
            Text(l10n.weStroopResultCaption, style: AppText.of(context).body()),
            SizedBox(height: 20.h),
            Text(
              l10n.weStroopAccuracy(score.correctCount, score.scoredCount),
              style: AppText.of(context).bodySmall(color: colors.textSecondary),
            ),
            if (_nouveauRecord) ...[
              SizedBox(height: 8.h),
              Text(
                l10n.weStroopNewBest,
                style: AppText.of(context).bodyStrong(color: colors.primary),
              ),
            ] else if (_record.bestInterferenceMs != null) ...[
              SizedBox(height: 8.h),
              Text(
                l10n.weStroopBest(_record.bestInterferenceMs!),
                style: AppText.of(context).bodySmall(color: colors.textSecondary),
              ),
            ],
          ],
          SizedBox(height: 24.h),
          // Les deux phrases qui empêchent ce chiffre d'être mal lu. Elles
          // sont montrées MÊME quand la partie n'a rien donné : c'est là que
          // la tentation de « réessayer pour faire un meilleur temps » est la
          // plus forte.
          KeplerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.weStroopNotSpeed,
                  style: AppText.of(context).bodySmall(),
                ),
                SizedBox(height: 10.h),
                Text(
                  l10n.weStroopNotClinical,
                  style:
                      AppText.of(context).bodySmall(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  /// Deux boutons à parts égales : « Rejouer » et « Weiter spielen » n'ont pas
  /// la même longueur, et une largeur naturelle déborde dès la langue la plus
  /// bavarde.
  Widget _barre({required Widget principal, Widget? secondaire}) => SafeArea(
        minimum: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
        child: Row(
          children: [
            if (secondaire != null) ...[
              Expanded(child: secondaire),
              SizedBox(width: 12.w),
            ],
            Expanded(child: principal),
          ],
        ),
      );
}

/// Un bouton de réponse : le NOM d'une couleur, dans la couleur du texte
/// ordinaire. Jamais dans sa propre teinte — voir l'en-tête du fichier.
class _BoutonReponse extends StatelessWidget {
  const _BoutonReponse({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => KeplerCard(
        onTap: onTap,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Center(
          child: Text(
            label,
            style: AppText.of(context).bodyStrong(),
          ),
        ),
      );
}
