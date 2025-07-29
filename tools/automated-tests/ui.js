import playwright from "playwright";
import yaml from "js-yaml";
import * as fs from "fs";
import * as path from "path";
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export async function launchBrowser() {
  try {
    const browser = await playwright.chromium.launch({
      args: ["--no-sandbox", "--disable-setuid-sandbox"],
      headless: true
    });
    return browser;
  } catch (error) {
    throw error;
  }
}

(async function main() {

  const baseUrl = 'http://localhost:8002';

  const browser = await launchBrowser();

  const job = yaml.load(fs.readFileSync(path.join(__dirname, 'input_ui/demo/gateway.yml'), 'utf8'));
  const page = await browser.newPage();
  for (const step of job.steps) {
    console.log(step)
    if (step.navigate) {
      await page.goto(baseUrl + step.navigate);
    }

    if (step.fill) {
      const x = await page.locator(step.element, { hasText: step.label }).last();
      const forAttr = await x.getAttribute("for");
      const field = await page.locator('#' + forAttr);
      await field.fill(step.fill)
    }

    if (step.action) {
      const x = await page.locator(step.element, { hasText: step.text }).last();
      await x.click();
    }

    await new Promise(resolve => setTimeout(resolve, 1000));
  }
  await browser.close();
})();
