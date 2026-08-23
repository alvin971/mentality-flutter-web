import 'dart:async';
// lib/features/data_collection/token_issuance_step.dart
//
// Dernière étape du flow oral : formulaire démographique LARGE (sexe,
// mois/année de naissance, région) → génération d'un token anonyme que
// l'utilisateur doit sauvegarder lui-même (aucune récupération possible).
//
// Voir PLAN_TOKEN_FIN_DE_TEST.md.
//
// TODO(i18n) : les libellés de cet écran sont en dur (FR) pour itérer vite.
// À migrer vers l'ARB (l10n_fragments) une fois la fonction validée.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/token_regions.dart';
import '../../core/l10n/l10n_ext.dart';
import '../../core/services/auth_local_store.dart';
import '../../core/services/token_issuer.dart';
import '../../core/theme/app_colors.dart';
import '../../services/tokeniser_service.dart';
import '../../core/services/results_sync.dart';
import '../../core/theme/kepler_colors.dart';
import '../registration/domain/entities/registration_form.dart' show Sex, SexX;

const List<String> _kMonths = [
  'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
  'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
];

/// Étape finale : démographiques larges + émission du token.
///
/// - Intégrée dans [OralTestFlow] : passer [onIssued] (pas de Scaffold ajouté).
/// - En route de DEV (`/test/token`) : passer `standalone: true` pour un
///   Scaffold autonome permettant de tester l'écran sans refaire tout le test.
class TokenIssuanceStep extends StatefulWidget {
  /// Appelé une fois le token généré + persisté. `null` en mode standalone.
  final void Function(String token)? onIssued;

  /// Si fourni, affiche un lien « J'ai déjà un token » qui déclenche ce callback
  /// (typiquement : naviguer vers l'écran de reconnexion).
  final VoidCallback? onRestore;

  /// Si true, fournit son propre Scaffold (usage page autonome / DEV).
  final bool standalone;

  const TokenIssuanceStep({
    super.key,
    this.onIssued,
    this.onRestore,
    this.standalone = false,
  });

  @override
  State<TokenIssuanceStep> createState() => _TokenIssuanceStepState();
}

class _TokenIssuanceStepState extends State<TokenIssuanceStep> {
  Sex? _sex;
  int? _birthYear;
  int? _birthMonth;
  String? _regionCode;
  String? _issuedToken;
  String? _error;
  bool _busy = false;
  bool _regionAutodetected = false;

  // Le parrainage n'a plus de champ code : le filleul crée son passe sur
  // mental-et.com/inscription?ref=<code> et la liaison est automatique
  // (worker referral POST /link). L'app ne fait que restaurer le token.

  @override
  void initState() {
    super.initState();
    _prefillRegionFromGeo();
  }

  /// Pré-remplit la région via la géo-IP (Cloudflare), corrigeable. No-op si le
  /// worker n'est pas configuré ou si la détection échoue.
  Future<void> _prefillRegionFromGeo() async {
    final code = await TokeniserService.instance.suggestRegion();
    if (!mounted || code == null || _regionCode != null) return;
    if (kTokenRegionCodes.contains(code)) {
      setState(() {
        _regionCode = code;
        _regionAutodetected = true;
      });
    }
  }

  bool get _formComplete =>
      _sex != null &&
      _birthYear != null &&
      _birthMonth != null &&
      _regionCode != null;

  Future<void> _generate() async {
    if (!_formComplete || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final demo = TokenDemographics(
      sexCode: _sex!.code,
      birthYear: _birthYear!,
      birthMonth: _birthMonth!,
      regionCode: _regionCode!,
    );
    try {
      // issue() vérifie déjà la signature (chemin signé) AVANT de retourner ;
      // on ne persiste qu'un token confirmé.
      final token = await TokenIssuer.issue(demo);
      await AuthLocalStore.instance.saveToken(token);
      // Le token n'existe qu'ICI, à la fin du parcours, alors que les mesures
      // sont parties PENDANT — sans token elles ont toutes échoué en silence.
      // On rejoue la file maintenant qu'un en-tête d'authentification existe.
      unawaited(ResultsSync.instance.retryPending());
      if (!mounted) return;
      setState(() => _issuedToken = token);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Échec de génération du token. Réessaie. ($e)');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _finish() {
    final token = _issuedToken;
    if (token != null) {
      widget.onIssued?.call(token);
    }
    if (widget.standalone && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _issuedToken == null ? _buildForm() : _buildResult();
    if (!widget.standalone) return content;
    return Scaffold(
      appBar: AppBar(
        title: const Text('DEV — Token'),
        backgroundColor: AppColors.primary,
        foregroundColor: KeplerColors.of(context).onAccentFill,
      ),
      body: SafeArea(child: content),
    );
  }

  // ─── Formulaire démographique ─────────────────────────────────────────────

  Widget _buildForm() {
    final currentYear = DateTime.now().year;
    final years = [
      for (int y = currentYear - 5; y >= currentYear - 100; y--) y,
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 12.h),
          Icon(Icons.badge_outlined, size: 56.sp, color: KeplerColors.of(context).primary),
          SizedBox(height: 16.h),
          Text(
            'Dernière étape',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text(
            'Quelques informations générales pour situer tes résultats. '
            'Aucune donnée permettant de t’identifier n’est demandée.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          SizedBox(height: 28.h),

          // Sexe
          _label('Sexe'),
          SizedBox(height: 8.h),
          ...Sex.values.map(
            (s) => RadioListTile<Sex>(
              value: s,
              groupValue: _sex,
              onChanged: (v) => setState(() => _sex = v),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              activeColor: AppColors.primary,
              title: Text(s.label(context.l10n), style: TextStyle(fontSize: 14.sp)),
            ),
          ),
          SizedBox(height: 16.h),

          // Mois + année de naissance
          _label('Date de naissance (mois et année uniquement)'),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _birthMonth,
                  isExpanded: true,
                  decoration: _dropdownDecoration('Mois'),
                  items: [
                    for (int m = 1; m <= 12; m++)
                      DropdownMenuItem(value: m, child: Text(_kMonths[m - 1])),
                  ],
                  onChanged: (v) => setState(() => _birthMonth = v),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _birthYear,
                  isExpanded: true,
                  decoration: _dropdownDecoration('Année'),
                  items: [
                    for (final y in years)
                      DropdownMenuItem(value: y, child: Text('$y')),
                  ],
                  onChanged: (v) => setState(() => _birthYear = v),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Région
          _label('Région'),
          SizedBox(height: 8.h),
          DropdownButtonFormField<String>(
            value: _regionCode,
            isExpanded: true,
            decoration: _dropdownDecoration('Sélectionne ta région'),
            items: [
              for (final entry in kTokenRegionLabels.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: (v) => setState(() {
              _regionCode = v;
              _regionAutodetected = false; // l'utilisateur a corrigé
            }),
          ),
          if (_regionAutodetected) ...[
            SizedBox(height: 6.h),
            Row(
              children: [
                Icon(Icons.my_location_outlined,
                    size: 14.sp, color: Theme.of(context).colorScheme.outline),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    'Détectée automatiquement — corrige si besoin.',
                    style: TextStyle(
                        fontSize: 11.sp,
                        color: Theme.of(context).colorScheme.outline,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 32.h),

          ElevatedButton.icon(
            onPressed: _formComplete && !_busy ? _generate : null,
            icon: _busy
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: KeplerColors.of(context).onAccentFill),
                  )
                : const Icon(Icons.vpn_key_outlined),
            label: const Text('Générer mon token'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: KeplerColors.of(context).onAccentFill,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.35),
              disabledForegroundColor: KeplerColors.of(context).textTertiary,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
          ),
          if (_error != null) ...[
            SizedBox(height: 12.h),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (widget.onRestore != null) ...[
            SizedBox(height: 8.h),
            TextButton.icon(
              onPressed: _busy ? null : widget.onRestore,
              icon: Icon(Icons.login, size: 16.sp),
              label: const Text('J’ai déjà un token — me connecter'),
            ),
          ],
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  // ─── Résultat : token à sauvegarder ───────────────────────────────────────

  Widget _buildResult() {
    final token = _issuedToken!;
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 12.h),
          Icon(Icons.vpn_key_rounded, size: 56.sp, color: KeplerColors.of(context).success),
          SizedBox(height: 16.h),
          Text(
            'Voici ton token',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),

          // Avertissement critique : pas de récupération possible.
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: KeplerColors.of(context).error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: KeplerColors.of(context).error.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 22.sp, color: KeplerColors.of(context).error),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Sauvegarde ce token précieusement (capture, gestionnaire de '
                    'mots de passe…). Il est ta seule clé d’accès à tes données : '
                    'sans lui, aucune récupération n’est possible.',
                    style: TextStyle(fontSize: 13.sp, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // Le token, sélectionnable.
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: SelectableText(
              token,
              style: TextStyle(
                  fontSize: 13.sp, fontFamily: 'monospace', height: 1.4),
            ),
          ),
          SizedBox(height: 12.h),
          OutlinedButton.icon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(ClipboardData(text: token));
              messenger.showSnackBar(
                const SnackBar(content: Text('Token copié')),
              );
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copier le token'),
          ),
          SizedBox(height: 28.h),

          ElevatedButton.icon(
            onPressed: _finish,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(widget.standalone ? 'Terminer' : 'J’ai sauvegardé, continuer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: KeplerColors.of(context).onAccentFill,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              textStyle: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _label(String text) => Text(
        text,
        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
      );

  InputDecoration _dropdownDecoration(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
      );
}
