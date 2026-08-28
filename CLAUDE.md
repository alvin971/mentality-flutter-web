# CLAUDE.md — mentality-flutter-web

App patient Flutter — exercices cognitifs construits sur le modèle CHC (batterie à items **fixes** ; le moteur adaptatif `adaptive_testing/` est du code mort).
Contexte vault (`Projects/Mentality/`) injecté automatiquement en début de session ; règles écosystème dans `~/.claude/rules/mentality.md`.

> ⚠️ **Pivot mobile-only en cours** (2026-07) : préparation Play Store, minSdk Android 23 — voir `Projects/Mentality/Progress.md` pour l'état exact.

## Stack technique (audit réconcilié 2026-06-13)

- **Framework** : Flutter 3.32.2 / Dart 3.8.1 (verrouillé par intl 0.20.2 — ne pas « upgrader » vers un vieux 3.5)
- **State management** : flutter_bloc ^8.1.6 — BLoC **local par page/route**, pas de DI globale
- **Navigation** : go_router ^14.8.1
- **Persistance locale** : hive ^2.2.3 (AES-256) + SharedPreferences
- **Audio** : record ^5.2.1 — **Opus 32 kbps forcé** (webm/opus Chrome/FF, mp4 Safari, wav secours)
- **PDF** : pdf ^3.11.3, printing ^5.14.3
- **Remote** : Supabase via RemoteConfigService
- **Déploiement** : Cloudflare Pages + Workers

## Commandes dev

```bash
flutter run -d chrome          # dev local
flutter build web              # build production
flutter test                   # tests unitaires
```

## Architecture

Clean Architecture stricte, 3 couches par feature :
- `lib/features/<feature>/data/` — repositories, datasources, modèles
- `lib/features/<feature>/domain/` — entités, use cases, interfaces
- `lib/features/<feature>/presentation/` — BLoC, pages, widgets

Documentation complète : `ARCHITECTURE.md`, `PROJECT_STRUCTURE.md`.

## Points d'attention

- Migrations Supabase dans **mentality-admin/supabase/**, jamais ici.
- Le chat IA passe par un Cloudflare Worker — jamais d'appel direct Anthropic depuis Flutter.
- Base UI 375×812 ; le patient ne voit jamais scores bruts ni tables normatives.
