// Owns how the harness turns the container's persisted environment
// (/env-vars.sh, format owned by instructions/export-assignment.js) into the
// environment a step runs with.
//
// Two forms can write the same variable name:
//
//   export NAME="value"          # setEnvVariable: extract_body, env-variables
//   export NAME_BASE64="<b64>"   # buildPersistCommand and capture entries
//
// The _BASE64 form exists because a persisted value can carry newlines (a
// certificate, a JSON document) or quoting that a literal `export NAME="..."`
// line would mangle, so it is stored base64-encoded and decoded here. A name can
// therefore appear twice in the file, and which entry wins follows *file order*:
// bash resolves a `source` by last assignment, and the environment we hand to a
// step has to agree with it.
//
// Preferring every _BASE64 entry unconditionally is wrong across instruction
// files. /env-vars.sh is never pruned between tests, so a capture written by an
// earlier how-to keeps overriding a later how-to's plain entry for the same
// name. That is what broke `enable-vault-authentication`: the OAuth2 how-to that
// runs immediately before it captures ACCESS_TOKEN for its bearer header, and
// the Vault how-to reuses ACCESS_TOKEN for the consumer credential the plugin
// reads back, so the plugin was handed the OAuth2 token and answered
// "Unauthorized" (401) on every retry.

function baseName(name) {
  return name.endsWith("_BASE64") ? name.slice(0, -"_BASE64".length) : name;
}

export function lastWriters(fileContent) {
  const writers = new Map();
  for (const line of (fileContent ?? "").split("\n")) {
    const match = line.match(/^\s*export\s+([A-Za-z_][A-Za-z0-9_]*)=/);
    if (!match) continue;
    const name = match[1];
    writers.set(baseName(name), name.endsWith("_BASE64") ? "base64" : "plain");
  }
  return writers;
}

export function parseEnvOutput(output) {
  const env = {};
  const base64Entries = [];

  for (const line of (output ?? "").split("\n")) {
    const [name, ...rest] = line.split("=");
    const value = rest.join("=");

    if (name.endsWith("_BASE64")) {
      base64Entries.push([baseName(name), value]);
    } else {
      env[name] = value;
    }
  }

  return { env, base64Entries };
}

export function resolveEnvVars(output, fileContent) {
  const { env, base64Entries } = parseEnvOutput(output);
  const writers = lastWriters(fileContent);

  for (const [name, value] of base64Entries) {
    const writer = writers.get(name);
    if (writer === undefined || writer === "base64") {
      env[name] = Buffer.from(value, "base64").toString("utf-8");
    }
  }

  return env;
}
