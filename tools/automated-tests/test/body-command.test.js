import { test } from "node:test";
import assert from "node:assert/strict";

import { bodyCommand, bodyFromCommand } from "../instructions/body-command.js";

test("strips the command-substitution wrapper", () => {
  assert.equal(bodyCommand("$(cat secret.json)"), "cat secret.json");
});

test("trims whitespace around and inside the wrapper", () => {
  assert.equal(bodyCommand("  $(cat secret.json)  "), "cat secret.json");
  assert.equal(bodyCommand("$(cat secret.json )"), "cat secret.json");
});

test("keeps the inner command verbatim, including quotes and parens", () => {
  assert.equal(
    bodyCommand(
      "$(jq -n --arg key example-tls-key --rawfile value tls.key '{key: $key, value: $value}')",
    ),
    "jq -n --arg key example-tls-key --rawfile value tls.key '{key: $key, value: $value}'",
  );
  assert.equal(
    bodyCommand("$(curl -s http://x | jq -r '.data[0].id')"),
    "curl -s http://x | jq -r '.data[0].id'",
  );
});

test("returns an unwrapped command unchanged", () => {
  assert.equal(bodyCommand("cat secret.json"), "cat secret.json");
});

test("rejects a non-string value", () => {
  assert.equal(bodyCommand(undefined), null);
  assert.equal(bodyCommand(null), null);
});

test("runs the unwrapped command and returns its trimmed stdout as the body", async () => {
  const calls = [];
  const exec = async (container, command) => {
    calls.push(command);
    return { exitCode: 0, output: '{"key":"example-tls-key"}\n' };
  };

  const body = await bodyFromCommand({}, "$(cat secret.json)", exec);

  assert.deepEqual(calls, ["cat secret.json"]);
  assert.equal(body, '{"key":"example-tls-key"}');
});
