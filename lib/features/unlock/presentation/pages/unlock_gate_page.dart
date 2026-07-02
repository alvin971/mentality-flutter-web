import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/kepler_colors.dart';
import '../../../../core/widgets/kepler_button.dart';
import '../../../../core/widgets/kepler_card.dart';
import '../../../../core/widgets/kepler_scaffold.dart';
import '../../data/unlock_service.dart';

/// Écran des paliers de déblocage du résultat, affiché à la FIN du test
/// complet à la place des résultats tant que `stage < 4`.
///
/// Les paliers sont révélés SÉQUENTIELLEMENT (jamais tous d'un coup) :
///   1. Inviter 3 amis via le lien lié au token du parrain.
///   2. (révélé quand les 3 invitations sont parties) Attendre que les
///      filleuls TERMINENT leur test — statut par filleul + polling.
///   3. Suivre le compte Instagram : pseudo + « vérification en cours »
///      (le délai est appliqué côté serveur, autorité worker).
///   4. Débloqué → [onUnlocked] est appelé (affiche le vrai résultat).
class UnlockGatePage extends StatefulWidget {
  const UnlockGatePage({super.key, required this.onUnlocked});

  /// Appelé quand le serveur confirme le déblocage (stage 4).
  final VoidCallback onUnlocked;

  @override
  State<UnlockGatePage> createState() => _UnlockGatePageState();
}

class _UnlockGatePageState extends State<UnlockGatePage> {
  UnlockProgress? _progress;
  bool _loading = true;
  bool _error = false;
  bool _copied = false;
  Timer? _pollTimer;
  final _instaController = TextEditingController();
  bool _submittingInsta = false;

  @override
  void initState() {
    super.initState();
    _load(init: true);
    // Polling léger : les validations des filleuls et le délai Instagram
    // avancent côté serveur pendant que la page est ouverte.
    _pollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _load(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _instaController.dispose();
    super.dispose();
  }

  Future<void> _load({bool init = false}) async {
    final p = init
        ? await UnlockService.instance.initProgress()
        : await UnlockService.instance.getProgress();
    if (!mounted) return;
    if (p == null) {
      setState(() {
        _loading = false;
        _error = _progress == null;
      });
      return;
    }
    setState(() {
      _progress = p;
      _loading = false;
      _error = false;
    });
    if (p.unlocked) widget.onUnlocked();
  }

  Future<void> _copyLink() async {
    final link = _progress?.inviteLink;
    if (link == null) return;
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _submitInstagram() async {
    final handle = _instaController.text.trim();
    if (handle.isEmpty || _submittingInsta) return;
    setState(() => _submittingInsta = true);
    final p = await UnlockService.instance.submitInstagram(handle);
    if (!mounted) return;
    setState(() {
      _submittingInsta = false;
      if (p != null) _progress = p;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return KeplerScaffold(
      title: l10n.ugTitle,
      eyebrow: l10n.ugEyebrow,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: _loading
          ? Padding(
              padding: EdgeInsets.only(top: 80.h),
              child: const Center(child: CircularProgressIndicator()),
            )
          : _error
              ? _buildError(l10n)
              : _buildSteps(l10n),
    );
  }

  Widget _buildError(dynamic l10n) {
    return Column(
      children: [
        SizedBox(height: 40.h),
        Text(l10n.ugErrorBody,
            style: AppText.body(), textAlign: TextAlign.center),
        SizedBox(height: 20.h),
        KeplerButton(
          label: l10n.ugRetry,
          onPressed: () {
            setState(() => _loading = true);
            _load(init: true);
          },
        ),
      ],
    );
  }

  Widget _buildSteps(dynamic l10n) {
    final p = _progress!;
    // Palier 2 révélé seulement quand les 3 invités ont rejoint mais que
    // tous n'ont pas terminé ; palier 3 seulement quand le parrainage est
    // acquis — jamais tous les paliers affichés d'un coup.
    final referralsDone = p.completedReferrals >= p.requiredReferrals;
    final showWaiting = !referralsDone && p.invitedReferrals >= p.requiredReferrals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Le test est gratuit : condition affichée clairement dès le départ.
        Text(l10n.ugFreeNotice, style: AppText.body()),
        SizedBox(height: 20.h),
        if (!referralsDone && !showWaiting) _buildInviteStep(l10n, p),
        if (showWaiting) _buildWaitingStep(l10n, p),
        if (referralsDone && p.stage >= 3) _buildInstagramStep(l10n, p),
        SizedBox(height: 24.h),
        Center(
          child: KeplerButton(
            label: l10n.ugRefresh,
            variant: KeplerButtonVariant.ghost,
            icon: Icons.refresh,
            onPressed: () => _load(),
          ),
        ),
      ],
    );
  }

  /// Palier 1 — inviter 3 amis via le lien lié au token.
  Widget _buildInviteStep(dynamic l10n, UnlockProgress p) {
    return KeplerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader('1', l10n.ugStep1Title),
          SizedBox(height: 10.h),
          Text(l10n.ugStep1Body, style: AppText.bodySmall()),
          SizedBox(height: 16.h),
          KeplerCard(
            surface: true,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            child: SelectableText(
              p.inviteLink,
              style: AppText.bodySmall().copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          SizedBox(height: 12.h),
          KeplerButton(
            label: _copied ? l10n.ugCopied : l10n.ugCopyLink,
            icon: _copied ? Icons.check : Icons.copy,
            expand: true,
            onPressed: _copyLink,
          ),
          SizedBox(height: 14.h),
          _progressCounter(
            l10n.ugInviteCounter(p.invitedReferrals, p.requiredReferrals),
            p.invitedReferrals / p.requiredReferrals,
          ),
        ],
      ),
    );
  }

  /// Palier 2 — attendre que les filleuls terminent leur test.
  Widget _buildWaitingStep(dynamic l10n, UnlockProgress p) {
    return KeplerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader('2', l10n.ugStep2Title),
          SizedBox(height: 10.h),
          Text(l10n.ugStep2Body, style: AppText.bodySmall()),
          SizedBox(height: 16.h),
          for (var i = 0; i < p.invitedReferrals; i++)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Icon(
                    i < p.completedReferrals
                        ? Icons.check_circle
                        : Icons.hourglass_empty,
                    size: 18.sp,
                    color: i < p.completedReferrals
                        ? AppColors.success
                        : KeplerColors.of(context).textSecondary,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    i < p.completedReferrals
                        ? l10n.ugFriendDone(i + 1)
                        : l10n.ugFriendPending(i + 1),
                    style: AppText.bodySmall(),
                  ),
                ],
              ),
            ),
          SizedBox(height: 8.h),
          _progressCounter(
            l10n.ugWaitingCounter(p.completedReferrals, p.requiredReferrals),
            p.completedReferrals / p.requiredReferrals,
          ),
        ],
      ),
    );
  }

  /// Palier 3 — suivre le compte Instagram (déclaratif + délai serveur).
  Widget _buildInstagramStep(dynamic l10n, UnlockProgress p) {
    if (p.instagramSubmitted) {
      return KeplerCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _stepHeader('3', l10n.ugStep3Title),
            SizedBox(height: 10.h),
            Row(
              children: [
                SizedBox(
                  width: 16.sp,
                  height: 16.sp,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(l10n.ugInstaPending,
                      style: AppText.bodySmall()),
                ),
              ],
            ),
          ],
        ),
      );
    }
    return KeplerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader('3', l10n.ugStep3Title),
          SizedBox(height: 10.h),
          Text(l10n.ugStep3Body(AppConstants.instagramHandle),
              style: AppText.bodySmall()),
          SizedBox(height: 14.h),
          KeplerButton(
            label: l10n.ugFollowButton(AppConstants.instagramHandle),
            icon: Icons.open_in_new,
            variant: KeplerButtonVariant.secondary,
            expand: true,
            onPressed: () => launchUrl(
              Uri.parse(AppConstants.instagramUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
          SizedBox(height: 14.h),
          TextField(
            controller: _instaController,
            decoration: InputDecoration(
              labelText: l10n.ugInstaFieldLabel,
              prefixText: '@',
              border: const OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 12.h),
          KeplerButton(
            label: l10n.ugInstaSubmit,
            expand: true,
            onPressed: _submittingInsta ? null : _submitInstagram,
          ),
        ],
      ),
    );
  }

  Widget _stepHeader(String number, String title) {
    final colors = KeplerColors.of(context);
    return Row(
      children: [
        Container(
          width: 26.w,
          height: 26.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: AppText.bodySmall().copyWith(
              color: colors.background,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(title,
              style: AppText.h3()
                  .copyWith(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _progressCounter(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.bodySmall()),
        SizedBox(height: 6.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 8.h,
          ),
        ),
      ],
    );
  }
}
