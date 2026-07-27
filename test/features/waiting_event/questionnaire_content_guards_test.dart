// Les gardes de contenu — écrites AVANT les contenus qu'elles protègent.
//
// Le registre des modules est vide aujourd'hui : ces tests passent donc en
// balayant zéro module, et c'est volontaire. Ils sont posés maintenant pour
// qu'aucun contenu ne puisse entrer sans les satisfaire — un instrument dont
// l'ordre a glissé, un item non traduit ou un volume hors règle ne se voit sur
// aucun écran, il fausse simplement le résultat ou laisse un blanc en
// portugais.
//
// Elles encodent les règles du plan produit : 40 à 50 questions par test,
// instrument validé intact et en premier, six langues partout, une échelle par
// bloc sauf transition déclarée.

import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_instrument.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_module.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_text.dart';
import 'package:mentality/features/waiting_event/_shared/domain/services/event_schedule.dart';
import 'package:mentality/features/waiting_event/_shared/domain/services/q_module_registry.dart';

/// Tous les textes affichés d'un module : items, modalités de réponse, écrans
/// de transition. C'est l'ensemble exact qui doit exister en six langues.
Map<String, QText> textesDe(QModule module) {
  final out = <String, QText>{};
  for (final bloc in module.instruments) {
    for (final option in bloc.scale.options) {
      out['${module.id}/${bloc.scale.id}/opt${option.value}'] = option.label;
    }
    if (bloc.transition != null) {
      out['${module.id}/${bloc.id}/transition.titre'] = bloc.transition!.title;
      out['${module.id}/${bloc.id}/transition.corps'] = bloc.transition!.body;
    }
    for (final item in bloc.items) {
      out['${module.id}/${bloc.id}/${item.id}'] = item.text;
    }
  }
  return out;
}

void main() {
  final modules = QModuleRegistry.modules;

  test('le registre est cohérent : un module au plus par journée', () {
    final jours = modules.map((m) => m.day).toList();
    expect(jours.toSet().length, jours.length,
        reason: 'deux modules revendiquent la même journée');
    for (final m in modules) {
      expect(m.day, inInclusiveRange(1, EventSchedule.totalDays),
          reason: 'module ${m.id} hors programme');
      expect(QModuleRegistry.forDay(m.day), m);
    }

    final ids = modules.map((m) => m.id).toList();
    expect(ids.toSet().length, ids.length, reason: 'identifiants en double');
  });

  test('GARDE volume : chaque test fait 40 à 50 questions', () {
    for (final m in modules) {
      expect(m.questionCount, inInclusiveRange(40, 50),
          reason: 'module ${m.id} : ${m.questionCount} questions');
    }
  });

  test('GARDE : le hub annonce le volume réel du module', () {
    for (final m in modules) {
      expect(m.questionCount, EventSchedule.byDay(m.day).questionCount,
          reason: 'le programme du jour ${m.day} promet un autre volume que '
              'celui que le module ${m.id} pose réellement');
    }
  });

  test('GARDE intégrité : les blocs validés passent avant nos questions', () {
    for (final m in modules) {
      expect(m.validatedBlocksComeFirst, isTrue,
          reason: 'module ${m.id} : nos questions candidates avant un '
              'instrument validé décaleraient son seuil publié');
    }
  });

  test('GARDE échelle : un bloc, une échelle ; tout changement est annoncé',
      () {
    for (final m in modules) {
      expect(m.undeclaredScaleChanges, isEmpty,
          reason: 'module ${m.id} : l\'échelle change sans écran de transition');
    }
  });

  test('GARDE parité : chaque texte affiché existe dans les six langues', () {
    final manquants = <String>[];
    for (final m in modules) {
      textesDe(m).forEach((chemin, texte) {
        if (texte.missingLocales.isNotEmpty) {
          manquants.add('$chemin → ${texte.missingLocales.join(", ")}');
        }
      });
    }
    expect(manquants, isEmpty,
        reason: 'textes non traduits :\n${manquants.join("\n")}');
  });

  test('les identifiants d\'items sont uniques — les réponses sont rangées '
      'par identifiant', () {
    for (final m in modules) {
      final ids = m.items.map((i) => i.id).toList();
      expect(ids.toSet().length, ids.length,
          reason: 'module ${m.id} : deux items partagent un identifiant, '
              'donc une réponse en écraserait une autre');
    }
  });

  test('les identifiants sont transportables : le worker les refuserait sinon',
      () {
    // Un identifiant d'item ou de module part tel quel dans la charge utile, et
    // le module devient un segment de la clé R2. Le worker (workers/event)
    // borne leur longueur et exige un module en slug ; un refus de sa part est
    // DÉFINITIF côté client — la donnée serait perdue. Cette garde attrape la
    // faute au moment où le contenu est écrit, pas en production.
    final slug = RegExp(r'^[A-Za-z0-9_-]+$');
    for (final m in modules) {
      expect(slug.hasMatch(m.id), isTrue,
          reason: 'module ${m.id} : identifiant non transportable (il devient '
              'un segment de la clé R2)');
      for (final i in m.items) {
        expect(i.id.length, lessThanOrEqualTo(64),
            reason: 'module ${m.id} : item ${i.id} — identifiant trop long, '
                'le worker refuserait tout le module (400)');
        expect(i.id, isNotEmpty, reason: 'module ${m.id} : item sans id');
      }
    }
  });

  test('une cotation inversée n\'existe que dans un bloc validé', () {
    for (final m in modules) {
      for (final bloc in m.instruments) {
        if (bloc.origin == QItemOrigin.candidate) {
          expect(bloc.items.every((i) => !i.reverseScored), isTrue,
              reason: 'module ${m.id}, bloc ${bloc.id} : nos questions '
                  'candidates ne portent pas encore de cotation');
        }
      }
    }
  });

  test('un instrument validé sous licence CC BY porte sa citation', () {
    // La citation est une OBLIGATION de licence (RAADS-14, CAT-Q), pas une
    // politesse. Elle est affichée en page Méthodologie.
    for (final m in modules) {
      for (final bloc in m.instruments) {
        if (bloc.origin == QItemOrigin.validated) {
          expect(bloc.citation, isNotNull,
              reason: 'module ${m.id}, bloc ${bloc.id} : instrument validé '
                  'sans citation déclarée');
        }
      }
    }
  });

  test('aucun contenu livré n\'est encore enregistré — le hub annonce donc '
      'ses journées sans les ouvrir', () {
    // Ce test documente l\'état réel plutôt que de le supposer. Il tombera au
    // premier module livré, ce qui est exactement le moment de le mettre à
    // jour.
    expect(modules, isEmpty);
    for (var d = 1; d <= EventSchedule.totalDays; d++) {
      expect(QModuleRegistry.forDay(d), isNull);
    }
  });
}
