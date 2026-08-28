/**
 * generate_screenshots.js
 *
 * Génère les screenshots App Store en naviguant DANS l'app.
 *
 * ⚠️ DEUX PIÈGES CORRIGÉS LE 2026-08-29 (chantier lexique, LOT U) :
 *
 * 1. L'app est en ROUTAGE PAR HASH (`/#/home`), pas par chemin. `goto('/home')`
 *    ne changeait donc PAS de route : l'app démarrait sur le splash, puis la
 *    porte du splash redirigeait vers `/#/register`. D'où `01_accueil` = splash
 *    et `02_evaluation` = écran de connexion par token.
 * 2. `waitUntil:"networkidle"` se déclenche AVANT que Flutter ait fini de
 *    peindre : on photographiait un écran transitoire. On attend désormais un
 *    TEXTE RÉEL de l'écran visé (`EXPECT`), jamais le réseau.
 *
 * Conséquence : une seule charge de page, la sémantique Flutter activée une
 * fois (elle rend le texte lisible dans le DOM), puis navigation par hash —
 * qui ne recharge pas la page et ne perd donc pas la sémantique.
 *
 * Usage : node scripts/generate_screenshots.js
 */

const { chromium } = require("playwright");
const path = require("path");
const fs = require("fs");
const http = require("http");

const BUILD_DIR = path.join(__dirname, "../build/web");
const PORT = 8181;
const BASE_URL = `http://localhost:${PORT}`;

const DEVICES = [
  {
    name: 'iPhone 6.9"',
    dir: path.join(__dirname, '../ios/fastlane/screenshots/fr-FR/iPhone 6.9"'),
    viewport: { width: 390, height: 844, deviceScaleFactor: 3 },
  },
  {
    name: 'iPhone 6.5"',
    dir: path.join(__dirname, '../ios/fastlane/screenshots/fr-FR/iPhone 6.5"'),
    viewport: { width: 414, height: 896, deviceScaleFactor: 3 },
  },
];

function startServer() {
  return new Promise((resolve, reject) => {
    const mime = {
      ".html": "text/html", ".js": "application/javascript",
      ".css": "text/css", ".png": "image/png", ".wasm": "application/wasm",
      ".json": "application/json", ".svg": "image/svg+xml",
      ".ico": "image/x-icon", ".woff2": "font/woff2",
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

/// Attend que le moteur Flutter ait monté sa vue, puis active l'arbre
/// sémantique : sans lui, `document.body.innerText` reste vide (rendu canvas)
/// et il devient impossible d'attendre autre chose que le réseau.
async function bootFlutter(page, timeout = 60000) {
  await page.waitForSelector("flt-glass-pane, flutter-view", { timeout });
  const placeholder = await page.$("flt-semantics-placeholder");
  if (placeholder) {
    // Le placeholder est hors viewport : un vrai clic échoue, on dispatche.
    await placeholder.dispatchEvent("click");
  }
  await page.waitForTimeout(2500);
}

/// Attend qu'un TEXTE réellement affiché apparaisse — la seule preuve fiable
/// que l'écran visé est peint. Remplace `networkidle`, qui mentait.
async function waitForScreen(page, expected, timeout = 45000) {
  await page.waitForFunction(
    (needle) => (document.body.innerText || "").includes(needle),
    expected,
    { timeout },
  );
  await page.waitForTimeout(1200); // laisser les animations se poser
}

async function capture(page, outputPath, label) {
  await page.addStyleTag({
    content: `* { cursor: none !important; caret-color: transparent !important; } ::-webkit-scrollbar { display: none !important; }`
  });
  await page.screenshot({ path: outputPath, fullPage: false, type: "png" });
  const size = fs.statSync(outputPath).size;
  console.log(`   ✓ ${label} (${(size / 1024).toFixed(0)} KB)`);
}

async function generateForDevice(browser, device) {
  fs.mkdirSync(device.dir, { recursive: true });

  console.log(`\n📱 ${device.name} (${device.viewport.width}×${device.viewport.height} @${device.viewport.deviceScaleFactor}x)`);

  const context = await browser.newContext({
    viewport: { width: device.viewport.width, height: device.viewport.height },
    deviceScaleFactor: device.viewport.deviceScaleFactor,
    locale: "fr-FR",
    colorScheme: "light",
    // ⚠️ PAS d'user-agent iPhone ici, volontairement. Dès que Flutter détecte
    // la plateforme iOS, il n'expose plus son arbre sémantique dans le DOM en
    // headless (vérifié : 5 stratégies d'activation, 0 nœud sémantique) — on
    // perdrait l'attente sur un texte réel, qui est justement ce qui garantit
    // qu'on photographie le bon écran. La plateforme détectée ne change ni les
    // dimensions (390×844 @3x) ni le rendu : Flutter peint sa propre UI.
  });

  const page = await context.newPage();
  await page.route("**/(analytics|tracking|gtag|facebook|sentry)**", r => r.abort());

  // Une seule charge de page : la sémantique survit aux changements de hash,
  // pas à un rechargement complet.
  await page.goto(`${BASE_URL}/`, { waitUntil: "domcontentloaded", timeout: 30000 });
  await bootFlutter(page);

  // Chaque écran : route en HASH + un texte réellement affiché qui prouve
  // qu'on photographie le bon écran. Si le texte n'apparaît pas, le script
  // échoue — plutôt qu'une capture muette du mauvais écran.
  const SHOTS = [
    { file: "01_accueil.png",    label: "Accueil",          route: "/#/home",                        expect: "Commencer une évaluation" },
    { file: "02_evaluation.png", label: "Intro évaluation", route: "/#/assessment",                  expect: "DOMAINES MESURÉS" },
    { file: "03_matrices.png",   label: "Matrices",         route: "/#/test/matrices?level=medium",  expect: "Matrices Progressives" },
    { file: "04_cubes.png",      label: "Cubes",            route: "/#/test/cubes?level=medium",     expect: "Reproduisez le pattern" },
    { file: "05_memoire.png",    label: "Suites de chiffres", route: "/#/test/digit-span",           expect: "Suites de chiffres" },
    { file: "06_chat.png",       label: "Assistant IA",     route: "/#/chat",                        expect: "Nouvelle conversation" },
  ];

  for (let i = 0; i < SHOTS.length; i++) {
    const shot = SHOTS[i];
    console.log(`   📸 ${i + 1}/${SHOTS.length} ${shot.label}...`);
    await page.goto(`${BASE_URL}${shot.route}`, { waitUntil: "domcontentloaded", timeout: 30000 });
    try {
      await waitForScreen(page, shot.expect);
    } catch (e) {
      const seen = (await page.evaluate(() => (document.body.innerText || "").trim().replace(/\s+/g, " ").slice(0, 200)));
      throw new Error(
        `Écran "${shot.label}" jamais peint : texte attendu « ${shot.expect} » absent.\n` +
        `   Texte réellement affiché : « ${seen} »`,
      );
    }
    await capture(page, path.join(device.dir, shot.file), shot.label);
  }

  await context.close();
}

// Vérifier que les screens sont bien différents
function checkDiversity(dir) {
  const files = fs.readdirSync(dir).filter(f => f.endsWith('.png'));
  const sizes = files.map(f => fs.statSync(path.join(dir, f)).size);
  const unique = new Set(sizes).size;
  const allSame = unique === 1;
  if (allSame) {
    console.log(`   ⚠️  ATTENTION : tous les ${files.length} screenshots ont la même taille (${sizes[0]} bytes) — probablement tous identiques !`);
  } else {
    console.log(`   ✅ ${unique} tailles différentes sur ${files.length} fichiers — bonne diversité`);
  }
}

async function main() {
  console.log("🌐 Démarrage du serveur local...");
  const server = await startServer();

  console.log("🔧 Lancement Playwright (headless)...");
  const browser = await chromium.launch({
    headless: true,
    args: ["--no-sandbox", "--disable-setuid-sandbox", "--disable-web-security"],
  });

  for (const device of DEVICES) {
    await generateForDevice(browser, device);
    checkDiversity(device.dir);
  }

  await browser.close();
  try { server.close(); } catch (_) {}

  console.log("\n✅ Génération terminée.");
}

main().catch(err => {
  console.error("\n❌ Erreur fatale :", err.message);
  process.exit(1);
});
