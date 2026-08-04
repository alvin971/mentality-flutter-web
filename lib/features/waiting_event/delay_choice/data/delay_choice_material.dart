// LE MATÉRIEL DU JEU : les délais dits en six langues, et l'écriture des
// montants.
//
// Pourquoi ce contenu ne va PAS dans les ARB. « dans trois mois » n'est pas du
// chrome : c'est la moitié de l'offre, donc le stimulus lui-même. Il suit la
// règle des items d'instrument — il vit en `data/`, sous `QText`, avec sa garde
// de parité six langues. Le chrome du jeu (consigne, boutons, libellés de
// résultat) reste dans les ARB.
//
// « Tout de suite » est ici pour la même raison, et pour une seconde : les deux
// branches d'un choix doivent se rédiger COTE À COTE. Séparer l'une dans les
// ARB et l'autre dans un fichier de données, c'est se garantir qu'un jour une
// traduction rendra les deux moitiés d'une même phrase dans deux registres
// différents.
//
// ── Les montants ─────────────────────────────────────────────────────────────
//
// LES SOMMES SONT IMAGINAIRES — voir l'en-tête de [DelayChoiceOffer]. Elles
// sont NOMINALEMENT IDENTIQUES dans les six langues : seul le symbole change,
// jamais le nombre. Convertir 150 € en livres ou en dollars donnerait des
// parties incomparables d'une langue à l'autre, et le résultat gardé sur
// l'appareil perdrait son sens le jour où quelqu'un change la langue de son
// téléphone.
//
// Les réglages du paradigme (somme différée, délais, nombre de choix) ne sont
// PAS ici : ils vivent dans `DelayChoiceRun`, parce qu'ils décrivent la forme de
// la mesure et non ce qui s'affiche.

import 'package:flutter/widgets.dart' show Locale;

import '../../_shared/domain/models/q_text.dart';

abstract final class DelayChoiceMaterial {
  /// Le délai retenu pour la phrase concrète de l'écran de résultat.
  ///
  /// Un mois : assez loin pour que l'attente pèse, assez proche pour que tout le
  /// monde se représente la scène. « Dans un an » ferait une phrase plus
  /// spectaculaire et moins parlante.
  static const int referenceDelayDays = 30;

  /// Comment se dit l'offre immédiate.
  static const QText now = QText(
    fr: 'tout de suite',
    en: 'right now',
    enGB: 'right now',
    de: 'sofort',
    es: 'ahora mismo',
    pt: 'já a seguir',
  );

  /// Comment se dit le délai d'une offre différée, dans l'offre elle-même.
  static QText delayLabel(int days) => switch (days) {
        7 => const QText(
            fr: 'dans une semaine',
            en: 'in one week',
            enGB: 'in one week',
            de: 'in einer Woche',
            es: 'dentro de una semana',
            pt: 'daqui a uma semana',
          ),
        30 => const QText(
            fr: 'dans un mois',
            en: 'in one month',
            enGB: 'in one month',
            de: 'in einem Monat',
            es: 'dentro de un mes',
            pt: 'daqui a um mês',
          ),
        90 => const QText(
            fr: 'dans trois mois',
            en: 'in three months',
            enGB: 'in three months',
            de: 'in drei Monaten',
            es: 'dentro de tres meses',
            pt: 'daqui a três meses',
          ),
        180 => const QText(
            fr: 'dans six mois',
            en: 'in six months',
            enGB: 'in six months',
            de: 'in sechs Monaten',
            es: 'dentro de seis meses',
            pt: 'daqui a seis meses',
          ),
        _ => const QText(
            fr: 'dans un an',
            en: 'in one year',
            enGB: 'in one year',
            de: 'in einem Jahr',
            es: 'dentro de un año',
            pt: 'daqui a um ano',
          ),
      };

  /// Le même délai en version courte, pour le tableau récapitulatif où il tient
  /// dans une colonne. « dans trois mois » y ferait une colonne de la largeur
  /// d'une phrase.
  static QText shortDelayLabel(int days) => switch (days) {
        7 => const QText(
            fr: '1 semaine',
            en: '1 week',
            enGB: '1 week',
            de: '1 Woche',
            es: '1 semana',
            pt: '1 semana',
          ),
        30 => const QText(
            fr: '1 mois',
            en: '1 month',
            enGB: '1 month',
            de: '1 Monat',
            es: '1 mes',
            pt: '1 mês',
          ),
        90 => const QText(
            fr: '3 mois',
            en: '3 months',
            enGB: '3 months',
            de: '3 Monate',
            es: '3 meses',
            pt: '3 meses',
          ),
        180 => const QText(
            fr: '6 mois',
            en: '6 months',
            enGB: '6 months',
            de: '6 Monate',
            es: '6 meses',
            pt: '6 meses',
          ),
        _ => const QText(
            fr: '1 an',
            en: '1 year',
            enGB: '1 year',
            de: '1 Jahr',
            es: '1 año',
            pt: '1 ano',
          ),
      };

  /// Le montant tel qu'il s'écrit pour quelqu'un qui lit en [locale] — même
  /// nombre partout, symbole et place selon l'usage.
  ///
  /// L'espace avant le symbole est INSÉCABLE : « 150 » et « € » ne doivent
  /// jamais se retrouver sur deux lignes, et une offre coupée en deux au milieu
  /// d'un montant se relit mal au moment précis où il faut choisir.
  static String amount(int value, Locale locale) => switch (_tag(locale)) {
        'en' => '\$$value',
        'en_GB' => '£$value',
        // fr, de, es, pt — l'euro se pose après le nombre dans les quatre.
        _ => '$value €',
      };

  static String _tag(Locale locale) =>
      locale.countryCode == null || locale.countryCode!.isEmpty
          ? locale.languageCode
          : '${locale.languageCode}_${locale.countryCode}';
}
