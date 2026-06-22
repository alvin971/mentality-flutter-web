import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../l10n/l10n_ext.dart';
import '../l10n/locale_notifier.dart';

/// Bouton de changement de langue (FR / EN-US / EN-UK / ES / PT / DE).
///
/// Affiche le tag de la langue courante et ouvre un menu listant les langues
/// disponibles. Le choix est persisté via [localeNotifier]. Les libellés et
/// drapeaux sont indexés par le tag de contenu ([LocaleNotifier.tagFor]) afin
/// de distinguer l'anglais US 🇺🇸 de l'anglais britannique 🇬🇧.
class LanguageSwitcherButton extends StatelessWidget {
  const LanguageSwitcherButton({super.key});

  static const Map<String, String> _labels = {
    'fr': 'Français',
    'en': 'English (US)',
    'en-GB': 'English (UK)',
    'es': 'Español',
    'pt': 'Português',
    'de': 'Deutsch',
  };

  static const Map<String, String> _flags = {
    'fr': '🇫🇷',
    'en': '🇺🇸',
    'en-GB': '🇬🇧',
    'es': '🇪🇸',
    'pt': '🇵🇹',
    'de': '🇩🇪',
  };

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        final color = Theme.of(context).colorScheme.onSurfaceVariant;
        return PopupMenuButton<Locale>(
          tooltip: context.l10n.languageSwitcherTooltip,
          position: PopupMenuPosition.under,
          onSelected: localeNotifier.setLocale,
          itemBuilder: (context) => [
            for (final l in LocaleNotifier.supportedLocales)
              PopupMenuItem<Locale>(
                value: l,
                child: Row(
                  children: [
                    Text(_flags[LocaleNotifier.tagFor(l)] ?? ''),
                    SizedBox(width: 8.w),
                    Text(_labels[LocaleNotifier.tagFor(l)] ??
                        LocaleNotifier.tagFor(l)),
                    const Spacer(),
                    if (l.languageCode == locale.languageCode &&
                        l.countryCode == locale.countryCode)
                      Icon(Icons.check, size: 16.sp),
                  ],
                ),
              ),
          ],
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.language, size: 20.sp, color: color),
                SizedBox(width: 4.w),
                Text(
                  LocaleNotifier.tagFor(locale).toUpperCase(),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
