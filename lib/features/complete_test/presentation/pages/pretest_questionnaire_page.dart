// Le questionnaire préalable — trois écrans au plus, avant le premier cube.
//
// Il s'intercale entre l'appui sur « Lancer le test complet » et le premier
// sous-test, et c'est le seul endroit possible : c'est le goulot par lequel
// passent AUSSI BIEN une première passation que la reprise d'un test
// interrompu. Le poser plus tôt (à l'inscription) ferait donner une estimation
// de QI à quelqu'un qui n'a pas encore vu à quoi ressemble le test ; le poser
// plus tard, ce serait après un résultat.
//
// L'EMBRANCHEMENT EST LA RAISON D'ÊTRE DE L'ÉCRAN. Qui a passé un test chez un
// psychiatre ou un psychologue possède une MESURE : on lui demande l'âge et le
// score de l'époque, et on ne lui demande pas d'estimer — il répondrait avec le
// chiffre qu'il a lu. Qui n'a passé qu'un test en ligne, ou aucun, n'a qu'une
// CROYANCE : c'est elle qu'on recueille, et c'est le seul moment où elle est
// encore intacte.
//
// TROIS RÈGLES TENUES PAR CET ÉCRAN, chacune vérifiée par un test :
//
// · LE VERROU ANTI-SAUT. La question obligatoire n'a aucune valeur par défaut
//   et le bouton reste inerte tant qu'elle n'a pas été touchée. Une valeur
//   pré-cochée partirait comme une réponse que personne n'a donnée.
// · RIEN N'EST ÉCRIT AVANT LA FIN DE LA BRANCHE. Fermer l'écran en cours de
//   route laisse la question ENTIÈRE — elle se reposera au prochain lancement,
//   et le test ne démarre pas. Un demi-questionnaire enregistré serait pire
//   qu'aucun : la question ne reviendrait plus, et sa moitié manquante serait
//   perdue pour toujours (l'écriture est unique).
// · L'ÉCHEC D'ÉCRITURE NE BLOQUE PAS LE TEST. Le produit, c'est la batterie ;
//   ce questionnaire l'accompagne. Si le stockage échoue, on lance quand même
//   le test et la question reste ouverte pour la fois suivante.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/kepler_colors.dart';
import '../../../../core/widgets/kepler_button.dart';
import '../../../../core/widgets/kepler_card.dart';
import '../../../../core/widgets/kepler_scaffold.dart';
import '../../../waiting_event/reveals/data/self_estimate_store.dart';
import '../../data/pretest_store.dart';
import '../../domain/models/pretest_answers.dart';

/// Les écrans, dans l'ordre où on peut les rencontrer. `passe` et `estimation`
/// sont EXCLUSIFS l'un de l'autre — voir l'en-tête de fichier.
enum _Etape { choix, passe, estimation }

class PretestQuestionnairePage extends StatefulWidget {
  const PretestQuestionnairePage({super.key, this.store = const PretestStore()});

  final PretestStore store;

  @override
  State<PretestQuestionnairePage> createState() =>
      _PretestQuestionnairePageState();
}

class _PretestQuestionnairePageState extends State<PretestQuestionnairePage> {
  final PretestDraft _draft = PretestDraft();

  _Etape _etape = _Etape.choix;

  /// Valeur de départ de l'échelle d'auto-estimation. Elle n'est PAS une
  /// réponse tant que `_estimationTouchee` est faux — c'est le même verrou
  /// anti-saut que la question obligatoire.
  int _estimation = 100;
  bool _estimationTouchee = false;

  final TextEditingController _ageCtrl = TextEditingController();
  final TextEditingController _scoreCtrl = TextEditingController();

  /// Verrou de ré-entrance. L'écriture ouvre une box Hive chiffrée — plusieurs
  /// centaines de millisecondes au premier accès — pendant lesquelles le bouton
  /// reste tactile. Sans ce verrou, un second appui déclenche un second
  /// `_terminer` dont le `pop()` retire la route SUIVANTE : l'écran de
  /// lancement disparaîtrait de la pile sous le test qui démarre.
  bool _enCours = false;

  @override
  void dispose() {
    _ageCtrl.dispose();
    _scoreCtrl.dispose();
    super.dispose();
  }

  // ─── Navigation interne ────────────────────────────────────────────────────

  void _choisir(PriorIqTest choix) => setState(() => _draft.priorTest = choix);

  void _apresLeChoix() {
    final choix = _draft.priorTest;
    if (choix == null) return;
    setState(() => _etape =
        choix.reportsScore ? _Etape.passe : _Etape.estimation);
  }

  void _revenirAuChoix() => setState(() => _etape = _Etape.choix);

  /// Écrit tout, puis rend la main. [estimation] n'est lu que sur la branche
  /// qui a posé la question ; `null` y vaut refus explicite.
  Future<void> _terminer({bool askedEstimate = false, int? estimation}) async {
    if (_enCours) return;
    final answers = _draft.build();
    if (answers == null) return;
    setState(() => _enCours = true);

    // Le résultat de l'écriture n'est délibérément PAS propagé : le test doit
    // démarrer dans tous les cas (voir l'en-tête). Un échec laisse simplement
    // la question ouverte pour la prochaine fois.
    await widget.store.record(
      answers,
      askedEstimate: askedEstimate,
      estimate: estimation,
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  // ─── Saisie ────────────────────────────────────────────────────────────────

  /// Un champ vide vaut « question passée » (`null`, aucune erreur affichée).
  /// Un champ REMPLI mais hors bornes vaut erreur : on ne ramène pas
  /// silencieusement une faute de frappe à la borne la plus proche.
  int? _lire(TextEditingController ctrl, bool Function(int?) valide) {
    final v = int.tryParse(ctrl.text.trim());
    return valide(v) ? v : null;
  }

  bool _enErreur(TextEditingController ctrl, bool Function(int?) valide) =>
      ctrl.text.trim().isNotEmpty && !valide(int.tryParse(ctrl.text.trim()));

  void _bouger(int delta) {
    final cible = (_estimation + delta)
        .clamp(SelfEstimateStore.minValue, SelfEstimateStore.maxValue);
    if (cible == _estimation && _estimationTouchee) return;
    setState(() {
      _estimation = cible;
      _estimationTouchee = true;
    });
  }

  // ─── Écrans ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    switch (_etape) {
      case _Etape.choix:
        return _ecranChoix();
      case _Etape.passe:
        return _ecranTestPasse();
      case _Etape.estimation:
        return _ecranEstimation();
    }
  }

  Widget _ecranChoix() {
    final l10n = context.l10n;
    final choisi = _draft.priorTest;

    return KeplerScaffold(
      eyebrow: l10n.preEyebrow,
      title: l10n.preQ1Title,
      bottomBar: _barre(
        principal: KeplerButton(
          label: l10n.commonContinue,
          expand: true,
          // LE verrou anti-saut : sans réponse, il n'existe aucun chemin vers
          // la suite.
          onPressed: _draft.isComplete ? _apresLeChoix : null,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8.h),
          Text(l10n.preQ1Body, style: AppText.of(context).body()),
          SizedBox(height: 24.h),
          for (final option in PriorIqTest.values) ...[
            _OptionTile(
              label: _libelle(context, option),
              selected: choisi == option,
              onTap: () => _choisir(option),
            ),
            SizedBox(height: 8.h),
          ],
          SizedBox(height: 16.h),
          Text(l10n.preLocalNotice,
              style: AppText.of(context)
                  .bodySmall(color: KeplerColors.of(context).textSecondary)),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  Widget _ecranTestPasse() {
    final l10n = context.l10n;

    return KeplerScaffold(
      eyebrow: l10n.prePastEyebrow,
      title: l10n.prePastTitle,
      bottomBar: _barre(
        secondaire: KeplerButton(
          label: l10n.commonBack,
          variant: KeplerButtonVariant.secondary,
          expand: true,
          onPressed: _enCours ? null : _revenirAuChoix,
        ),
        // Toujours actif : les deux champs sont FACULTATIFS, et un bouton
        // inerte devant des champs vides ferait croire le contraire.
        principal: KeplerButton(
          label: l10n.commonContinue,
          expand: true,
          onPressed: _enCours
              ? null
              : () {
                  _draft.ageAtTest =
                      _lire(_ageCtrl, PretestAnswers.isValidAge);
                  _draft.priorScore =
                      _lire(_scoreCtrl, PretestAnswers.isValidScore);
                  _terminer();
                },
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8.h),
          Text(l10n.prePastBody, style: AppText.of(context).body()),
          SizedBox(height: 24.h),
          _ChampNombre(
            label: l10n.prePastAgeLabel,
            controller: _ageCtrl,
            hint: '00',
            suffix: l10n.ctAgeSuffix,
            erreur: _enErreur(_ageCtrl, PretestAnswers.isValidAge)
                ? l10n.prePastAgeError
                : null,
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: 12.h),
          _ChampNombre(
            label: l10n.prePastScoreLabel,
            controller: _scoreCtrl,
            hint: '000',
            erreur: _enErreur(_scoreCtrl, PretestAnswers.isValidScore)
                ? l10n.prePastScoreError
                : null,
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: 16.h),
          Text(l10n.preLocalNotice,
              style: AppText.of(context)
                  .bodySmall(color: KeplerColors.of(context).textSecondary)),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  Widget _ecranEstimation() {
    final l10n = context.l10n;
    final colors = KeplerColors.of(context);

    return KeplerScaffold(
      eyebrow: l10n.preEstimateEyebrow,
      title: l10n.preEstimateTitle,
      bottomBar: SafeArea(
        minimum: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: KeplerButton(
                    label: l10n.commonBack,
                    variant: KeplerButtonVariant.secondary,
                    expand: true,
                    onPressed: _enCours ? null : _revenirAuChoix,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: KeplerButton(
                    label: l10n.preEstimateConfirm,
                    expand: true,
                    onPressed: (_estimationTouchee && !_enCours)
                        ? () => _terminer(
                            askedEstimate: true, estimation: _estimation)
                        : null,
                  ),
                ),
              ],
            ),
            // Écart généreux : en dessous se trouve un refus DÉFINITIF (la
            // question ne sera plus jamais posée). Deux cibles collées, dont
            // l'une est irréversible, se touchent l'une pour l'autre.
            SizedBox(height: 12.h),
            KeplerButton(
              label: l10n.preEstimateDecline,
              variant: KeplerButtonVariant.ghost,
              expand: true,
              onPressed: _enCours
                  ? null
                  : () => _terminer(askedEstimate: true, estimation: null),
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8.h),
          Text(l10n.preEstimateBody, style: AppText.of(context).body()),
          SizedBox(height: 24.h),
          KeplerCard(
            surface: true,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _PasAPas(
                      icone: Icons.remove,
                      etiquette: l10n.preEstimateDecrease,
                      onPressed: () => _bouger(-1),
                    ),
                    Text(
                      '$_estimation',
                      style: AppText.of(context).monoScore(
                        size: 44.sp,
                        color: _estimationTouchee ? null : colors.textTertiary,
                      ),
                    ),
                    _PasAPas(
                      icone: Icons.add,
                      etiquette: l10n.preEstimateIncrease,
                      onPressed: () => _bouger(1),
                    ),
                  ],
                ),
                Slider(
                  value: _estimation.toDouble(),
                  min: SelfEstimateStore.minValue.toDouble(),
                  max: SelfEstimateStore.maxValue.toDouble(),
                  divisions:
                      SelfEstimateStore.maxValue - SelfEstimateStore.minValue,
                  // Sans cela, un lecteur d'écran annonce la POSITION du
                  // curseur en pourcentage (« 44 % ») — un nombre qui ne veut
                  // rien dire ici.
                  label: '$_estimation',
                  semanticFormatterCallback: (v) => '${v.round()}',
                  activeColor: colors.primary,
                  inactiveColor: colors.border,
                  onChanged: (v) => setState(() {
                    _estimation = v.round();
                    _estimationTouchee = true;
                  }),
                ),
                Text(
                  _estimationTouchee
                      ? l10n.preEstimateAverage
                      : l10n.preEstimateHint,
                  style:
                      AppText.of(context).bodySmall(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Text(l10n.preLocalNotice,
              style: AppText.of(context).bodySmall(color: colors.textSecondary)),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  String _libelle(BuildContext context, PriorIqTest option) {
    switch (option) {
      case PriorIqTest.professional:
        return context.l10n.preQ1Professional;
      case PriorIqTest.online:
        return context.l10n.preQ1Online;
      case PriorIqTest.never:
        return context.l10n.preQ1Never;
    }
  }

  /// Les deux boutons se partagent la largeur à parts égales plutôt que de
  /// prendre leur taille naturelle : « Précédent » et « Fortfahren » n'ont pas
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

/// Un champ numérique FACULTATIF. Le vide y est une réponse légitime : aucune
/// erreur ne s'affiche tant qu'on n'a rien tapé.
class _ChampNombre extends StatelessWidget {
  const _ChampNombre({
    required this.label,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.suffix,
    this.erreur,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final String? suffix;
  final String? erreur;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = KeplerColors.of(context);
    return KeplerCard(
      surface: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.of(context).monoLabel(color: colors.primary)),
          SizedBox(height: 12.h),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppText.of(context).monoScore(size: 22.sp),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppText.of(context).monoScore(
                  color: Theme.of(context).colorScheme.outline, size: 22.sp),
              suffixText: suffix,
              suffixStyle: AppText.of(context)
                  .monoLabel(color: Theme.of(context).colorScheme.outline),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6.r),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6.r),
                borderSide:
                    BorderSide(color: Colors.black.withValues(alpha: 0.07)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6.r),
                borderSide: BorderSide(color: colors.primary, width: 2),
              ),
            ),
            onChanged: onChanged,
          ),
          if (erreur != null)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(erreur!,
                  style: AppText.of(context).bodySmall(color: colors.error)),
            ),
        ],
      ),
    );
  }
}

class _PasAPas extends StatelessWidget {
  const _PasAPas({
    required this.icone,
    required this.etiquette,
    required this.onPressed,
  });

  final IconData icone;
  final String etiquette;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onPressed,
        tooltip: etiquette,
        icon: Icon(icone, size: 22.sp),
        color: KeplerColors.of(context).primary,
      );
}
