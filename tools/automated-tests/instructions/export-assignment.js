// Detects and wraps doc-sourced commands that assign a variable from a command
// substitution (e.g. `export ID="$(kongctl get ...)"`). These commands run in a
// throwaway `bash -c` exec, so without extra handling the variable evaporates
// before the next step reads it. The wrapper re-runs the original command
// verbatim and, on success, appends the resulting value (base64-encoded, using
// the `_BASE64` convention decoded by getLiveEnv in docker-helper.js) to
// /env-vars.sh so later steps inherit it.

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

export function buildPersistCommand(cmd, name) {
  return [
    cmd,
    "__at_status=$?",
    'if [ "$__at_status" -eq 0 ]; then',
    `  echo "export ${name}_BASE64=\\"$(printf %s "$${name}" | base64 -w0)\\"" >> /env-vars.sh`,
    "fi",
    'exit "$__at_status"',
  ].join("\n");
}
