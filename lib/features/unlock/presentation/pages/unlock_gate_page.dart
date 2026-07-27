import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/kepler_colors.dart';
import '../../../../core/widgets/kepler_button.dart';
import '../../../../core/widgets/kepler_card.dart';
import '../../../../core/widgets/kepler_scaffold.dart';
import '../../../waiting_event/day_hub/presentation/pages/day_hub_page.dart';
import '../../data/unlock_service.dart';

/// Écran des paliers de déblocage du résultat, affiché à la FIN du test
/// complet à la place des résultats tant que `stage < 4`.
///
/// Les paliers sont révélés SÉQUENTIELLEMENT (jamais tous d'un coup) :
///   1. Inviter 3 amis via le lien lié au token du parrain.
///   2. (révélé quand les 3 invitations sont parties) Attendre que les
///      filleuls TERMINENT leur test — statut par filleul + polling.
///   3. Attendre le délai de publication — RIEN n'est demandé à l'utilisateur
///      et rien n'est vérifié à son sujet ; le serveur seul décide de
///      l'échéance (autorité worker).
///   4. Débloqué → [onUnlocked] est appelé (affiche le vrai résultat).

/// Granularité d'affichage du compte à rebours.
enum CountdownUnit { zero, minutes, hours, days }

/// Unité et valeur à afficher pour [remaining] : des JOURS au-delà de 48 h, des
/// HEURES en dessous, des MINUTES sous une heure.
///
/// Arrondi AU SUPÉRIEUR partout : on n'annonce jamais moins de temps qu'il n'en
/// reste. Les seuils portent sur les minutes DÉJÀ arrondies, ce qui interdit les
/// affichages absurdes du type « encore 60 minutes ».
({CountdownUnit unit, int value}) countdownParts(Duration remaining) {
  final secs = remaining.inSeconds;
  if (secs <= 0) return (unit: CountdownUnit.zero, value: 0);
  final minutes = (secs / 60).ceil();
  if (minutes > 2880) return (unit: CountdownUnit.days, value: (minutes / 1440).ceil());
  if (minutes >= 60) return (unit: CountdownUnit.hours, value: (minutes / 60).ceil());
  return (unit: CountdownUnit.minutes, value: minutes);
}

/// Bannière affichée quand le serveur tourne avec un délai d'affichage forcé.
///
/// VOLONTAIREMENT non traduite : ce n'est pas un message produit mais le signal
/// d'un défaut de configuration, et il ne doit jamais pouvoir se fondre dans
/// l'interface.
String debugDelayBannerText(int delayMinutes) =>
    'MODE TEST — délai réel : $delayMinutes min';

class UnlockGatePage extends StatefulWidget {
  const UnlockGatePage({super.key, required this.onUnlocked});

  /// Appelé quand le serveur confirme le déblocage (stage 4).
  final VoidCallback onUnlocked;

  @override
  State<UnlockGatePage> createState() => _UnlockGatePageState();
}

class _UnlockGatePageState extends State<UnlockGatePage>
    with WidgetsBindingObserver {
  UnlockProgress? _progress;
  bool _loading = true;
  bool _error = false;
  bool _copied = false;
  Timer? _pollTimer;

  /// Vrai quand le dernier rafraîchissement a échoué alors qu'un état était
  /// déjà affiché : les chiffres à l'écran sont périmés, il faut le dire.
  bool _refreshFailed = false;

  /// Rythme d'AFFICHAGE du compte à rebours. Ne fait aucun appel réseau.
  Timer? _tick;
  Duration _remaining = Duration.zero;

  /// Le compteur local est à zéro mais le serveur n'a pas encore confirmé le
  /// stage 4. C'est le seul état où l'écran annonce la fin de l'attente sans
  /// débloquer — et c'est exactement ce que voit quelqu'un qui a avancé
  /// l'horloge de son téléphone : le serveur, lui, n'a pas bougé.
  bool _awaitingServer = false;
  int _confirmBackoffS = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load(init: true);
    // Polling léger : les validations des filleuls et le délai d'attente
    // avancent côté serveur pendant que la page est ouverte.
    _pollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _load(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Au retour au premier plan, le compteur monotone peut avoir pris du retard
    // (processus suspendu) : on se recale sur le serveur avant de réafficher.
    if (state == AppLifecycleState.resumed) _load();
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
        // Un état est déjà affiché : il est simplement PÉRIMÉ. Le signaler,
        // au lieu de laisser croire que les compteurs sont à jour.
        _refreshFailed = _progress != null;
      });
      return;
    }
    setState(() {
      _progress = p;
      _loading = false;
      _error = false;
      _refreshFailed = false;
    });
    _syncCountdown(p);
    if (p.unlocked) widget.onUnlocked();
  }

  /// Ré-ancre le compte à rebours sur la valeur que vient de donner le serveur.
  void _syncCountdown(UnlockProgress p) {
    _tick?.cancel();
    if (!p.countdownApplicable) {
      _awaitingServer = false;
      return;
    }
    _remaining = p.remainingAt(UnlockService.instance.monotonicNow);
    if (_remaining > Duration.zero) {
      // Le serveur redonne du temps : on quitte l'état « attente de
      // confirmation » et on repart de SA valeur, jamais de la nôtre.
      _awaitingServer = false;
      _confirmBackoffS = 5;
      _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    } else {
      _enterAwaitingServer();
    }
  }

  void _onTick() {
    final p = _progress;
    if (p == null) return;
    final r = p.remainingAt(UnlockService.instance.monotonicNow);
    if (r <= Duration.zero) {
      _tick?.cancel();
      _enterAwaitingServer();
      return;
    }
    setState(() => _remaining = r);
  }

  /// Compteur local épuisé : on ne débloque RIEN, on redemande au serveur.
  ///
  /// [_awaitingServer] n'est levé que d'ici, et n'est baissé que par une
  /// réponse serveur — stage 4 (déblocage) ou secondsRemaining positif
  /// (le ticker repart de la valeur serveur). Le client n'a aucun chemin qui
  /// débloque de lui-même.
  void _enterAwaitingServer() {
    setState(() {
      _remaining = Duration.zero;
      _awaitingServer = true;
    });
    _load();
    _confirmBackoffS = (_confirmBackoffS * 2).clamp(5, 30);
    Timer(Duration(seconds: _confirmBackoffS), () {
      if (mounted && _awaitingServer) _load();
    });
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

  Widget _buildError(AppLocalizations l10n) {
    return Column(
      children: [
        SizedBox(height: 40.h),
        Text(l10n.ugErrorBody,
            style: AppText.of(context).body(), textAlign: TextAlign.center),
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

  Widget _buildSteps(AppLocalizations l10n) {
    final p = _progress!;
    // Palier 2 (attente) révélé dès qu'au moins un filleul a terminé mais que
    // le compte n'est pas atteint ; palier 3 seulement quand le parrainage est
    // acquis — jamais tous les paliers affichés d'un coup.
    final referralsDone = p.completedReferrals >= p.requiredReferrals;
    final showWaiting = !referralsDone && p.completedReferrals >= 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (p.debugDelayOverride) _buildDebugDelayBanner(p),
        // Le test est gratuit : condition affichée clairement dès le départ.
        Text(l10n.ugFreeNotice, style: AppText.of(context).body()),
        SizedBox(height: 10.h),
        // Tout est persisté : l'utilisateur peut quitter et retrouver ses
        // missions, son lien et son résultat (flouté) dans « Mes résultats ».
        Text(
          l10n.ugResultsHubNotice,
          style: AppText.of(context).bodySmall(
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        SizedBox(height: 20.h),
        // Le lien d'invitation reste affiché TANT QUE le palier n'est pas
        // atteint : à 1/3 ou 2/3 c'est précisément le moment où l'utilisateur
        // doit inviter les amis manquants. Le masquer l'enfermait dans un
        // écran d'attente sans issue.
        if (!referralsDone) _buildInviteStep(l10n, p),
        if (showWaiting) ...[
          SizedBox(height: 16.h),
          _buildWaitingStep(l10n, p),
        ],
        // Condition volontairement indépendante de `stage` : le serveur promeut
        // déjà en stage 3 dès que le parrainage est acquis, et se fier au stage
        // créait une impasse (parrainage acquis + stage resté à 1 ⇒ AUCUNE carte
        // affichée, plus aucune action possible). Tant que ce n'est pas
        // débloqué, il y a toujours une action.
        if (referralsDone && !p.unlocked) _buildWaitStep(l10n, p),
        if (_refreshFailed) ...[
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.cloud_off_outlined,
                  size: 16.sp, color: KeplerColors.of(context).warning),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(l10n.ugRefreshFailed,
                    style: AppText.of(context).bodySmall(color: KeplerColors.of(context).warning)),
              ),
            ],
          ),
        ],
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
  Widget _buildInviteStep(AppLocalizations l10n, UnlockProgress p) {
    return KeplerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader('1', l10n.ugStep1Title),
          SizedBox(height: 10.h),
          Text(l10n.ugStep1Body, style: AppText.of(context).bodySmall()),
          SizedBox(height: 16.h),
          KeplerCard(
            surface: true,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            child: SelectableText(
              p.inviteLink,
              style: AppText.of(context).bodySmall().copyWith(
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
            l10n.ugInviteCounter(p.completedReferrals, p.requiredReferrals),
            p.completedReferrals / p.requiredReferrals,
          ),
        ],
      ),
    );
  }

  /// Palier 2 — attendre que les filleuls terminent leur test.
  Widget _buildWaitingStep(AppLocalizations l10n, UnlockProgress p) {
    return KeplerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader('2', l10n.ugStep2Title),
          SizedBox(height: 10.h),
          Text(l10n.ugStep2Body, style: AppText.of(context).bodySmall()),
          SizedBox(height: 16.h),
          for (var i = 0; i < p.requiredReferrals; i++)
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
                    style: AppText.of(context).bodySmall(),
                  ),
                ],
              ),
            ),
          // Pas de second compteur : le palier 1 (toujours affiché tant que le
          // parrainage n'est pas acquis) porte déjà la barre de progression.
        ],
      ),
    );
  }

  /// Palier 3 — le délai de publication court côté serveur.
  ///
  /// AUCUN indicateur d'activité ici : rien n'est en cours de traitement et
  /// personne n'est vérifié. On attend une date, on le dit.
  Widget _buildWaitStep(AppLocalizations l10n, UnlockProgress p) {
    final colors = KeplerColors.of(context);
    return KeplerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader('3', l10n.ugWaitTitle),
          SizedBox(height: 10.h),
          Text(l10n.ugWaitBody(p.displayDelayDays),
              style: AppText.of(context).bodySmall()),
          if (p.countdownApplicable) ...[
            SizedBox(height: 14.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.schedule_outlined, size: 18.sp, color: colors.primary),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    _countdownLabel(l10n),
                    style: AppText.of(context)
                        .bodyStrong(color: colors.primary),
                  ),
                ),
              ],
            ),
          ],
          if (_awaitingServer) ...[
            SizedBox(height: 8.h),
            Text(l10n.ugWaitConfirming,
                style: AppText.of(context)
                    .bodySmall(color: colors.textSecondary)),
          ],
          // Le programme des 8 jours n'a de sens que si le serveur sait dire
          // quel jour on est. Face à un worker antérieur au champ, `dayIndex`
          // est nul et la carte reste exactement ce qu'elle était : pas de
          // bouton qui mène nulle part. Rien ici n'avance le déblocage.
          if (p.dayIndex != null) ...[
            SizedBox(height: 16.h),
            KeplerButton(
              label: l10n.weGateCta,
              icon: Icons.map_outlined,
              expand: true,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => DayHubPage(serverDayIndex: p.dayIndex!),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _countdownLabel(AppLocalizations l10n) {
    final parts = countdownParts(_remaining);
    return switch (parts.unit) {
      CountdownUnit.days => l10n.ugWaitCountdownDays(parts.value),
      CountdownUnit.hours => l10n.ugWaitCountdownHours(parts.value),
      CountdownUnit.minutes => l10n.ugWaitCountdownMinutes(parts.value),
      CountdownUnit.zero => l10n.ugWaitCountdownDone,
    };
  }

  /// Bannière de recette. Affichée à TOUT stage, non traduite, non contournable :
  /// tant que le worker tourne avec DEBUG_DISPLAY_DELAY_DAYS, le délai annoncé
  /// est un mensonge et cela doit se voir.
  Widget _buildDebugDelayBanner(UnlockProgress p) {
    final colors = KeplerColors.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      margin: EdgeInsets.only(bottom: 12.h),
      color: colors.warning.withValues(alpha: 0.15),
      child: Row(
        children: [
          Icon(Icons.bug_report_outlined, size: 16.sp, color: colors.warning),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              debugDelayBannerText(p.delayMinutes),
              style: AppText.of(context).bodySmall(color: colors.warning),
            ),
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
            style: AppText.of(context).bodySmall().copyWith(
              color: colors.background,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(title,
              style: AppText.of(context).h3()
                  .copyWith(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _progressCounter(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.of(context).bodySmall()),
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
