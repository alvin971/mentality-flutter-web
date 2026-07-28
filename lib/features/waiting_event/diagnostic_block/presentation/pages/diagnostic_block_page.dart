// Le bloc diagnostic — deux écrans, posés une seule fois, à la fin du jour 1.
//
// POURQUOI À LA FIN, ET PAS AU DÉBUT. Demander d'emblée « as-tu un TDAH ? »
// amorcerait toutes les réponses qui suivent : on répond ensuite au
// questionnaire comme la personne qu'on vient de se déclarer être. Posé à la
// fin du jour 1, le bloc ne peut plus contaminer le dépistage autisme du
// jour 7 — ni aucun autre.
//
// POURQUOI « JE PRÉFÈRE NE PAS RÉPONDRE » N'EST PAS UNE POLITESSE. C'est une
// nécessité technique. Sans cette case, qui ne veut pas se déclarer coche
// « aucun » : le groupe témoin se remplit alors de personnes concernées, et
// l'échelle qu'on en tire ne sépare plus rien. Le refus, lui, s'exclut
// proprement de l'analyse.
//
// POURQUOI RIEN N'EST ÉCRIT AVANT LA FIN. Le store est en tout-ou-rien (voir
// son en-tête) : ce qui est coché ici ne vit que dans cet écran tant que la
// déclaration n'est pas entière. Quitter en route ne laisse donc aucune trace,
// et l'écran le dit avant de laisser partir.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/l10n/l10n_ext.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/kepler_colors.dart';
import '../../../../../core/widgets/kepler_button.dart';
import '../../../../../core/widgets/kepler_card.dart';
import '../../../../../core/widgets/kepler_scaffold.dart';
import '../../data/diagnostic_block_store.dart';
import '../../domain/models/diagnostic_answers.dart';

enum _Etape { liste, detail, fin, deja, echec }

class DiagnosticBlockPage extends StatefulWidget {
  const DiagnosticBlockPage({
    super.key,
    this.store = const DiagnosticBlockStore(),
  });

  final DiagnosticBlockStore store;

  @override
  State<DiagnosticBlockPage> createState() => _DiagnosticBlockPageState();
}

class _DiagnosticBlockPageState extends State<DiagnosticBlockPage> {
  _Etape _etape = _Etape.liste;

  final Set<DxCondition> _coches = {};
  bool _aucun = false;
  bool _refus = false;

  /// Les troubles à détailler, figés au passage de l'écran 1 à l'écran 2 :
  /// parcourir `_coches` directement exposerait l'écran de détail à une
  /// sélection qui bougerait sous lui.
  List<DxCondition> _aDetailler = const [];
  int _index = 0;
  final Map<DxCondition, DiagnosticDetailDraft> _brouillons = {};

  /// Verrou de ré-entrance sur la validation finale — l'écriture ouvre une box
  /// Hive chiffrée, plusieurs centaines de millisecondes au premier accès,
  /// pendant lesquelles le bouton reste tactile.
  bool _enCours = false;

  bool get _listeValidable => _refus || _aucun || _coches.isNotEmpty;

  DiagnosticDetailDraft _brouillon(DxCondition c) =>
      _brouillons.putIfAbsent(c, DiagnosticDetailDraft.new);

  // ─── Sélection ──────────────────────────────────────────────────────────────

  /// Cocher un trouble annule « aucun » et le refus : les trois formes
  /// s'excluent, et laisser coexister « aucun » avec un trouble produirait une
  /// déclaration qu'aucune analyse ne saurait lire.
  void _basculerTrouble(DxCondition c) => setState(() {
        _aucun = false;
        _refus = false;
        if (!_coches.remove(c)) _coches.add(c);
      });

  void _basculerAucun() => setState(() {
        _refus = false;
        _coches.clear();
        _aucun = !_aucun;
      });

  void _basculerRefus() => setState(() {
        _aucun = false;
        _coches.clear();
        _refus = !_refus;
      });

  // ─── Enchaînement ───────────────────────────────────────────────────────────

  Future<void> _quitterListe() async {
    // Refus et « aucun » n'ont rien à détailler : ils partent tels quels.
    if (_refus) return _valider(DiagnosticAnswers.declined);
    if (_aucun) return _valider(DiagnosticAnswers.none);
    setState(() {
      _aDetailler = [
        for (final c in DxCondition.values)
          if (_coches.contains(c)) c
      ];
      _index = 0;
      _etape = _Etape.detail;
    });
  }

  Future<void> _suivant() async {
    if (_index + 1 < _aDetailler.length) {
      return setState(() => _index += 1);
    }
    final details = <DxCondition, DiagnosticDetail>{};
    for (final c in _aDetailler) {
      final detail = _brouillon(c).build();
      // Ne peut pas arriver : le bouton est inerte tant que le brouillon
      // courant est incomplet, et les précédents l'ont été pour passer. On
      // s'arrête quand même plutôt que d'écrire une déclaration à trous.
      if (detail == null) return;
      details[c] = detail;
    }
    return _valider(DiagnosticAnswers.declared(details));
  }

  void _precedent() {
    if (_index == 0) return setState(() => _etape = _Etape.liste);
    setState(() => _index -= 1);
  }

  Future<void> _valider(DiagnosticAnswers answers) async {
    if (_enCours) return;
    setState(() => _enCours = true);
    // La langue de passation est lue TANT QUE LE CONTEXTE VIT : le store n'en
    // a pas, et c'est la seule information de contexte que la déclaration
    // emporte.
    final locale = Localizations.localeOf(context).toString();
    final ecrit = await widget.store.record(answers, locale: locale);
    if (!mounted) return;

    if (ecrit) {
      return setState(() {
        _enCours = false;
        _etape = _Etape.fin;
      });
    }
    // Refusée. Deux causes possibles, qui ne se disent pas de la même façon :
    // la question était déjà close (rien à refaire), ou l'écriture a échoué
    // (on peut réessayer). Un remerciement affiché ici ferait croire à une
    // déclaration enregistrée qui n'existe nulle part.
    final deja = await widget.store.isRecorded();
    if (!mounted) return;
    setState(() {
      _enCours = false;
      _etape = deja ? _Etape.deja : _Etape.echec;
    });
  }

  /// Quitter en route : contrairement au moteur de questionnaire, rien n'a été
  /// enregistré — et l'écran doit le dire plutôt que de laisser croire à une
  /// reprise possible.
  Future<void> _demanderSortie() async {
    final l10n = context.l10n;
    final partir = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.weDxQuitTitle),
        content: Text(l10n.weDxQuitBody),
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
    if (partir == true && mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final enSaisie = _etape == _Etape.liste || _etape == _Etape.detail;
    return PopScope(
      // Une fois la déclaration écrite (ou constatée impossible), il n'y a
      // plus rien à perdre : on sort sans confirmation.
      canPop: !enSaisie,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _demanderSortie();
      },
      child: switch (_etape) {
        _Etape.liste => _ecranListe(),
        _Etape.detail => _ecranDetail(),
        _Etape.fin => _ecranSimple(
            titre: context.l10n.weDxDoneTitle,
            corps: context.l10n.weDxDoneBody,
            resultat: true,
          ),
        _Etape.deja => _ecranSimple(
            titre: context.l10n.weDxAlreadyTitle,
            corps: context.l10n.weDxAlreadyBody,
            resultat: true,
          ),
        _Etape.echec => _ecranSimple(
            titre: context.l10n.weDxFailedTitle,
            corps: context.l10n.weDxFailedBody,
            resultat: false,
          ),
      },
    );
  }

  // ─── Écran 1 — la liste ─────────────────────────────────────────────────────

  Widget _ecranListe() {
    final l10n = context.l10n;
    final colors = KeplerColors.of(context);
    return KeplerScaffold(
      eyebrow: l10n.weDxEyebrow,
      title: l10n.weDxListTitle,
      bottomBar: _barre(
        principal: KeplerButton(
          label: l10n.weRunnerNext,
          expand: true,
          onPressed: (_listeValidable && !_enCours) ? _quitterListe : null,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8.h),
          Text(l10n.weDxListQuestion, style: AppText.of(context).h3()),
          SizedBox(height: 12.h),
          Text(l10n.weDxListBody,
              style: AppText.of(context).bodySmall(color: colors.textSecondary)),
          SizedBox(height: 6.h),
          Text(l10n.weDxListHint,
              style: AppText.of(context).bodySmall(color: colors.textSecondary)),
          SizedBox(height: 20.h),
          for (final c in DxCondition.values) ...[
            _Case(
              label: _nomTrouble(l10n, c),
              coche: _coches.contains(c),
              onTap: () => _basculerTrouble(c),
            ),
            SizedBox(height: 8.h),
          ],
          SizedBox(height: 12.h),
          _Case(
            label: l10n.weDxNone,
            coche: _aucun,
            onTap: _basculerAucun,
          ),
          SizedBox(height: 8.h),
          _Case(
            label: l10n.weDxPreferNotToSay,
            coche: _refus,
            onTap: _basculerRefus,
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  // ─── Écran 2 — le détail, trouble par trouble ───────────────────────────────

  Widget _ecranDetail() {
    final l10n = context.l10n;
    final condition = _aDetailler[_index];
    final draft = _brouillon(condition);
    final dernier = _index + 1 >= _aDetailler.length;

    return KeplerScaffold(
      eyebrow: l10n.weDxDetailProgress(_index + 1, _aDetailler.length),
      title: l10n.weDxDetailTitle,
      bottomBar: _barre(
        secondaire: KeplerButton(
          label: l10n.weRunnerBack,
          variant: KeplerButtonVariant.secondary,
          expand: true,
          onPressed: _enCours ? null : _precedent,
        ),
        principal: KeplerButton(
          label: dernier ? l10n.weRunnerFinish : l10n.weRunnerNext,
          expand: true,
          // Le même verrou anti-saut que le moteur : sans les quatre
          // réponses, il n'existe aucun chemin vers la suite.
          onPressed: (draft.isComplete && !_enCours) ? _suivant : null,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8.h),
          // Le nom du trouble vit dans le CORPS, pas seulement dans la barre :
          // celle-ci a une hauteur fixe et ellipse les titres longs — en
          // allemand, « Aufmerksamkeitsdefizit-Störung » y disparaîtrait.
          Text(_nomTrouble(l10n, condition), style: AppText.of(context).h2()),
          SizedBox(height: 20.h),
          _Groupe<DxSource>(
            question: l10n.weDxSourceQuestion,
            valeurs: DxSource.values,
            choisi: draft.source,
            libelle: (v) => switch (v) {
              DxSource.psychiatrist => l10n.weDxSourcePsychiatrist,
              DxSource.gp => l10n.weDxSourceGp,
              DxSource.psychologist => l10n.weDxSourcePsychologist,
              DxSource.selfSuspected => l10n.weDxSourceSelf,
            },
            onChanged: (v) => setState(() => draft.source = v),
          ),
          _Groupe<DxRecency>(
            question: l10n.weDxWhenQuestion,
            valeurs: DxRecency.values,
            choisi: draft.recency,
            libelle: (v) => switch (v) {
              DxRecency.under1Year => l10n.weDxWhenUnder1,
              DxRecency.from1to3Years => l10n.weDxWhen1to3,
              DxRecency.from3to10Years => l10n.weDxWhen3to10,
              DxRecency.over10Years => l10n.weDxWhenOver10,
              DxRecency.unknown => l10n.weDxWhenUnknown,
            },
            onChanged: (v) => setState(() => draft.recency = v),
          ),
          _Groupe<DxTreatment>(
            question: l10n.weDxTreatmentQuestion,
            valeurs: DxTreatment.values,
            choisi: draft.treatment,
            libelle: (v) => switch (v) {
              DxTreatment.current => l10n.weDxTreatmentYes,
              DxTreatment.none => l10n.weDxTreatmentNo,
              DxTreatment.past => l10n.weDxTreatmentPast,
            },
            onChanged: (v) => setState(() => draft.treatment = v),
          ),
          _Groupe<DxAssessment>(
            question: l10n.weDxAssessmentQuestion,
            valeurs: DxAssessment.values,
            choisi: draft.assessment,
            libelle: (v) => switch (v) {
              DxAssessment.yes => l10n.weDxAssessmentYes,
              DxAssessment.no => l10n.weDxAssessmentNo,
              DxAssessment.unknown => l10n.weDxAssessmentUnknown,
            },
            onChanged: (v) => setState(() => draft.assessment = v),
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  // ─── Écrans de sortie ───────────────────────────────────────────────────────

  /// [resultat] est ce que l'écran renvoie au hub : `true` quand la question
  /// est close (déclarée à l'instant ou déjà close auparavant), `false` quand
  /// rien n'a pu être écrit — auquel cas la carte doit rester visible.
  Widget _ecranSimple({
    required String titre,
    required String corps,
    required bool resultat,
  }) {
    final l10n = context.l10n;
    return KeplerScaffold(
      title: l10n.weDxListTitle,
      bottomBar: _barre(
        principal: KeplerButton(
          label: l10n.weRunnerDoneCta,
          expand: true,
          onPressed: () => Navigator.of(context).pop(resultat),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 24.h),
          Text(titre, style: AppText.of(context).h2()),
          SizedBox(height: 12.h),
          Text(corps, style: AppText.of(context).body()),
        ],
      ),
    );
  }

  /// Les deux boutons se partagent la largeur à parts égales : une largeur
  /// naturelle déborde dès la langue la plus bavarde.
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

String _nomTrouble(AppLocalizations l10n, DxCondition c) => switch (c) {
      DxCondition.adhd => l10n.weDxAdhd,
      DxCondition.autism => l10n.weDxAutism,
      DxCondition.dyslexia => l10n.weDxDyslexia,
      DxCondition.dyspraxia => l10n.weDxDyspraxia,
      DxCondition.dyscalculia => l10n.weDxDyscalculia,
      DxCondition.hpi => l10n.weDxHpi,
      DxCondition.depression => l10n.weDxDepression,
      DxCondition.anxiety => l10n.weDxAnxiety,
      DxCondition.bipolar => l10n.weDxBipolar,
      DxCondition.ocd => l10n.weDxOcd,
      DxCondition.sleep => l10n.weDxSleep,
      DxCondition.burnout => l10n.weDxBurnout,
      DxCondition.other => l10n.weDxOther,
    };

/// Une case à cocher pleine largeur : la cible tactile couvre le libellé
/// entier, ce qu'une `Checkbox` seule ne fait pas.
class _Case extends StatelessWidget {
  const _Case({required this.label, required this.coche, required this.onTap});

  final String label;
  final bool coche;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = KeplerColors.of(context);
    return Semantics(
      checked: coche,
      child: KeplerCard(
        onTap: onTap,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        surface: coche,
        child: Row(
          children: [
            Icon(
              coche ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20.sp,
              color: coche ? colors.primary : colors.textTertiary,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: coche
                    ? AppText.of(context).bodyStrong(color: colors.primary)
                    : AppText.of(context).body(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une question à choix unique — question, puis ses modalités.
class _Groupe<T> extends StatelessWidget {
  const _Groupe({
    required this.question,
    required this.valeurs,
    required this.choisi,
    required this.libelle,
    required this.onChanged,
  });

  final String question;
  final List<T> valeurs;
  final T? choisi;
  final String Function(T) libelle;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: AppText.of(context).bodyStrong()),
          SizedBox(height: 10.h),
          for (final v in valeurs) ...[
            _Radio(
              label: libelle(v),
              selected: choisi == v,
              onTap: () => onChanged(v),
            ),
            SizedBox(height: 8.h),
          ],
          SizedBox(height: 14.h),
        ],
      );
}

class _Radio extends StatelessWidget {
  const _Radio({
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
