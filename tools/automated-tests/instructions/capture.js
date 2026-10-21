// Owns how a `capture` entry turns a response into a value.
//
// The reader-facing contract lives in
// app/_includes/how-tos/validations/request-check/snippet.md: a page renders the
// capture as
//
//   VAR=$(curl [-i] ... | jq -r "<filter>")     # capture: [{variable, jq}]
//   VAR=$(curl [-i] ... | <command>)            # capture: [{variable, command}]
//   VAR=$(curl [-i] ...)                        # capture: [{variable}]
//
// so all three forms are valid doc config, and `-i` (display_headers) puts the
// status line and response headers in front of the body the pipeline reads.
// The harness holds the response as a parsed body plus headers rather than as
// curl output, so this module rebuilds the text curl would have printed and the
// pipeline the page appends to it.

// Single-quote a value for bash, so a jq filter reaches jq unexpanded even when
// it contains double quotes. The page double-quotes its filter; single quotes
// are the stricter equivalent (a `$` in a filter is not expanded here).
function shellQuote(value) {
  return `'${value.replace(/'/g, "'\\''")}'`;
}

// The text curl prints: body only, or `HTTP/1.1 <status>`, one line per header,
// a blank line, then the body when the page renders curl with `-i`.
export function captureInputText({ status, headers, bodyText, displayHeaders }) {
  if (!displayHeaders) {
    return bodyText;
  }

  const lines = [`HTTP/1.1 ${status}`];
  for (const [name, value] of headers) {
    lines.push(`${name}: ${value}`);
  }
  return `${lines.join("\n")}\n\n${bodyText}`;
}

// The shell pipeline the page appends after curl, or null for the bare
// `capture: - variable: X` form, which keeps the whole response.
export function capturePipeline(capture) {
  const jq = capture?.jq;
  if (typeof jq === "string" && jq.trim() !== "") {
    return `jq -r ${shellQuote(jq.trim())}`;
  }

  const command = capture?.command;
  if (typeof command === "string" && command.trim() !== "") {
    return command.trim();
  }

  return null;
}

// Human-readable form of the pipeline, for assertion messages.
export function captureDescription(capture) {
  const pipeline = capturePipeline(capture);
  return pipeline ?? "the whole response";
}

// The bash command that runs a capture entry against the response text, the
// same way the page's copyable command runs it against curl output.
export function captureCommand(capture, inputText) {
  const encoded = Buffer.from(inputText).toString("base64");
  const pipeline = capturePipeline(capture);
  const pipelinePart = pipeline ? ` | ${pipeline}` : "";
  return `printf '%s' '${encoded}' | base64 -d${pipelinePart}`;
}
