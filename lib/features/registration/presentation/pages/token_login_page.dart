// lib/features/registration/presentation/pages/token_login_page.dart
//
// Écran de CONNEXION au démarrage : l'utilisateur colle le token qu'il a reçu
// lors de son inscription sur le site web. Le token est vérifié (signature
// Ed25519) puis sauvegardé localement → accès à l'application.
//
// L'inscription (génération du token) se fait DÉSORMAIS UNIQUEMENT sur le site
// web (mental-et.com/inscription). L'app ne génère plus de token : l'ancien
// formulaire démographique local (TokenIssuanceStep) a été retiré du parcours
// d'entrée.
//
// TODO(i18n) : libellés en dur (FR), cohérent avec les autres écrans token.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/auth_local_store.dart';
import '../../../../core/services/token_access.dart';
import '../../../../core/theme/app_colors.dart';

class TokenLoginPage extends StatefulWidget {
  const TokenLoginPage({super.key});

  @override
  State<TokenLoginPage> createState() => _TokenLoginPageState();
}

class _TokenLoginPageState extends State<TokenLoginPage> {
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
    if (!mounted) return;
    context.go(AppConstants.routeHome);
  }

  Future<void> _openInscription() async {
    await launchUrl(
      Uri.parse(AppConstants.inscriptionUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 12.h),
              Icon(Icons.vpn_key_outlined,
                  size: 56.sp, color: AppColors.primary),
              SizedBox(height: 16.h),
              Text(
                'Entre ton token',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              Text(
                'Colle le token reçu lors de ton inscription. Il te donne '
                'accès à l’application sur cet appareil.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: onSurfaceVariant,
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
                onSubmitted: (_) => _connect(),
                decoration: InputDecoration(
                  hintText: 'M2.… ou eyJ…',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r)),
                ),
                style: TextStyle(fontSize: 12.sp, fontFamily: 'monospace'),
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
              SizedBox(height: 32.h),
              Divider(color: onSurfaceVariant.withValues(alpha: 0.2)),
              SizedBox(height: 16.h),
              Text(
                'Pas encore de token ?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.sp, color: onSurfaceVariant),
              ),
              SizedBox(height: 8.h),
              TextButton(
                onPressed: _openInscription,
                child: Text(
                  'Inscris-toi sur mental-et.com',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
