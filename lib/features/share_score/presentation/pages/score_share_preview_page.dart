import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/kepler_colors.dart';
import '../../../../core/widgets/kepler_button.dart';
import '../../../../core/widgets/kepler_scaffold.dart';
import '../../domain/services/score_card_renderer.dart';
import '../widgets/score_share_card.dart';

/// Écran d'aperçu du partage.
///
/// La confirmation est OBLIGATOIRE : l'utilisateur voit l'image exacte qui
/// partira avant que quoi que ce soit ne quitte l'appareil. Déclencher un
/// partage sans cette étape est un motif de rejet en revue de store, et de
/// toute façon personne ne devrait publier son score sans l'avoir vu.
class ScoreSharePreviewPage extends StatefulWidget {
  const ScoreSharePreviewPage({
    super.key,
    required this.iq,
    required this.percentile,
    required this.classification,
    required this.inviteCode,
    required this.inviteLink,
  });

  final int iq;
  final int percentile;
  final String classification;
  final String inviteCode;
  final String inviteLink;

  @override
  State<ScoreSharePreviewPage> createState() => _ScoreSharePreviewPageState();
}

class _ScoreSharePreviewPageState extends State<ScoreSharePreviewPage> {
  final GlobalKey _cardKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final png = await const ScoreCardRenderer().capturePng(_cardKey);
      if (png == null) throw StateError('carte non montée');

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/mental-et-score.png');
      await file.writeAsBytes(png);

      // Le lien part dans le presse-papier AVANT la feuille de partage : sur
      // une story, l'image ne porte pas de lien cliquable, et c'est le sticker
      // « Lien » qui fait le travail. Il faut que le lien soit déjà disponible
      // au moment où l'utilisateur arrive dans Instagram.
      await Clipboard.setData(ClipboardData(text: widget.inviteLink));

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)]),
      );
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.shareLinkCopied)));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.shareError)));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return KeplerScaffold(
      title: l10n.shareTitle,
      eyebrow: l10n.shareEyebrow,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.shareIntro,
              style: AppText.of(context)
                  .bodySmall(color: KeplerColors.of(context).textSecondary)),
          SizedBox(height: 20.h),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              // La carte est TOUJOURS disposée à sa taille logique réelle
              // (360 × 640) ; seule sa peinture est réduite pour tenir dans
              // l'écran. La capture, elle, part de la RepaintBoundary et rend
              // donc bien du 1080 × 1920, quel que soit l'appareil.
              child: FittedBox(
                fit: BoxFit.contain,
                child: RepaintBoundary(
                  key: _cardKey,
                  child: ScoreShareCard(
                    iq: widget.iq,
                    percentile: widget.percentile,
                    classification: widget.classification,
                    inviteCode: widget.inviteCode,
                    scoreLabel: l10n.shareScoreLabel,
                    percentileLabel: l10n.sharePercentile(widget.percentile),
                    codeLabel: l10n.shareCodeLabel,
                    siteLabel: 'mental-et.com',
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          KeplerButton(
            label: l10n.shareConfirm,
            icon: Icons.ios_share,
            expand: true,
            onPressed: _sharing ? null : _share,
          ),
          SizedBox(height: 12.h),
          KeplerButton(
            label: l10n.shareCancel,
            variant: KeplerButtonVariant.ghost,
            expand: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
