import {
  configuration, discovery, redirectUri, transaction, transactionCookie, noStoreHeaders,
} from "../utils/oidc.mjs";

export default async function handler(request) {
  if (request.method !== "GET") return new Response("Method Not Allowed", { status: 405 });

  // Netlify dev can be opened at 127.0.0.1 while the OAuth client has a
  // localhost callback. Redirect before setting the host-only state cookie.
  const requestUrl = new URL(request.url);
  if (requestUrl.protocol === "http:" &&
      (requestUrl.hostname === "127.0.0.1" || requestUrl.hostname === "[::1]")) {
    requestUrl.hostname = "localhost";
    return new Response(null, {
      status: 302,
      headers: noStoreHeaders({ Location: requestUrl.href }),
    });
  }

  try {
    const config = configuration();
    const metadata = await discovery(config);
    const tx = transaction(request);
    const authorizationUrl = new URL(metadata.authorization_endpoint);
    authorizationUrl.searchParams.set("response_type", "code");
    authorizationUrl.searchParams.set("client_id", config.clientId);
    authorizationUrl.searchParams.set("redirect_uri", redirectUri(request));
    authorizationUrl.searchParams.set("scope", "openid");
    authorizationUrl.searchParams.set("state", tx.state);
    authorizationUrl.searchParams.set("nonce", tx.nonce);
    authorizationUrl.searchParams.set("code_challenge", tx.challenge);
    authorizationUrl.searchParams.set("code_challenge_method", "S256");

    const cookieValue = Buffer.from(JSON.stringify(tx)).toString("base64url");
    return new Response(null, {
      status: 302,
      headers: noStoreHeaders({
        Location: authorizationUrl.href,
        "Set-Cookie": transactionCookie(request, cookieValue, 600),
      }),
    });
  } catch (error) {
    console.error("OIDC login failed:", error);
    return new Response("Login is unavailable. Please try again later.", {
      status: 503,
      headers: noStoreHeaders({ "Content-Type": "text/plain; charset=utf-8" }),
    });
  }
}

export const config = { path: "/auth/login" };
