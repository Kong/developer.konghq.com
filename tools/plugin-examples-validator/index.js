import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import fg from "fast-glob";
import YAML from "yaml";
import Ajv from "ajv";
import addFormats from "ajv-formats";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "../..");
const SCHEMAS_DIR = path.join(ROOT, "app/_schemas/gateway/plugins");
const EXAMPLES_GLOB = "app/_kong_plugins/*/examples/*.yaml";

function findLatestSchemaVersion() {
  const dirs = fs
    .readdirSync(SCHEMAS_DIR)
    .filter((d) => fs.statSync(path.join(SCHEMAS_DIR, d)).isDirectory())
    .sort((a, b) => {
      const pa = a.split(".").map(Number);
      const pb = b.split(".").map(Number);
      for (let i = 0; i < Math.max(pa.length, pb.length); i++) {
        const diff = (pa[i] || 0) - (pb[i] || 0);
        if (diff !== 0) return diff;
      }
      return 0;
    });
  return dirs[dirs.length - 1];
}

// Build a case-insensitive lookup map: lowercased name -> { filePath }
// configSchema and validateFn are populated lazily via loadSchema().
function buildSchemaMap(schemaDir) {
  const files = fs.readdirSync(schemaDir);
  const map = {};
  for (const file of files) {
    if (file.endsWith(".json")) {
      const name = file.replace(".json", "");
      map[name.toLowerCase()] = { filePath: path.join(schemaDir, file) };
    }
  }
  return map;
}

// Generate a type-appropriate placeholder for a schema field.
// Uses `default` if available, then first `enum` value, otherwise a safe value per type.
function placeholderForSchema(fieldSchema) {
  if (!fieldSchema) return "__placeholder__";
  if (fieldSchema.default !== undefined) return fieldSchema.default;
  if (fieldSchema.enum && fieldSchema.enum.length > 0)
    return fieldSchema.enum[0];
  switch (fieldSchema.type) {
    case "number":
    case "integer":
      return 0;
    case "boolean":
      return false;
    case "array":
      return [];
    case "object":
      return {};
    default:
      return "__placeholder__";
  }
}

// Load and cache the parsed schema, config sub-schema, and compiled validator for a plugin.
function loadSchema(entry, ajv) {
  if (!entry.loaded) {
    entry.loaded = true;
    const schema = JSON.parse(fs.readFileSync(entry.filePath, "utf-8"));
    entry.configSchema = schema.properties && schema.properties.config;
    if (entry.configSchema) {
      entry.validateFn = ajv.compile(entry.configSchema);
    }
  }
  return entry;
}

function schemaAllowsNull(fieldSchema) {
  if (!fieldSchema) return false;
  if (fieldSchema.type === "null") return true;
  if (Array.isArray(fieldSchema.type) && fieldSchema.type.includes("null"))
    return true;
  return false;
}

// Recursively replace ${...} template variables with schema-appropriate values.
// Passes the resolved sub-schema down through the recursion so we never re-walk from root.
// Also strips null values when the schema doesn't allow null for that field.
function replaceVariables(obj, fieldSchema) {
  if (typeof obj === "string") {
    if (/\$\{[^}]+\}/.test(obj)) {
      return placeholderForSchema(fieldSchema);
    }
    return obj;
  }
  if (Array.isArray(obj)) {
    const itemSchema = fieldSchema && fieldSchema.items;
    return obj.map((item) => replaceVariables(item, itemSchema));
  }
  if (obj !== null && typeof obj === "object") {
    const props = fieldSchema && fieldSchema.properties;
    const result = {};
    for (const [key, value] of Object.entries(obj)) {
      const propSchema = props && props[key];
      if (value === null && !schemaAllowsNull(propSchema)) continue;
      result[key] = replaceVariables(value, propSchema);
    }
    return result;
  }
  return obj;
}

async function validate() {
  const version = findLatestSchemaVersion();
  console.log(`Using schema version: ${version}`);

  const schemaDir = path.join(SCHEMAS_DIR, version);
  const schemaMap = buildSchemaMap(schemaDir);

  const exampleFiles = await fg(EXAMPLES_GLOB, { cwd: ROOT });
  console.log(`Found ${exampleFiles.length} example files\n`);

  const ajv = new Ajv({ allErrors: true, strict: false });
  addFormats(ajv);

  const errors = [];
  let skipped = 0;

  for (const filePath of exampleFiles) {
    const fullPath = path.join(ROOT, filePath);
    const content = fs.readFileSync(fullPath, "utf-8");
    let parsed;
    try {
      parsed = YAML.parse(content, { uniqueKeys: false });
    } catch (e) {
      console.log(`SKIP: YAML parse error in ${filePath}: ${e.message}`);
      skipped++;
      continue;
    }

    if (!parsed || !parsed.config) {
      continue;
    }

    // Extract plugin slug from path: app/_kong_plugins/<slug>/examples/...
    const slug = filePath.split("/")[2];
    const lookupKey = slug.replace(/-/g, "");

    const entry = schemaMap[lookupKey];
    if (!entry) {
      console.log(`SKIP: No schema found for "${slug}"`);
      skipped++;
      continue;
    }

    loadSchema(entry, ajv);
    if (!entry.configSchema) {
      console.log(`SKIP: No properties.config in schema for "${slug}"`);
      skipped++;
      continue;
    }

    // config can be an object or an array of objects (multi-route examples)
    const configs = Array.isArray(parsed.config)
      ? parsed.config.map((c, i) => ({ config: c, label: `[${i}]` }))
      : [{ config: parsed.config, label: "" }];

    const fileErrors = [];
    for (const { config: rawConfig, label } of configs) {
      const config = replaceVariables(rawConfig, entry.configSchema);

      const valid = entry.validateFn(config);

      if (!valid) {
        for (const err of entry.validateFn.errors) {
          err.instancePath = label + (err.instancePath || "");
        }
        fileErrors.push(...entry.validateFn.errors);
      }
    }

    if (fileErrors.length > 0) {
      errors.push({ file: filePath, errors: fileErrors });
    }
  }

  console.log(`Skipped: ${skipped}`);
  console.log(`Errors: ${errors.length}\n`);

  if (errors.length > 0) {
    for (const { file, errors: errs } of errors) {
      console.log(`--- ${file} ---`);
      for (const err of errs) {
        console.log(`  ${err.instancePath || "/"}: ${err.message}`);
        if (err.params) {
          console.log(`    ${JSON.stringify(err.params)}`);
        }
      }
      console.log();
    }
    process.exit(1);
  }

  console.log("All plugin examples are valid.");
}

export default validate;

validate().catch((err) => {
  console.error(err);
  process.exit(1);
});
