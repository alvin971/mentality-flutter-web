// lib/features/privacy/presentation/pages/privacy_consent_page.dart
//
// L'ÉCRAN DE RETRAIT DU CONSENTEMENT (RGPD art. 7-3).
//
// Pourquoi il existe. Les textes de l'application promettaient déjà le
// retrait — « Vous pouvez retirer votre consentement à tout moment depuis les
// paramètres de l'application » (clé `oralWithdrawConsentNote`) — et la
// politique de confidentialité du site le promet aussi. Or
// `ConsentService.withdraw()` n'avait AUCUN appelant : la promesse était
// affichée, le geste n'existait nulle part. L'art. 7-3 exige qu'il soit aussi
// simple de retirer que de donner ; il l'était infiniment moins, puisqu'il
// était impossible.
//
// Le parcours, de bout en bout : accueil → carte « Confidentialité et
// consentement » → cet écran → bouton « Retirer mon consentement » →
// confirmation qui dit ce que le retrait change → retrait effectif.
//
// Ce que l'écran s'interdit :
//   · promettre l'effacement de ce qui est déjà parti. Les enregistrements
//     envoyés sont anonymes : sans le passe, personne ne peut dire lesquels
//     appartiennent à qui. Le dire franchement vaut mieux qu'un bouton
//     « tout effacer » qui n'effacerait rien ;
//   · re-consentir d'un clic. Le retrait se lève par l'écran de consentement
//     de l'épreuve orale, face au texte — pas par une bascule posée ici.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/consent/consent_record.dart';
import '../../../../core/consent/consent_service.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/kepler_colors.dart';
import '../../../../core/widgets/kepler_button.dart';
import '../../../../core/widgets/kepler_card.dart';
import '../../../../core/widgets/kepler_scaffold.dart';

/// Ce que l'écran a besoin de savoir, relu à chaque affichage.
class _EtatConsentement {
  const _EtatConsentement({
    required this.record,
    required this.actif,
    required this.retireLe,
  });

  /// L'enregistrement persisté, ou `null` s'il n'y en a aucun.
  final ConsentRecord? record;

  /// `true` si le micro est réellement autorisé aujourd'hui.
  final bool actif;

  /// Date du retrait explicite encore en vigueur, ou `null`.
  final DateTime? retireLe;
}

class PrivacyConsentPage extends StatefulWidget {
  const PrivacyConsentPage({super.key});

  @override
  State<PrivacyConsentPage> createState() => _PrivacyConsentPageState();
}

class _PrivacyConsentPageState extends State<PrivacyConsentPage> {
  Future<_EtatConsentement>? _etat;

  /// Passe à `true` après un retrait effectué DEPUIS cet écran, pour afficher
  /// la confirmation sans dépendre d'un SnackBar qui disparaît.
  bool _retraitVientDEtreFait = false;

  @override
  void initState() {
    super.initState();
    _etat = _lire();
  }

  Future<_EtatConsentement> _lire() async {
    final service = ConsentService.instance;
    final record = await service.load();
    return _EtatConsentement(
      record: record,
      actif: await service.hasValidConsent(),
      retireLe: await service.withdrawnAt(),
    );
  }

  void _relire() {
    if (!mounted) return;
    // Corps de bloc OBLIGATOIRE : `setState(() => _etat = _lire())` renvoie la
    // Future de l'affectation, et Flutter lève alors « setState() callback
    // argument returned a Future ». La flèche est un piège silencieux dès que
    // l'on range une Future dans l'état.
    final futur = _lire();
    setState(() {
      _etat = futur;
    });
  }

  /// Retrait confirmé. La confirmation dit ce qui change AVANT le geste : un
  /// retrait qui surprendrait la personne ne serait pas plus éclairé qu'un
  /// consentement arraché.
  Future<void> _confirmerRetrait() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.privacyWithdrawDialogTitle),
        content: SingleChildScrollView(
          child: Text(ctx.l10n.privacyWithdrawDialogBody),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.privacyWithdrawConfirm),
          ),
        ],
      ),
    );
    if (confirme != true) return;

    await ConsentService.instance.withdraw();
    if (!mounted) return;
    _retraitVientDEtreFait = true;
    _relire();
  }

  @override
  Widget build(BuildContext context) {
    final couleurs = KeplerColors.of(context);
    return KeplerScaffold(
      eyebrow: context.l10n.privacyEyebrow,
      title: context.l10n.privacyTitle,
      child: FutureBuilder<_EtatConsentement>(
        future: _etat,
        builder: (context, snap) {
          if (!snap.hasData) {
            return Padding(
              padding: EdgeInsets.only(top: 40.h),
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          final etat = snap.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.h),
              Text(context.l10n.privacyIntro,
                  style: AppText.of(context).body()),
              SizedBox(height: 24.h),
              _Etat(etat: etat, retraitFait: _retraitVientDEtreFait),
              SizedBox(height: 20.h),
              // Le bouton reste OFFERT tant qu'un consentement vaut, et
              // disparaît une fois le retrait acquis : proposer de retirer ce
              // qui est déjà retiré ne ferait que semer le doute.
              if (etat.actif)
                KeplerButton(
                  label: context.l10n.privacyWithdrawAction,
                  expand: true,
                  onPressed: _confirmerRetrait,
                ),
              SizedBox(height: 28.h),
              KeplerCard(
                surface: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.privacyErasureTitle,
                        style: AppText.of(context).bodyStrong()),
                    SizedBox(height: 6.h),
                    Text(context.l10n.privacyErasureBody,
                        style: AppText.of(context)
                            .bodySmall(color: couleurs.textSecondary)),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
            ],
          );
        },
      ),
    );
  }
}

/// Le bloc « état actuel » : ce qui vaut aujourd'hui, et sur quel texte.
class _Etat extends StatelessWidget {
  const _Etat({required this.etat, required this.retraitFait});

  final _EtatConsentement etat;
  final bool retraitFait;

  /// Date lisible sans dépendre d'`intl` : l'écran n'affiche qu'un jour.
  static String _jour(DateTime d) {
    final l = d.toLocal();
    String deuxChiffres(int n) => n.toString().padLeft(2, '0');
    return '${deuxChiffres(l.day)}/${deuxChiffres(l.month)}/${l.year}';
  }

  @override
  Widget build(BuildContext context) {
    final couleurs = KeplerColors.of(context);
    final record = etat.record;

    final lignes = <String>[];
    if (etat.actif && record != null) {
      lignes.add(record.source == ConsentSource.token
          ? context.l10n.privacySourceToken
          : context.l10n.privacySourceInApp);
      lignes.add(record.commercialReuse
          ? context.l10n.privacyReuseYes
          : context.l10n.privacyReuseNo);
      lignes.add(context.l10n
          .privacyVersionLine(record.version, _jour(record.grantedAt)));
    } else if (etat.retireLe != null) {
      lignes.add(context.l10n.privacyWithdrawnOnLine(_jour(etat.retireLe!)));
    }

    final String resume;
    if (retraitFait) {
      resume = context.l10n.privacyWithdrawDone;
    } else if (etat.actif) {
      resume = context.l10n.privacyStatusActive;
    } else if (etat.retireLe != null) {
      resume = context.l10n.privacyStatusWithdrawn;
    } else {
      resume = context.l10n.privacyStatusNone;
    }

    return KeplerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.privacyStatusEyebrow,
              style: AppText.of(context).monoLabel(color: couleurs.primary)),
          SizedBox(height: 10.h),
          Text(resume, style: AppText.of(context).bodyStrong()),
          for (final ligne in lignes) ...[
            SizedBox(height: 6.h),
            Text(ligne,
                style:
                    AppText.of(context).bodySmall(color: couleurs.textSecondary)),
          ],
        ],
      ),
    );
  }
}
