// lib/features/registration/presentation/pages/token_restore_page.dart
//
// « Se connecter avec un token » : l'utilisateur colle le token qu'il a
// sauvegardé à l'inscription → vérification → restauration de l'accès.
//
// TODO(i18n) : libellés en dur (FR), à migrer vers l'ARB.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/auth_local_store.dart';
import '../../../../core/services/results_sync.dart';
import '../../../../core/services/token_access.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/kepler_colors.dart';

class TokenRestorePage extends StatefulWidget {
  const TokenRestorePage({super.key});

  @override
  State<TokenRestorePage> createState() => _TokenRestorePageState();
}

class _TokenRestorePageState extends State<TokenRestorePage> {
  final _controller = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final token = _controller.text.trim();
    if (token.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await TokenAccess.isAcceptable(token);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _busy = false;
        _error = 'Token invalide ou non reconnu.';
      });
      return;
    }
    await AuthLocalStore.instance.saveToken(token);
    // Un en-tête d'authentification existe enfin : on rejoue ce qui aurait pu
    // s'accumuler sans token (voir ResultsSync.retryPending).
    unawaited(ResultsSync.instance.retryPending());
    if (!mounted) return;
    context.go(AppConstants.routeHome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Se connecter avec un token'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 12.h),
              Icon(Icons.vpn_key_outlined, size: 56.sp, color: KeplerColors.of(context).primary),
              SizedBox(height: 16.h),
              Text(
                'Colle ton token',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              Text(
                'Celui que tu as sauvegardé à l’inscription. Il restaure '
                'l’accès à tes données sur cet appareil.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24.h),
              TextField(
                controller: _controller,
                minLines: 2,
                maxLines: 4,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  hintText: 'M2.… ou eyJ…',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r)),
                ),
                style: TextStyle(fontSize: 12.sp, fontFamily: 'monospace'),
              ),
              SizedBox(height: 20.h),
              // L'inscription n'existe QUE sur le site : l'app ne crée jamais de
              // token, elle en reçoit un. Sans ce renvoi, un nouvel arrivant se
              // retrouverait devant un champ qu'il ne peut pas remplir.
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color:
                      KeplerColors.of(context).primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Column(
                  children: [
                    Text(
                      'Pas encore de token ?',
                      style: TextStyle(
                          fontSize: 14.sp, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Il se crée en une minute sur le site, sans compte ni '
                      'email. Pense à le sauvegarder : il est ta seule clé.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    OutlinedButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse(AppConstants.inviteBaseUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Créer mon token sur le site'),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                SizedBox(height: 12.h),
                Text(
                  _error!,
                  style: TextStyle(
                      fontSize: 12.sp,
                      color: Theme.of(context).colorScheme.error),
                ),
              ],
              SizedBox(height: 24.h),
              ElevatedButton.icon(
                onPressed: _busy ? null : _connect,
                icon: _busy
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.login),
                label: const Text('Se connecter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.35),
                  disabledForegroundColor: Colors.white70,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  textStyle:
                      TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
