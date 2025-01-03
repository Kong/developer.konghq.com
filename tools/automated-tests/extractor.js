import puppeteer from "puppeteer";
import fs from "fs/promises";
import debug from "debug";
import path from "path";
import yaml from "js-yaml";

const log = debug("extractor");

async function copyFromClipboard(page) {
  const copiedText = await page.evaluate(async () => {
    const instruction = await navigator.clipboard.readText();
    return instruction;
  });

  return copiedText;
}

async function extractPrereqsBlocks(page) {
  // We extract instructions from codeblocks that have data-test-prereqs='block'.
  // As an alternative, the prereq (accordion-item) could have the data-test-prereqs set,
  // and we could extract all the codeblocks it contains.
  const instructions = [];
  const blocks = await page.$$("[data-test-prereqs='block']");

  for (const elem of blocks) {
    if (await elem.isVisible()) {
      const copy = await elem.$(".copy-action");
      await copy.evaluate((e) => e.click());

      const copiedText = await copyFromClipboard(page);
      instructions.push(copiedText);
    }
    await elem.dispose();
  }
  return instructions;
}

async function extractPrereqs(page) {
  const blocks = [];
  // Handle the accordion gracefully, we need to click on each item (visible ones only).
  const [_prereq, ...prerequisites] = await page.$$(
    '[data-test-id="prereqs"] > *'
  );

  let extractedBlocks = await extractPrereqsBlocks(page);
  blocks.push(...extractedBlocks);

  for (const prereq of prerequisites) {
    if (await prereq.isVisible) {
      const trigger = await prereq.$(".accordion-trigger");
      await trigger.evaluate((e) => e.click());
    }
    extractedBlocks = await extractPrereqsBlocks(page);
    blocks.push(...extractedBlocks);
    await prereq.dispose();
  }

  return { blocks };
}

async function extractSetup(config, page) {
  // Fetch all elements that have data-test-setup and copy its value.
  // Check the config for specific values.
  const instructions = [];
  const setups = await page.$$("[data-test-setup]");

  for (const elem of setups) {
    if (await elem.isVisible()) {
      const instruction = await elem.evaluate((el) => el.dataset.testSetup);
      let key;
      try {
        const json = JSON.parse(instruction);
        key = Object.keys(json)[0];

        if (config.versions[key]) {
          // Overwrite the version with env variable
          instructions.push({ [key]: config.versions[key] });
        } else {
          instructions.push(json);
        }
      } catch (error) {
        // Not a json, for products/platforms that don't have versions.
        instructions.push(instruction);
      }
    }
    await elem.dispose();
  }

  return instructions;
}

async function extractSteps(page) {
  const instructions = [];
  const steps = await page.$$("[data-test-step]");

  for (const elem of steps) {
    if (await elem.isVisible()) {
      const copy = await elem.$(".copy-action");
      await copy.evaluate((e) => e.click());

      const copiedText = await copyFromClipboard(page);
      instructions.push(copiedText);
    }
    await elem.dispose();
  }
  return instructions;
}

async function extractValidations(page) {
  const instructions = [];
  const steps = await page.$$("[data-test-validate]");

  for (const elem of steps) {
    if (await elem.isVisible()) {
      const instruction = await elem.evaluate((el) => el.dataset.testValidate);
      const parsedInstruction = JSON.parse(instruction);

      instructions.push(parsedInstruction);
    }
    await elem.dispose();
  }
  return instructions;
}

async function extractCleanup(page) {
  const instructions = [];

  return instructions;
}

async function writeInstrctionsToFile(url, config, instructions) {
  const instructionsFile = path.join(
    config.outputDir,
    url.pathname.slice(1, -1) + ".yaml"
  );
  const outputDir = path.dirname(instructionsFile);
  await fs.mkdir(outputDir, { recursive: true });

  await fs.writeFile(instructionsFile, yaml.dump(instructions), "utf-8");

  return instructionsFile;
}

async function extractInstructions(uri, config) {
  const browser = await puppeteer.launch();
  const url = new URL(uri);

  await browser
    .defaultBrowserContext()
    .overridePermissions(url.origin, ["clipboard-read"]);

  const page = await browser.newPage();

  try {
    log(`Extracting instructions from: ${url}`);
    await page.goto(url, { waitUntil: "domcontentloaded" });

    await page.select("select#deployment-topology-switch", config.platform);

    const setup = await extractSetup(config, page);
    const prereqs = await extractPrereqs(page);
    const steps = await extractSteps(page);
    const validations = await extractValidations(page);
    const cleanup = await extractCleanup(page);
    const instructionsFile = await writeInstrctionsToFile(url, config, {
      setup,
      prereqs,
      steps,
      validations,
      cleanup,
    });

    log(`Instructions extracted successfully to ${instructionsFile}`);
  } catch (error) {
    log("There was an error extracting the instructions:", error);
  } finally {
    await browser.close();
  }
}

// TODO: extract the following functions from this file
async function loadConfig() {
  const configFile = "./config/setup.yaml";

  const fileContent = await fs.readFile(configFile, "utf8");
  const config = yaml.load(fileContent);
  config.versions = {};

  const versionEnvVars = Object.keys(process.env)
    .filter((key) => key.startsWith("TEST_") && key.endsWith("_VERSION"))
    .reduce((acc, key) => {
      acc[key] = process.env[key];
      return acc;
    }, {});

  // Overwrite config values with environment variables
  Object.keys(config).forEach((key) => {
    const envKey = key.toUpperCase();
    if (process.env[envKey]) {
      config[key] = process.env[envKey];
    }
  });

  // Set versions based on `TEST_<product>_VERSION` env variables
  // e.g. TEST_GATEWAY_VERSION='3.5'
  for (const envVar in versionEnvVars) {
    const key = envVar.replace(/^TEST_|_VERSION$/g, "").toLowerCase();
    config.versions[key] = process.env[envVar];
  }

  return config;
}

(async function main() {
  const config = await loadConfig();
  log(`Config: ${JSON.stringify(config)}`);

  // TODO: toggle config.platform, i.e. konnect or gateway
  extractInstructions(
    "http://localhost:8888/how-to/add-rate-limiting-for-a-consumer-with-kong-gateway/",
    config
  );
})();
