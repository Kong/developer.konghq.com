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
{{site.kong_harnesses}} isn't tested with these identity providers, so test the settings in a non-production deployment first.

## Auth0

* Issuer: Use `https://YOUR_AUTH0_DOMAIN/`, with the trailing slash.
* Client: Create a **Native** application, which Auth0 registers as a public application with the token endpoint authentication method **None**, as [Confidential and Public Applications](https://auth0.com/docs/get-started/applications/confidential-and-public-applications) describes.
* Consent: Auth0 can show a confirmation prompt for a loopback callback, such as `localhost` or `127.0.0.1`, even when **Allow Skipping User Consent** is on in the API.
  It shows the prompt only when the user didn't see another screen, such as MFA, before it, as [Measures Against Application Impersonation](https://auth0.com/docs/secure/security-guidance/measures-against-app-impersonation) describes.
* Offline access: Turn on **Allow Offline Access** in the API of the gateway, as [API Settings](https://auth0.com/docs/get-started/apis/api-settings) describes.
  To use rotating refresh tokens, turn on **Allow Refresh Token Rotation** under **Refresh Token Rotation** in the settings of the native application.
  Keep **Rotation Overlap Period** at 0, because Auth0 doesn't detect the reuse of a refresh token during that period, as [Configure Refresh Token Rotation](https://auth0.com/docs/secure/tokens/refresh-tokens/configure-refresh-token-rotation) describes.
* Audience: Register the gateway as an API, with an identifier that is an absolute URI, such as `https://gateway.example.com/api`.
  Set `--audience` to the identifier of the API, and set `--audience-parameter audience`.
* Access token lifetime: Auth0 issues access tokens for 24 hours by default, as [Token Settings](https://auth0.com/docs/get-started/apis/api-settings#token-settings) describes.
  Set `--max-token-lifetime-seconds 86400`, or set the token lifetime of the API from 365 to 3600 seconds.

## Keycloak

* Issuer: Use the `issuer` value from the discovery document of the realm, such as `https://KEYCLOAK_HOST/realms/REALM_NAME`.
  If your deployment has a [context path](https://www.keycloak.org/server/reverseproxy#_different_context_path_on_reverse_proxy), such as `/auth`, the issuer includes it.
* Client: Create an OpenID Connect client with **Client authentication** off, which makes it a public client, and with **Standard Flow** on.
  Set its **PKCE method** to `S256`, as the [Server Administration Guide](https://www.keycloak.org/docs/latest/server_admin/index.html) describes.
  By default, the discovery document doesn't list `none` in `token_endpoint_auth_methods_supported`, so test the client with `--public-client-evidence deployment`, as [Discovery document](/kong-harnesses/identity-provider/#discovery-document) describes.
* Consent: Keycloak shows the consent screen only when consent is on for the client.
* Offline access: Keep `offline_access` as an optional client scope of the client.
  Check that users have the realm role `offline_access`, and that the **Scope** tab of the `offline_access` client scope maps that role.
* Scopes: The token response names each default client scope of the client that has **Include in token scope** on, as [Include in token scope](https://www.keycloak.org/docs/latest/server_admin/index.html#include-in-token-scope) describes.
  The response can't name a scope that the profile doesn't request, and a response with `scope` must keep every custom scope that the profile requests, as [Token responses](/kong-harnesses/identity-provider/checks/#token-responses) describes.
  **Include in token scope** is a setting of the shared client scope, so changing it alters the `scope` claim for every other client linked to that scope.
  In the **Client scopes** tab of the {{site.kong_harnesses}} client, find each default client scope that the profile doesn't request and that has **Include in token scope** on, as [Link client scope with the client](https://www.keycloak.org/docs/latest/server_admin/index.html#_client_scopes_linking) describes.
  Before you unlink a scope, pick the first change in this list that applies to it:

  * If the {{site.kong_harnesses}} client doesn't need the mappers or the role scope mappings of the scope, unlink the scope from the client.
  * If every other client linked to the scope needs **Include in token scope** off too, keep the link and turn **Include in token scope** off on the scope.
  * If another linked client needs **Include in token scope** on and the scope doesn't have role scope mappings, unlink the scope and add its mappers to the [dedicated client scope](https://www.keycloak.org/docs/latest/server_admin/index.html#_client_scopes_dedicated) of the client.
  * If another linked client needs **Include in token scope** on and the scope has role scope mappings, create a client scope with the same mappers and role scope mappings, and turn **Include in token scope** off on it.
    Link the new scope as a default client scope only to the {{site.kong_harnesses}} client, and unlink the shared scope.
    Don't add these mappers to the dedicated client scope, because Keycloak applies a client scope with role scope mappings only for users who have one of its roles, as [Client scopes permissions](https://www.keycloak.org/docs/latest/server_admin/index.html#client-scopes-permissions) describes, and the dedicated client scope doesn't make that check.

  Keep `openid` and `offline_access` in the scopes that the profile requests.
  `openid` is a protocol value, so it has no client scope to link.
  Link each other scope that the profile requests to the client as a default client scope, or as an optional client scope, which Keycloak applies because the profile requests it, as [Link client scope with the client](https://www.keycloak.org/docs/latest/server_admin/index.html#_client_scopes_linking) describes.
  For example, link `profile` and `email` when the profile uses the default `--scope` list.
  Keep **Include in token scope** on for each custom scope that the profile requests, because the response must keep it.
  If such a custom scope has role scope mappings, Keycloak leaves it out of the token and out of `scope` for a user who has none of its roles, as [Client scopes permissions](https://www.keycloak.org/docs/latest/server_admin/index.html#client-scopes-permissions) describes, so the sign-in of that user fails.
  Check that each user who signs in has at least one role of each such scope.
  For `profile`, `email`, `offline_access` and the other scopes that [Token responses](/kong-harnesses/identity-provider/checks/#token-responses) lists as exceptions, the setting can be on or off.
* Refresh token rotation: You can keep **Revoke Refresh Token** off.
  When **Use Refresh Tokens** is on, Keycloak sends a new refresh token in each successful renewal response.
  If you turn on **Revoke Refresh Token** in the **Tokens** tab of the realm settings, as [Session and token timeouts](https://www.keycloak.org/docs/latest/server_admin/index.html#_timeouts) describes, keep **Refresh Token Max Reuse** at 0.
  This setting is the number of times that a client can use a refresh token again, so a higher value lets a copied refresh token stay usable.
* Audience: Set `--audience-parameter none`, so that the sign-in request doesn't send `resource` and the Audience mapper is the only source of the gateway audience.
  In the dedicated client scope of the client, add an Audience mapper, and set its **Included Custom Audience** to the `--audience` value.
  Keep **Add to ID token** off in the mapper, as it is by default ([Hardcoded audience](https://www.keycloak.org/docs/latest/server_admin/index.html#_audience_hardcoded)), because the [ID token](/kong-harnesses/identity-provider/checks/#id-token) check accepts only the client ID in `aud`.
  The dedicated client scope isn't named in the scope list of the token response, so it passes the scope check of {{site.kong_harnesses}}.
  If you use a shared client scope instead, assign it to the client as a default client scope, because the profile doesn't request it by name, and turn off **Include in token scope** in it.
  Use a shared client scope this way only when the other clients linked to it need **Include in token scope** off too.
* Access token lifetime: Set the **Access Token Lifespan** of the realm, or of the client, from 7 to 60 minutes, as [Session and token timeouts](https://www.keycloak.org/docs/latest/server_admin/index.html#_timeouts) describes.
  For longer lifespans, see [Access token lifetime](/kong-harnesses/identity-provider/#access-token-lifetime).

## Microsoft Entra ID

* Issuer: Use the issuer of your tenant, `https://login.microsoftonline.com/TENANT_ID/v2.0`, not `common`, `organizations` or `consumers`.
* Client: Under **Authentication**, set **Allow public client flows** to **Yes**, and don't add a client secret, as [Configure desktop apps that call web APIs](https://learn.microsoft.com/en-us/entra/identity-platform/scenario-desktop-app-configuration) describes.
  The discovery document doesn't list `none` in `token_endpoint_auth_methods_supported`, so test the client with `--public-client-evidence deployment`, as [Discovery document](/kong-harnesses/identity-provider/#discovery-document) describes.
* Callback: Register the callback under **Mobile and desktop applications**.
  Entra ID ignores the port only for a `localhost` callback, and doesn't accept `[::1]`, as [Redirect URI best practices](https://learn.microsoft.com/en-us/entra/identity-platform/reply-url) describes.
  So register one `localhost` callback for each path, not one for each port, because Entra ID picks one of several that differ only by port, as [localhost exceptions](https://learn.microsoft.com/en-us/entra/identity-platform/reply-url#localhost-exceptions) describes.
  The Azure portal doesn't accept an `http` callback with `127.0.0.1`, so register a `localhost` callback there.
  To register a `127.0.0.1` callback, add it to `publicClient.redirectUris` in the [application manifest](https://learn.microsoft.com/en-us/entra/identity-platform/reference-microsoft-graph-app-manifest#publicclient-attribute), keep every redirect URI that is already there, and include the port that the profile uses, because each `127.0.0.1` port is its own redirect URI in the same app registration:

  ```json
  "publicClient": {
    "redirectUris": [
      "http://127.0.0.1:9876/callback"
    ]
  }
  ```

  The older [Azure AD Graph format](https://learn.microsoft.com/en-us/entra/identity-platform/reference-app-manifest) of the manifest names this attribute `replyUrlsWithType`.

* Audience: Set `--audience` to the Application ID URI of the gateway API, and set `--audience-parameter none`.
  In the client, select **API permissions** > **Add a permission** > **My APIs**, select the gateway API, and add its delegated permission, as [Configure app permissions for a web API](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-configure-app-access-web-apis#add-permissions-to-access-your-web-api) describes.
  Grant admin consent if the tenant or the API scope needs it.
  Give the full URI of the API scope, such as `api://API_ID/access_as_user`, with its own `--scope` flag, as [Gateway audience](/kong-harnesses/identity-provider/#gateway-audience) describes.
* Token version: Set `api.requestedAccessTokenVersion` to `2` in the [manifest](https://learn.microsoft.com/en-us/entra/identity-platform/reference-microsoft-graph-app-manifest) of the gateway API to get v2.0 access tokens.
  When `api.requestedAccessTokenVersion` is `null` or `1`, Entra ID issues v1.0 access tokens.
  A v2.0 access token has the application ID of the gateway API, a GUID, in `aud`, and a v1.0 access token can have the application ID or the Application ID URI.
  Put the value that your tokens have in `config.audience_required`.
* Access token lifetime: Entra ID issues access tokens for 60 to 90 minutes by default, as [Configurable token lifetimes](https://learn.microsoft.com/en-us/entra/identity-platform/configurable-token-lifetimes#access-tokens) describes.
  For these default lifetimes, set `--max-token-lifetime-seconds 5400`.
  If a token lifetime policy applies to the gateway API, set the value to the longest access token lifetime of that policy.

## PingFederate

* Issuer: Use the `issuer` value from the [OpenID Provider configuration](https://docs.pingidentity.com/pingfederate/13.1/developers_reference_guide/pf_openid_provider_config_endpoint.html) of PingFederate, which is the base URL of the deployment, such as `https://PINGFEDERATE_HOST`.
  Include the port when it isn't 443, such as `https://PINGFEDERATE_HOST:9031`.
* Client: Create an OAuth client with **Client Authentication** set to **None**, and select only the **Authorization Code** and **Refresh Token** grant types.
  Select **Require Proof Key for Code Exchange (PKCE)** in the client, as [Configuring OAuth clients](https://docs.pingidentity.com/pingfederate/12.3/administrators_reference_guide/pf_configuring_oauth_clients.html) describes.
  Select **Disallow the Plain PKCE Code Challenge Method** in the [authorization server settings](https://docs.pingidentity.com/pingfederate/12.3/administrators_reference_guide/help_authorizationserversettingstasklet_oauthauthorizationserversettingsstate.html).
  The discovery document can leave out `none` in `token_endpoint_auth_methods_supported`, as in the example of the [OpenID Provider configuration](https://docs.pingidentity.com/pingfederate/13.1/developers_reference_guide/pf_openid_provider_config_endpoint.html).
  If it does, add `none` to the discovery template, or test the client with `--public-client-evidence deployment`, as [Discovery document](/kong-harnesses/identity-provider/#discovery-document) describes.
* ID token: Configure an OpenID Connect policy in **Applications > OAuth > OpenID Connect Policy Management**, as the prerequisites of [Create an OAuth or OpenID Connect application in PingFederate](https://docs.pingidentity.com/solution-guides/customer_use_cases/htg_oidc_app_setup_pf.html) list.
  In the **Policy** list of the client, select that policy, or keep the default policy if it applies.
* Audience: Keep `--audience-parameter resource`, and create a JWT access token management instance for the gateway.
  Sign its access tokens with an asymmetric key, and set its **Type Header Value** to `at+jwt`.
  Add the `--audience` value to its **Resource URIs**, and set its **Audience Claim Value** to the `--audience` value.
  Select the instance as the **Default Access Token Manager** of the client, as [Configuring OAuth clients](https://docs.pingidentity.com/pingfederate/12.3/administrators_reference_guide/pf_configuring_oauth_clients.html) describes, because the code exchange and the renewal request don't send `resource`.
* Access token lifetime: The JWT access token management instance sets the lifetime in whole minutes, and it issues access tokens for 120 minutes by default, as [Configuring an access token management instance](https://docs.pingidentity.com/pingfederate/12.3/administrators_reference_guide/pf_configuring_access_token_management_instance.html) describes.
  Set its **Token Lifetime** from 7 to 60 minutes, or keep 120 minutes and set `--max-token-lifetime-seconds 7200`.
