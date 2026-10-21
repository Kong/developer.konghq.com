// Pure helpers for re-running a fetch-based validation request inside the
// test container when the runner process (the host) cannot reach the target.
// On macOS, a host-side fetch to a Docker-internal address (an operator k3d
// bridge-network $PROXY_IP) fails with a network-level cause such as
// EHOSTUNREACH, while the container shares the daemon's network namespace
// and can reach it. executeRequest (validations.js) hooks these helpers into
// its fetch catch path; the module itself is container-free and unit-tested
// (test/container-request.test.js).
//
// Out of scope: binary response bodies. docker exec stdout is
// text-multiplexed, and in-scope validations are JSON-over-HTTP.

// Matches the curl convention in config/runtimes.yaml.
const MAX_TIME_SECONDS = 60;

const NETWORK_LEVEL_CODES = new Set([
  "EHOSTUNREACH",
  "ENETUNREACH",
  "ETIMEDOUT",
  "ECONNREFUSED",
  "EAI_AGAIN",
  "ENOTFOUND",
  "ECONNRESET",
]);

const NULL_BODY_STATUSES = new Set([204, 205, 304]);

// The command runs through `bash -c` (docker-helper.js executeCommand), so
// every interpolated value is single-quoted with embedded quotes escaped
// (' -> '\'').
function shellQuote(value) {
  return `'${String(value).replaceAll("'", `'\\''`)}'`;
}

export function buildCurlCommand(url, options = {}) {
  const parts = ["curl", "-s", "-i", `--max-time ${MAX_TIME_SECONDS}`, shellQuote(url)];

  if (options.insecure) {
    parts.push("-k");
  }
  // curl defaults to GET, but --data without -X defaults to POST: emit -X
  // for every non-GET method, and for a GET that carries a body.
  const method = options.method ?? "GET";
  if (method !== "GET" || typeof options.body === "string") {
    parts.push("-X", shellQuote(method));
  }
  for (const [name, value] of Object.entries(options.headers ?? {})) {
    parts.push("-H", shellQuote(`${name}: ${value}`));
  }
  if (typeof options.body === "string") {
    parts.push("--data", shellQuote(options.body));
  }

  return parts.join(" ");
}

export function parseCurlResponse(output) {
  // curl emits CRLF line endings and docker exec passes the bytes through
  // unchanged. Normalize to LF so the CRLF bytes from the container and
  // LF-only text parse identically.
  let remaining = output.replaceAll("\r\n", "\n");
  let status;
  let headerLines;
  let bodyText;

  // Skip any interim response blocks that precede the real one.
  for (;;) {
    const separatorIndex = remaining.indexOf("\n\n");
    const block =
      separatorIndex === -1 ? remaining : remaining.slice(0, separatorIndex);
    bodyText = separatorIndex === -1 ? "" : remaining.slice(separatorIndex + 2);

    const [statusLine, ...lines] = block.split("\n");
    status = parseStatusCode(statusLine);
    if (status === null) {
      throw new Error(
        `Could not parse a status line from curl output: ${JSON.stringify(output)}`,
      );
    }
    if (status < 200) {
      remaining = bodyText;
      continue;
    }
    headerLines = lines;
    break;
  }

  const headers = [];
  for (const line of headerLines) {
    if (line === "") {
      continue;
    }
    if (/^[ \t]/.test(line)) {
      const previous = headers.at(-1);
      if (previous) {
        previous[1] = `${previous[1]} ${line.trim()}`;
      }
      continue;
    }
    const colonIndex = line.indexOf(":");
    if (colonIndex === -1) {
      continue;
    }
    headers.push([line.slice(0, colonIndex).trim(), line.slice(colonIndex + 1).trim()]);
  }

  if (NULL_BODY_STATUSES.has(status)) {
    bodyText = null;
  }

  return new Response(bodyText, { status, headers });
}

function parseStatusCode(statusLine) {
  const match = statusLine?.match(/^HTTP\/[\d.]+\s+(\d{3})/);
  return match ? Number.parseInt(match[1], 10) : null;
}

// Whether a failed host-side fetch may be re-run inside the test container:
// only network-level causes qualify. Non-network errors (invalid URL, TLS
// certificate failure, ...) propagate as-is.
export function isNetworkLevelError(error) {
  return NETWORK_LEVEL_CODES.has(error?.cause?.code);
}
