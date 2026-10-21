import test from "node:test";
import assert from "node:assert/strict";

import {
  buildCurlCommand,
  isNetworkLevelError,
  parseCurlResponse,
} from "../instructions/container-request.js";

// buildCurlCommand mirrors what executeRequest already resolved: URL
// (post-env-substitution), method, headers (auth merged), string body,
// insecure flag. Flag order is pinned by these tests: url right after the
// fixed preamble, then -k, -X, -H, --data. max-time 60 matches the curl
// convention in config/runtimes.yaml.

// Expected commands are written heredoc-style, one flag per line, then
// joined into the single-line command buildCurlCommand emits.
const command = (heredoc) =>
  heredoc
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean)
    .join(" ");

test("buildCurlCommand emits a plain GET with no -X flag", () => {
  assert.equal(
    buildCurlCommand("http://localhost:8000/anything"),
    "curl -s -i --max-time 60 'http://localhost:8000/anything'",
  );
});

test("buildCurlCommand emits -X for an explicit non-GET method", () => {
  assert.equal(
    buildCurlCommand("http://localhost:8000/anything", { method: "DELETE" }),
    "curl -s -i --max-time 60 'http://localhost:8000/anything' -X 'DELETE'",
  );
});

test("buildCurlCommand keeps a body-carrying GET as GET", () => {
  assert.equal(
    buildCurlCommand("http://localhost:8000/anything", {
      method: "GET",
      body: "a=b",
    }),
    "curl -s -i --max-time 60 'http://localhost:8000/anything' -X 'GET' --data 'a=b'",
  );
});

test("buildCurlCommand emits one -H flag per header", () => {
  assert.equal(
    buildCurlCommand("http://localhost:8000/anything", {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
        apikey: "secret",
      },
    }),
    command(`
      curl -s -i --max-time 60 'http://localhost:8000/anything'
      -H 'Content-Type: application/json'
      -H 'apikey: secret'
    `),
  );
});

test("buildCurlCommand single-quote-escapes header and body values", () => {
  assert.equal(
    buildCurlCommand("http://localhost:8000/anything", {
      method: "POST",
      headers: { "X-Note": "it's here" },
      body: `{"msg":"won't fail"}`,
    }),
        command(`
      curl -s -i --max-time 60 'http://localhost:8000/anything'
      -X 'POST'
      -H 'X-Note: it'\\''s here'
      --data '{"msg":"won'\\''t fail"}'
    `),
  );
});

test("buildCurlCommand emits string bodies as --data", () => {
  assert.equal(
    buildCurlCommand("http://localhost:8000/anything", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: '{"name":"kong"}',
    }),
        command(`
      curl -s -i --max-time 60 'http://localhost:8000/anything'
      -X 'POST'
      -H 'Content-Type: application/json'
      --data '{"name":"kong"}'
    `),
  );
});

test("buildCurlCommand emits -k for an insecure TLS request", () => {
  assert.equal(
    buildCurlCommand("https://localhost:8444/anything", { insecure: true }),
    "curl -s -i --max-time 60 'https://localhost:8444/anything' -k",
  );
});

// parseCurlResponse turns `curl -s -i` output into a real Response, so the
// downstream status/extract/retry flow in executeRequest keeps working
// unchanged. Header block and body are separated by curl's blank line.

test("parseCurlResponse reads status, headers, and body of a plain 200 response", async () => {
  const output = `HTTP/1.1 200 OK
Content-Type: application/json
X-Request-Id: abc-123

{"message":"ok"}`;
  const response = parseCurlResponse(output);

  assert.equal(response.status, 200);
  assert.equal(response.headers.get("Content-Type"), "application/json");
  assert.equal(response.headers.get("x-request-id"), "abc-123");
  assert.equal(await response.text(), '{"message":"ok"}');
});

test("parseCurlResponse skips a 100 Continue block before the real status line", async () => {
  const output = `HTTP/1.1 100 Continue

HTTP/1.1 201 Created
Content-Type: application/json

{"id":1}`;
  const response = parseCurlResponse(output);

  assert.equal(response.status, 201);
  assert.equal(response.headers.get("Content-Type"), "application/json");
  assert.equal(await response.text(), '{"id":1}');
});

test("parseCurlResponse drops the body for 204, 205, and 304", async () => {
  for (const status of [204, 205, 304]) {
    const output = `HTTP/1.1 ${status} x
ETag: "v1"

not a body`;
    const response = parseCurlResponse(output);

    assert.equal(response.status, status);
    assert.equal(response.body, null);
    assert.equal(await response.text(), "");
  }
});

test("parseCurlResponse accepts curl's literal CRLF output", async () => {
  const response = parseCurlResponse(
    "HTTP/1.1 200 OK\r\nX-Crlf: yes\r\n\r\n{\"ok\":true}",
  );

  assert.equal(response.status, 200);
  assert.equal(response.headers.get("x-crlf"), "yes");
  assert.equal(await response.text(), '{"ok":true}');
});

test("parseCurlResponse exposes headers case-insensitively", async () => {
  const output = `HTTP/1.1 200 OK
Set-Cookie: session=abc-123; Path=/

{}`;
  const response = parseCurlResponse(output);

  assert.equal(response.headers.get("set-cookie"), "session=abc-123; Path=/");
});

test("parseCurlResponse joins folded header lines", async () => {
  const output = `HTTP/1.1 200 OK
X-Folded: first
  second

{}`;
  const response = parseCurlResponse(output);

  assert.equal(response.headers.get("x-folded"), "first second");
});

// isNetworkLevelError decides whether executeRequest may re-run the request
// inside the test container: only network-level fetch failures qualify.

test("isNetworkLevelError classifies every network-level cause code", () => {
  const codes = [
    "EHOSTUNREACH",
    "ENETUNREACH",
    "ETIMEDOUT",
    "ECONNREFUSED",
    "EAI_AGAIN",
    "ENOTFOUND",
    "ECONNRESET",
  ];

  for (const code of codes) {
    const error = new TypeError("fetch failed", { cause: { code } });
    assert.equal(isNetworkLevelError(error), true, code);
  }
});

test("isNetworkLevelError rejects non-network errors", () => {
  // Invalid-URL shape: no cause at all.
  assert.equal(isNetworkLevelError(new TypeError("Failed to parse URL")), false);
  // TLS certificate failure: a cause whose code is not network-level.
  assert.equal(
    isNetworkLevelError(
      new TypeError("fetch failed", {
        cause: { code: "UNABLE_TO_VERIFY_LEAF_SIGNATURE" },
      }),
    ),
    false,
  );
});

test("isNetworkLevelError rejects errors without a cause", () => {
  assert.equal(isNetworkLevelError(new Error("fetch failed")), false);
  assert.equal(isNetworkLevelError(new TypeError("fetch failed")), false);
});
