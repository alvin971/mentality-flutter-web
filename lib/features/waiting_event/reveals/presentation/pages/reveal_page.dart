// Les sept révélations — le cadeau quotidien de l'événement.
//
// L'utilisateur ne fait RIEN ici : il a passé 90 minutes de bilan, et chaque
// jour lui en rend un morceau. C'est pour cela que cet écran n'a ni bouton de
// réponse, ni score à calculer — il lit `RevealData` et le met en forme.
//
// Un seul écran pour sept révélations, parce qu'elles n'ont que trois formes :
// un indice (J1 à J5), la comparaison des cinq indices entre eux (J6), et le
// QI global confronté à l'auto-estimation du J1 (J8). Le J7 n'en a aucune —
// c'est le jour vedette, rien ne doit lui faire concurrence.
//
// Règles de formulation tenues ici (plan produit §9) :
//   · le NOMBRE et son intervalle de confiance, jamais un pourcentage inventé ;
//   · jamais le mot « diagnostic » — l'avertissement d'orientation est repris
//     tel quel de l'écran de résultats ;
//   · un indice bas n'est pas un verdict : la marge d'erreur est dite, pas
//     sous-entendue.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/l10n/l10n_ext.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/kepler_colors.dart';
import '../../../../../core/widgets/kepler_button.dart';
import '../../../../../core/widgets/kepler_card.dart';
import '../../../../../core/widgets/kepler_scaffold.dart';
import '../../../../scoring/data/composite_score_tables.dart';
import '../../../_shared/domain/models/event_day.dart';
import '../../data/self_estimate_store.dart';
import '../../domain/models/reveal_data.dart';

class RevealPage extends StatelessWidget {
  const RevealPage({
    super.key,
    required this.kind,
    required this.data,
    required this.ctaLabel,
    this.selfEstimate = SelfEstimate.absent,
  });

  final RevealKind kind;

  /// `null` quand aucun bilan n'est rattaché au passe courant. L'écran le dit
  /// alors franchement plutôt que d'afficher des zéros.
  final RevealData? data;

  /// Libellé du bouton de sortie, décidé par l'appelant : « Continuer » quand
  /// une activité suit, « Revenir au programme » quand la révélation est tout
  /// ce que la journée avait à offrir.
  final String ctaLabel;

  /// L'auto-estimation du jour 1, pour la seule révélation qui la confronte au
  /// réel (le QI global du jour 8).
  final SelfEstimate selfEstimate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profil = data;

    return KeplerScaffold(
      eyebrow: l10n.weRvEyebrow,
      title: _titre(l10n),
      bottomBar: SafeArea(
        minimum: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
        // Sort avec `true` : c'est ce qui distingue « j'ai lu » d'un retour
        // système. L'appelant n'enchaîne la suite de la journée que sur cette
        // sortie-là.
        child: KeplerButton(
          label: ctaLabel,
          expand: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ),
      child: profil == null
          ? _Indisponible(
              titre: l10n.weRvUnavailableTitle,
              corps: l10n.weRvUnavailableBody,
            )
          : _corps(context, profil),
    );
  }

  String _titre(AppLocalizations l10n) => switch (kind) {
        RevealKind.vci => l10n.ctIndexVci,
        RevealKind.vsi => l10n.ctIndexVsi,
        RevealKind.fri => l10n.ctIndexFri,
        RevealKind.wmi => l10n.ctIndexWmi,
        RevealKind.psi => l10n.ctIndexPsi,
        RevealKind.strengths => l10n.weRvStrengthsTitle,
        RevealKind.fullIq => l10n.weRvFullIqLabel,
      };

  Widget _corps(BuildContext context, RevealData profil) {
    final l10n = context.l10n;

    if (kind == RevealKind.strengths) return _ForcesEtVigilance(data: profil);
    if (kind == RevealKind.fullIq) {
      return _QiGlobal(data: profil, selfEstimate: selfEstimate);
    }

    final index = RevealData.indexFor(kind)!;
    final score = profil.scoreOf(index);
    // Un sous-test non passé laisse un indice sans valeur. On le dit : le
    // deviner à partir des autres serait un chiffre inventé.
    if (score == null) {
      return _Indisponible(
        titre: l10n.weRvMissingTitle,
        corps: l10n.weRvMissingBody,
      );
    }
    return _RevelationIndice(index: index, score: score);
  }
}

// ─── Un indice (J1 à J5) ─────────────────────────────────────────────────────

class _RevelationIndice extends StatelessWidget {
  const _RevelationIndice({required this.index, required this.score});

  final CognitiveIndex index;
  final int score;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        // Le nom de l'indice est porté par la CARTE, pas seulement par le
        // titre de l'AppBar : celui-ci tient sur une ligne et s'ellipse, ce
        // qui suffit à faire disparaître « Verarbeitungsgeschwindigkeit ».
        // Un nombre sans le nom de ce qu'il mesure ne révèle rien.
        _CarteScore(
          code: index.code,
          score: score,
          etiquette: nomIndice(l10n, index),
        ),
        SizedBox(height: 20.h),
        Text(_explication(l10n), style: AppText.of(context).body()),
        SizedBox(height: 20.h),
        const _Prudence(),
      ],
    );
  }

  String _explication(AppLocalizations l10n) => switch (index) {
        CognitiveIndex.vci => l10n.weRvVciBody,
        CognitiveIndex.vsi => l10n.weRvVsiBody,
        CognitiveIndex.fri => l10n.weRvFriBody,
        CognitiveIndex.wmi => l10n.weRvWmiBody,
        CognitiveIndex.psi => l10n.weRvPsiBody,
      };
}

// ─── Forces et points de vigilance (J6) ──────────────────────────────────────

class _ForcesEtVigilance extends StatelessWidget {
  const _ForcesEtVigilance({required this.data});

  final RevealData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = KeplerColors.of(context);
    final forces = data.strengths;
    final vigilance = data.weaknesses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        Text(l10n.weRvStrengthsIntro, style: AppText.of(context).body()),
        SizedBox(height: 20.h),
        KeplerCard(
          surface: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.isHomogeneousProfile
                    ? l10n.ctProfileHomogeneous
                    : l10n.ctProfileHeterogeneous,
                style: AppText.of(context).bodyStrong(),
              ),
              SizedBox(height: 6.h),
              Text(
                l10n.ctMaxDiscrepancy(data.maxIndexDiscrepancy),
                style: AppText.of(context).monoLabel(color: colors.textTertiary),
              ),
              if (forces.isEmpty && vigilance.isEmpty) ...[
                SizedBox(height: 14.h),
                Text(l10n.weRvStrengthsNone,
                    style: AppText.of(context).bodySmall()),
              ],
              if (forces.isNotEmpty) ...[
                SizedBox(height: 16.h),
                Text(l10n.ctRelativeStrengths,
                    style: AppText.of(context).bodyStrong(color: colors.success)),
                SizedBox(height: 8.h),
                _Jetons(indices: forces, teinte: colors.success),
              ],
              if (vigilance.isNotEmpty) ...[
                SizedBox(height: 16.h),
                Text(l10n.ctVigilancePoints,
                    style: AppText.of(context).bodyStrong(color: colors.warning)),
                SizedBox(height: 8.h),
                _Jetons(indices: vigilance, teinte: colors.warning),
              ],
            ],
          ),
        ),
        SizedBox(height: 20.h),
        const _Prudence(),
      ],
    );
  }
}

class _Jetons extends StatelessWidget {
  const _Jetons({required this.indices, required this.teinte});

  final List<CognitiveIndex> indices;
  final Color teinte;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8.w,
        runSpacing: 6.h,
        children: [
          for (final index in indices)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: teinte.withValues(alpha: 0.12),
                border: Border.all(color: teinte.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(nomIndice(context.l10n, index),
                  style: AppText.of(context).monoLabel(color: teinte)),
            ),
        ],
      );
}

// ─── QI global, et l'estimation du jour 1 (J8) ───────────────────────────────

class _QiGlobal extends StatelessWidget {
  const _QiGlobal({required this.data, required this.selfEstimate});

  final RevealData data;
  final SelfEstimate selfEstimate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        _CarteScore(code: 'FSIQ', score: data.fsiq),
        SizedBox(height: 20.h),
        Text(l10n.weRvFullIqBody, style: AppText.of(context).body()),
        SizedBox(height: 20.h),
        _Confrontation(mesure: data.fsiq, estimation: selfEstimate),
        SizedBox(height: 20.h),
        const _Prudence(),
      ],
    );
  }
}

class _Confrontation extends StatelessWidget {
  const _Confrontation({required this.mesure, required this.estimation});

  /// En deçà de cet écart, l'estimation et la mesure sont indissociables :
  /// deux passations du même bilan varient déjà d'autant.
  ///
  /// La comparaison est STRICTE, parce que le texte affiché dit « moins de
  /// 5 points » dans les six langues. Un écart d'exactement 5 est donc
  /// annoncé comme un écart — pas comme une égalité que la phrase
  /// démentirait.
  static const int _tolerance = 5;

  final int mesure;
  final SelfEstimate estimation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = KeplerColors.of(context);
    final valeur = estimation.value;

    return KeplerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.weRvEstimateTitle,
              style: AppText.of(context).monoLabel(color: colors.primary)),
          SizedBox(height: 12.h),
          if (valeur == null)
            Text(l10n.weRvEstimateMissing, style: AppText.of(context).bodySmall())
          else ...[
            Text(l10n.weRvEstimateLine(valeur, mesure),
                style: AppText.of(context).bodyStrong()),
            SizedBox(height: 6.h),
            Text(_verdict(l10n, valeur), style: AppText.of(context).bodySmall()),
          ],
        ],
      ),
    );
  }

  /// Un constat d'écart, et rien d'autre. Dire à quel rang cet écart place
  /// quelqu'un supposerait une distribution que nous n'avons pas encore
  /// mesurée : ce serait un chiffre inventé.
  String _verdict(AppLocalizations l10n, int valeur) {
    final ecart = valeur - mesure;
    if (ecart.abs() < _tolerance) return l10n.weRvEstimateClose;
    return ecart > 0
        ? l10n.weRvEstimateOver(ecart)
        : l10n.weRvEstimateUnder(-ecart);
  }
}

// ─── Briques communes ────────────────────────────────────────────────────────

/// Le nombre, sa bande descriptive, son intervalle de confiance.
class _CarteScore extends StatelessWidget {
  const _CarteScore({required this.code, required this.score, this.etiquette});

  /// Code du barème (`VCI`… `FSIQ`) — il porte la fidélité qui donne
  /// l'intervalle.
  final String code;
  final int score;

  /// Ce que le nombre mesure. `null` pour le QI global, dont le titre de
  /// l'écran suffit (« QI global » tient sur une ligne dans les six langues).
  final String? etiquette;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = KeplerColors.of(context);
    final (bas, haut) = CompositeScoreTables.getConfidenceInterval(code, score);

    return KeplerCard(
      surface: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiquette ?? l10n.weRvScoreLabel,
              style: AppText.of(context).monoLabel(color: colors.primary)),
          SizedBox(height: 8.h),
          Text('$score', style: AppText.of(context).monoScore(size: 44.sp)),
          SizedBox(height: 4.h),
          Text(libelleBande(l10n, RevealBand.of(score)),
              style: AppText.of(context).h3()),
          SizedBox(height: 10.h),
          Text(l10n.weRvCi(bas, haut),
              style: AppText.of(context).monoLabel(color: colors.textTertiary)),
        ],
      ),
    );
  }
}

/// La marge d'erreur et l'orientation, sur toutes les révélations. Ce n'est pas
/// un ornement : un nombre affiché seul se lit comme un verdict.
class _Prudence extends StatelessWidget {
  const _Prudence();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = KeplerColors.of(context);
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.weRvCaveat,
              style: AppText.of(context).bodySmall(color: colors.textSecondary)),
          SizedBox(height: 8.h),
          Text(l10n.ctIndicativeDisclaimer,
              style: AppText.of(context).bodySmall(color: colors.textSecondary)),
        ],
      ),
    );
  }
}

/// Ce qu'on affiche quand il n'y a rien à révéler — sans chiffre de
/// remplacement.
class _Indisponible extends StatelessWidget {
  const _Indisponible({required this.titre, required this.corps});

  final String titre;
  final String corps;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 24.h),
          Text(titre, style: AppText.of(context).h2()),
          SizedBox(height: 12.h),
          Text(corps, style: AppText.of(context).body()),
        ],
      );
}

/// Le nom d'un indice, dans la langue de l'écran. Les mêmes libellés que
/// l'écran de résultats : un indice ne change pas de nom selon l'endroit où on
/// le lit.
String nomIndice(AppLocalizations l10n, CognitiveIndex index) =>
    switch (index) {
      CognitiveIndex.vci => l10n.ctIndexVci,
      CognitiveIndex.vsi => l10n.ctIndexVsi,
      CognitiveIndex.fri => l10n.ctIndexFri,
      CognitiveIndex.wmi => l10n.ctIndexWmi,
      CognitiveIndex.psi => l10n.ctIndexPsi,
    };

/// Le libellé d'une bande, pris aux clés du moteur de notation — mêmes mots
/// que partout ailleurs dans l'app, mais résolus sur la langue de l'ÉCRAN.
String libelleBande(AppLocalizations l10n, RevealBand bande) => switch (bande) {
      RevealBand.verySuperior => l10n.scoringClassificationVerySuperior,
      RevealBand.superior => l10n.scoringClassificationSuperior,
      RevealBand.highAverage => l10n.scoringClassificationHighAverage,
      RevealBand.average => l10n.scoringClassificationAverage,
      RevealBand.lowAverage => l10n.scoringClassificationLowAverage,
      RevealBand.borderline => l10n.scoringClassificationBorderline,
      RevealBand.extremelyLow => l10n.scoringClassificationExtremelyLow,
    };
