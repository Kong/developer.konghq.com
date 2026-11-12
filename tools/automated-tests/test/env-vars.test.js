import test from "node:test";
import assert from "node:assert/strict";

import {
  lastWriters,
  parseEnvOutput,
  resolveEnvVars,
} from "../instructions/env-vars.js";

const b64 = (value) => Buffer.from(value).toString("base64");

// The shape `source /env-vars.sh && env` prints: every plain entry as bash
// resolved it, plus the raw _BASE64 entries.
function envOutput(entries) {
  return entries.map(([name, value]) => `${name}=${value}`).join("\n");
}

test("lastWriters records the last form that writes each name", () => {
  const writers = lastWriters(
    [
      'export ACCESS_TOKEN="oauth-token"',
      'export ACCESS_TOKEN_BASE64="b2F1dGg="',
      'export SECRET_TOKEN="vault-secret"',
    ].join("\n"),
  );

  assert.equal(writers.get("ACCESS_TOKEN"), "base64");
  assert.equal(writers.get("SECRET_TOKEN"), "plain");
});

test("lastWriters sees an _BASE64 entry as a writer of its bare name", () => {
  const writers = lastWriters('export CLIENT_ID_BASE64="YWJj"');

  assert.equal(writers.get("CLIENT_ID"), "base64");
  assert.equal(writers.has("CLIENT_ID_BASE64"), false);
});

test("lastWriters ignores comments and non-export lines", () => {
  const writers = lastWriters(
    ['# export IGNORED="x"', 'NAME="not-an-export"'].join("\n"),
  );

  assert.equal(writers.size, 0);
});

test("parseEnvOutput defers _BASE64 entries and keeps plain ones", () => {
  const { env, base64Entries } = parseEnvOutput(
    envOutput([
      ["ACCESS_TOKEN", "plain-token"],
      ["ACCESS_TOKEN_BASE64", b64("captured-token")],
    ]),
  );

  assert.equal(env.ACCESS_TOKEN, "plain-token");
  assert.deepEqual(base64Entries, [["ACCESS_TOKEN", b64("captured-token")]]);
});

test("a capture written after the plain entry wins, as bash resolves it", () => {
  // configure-oidc-with-kong-oauth2: extract_body writes the plain entry, then
  // the capture persists the same name. The captured value is authoritative.
  const file = [
    'export ACCESS_TOKEN="from-extract-body"',
    `export ACCESS_TOKEN_BASE64="${b64("from-capture")}"`,
  ].join("\n");

  const env = resolveEnvVars(
    envOutput([
      ["ACCESS_TOKEN", "from-extract-body"],
      ["ACCESS_TOKEN_BASE64", b64("from-capture")],
    ]),
    file,
  );

  assert.equal(env.ACCESS_TOKEN, "from-capture");
});

test("a plain entry written later wins over an earlier file's capture", () => {
  // The regression: enable-oauth2/capture runs earlier in the batch and leaves
  // ACCESS_TOKEN_BASE64 behind; enable-vault-authentication then sets
  // ACCESS_TOKEN plainly from its own credentials response. The earlier capture
  // must not shadow the newer value.
  const file = [
    'export ACCESS_TOKEN="oauth-access-token"',
    `export ACCESS_TOKEN_BASE64="${b64("oauth-access-token")}"`,
    'export ACCESS_TOKEN="vault-consumer-access-token"',
  ].join("\n");

  const env = resolveEnvVars(
    envOutput([
      ["ACCESS_TOKEN", "vault-consumer-access-token"],
      ["ACCESS_TOKEN_BASE64", b64("oauth-access-token")],
    ]),
    file,
  );

  assert.equal(env.ACCESS_TOKEN, "vault-consumer-access-token");
});

test("an _BASE64 entry with no plain counterpart is decoded", () => {
  const env = resolveEnvVars(
    envOutput([["CERT_BASE64", b64("line1\nline2")]]),
    'export CERT_BASE64="bGluZTEKbGluZTI="',
  );

  assert.equal(env.CERT, "line1\nline2");
});

test("a multi-line value persisted after its plain entry survives", () => {
  const certificate = "-----BEGIN CERT-----\nABCDEF\n-----END CERT-----";
  const env = resolveEnvVars(
    envOutput([
      ["CERT", "placeholder"],
      ["CERT_BASE64", b64(certificate)],
    ]),
    [
      'export CERT="placeholder"',
      `export CERT_BASE64="${b64(certificate)}"`,
    ].join("\n"),
  );

  assert.equal(env.CERT, certificate);
});

test("an unreadable env file keeps the encoded value rather than dropping it", () => {
  const env = resolveEnvVars(
    envOutput([["TOKEN_BASE64", b64("persisted")]]),
    undefined,
  );

  assert.equal(env.TOKEN, "persisted");
});

test("plain entries unrelated to any capture pass through untouched", () => {
  const env = resolveEnvVars(
    envOutput([
      ["VAULT_HOST", "vault"],
      ["VAULT_TOKEN", "root"],
    ]),
    ['export VAULT_HOST="vault"', 'export VAULT_TOKEN="root"'].join("\n"),
  );

  assert.equal(env.VAULT_HOST, "vault");
  assert.equal(env.VAULT_TOKEN, "root");
});
