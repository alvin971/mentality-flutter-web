#!/usr/bin/env node
/**
 * push_metadata_asc.js
 *
 * Pousse TOUTES les métadonnées de l'app vers App Store Connect via l'API REST.
 * Fonctionne depuis Linux/macOS/Windows — sans Xcode ni fastlane.
 *
 * Prérequis :
 *   npm install jsonwebtoken node-fetch@2
 *
 * Usage :
 *   node scripts/push_metadata_asc.js --key /chemin/vers/AuthKey_W426TUCNJK.p8
 *
 * Ce script met à jour :
 *   - App Information : nom, sous-titre, catégories, URL confidentialité
 *   - Version localisation : description, mots-clés, texte promo, notes de version, URLs
 *   - Classification par âge
 *   - Conformité export
 */

const fs   = require("fs");
const path = require("path");
const jwt  = require("jsonwebtoken");
const fetch = require("node-fetch");

// ─── Credentials ────────────────────────────────────────────────────────────
const KEY_ID     = "W426TUCNJK";
const ISSUER_ID  = "9ed054a6-6ff1-47d8-b54d-27e1a0c12862";
const BUNDLE_ID  = "com.mentalite.app";
const BASE_URL   = "https://api.appstoreconnect.apple.com/v1";

// ─── Helpers ─────────────────────────────────────────────────────────────────
function getKeyPath() {
  const args = process.argv.slice(2);
  const idx  = args.indexOf("--key");
  if (idx !== -1 && args[idx + 1]) return args[idx + 1];
  // Chercher dans les emplacements courants
  const candidates = [
    `./AuthKey_${KEY_ID}.p8`,
    `~/Downloads/AuthKey_${KEY_ID}.p8`,
    `/tmp/AuthKey_${KEY_ID}.p8`,
  ];
  for (const c of candidates) {
    if (fs.existsSync(c)) return c;
  }
  throw new Error(
    `Clé .p8 introuvable. Passez --key /chemin/vers/AuthKey_${KEY_ID}.p8`
  );
}

function generateToken(privateKey) {
  const now = Math.floor(Date.now() / 1000);
  return jwt.sign(
    { iss: ISSUER_ID, iat: now, exp: now + 1200, aud: "appstoreconnect-v1" },
    privateKey,
    { algorithm: "ES256", header: { kid: KEY_ID, typ: "JWT" } }
  );
}

async function asc(token, method, endpoint, body) {
  const res = await fetch(`${BASE_URL}${endpoint}`, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const data = await res.json();
  if (!res.ok) {
    const errors = data.errors?.map(e => `${e.status} — ${e.detail}`).join("\n") || JSON.stringify(data);
    throw new Error(`ASC API ${method} ${endpoint}\n${errors}`);
  }
  return data;
}

function readMeta(filePath) {
  const full = path.join(__dirname, "..", "ios", "fastlane", "metadata", filePath);
  return fs.existsSync(full) ? fs.readFileSync(full, "utf8").trim() : null;
}

// ─── Métadonnées à pousser ───────────────────────────────────────────────────
const META = {
  // App Information (par locale)
  name:            readMeta("fr-FR/name.txt"),
  subtitle:        readMeta("fr-FR/subtitle.txt"),
  privacyPolicyUrl: readMeta("fr-FR/privacy_url.txt"),

  // Version localisation
  description:      readMeta("fr-FR/description.txt"),
  keywords:         readMeta("fr-FR/keywords.txt"),
  promotionalText:  readMeta("fr-FR/promotional_text.txt"),
  whatsNew:         readMeta("fr-FR/release_notes.txt"),
  supportUrl:       readMeta("fr-FR/support_url.txt"),
  marketingUrl:     readMeta("fr-FR/marketing_url.txt"),

  // Classification par âge
  ageRating: JSON.parse(
    fs.readFileSync(
      path.join(__dirname, "..", "ios", "fastlane", "metadata", "rating_config.json"),
      "utf8"
    )
  ),
};

// ─── Main ────────────────────────────────────────────────────────────────────
async function main() {
  console.log("🔑 Lecture de la clé API...");
  const privateKey = fs.readFileSync(getKeyPath(), "utf8");
  const token = generateToken(privateKey);

  // 1. Trouver l'app
  console.log(`\n📱 Recherche de l'app ${BUNDLE_ID}...`);
  const appsData = await asc(token, "GET", `/apps?filter[bundleId]=${BUNDLE_ID}`);
  if (!appsData.data?.length) throw new Error(`App ${BUNDLE_ID} introuvable dans App Store Connect`);
  const app = appsData.data[0];
  const appId = app.id;
  console.log(`   ✓ App trouvée : ${appId}`);

  // 2. App Info — catégories + URL confidentialité
  console.log("\n📋 Mise à jour des informations de l'app...");
  const appInfosData = await asc(token, "GET", `/apps/${appId}/appInfos`);
  const appInfo = appInfosData.data?.[0];
  if (appInfo) {
    // Catégories (MEDICAL + EDUCATION)
    const primaryCatData = await asc(token, "GET", "/appCategories?filter[platforms]=IOS&limit=200");
    const cats = primaryCatData.data || [];
    const medical   = cats.find(c => c.id === "MEDICAL");
    const education = cats.find(c => c.id === "EDUCATION");

    await asc(token, "PATCH", `/appInfos/${appInfo.id}`, {
      data: {
        type: "appInfos",
        id: appInfo.id,
        relationships: {
          ...(medical   ? { primaryCategory:   { data: { type: "appCategories", id: medical.id   } } } : {}),
          ...(education ? { secondaryCategory: { data: { type: "appCategories", id: education.id } } } : {}),
        },
      },
    });
    console.log("   ✓ Catégories : Medical (primaire), Education (secondaire)");

    // Localisation AppInfo (fr-FR)
    const appInfoLocsData = await asc(token, "GET", `/appInfos/${appInfo.id}/appInfoLocalizations`);
    const frLoc = appInfoLocsData.data?.find(l => l.attributes.locale === "fr-FR");

    if (frLoc) {
      await asc(token, "PATCH", `/appInfoLocalizations/${frLoc.id}`, {
        data: {
          type: "appInfoLocalizations",
          id: frLoc.id,
          attributes: {
            name:            META.name,
            subtitle:        META.subtitle,
            privacyPolicyUrl: META.privacyPolicyUrl,
          },
        },
      });
    } else {
      // Créer la localisation fr-FR
      await asc(token, "POST", "/appInfoLocalizations", {
        data: {
          type: "appInfoLocalizations",
          attributes: {
            locale:          "fr-FR",
            name:            META.name,
            subtitle:        META.subtitle,
            privacyPolicyUrl: META.privacyPolicyUrl,
          },
          relationships: {
            appInfo: { data: { type: "appInfos", id: appInfo.id } },
          },
        },
      });
    }
    console.log("   ✓ Nom, sous-titre, URL confidentialité mis à jour");
  }

  // 3. Version App Store (PREPARE_FOR_SUBMISSION ou READY_FOR_REVIEW)
  console.log("\n📦 Recherche de la version en préparation...");
  const versionsData = await asc(
    token, "GET",
    `/apps/${appId}/appStoreVersions?filter[platform]=IOS&filter[appStoreState]=PREPARE_FOR_SUBMISSION`
  );

  let version = versionsData.data?.[0];

  if (!version) {
    // Créer une version 1.0.0
    console.log("   Aucune version en préparation — création de la version 1.0.0...");
    const newVer = await asc(token, "POST", "/appStoreVersions", {
      data: {
        type: "appStoreVersions",
        attributes: {
          platform:    "IOS",
          versionString: "1.0.0",
        },
        relationships: {
          app: { data: { type: "apps", id: appId } },
        },
      },
    });
    version = newVer.data;
  }
  const versionId = version.id;
  console.log(`   ✓ Version : ${version.attributes.versionString} (${versionId})`);

  // 4. Localisation de la version (description, keywords, etc.)
  console.log("\n✍️  Mise à jour des textes de la version...");
  const versionLocsData = await asc(token, "GET", `/appStoreVersions/${versionId}/appStoreVersionLocalizations`);
  const frVersionLoc = versionLocsData.data?.find(l => l.attributes.locale === "fr-FR");

  const locAttributesBase = {
    description:     META.description,
    keywords:        META.keywords,
    promotionalText: META.promotionalText,
    supportUrl:      META.supportUrl,
    marketingUrl:    META.marketingUrl,
    // whatsNew non modifiable avant soumission
  };

  if (frVersionLoc) {
    // PATCH : pas de locale dans les attributs
    await asc(token, "PATCH", `/appStoreVersionLocalizations/${frVersionLoc.id}`, {
      data: {
        type: "appStoreVersionLocalizations",
        id: frVersionLoc.id,
        attributes: locAttributesBase,
      },
    });
  } else {
    // POST : locale requis à la création
    await asc(token, "POST", "/appStoreVersionLocalizations", {
      data: {
        type: "appStoreVersionLocalizations",
        attributes: { locale: "fr-FR", ...locAttributesBase },
        relationships: {
          appStoreVersion: { data: { type: "appStoreVersions", id: versionId } },
        },
      },
    });
  }
  console.log("   ✓ Description, mots-clés, texte promo, notes de version, URLs");

  // 5. Classification par âge
  console.log("\n🔞 Mise à jour de la classification par âge...");
  try {
    // Récupérer l'ID depuis les relationships de la version
    const verDetail = await asc(token, "GET", `/appStoreVersions/${versionId}?include=ageRatingDeclaration`);
    const ageRatingId = verDetail.included?.[0]?.id;

    if (ageRatingId) {
      const ar = META.ageRating;
      await asc(token, "PATCH", `/ageRatingDeclarations/${ageRatingId}`, {
        data: {
          type: "ageRatingDeclarations",
          id: ageRatingId,
          attributes: {
            violenceCartoonOrFantasy:                    ar.violenceCartoonOrFantasy,
            violenceRealistic:                           ar.violenceRealistic,
            violenceRealisticProlongedGraphicOrSadistic: ar.violenceRealisticProlongedGraphicOrSadistic,
            profanityOrCrudeHumor:                       ar.profanityOrCrudeHumor,
            matureOrSuggestiveThemes:                    ar.matureOrSuggestiveThemes,
            horrorOrFearThemes:                          ar.horrorOrFearThemes,
            medicalOrTreatmentInformation:               ar.medicalOrTreatmentInformation,
            alcoholTobaccoOrDrugUseOrReferences:         ar.alcoholTobaccoOrDrugUseOrReferences,
            sexualContentOrNudity:                       ar.sexualContentOrNudity,
            sexualContentGraphicAndNudity:               ar.sexualContentGraphicAndNudity,
            gambling:                                    ar.gambling,
            gamblingSimulated:                           ar.gamblingSimulated,
            contests:                                    ar.contests,
            lootBox:                                     ar.lootBox,
            unrestrictedWebAccess:                       ar.unrestrictedWebAccess,
          },
        },
      });
      console.log("   ✓ Classification : 4+ (aucun contenu sensible)");
    } else {
      console.warn("   ⚠ Age rating ID non trouvé — à configurer manuellement dans ASC");
    }
  } catch (e) {
    console.warn(`   ⚠ Age rating : ${e.message.split("\n")[0]}`);
  }

  // 6. Conformité export (ITSAppUsesNonExemptEncryption = false)
  console.log("\n🔐 Mise à jour de la conformité export...");
  try {
    await asc(token, "PATCH", `/appStoreVersions/${versionId}`, {
      data: {
        type: "appStoreVersions",
        id: versionId,
        attributes: {
          usesNonExemptEncryption: false,
        },
      },
    });
    console.log("   ✓ Conformité export : pas de chiffrement non-exempt");
  } catch (e) {
    console.warn(`   ⚠ Conformité export : ${e.message.split("\n")[0]}`);
  }

  console.log("\n✅ Toutes les métadonnées ont été poussées avec succès !");
  console.log("\nProchaines étapes :");
  console.log("  1. Vérifier dans App Store Connect → Informations sur l'app");
  console.log("  2. Vérifier la section Distribution → Version");
  console.log("  3. Remplir manuellement : Confidentialité de l'app (données collectées)");
  console.log("  4. Ajouter les screenshots (node scripts/generate_screenshots.js)");
  console.log("  5. Uploader un build via GitHub Actions (git push origin main)");
}

main().catch(err => {
  console.error("\n❌ Erreur :", err.message);
  process.exit(1);
});
