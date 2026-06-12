import 'package:flutter/widgets.dart';
import 'gen/app_localizations.dart';
import 'locale_notifier.dart';

export 'gen/app_localizations.dart';

/// Raccourci d'accès aux traductions : `context.l10n.maCle`.
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Accès aux traductions HORS widget tree (services, générateurs, PDF...),
/// basé sur la langue courante de [localeNotifier].
AppLocalizations get appL10n => lookupAppLocalizations(localeNotifier.value);
