import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Label de section Kepler — eyebrow mono majuscule "TITRE".
///
/// Utilisé en eyebrow au-dessus des hero/h1 pour ancrer l'identité éditoriale
/// Mental E.T. (palette Kepler).
class KeplerSectionLabel extends StatelessWidget {
  const KeplerSectionLabel({
    super.key,
    required this.text,
    this.color,
    this.withGlyph = false,
  });

  final String text;
  final Color? color;
  final bool withGlyph;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    final label = text.toUpperCase();
    return Text(label, style: AppText.of(context).monoLabel(color: c));
  }
}
