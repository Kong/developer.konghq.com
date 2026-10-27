import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import minimist from "minimist";
import { glob } from "tinyglobby";
import YAML from "yaml";
import Ajv from "ajv";
import addFormats from "ajv-formats";
import { $RefParser } from "@apidevtools/json-schema-ref-parser";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "../..");
const API_SPECS_DIR = path.join(ROOT, "api-specs");
const POLICIES_DIR = "app/_event_gateway_policies";
const EXAMPLES_GLOB = `${POLICIES_DIR}/*/examples/*.{yaml,yml}`;

class UserError extends Error {}

function parseArgs(argv) {
  const parsed = minimist(argv, {
    string: ["spec"],
    boolean: ["help"],
    alias: { spec: "s", help: "h" },
    default: { spec: null },
    unknown: (arg) => {
      if (arg.startsWith("-")) throw new UserError(`Unknown argument: ${arg}`);
    },
  });
  const args = { spec: parsed.spec, help: parsed.help };
  if (args.spec !== null && !args.spec) {
    throw new UserError("--spec needs a path to an OpenAPI file");
  }
  return args;
}

const USAGE = `Usage: node index.js [--spec <path-to-openapi.yaml>]

Validates app/_event_gateway_policies/*/examples/*.yml against the schemas that
each policy's index.md frontmatter points at.

  --spec, -s   Validate against this OpenAPI file instead of the one that
               'schema.api' resolves to. Applies to every policy.
  --help, -h   Show this message.
`;

// Keys of an example file that describe the policy itself. Everything else in
// the file is documentation metadata (title, weight, requirements, tools, ...)
// and has no counterpart in the API spec.
const POLICY_KEYS = ["name", "type", "condition", "config"];

function findLatestSpecVersion(apiDir) {
  const dirs = fs
    .readdirSync(apiDir)
    .filter((d) => fs.statSync(path.join(apiDir, d)).isDirectory())
    .sort((a, b) => {
      const pa = a.replace(/^v/, "").split(".").map(Number);
      const pb = b.replace(/^v/, "").split(".").map(Number);
      for (let i = 0; i < Math.max(pa.length, pb.length); i++) {
        const diff = (pa[i] || 0) - (pb[i] || 0);
        if (diff !== 0) return diff;
      }
      return 0;
    });
  return dirs[dirs.length - 1];
}

// Extract the YAML frontmatter block from a Markdown file.
function readFrontmatter(filePath) {
  const content = fs.readFileSync(filePath, "utf-8");
  const match = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (!match) return null;
  return YAML.parse(match[1], { uniqueKeys: false });
}

// The API spec omits `additionalProperties` on nearly every object, so Ajv
// accepts misspelled config keys silently -- the failure most likely in a
// hand-written docs example. Close every object that does not compose with
// another schema, and does not already say what it accepts.
// Find every schema used as an `allOf` member. This has to be its own pass: a
// named schema such as `BaseEventGatewayPolicy` is reached directly from
// `components.schemas` before anything reveals that an `allOf` composes it, so
// a single walk would close it before knowing better.
function findAllOfMembers(node, members = new WeakSet(), seen = new WeakSet()) {
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

function closeObjectSchemas(node, members, visited = new WeakSet()) {
  if (node === null || typeof node !== "object") return;
  if (visited.has(node)) return;
  visited.add(node);

  if (Array.isArray(node)) {
    node.forEach((item) => closeObjectSchemas(item, members, visited));
    return;
  }

  // A member of an `allOf` must stay open: its siblings carry the rest of the
  // object's properties, so closing it makes every member reject the others'
  // keys and nothing validates at all. `oneOf`/`anyOf` branches are whole
  // alternatives to each other, so those are closed as normal.
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

async function loadSpec(api, override) {
  let specPath;
  let version;

  if (override) {
    specPath = path.resolve(override);
    if (!fs.existsSync(specPath)) {
      throw new UserError(`No OpenAPI file at ${override}`);
    }
    version = "override";
  } else {
    const apiDir = path.join(API_SPECS_DIR, api);
    if (!fs.existsSync(apiDir)) {
      throw new UserError(`No API spec directory at api-specs/${api}`);
    }
    version = findLatestSpecVersion(apiDir);
    specPath = path.join(apiDir, version, "openapi.yaml");
  }

  const parser = new $RefParser();
  let spec;
  try {
    spec = await parser.dereference(specPath);
  } catch (e) {
    throw new UserError(`Could not resolve ${specPath}: ${e.message}`);
  }

  const schemas = spec.components && spec.components.schemas;
  closeObjectSchemas(schemas, findAllOfMembers(schemas));
  return { spec, refs: parser.$refs, version, specPath };
}

// A schema composed with `allOf` holds nothing itself: its properties, its
// `items`, even its `type` live in its members. The published spec is
// post-processed to flatten these away, but a source spec is not, so every
// lookup has to look through them.
function collectAllOf(schema, out = [], visited = new WeakSet()) {
  if (!schema || typeof schema !== "object") return out;
  if (visited.has(schema)) return out;
  visited.add(schema);
  out.push(schema);
  for (const member of schema.allOf || []) collectAllOf(member, out, visited);
  return out;
}

function lookupThroughAllOf(schema, pick) {
  for (const member of collectAllOf(schema)) {
    const found = pick(member);
    if (found !== undefined) return found;
  }
  return undefined;
}

// `allOf` members routinely declare the same property twice: a base schema
// gives `config` a generic `type: object`, and the policy-specific member
// narrows it to the real thing. Picking one candidate loses whichever half was
// not picked, so return all of them composed instead. Every lookup here already
// looks through `allOf`, so this needs no special handling downstream, and it
// is only ever walked for substitution -- Ajv still compiles the real schema.
function propertySchema(schema, key) {
  const candidates = [];
  for (const member of collectAllOf(schema)) {
    const found = member.properties && member.properties[key];
    if (found !== undefined && !candidates.includes(found)) {
      candidates.push(found);
    }
  }
  if (candidates.length === 0) return undefined;
  if (candidates.length === 1) return candidates[0];
  return { allOf: candidates };
}

const FORMAT_PLACEHOLDERS = {
  uuid: "00000000-0000-0000-0000-000000000000",
  "date-time": "2024-01-01T00:00:00Z",
  date: "2024-01-01",
  uri: "https://example.com",
  email: "user@example.com",
  hostname: "example.com",
  ipv4: "127.0.0.1",
};

// Generate a type-appropriate placeholder for a schema field.
// `hint` is the value the schema's own `example` gives for this field, which is
// the only thing that can satisfy a `pattern` or `format` constraint.
function placeholderForSchema(fieldSchema, hint) {
  if (hint !== undefined) return hint;
  if (!fieldSchema) return "__placeholder__";
  const pick = (keyword) =>
    lookupThroughAllOf(fieldSchema, (member) => member[keyword]);
  const example = pick("example");
  if (example !== undefined) return example;
  const dflt = pick("default");
  if (dflt !== undefined) return dflt;
  const enumeration = pick("enum");
  if (enumeration && enumeration.length > 0) return enumeration[0];
  const format = pick("format");
  if (format && FORMAT_PLACEHOLDERS[format]) return FORMAT_PLACEHOLDERS[format];
  switch (pick("type")) {
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

function schemaAllowsNull(fieldSchema) {
  if (!fieldSchema) return false;
  // The spec is OpenAPI 3.0, where nullability is `nullable: true` rather than
  // a `null` entry in `type`. Ajv does not understand it, so check it here.
  return collectAllOf(fieldSchema).some((member) => {
    if (member.nullable === true) return true;
    if (member.type === "null") return true;
    return Array.isArray(member.type) && member.type.includes("null");
  });
}

// Pick the `oneOf`/`anyOf` branch that a value is meant to satisfy, so variable
// replacement can keep walking the schema. Without this, a value under a
// polymorphic field resolves to no sub-schema and every `${...}` in it collapses
// to a generic placeholder, which then fails the branch's own constraints.
function jsonType(value) {
  if (value === null) return "null";
  if (Array.isArray(value)) return "array";
  if (Number.isInteger(value)) return "integer";
  if (typeof value === "number") return "number";
  return typeof value;
}

function schemaAcceptsType(schema, type) {
  const declared = lookupThroughAllOf(schema, (member) => member.type);
  if (declared === undefined) return false;
  const types = Array.isArray(declared) ? declared : [declared];
  // An integer value also satisfies a `number` schema.
  return types.includes(type) || (type === "integer" && types.includes("number"));
}

function resolveForValue(fieldSchema, value, refs) {
  const branches = lookupThroughAllOf(
    fieldSchema,
    (member) => member.oneOf || member.anyOf,
  );
  if (!branches) return fieldSchema;
  if (value === null) return fieldSchema;

  // Branches that cannot hold a value of this JSON type are out. When exactly
  // one survives, that is the answer -- this is how a field that is either a
  // literal array or an expression string gets resolved.
  const type = jsonType(value);
  const byType = branches.filter((branch) => schemaAcceptsType(branch, type));
  if (byType.length === 1) return byType[0];

  const candidates = byType.length > 0 ? byType : branches;

  // Only an object can be told apart by its keys, whether by a discriminator
  // or by key counting. Anything else, we have gone as far as we can.
  if (typeof value !== "object" || Array.isArray(value)) return fieldSchema;

  // `discriminator.mapping` values are plain pointer strings, not `$ref`
  // keywords, so dereferencing the spec leaves them untouched. Resolve them
  // through the parser rather than walking the document by hand.
  const discriminator = lookupThroughAllOf(
    fieldSchema,
    (member) => member.discriminator,
  );
  if (discriminator && discriminator.propertyName) {
    const key = value[discriminator.propertyName];
    const mapped = discriminator.mapping && discriminator.mapping[key];
    if (mapped) {
      try {
        return refs.get(mapped);
      } catch {
        // A mapping that points nowhere is the spec's problem, not ours. Fall
        // through to key counting.
      }
    }
  }

  // No discriminator: take the branch that declares the most of this value's keys.
  let best = fieldSchema;
  let bestScore = -1;
  for (const branch of candidates) {
    const score = Object.keys(value).filter((k) =>
      propertySchema(branch, k),
    ).length;
    if (score > bestScore) {
      bestScore = score;
      best = branch;
    }
  }
  return best;
}

// Recursively replace ${...} template variables with schema-appropriate values,
// and strip nulls the schema does not allow. Passes the resolved sub-schema
// down through the recursion so we never re-walk from root.
function replaceVariables(obj, fieldSchema, refs, hint) {
  const resolved = resolveForValue(fieldSchema, obj, refs);

  if (typeof obj === "string") {
    if (/\$\{[^}]+\}/.test(obj)) {
      return placeholderForSchema(resolved, hint);
    }
    return obj;
  }
  if (Array.isArray(obj)) {
    const itemSchema = lookupThroughAllOf(resolved, (member) => member.items);
    const itemHint = Array.isArray(hint) ? hint[0] : undefined;
    return obj.map((item) => replaceVariables(item, itemSchema, refs, itemHint));
  }
  if (obj !== null && typeof obj === "object") {
    // An object-level `example` is often the only place a patterned string
    // field has a value that actually matches its own pattern.
    const example = lookupThroughAllOf(resolved, (member) =>
      member.example && typeof member.example === "object"
        ? member.example
        : undefined,
    );
    const result = {};
    for (const [key, value] of Object.entries(obj)) {
      const propSchema = resolveForValue(
        propertySchema(resolved, key),
        value,
        refs,
      );
      if (value === null && !schemaAllowsNull(propSchema)) continue;
      result[key] = replaceVariables(
        value,
        propSchema,
        refs,
        example && example[key],
      );
    }
    return result;
  }
  return obj;
}

async function validate(args = { spec: null }) {
  const indexFiles = await glob(`${POLICIES_DIR}/*/index.md`, { cwd: ROOT });
  const exampleFiles = await glob(EXAMPLES_GLOB, { cwd: ROOT });

  const ajv = new Ajv({ allErrors: true, strict: false });
  addFormats(ajv);
  // Formats the spec uses that ajv-formats does not know. Registered as
  // always-valid so Ajv stops warning about them; their shape is not checkable here.
  for (const format of ["glob", "path"]) {
    ajv.addFormat(format, true);
  }

  const errors = [];
  const specs = new Map();
  const policies = new Map();
  let skipped = 0;

  for (const indexFile of indexFiles) {
    const slug = indexFile.split("/")[2];
    const frontmatter = readFrontmatter(path.join(ROOT, indexFile));
    const schema = frontmatter && frontmatter.schema;

    if (!schema || !schema.api || !schema.path) {
      errors.push({
        file: indexFile,
        errors: [
          {
            instancePath: "/schema",
            message:
              "no `schema.api` and `schema.path` in the frontmatter, so there is nothing to validate this policy's examples against.",
          },
        ],
      });
      policies.set(slug, { failed: true });
      continue;
    }

    if (!specs.has(schema.api)) {
      const loaded = await loadSpec(schema.api, args.spec);
      // A spec inside the repo reads better relative to the root; one outside
      // it does not, so keep those absolute.
      const shown = loaded.specPath.startsWith(`${ROOT}${path.sep}`)
        ? path.relative(ROOT, loaded.specPath)
        : loaded.specPath;
      console.log(
        `Using spec: ${shown} (${schema.api} ${loaded.version})`,
      );
      specs.set(schema.api, loaded);
    }
    const { spec, refs } = specs.get(schema.api);

    const pointer = `/components${schema.path}`;
    const policySchema = pointer
      .split("/")
      .filter(Boolean)
      .reduce((node, segment) => (node ? node[segment] : undefined), spec);

    if (!policySchema) {
      const source = args.spec
        ? args.spec
        : `api-specs/${schema.api}`;
      errors.push({
        file: indexFile,
        errors: [
          {
            instancePath: "/schema/path",
            message: `"${schema.path}" does not resolve in ${source}. Either the path is wrong, or the spec does not carry this schema yet.`,
          },
        ],
      });
      policies.set(slug, { failed: true });
      continue;
    }

    policies.set(slug, {
      validateFn: ajv.compile(policySchema),
      policySchema,
      refs,
    });
  }

  console.log(`Found ${exampleFiles.length} example files\n`);

  for (const filePath of exampleFiles) {
    const fullPath = path.join(ROOT, filePath);
    let parsed;
    try {
      parsed = YAML.parse(fs.readFileSync(fullPath, "utf-8"), {
        uniqueKeys: false,
      });
    } catch (e) {
      errors.push({
        file: filePath,
        errors: [{ instancePath: "/", message: `YAML parse error: ${e.message}` }],
      });
      continue;
    }

    if (!parsed) continue;

    const slug = filePath.split("/")[2];
    const entry = policies.get(slug);

    if (!entry) {
      console.log(`SKIP: No index.md found for "${slug}"`);
      skipped++;
      continue;
    }
    if (entry.failed) continue;

    // Keep only the keys that describe the policy; the rest is docs metadata.
    const rawPolicy = {};
    for (const key of POLICY_KEYS) {
      if (parsed[key] !== undefined) rawPolicy[key] = parsed[key];
    }

    const policy = replaceVariables(rawPolicy, entry.policySchema, entry.refs);

    if (!entry.validateFn(policy)) {
      errors.push({ file: filePath, errors: [...entry.validateFn.errors] });
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

  console.log("All Event Gateway policy examples are valid.");
}

export default validate;

let args;
try {
  args = parseArgs(process.argv.slice(2));
} catch (err) {
  console.error(`${err.message}\n\n${USAGE}`);
  process.exit(2);
}

if (args.help) {
  console.log(USAGE);
} else {
  validate(args).catch((err) => {
    console.error(err instanceof UserError ? err.message : err);
    process.exit(1);
  });
}
