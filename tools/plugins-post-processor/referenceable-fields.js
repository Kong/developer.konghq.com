#!/usr/bin/env node

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import minimist from "minimist";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function extractReferenceableFields(obj, basePath = "") {
  const referenceableFields = [];

  if (typeof obj !== "object" || obj === null) {
    return referenceableFields;
  }

  if (Array.isArray(obj)) {
    obj.forEach((item, index) => {
      const arrayPath = basePath ? `${basePath}[${index}]` : `[${index}]`;
      referenceableFields.push(...extractReferenceableFields(item, arrayPath));
    });
    return referenceableFields;
  }

  if (obj["x-referenceable"]) {
    if (basePath) {
      referenceableFields.push(basePath);
    }
  }

  if (obj.type === "object" && obj.additionalProperties?.["x-referenceable"]) {
    if (basePath) {
      referenceableFields.push(basePath);
    }
  }

  for (const [key, value] of Object.entries(obj)) {
    if (key.startsWith("x-") && key !== "x-referenceable") {
      continue;
    }
    if (
      [
        "description",
        "type",
        "default",
        "enum",
        "pattern",
        "format",
        "minimum",
        "maximum",
        "required",
      ].includes(key)
    ) {
      continue;
    }

    const newPath = basePath ? `${basePath}.${key}` : key;

    if (key === "properties" && typeof value === "object") {
      for (const [propKey, propValue] of Object.entries(value)) {
        const propPath = basePath ? `${basePath}.${propKey}` : propKey;
        referenceableFields.push(
          ...extractReferenceableFields(propValue, propPath),
        );
      }
    } else if (key === "items" && typeof value === "object") {
      referenceableFields.push(...extractReferenceableFields(value, basePath));
    } else if (typeof value === "object") {
      referenceableFields.push(...extractReferenceableFields(value, newPath));
    }
  }

  return referenceableFields;
}

function getPluginName(filename) {
  const name = filename.replace(/\.json$/, "");

  return name
    .replace(/([a-z0-9])([A-Z])/g, "$1-$2")
    .replace(/([A-Z])([A-Z][a-z])/g, "$1-$2")
    .toLowerCase();
}

(async function main() {
  const argv = minimist(process.argv.slice(2), {
    string: ["version"],
  });

  if (argv.help || (argv._.length < 1 && !argv.version)) {
    console.error("Usage: node referenceable-fields.js <version>");
    console.error("       node referenceable-fields.js --version <version>");
    console.error("       node referenceable-fields.js -v <version>");
    console.error("");
    process.exit(1);
  }

  const version = argv.version || argv._[0];

  try {
    const inputDir = path.resolve(
      __dirname,
      `../../app/_schemas/gateway/plugins/${version}`,
    );

    if (!fs.existsSync(inputDir)) {
      throw new Error(`Plugins schema directory not found: ${inputDir}`);
    }

    const outputDir = path.resolve(
      __dirname,
      "../../app/_data/plugins/referenceable_fields",
    );
    const outputFile = path.join(outputDir, `${version}.json`);

    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
      console.log(`Created output directory: ${outputDir}`);
    }

    const files = fs.readdirSync(inputDir);
    const jsonFiles = files.filter((file) => file.endsWith(".json"));

    if (jsonFiles.length === 0) {
      console.log("No JSON schema files found in the directory.");
      return;
    }

    console.log(
      `Processing ${jsonFiles.length} plugin schema files for version ${version}...`,
    );

    const referenceableFieldsData = {};

    for (const file of jsonFiles) {
      try {
        const filePath = path.join(inputDir, file);
        const pluginName = getPluginName(file);

        console.log(`Processing: ${file} -> ${pluginName}`);

        const schemaContent = fs.readFileSync(filePath, "utf8");
        const schema = JSON.parse(schemaContent);

        const referenceableFields = extractReferenceableFields(schema);
        if (referenceableFields.length > 0) {
          referenceableFieldsData[pluginName] = referenceableFields.sort();
          console.log(
            `  Found ${referenceableFields.length} referenceable fields`,
          );
        } else {
          console.log(`  No referenceable fields found`);
        }
      } catch (error) {
        console.error(`Error processing file ${file}:`, error.message);
      }
    }

    const sortedData = {};
    Object.keys(referenceableFieldsData)
      .sort()
      .forEach((key) => {
        sortedData[key] = referenceableFieldsData[key];
      });

    fs.writeFileSync(outputFile, JSON.stringify(sortedData, null, 2));

    console.log(
      `\nCompleted processing. Found ${
        Object.keys(sortedData).length
      } plugins with referenceable fields.`,
    );
    console.log(`Output saved to: ${outputFile}`);
  } catch (error) {
    console.error("Error:", error.message);
    process.exit(1);
  }
})();
