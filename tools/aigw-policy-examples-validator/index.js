import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "../..");
export const SCHEMAS_DIR = path.join(ROOT, "app/_schemas/ai-gateway/policies");
export const EXAMPLES_GLOB = "app/_ai_gateway_policies/*/examples/*.{yaml,yml}";

export function buildSchemaMap(schemasDir = SCHEMAS_DIR) {
  const bySlug = {};
  for (const file of fs.readdirSync(schemasDir)) {
    if (!file.endsWith(".json")) continue;
    bySlug[file.replace(/\.json$/, "").toLowerCase()] = path.join(schemasDir, file);
  }
  return { schemasDir, bySlug };
}

export function schemaForFolder(schemaMap, folder) {
  const slug = path.basename(folder);
  const normalized = slug.replace(/-/g, "").toLowerCase();
  const schemaPath = schemaMap.bySlug[normalized];
  if (schemaPath) return { schemaPath };
  return {
    findings: [
      {
        instancePath: "/",
        message:
          `No schema for policy folder "${slug}": no file in ${schemaMap.schemasDir} ` +
          `matches "${normalized}.json" (case-insensitive, dashes stripped)`,
      },
    ],
  };
}

// Find every schema used as an `allOf` member. This has to be its own pass: a
// named schema is reached directly before anything reveals that an `allOf`
// composes it, so a single walk would close it before knowing better.
export function findAllOfMembers(node, members = new WeakSet(), seen = new WeakSet()) {
  if (node === null || typeof node !== "object") return members;
  if (seen.has(node)) return members;
  seen.add(node);

  if (Array.isArray(node)) {
    node.forEach((item) => findAllOfMembers(item, members, seen));
    return members;
  }

  for (const member of node.allOf || []) {
    if (member && typeof member === "object") members.add(member);
  }
  for (const value of Object.values(node)) {
    findAllOfMembers(value, members, seen);
  }
  return members;
}

// Close every object schema that declares `properties` and does not say what
// else it accepts, so misspelled config keys are rejected instead of silently
// passed by Ajv. A member of an `allOf` must stay open: its siblings carry the
// rest of the object's properties, so closing it makes every member reject the
// others' keys and nothing validates at all. `oneOf`/`anyOf` branches are whole
// alternatives to each other, so those are closed as normal.
export function closeObjectSchemas(node, members, visited = new WeakSet()) {
  if (node === null || typeof node !== "object") return;
  if (visited.has(node)) return;
  visited.add(node);

  if (Array.isArray(node)) {
    node.forEach((item) => closeObjectSchemas(item, members, visited));
    return;
  }

  const composes = node.allOf || node.oneOf || node.anyOf;
  if (
    node.properties &&
    node.additionalProperties === undefined &&
    !composes &&
    !members.has(node)
  ) {
    node.additionalProperties = false;
  }

  for (const value of Object.values(node)) {
    closeObjectSchemas(value, members, visited);
  }
}

// Generate a value the schema accepts for a ${...} template variable: the
// schema's own example, then its default, then its first enum value, then a
// safe value per type.
export function placeholderForSchema(fieldSchema) {
  if (!fieldSchema) return "__placeholder__";
  if (fieldSchema.example !== undefined) return fieldSchema.example;
  if (fieldSchema.default !== undefined) return fieldSchema.default;
  if (fieldSchema.enum && fieldSchema.enum.length > 0) {
    return fieldSchema.enum[0];
  }
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

export function schemaAllowsNull(fieldSchema) {
  if (!fieldSchema) return false;
  if (fieldSchema.type === "null") return true;
  if (Array.isArray(fieldSchema.type) && fieldSchema.type.includes("null")) {
    return true;
  }
  return false;
}

// Recursively replace ${...} template variables with schema-appropriate
// values, and strip nulls the schema does not allow. The resolved sub-schema
// is passed down through the recursion so we never re-walk from the root.
export function replaceVariables(obj, fieldSchema) {
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
