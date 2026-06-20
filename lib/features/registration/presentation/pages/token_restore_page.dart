// lib/features/registration/presentation/pages/token_restore_page.dart
//
// « Se connecter avec un token » : l'utilisateur colle le token qu'il a
// sauvegardé à l'inscription → vérification → restauration de l'accès.
//
// TODO(i18n) : libellés en dur (FR), à migrer vers l'ARB.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/auth_local_store.dart';
import '../../../../core/services/token_access.dart';
import '../../../../core/theme/app_colors.dart';

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
              Icon(Icons.vpn_key_outlined, size: 56.sp, color: AppColors.primary),
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
                  hintText: 'MENTA1.… ou eyJ…',
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
            ],
          ),
        ),
      ),
    );
  }
}
