/**
 * generate_screenshots_landing.js
 *
 * Capture des visuels du SITE VITRINE depuis le build local de mentalite_site_web_flutter.
 * Scroll vers chaque section clé et capture 390×844 @3x (iPhone 6.9").
 *
 * ⚠️ CE SCRIPT NE PRODUIT PAS DES CAPTURES DE L'APP — il photographie le site vitrine.
 * Il écrit donc dans `screenshots_vitrine/`, JAMAIS dans `ios/fastlane/screenshots/`,
 * qui est le chemin d'envoi App Store lu par `upload_screenshots_asc.js`. C'est cette
 * confusion qui avait envoyé 24 captures de vitrine dans la fiche de l'app.
 * Pour les captures DE L'APP : `scripts/generate_screenshots.js`.
 *
 * Usage : node scripts/generate_screenshots_landing.js
 */

const { chromium } = require("playwright");
const path = require("path");
const fs = require("fs");
const http = require("http");

const BUILD_DIR = path.join(__dirname, "../../mentalite_site_web_flutter/build/web");
// Destination HORS du chemin d'envoi App Store (voir l'avertissement en tête de fichier).
const VITRINE_DIR = path.join(__dirname, "../screenshots_vitrine/fr-FR");
const OUTPUT_DIR = path.join(VITRINE_DIR, "iPhone 6.9\"");
const OUTPUT_DIR_65 = path.join(VITRINE_DIR, "iPhone 6.5\"");
const OUTPUT_DIR_61 = path.join(VITRINE_DIR, "iPhone 6.1\"");
const OUTPUT_DIR_55 = path.join(VITRINE_DIR, "iPhone 5.5\"");

// Garde-fou : refuser toute destination qui retomberait dans le chemin fastlane.
for (const dir of [OUTPUT_DIR, OUTPUT_DIR_65, OUTPUT_DIR_61, OUTPUT_DIR_55]) {
  if (path.resolve(dir).includes(path.join("ios", "fastlane", "screenshots"))) {
    console.error(`❌ Destination interdite (chemin d'envoi App Store) : ${dir}`);
    process.exit(1);
  }
}
const PORT = 8282;
const BASE_URL = `http://localhost:${PORT}`;

// Viewport iPhone — rendu à 390×844, scale ×3 → 1170×2532
const VIEWPORT = { width: 430, height: 932, deviceScaleFactor: 3 };

function startServer() {
  return new Promise((resolve, reject) => {
    const mime = {
      ".html": "text/html", ".js": "application/javascript",
      ".css": "text/css", ".png": "image/png", ".wasm": "application/wasm",
      ".json": "application/json", ".svg": "image/svg+xml",
      ".ico": "image/x-icon", ".woff2": "font/woff2", ".woff": "font/woff",
      ".ttf": "font/ttf",
    };
    const server = http.createServer((req, res) => {
      let filePath = path.join(BUILD_DIR, req.url.split("?")[0]);
      if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
        filePath = path.join(BUILD_DIR, "index.html");
      }
      const ext = path.extname(filePath);
      res.writeHead(200, { "Content-Type": mime[ext] || "application/octet-stream" });
      fs.createReadStream(filePath).pipe(res);
    });
    server.listen(PORT, () => resolve(server));
    server.on("error", reject);
  });
}

// Sections à capturer : [fichier, scrollY, délai_ms, description]
// Les Y sont calibrés pour le viewport 390px de large
const SHOTS = [
  ["01_hero.png",        0,    3000, "Hero — accroche + CTA"],
  ["02_constat.png",     900,  1500, "Le Constat — santé mentale pas un luxe"],
  ["03_profil.png",      2400, 1500, "Profil cognitif — scores QI"],
  ["04_exercices.png",   3300, 1500, "Les exercices — liste des exercices"],
  ["05_chat.png",        4200, 1500, "Accompagnement IA — espace d'écoute"],
  ["06_inscription.png", 6200, 1500, "Inscription — formulaire accès gratuit"],
];

// Scroll jusqu'à une position cumulée en envoyant de petits chunks wheel.
// Flutter web répond aux WheelEvent; on envoie des petits chunks pour éviter le throttling.
async function wheelScrollTo(page, totalDelta, cx, cy) {
  const chunk = 500;
  const count = Math.ceil(totalDelta / chunk);
  await page.mouse.move(cx, cy);
  for (let i = 0; i < count; i++) {
    await page.mouse.wheel(0, chunk);
    await page.waitForTimeout(30);
  }
  await page.waitForTimeout(1000); // Laisser Flutter finir l'animation
}

// Positions cumulées calibrées (px de wheel delta depuis le haut de page).
// Chaque screenshot recharge la page → positions indépendantes.
const SCROLL_TARGETS = {
  "01_hero.png":        0,
  "02_constat.png":     9000,   // Section01Conviction — "La santé mentale n'est pas un luxe"
  "03_profil.png":     27000,   // Section03Profile — profil cognitif + scores QI
  "04_exercices.png":  35000,   // Section04Tests — liste des exercices
  "05_chat.png":       52000,   // Section05Chat — espace d'écoute 24h/24
  "06_inscription.png":96000,   // FormSection — formulaire inscription
};

async function loadPage(page) {
  await page.goto(BASE_URL, { waitUntil: "networkidle", timeout: 30000 });
  await page.waitForTimeout(5000);
}

async function captureSections(page, outputDir, viewportWidth, viewportHeight) {
  fs.mkdirSync(outputDir, { recursive: true });

  const cx = Math.floor(viewportWidth / 2);
  const cy = Math.floor(viewportHeight / 2);

  const shots = [
    ["01_hero.png",        "Hero — accroche + CTA"],
    ["02_constat.png",     "Le Constat (sombre)"],
    ["03_profil.png",      "Profil cognitif + scores QI"],
    ["04_exercices.png",   "Les exercices"],
    ["05_chat.png",        "Accompagnement IA"],
    ["06_inscription.png", "Formulaire inscription"],
  ];

  for (const [filename, label] of shots) {
    process.stdout.write(`   📸 ${filename.replace(".png", "")} — ${label} ... `);

    // Recharger la page pour chaque screenshot (positions indépendantes)
    await loadPage(page);

    const target = SCROLL_TARGETS[filename];
    if (target > 0) {
      await wheelScrollTo(page, target, cx, cy);
    }

    await page.screenshot({ path: path.join(outputDir, filename), fullPage: false, type: "png" });
    console.log(`✓ (${(fs.statSync(path.join(outputDir, filename)).size / 1024).toFixed(0)} KB)`);
  }
}

async function main() {
  if (!fs.existsSync(BUILD_DIR)) {
    console.error(`❌ Build introuvable : ${BUILD_DIR}`);
    console.error("   → Lance d'abord : cd mentalite_site_web_flutter && flutter build web");
    process.exit(1);
  }

  console.log(`🌐 Serveur local → ${BASE_URL}`);
  const server = await startServer();

  console.log("🔧 Playwright headless...\n");
  const browser = await chromium.launch({
    headless: true,
    args: ["--no-sandbox", "--disable-setuid-sandbox", "--disable-web-security"],
  });

  // iPhone 6.9"
  console.log(`📱 iPhone 6.9" (${VIEWPORT.width}×${VIEWPORT.height} @${VIEWPORT.deviceScaleFactor}x)`);
  const ctx69 = await browser.newContext({
    viewport: { width: VIEWPORT.width, height: VIEWPORT.height },
    deviceScaleFactor: VIEWPORT.deviceScaleFactor,
    locale: "fr-FR",
    colorScheme: "light",
  });
  const page69 = await ctx69.newPage();
  await captureSections(page69, OUTPUT_DIR, VIEWPORT.width, VIEWPORT.height);
  await ctx69.close();

  // iPhone 6.5"
  console.log(`\n📱 iPhone 6.5" (414×896 @3x)`);
  const ctx65 = await browser.newContext({
    viewport: { width: 414, height: 896 },
    deviceScaleFactor: 3,
    locale: "fr-FR",
    colorScheme: "light",
  });
  const page65 = await ctx65.newPage();
  await captureSections(page65, OUTPUT_DIR_65, 414, 896);
  await ctx65.close();

  // iPhone 6.1" (393×852 @3x → 1179×2556 px)
  console.log(`\n📱 iPhone 6.1" (393×852 @3x)`);
  const ctx61 = await browser.newContext({
    viewport: { width: 393, height: 852 },
    deviceScaleFactor: 3,
    locale: "fr-FR",
    colorScheme: "light",
  });
  const page61 = await ctx61.newPage();
  await captureSections(page61, OUTPUT_DIR_61, 393, 852);
  await ctx61.close();

  // iPhone 5.5" (414×736 @3x → 1242×2208 px)
  console.log(`\n📱 iPhone 5.5" (414×736 @3x)`);
  const ctx55 = await browser.newContext({
    viewport: { width: 414, height: 736 },
    deviceScaleFactor: 3,
    locale: "fr-FR",
    colorScheme: "light",
  });
  const page55 = await ctx55.newPage();
  await captureSections(page55, OUTPUT_DIR_55, 414, 736);
  await ctx55.close();

  await browser.close();
  try { server.close(); } catch (_) {}

  // Vérification diversité
  console.log("\n📊 Vérification diversité des screenshots :");
  for (const dir of [OUTPUT_DIR, OUTPUT_DIR_65, OUTPUT_DIR_61, OUTPUT_DIR_55]) {
    const label = dir.includes("6.9") ? "iPhone 6.9\"" : "iPhone 6.5\"";
    const files = fs.readdirSync(dir).filter(f => f.endsWith(".png")).sort();
    const sizes = files.map(f => fs.statSync(path.join(dir, f)).size);
    const unique = new Set(sizes).size;
    console.log(`   ${label} : ${unique}/${files.length} tailles uniques ${unique === files.length ? "✅" : "⚠️ doublons possibles"}`);
  }

  console.log("\n✅ Terminé. Lance ensuite :");
  console.log("   node scripts/upload_screenshots_asc.js");
}

main().catch(err => {
  console.error("\n❌ Erreur :", err.message);
  process.exit(1);
});
