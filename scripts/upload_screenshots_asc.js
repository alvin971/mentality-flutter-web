#!/usr/bin/env node
/**
 * upload_screenshots_asc.js
 *
 * Upload les screenshots iPhone 6.9" et iPhone 6.5" vers App Store Connect.
 *
 * Usage :
 *   node scripts/upload_screenshots_asc.js --key /chemin/vers/AuthKey.p8
 */

const fs    = require("fs");
const path  = require("path");
const crypto = require("crypto");
const jwt   = require("jsonwebtoken");
const fetch = require("node-fetch");

const KEY_ID     = "W426TUCNJK";
const ISSUER_ID  = "9ed054a6-6ff1-47d8-b54d-27e1a0c12862";
const VERSION_ID = "4360ff14-10d3-4201-8891-9b8196da2e88";
const BASE_URL   = "https://api.appstoreconnect.apple.com/v1";

const DEVICE_CONFIGS = [
  {
    label: 'iPhone 6.9"',
    displayType: "APP_IPHONE_67",
    dir: path.join(__dirname, '../ios/fastlane/screenshots/fr-FR/iPhone 6.9"'),
  },
  {
    label: 'iPhone 6.5"',
    displayType: "APP_IPHONE_65",
    dir: path.join(__dirname, '../ios/fastlane/screenshots/fr-FR/iPhone 6.5"'),
  },
  {
    label: 'iPhone 6.1"',
    displayType: "APP_IPHONE_61",
    dir: path.join(__dirname, '../ios/fastlane/screenshots/fr-FR/iPhone 6.1"'),
  },
  {
    label: 'iPhone 5.5"',
    displayType: "APP_IPHONE_55",
    dir: path.join(__dirname, '../ios/fastlane/screenshots/fr-FR/iPhone 5.5"'),
  },
];

function getKeyPath() {
  const args = process.argv.slice(2);
  const idx  = args.indexOf("--key");
  if (idx !== -1 && args[idx + 1]) return args[idx + 1];
  const candidates = [
    `/tmp/AuthKey_${KEY_ID}.p8`,
    `./AuthKey_${KEY_ID}.p8`,
  ];
  for (const c of candidates) if (fs.existsSync(c)) return c;
  throw new Error(`Clé .p8 introuvable. Passez --key /chemin/vers/AuthKey_${KEY_ID}.p8`);
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
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (method === "DELETE" && res.status === 204) return null;
  const data = await res.json();
  if (!res.ok) {
    const errors = data.errors?.map(e => `${e.status} — ${e.detail}`).join("\n") || JSON.stringify(data);
    throw new Error(`${method} ${endpoint}\n${errors}`);
  }
  return data;
}

async function uploadBinary(uploadOp, fileBuffer) {
  const { url, method, requestHeaders, length, offset } = uploadOp;
  const chunk = fileBuffer.slice(offset, offset + length);
  const headers = {};
  for (const h of requestHeaders) headers[h.name] = h.value;
  const res = await fetch(url, { method, headers, body: chunk });
  if (!res.ok) throw new Error(`Upload chunk failed: ${res.status}`);
}

async function uploadScreenshot(token, screenshotSetId, filePath) {
  const fileName   = path.basename(filePath);
  const fileBuffer = fs.readFileSync(filePath);
  const fileSize   = fileBuffer.length;
  const md5        = crypto.createHash("md5").update(fileBuffer).digest("hex");

  const reserveRes = await asc(token, "POST", "/appScreenshots", {
    data: {
      type: "appScreenshots",
      attributes: { fileSize, fileName },
      relationships: {
        appScreenshotSet: { data: { type: "appScreenshotSets", id: screenshotSetId } },
      },
    },
  });

  const screenshotId = reserveRes.data.id;
  for (const op of reserveRes.data.attributes.uploadOperations) {
    await uploadBinary(op, fileBuffer);
  }

  await asc(token, "PATCH", `/appScreenshots/${screenshotId}`, {
    data: {
      type: "appScreenshots",
      id: screenshotId,
      attributes: { sourceFileChecksum: md5, uploaded: true },
    },
  });
}

async function uploadDeviceScreenshots(token, localizationId, config) {
  console.log(`\n📱 ${config.label} (${config.displayType})`);

  // Trouver ou créer le screenshot set
  const setsData = await asc(token, "GET", `/appStoreVersionLocalizations/${localizationId}/appScreenshotSets`);
  let screenshotSet = setsData.data?.find(s => s.attributes.screenshotDisplayType === config.displayType);

  if (!screenshotSet) {
    console.log(`   → Création du set ${config.label}...`);
    const newSet = await asc(token, "POST", "/appScreenshotSets", {
      data: {
        type: "appScreenshotSets",
        attributes: { screenshotDisplayType: config.displayType },
        relationships: {
          appStoreVersionLocalization: {
            data: { type: "appStoreVersionLocalizations", id: localizationId },
          },
        },
      },
    });
    screenshotSet = newSet.data;
  }
  const screenshotSetId = screenshotSet.id;
  console.log(`   ✓ Set ID : ${screenshotSetId}`);

  // Supprimer les anciens
  const existingData = await asc(token, "GET", `/appScreenshotSets/${screenshotSetId}/appScreenshots`);
  for (const s of existingData.data || []) {
    try { await asc(token, "DELETE", `/appScreenshots/${s.id}`); } catch (_) {}
  }
  if (existingData.data?.length) console.log(`   ✓ ${existingData.data.length} anciens supprimés`);

  // Uploader
  if (!fs.existsSync(config.dir)) {
    console.log(`   ⚠ Dossier introuvable : ${config.dir}`);
    return;
  }

  const files = fs.readdirSync(config.dir).filter(f => f.endsWith(".png")).sort();
  console.log(`   📤 Upload de ${files.length} screenshots...`);

  for (const file of files) {
    process.stdout.write(`      ${file} ... `);
    try {
      await uploadScreenshot(token, screenshotSetId, path.join(config.dir, file));
      console.log("✓");
    } catch (err) {
      console.log(`⚠ ${err.message.split("\n")[0]}`);
    }
  }
}

async function main() {
  console.log("🔑 Lecture de la clé API...");
  const privateKey = fs.readFileSync(getKeyPath(), "utf8");
  const token = generateToken(privateKey);

  console.log("🔍 Recherche de la localisation fr-FR...");
  const locsData = await asc(token, "GET", `/appStoreVersions/${VERSION_ID}/appStoreVersionLocalizations`);
  const frLoc = locsData.data?.find(l => l.attributes.locale === "fr-FR");
  if (!frLoc) throw new Error("Localisation fr-FR introuvable");
  console.log(`   ✓ Localisation ID : ${frLoc.id}`);

  for (const config of DEVICE_CONFIGS) {
    await uploadDeviceScreenshots(token, frLoc.id, config);
  }

  console.log("\n✅ Tous les screenshots uploadés !");
  console.log("   → App Store Connect → Distribution → Version → Médias");
}

main().catch(err => {
  console.error("\n❌ Erreur :", err.message);
  process.exit(1);
});
