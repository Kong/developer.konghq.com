// Owns the `body_cmd` config value for request validations.
//
// A doc block may build its request body with a shell command substitution
// instead of an inline `body` mapping, e.g.
//
//   {% konnect_api_request %}
//   body_cmd: $(cat secret.json)
//   {% endkonnect_api_request %}
//
// The rendering layer (app/_includes/how-tos/validations/request-check/snippet.md)
// emits `--json "$(cat secret.json)"`, so the value keeps its `$(...)` wrapper
// and a reader runs the inner command in their own shell. The runner executes
// the command through `bash -c` in the test container instead, so it needs the
// inner command, not the substitution syntax around it.

import { executeCommand } from "../docker-helper.js";

// Strips a single `$(...)` wrapper, if present, and trims the result. The
// wrapper is removed by slicing the first two and last characters rather than
// matching an inner pattern, so a command that itself contains parentheses or
// quotes (a `jq` filter, a `curl` pipeline) survives verbatim.
export function bodyCommand(bodyCmd) {
  if (typeof bodyCmd !== "string") {
    return null;
  }
  const trimmed = bodyCmd.trim();
  if (trimmed.startsWith("$(") && trimmed.endsWith(")")) {
    return trimmed.slice(2, -1).trim();
  }
  return trimmed;
}

// Runs the resolved command in the container and returns its stdout as the
// request body. The command already emits the finished document (JSON built by
// `jq`, a cat of a prepared file), so the output is used as-is: it is never
// re-serialized, and trailing newlines from the command substitution are
// dropped the way the shell would drop them.
export async function bodyFromCommand(container, bodyCmd, exec = executeCommand) {
  const command = bodyCommand(bodyCmd);
  const result = await exec(container, command);
  return result.output.trim();
}
