import { hardenSchema } from "./crds.js";

function escapeSegment(segment) {
  return String(segment).replace(/~/g, "~0").replace(/\//g, "~1");
}

export function findNullValues(value, pointer = "") {
  if (value === null || typeof value !== "object") return [];

  const entries = Array.isArray(value)
    ? value.map((item, index) => [index, item])
    : Object.entries(value);

  const findings = [];
  for (const [key, child] of entries) {
    const childPointer = `${pointer}/${escapeSegment(key)}`;
    if (child === null) {
      findings.push(childPointer);
    } else {
      findings.push(...findNullValues(child, childPointer));
    }
  }
  return findings;
}

const MARKER_NAME_PATTERN = /^_/;
const MARKER_NAMES = new Set(["name_uni", "name_kube"]);

// Returns a JSON pointer for every renderer marker key that survived into the
// published output: keys matching `_*`, plus `name_uni` and `name_kube`.
export function findMarkerFields(value, pointer = "") {
  if (value === null || typeof value !== "object") return [];

  if (Array.isArray(value)) {
    return value.flatMap((item, index) =>
      findMarkerFields(item, `${pointer}/${index}`),
    );
  }

  const findings = [];
  for (const [key, child] of Object.entries(value)) {
    const childPointer = `${pointer}/${escapeSegment(key)}`;
    if (MARKER_NAME_PATTERN.test(key) || MARKER_NAMES.has(key)) {
      findings.push(childPointer);
    }
    findings.push(...findMarkerFields(child, childPointer));
  }
  return findings;
}

function formatAjvError(err) {
  if (err.keyword === "additionalProperties") {
    return `must NOT have additional property "${err.params.additionalProperty}"`;
  }
  if (err.keyword === "required") {
    return `must have required property "${err.params.missingProperty}"`;
  }
  return err.message;
}

// Validates a block against the CRD schema for its kind: a kubernetes block
// is a whole manifest, validated against the whole hardened schema; a
// universal block carries the spec at its top level, validated against the
// hardened schema's spec subtree.
export function checkSchema(block, crds, ajv) {
  const { panel, value } = block;
  const kind = panel === "kubernetes" ? value?.kind : value?.type;
  const crd = crds.get(kind);

  if (!crd) {
    return {
      findings: [{ pointer: "/", message: `No CRD defines kind "${kind}"` }],
      hasCoverage: false,
    };
  }

  const specSchema = crd.schema?.properties?.spec;
  const hasCoverage = !specSchema?.["x-kubernetes-preserve-unknown-fields"];
  if (!hasCoverage) {
    return { findings: [], hasCoverage: false };
  }

  if (!crd.validateManifest) {
    const hardened = hardenSchema(crd.schema);
    crd.validateManifest = ajv.compile(hardened);
    crd.validateSpec = ajv.compile(hardened.properties.spec);
  }

  const validate =
    panel === "kubernetes" ? crd.validateManifest : crd.validateSpec;
  const target = panel === "kubernetes" ? value : value?.spec;

  const valid = validate(target);
  const findings = valid
    ? []
    : validate.errors.map((err) => ({
        pointer: err.instancePath || "/",
        message: formatAjvError(err),
      }));

  return { findings, hasCoverage: true };
}
