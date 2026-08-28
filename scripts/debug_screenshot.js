const { chromium } = require("playwright");

async function debug() {
  const browser = await chromium.launch({
    headless: false,
    args: ["--no-sandbox", "--disable-setuid-sandbox", "--disable-web-security"],
  });
  
  const context = await browser.newContext({
    viewport: { width: 430, height: 932 },
    deviceScaleFactor: 3,
    locale: "fr-FR",
    colorScheme: "light",
  });
  
  const page = await context.newPage();
  
  const messages = [];
  page.on("console", msg => messages.push(`[${msg.type()}] ${msg.text()}`));
  page.on("pageerror", err => messages.push(`[PAGEERROR] ${err.message}`));
  
  console.log("Navigating to home...");
  await page.goto("http://localhost:8181/home", { waitUntil: "networkidle", timeout: 30000 });
  await page.waitForTimeout(5000);
  
  console.log("\n=== Console messages ===");
  messages.slice(0, 40).forEach(m => console.log(m));
  
  console.log("\n=== Page title:", await page.title());
  
  // Check if flutter canvas exists
  const canvasExists = await page.evaluate(() => !!document.querySelector('canvas'));
  console.log("Canvas element exists:", canvasExists);
  
  const bodyHTML = await page.evaluate(() => document.body.innerHTML.substring(0, 500));
  console.log("Body HTML:", bodyHTML);
  
  await page.screenshot({ path: "/tmp/debug.png", fullPage: false });
  console.log("\nScreenshot saved");
  
  await browser.close();
}

debug().catch(console.error);
