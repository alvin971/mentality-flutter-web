// Le matériel du jeu de délai : les délais dits en six langues, et l'écriture
// des montants.
//
// Deux familles de gardes, pour deux erreurs qui ne se verraient pas :
//
// · PARITÉ SIX LANGUES. Un délai non traduit ne casserait rien — `QText` se
//   replie sur l'anglais. L'offre afficherait « in three months » au milieu
//   d'un écran allemand, et la personne choisirait quand même. Rien dans le
//   résultat n'en garderait la trace.
// · MÊMES MONTANTS PARTOUT. Convertir 150 € en livres donnerait des parties
//   incomparables d'une langue à l'autre, et le résultat gardé sur l'appareil
//   perdrait son sens le jour où quelqu'un change la langue de son téléphone.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_text.dart';
import 'package:mentality/features/waiting_event/delay_choice/data/delay_choice_material.dart';
import 'package:mentality/features/waiting_event/delay_choice/domain/services/delay_choice_run.dart';

/// Les six locales du produit, telles qu'elles arrivent à un widget.
const List<Locale> locales = [
  Locale('fr'),
  Locale('en'),
  Locale('en', 'GB'),
  Locale('de'),
  Locale('es'),
  Locale('pt'),
];

void main() {
  group('parité six langues', () {
    test('★ chaque délai est dit dans les six langues', () {
      for (final jours in DelayChoiceRun.delaysDays) {
        expect(DelayChoiceMaterial.delayLabel(jours).missingLocales, isEmpty,
            reason: 'délai $jours, libellé long');
        expect(
            DelayChoiceMaterial.shortDelayLabel(jours).missingLocales, isEmpty,
            reason: 'délai $jours, libellé court');
      }
    });

    test('★ « tout de suite » est dit dans les six langues', () {
      expect(DelayChoiceMaterial.now.missingLocales, isEmpty);
    });

    test('aucun libellé ne se replie sur une autre langue', () {
      // `resolve` ne rend jamais vide, mais il peut rendre l'anglais sans
      // prévenir. On vérifie donc la valeur BRUTE, langue par langue.
      for (final tag in QText.locales) {
        for (final jours in DelayChoiceRun.delaysDays) {
          expect(DelayChoiceMaterial.delayLabel(jours).raw(tag), isNotNull,
              reason: '$tag / $jours');
        }
      }
    });

    test('les deux branches d\'un choix ne se ressemblent pas', () {
      // « tout de suite » et « dans une semaine » doivent se distinguer d'un
      // coup d'œil dans chaque langue — c'est toute la lisibilité de l'offre.
      for (final locale in locales) {
        final maintenant = DelayChoiceMaterial.now.resolve(locale);
        for (final jours in DelayChoiceRun.delaysDays) {
          expect(
            DelayChoiceMaterial.delayLabel(jours).resolve(locale),
            isNot(maintenant),
            reason: '$locale / $jours',
          );
        }
      }
    });

    test('le libellé court est plus court que le long', () {
      for (final locale in locales) {
        for (final jours in DelayChoiceRun.delaysDays) {
          final court =
              DelayChoiceMaterial.shortDelayLabel(jours).resolve(locale);
          final long = DelayChoiceMaterial.delayLabel(jours).resolve(locale);
          expect(court.length, lessThan(long.length),
              reason: '$locale / $jours');
        }
      }
    });
  });

  group('écriture des montants', () {
    test('★ le NOMBRE est le même dans les six langues', () {
      for (final locale in locales) {
        expect(DelayChoiceMaterial.amount(150, locale), contains('150'),
            reason: '$locale');
      }
    });

    test('la devise suit la langue et le pays', () {
      expect(DelayChoiceMaterial.amount(150, const Locale('fr')), contains('€'));
      expect(DelayChoiceMaterial.amount(150, const Locale('de')), contains('€'));
      expect(DelayChoiceMaterial.amount(150, const Locale('es')), contains('€'));
      expect(DelayChoiceMaterial.amount(150, const Locale('pt')), contains('€'));
      expect(DelayChoiceMaterial.amount(150, const Locale('en')), r'$150');
      expect(
          DelayChoiceMaterial.amount(150, const Locale('en', 'GB')), '£150');
    });

    test('★ jamais deux devises dans le même montant', () {
      for (final locale in locales) {
        final ecrit = DelayChoiceMaterial.amount(150, locale);
        final devises =
            ['€', r'$', '£'].where(ecrit.contains).toList();
        expect(devises.length, 1, reason: '$locale → $ecrit');
      }
    });

    test('l\'euro se colle au nombre par une espace insécable', () {
      // Une espace ordinaire laisserait « 150 » et « € » se retrouver sur deux
      // lignes, en plein milieu d'une offre qu'il faut lire d'un coup d'œil.
      // Les deux espaces sont écrites EN ÉCHAPPEMENT : à l'œil nu, l'insécable
      // et l'ordinaire sont le même caractère, et un test qui les confondrait
      // passerait pour la mauvaise raison.
      expect(DelayChoiceMaterial.amount(150, const Locale('fr')),
          '150\u00A0€');
      expect(DelayChoiceMaterial.amount(150, const Locale('fr')),
          isNot(contains('\u0020€')));
    });

    test('les montants de l\'escalier s\'écrivent tous', () {
      for (final locale in locales) {
        for (final montant in [3, 8, 37, 75, 113, 147]) {
          expect(DelayChoiceMaterial.amount(montant, locale),
              contains('$montant'));
        }
      }
    });
  });

  test('le délai de référence fait partie du jeu', () {
    // La phrase concrète du résultat porte sur ce délai : s'il disparaissait
    // des délais interrogés, elle ne s'afficherait plus jamais — sans que rien
    // ne signale la perte.
    expect(DelayChoiceRun.delaysDays,
        contains(DelayChoiceMaterial.referenceDelayDays));
  });
}
