// lib/core/constants/token_regions.dart
//
// Codes de région large autorisés dans le token anonyme (jamais code
// postal/commune — cf. token_issuer.dart). Source unique de vérité partagée
// entre le formulaire (token_issuance_step.dart) et la validation côté client
// (TokenIssuer). Miroir de `ALLOWED_REGIONS` dans workers/tokeniser/index.js —
// garder synchronisé si la liste évolue.
const Map<String, String> kTokenRegionLabels = {
  'IDF': 'Île-de-France',
  'ARA': 'Auvergne-Rhône-Alpes',
  'BFC': 'Bourgogne-Franche-Comté',
  'BRE': 'Bretagne',
  'CVL': 'Centre-Val de Loire',
  'COR': 'Corse',
  'GES': 'Grand Est',
  'HDF': 'Hauts-de-France',
  'NOR': 'Normandie',
  'NAQ': 'Nouvelle-Aquitaine',
  'OCC': 'Occitanie',
  'PDL': 'Pays de la Loire',
  'PAC': "Provence-Alpes-Côte d'Azur",
  'DOM': 'Outre-mer',
  'OTHER': 'Hors France / Autre',
};

final Set<String> kTokenRegionCodes = kTokenRegionLabels.keys.toSet();
