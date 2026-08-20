#!/usr/bin/env node

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import minimist from "minimist";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function replaceWordPreserveCase(text, pattern, replacement) {
  return text.replace(pattern, (match) => {
    if (match === match.toUpperCase()) {
      return replacement.toUpperCase();
    }
    if (match[0] === match[0].toUpperCase()) {
      return replacement[0].toUpperCase() + replacement.slice(1);
    }
    return replacement;
  });
}

function rewriteDescription(text) {
  let result = text;
  result = replaceWordPreserveCase(
    result,
    /\bplugins\b(?!-global)/gi,
    "policies",
  );
  result = replaceWordPreserveCase(
    result,
    /\bplugin\b(?!-global)/gi,
    "policy",
  );
  return result;
}

function processDescriptions(obj) {
  if (typeof obj !== "object" || obj === null) {
    return obj;
  }

  if (Array.isArray(obj)) {
    return obj.map((item) => processDescriptions(item));
  }

  const processed = { ...obj };

  for (const [key, value] of Object.entries(processed)) {
    if (key === "description" && typeof value === "string") {
      processed[key] = rewriteDescription(value);
    } else {
      processed[key] = processDescriptions(value);
    }
  }

  return processed;
}

(async function main() {
  const argv = minimist(process.argv.slice(2), {
    string: ["schemas-path"],
    alias: { s: "schemas-path" },
  });

  if (argv.help || (argv._.length < 1 && !argv["schemas-path"])) {
    console.error("Usage: node run.js <schemasPath>");
    console.error("       node run.js --schemas-path <path>");
    console.error("       node run.js -s <path>");
    console.error("");
    console.error("Examples:");
    console.error("  node run.js ./input-schemas");
    console.error("  node run.js --schemas-path ./input-schemas");
    console.error("  node run.js -s ./input-schemas");
    process.exit(1);
  }

  const schemasPath = argv["schemas-path"] || argv._[0];

  try {
    const absoluteSchemasPath = path.resolve(__dirname, schemasPath);

    if (!fs.existsSync(absoluteSchemasPath)) {
      throw new Error(`Schemas directory not found: ${absoluteSchemasPath}`);
    }

    const outputDir = path.resolve(
      __dirname,
      "../../app/_schemas/ai-gateway/policies",
    );

    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
      console.log(`Created output directory: ${outputDir}`);
    }

    const files = fs.readdirSync(absoluteSchemasPath);
    const jsonFiles = files.filter((file) => file.endsWith(".json"));

    if (jsonFiles.length === 0) {
      console.log("No JSON files found in the schemas directory.");
      return;
    }

    console.log(`Processing ${jsonFiles.length} JSON schema files...`);

    let hadErrors = false;

    for (const file of jsonFiles) {
      try {
        const inputFilePath = path.join(absoluteSchemasPath, file);
        const outputFilePath = path.join(outputDir, file);

        console.log(`Processing: ${file}`);

        const schemaContent = fs.readFileSync(inputFilePath, "utf8");
        const schema = JSON.parse(schemaContent);

        const processedSchema = processDescriptions(schema);

        fs.writeFileSync(
          outputFilePath,
          JSON.stringify(processedSchema, null, 2),
        );

        console.log(`Processed and saved: ${file} ✓`);
      } catch (error) {
        console.error(`Error processing file ${file}:`, error.message);
        hadErrors = true;
      }
    }

    console.log(`\nCompleted processing. Output saved to: ${outputDir}`);

    if (hadErrors) {
      process.exit(1);
    }
  } catch (error) {
    console.error("Error:", error.message);
    process.exit(1);
  }
})();
