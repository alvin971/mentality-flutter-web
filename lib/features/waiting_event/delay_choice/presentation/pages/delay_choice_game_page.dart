// L'écran du jeu de délai — le jeu du jour 4.
//
// ═══ CE QUE CET ÉCRAN DIT, ET REDIT ═══
//
// Que les sommes sont IMAGINAIRES. En toutes lettres à l'ouverture, puis en
// une ligne discrète sur chacun des vingt écrans de choix. La répétition n'est
// pas de la timidité : l'app vend un bilan par ailleurs, et quelqu'un qui
// arriverait au dixième écran en croyant avoir gagné 150 € répondrait pour
// toucher l'argent, pas selon sa préférence.
//
// ═══ CE QU'IL N'AFFICHE JAMAIS ═══
//
// · Aucun record, aucun « meilleur score ». Il n'y a pas de bonne réponse à un
//   arbitrage entre maintenant et plus tard — le raisonnement complet est en
//   tête de `delay_choice_score.dart`, et la conséquence ici est qu'on ne peint
//   pas ce chiffre.
// · Aucun chronomètre, aucun temps de réponse. Prendre trente secondes pour
//   choisir est parfaitement légitime : c'est une préférence, pas un réflexe.
//   L'écran ne mesure donc rien du temps, et n'a besoin d'aucun `Timer` — ce qui
//   lui évite au passage d'en laisser un en vol à sa fermeture.
// · Le mot « impulsivité ». Il désignerait un des deux bouts de l'échelle comme
//   un défaut.
//
// ═══ LES DEUX OFFRES CHANGENT DE PLACE ═══
//
// L'offre immédiate n'est pas toujours en haut : sa position alterne d'un essai
// à l'autre. C'est l'inverse du Stroop, dont les boutons gardent un ordre fixe,
// et les deux choix sont justes pour des raisons opposées — voir
// [DelayChoiceOffer.immediateOnTop].

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
import '../../data/delay_choice_material.dart';
import '../../data/delay_choice_record_store.dart';
import '../../domain/models/delay_choice_offer.dart';
import '../../domain/models/delay_choice_score.dart';
import '../../domain/services/delay_choice_run.dart';

/// Ce que l'écran montre à un instant donné.
enum _Phase { intro, trial, result }

/// La clé d'une des deux offres.
///
/// Viser le libellé ne suffirait pas : les deux offres portent toutes deux un
/// montant, et l'escalier finit par en proposer d'assez proches pour qu'un
/// `find.text` devienne ambigu. Surtout, les offres CHANGENT DE PLACE — un test
/// qui viserait « la première carte » toucherait tantôt l'une, tantôt l'autre.
Key offerKey({required bool immediate}) =>
    ValueKey('delay_choice_${immediate ? 'now' : 'later'}');

class DelayChoiceGamePage extends StatefulWidget {
  const DelayChoiceGamePage({
    super.key,
    this.store = const DelayChoiceRecordStore(),
    this.seed,
  });

  /// Où la dernière partie est gardée. Injectable pour les tests ; en
  /// production, la box chiffrée du module. Rien n'en sort vers le réseau.
  final DelayChoiceRecordStore store;

  /// `null` = partie tirée au hasard. Un test la fixe pour savoir quel délai et
  /// quelle position l'attendent à chaque essai.
  final int? seed;

  @override
  State<DelayChoiceGamePage> createState() => _DelayChoiceGamePageState();
}

class _DelayChoiceGamePageState extends State<DelayChoiceGamePage> {
  late DelayChoiceRun _partie;

  _Phase _phase = _Phase.intro;

  /// L'état d'AVANT cette partie — « la dernière fois : … ». Jamais un record.
  DelayChoiceRecord _precedent = DelayChoiceRecord.none;

  /// Verrou de ré-entrance sur la clôture : l'écriture est asynchrone et les
  /// cartes restent tactiles pendant ce temps. Sans lui, un dernier appui
  /// répété compterait la partie deux fois.
  bool _clotureEnCours = false;

  @override
  void initState() {
    super.initState();
    _partie = DelayChoiceRun.start(seed: _graine());
  }

  int _graine() => widget.seed ?? Random().nextInt(1 << 31);

  void _demarrer() => setState(() => _phase = _Phase.trial);

  Future<void> _choisir(bool toutDeSuite) async {
    if (_phase != _Phase.trial || _clotureEnCours) return;
    final suivante = _partie.answer(toutDeSuite);
    setState(() => _partie = suivante);
    if (suivante.isDone) await _terminer();
  }

  Future<void> _terminer() async {
    if (_clotureEnCours) return;
    _clotureEnCours = true;

    final avant = await widget.store.record(_score);
    if (!mounted) return;
    setState(() {
      _precedent = avant;
      _phase = _Phase.result;
    });
  }

  DelayChoiceScore get _score => DelayChoiceScore(
        indifferenceByDelay: _partie.indifferencePoints,
        delayedAmount: DelayChoiceRun.delayedAmount,
      );

  void _rejouer() {
    setState(() {
      // Une NOUVELLE partie : l'ordre des délais et les positions changent. La
      // graine injectée, elle, est respectée — c'est ce qui rend une partie
      // rejouée vérifiable par un test.
      _partie = DelayChoiceRun.start(seed: _graine());
      _clotureEnCours = false;
      _phase = _Phase.trial;
    });
  }

  @override
  Widget build(BuildContext context) => switch (_phase) {
        _Phase.intro => _ecranIntro(),
        _Phase.trial => _ecranChoix(),
        _Phase.result => _ecranResultat(),
      };

  // ─── Intro ──────────────────────────────────────────────────────────────────

  Widget _ecranIntro() {
    final l10n = context.l10n;
    final colors = KeplerColors.of(context);
    return KeplerScaffold(
      eyebrow: l10n.weDcEyebrow,
      title: l10n.weDcTitle,
      bottomBar: _barre(
        principal: KeplerButton(
          label: l10n.weDcStart,
          expand: true,
          onPressed: _demarrer,
        ),
        secondaire: KeplerButton(
          label: l10n.weDcLater,
          variant: KeplerButtonVariant.secondary,
          expand: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          Text(l10n.weDcIntroTitle, style: AppText.of(context).h2()),
          SizedBox(height: 12.h),
          Text(l10n.weDcIntroBody, style: AppText.of(context).body()),
          SizedBox(height: 20.h),
          // L'avertissement le plus important du jeu, et le seul encadré de
          // l'écran : rien n'est à gagner.
          KeplerCard(
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20.sp, color: colors.primary),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    l10n.weDcIntroImaginary,
                    style: AppText.of(context).bodySmall(),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            l10n.weDcIntroNoRightAnswer,
            style: AppText.of(context).bodySmall(color: colors.textSecondary),
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  // ─── Choix ──────────────────────────────────────────────────────────────────

  Widget _ecranChoix() {
    final l10n = context.l10n;
    final colors = KeplerColors.of(context);
    final locale = Localizations.localeOf(context);
    final DelayChoiceOffer? offre = _partie.offer;
    // La partie finie, l'écran de résultat prend le relais au `setState`
    // suivant. Ce garde-fou couvre la reconstruction qui se glisse entre les
    // deux.
    if (offre == null) return const SizedBox.shrink();

    final immediate = _CarteOffre(
      key: offerKey(immediate: true),
      amount: DelayChoiceMaterial.amount(offre.immediateAmount, locale),
      timing: DelayChoiceMaterial.now.resolve(locale),
      onTap: () => _choisir(true),
    );
    final differee = _CarteOffre(
      key: offerKey(immediate: false),
      amount: DelayChoiceMaterial.amount(offre.delayedAmount, locale),
      timing: DelayChoiceMaterial.delayLabel(offre.delayDays).resolve(locale),
      onTap: () => _choisir(false),
    );

    return KeplerScaffold(
      eyebrow: l10n.weDcEyebrow,
      title: l10n.weDcTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8.h),
          KeplerProgress(
            value: (_partie.answered + 1) / _partie.totalTrials,
            current: _partie.answered + 1,
            total: _partie.totalTrials,
            label: l10n.weDcProgressTag,
          ),
          SizedBox(height: 24.h),
          Text(l10n.weDcPrompt, style: AppText.of(context).h3()),
          SizedBox(height: 6.h),
          // Le rappel qui accompagne l'argent partout où il s'affiche.
          Text(
            l10n.weDcImaginaryTag,
            style: AppText.of(context).bodySmall(color: colors.textSecondary),
          ),
          SizedBox(height: 20.h),
          if (offre.immediateOnTop) ...[
            immediate,
            SizedBox(height: 12.h),
            differee,
          ] else ...[
            differee,
            SizedBox(height: 12.h),
            immediate,
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
    final locale = Localizations.localeOf(context);
    final score = _score;

    return KeplerScaffold(
      eyebrow: l10n.weDcEyebrow,
      title: l10n.weDcTitle,
      bottomBar: _barre(
        principal: KeplerButton(
          label: l10n.weDcDone,
          expand: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
        secondaire: KeplerButton(
          label: l10n.weDcReplay,
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
            // nuancer.
            Text(l10n.weDcIncoherentTitle, style: AppText.of(context).h2()),
            SizedBox(height: 12.h),
            Text(l10n.weDcIncoherentBody, style: AppText.of(context).body()),
          ] else ...[
            Text(l10n.weDcResultTitle, style: AppText.of(context).h2()),
            SizedBox(height: 16.h),
            Text(
              l10n.weDcPatienceScore(score.patiencePercent),
              style: AppText.of(context).monoScore(color: colors.primary),
            ),
            SizedBox(height: 12.h),
            Text(l10n.weDcResultCaption, style: AppText.of(context).body()),
            SizedBox(height: 20.h),
            // La phrase concrète : le chiffre redit en langue humaine. C'est
            // elle qu'on retient, pas l'index.
            ..._phraseConcrete(l10n, locale, score),
            _tableau(locale, score),
            if (_precedent.lastPatiencePercent != null) ...[
              SizedBox(height: 12.h),
              Text(
                l10n.weDcPrevious(_precedent.lastPatiencePercent!),
                style:
                    AppText.of(context).bodySmall(color: colors.textSecondary),
              ),
            ],
          ],
          SizedBox(height: 24.h),
          // Les deux phrases qui empêchent ce chiffre d'être mal lu. Elles sont
          // montrées MÊME quand la partie n'a rien donné : c'est là que la
          // tentation de « refaire pour avoir un meilleur score » est la plus
          // forte, alors qu'il n'y a pas de meilleur score.
          KeplerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.weDcNoBetterEnd,
                    style: AppText.of(context).bodySmall()),
                SizedBox(height: 10.h),
                Text(
                  l10n.weDcNotClinical,
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

  /// « Attendre 150 € un mois revient, pour toi, à recevoir 85 € tout de
  /// suite. » Vide si le délai de référence n'a pas été mené à son terme —
  /// ce qui n'arrive qu'à une partie abandonnée, jamais à une partie complète.
  List<Widget> _phraseConcrete(
    AppLocalizations l10n,
    Locale locale,
    DelayChoiceScore score,
  ) {
    final point = score.indifferenceAt(DelayChoiceMaterial.referenceDelayDays);
    if (point == null) return const [];
    return [
      Padding(
        padding: EdgeInsets.only(bottom: 20.h),
        child: Text(
          l10n.weDcIndifference(
            DelayChoiceMaterial.amount(DelayChoiceRun.delayedAmount, locale),
            DelayChoiceMaterial.amount(point, locale),
          ),
          style: AppText.of(context).bodyStrong(),
        ),
      ),
    ];
  }

  /// Ce que chaque délai valait. Le tableau est le résultat le plus honnête de
  /// l'écran : il montre les réponses telles quelles, sans index ni modèle.
  Widget _tableau(Locale locale, DelayChoiceScore score) {
    final colors = KeplerColors.of(context);
    final l10n = context.l10n;
    return KeplerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.weDcCurveTitle, style: AppText.of(context).monoLabel()),
          SizedBox(height: 12.h),
          for (final jours in score.delays) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DelayChoiceMaterial.shortDelayLabel(jours).resolve(locale),
                  style:
                      AppText.of(context).bodySmall(color: colors.textSecondary),
                ),
                Text(
                  DelayChoiceMaterial.amount(
                    score.indifferenceByDelay[jours]!,
                    locale,
                  ),
                  style: AppText.of(context).bodyStrong(),
                ),
              ],
            ),
            SizedBox(height: 8.h),
          ],
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

/// Une des deux offres : un montant, et quand on l'aurait.
///
/// Les deux cartes sont RIGOUREUSEMENT IDENTIQUES de présentation — même fond,
/// même typographie, même taille. Mettre l'offre différée en avant (ou
/// l'immédiate en couleur d'accent) suggérerait une bonne réponse, et un jeu qui
/// suggère la réponse ne mesure plus la préférence de personne.
///
/// La LARGEUR est imposée, et ce n'est pas une coquetterie de mise en page.
/// Laissée à leur contenu, les deux cartes prennent des largeurs différentes —
/// « dans une semaine » est plus long que « tout de suite », donc la carte
/// différée est SYSTÉMATIQUEMENT la plus large. La forme désignerait alors une
/// des deux offres avant même qu'on ait lu les montants, et elle le ferait dans
/// le même sens à chaque essai. Une garde de test compare les deux tailles.
class _CarteOffre extends StatelessWidget {
  const _CarteOffre({
    super.key,
    required this.amount,
    required this.timing,
    required this.onTap,
  });

  final String amount;
  final String timing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = KeplerColors.of(context);
    return SizedBox(
      width: double.infinity,
      child: KeplerCard(
        onTap: onTap,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(amount, style: AppText.of(context).h1()),
            SizedBox(height: 4.h),
            Text(
              timing,
              style: AppText.of(context).body(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
