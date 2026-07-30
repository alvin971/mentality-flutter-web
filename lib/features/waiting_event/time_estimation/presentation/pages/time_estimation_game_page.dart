// L'écran du jeu des durées — le jeu du jour 5.
//
// ═══ LE SEUL JEU QUI A BESOIN D'UNE MINUTERIE ═══
//
// Le Stroop s'en est passé volontairement, le jeu du délai n'en a jamais eu
// l'usage. Ici elle est inévitable : le stimulus EST une durée, il faut donc
// allumer un panneau et l'éteindre 900 millisecondes plus tard.
//
// D'où trois règles, et la troisième est celle qui compte :
//
//  1. UNE SEULE minuterie à la fois. Le champ est unique et chaque programmation
//     annule la précédente — deux minuteries en vol feraient avancer l'essai deux
//     fois, et l'intervalle affiché ne serait plus celui qui est enregistré.
//  2. TOUT RAPPEL VÉRIFIE `mounted`. Une minuterie qui se déclenche après la
//     fermeture appellerait `setState` sur un état démonté.
//  3. `dispose` ANNULE. C'est la garde principale : sans elle, une minuterie
//     programmée survit à la fermeture de l'écran, et le banc d'essai des widgets
//     le refuse explicitement (« a Timer is still pending »). Le test qui ferme
//     l'écran en plein intervalle échouerait donc — c'est voulu, c'est lui qui
//     tient cette règle.
//
// ═══ CE QUI N'EST PAS MESURÉ ═══
//
// Le temps de RÉPONSE. La personne répond quand elle veut, aucune horloge ne
// tourne de son côté, et rien de ce qu'elle met à décider n'entre dans le score.
// C'est ce qui garde ce jeu à distance de la vitesse de traitement, que la
// batterie mesure déjà par ailleurs.
//
// ═══ LA DURÉE AFFICHÉE N'EST PAS RE-MESURÉE ═══
//
// Le score repose sur les durées VOULUES, pas sur des durées relevées à
// l'exécution. Un téléphone qui saute des images affiche donc des intervalles un
// peu plus longs que demandé — mais les deux intervalles d'un même essai sont
// dessinés de la même façon, et le score est leur RAPPORT : un retard
// systématique s'annule. Reste une gigue aléatoire, qui ajoute du bruit et donc
// GONFLE légèrement le seuil mesuré. Le biais va dans le sens prudent : il ne
// fabrique pas de finesse, il en rabote.

import 'dart:async';
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
import '../../data/time_estimation_record_store.dart';
import '../../domain/models/duration_trial.dart';
import '../../domain/models/time_acuity_score.dart';
import '../../domain/services/time_estimation_run.dart';
import '../widgets/duration_panel.dart';

/// Ce que l'écran montre à un instant donné.
enum _Phase {
  intro,

  /// Panneau éteint, juste avant le premier intervalle. Sans ce temps mort, le
  /// premier intervalle démarrerait sur l'appui précédent : son début serait
  /// confondu avec un geste, et la durée perçue en serait entamée.
  ready,

  /// Premier intervalle en cours.
  first,

  /// Entre les deux intervalles. Le panneau s'éteint : sans coupure, les deux
  /// durées n'en feraient qu'une.
  between,

  /// Second intervalle en cours.
  second,

  /// Les deux boutons de réponse.
  answer,

  result,
}

/// La clé d'un des deux boutons de réponse.
///
/// Les libellés (« Le premier », « Le second ») sont traduits, et un test qui les
/// viserait en dur casserait à la première relecture d'un traducteur.
Key answerKey({required bool first}) =>
    ValueKey('time_estimation_${first ? 'first' : 'second'}');

class TimeEstimationGamePage extends StatefulWidget {
  const TimeEstimationGamePage({
    super.key,
    this.store = const TimeEstimationRecordStore(),
    this.seed,
  });

  /// Où le record est gardé. Injectable pour les tests ; en production, la box
  /// chiffrée du module. Rien n'en sort vers le réseau.
  final TimeEstimationRecordStore store;

  /// `null` = partie tirée au hasard. Un test la fixe pour savoir quel standard
  /// et quelle position l'attendent à chaque essai.
  final int? seed;

  /// Temps mort avant le premier intervalle d'un essai.
  ///
  /// PUBLIC parce qu'un test doit avancer l'horloge exactement de ce qu'il faut :
  /// recopier la valeur dans le test créerait deux vérités, et la première
  /// retouche de rythme laisserait un test vert sur un écran devenu faux.
  static const Duration beforeTrial = Duration(milliseconds: 700);

  /// Coupure entre les deux intervalles. Fixe, et la même à chaque essai : une
  /// coupure variable ferait partie de ce qu'on compare.
  static const Duration betweenIntervals = Duration(milliseconds: 600);

  @override
  State<TimeEstimationGamePage> createState() => _TimeEstimationGamePageState();
}

class _TimeEstimationGamePageState extends State<TimeEstimationGamePage> {
  late TimeEstimationRun _partie;

  /// L'unique minuterie en vol. Toute programmation annule la précédente, et
  /// `dispose` l'annule — voir l'en-tête du fichier.
  Timer? _minuterie;

  _Phase _phase = _Phase.intro;

  /// Le record connu — affiché à la fin, et mis à jour par la partie.
  TimeEstimationRecord _record = TimeEstimationRecord.none;

  /// La partie qui vient d'être jouée a-t-elle affiné le record ?
  bool _nouveauRecord = false;

  /// Verrou de ré-entrance sur la clôture : le calcul et l'écriture sont
  /// asynchrones, et les boutons restent tactiles pendant ce temps. Sans lui, un
  /// dernier appui répété compterait la partie deux fois.
  bool _clotureEnCours = false;

  @override
  void initState() {
    super.initState();
    _partie = TimeEstimationRun.start(seed: _graine());
    _lireRecord();
  }

  @override
  void dispose() {
    // LA garde : sans elle, une minuterie programmée survit à l'écran.
    _minuterie?.cancel();
    super.dispose();
  }

  int _graine() => widget.seed ?? Random().nextInt(1 << 31);

  Future<void> _lireRecord() async {
    final connu = await widget.store.read();
    if (mounted) setState(() => _record = connu);
  }

  /// Programme [action] dans [delai], en remplaçant ce qui était en vol.
  void _apres(Duration delai, VoidCallback action) {
    _minuterie?.cancel();
    _minuterie = Timer(delai, () {
      if (!mounted) return;
      action();
    });
  }

  DurationTrial? get _essai => _partie.trial;

  void _demarrer() {
    setState(() => _phase = _Phase.ready);
    _lancerEssai();
  }

  /// Enchaîne les quatre temps d'un essai : temps mort, premier intervalle,
  /// coupure, second intervalle. Puis rend la main.
  void _lancerEssai() {
    final essai = _essai;
    if (essai == null) return;
    _apres(TimeEstimationGamePage.beforeTrial, () {
      setState(() => _phase = _Phase.first);
      _apres(Duration(milliseconds: essai.firstMs), () {
        setState(() => _phase = _Phase.between);
        _apres(TimeEstimationGamePage.betweenIntervals, () {
          setState(() => _phase = _Phase.second);
          _apres(Duration(milliseconds: essai.secondMs), () {
            setState(() => _phase = _Phase.answer);
          });
        });
      });
    });
  }

  Future<void> _repondre({required bool premier}) async {
    if (_phase != _Phase.answer || _clotureEnCours) return;
    final suivante = _partie.answer(choseFirst: premier);
    if (suivante.isDone) {
      setState(() => _partie = suivante);
      await _terminer();
      return;
    }
    setState(() {
      _partie = suivante;
      _phase = _Phase.ready;
    });
    _lancerEssai();
  }

  Future<void> _terminer() async {
    if (_clotureEnCours) return;
    _clotureEnCours = true;
    _minuterie?.cancel();

    final TimeAcuityScore score = _partie.score;
    // Le record d'AVANT se relit ici, et pas dans `_record` : celui-ci a pu
    // n'être pas encore chargé (la lecture est asynchrone) ou avoir vieilli.
    // Annoncer « nouveau record » sur un record inconnu serait une flatterie
    // automatique à la première partie de chaque session.
    final avant = (await widget.store.read()).bestThresholdPercent;
    final apres = await widget.store.record(score);
    if (!mounted) return;
    setState(() {
      _record = apres;
      _nouveauRecord =
          score.isReliable && (avant == null || score.thresholdPercent < avant);
      _phase = _Phase.result;
    });
  }

  void _rejouer() {
    setState(() {
      // Une NOUVELLE partie : standards et positions changent. La graine
      // injectée, elle, est respectée — c'est ce qui rend une partie rejouée
      // vérifiable par un test.
      _partie = TimeEstimationRun.start(seed: _graine());
      _nouveauRecord = false;
      _clotureEnCours = false;
      _phase = _Phase.ready;
    });
    _lancerEssai();
  }

  @override
  Widget build(BuildContext context) => switch (_phase) {
        _Phase.intro => _ecranIntro(),
        _Phase.result => _ecranResultat(),
        _ => _ecranEssai(),
      };

  // ─── Intro ──────────────────────────────────────────────────────────────────

  Widget _ecranIntro() {
    final l10n = context.l10n;
    final colors = KeplerColors.of(context);
    return KeplerScaffold(
      eyebrow: l10n.weTeEyebrow,
      title: l10n.weTeTitle,
      bottomBar: _barre(
        principal: KeplerButton(
          label: l10n.weTeStart,
          expand: true,
          onPressed: _demarrer,
        ),
        secondaire: KeplerButton(
          label: l10n.weTeLater,
          variant: KeplerButtonVariant.secondary,
          expand: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          Text(l10n.weTeIntroTitle, style: AppText.of(context).h2()),
          SizedBox(height: 12.h),
          Text(l10n.weTeIntroBody, style: AppText.of(context).body()),
          SizedBox(height: 16.h),
          Text(
            l10n.weTeIntroTooShortToCount,
            style: AppText.of(context).bodySmall(color: colors.textSecondary),
          ),
          SizedBox(height: 20.h),
          // Le panneau éteint, montré une fois : la consigne parle d'un panneau
          // qui s'allume, autant savoir lequel avant que ça commence.
          const DurationPanel(lit: false),
          SizedBox(height: 12.h),
          Text(
            l10n.weTeIntroExample,
            style: AppText.of(context).bodySmall(color: colors.textSecondary),
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  // ─── Essai ──────────────────────────────────────────────────────────────────

  Widget _ecranEssai() {
    final l10n = context.l10n;
    final colors = KeplerColors.of(context);
    final aRepondre = _phase == _Phase.answer;

    return KeplerScaffold(
      eyebrow: l10n.weTeEyebrow,
      title: l10n.weTeTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8.h),
          KeplerProgress(
            value: (_partie.answered + 1) / TimeEstimationRun.trials,
            current: _partie.answered + 1,
            total: TimeEstimationRun.trials,
            label: l10n.weTeProgressTag,
          ),
          SizedBox(height: 24.h),
          // La consigne ne bouge pas de place entre « regarde » et « réponds » :
          // un texte qui change de hauteur déplacerait le panneau juste avant
          // qu'un intervalle commence.
          SizedBox(
            height: 44.h,
            child: Text(
              aRepondre ? l10n.weTePrompt : l10n.weTeWatch,
              style: aRepondre
                  ? AppText.of(context).h3()
                  : AppText.of(context).bodySmall(color: colors.textSecondary),
            ),
          ),
          SizedBox(height: 16.h),
          DurationPanel(
            lit: _phase == _Phase.first || _phase == _Phase.second,
          ),
          SizedBox(height: 28.h),
          // Les boutons n'apparaissent qu'à la question, mais leur PLACE est
          // réservée d'un bout à l'autre de l'essai : surgissants, ils feraient
          // remonter le panneau au moment précis où le second intervalle
          // s'achève.
          Opacity(
            opacity: aRepondre ? 1 : 0,
            child: IgnorePointer(
              ignoring: !aRepondre,
              child: Column(
                children: [
                  _BoutonReponse(
                    key: answerKey(first: true),
                    label: l10n.weTeFirst,
                    onTap: () => _repondre(premier: true),
                  ),
                  SizedBox(height: 10.h),
                  _BoutonReponse(
                    key: answerKey(first: false),
                    label: l10n.weTeSecond,
                    onTap: () => _repondre(premier: false),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  // ─── Résultat ───────────────────────────────────────────────────────────────

  Widget _ecranResultat() {
    final l10n = context.l10n;
    final colors = KeplerColors.of(context);
    final TimeAcuityScore score = _partie.score;

    return KeplerScaffold(
      eyebrow: l10n.weTeEyebrow,
      title: l10n.weTeTitle,
      bottomBar: _barre(
        principal: KeplerButton(
          label: l10n.weTeDone,
          expand: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
        secondaire: KeplerButton(
          label: l10n.weTeReplay,
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
            Text(l10n.weTeUnreliableTitle, style: AppText.of(context).h2()),
            SizedBox(height: 12.h),
            Text(l10n.weTeUnreliableBody, style: AppText.of(context).body()),
          ] else ...[
            Text(l10n.weTeResultTitle, style: AppText.of(context).h2()),
            SizedBox(height: 16.h),
            Text(
              l10n.weTeThreshold(score.thresholdPercent),
              style: AppText.of(context).monoScore(color: colors.primary),
            ),
            SizedBox(height: 12.h),
            Text(l10n.weTeResultCaption, style: AppText.of(context).body()),
            SizedBox(height: 20.h),
            Text(
              l10n.weTeAccuracyNote(score.accuracyPercent),
              style: AppText.of(context).bodySmall(color: colors.textSecondary),
            ),
            if (_nouveauRecord) ...[
              SizedBox(height: 8.h),
              Text(
                l10n.weTeNewBest,
                style: AppText.of(context).bodyStrong(color: colors.primary),
              ),
            ] else if (_record.bestThresholdPercent != null) ...[
              SizedBox(height: 8.h),
              Text(
                l10n.weTeBest(_record.bestThresholdPercent!),
                style: AppText.of(context).bodySmall(color: colors.textSecondary),
              ),
            ],
          ],
          SizedBox(height: 24.h),
          // Les deux phrases qui empêchent ce chiffre d'être mal lu. Elles sont
          // montrées MÊME quand la partie n'a rien donné : c'est là que la
          // tentation de recommencer pour « faire un meilleur chiffre » est la
          // plus forte.
          KeplerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.weTeNotSpeed, style: AppText.of(context).bodySmall()),
                SizedBox(height: 10.h),
                Text(
                  l10n.weTeNotClinical,
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

  /// Deux boutons à parts égales : « Rejouer » et « Nochmal spielen » n'ont pas
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

/// Un bouton de réponse. Les deux sont de présentation identique : mettre l'un en
/// avant orienterait la réponse d'un essai dont la bonne moitié du temps est de
/// l'autre côté.
class _BoutonReponse extends StatelessWidget {
  const _BoutonReponse({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: KeplerCard(
          onTap: onTap,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Center(
            child: Text(label, style: AppText.of(context).bodyStrong()),
          ),
        ),
      );
}
