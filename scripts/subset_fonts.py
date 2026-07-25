#!/usr/bin/env python3
"""Récupère et allège les trois polices embarquées de Mental E.T.

## Pourquoi ce script existe

Avant le 2026-07-25, les polices étaient téléchargées au lancement par
`google_fonts`. Sans réseau au premier démarrage, l'app retombait sur la
police système et perdait toute son identité éditoriale ; s'y ajoutaient un
changement de fonte visible au démarrage et une requête vers
fonts.gstatic.com à chaque ouverture.

Elles sont désormais dans le bundle. Mais les fichiers d'origine pèsent
2,4 Mo : ce sont des polices variables complètes, avec cyrillique, grec et
tous les corps optiques. L'app est en FR/EN/DE/ES/PT — donc latin seul — et
n'utilise que trois graisses. Ce script réduit à ~470 Ko (-80 %).

## Usage

    pip install fonttools brotli
    python3 scripts/subset_fonts.py            # télécharge + allège
    python3 scripts/subset_fonts.py --verify   # contrôle seulement

Après exécution, vérifier que `flutter build web` liste bien les trois
familles dans `build/web/assets/FontManifest.json`.

## Attention

Les plages de graisses ci-dessous doivent couvrir CELLES RÉELLEMENT
UTILISÉES par `app_typography.dart`. Si une nouvelle graisse y apparaît sans
être ajoutée ici, le rendu retombera silencieusement sur la graisse la plus
proche disponible.
"""
import argparse
import os
import subprocess
import sys
import urllib.request

DEST = 'assets/fonts'
BASE = 'https://raw.githubusercontent.com/google/fonts/main'

# Latin + latin étendu + ponctuation typographique + symboles utilisés.
UNICODES = ','.join([
    'U+0000-00FF',   # latin de base + supplément (é à ç ü ñ ã …)
    'U+0100-017F',   # latin étendu A
    'U+0180-024F',   # latin étendu B
    'U+2000-206F',   # ponctuation générale (— – … « » ·)
    'U+20A0-20BF',   # symboles monétaires
    'U+2100-214F',   # symboles de type lettre (№ ™)
    'U+2190-21BB',   # flèches
    'U+2212',        # signe moins
])

# (nom local, chemin amont, plage wght, valeur opsz épinglée)
# Les graisses proviennent de app_typography.dart :
#   serif  → w500 (titres) ; italique → w500 uniquement
#   sans   → w400 (corps), w500 (corps fort), w600 (boutons)
#   mono   → w500 (scores), w600 (labels)
FONTS = [
    ('SourceSerif4.ttf',
     'ofl/sourceserif4/SourceSerif4%5Bopsz,wght%5D.ttf', 'wght=400:600', 'opsz=14'),
    ('SourceSerif4-Italic.ttf',
     'ofl/sourceserif4/SourceSerif4-Italic%5Bopsz,wght%5D.ttf', 'wght=500', 'opsz=14'),
    ('DMSans.ttf',
     'ofl/dmsans/DMSans%5Bopsz,wght%5D.ttf', 'wght=400:600', 'opsz=14'),
    ('RobotoMono.ttf',
     'ofl/robotomono/RobotoMono%5Bwght%5D.ttf', 'wght=500:600', None),
]

# Accents des six langues supportées + typographie de l'UI.
COVERAGE = ('éèêëàâçùûôîïÉÈÀÇÙÔÎ' 'äöüßÄÖÜ' 'ñáíóúÁÍÓÚ¿¡' 'ãõâêÃÕ'
            '«»—–…·0123456789%/')


def fetch(name, path):
    url = f'{BASE}/{path}'
    dest = os.path.join(DEST, name)
    os.makedirs(DEST, exist_ok=True)
    urllib.request.urlretrieve(url, dest)
    return dest


def shrink(dest, wght, opsz):
    before = os.path.getsize(dest)
    axes = [wght] + ([opsz] if opsz else [])
    subprocess.run([sys.executable, '-m', 'fontTools.varLib.instancer',
                    dest, *axes, '-o', '/tmp/_inst.ttf'], check=True,
                   capture_output=True)
    subprocess.run([sys.executable, '-m', 'fontTools.subset', '/tmp/_inst.ttf',
                    f'--unicodes={UNICODES}', '--layout-features=*',
                    '--glyph-names', f'--output-file={dest}'], check=True,
                   capture_output=True)
    return before, os.path.getsize(dest)


def verify():
    from fontTools.ttLib import TTFont
    ok = True
    for name, _, wght, _ in FONTS:
        p = os.path.join(DEST, name)
        if not os.path.exists(p):
            print(f'  MANQUANT  {name}')
            ok = False
            continue
        ft = TTFont(p)
        cmap = set(ft.getBestCmap())
        missing = [c for c in COVERAGE if ord(c) not in cmap]
        axes = {a.axisTag: (a.minValue, a.maxValue)
                for a in ft['fvar'].axes} if 'fvar' in ft else {}
        status = 'OK' if not missing else f'GLYPHES MANQUANTS {missing}'
        if missing:
            ok = False
        print(f'  {name:<26} {os.path.getsize(p)//1024:>4} Ko  '
              f'axes={axes or "statique"}  {status}')
    return ok


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--verify', action='store_true',
                    help='ne contrôle que les fichiers déjà présents')
    args = ap.parse_args()

    if not args.verify:
        total_before = total_after = 0
        for name, path, wght, opsz in FONTS:
            dest = fetch(name, path)
            b, a = shrink(dest, wght, opsz)
            total_before += b
            total_after += a
            print(f'  {name:<26} {b//1024:>5} Ko → {a//1024:>4} Ko')
        print(f'  {"TOTAL":<26} {total_before//1024:>5} Ko → '
              f'{total_after//1024:>4} Ko')

    print('\nContrôle de couverture :')
    sys.exit(0 if verify() else 1)
