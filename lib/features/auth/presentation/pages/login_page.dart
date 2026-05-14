// lib/features/auth/presentation/pages/login_page.dart
//
// Page de connexion — Email/Password + Google Sign-in.
//
// STATUT : skeleton prêt, Firebase non configuré.
// Activer en suivant les étapes dans lib/core/config/firebase_config.dart.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/firebase_config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isRegistering = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!FirebaseConfig.isConfigured) {
      setState(() {
        _errorMessage =
            'Firebase n\'est pas encore configuré. Suivez les instructions dans firebase_config.dart.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Décommenter après configuration Firebase
      // if (_isRegistering) {
      //   await FirebaseAuth.instance.createUserWithEmailAndPassword(
      //     email: _emailController.text.trim(),
      //     password: _passwordController.text,
      //   );
      // } else {
      //   await FirebaseAuth.instance.signInWithEmailAndPassword(
      //     email: _emailController.text.trim(),
      //     password: _passwordController.text,
      //   );
      // }
      // if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!FirebaseConfig.isConfigured) {
      setState(() {
        _errorMessage =
            'Firebase n\'est pas encore configuré.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Décommenter après configuration Firebase + ajout google_sign_in
      // final googleUser = await GoogleSignIn().signIn();
      // if (googleUser == null) return;
      // final googleAuth = await googleUser.authentication;
      // final credential = GoogleAuthProvider.credential(
      //   accessToken: googleAuth.accessToken,
      //   idToken: googleAuth.idToken,
      // );
      // await FirebaseAuth.instance.signInWithCredential(credential);
      // if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegistering ? 'Créer un compte' : 'Connexion'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context),
                    SizedBox(height: 32.h),
                    _buildEmailField(),
                    SizedBox(height: 16.h),
                    _buildPasswordField(),
                    SizedBox(height: 8.h),
                    if (_errorMessage != null) _buildError(),
                    SizedBox(height: 24.h),
                    _buildSubmitButton(),
                    SizedBox(height: 16.h),
                    _buildDivider(),
                    SizedBox(height: 16.h),
                    _buildGoogleButton(),
                    SizedBox(height: 24.h),
                    _buildToggleMode(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.psychology_rounded,
          size: 64.sp,
          color: AppColors.primary,
        ),
        SizedBox(height: 16.h),
        Text(
          'Mental E.T.',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: 8.h),
        Text(
          _isRegistering
              ? 'Créez un compte pour sauvegarder vos résultats'
              : 'Connectez-vous pour accéder à votre historique',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Adresse e-mail',
        prefixIcon: Icon(Icons.email_outlined),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Champ obligatoire';
        if (!v.contains('@')) return 'Adresse e-mail invalide';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _submit(),
      decoration: const InputDecoration(
        labelText: 'Mot de passe',
        prefixIcon: Icon(Icons.lock_outlined),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Champ obligatoire';
        if (_isRegistering && v.length < 8) {
          return 'Minimum 8 caractères';
        }
        return null;
      },
    );
  }

  Widget _buildError() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Text(
        _errorMessage!,
        style: TextStyle(color: AppColors.error, fontSize: 13.sp),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _submit,
      child: _isLoading
          ? SizedBox(
              height: 20.h,
              width: 20.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(_isRegistering ? 'Créer un compte' : 'Se connecter'),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text('ou', style: TextStyle(color: AppColors.grey500, fontSize: 13.sp)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _signInWithGoogle,
      icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
      label: const Text('Continuer avec Google'),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  Widget _buildToggleMode() {
    return TextButton(
      onPressed: () => setState(() {
        _isRegistering = !_isRegistering;
        _errorMessage = null;
      }),
      child: Text(
        _isRegistering
            ? 'Déjà un compte ? Se connecter'
            : 'Pas encore de compte ? S\'inscrire',
      ),
    );
  }
}
