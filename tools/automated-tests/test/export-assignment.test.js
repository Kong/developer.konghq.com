import { test } from "node:test";
import assert from "node:assert/strict";

import {
  parseExportAssignment,
  parseExportAssignments,
  buildPersistCommand,
} from "../instructions/export-assignment.js";

import { executeDocCommand } from "../docker-helper.js";

function recordingExec(calls) {
  return async (container, command, displayCmd) => {
    calls.push([command, displayCmd]);
    return { exitCode: 0, output: "" };
  };
}

test("detects export with quoted command substitution", () => {
  const cmd = `export CONSUMER_ID="$(kongctl get ai-gateway consumers \\
  --gateway-id "$AI_GATEWAY_ID" kong-air \\
  --output json --jq '.id' --jq-raw-output \\
  --pat "$KONNECT_TOKEN")"`;
  assert.equal(parseExportAssignment(cmd), "CONSUMER_ID");
});

test("detects bare assignment with command substitution", () => {
  assert.equal(parseExportAssignment(`TOKEN=$(curl -s -X POST \\
  http://localhost:8000/routes)`), "TOKEN");
});

test("detects single-line unquoted substitution", () => {
  assert.equal(
    parseExportAssignment("export EVENT_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)"),
    "EVENT_TIME",
  );
});

test("detects indented assignment from extracted doc block", () => {
  assert.equal(
    parseExportAssignment('   export PROXY_IP=$(kubectl get gateway kong -n kong -o jsonpath=\'{.status.addresses[0].value}\')'),
    "PROXY_IP",
  );
});

test("rejects plain assignment without substitution", () => {
  assert.equal(parseExportAssignment("export GREETING=hello"), null);
  assert.equal(parseExportAssignment("GREETING=hello"), null);
});

test("rejects plain variable expansion without substitution", () => {
  assert.equal(parseExportAssignment("export KONGCTL_DEFAULT_KONNECT_PAT=$KONNECT_TOKEN"), null);
});

test("rejects non-assignment commands", () => {
  assert.equal(parseExportAssignment("curl -s http://localhost:8000/routes"), null);
  assert.equal(parseExportAssignment("deck gateway dump -o /tmp/kong.yaml"), null);
});

test("rejects commands where assignment is not first", () => {
  assert.equal(
    parseExportAssignment("echo hello && export TOKEN=$(curl -s http://x)"),
    null,
  );
});

test("wrapper chains original command verbatim and persists base64 value", () => {
  const cmd = 'export FOO="$(printf abc123)"';
  const wrapped = buildPersistCommand(cmd, "FOO");
  assert.ok(wrapped.startsWith(cmd), "original command must come first, unmodified");
  const persistLines = wrapped.slice(cmd.length);
  assert.match(persistLines, /FOO_BASE64/);
  assert.match(persistLines, /printf %s "\$FOO" \| base64 -w0/);
  assert.match(persistLines, />> \/env-vars\.sh/);
});

test("wrapper keeps multiline continuation command intact and exits with its status", () => {
  const cmd = `export CONSUMER_ID="$(kongctl get ai-gateway consumers \\
  --gateway-id "$AI_GATEWAY_ID" kong-air \\
  --output json --jq '.id' --jq-raw-output \\
  --pat "$KONNECT_TOKEN")"`;
  const wrapped = buildPersistCommand(cmd, "CONSUMER_ID");
  assert.ok(wrapped.includes(cmd), "multiline command must be embedded verbatim");
  assert.match(wrapped, /exit "\$__doc_cmd_status"/);
});

test("wrapper produces the exact expected script for a single-line command", () => {
  const cmd = 'export TOKEN="$(curl -s http://x)"';
  assert.equal(
    buildPersistCommand(cmd, "TOKEN"),
    [
      cmd,
      "__doc_cmd_status=$?",
      'if [ "$__doc_cmd_status" -eq 0 ]; then',
      '  echo "export TOKEN_BASE64=\\"$(printf %s "$TOKEN" | base64 -w0)\\"" >> /env-vars.sh',
      "fi",
      'exit "$__doc_cmd_status"',
    ].join("\n"),
  );
});

test("wrapper bakes the computed value into the env file line", () => {
  const wrapped = buildPersistCommand('export TOKEN="$(curl -s http://x)"', "TOKEN");
  // The echo is double-quoted, so the substitution is evaluated once here in the
  // shell where $TOKEN was just set; the env file receives the literal base64
  // value and never re-evaluates at getLiveEnv source time.
  assert.match(wrapped, /echo "export TOKEN_BASE64=\\\x22\$\(printf %s "\$TOKEN" \| base64 -w0\)\\\x22"/);
});

test("executeDocCommand wraps assignment commands for persistence", async () => {
  const calls = [];
  const cmd = 'export FOO="$(printf abc123)"';
  await executeDocCommand({}, cmd, recordingExec(calls));
  assert.equal(calls.length, 1);
  assert.ok(
    calls[0][0].startsWith("set -eo pipefail\n"),
    "wrapped script must start with the errexit/pipefail guard",
  );
  assert.match(calls[0][0], /FOO_BASE64/);
  assert.match(calls[0][0], />> \/env-vars\.sh/);
  assert.equal(calls[0][1], cmd, "failures must report the original doc command");
});

test("executeDocCommand guards plain commands with errexit and pipefail", async () => {
  const calls = [];
  const cmd = "export GREETING=hello";
  await executeDocCommand({}, cmd, recordingExec(calls));
  assert.equal(calls.length, 1);
  assert.equal(calls[0][0], `set -eo pipefail\n${cmd}`);
  assert.equal(calls[0][1], cmd, "failures must report the original doc command");
});

test("executeDocCommand guards non-assignment commands with errexit and pipefail", async () => {
  const calls = [];
  const cmd = "curl -s http://localhost:8000/routes";
  await executeDocCommand({}, cmd, recordingExec(calls));
  assert.equal(calls.length, 1);
  assert.equal(calls[0][0], `set -eo pipefail\n${cmd}`);
  assert.equal(calls[0][1], cmd, "failures must report the original doc command");
});

test("executeDocCommand guards a multi-line command on the first line only", async () => {
  const calls = [];
  const cmd = "kubectl wait --for=condition=Valid gateway/kong --timeout=60s\necho $PROXY_IP";
  await executeDocCommand({}, cmd, recordingExec(calls));
  assert.equal(calls.length, 1);
  assert.equal(calls[0][0], `set -eo pipefail\n${cmd}`);
  assert.equal(calls[0][1], cmd, "failures must report the original doc command");
});

test("parseExportAssignments returns every assignment line in a multi-assignment doc block", () => {
  const cmd = `export CONTROL_PLANE_ID=$(kubectl get -n kong konnectgatewaycontrolplanes.konnect.konghq.com gateway-control-plane -o jsonpath='{.status.id}')
echo $CONTROL_PLANE_ID
export CONFIG_STORE_ID=$(kubectl get -n kong konnectconfigstores.konnect.konghq.com cert-keys -o jsonpath='{.status.id}')
echo $CONFIG_STORE_ID`;
  assert.deepEqual(parseExportAssignments(cmd), [
    "CONTROL_PLANE_ID",
    "CONFIG_STORE_ID",
  ]);
});

test("parseExportAssignments ignores assignment-looking lines that do not start a statement", () => {
  const cmd = `echo hello && export TOKEN=$(curl -s http://x)
if [ -n "$X" ]; then export Y=$(date); fi`;
  assert.deepEqual(parseExportAssignments(cmd), []);
});

test("parseExportAssignments does not match yaml payload lines", () => {
  const cmd = `echo '
kind: KonnectAPIAuthConfiguration
token: "'$KONNECT_TOKEN'"
' | kubectl apply -f -`;
  assert.deepEqual(parseExportAssignments(cmd), []);
});

test("buildPersistCommand persists one base64 line per assignment name", () => {
  const cmd = `export A=$(curl -s http://x/a)
export B=$(curl -s http://x/b)`;
  const wrapped = buildPersistCommand(cmd, ["A", "B"]);
  assert.ok(wrapped.startsWith(cmd), "original command must come first, unmodified");
  const aCount = (wrapped.match(/A_BASE64/g) || []).length;
  const bCount = (wrapped.match(/B_BASE64/g) || []).length;
  assert.equal(aCount, 1);
  assert.equal(bCount, 1);
  assert.match(wrapped, /if \[ "\$__doc_cmd_status" -eq 0 \]; then/);
  assert.match(wrapped, /exit "\$__doc_cmd_status"/);
});

test("executeDocCommand wraps multi-assignment commands and reports the original", async () => {
  const calls = [];
  const cmd = `export A=$(curl -s http://x/a)
export B=$(curl -s http://x/b)`;
  await executeDocCommand({}, cmd, recordingExec(calls));
  assert.equal(calls.length, 1);
  assert.ok(
    calls[0][0].startsWith("set -eo pipefail\n"),
    "wrapped script must start with the errexit/pipefail guard",
  );
  assert.match(calls[0][0], /A_BASE64/);
  assert.match(calls[0][0], /B_BASE64/);
  assert.equal(calls[0][1], cmd, "failures must report the original doc command");
});
