// Le moteur de questionnaire — une question par écran, pour tous les modules.
//
// Écrit une fois, il sert aussi bien à un instrument validé qu'à un bloc de
// questions candidates : ce qui change d'un module à l'autre vit dans le
// `QModule` qu'on lui passe, jamais ici.
//
// Trois règles du programme sont tenues par la STRUCTURE de cet écran plutôt
// que par la discipline de qui l'utilisera :
//
// · AUCUNE QUESTION SAUTABLE. Il n'existe aucun chemin vers la question
//   suivante tant que la question courante n'a pas de réponse : le bouton est
//   désactivé, et il est le seul moyen d'avancer. Revenir en arrière pour se
//   corriger reste permis — ce n'est pas sauter.
// · ABANDON PERMIS, MAIS NOMMÉ. Chaque réponse est persistée dès qu'elle est
//   donnée ; quitter n'efface rien et ne termine rien. Le jeu de réponses
//   reste `inProgress`, donc partira marqué partiel.
// · L'ORDRE EST UN CONTRAT. Les items sont parcourus dans l'ordre du module,
//   et les réponses sont rangées par identifiant : rien ne peut les
//   redistribuer silencieusement.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/kepler_colors.dart';
import '../../../../core/widgets/kepler_button.dart';
import '../../../../core/widgets/kepler_card.dart';
import '../../../../core/widgets/kepler_progress.dart';
import '../../../../core/widgets/kepler_scaffold.dart';
import '../data/event_local_store.dart';
import '../data/event_upload_service.dart';
import '../domain/models/event_day.dart';
import '../domain/models/event_submission.dart';
import '../domain/models/q_answer_set.dart';
import '../domain/models/q_instrument.dart';
import '../domain/models/q_module.dart';

/// Ce que l'écran affiche à un instant donné.
enum _Phase { loading, transition, question, done }

/// Ce qui emporte les réponses vers le serveur. Injecté pour que les tests du
/// moteur n'aient pas de réseau à simuler.
typedef EventSubmitter = Future<void> Function(EventSubmission submission);

Future<void> _envoiParDefaut(EventSubmission submission) =>
    EventUploadService.instance.submit(submission);

class QuestionnaireRunnerPage extends StatefulWidget {
  const QuestionnaireRunnerPage({
    super.key,
    required this.module,
    required this.store,
    required this.title,
    this.onFinished,
    this.submit = _envoiParDefaut,
  });

  final QModule module;

  /// Injecté plutôt que pris en singleton : les tests s'en servent pour
  /// rejouer une reprise sans Hive.
  final EventAnswerStore store;

  /// Titre de la journée, résolu par l'appelant depuis les ARB.
  final String title;

  /// Notifié une seule fois, quand le questionnaire est terminé.
  final ValueChanged<QAnswerSet>? onFinished;

  /// Emporte les réponses vers le serveur — à la dernière question comme à
  /// l'abandon. Appelé DEPUIS CET ÉCRAN, jamais depuis un écran ultérieur :
  /// une action critique placée derrière une étape facultative finit par ne
  /// jamais être émise (le parrainage l'a prouvé). L'appel n'est pas attendu :
  /// l'envoi est durable et rejoué, il n'a pas à retarder l'affichage.
  final EventSubmitter submit;

  @override
  State<QuestionnaireRunnerPage> createState() =>
      _QuestionnaireRunnerPageState();
}

class _QuestionnaireRunnerPageState extends State<QuestionnaireRunnerPage> {
  late QAnswerSet _answers;
  _Phase _phase = _Phase.loading;
  int _index = 0;

  /// Vrai seulement au premier écran d'une session reprise — de quoi expliquer
  /// pourquoi on n'ouvre pas à la question 1.
  bool _reprise = false;

  /// La langue de passation, capturée tant que le contexte vit : un abandon
  /// déclenche l'envoi au moment où l'écran se ferme.
  String? _locale;

  QModule get _module => widget.module;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _locale = Localizations.localeOf(context).toString();
  }

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final enregistre = await widget.store.load(_module.id);
    if (!mounted) return;
    final answers = enregistre ?? QAnswerSet(moduleId: _module.id);
    final index = _module.resumeIndexFor(answers.answeredItemIds);

    setState(() {
      _answers = answers;
      // Un module déjà terminé se rouvre sur son écran de fin plutôt que sur
      // une question : on ne redemande pas ce qui a été donné.
      if (index >= _module.questionCount) {
        _index = _module.questionCount - 1;
        _phase = _Phase.done;
      } else {
        _index = index;
        _reprise = index > 0;
        _phase = _phaseFor(index);
      }
    });

    // RATTRAPAGE. Toutes les questions ont une réponse, mais le jeu est encore
    // `inProgress` : `_terminer()` n'a donc jamais abouti (app tuée entre la
    // dernière réponse et « Terminer »), et ces réponses n'ont JAMAIS été
    // confiées au service d'envoi. L'écran de fin n'offrant aucun second
    // chemin, sans ce rattrapage elles ne partiraient plus jamais.
    if (index >= _module.questionCount && answers.isPartial) {
      final termine = answers.markCompleted();
      _answers = termine;
      await widget.store.save(termine);
      _emporter(termine);
    }
  }

  /// Un bloc qui déclare un écran de transition l'affiche avant sa première
  /// question — y compris à la reprise, où l'échelle mérite d'être rappelée.
  _Phase _phaseFor(int index) =>
      _module.startsBlockAt(index) && _module.instrumentAt(index).transition != null
          ? _Phase.transition
          : _Phase.question;

  Future<void> _choisir(int value) async {
    final item = _module.items[_index];
    setState(() => _answers = _answers.withAnswer(item.id, value));
    // Persisté À CHAQUE réponse : c'est ce qui rend l'abandon inoffensif.
    await widget.store.save(_answers);
  }

  Future<void> _suivant() async {
    if (_index + 1 >= _module.questionCount) return _terminer();
    setState(() {
      _index += 1;
      _reprise = false;
      _phase = _phaseFor(_index);
    });
  }

  void _precedent() {
    if (_index == 0) return;
    setState(() {
      _index -= 1;
      _reprise = false;
      // On ne re-joue pas la transition en marche arrière : elle a déjà été lue.
      _phase = _Phase.question;
    });
  }

  Future<void> _terminer() async {
    final termine = _answers.markCompleted();
    setState(() {
      _answers = termine;
      _phase = _Phase.done;
    });
    await widget.store.save(termine);
    _emporter(termine);
    widget.onFinished?.call(termine);
  }

  /// Confie les réponses au service d'envoi. Rien n'est attendu ici : le
  /// service enregistre d'abord, envoie ensuite, et rejoue tant que le serveur
  /// n'a pas confirmé.
  void _emporter(QAnswerSet answers) {
    if (answers.answeredCount == 0) return;
    final locale = _locale;
    if (locale == null) return;
    widget.submit(EventSubmission.of(_module, answers, locale: locale));
  }

  /// Quitter en cours de route : on prévient que rien n'est perdu, ce qui est
  /// vrai — les réponses sont déjà sur le disque.
  Future<void> _demanderSortie() async {
    final l10n = context.l10n;
    final partir = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.weRunnerQuitTitle),
        content: Text(l10n.weRunnerQuitBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.weRunnerQuitStay),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.weRunnerQuitLeave),
          ),
        ],
      ),
    );
    if (partir != true) return;
    // Ce qui a déjà été répondu part MAINTENANT, marqué partiel — avant la
    // fermeture, pas depuis un écran qu'on n'atteindra peut-être jamais.
    _emporter(_answers);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Rien ne peut sortir de l'écran sans passer par la confirmation, sauf une
    // fois le questionnaire terminé.
    return PopScope(
      canPop: _phase == _Phase.done || _phase == _Phase.loading,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _demanderSortie();
      },
      child: switch (_phase) {
        // Pas d'indicateur d'attente : la lecture disque est instantanée, et
        // un tourniquet ferait croire à un traitement.
        _Phase.loading => KeplerScaffold(
            title: widget.title,
            child: const SizedBox.shrink(),
          ),
        _Phase.transition => _ecranTransition(),
        _Phase.question => _ecranQuestion(),
        _Phase.done => _ecranFin(),
      },
    );
  }

  // ─── Transition — « Partie 2 » ──────────────────────────────────────────────

  Widget _ecranTransition() {
    final transition = _module.instrumentAt(_index).transition!;
    final locale = Localizations.localeOf(context);
    return KeplerScaffold(
      title: widget.title,
      bottomBar: _barre(
        principal: KeplerButton(
          label: context.l10n.weRunnerTransitionCta,
          expand: true,
          onPressed: () => setState(() => _phase = _Phase.question),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 24.h),
          Text(transition.title.resolve(locale),
              style: AppText.of(context).h2()),
          SizedBox(height: 12.h),
          Text(transition.body.resolve(locale),
              style: AppText.of(context).body()),
        ],
      ),
    );
  }

  // ─── Question ───────────────────────────────────────────────────────────────

  Widget _ecranQuestion() {
    final l10n = context.l10n;
    final colors = KeplerColors.of(context);
    final locale = Localizations.localeOf(context);
    final item = _module.items[_index];
    final bloc = _module.instrumentAt(_index);
    final choisi = _answers.valueOf(item.id);
    final dernier = _index + 1 >= _module.questionCount;

    return KeplerScaffold(
      title: widget.title,
      bottomBar: _barre(
        secondaire: _index > 0
            ? KeplerButton(
                label: l10n.weRunnerBack,
                variant: KeplerButtonVariant.secondary,
                expand: true,
                onPressed: _precedent,
              )
            : null,
        principal: KeplerButton(
          label: dernier ? l10n.weRunnerFinish : l10n.weRunnerNext,
          expand: true,
          // LE verrou anti-saut : sans réponse, il n'existe aucun chemin vers
          // la suite.
          onPressed: choisi == null ? null : _suivant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8.h),
          KeplerProgress(
            value: (_index + 1) / _module.questionCount,
            current: _index + 1,
            total: _module.questionCount,
            label: _module.kind == DayActivityKind.contribution
                ? l10n.weRunnerContributionLabel
                : l10n.weRunnerScoredLabel,
          ),
          if (_reprise) ...[
            SizedBox(height: 12.h),
            Text(l10n.weRunnerResumed,
                style: AppText.of(context).bodySmall(color: colors.primary)),
          ],
          // Le cadrage honnête d'une contribution, à l'endroit où il compte :
          // pendant qu'on répond, pas dans une page annexe.
          if (bloc.origin == QItemOrigin.candidate) ...[
            SizedBox(height: 12.h),
            Text(l10n.weRunnerNoScoreNotice,
                style:
                    AppText.of(context).bodySmall(color: colors.textSecondary)),
          ],
          SizedBox(height: 24.h),
          Text(item.text.resolve(locale), style: AppText.of(context).h3()),
          SizedBox(height: 20.h),
          for (final option in bloc.scale.options) ...[
            _OptionTile(
              label: option.label.resolve(locale),
              selected: choisi == option.value,
              onTap: () => _choisir(option.value),
            ),
            SizedBox(height: 8.h),
          ],
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  // ─── Fin ────────────────────────────────────────────────────────────────────

  Widget _ecranFin() {
    final l10n = context.l10n;
    final contribution = _module.kind == DayActivityKind.contribution;
    return KeplerScaffold(
      title: widget.title,
      bottomBar: _barre(
        principal: KeplerButton(
          label: l10n.weRunnerDoneCta,
          expand: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 24.h),
          Text(l10n.weRunnerDoneTitle, style: AppText.of(context).h2()),
          SizedBox(height: 12.h),
          Text(
            contribution
                ? l10n.weRunnerDoneContributionBody
                : l10n.weRunnerDoneBody,
            style: AppText.of(context).body(),
          ),
        ],
      ),
    );
  }

  /// Les deux boutons se partagent la largeur à parts égales plutôt que de
  /// prendre leur taille naturelle : « Précédent » et « Abschließen » n'ont pas
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

/// Une modalité de réponse. Rendue en carte pleine largeur : la cible tactile
/// couvre le libellé entier, ce qu'un bouton radio ne fait pas.
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = KeplerColors.of(context);
    return KeplerCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      surface: selected,
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            size: 20.sp,
            color: selected ? colors.primary : colors.textTertiary,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: selected
                  ? AppText.of(context).bodyStrong(color: colors.primary)
                  : AppText.of(context).body(),
            ),
          ),
        ],
      ),
    );
  }
}
