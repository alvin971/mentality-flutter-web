# AIDE DÉPLOIEMENT - Cloudflare Pages Flutter Web

## 📋 Résumé du Problème

Cloudflare Pages affichait une erreur "Output directory 'racine' not found" lors du déploiement du projet Flutter web.

## 🚨 Cause Principale

Cloudflare Pages détecte la configuration via `wrangler.toml` et l'ignore si la structure n'est pas valide.

## ✅ Solution Correcte

### Étape 1 : Supprimer le wrangler.toml

Supprimez le fichier :

```bash
rm wrangler.toml
git add wrangler.toml
git commit -m "Remove wrangler.toml"
git push
```

### Étape 2 : Configurer via Dashboard Cloudflare Pages

Allez dans Cloudflare Dashboard → Pages → votre projet → Settings → Builds & deployments

**Paramètres à mettre :**
- **Framework preset**: `None`
- **Build command**: vide/None
- **Build output directory**: vide/None

Ceci uploadera directement le dossier racine (contenant `index.html`, `main.dart.js`, etc.)

### Étape 3 : Branches GitHub

Si vous travaillez avec `master` et `main` :
- `master` = version de travail (avec vos changements)
- `main` = version production (branch Cloudflare)

Pour synchroniser :

```bash
# Sur master
git merge main --allow-unrelated-histories -m "Merge main into master"
git push origin master
```

### Étape 4 : Déployer en Production

Dans Cloudflare Pages Dashboard :
1. Deployments → sélectionnez le dernier déploiement
2. Cliquez sur **"Promote to production"**
3. Ou : Settings → Builds & deployments → Production branch → mettez `master`

## 📝 Checklist Déploiement

- [ ] Supprimer `wrangler.toml` (ou utiliser configuration dashboard)
- [ ] Dashboard : Framework preset = None
- [ ] Dashboard : Build command = vide
- [ ] Dashboard : Build output directory = vide
- [ ] Pousser le code sur le bon branch (master ou main)
- [ ] Créer un nouveau déploiement dans Cloudflare
- [ ] Promouvoir en production si nécessaire

## ⚠️ Erreurs Fréquentes

| Erreur | Cause | Solution |
|--------|-------|----------|
| "Output directory not found" | Build command vide ou mauvais path | Mettre build output directory = vide |
| "flutter: not found" | Cloudflare n'a pas Flutter installé | Build command = vide (upload direct) |
| "Merge unrelated histories" | master et main ont des historiques différents | `--allow-unrelated-histories` |

## 💡 Astuce

Si le déploiement reste en "Preview", faites :
1. Settings → Builds & deployments
2. Production branch = `master`
3. Sauvegardez

## 📖 Sources

- Cloudflare Pages documentation
- Flutter web build structure
