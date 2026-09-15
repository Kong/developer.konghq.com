import fs from "fs";
import path from "path";
import { parseAllDocuments } from "yaml";

// Reads every file in dir, keeps documents whose kind is CustomResourceDefinition,
// and indexes them by spec.names.kind, never by pluralising the file name
// (naive pluralisation breaks for kinds like MeshTLS and MeshRetry).
export function loadCrds(dir) {
  const crds = new Map();

  for (const file of fs.readdirSync(dir)) {
    const filePath = path.join(dir, file);
    if (!fs.statSync(filePath).isFile()) continue;

    const content = fs.readFileSync(filePath, "utf-8");
    for (const doc of parseAllDocuments(content)) {
      const parsed = doc.toJS();
      if (!parsed || parsed.kind !== "CustomResourceDefinition") continue;

      const kind = parsed.spec?.names?.kind;
      if (!kind) continue;

      const schema = parsed.spec?.versions?.[0]?.schema?.openAPIV3Schema;
      crds.set(kind, { schema });
    }
  }

  return crds;
}

// Injects additionalProperties: false into every object schema that declares
// properties, so unknown fields are rejected. Skips any node carrying
// x-kubernetes-preserve-unknown-fields, since that already declares the node
// permissive and any nested properties are illustrative, not exhaustive.
export function hardenSchema(schema) {
  if (schema === null || typeof schema !== "object") return schema;
  if (Array.isArray(schema)) return schema.map(hardenSchema);
  if (schema["x-kubernetes-preserve-unknown-fields"]) return schema;

  const hardened = { ...schema };

  if (hardened.properties) {
    const properties = {};
    for (const [key, value] of Object.entries(hardened.properties)) {
      properties[key] = hardenSchema(value);
    }
    hardened.properties = properties;
    hardened.additionalProperties = false;
  }

  if (hardened.items) {
    hardened.items = hardenSchema(hardened.items);
  }

  for (const key of ["oneOf", "anyOf", "allOf"]) {
    if (Array.isArray(hardened[key])) {
      hardened[key] = hardened[key].map(hardenSchema);
    }
  }

  return hardened;
}
