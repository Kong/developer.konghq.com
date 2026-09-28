import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { after, before, test } from "node:test";
import vm from "node:vm";
import { exportJWK, generateKeyPair, SignJWT } from "jose";
import login from "../netlify/functions/oidc-login.mjs";
import callback from "../netlify/functions/oidc-callback.mjs";
import { fetchControlPlanes } from "../netlify/utils/oidc.mjs";

const originalFetch = globalThis.fetch;
const originalEnv = {
  OIDC_ISSUER: process.env.OIDC_ISSUER,
  OIDC_CLIENT_ID: process.env.OIDC_CLIENT_ID,
  OIDC_CLIENT_SECRET: process.env.OIDC_CLIENT_SECRET,
  OIDC_DEBUG_TOKENS: process.env.OIDC_DEBUG_TOKENS,
  KONNECT_CONTROL_PLANE_API_BASE_URL: process.env.KONNECT_CONTROL_PLANE_API_BASE_URL,
};

const issuer = "https://identity.example.test";
const metadata = {
  issuer,
  authorization_endpoint: `${issuer}/authorize`,
  token_endpoint: `${issuer}/token`,
  jwks_uri: `${issuer}/keys`,
  id_token_signing_alg_values_supported: ["RS256"],
};

let privateKey;
let publicJwk;
let issuedToken;
let tokenRequests = 0;
let profileRequests = 0;
let profileStatus = 200;
let profileName = "Ada";
let profileFullName = "Ada Lovelace";
let organizationRequests = 0;
let organizationStatus = 200;
let organizationName = "Kong";
let controlPlaneRequests = 0;
let controlPlaneStatus = 200;
let paginateControlPlanes = false;
let controlPlaneName = "Alpha";

before(async () => {
  process.env.OIDC_ISSUER = issuer;
  process.env.OIDC_CLIENT_ID = "docs-client";
  process.env.OIDC_CLIENT_SECRET = "docs-secret";
  const keys = await generateKeyPair("RS256");
  privateKey = keys.privateKey;
  publicJwk = { ...await exportJWK(keys.publicKey), kid: "key-1", alg: "RS256", use: "sig" };

  globalThis.fetch = async (input, options) => {
    const url = String(input);
    if (url === `${issuer}/.well-known/openid-configuration`) return Response.json(metadata);
    if (url === metadata.jwks_uri) return Response.json({ keys: [publicJwk] });
    if (url === metadata.token_endpoint) {
      tokenRequests++;
      assert.equal(options.method, "POST");
      assert.equal(options.body.get("grant_type"), "authorization_code");
      assert.equal(options.body.get("redirect_uri"), "http://localhost:8888/auth/callback");
      assert.ok(options.body.get("code_verifier"));
      return Response.json({ id_token: issuedToken, access_token: "konnect-access-token" });
    }
    if (url === "https://global.api.konghq.com/v3/users/me") {
      profileRequests++;
      assert.equal(options.headers.Authorization, "Bearer konnect-access-token");
      return Response.json({ preferred_name: profileName, full_name: profileFullName }, { status: profileStatus });
    }
    if (url === "https://global.api.konghq.com/v3/organizations/me") {
      organizationRequests++;
      assert.equal(options.headers.Authorization, "Bearer konnect-access-token");
      return Response.json({ name: organizationName }, { status: organizationStatus });
    }
    if (url.startsWith("https://us.api.konghq.com/v2/control-planes")) {
      controlPlaneRequests++;
      assert.equal(options.headers.Authorization, "Bearer konnect-access-token");
      if (url.endsWith("?page=2")) {
        return Response.json({ data: [{ id: "cp-2", name: "Beta" }] });
      }
      return Response.json({
        data: [{ id: "cp-1", name: controlPlaneName }],
        meta: { page: { next: paginateControlPlanes ? "?page=2" : null } },
      }, { status: controlPlaneStatus });
    }
    throw new Error(`Unexpected request: ${url}`);
  };
});

after(() => {
  globalThis.fetch = originalFetch;
  for (const [key, value] of Object.entries(originalEnv)) {
    if (value === undefined) delete process.env[key];
    else process.env[key] = value;
  }
});

async function startLogin(returnTo = "/guides/?topic=auth") {
  const request = new Request(`http://localhost:8888/auth/login?return_to=${encodeURIComponent(returnTo)}`);
  const response = await login(request);
  assert.equal(response.status, 302);
  const location = new URL(response.headers.get("location"));
  const cookie = response.headers.get("set-cookie").split(";")[0];
  return { response, location, cookie };
}

async function signToken(nonce, overrides = {}) {
  return new SignJWT({ sub: "user-123", nonce, ...overrides })
    .setProtectedHeader({ alg: "RS256", kid: "key-1" })
    .setIssuer(issuer)
    .setAudience("docs-client")
    .setIssuedAt()
    .setExpirationTime("5m")
    .sign(privateKey);
}

test("authorization request uses code flow, PKCE, and a host-only transaction cookie", async () => {
  const { response, location, cookie } = await startLogin();
  assert.equal(location.searchParams.get("response_type"), "code");
  assert.equal(location.searchParams.get("scope"), "openid");
  assert.equal(location.searchParams.get("code_challenge_method"), "S256");
  assert.equal(location.searchParams.get("redirect_uri"), "http://localhost:8888/auth/callback");
  assert.ok(location.searchParams.get("state"));
  assert.ok(location.searchParams.get("nonce"));
  const tx = JSON.parse(Buffer.from(cookie.split("=")[1], "base64url").toString());
  assert.equal(tx.returnTo, "/guides/?topic=auth");
  assert.equal(tx.challenge, createHash("sha256").update(tx.verifier).digest("base64url"));
  assert.match(response.headers.get("set-cookie"), /HttpOnly; SameSite=Lax/);
});

test("loopback login moves to localhost before creating the transaction", async () => {
  const response = await login(new Request(
    "http://127.0.0.1:8888/auth/login?return_to=%2Fguides%2F"
  ));
  assert.equal(response.status, 302);
  assert.equal(response.headers.get("location"),
    "http://localhost:8888/auth/login?return_to=%2Fguides%2F");
  assert.equal(response.headers.get("set-cookie"), null);
});

test("callback validates the ID token before returning browser storage script", async () => {
  const { location, cookie } = await startLogin("/guides/?topic=auth");
  issuedToken = await signToken(location.searchParams.get("nonce"));
  const request = new Request(
    `http://localhost:8888/auth/callback?code=abc&state=${location.searchParams.get("state")}`,
    { headers: { Cookie: cookie } }
  );
  const response = await callback(request);
  const html = await response.text();
  assert.equal(response.status, 200);
  assert.match(html, /localStorage\.setItem\("oidc_id_token"/);
  assert.match(html, /localStorage\.setItem\("oidc_preferred_name", "Ada"\)/);
  assert.match(html, /localStorage\.setItem\("oidc_organization_name", "Kong"\)/);
  assert.match(html, /localStorage\.setItem\("oidc_control_planes"/);
  assert.match(html, /location\.replace\("\/guides\/\?topic=auth"\)/);
  assert.match(html, /user-123|eyJ/);
  assert.equal(response.headers.get("cache-control"), "no-store");
  assert.equal(response.headers.get("referrer-policy"), "no-referrer");
  assert.match(response.headers.get("set-cookie"), /Max-Age=0/);
});

test("control plane lookup follows pages and defaults to the first plane", async () => {
  paginateControlPlanes = true;
  try {
    assert.deepEqual(await fetchControlPlanes("konnect-access-token"), [
      { id: "cp-1", name: "Alpha" },
      { id: "cp-2", name: "Beta" },
    ]);
    const { location, cookie } = await startLogin();
    issuedToken = await signToken(location.searchParams.get("nonce"));
    const response = await callback(new Request(
      `http://localhost:8888/auth/callback?code=abc&state=${location.searchParams.get("state")}`,
      { headers: { Cookie: cookie } }
    ));
    const html = await response.text();
    const values = new Map();
    const localStorage = {
      getItem: (key) => values.get(key) ?? null,
      setItem: (key, value) => values.set(key, value),
    };
    const script = html.match(/<script nonce="[^"]+">([^]*?)<\/script>/)[1];
    vm.runInNewContext(script, { localStorage, location: { replace() {} }, document: {} });
    assert.deepEqual(JSON.parse(values.get("oidc_control_planes")), {
      sub: "user-123",
      items: [{ id: "cp-1", name: "Alpha" }, { id: "cp-2", name: "Beta" }],
      activeId: "cp-1",
      error: false,
    });
    values.set("oidc_control_planes", JSON.stringify({
      sub: "user-123", items: [], activeId: "cp-2",
    }));
    vm.runInNewContext(script, { localStorage, location: { replace() {} }, document: {} });
    assert.equal(JSON.parse(values.get("oidc_control_planes")).activeId, "cp-2");
  } finally {
    paginateControlPlanes = false;
  }
});

test("control plane lookup failure leaves login valid without stale planes", async () => {
  const { location, cookie } = await startLogin();
  issuedToken = await signToken(location.searchParams.get("nonce"));
  controlPlaneStatus = 401;
  try {
    const response = await callback(new Request(
      `http://localhost:8888/auth/callback?code=abc&state=${location.searchParams.get("state")}`,
      { headers: { Cookie: cookie } }
    ));
    assert.equal(response.status, 200);
    assert.match(await response.text(), /items: controlPlanes, activeId, error: true/);
  } finally {
    controlPlaneStatus = 200;
  }
});

test("callback uses full_name when preferred_name is missing", async () => {
  const { location, cookie } = await startLogin();
  issuedToken = await signToken(location.searchParams.get("nonce"));
  profileName = undefined;
  try {
    const response = await callback(new Request(
      `http://localhost:8888/auth/callback?code=abc&state=${location.searchParams.get("state")}`,
      { headers: { Cookie: cookie } }
    ));
    assert.equal(response.status, 200);
    assert.match(await response.text(), /localStorage\.setItem\("oidc_preferred_name", "Ada Lovelace"\)/);
  } finally {
    profileName = "Ada";
  }
});

test("explicit local debug mode prints the exchanged access token", async () => {
  const { location, cookie } = await startLogin();
  issuedToken = await signToken(location.searchParams.get("nonce"));
  const originalLog = console.log;
  const messages = [];
  process.env.OIDC_DEBUG_TOKENS = "true";
  console.log = (...parts) => messages.push(parts);
  try {
    const response = await callback(new Request(
      `http://localhost:8888/auth/callback?code=abc&state=${location.searchParams.get("state")}`,
      { headers: { Cookie: cookie } }
    ));
    assert.equal(response.status, 200);
    assert.deepEqual(messages.find(([label]) => label === "OIDC access token (local debug):"),
      ["OIDC access token (local debug):", "konnect-access-token"]);
  } finally {
    console.log = originalLog;
    delete process.env.OIDC_DEBUG_TOKENS;
  }
});

test("callback rejects a state mismatch without exchanging the code", async () => {
  const { cookie } = await startLogin();
  const count = tokenRequests;
  const response = await callback(new Request(
    "http://localhost:8888/auth/callback?code=abc&state=wrong",
    { headers: { Cookie: cookie } }
  ));
  assert.equal(response.status, 400);
  assert.equal(tokenRequests, count);
});

test("callback rejects an ID token with the wrong nonce", async () => {
  const { location, cookie } = await startLogin();
  issuedToken = await signToken("wrong-nonce");
  const count = profileRequests;
  const orgCount = organizationRequests;
  const cpCount = controlPlaneRequests;
  const response = await callback(new Request(
    `http://localhost:8888/auth/callback?code=abc&state=${location.searchParams.get("state")}`,
    { headers: { Cookie: cookie } }
  ));
  assert.equal(response.status, 400);
  assert.doesNotMatch(await response.text(), /localStorage\.setItem/);
  assert.equal(profileRequests, count);
  assert.equal(organizationRequests, orgCount);
  assert.equal(controlPlaneRequests, cpCount);
});

test("profile failure leaves login valid and clears a previous name", async () => {
  const { location, cookie } = await startLogin();
  issuedToken = await signToken(location.searchParams.get("nonce"));
  profileStatus = 401;
  try {
    const response = await callback(new Request(
      `http://localhost:8888/auth/callback?code=abc&state=${location.searchParams.get("state")}`,
      { headers: { Cookie: cookie } }
    ));
    assert.equal(response.status, 200);
    const html = await response.text();
    assert.match(html, /localStorage\.setItem\("oidc_id_token"/);
    assert.match(html, /localStorage\.removeItem\("oidc_preferred_name"\)/);
    assert.match(html, /localStorage\.setItem\("oidc_organization_name", "Kong"\)/);
  } finally {
    profileStatus = 200;
  }
});

test("organization failure leaves login valid and clears a previous organization", async () => {
  const { location, cookie } = await startLogin();
  issuedToken = await signToken(location.searchParams.get("nonce"));
  organizationStatus = 401;
  try {
    const response = await callback(new Request(
      `http://localhost:8888/auth/callback?code=abc&state=${location.searchParams.get("state")}`,
      { headers: { Cookie: cookie } }
    ));
    assert.equal(response.status, 200);
    const html = await response.text();
    assert.match(html, /localStorage\.setItem\("oidc_preferred_name", "Ada"\)/);
    assert.match(html, /localStorage\.removeItem\("oidc_organization_name"\)/);
  } finally {
    organizationStatus = 200;
  }
});

test("callback escapes profile names before inserting them into HTML", async () => {
  const { location, cookie } = await startLogin();
  issuedToken = await signToken(location.searchParams.get("nonce"));
  profileName = "</script><script>alert(1)</script>";
  organizationName = "</script><script>alert(2)</script>";
  controlPlaneName = "</script><script>alert(3)</script>";
  try {
    const response = await callback(new Request(
      `http://localhost:8888/auth/callback?code=abc&state=${location.searchParams.get("state")}`,
      { headers: { Cookie: cookie } }
    ));
    const html = await response.text();
    assert.equal(response.status, 200);
    assert.doesNotMatch(html, /<script>alert\(1\)<\/script>/);
    assert.doesNotMatch(html, /<script>alert\(2\)<\/script>/);
    assert.doesNotMatch(html, /<script>alert\(3\)<\/script>/);
    assert.match(html, /\\u003cscript>/);
  } finally {
    profileName = "Ada";
    organizationName = "Kong";
    controlPlaneName = "Alpha";
  }
});

test("login prevents an external return URL", async () => {
  const { cookie } = await startLogin("//evil.example.test/path");
  const tx = JSON.parse(Buffer.from(cookie.split("=")[1], "base64url").toString());
  assert.equal(tx.returnTo, "/");
});

test("callback escapes return path text in its inline script", async () => {
  const { location, cookie } = await startLogin("/search/?q=</script><script>alert(1)</script>");
  issuedToken = await signToken(location.searchParams.get("nonce"));
  const response = await callback(new Request(
    `http://localhost:8888/auth/callback?code=abc&state=${location.searchParams.get("state")}`,
    { headers: { Cookie: cookie } }
  ));
  const html = await response.text();
  assert.equal(response.status, 200);
  assert.doesNotMatch(html, /<script>alert\(1\)<\/script>/);
  assert.match(html, /%3Cscript%3E/);
});
