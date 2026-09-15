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
