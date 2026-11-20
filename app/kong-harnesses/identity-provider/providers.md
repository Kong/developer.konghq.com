---
title: "Identity provider settings for {{site.kong_harnesses}}"
description: "The settings that Auth0, Keycloak, Microsoft Entra ID and PingFederate need for the {{site.kong_harnesses}} sign-in client."
content_type: reference
layout: reference

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kong-harnesses

min_version:
  ai-gateway: '2.4'

tags:
  - cli
  - openid-connect

breadcrumbs:
  - /kong-harnesses/
  - /kong-harnesses/identity-provider/

related_resources:
  - text: Register kong-harnesses in your identity provider
    url: /kong-harnesses/identity-provider/
  - text: kong-harnesses profile create
    url: /kong-harnesses/profile/create/
---

These settings add to the client settings in [Register {{site.kong_harnesses}} in your identity provider](/kong-harnesses/identity-provider/).
They come from the documentation of each identity provider, and they aren't tested with {{site.kong_harnesses}}.
For Okta, see the prerequisites of [Set up {{ site.claude_code }} with kong-harnesses](/ai-gateway/set-up-claude-code-with-kong-harnesses/).

Before you give a profile to developers, check that the gateway accepts access tokens from a sign-in and from a renewal.

## Auth0

* Consent: Auth0 can show a confirmation prompt for a loopback callback, such as `localhost` or `127.0.0.1`, even when **Allow Skipping User Consent** is on in the API.
* Offline access: Turn on **Allow Offline Access** in the API of the gateway.
  Turn on **Refresh Token Rotation** for the native application, which also detects the reuse of a refresh token.
* Audience: Register the gateway as an API, with an identifier that is an absolute URI, such as `https://gateway.example.com/api`.
  Set `--audience` to the identifier of the API, and set `--audience-parameter audience`.
* Access token lifetime: Auth0 issues access tokens for 24 hours by default.
  Set `--max-token-lifetime-seconds 86400`, or reduce the token lifetime of the API to at most 3600 seconds.

## Keycloak

* Consent: Keycloak shows the consent screen only when consent is on for the client.
* Offline access: Keep `offline_access` as an optional client scope of the client.
  Check that users have the realm role `offline_access`, and that the **Scope** tab of the `offline_access` client scope maps that role.
* Refresh token rotation: If you turn on **Revoke Refresh Token**, keep **Refresh Token Max Reuse** at 0, because a higher value lets a replayed refresh token stay usable after rotation.
* Audience: Keycloak ignores the `resource` parameter by default, so set `--audience-parameter none`.
  In the dedicated client scope of the client, add an Audience mapper, and set its **Included Custom Audience** to the `--audience` value.
  The dedicated client scope isn't named in the scope list of the token response, so it passes the scope check of {{site.kong_harnesses}}.
  If you use a shared client scope, assign it to the client as a default client scope, because the profile doesn't request it by name, and turn off **Include in token scope** in it.
* Access token lifetime: Keycloak issues access tokens for 5 minutes by default, which is too short.
  Raise the access token lifespan of the realm or the client to at least 7 minutes.

## Microsoft Entra ID

* Issuer: Use the issuer of your tenant, `https://login.microsoftonline.com/TENANT_ID/v2.0`, not `common`, `organizations` or `consumers`.
* Callback: Register the callback under **Mobile and desktop applications**.
  Entra ID ignores the port only for a `localhost` callback, and doesn't accept `[::1]`.
  The Azure portal doesn't accept an `http` callback with `127.0.0.1`, so register a `localhost` callback there.
  To register a `127.0.0.1` callback, add it to `publicClient.redirectUris` in the application manifest, keep every redirect URI that is already there, and include the port that the profile uses:

  ```json
  "publicClient": {
    "redirectUris": [
      "http://127.0.0.1:9876/callback"
    ]
  }
  ```

* Public client: The discovery document doesn't list `none` in `token_endpoint_auth_methods_supported`, so test the client with `--public-client-evidence deployment`.
  See [Discovery document](/kong-harnesses/identity-provider/#discovery-document).
* Audience: Set `--audience` to the Application ID URI of the gateway API, and set `--audience-parameter none`.
  Give the client the delegated permission of the gateway API, and grant admin consent if the tenant or the API scope needs it.
  Give the full URI of the API scope with `--scope`.
* Token version: Set `api.requestedAccessTokenVersion` to `2` in the [manifest](https://learn.microsoft.com/en-us/entra/identity-platform/reference-microsoft-graph-app-manifest) of the gateway API to get v2.0 access tokens.
  With `null` or `1`, Entra ID issues v1.0 access tokens.
  A v2.0 access token has the application ID of the gateway API, a GUID, in `aud`, and a v1.0 access token can have the application ID or the Application ID URI.
  Put the value that your tokens have in `config.audience_required`.
* Access token lifetime: Entra ID issues access tokens for 60 to 90 minutes by default.
  Set `--max-token-lifetime-seconds 5400`.

## PingFederate

* Audience: Keep `--audience-parameter resource`, and create a JWT access token management instance for the gateway.
  Sign its access tokens with an asymmetric key, and set its **Type Header Value** to `at+jwt`.
  Add the `--audience` value to its **Resource URIs**, and set its **Audience Claim Value** to the `--audience` value.
  Select the instance in the OpenID Connect policy of the client and as the **Default Access Token Manager** of the client, because the code exchange and the renewal request don't send `resource`.
