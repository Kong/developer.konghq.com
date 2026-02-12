#!/usr/bin/env node

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import minimist from "minimist";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function processSchema(obj) {
  if (typeof obj !== "object" || obj === null) {
    return obj;
  }

  if (Array.isArray(obj)) {
    return obj.map((item) => processSchema(item));
  }

  const processed = { ...obj };

  if (
    processed["x-referenceable"] ||
    processed["additionalProperties"]?.["x-referenceable"]
  ) {
    const referenceableText =
      "\nThis field is [referenceable](/gateway/entities/vault/#how-do-i-reference-secrets-stored-in-a-vault).";

    if (processed.description) {
      if (!processed.description.includes(referenceableText)) {
        processed.description = `${processed.description} ${referenceableText}`;
      }
    } else {
      processed.description = referenceableText;
    }
  }

  if (processed["x-encrypted"]) {
    const encryptedText = "\nThis field is [encrypted](/gateway/keyring/).";

    if (processed.description) {
      if (!processed.description.includes(encryptedText)) {
        processed.description = `${processed.description} ${encryptedText}`;
      }
    } else {
      processed.description = encryptedText;
    }
  }

  if (processed.deprecation) {
    const deprecationText = `\nDeprecation notice: ${processed.deprecation.message}. It will be removed in ${processed.deprecation.removal_in_version}`;

    if (processed.description) {
      if (!processed.description.includes(deprecationText)) {
        processed.description = `${processed.description} ${deprecationText}`;
      }
    } else {
      processed.description = deprecationText;
    }
  }

  for (const [key, value] of Object.entries(processed)) {
    processed[key] = processSchema(value);
  }

  return processed;
}

(async function main() {
  const argv = minimist(process.argv.slice(2), {
    string: ["schemas-path", "version"],
  });

  if (
    argv.help ||
    (argv._.length < 2 && (!argv["schemas-path"] || !argv.version))
  ) {
    console.error("Usage: node run.js <schemasPath> <version>");
    console.error(
      "       node run.js --schemas-path <path> --version <version>",
    );
    console.error("       node run.js -s <path> -v <version>");
    console.error("");
    console.error("Examples:");
    console.error("  node run.js ./input-schemas 3.12");
    console.error(
      "  node run.js --schemas-path ./input-schemas --version 3.12",
    );
    console.error("  node run.js -s ./input-schemas -v 3.12");
    process.exit(1);
  }

  const schemasPath = argv["schemas-path"] || argv._[0];
  const version = argv.version || argv._[1];
  try {
    const absoluteSchemasPath = path.resolve(__dirname, schemasPath);

    if (!fs.existsSync(absoluteSchemasPath)) {
      throw new Error(`Schemas directory not found: ${absoluteSchemasPath}`);
    }

    const outputDir = path.resolve(
      __dirname,
      "../../app/_schemas/gateway/plugins",
      version,
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

    for (const file of jsonFiles) {
      try {
        const inputFilePath = path.join(absoluteSchemasPath, file);
        const outputFilePath = path.join(outputDir, file);

        console.log(`Processing: ${file}`);

        const schemaContent = fs.readFileSync(inputFilePath, "utf8");
        const schema = JSON.parse(schemaContent);

        const processedSchema = processSchema(schema);

        fs.writeFileSync(
          outputFilePath,
          JSON.stringify(processedSchema, null, 2),
        );

        console.log(`Processed and saved: ${file} ✓`);
      } catch (error) {
        console.error(`Error processing file ${file}:`, error.message);
      }
    }

    console.log(`\nCompleted processing. Output saved to: ${outputDir}`);
  } catch (error) {
    console.error("Error:", error.message);
    process.exit(1);
  }
})();
