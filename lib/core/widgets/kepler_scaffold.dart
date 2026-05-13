import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import 'kepler_app_bar.dart';

/// Scaffold pré-configuré pour la charte Kepler — fond crème,
/// padding horizontal cohérent, AppBar Kepler optionnelle.
class KeplerScaffold extends StatelessWidget {
  const KeplerScaffold({
    super.key,
    required this.child,
    this.title,
    this.eyebrow,
    this.actions,
    this.appBar,
    this.bottomBar,
    this.padding,
    this.scroll = true,
    this.background,
  });

  final Widget child;
  final String? title;
  final String? eyebrow;
  final List<Widget>? actions;

  /// AppBar custom. Si fourni, `title`/`eyebrow`/`actions` sont ignorés.
  final PreferredSizeWidget? appBar;

  final Widget? bottomBar;
  final EdgeInsetsGeometry? padding;
  final bool scroll;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final bar = appBar ??
        ((title != null || eyebrow != null || actions != null)
            ? KeplerAppBar(title: title, eyebrow: eyebrow, actions: actions)
            : null);

    final p = padding ?? EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h);
    final body = Padding(padding: p, child: child);

    return Scaffold(
      backgroundColor: background ?? AppColors.background,
      appBar: bar,
      bottomNavigationBar: bottomBar,
      body: scroll
          ? SafeArea(
              top: bar == null,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: body,
              ),
            )
          : SafeArea(top: bar == null, child: body),
    );
  }
}
