import test from "node:test";
import assert from "node:assert/strict";

import {
  captureCommand,
  captureDescription,
  captureInputText,
  capturePipeline,
} from "../instructions/capture.js";

// Mirrors the doc block on app/_how-tos/ai-gateway/get-started-with-mcp-server.md,
// whose capture is the shell-command form.
const commandCapture = {
  variable: "SESSION_ID",
  command: "grep -i '^mcp-session-id:' | tr -d '\\r' | cut -d' ' -f2",
};

test("capturePipeline builds a jq pipeline for the jq form", () => {
  assert.equal(capturePipeline({ variable: "ID", jq: ".id" }), "jq -r '.id'");
});

test("capturePipeline keeps a filter that contains double quotes intact", () => {
  assert.equal(
    capturePipeline({ variable: "ID", jq: 'select(.name=="a")' }),
    `jq -r 'select(.name=="a")'`,
  );
});

test("capturePipeline escapes single quotes in a filter", () => {
  assert.equal(
    capturePipeline({ variable: "ID", jq: "select(.name=='a')" }),
    `jq -r 'select(.name=='\\''a'\\'')'`,
  );
});

test("capturePipeline passes a shell command through untouched", () => {
  assert.equal(capturePipeline(commandCapture), commandCapture.command);
});

test("capturePipeline returns null for the bare capture form", () => {
  assert.equal(capturePipeline({ variable: "DETAILS" }), null);
});

test("capturePipeline ignores empty filters and commands", () => {
  assert.equal(capturePipeline({ variable: "ID", jq: "  " }), null);
  assert.equal(capturePipeline({ variable: "ID", command: "" }), null);
  assert.equal(capturePipeline({ variable: "ID", jq: "", command: "" }), null);
});

test("captureDescription names the pipeline in use", () => {
  assert.equal(captureDescription({ variable: "ID", jq: ".id" }), "jq -r '.id'");
  assert.equal(captureDescription(commandCapture), commandCapture.command);
  assert.equal(
    captureDescription({ variable: "DETAILS" }),
    "the whole response",
  );
});

test("captureInputText returns the body when the page renders curl without -i", () => {
  assert.equal(
    captureInputText({
      status: 200,
      headers: new Headers({ "content-type": "application/json" }),
      bodyText: '{"id":"abc"}',
      displayHeaders: false,
    }),
    '{"id":"abc"}',
  );
});

test("captureInputText prepends the status line and headers for display_headers", () => {
  const text = captureInputText({
    status: 200,
    headers: new Headers({
      "mcp-session-id": "session-123",
      "content-type": "text/event-stream",
    }),
    bodyText: "event: message",
    displayHeaders: true,
  });

  // Header order is the platform's, not the fixture's: assert the shape curl -i
  // prints instead of one exact ordering.
  assert.equal(text.split("\n")[0], "HTTP/1.1 200");
  assert.match(text, /^mcp-session-id: session-123$/m);
  assert.match(text, /^content-type: text\/event-stream$/m);
  assert.equal(text.split("\n\n").at(-1), "event: message");
});

test("captureCommand feeds the response text through a jq pipeline", () => {
  const command = captureCommand({ variable: "ID", jq: ".id" }, '{"id":"abc"}');
  const encoded = command.match(/^printf '%s' '([^']+)' \| base64 -d \| jq -r '.id'$/);

  assert.ok(encoded, `unexpected command: ${command}`);
  assert.equal(Buffer.from(encoded[1], "base64").toString("utf8"), '{"id":"abc"}');
});

test("captureCommand feeds the response text through a shell command", () => {
  const command = captureCommand(commandCapture, "mcp-session-id: session-123");
  const encoded = command.match(/^printf '%s' '([^']+)' \| base64 -d \| (.+)$/);

  assert.ok(encoded, `unexpected command: ${command}`);
  assert.equal(
    Buffer.from(encoded[1], "base64").toString("utf8"),
    "mcp-session-id: session-123",
  );
  assert.equal(encoded[2], commandCapture.command);
});

test("captureCommand keeps the whole response for the bare form", () => {
  const command = captureCommand({ variable: "DETAILS" }, '{"id":"abc"}');
  const encoded = command.match(/^printf '%s' '([^']+)' \| base64 -d$/);

  assert.ok(encoded, `unexpected command: ${command}`);
  assert.equal(Buffer.from(encoded[1], "base64").toString("utf8"), '{"id":"abc"}');
});

test("captureCommand survives a multi-line response", () => {
  const command = captureCommand({ variable: "CERT", jq: ".items[].cert" }, "line1\nline2");
  const encoded = command.match(/^printf '%s' '([^']+)'/);

  assert.equal(Buffer.from(encoded[1], "base64").toString("utf8"), "line1\nline2");
});
