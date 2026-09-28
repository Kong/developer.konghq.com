import { randomBytes, timingSafeEqual } from "node:crypto";
import {
  configuration, discovery, exchangeCode, fetchControlPlanes, fetchOrganizationName, fetchPreferredName,
  noStoreHeaders, readTransaction, CONTROL_PLANES_STORAGE_KEY, ORGANIZATION_NAME_STORAGE_KEY,
  PREFERRED_NAME_STORAGE_KEY, TOKEN_STORAGE_KEY, transactionCookie, verifyIdToken, safeReturnTo,
} from "../utils/oidc.mjs";

function sameState(expected, actual) {
  if (typeof expected !== "string" || typeof actual !== "string") return false;
  const a = Buffer.from(expected);
  const b = Buffer.from(actual);
  return a.length === b.length && timingSafeEqual(a, b);
}

function scriptValue(value) {
  return JSON.stringify(value).replace(/</g, "\\u003c").replace(/&/g, "\\u0026");
}

function page(script, message, status, clearCookie) {
  const nonce = randomBytes(16).toString("base64");
  const html = `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Log in</title></head><body><p>${message}</p><script nonce="${nonce}">${script}</script></body></html>`;
  return new Response(html, {
    status,
    headers: noStoreHeaders({
      "Content-Type": "text/html; charset=utf-8",
      "Content-Security-Policy": `default-src 'none'; script-src 'nonce-${nonce}'; base-uri 'none'; form-action 'none'`,
      "X-Content-Type-Options": "nosniff",
      "Set-Cookie": clearCookie,
    }),
  });
}

export default async function handler(request) {
  if (request.method !== "GET") return new Response("Method Not Allowed", { status: 405 });

  const clearCookie = transactionCookie(request, "", 0);
  const url = new URL(request.url);
  const tx = readTransaction(request);

  if (url.searchParams.has("error") || !tx || !sameState(tx.state, url.searchParams.get("state")) ||
      !tx.verifier || !tx.nonce || !tx.returnTo || !url.searchParams.get("code")) {
    return page("", 'Login failed. <a href="/auth/login">Try again</a>.', 400, clearCookie);
  }

  try {
    const config = configuration();
    const metadata = await discovery(config);
    const tokens = await exchangeCode(url.searchParams.get("code"), tx.verifier, request, config, metadata);
    const identity = await verifyIdToken(tokens.id_token, tx.nonce, config, metadata);

    if (process.env.OIDC_DEBUG_TOKENS === "true" &&
        ["localhost", "127.0.0.1", "[::1]"].includes(url.hostname)) {
      console.log("OIDC access token (local debug):", tokens.access_token);
    }

    const [preferredNameResult, organizationNameResult, controlPlanesResult] = await Promise.allSettled([
      fetchPreferredName(tokens.access_token),
      fetchOrganizationName(tokens.access_token),
      fetchControlPlanes(tokens.access_token),
    ]);
    if (preferredNameResult.status === "rejected") {
      console.error("Konnect profile lookup failed:", preferredNameResult.reason);
    }
    if (organizationNameResult.status === "rejected") {
      console.error("Konnect organization lookup failed:", organizationNameResult.reason);
    }
    if (controlPlanesResult.status === "rejected") {
      console.error("Konnect control plane lookup failed:", controlPlanesResult.reason);
    }
    const preferredName = preferredNameResult.status === "fulfilled" ? preferredNameResult.value : null;
    const organizationName = organizationNameResult.status === "fulfilled" ? organizationNameResult.value : null;
    const controlPlanes = controlPlanesResult.status === "fulfilled" ? controlPlanesResult.value : [];

    // The callback is on the same origin as the site. Keep the token out of URLs,
    // referrers, and analytics by writing it before navigating to the static page.
    const returnTo = safeReturnTo(tx.returnTo, url.origin);
    const profileScript = preferredName
      ? `localStorage.setItem(${scriptValue(PREFERRED_NAME_STORAGE_KEY)}, ${scriptValue(preferredName)});`
      : `localStorage.removeItem(${scriptValue(PREFERRED_NAME_STORAGE_KEY)});`;
    const organizationScript = organizationName
      ? `localStorage.setItem(${scriptValue(ORGANIZATION_NAME_STORAGE_KEY)}, ${scriptValue(organizationName)});`
      : `localStorage.removeItem(${scriptValue(ORGANIZATION_NAME_STORAGE_KEY)});`;
    const controlPlanesScript = `let previousControlPlanes; try { previousControlPlanes = JSON.parse(localStorage.getItem(${scriptValue(CONTROL_PLANES_STORAGE_KEY)})); } catch {} const controlPlanes = ${scriptValue(controlPlanes)}; const activeId = previousControlPlanes?.sub === ${scriptValue(identity.sub)} && controlPlanes.some((plane) => plane.id === previousControlPlanes.activeId) ? previousControlPlanes.activeId : (controlPlanes[0]?.id || null); localStorage.setItem(${scriptValue(CONTROL_PLANES_STORAGE_KEY)}, JSON.stringify({ sub: ${scriptValue(identity.sub)}, items: controlPlanes, activeId, error: ${controlPlanesResult.status === "rejected"} }));`;
    const script = `try { ${controlPlanesScript} localStorage.setItem(${scriptValue(TOKEN_STORAGE_KEY)}, ${scriptValue(tokens.id_token)}); ${profileScript} ${organizationScript} location.replace(${scriptValue(returnTo)}); } catch { document.body.textContent = "Login succeeded, but browser storage is unavailable."; }`;
    return page(script, "Finishing login…", 200, clearCookie);
  } catch (error) {
    console.error("OIDC callback failed:", error);
    return page("", 'Login failed. <a href="/auth/login">Try again</a>.', 400, clearCookie);
  }
}

export const config = { path: "/auth/callback" };
