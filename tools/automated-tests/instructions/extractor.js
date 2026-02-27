import { chromium } from "playwright";
import fs from "fs/promises";
import path from "path";
import yaml from "js-yaml";

async function copyFromClipboard(page) {
  return await page.evaluate(() => navigator.clipboard.readText());
}

async function extractPrereqsBlocks(page) {
  // We extract instructions from codeblocks that have data-test-prereqs='block'.
  // As an alternative, the prereq (accordion-item) could have the data-test-prereqs set,
  // and we could extract all the codeblocks it contains.
  const instructions = [];
  const blocks = await page.locator("[data-test-prereqs]").all();

  for (const elem of blocks) {
    if (await elem.isVisible()) {
      const instruction = await elem.getAttribute("data-test-prereqs");

      if (instruction === "block") {
        const copy = await elem.locator(".copy-action");
        await copy.click();

        const copiedText = await copyFromClipboard(page);
        instructions.push(copiedText);
      } else {
        try {
          const json = JSON.parse(instruction);
          instructions.push(json);
        } catch (error) {
          console.error(
            "There was an error parsing the prereq instruction:",
            error,
          );
        }
      }
    }
  }
  return instructions;
}

async function extractPrereqs(page) {
  const blocks = [];
  // Handle the accordion gracefully, we need to click on each item (visible ones only).
  const [_prereq, ...prerequisites] = await page
    .locator('[data-test-id="prereqs"] > *')
    .all();

  for (const prereq of prerequisites) {
    if (await prereq.isVisible()) {
      const trigger = await prereq.locator(".accordion-trigger");
      if (prerequisites.length >= 1) {
        await trigger.click();
      }
    }
    const extractedBlocks = await extractPrereqsBlocks(page);
    blocks.push(...extractedBlocks);
  }

  return { blocks };
}

async function extractCleanup(page) {
  const instructions = [];
  const blocks = await page.locator("[data-test-cleanup='block']").all();

  for (const elem of blocks) {
    if (await elem.isVisible()) {
      const copy = await elem.locator(".copy-action");
      await copy.click();

      const copiedText = await copyFromClipboard(page);
      instructions.push(copiedText);
    }
  }
  return instructions;
}

async function extractSetup(page) {
  // Fetch all elements that have data-test-setup and copy its value.
  const instructions = [];

  const elem = await page
    .locator(
      ".prerequisites > [data-deployment-topology][data-test-setup]:not(.hidden),.prerequisites > :not(.hidden) [data-test-setup]",
    )
    .first();
  const instruction = await elem.getAttribute("data-test-setup");

  try {
    const json = JSON.parse(instruction);
    instructions.push(json);
  } catch (error) {
    // Not a json, for products/platforms that don't have versions.
    instructions.push(instruction);
  }

  return instructions;
}

async function extractSteps(page) {
  const instructions = [];
  const steps = await page.locator("[data-test-step]").all();

  for (const elem of steps) {
    if (await elem.isVisible()) {
      const step = await elem.evaluate((el) => el.dataset.testStep);

      if (step === "block") {
        // copy code block
        const copy = await elem.locator(".copy-action");
        await copy.click();

        const copiedText = await copyFromClipboard(page);
        instructions.push(copiedText);
      } else {
        // validation-type step
        const parsedInstruction = JSON.parse(step);

        instructions.push(parsedInstruction);
      }
    }
  }
  return instructions;
}

function deriveProduct(setup, products) {
  // The setup config tells us the product:
  // - Object like {"gateway": "3.9"} -> product is the key (e.g., "gateway")
  // - String like "operator" -> product is the string itself
  // - String like "konnect" -> product must be derived from the products list
  const setupEntry = setup[0];
  if (typeof setupEntry === "object") {
    // e.g., {"gateway": "3.9"} -> "gateway"
    return Object.keys(setupEntry)[0];
  }
  // String value
  if (setupEntry === "konnect") {
    // For konnect, determine the product from the products list
    if (products.includes("ai-gateway")) {
      return "ai-gateway";
    }
    if (products.includes("event-gateway")) {
      return "event-gateway";
    }
    return "gateway";
  }
  // e.g., "operator"
  return setupEntry;
}

async function writeInstructionsToFile(url, config, platform, product, instructions) {
  const instructionsFile = path.join(
    config.instructionsDir,
    url.pathname,
    platform,
    `${product}.yaml`,
  );
  const instructionsDir = path.dirname(instructionsFile);
  await fs.mkdir(instructionsDir, { recursive: true });

  await fs.writeFile(instructionsFile, yaml.dump(instructions), "utf-8");

  return instructionsFile;
}

export async function extractInstructionsFromURL(uri, config, context) {
  const url = new URL(uri);
  let timeout = 0;
  const page = await context.newPage();

  try {
    console.log(`Extracting instructions from: ${url}`);
    await page.goto(url.toString(), { waitUntil: "domcontentloaded" });

    const productsString = await page
      .locator("[data-test-products]")
      .getAttribute("data-test-products");

    const products = productsString
      .split(",")
      .map((item) => item.trim())
      .filter((item) => item !== "");

    let worksOn = await page
      .locator('meta[name="algolia:works_on"]')
      .getAttribute("content");

    const platforms = worksOn.split(",").sort();

    for (const platform of platforms) {
      const title = await page.locator("h1").textContent();
      const howToUrl = `${config.productionUrl}${url.pathname}`;

      const toggleSwitch = await page.locator("aside .switch__slider");

      if ((await toggleSwitch.count()) > 0) {
        const option = page.locator(`aside .switch input[value="${platform}"]`);
        if (!(await option.isChecked())) {
          await page.locator("aside .switch__slider").click();
        }
        await page.locator(`aside .switch input[value="${platform}"]`).check();
      }

      const name = `[${title}](${howToUrl}) [${platform}]`;
      const setup = await extractSetup(page);
      const product = deriveProduct(setup, products);
      const prereqs = await extractPrereqs(page);
      const steps = await extractSteps(page);
      const cleanup = await extractCleanup(page);
      const instructionsFile = await writeInstructionsToFile(
        url,
        config,
        platform,
        product,
        {
          name,
          setup,
          products,
          prereqs,
          steps,
          cleanup,
        },
      );

      console.log(
        `  Instructions extracted successfully to ${instructionsFile}`,
      );

      // On some machines, we need to wait before extracting the instructions
      if (process.env.AUTOMATED_TESTS_EXTRACTION_TIMEOUT) {
        timeout = parseInt(process.env.AUTOMATED_TESTS_EXTRACTION_TIMEOUT, 10);
      }
      const promise = new Promise((resolve) => {
        setTimeout(() => {
          resolve();
        }, timeout);
      });
      await promise;
    }
  } catch (error) {
    console.error("There was an error extracting the instructions:", error);
  } finally {
    await page.close();
  }
}

export async function generateInstructionFiles(urlsToTest, config) {
  const browser = await chromium.launch({
    args: [
      "--no-sandbox",
      "--disable-setuid-sandbox",
      "--enable-clipboard",
      "--disable-web-security",
      "--disable-features=VizDisplayCompositor",
    ],
  });

  try {
    const context = await browser.newContext({
      permissions: ["clipboard-read", "clipboard-write"],
      origin: new URL(config.baseUrl).origin,
    });

    for (const uri of urlsToTest) {
      await extractInstructionsFromURL(uri, config, context);
    }
  } catch (error) {
    throw error;
  } finally {
    browser.close();
  }
}
