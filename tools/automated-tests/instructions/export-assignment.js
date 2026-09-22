// Owns the export-assignment persistence contract for doc-sourced commands.
//
// Commands that assign a variable from a command substitution (e.g.
// `export ID="$(kongctl get ...)"`) run in a throwaway `bash -c` exec, so the
// variable evaporates before the next step reads it. buildPersistCommand wraps
// the original command verbatim and, on success, appends the resulting value to
// /env-vars.sh base64-encoded. docker-helper.js getLiveEnv decodes every
// `NAME_BASE64` entry last, so persisted values win over stale plain entries.
// The line format lives in base64EnvLine; docker-helper.js setEnvVariable uses
// the same formatter, so the file convention has a single owner.

const ASSIGNMENT_FROM_SUBSTITUTION =
  /^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*["']?\$\(/;

export function parseExportAssignment(cmd) {
  if (typeof cmd !== "string") {
    return null;
  }
  const firstLine = cmd.split("\n")[0];
  const match = firstLine.match(ASSIGNMENT_FROM_SUBSTITUTION);
  return match ? match[1] : null;
}

// The single owner of the /env-vars.sh _BASE64 line format. quotedValue is the
// value already wrapped in whatever quoting the caller needs: a literal base64
// string in double quotes (setEnvVariable encodes in Node), or an escaped
// in-shell expression inside a double-quoted echo (buildPersistCommand defers
// encoding to the executing shell).
export function base64EnvLine(name, quotedValue) {
  return `export ${name}_BASE64=${quotedValue}`;
}

export function buildPersistCommand(cmd, name) {
  const inShellValue = `\\"$(printf %s "$${name}" | base64 -w0)\\"`;
  return [
    cmd,
    "__doc_cmd_status=$?",
    'if [ "$__doc_cmd_status" -eq 0 ]; then',
    `  echo "${base64EnvLine(name, inShellValue)}" >> /env-vars.sh`,
    "fi",
    'exit "$__doc_cmd_status"',
  ].join("\n");
}
