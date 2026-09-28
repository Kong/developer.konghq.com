import { createHash, randomBytes } from "node:crypto";
import { createRemoteJWKSet, jwtVerify } from "jose";

export const TOKEN_STORAGE_KEY = "oidc_id_token";
export const PREFERRED_NAME_STORAGE_KEY = "oidc_preferred_name";
export const ORGANIZATION_NAME_STORAGE_KEY = "oidc_organization_name";

const allowedAlgorithms = [
  "RS256", "RS384", "RS512",
  "PS256", "PS384", "PS512",
  "ES256", "ES384", "ES512",
  "EdDSA",
];

export function configuration() {
  const { OIDC_ISSUER, OIDC_CLIENT_ID, OIDC_CLIENT_SECRET } = process.env;
  if (!OIDC_ISSUER || !OIDC_CLIENT_ID || !OIDC_CLIENT_SECRET) {
    throw new Error("OIDC_ISSUER, OIDC_CLIENT_ID, and OIDC_CLIENT_SECRET must be set");
  }

  const issuer = new URL(OIDC_ISSUER);
  if (issuer.protocol !== "https:" || issuer.search || issuer.hash) {
    throw new Error("OIDC_ISSUER must be an HTTPS URL without a query or fragment");
  }

  return {
    issuer: issuer.href.replace(/\/$/, ""),
    clientId: OIDC_CLIENT_ID,
    clientSecret: OIDC_CLIENT_SECRET,
  };
}

export async function discovery(config) {
  const response = await fetch(`${config.issuer}/.well-known/openid-configuration`);
  if (!response.ok) throw new Error("OIDC discovery failed");

  const metadata = await response.json();
  if (metadata.issuer !== config.issuer) {
    throw new Error("OIDC discovery issuer mismatch");
  }

  for (const key of ["authorization_endpoint", "token_endpoint", "jwks_uri"]) {
    if (!metadata[key] || new URL(metadata[key]).protocol !== "https:") {
      throw new Error(`OIDC discovery has no secure ${key}`);
    }
  }

  return metadata;
}

export function redirectUri(request) {
  return new URL("/auth/callback", request.url).href;
}

export function safeReturnTo(value, origin) {
  if (!value || !value.startsWith("/") || value.startsWith("//") || value.includes("\\")) {
    return "/";
  }

  const url = new URL(value, origin);
  return url.origin === origin ? `${url.pathname}${url.search}${url.hash}` : "/";
}

export function transaction(request) {
  const state = randomBytes(32).toString("base64url");
  const nonce = randomBytes(32).toString("base64url");
  const verifier = randomBytes(32).toString("base64url");
  const challenge = createHash("sha256").update(verifier).digest("base64url");
  const url = new URL(request.url);

  return {
    state,
    nonce,
    verifier,
    challenge,
    returnTo: safeReturnTo(url.searchParams.get("return_to"), url.origin),
  };
}

export function cookieName(request) {
  return new URL(request.url).protocol === "https:" ? "__Host-oidc_transaction" : "oidc_transaction";
}

export function transactionCookie(request, value, maxAge) {
  const secure = new URL(request.url).protocol === "https:" ? "; Secure" : "";
  return `${cookieName(request)}=${value}; HttpOnly; SameSite=Lax; Path=/; Max-Age=${maxAge}${secure}`;
}

export function readTransaction(request) {
  const entry = request.headers.get("cookie")?.split(";").map((part) => part.trim()).find((part) =>
    part.startsWith(`${cookieName(request)}=`)
  );
  if (!entry) return null;

  try {
    return JSON.parse(Buffer.from(entry.split("=")[1], "base64url").toString("utf8"));
  } catch {
    return null;
  }
}

export async function exchangeCode(code, verifier, request, config, metadata) {
  const encodeCredential = (value) => new URLSearchParams({ value }).toString().slice(6);
  const credentials = Buffer.from(
    `${encodeCredential(config.clientId)}:${encodeCredential(config.clientSecret)}`
  ).toString("base64");
  const response = await fetch(metadata.token_endpoint, {
    method: "POST",
    headers: {
      Authorization: `Basic ${credentials}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "authorization_code",
      code,
      redirect_uri: redirectUri(request),
      code_verifier: verifier,
    }),
  });
  if (!response.ok) throw new Error("OIDC token exchange failed");

  const tokens = await response.json();
  if (typeof tokens.id_token !== "string") throw new Error("OIDC token response has no ID token");
  return tokens;
}

async function fetchKonnectField(accessToken, path, fields) {
  if (typeof accessToken !== "string" || !accessToken) {
    throw new Error("OIDC token response has no access token");
  }

  const response = await fetch(`https://global.api.konghq.com/v3/${path}`, {
    headers: {
      Authorization: `Bearer ${accessToken}`,
      Accept: "application/json",
    },
    cache: "no-store",
  });
  if (!response.ok) throw new Error(`Konnect ${path} request failed (${response.status})`);

  const data = await response.json();
  for (const field of fields) {
    if (typeof data[field] === "string" && data[field].trim()) {
      return data[field].trim();
    }
  }
  throw new Error(`Konnect ${path} has no ${fields.join(" or ")}`);
}

export function fetchPreferredName(accessToken) {
  return fetchKonnectField(accessToken, "users/me", ["preferred_name", "full_name"]);
}

export function fetchOrganizationName(accessToken) {
  return fetchKonnectField(accessToken, "organizations/me", ["name"]);
}

export async function verifyIdToken(idToken, nonce, config, metadata) {
  const algorithms = allowedAlgorithms.filter((algorithm) =>
    metadata.id_token_signing_alg_values_supported?.includes(algorithm)
  );
  if (algorithms.length === 0) throw new Error("OIDC provider has no supported ID token signing algorithm");

  const jwks = createRemoteJWKSet(new URL(metadata.jwks_uri));
  const { payload } = await jwtVerify(idToken, jwks, {
    issuer: config.issuer,
    audience: config.clientId,
    algorithms,
    requiredClaims: ["sub", "exp", "iat", "nonce"],
  });
  if (payload.nonce !== nonce || typeof payload.sub !== "string" || !payload.sub) {
    throw new Error("OIDC ID token has invalid nonce or subject");
  }
  if (Array.isArray(payload.aud) && payload.aud.length > 1 && payload.azp !== config.clientId) {
    throw new Error("OIDC ID token has invalid authorized party");
  }
  return payload;
}

export function noStoreHeaders(extra = {}) {
  return { "Cache-Control": "no-store", "Referrer-Policy": "no-referrer", ...extra };
}
