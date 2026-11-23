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

Auth0, Keycloak, Microsoft Entra ID and PingFederate each need provider-specific settings for the {{site.kong_harnesses}} sign-in client, in addition to the [client settings](/kong-harnesses/identity-provider/#client-settings) that every identity provider needs.
{{site.kong_harnesses}} isn't tested with these identity providers, so test sign-in and token renewal in a non-production deployment before you give the profile to developers.

## Auth0

Auth0 needs the following settings for the {{site.kong_harnesses}} client:

* Issuer: Use `https://YOUR_AUTH0_DOMAIN/`, with the trailing slash.
* Client: Create a **Native** application, which Auth0 registers as a public application with the token endpoint authentication method **None**, as [Confidential and Public Applications](https://auth0.com/docs/get-started/applications/confidential-and-public-applications) describes.
* Consent: In the settings of the native application, under **Advanced** > **OAuth**, keep **Non-Verifiable Callback URI End-User Confirmation** enabled, as [Measures Against Application Impersonation](https://auth0.com/docs/secure/security-guidance/measures-against-app-impersonation) recommends.
  Auth0 then shows a confirmation prompt at each sign-in with a loopback callback, such as `localhost` or `127.0.0.1`, unless the user saw another screen, such as MFA, in the same sign-in.
* Offline access: Enable **Allow Offline Access** in the API of the gateway, as [API Settings](https://auth0.com/docs/get-started/apis/api-settings) describes.
  To use rotating refresh tokens, enable **Allow Refresh Token Rotation** under **Refresh Token Rotation** in the settings of the native application.
  Keep **Rotation Overlap Period** at 0, because Auth0 doesn't detect the reuse of a refresh token during that period, as [Configure Refresh Token Rotation](https://auth0.com/docs/secure/tokens/refresh-tokens/configure-refresh-token-rotation) describes.
* Audience: Register the gateway as an API, with an identifier that is an absolute URI, such as `https://gateway.example.com/api`.
  Set `--audience` to the identifier of the API, and set `--audience-parameter audience`.
  If **User-Delegated Access** of the API is **Per-app authorization**, grant the native application access to the API, as [Per-application permissions](https://auth0.com/docs/get-started/applications/application-access-to-apis-client-grants#per-application-permissions) describes.
* Access token lifetime: Auth0 issues access tokens for 24 hours by default, as [Token Settings](https://auth0.com/docs/get-started/apis/api-settings#token-settings) describes.
  Set `--max-token-lifetime-seconds 86400`, or set the token lifetime of the API from 365 to 3600 seconds.

## Keycloak

Keycloak needs the following settings for the {{site.kong_harnesses}} client:

* Issuer: Use the `issuer` value from the discovery document of the realm, such as `https://KEYCLOAK_HOST/realms/REALM_NAME`.
  If your deployment has a [context path](https://www.keycloak.org/server/reverseproxy#_different_context_path_on_reverse_proxy), such as `/auth`, the issuer includes it.
* Client: Create an OpenID Connect client, disable **Client authentication**, which makes it a public client, and enable **Standard flow**.
  Set its **PKCE Method** to `S256`, as [PKCE method](https://www.keycloak.org/docs/latest/server_admin/index.html#_proof-key-for-code-exchange) describes.
  By default, the discovery document doesn't list `none` in `token_endpoint_auth_methods_supported`, so test the client with `--public-client-evidence deployment`, as [Discovery document](/kong-harnesses/identity-provider/#discovery-document) describes.
* Consent: Keycloak shows the consent screen only when **Consent required** is on in the **Login settings** of the client.
* Offline access: Keep `offline_access` as an optional client scope of the client.
  Check that users have the realm role `offline_access`, and that the **Scope** tab of the `offline_access` client scope maps that role.
* Scopes: Link the scopes that the profile requests, and unlink or change the default client scopes that it doesn't request, as [Keycloak client scopes](#keycloak-client-scopes) describes.
* Refresh token rotation: When **Use refresh tokens** is on, Keycloak sends a new refresh token in each renewal response, unless a client policy with the `suppress-refresh-token-rotation` executor applies to the client, as [OIDC auth flows](https://www.keycloak.org/docs/latest/server_admin/index.html#con-oidc-auth-flows_server_administration_guide) describes.
  {{site.kong_harnesses}} works with and without a new refresh token in the renewal response, so **Revoke Refresh Token** can stay off.
  If you turn on **Revoke Refresh Token** in the **Tokens** tab of the realm settings, as [Session and token timeouts](https://www.keycloak.org/docs/latest/server_admin/index.html#_timeouts) describes, keep **Refresh Token Max Reuse** at 0, so that Keycloak accepts each refresh token only once.
* Audience: Set `--audience-parameter none`, so that the sign-in request doesn't send `resource` and the Audience mapper is the only source of the gateway audience.
  In the dedicated client scope of the client, add an Audience mapper, as [Hardcoded audience](https://www.keycloak.org/docs/latest/server_admin/index.html#_audience_hardcoded) describes, set its **Included Custom Audience** to the `--audience` value, and keep **Add to access token** on.
  Keep **Add to ID token** off, because the [ID token](/kong-harnesses/identity-provider/checks/#id-token) check accepts only the client ID in `aud`.
  The dedicated client scope isn't named in the scope list of the token response, so it passes the scope check of {{site.kong_harnesses}}.
  If you use a shared client scope instead, assign it to the client as a default client scope, because the profile doesn't request it by name, and turn off **Include in token scope** in it.
  Use a shared client scope this way only when the other clients linked to it need **Include in token scope** off too.
* Access token lifetime: Set the **Access Token Lifespan** of the realm, or of the client, from 7 to 60 minutes, as [Session and token timeouts](https://www.keycloak.org/docs/latest/server_admin/index.html#_timeouts) describes.
  For longer lifespans, see [Access token lifetime](/kong-harnesses/identity-provider/#access-token-lifetime).

### Keycloak client scopes

When **Include in token scope** is on for a default client scope of the client, Keycloak names that scope in the `scope` of the token response, as [Include in token scope](https://www.keycloak.org/docs/latest/server_admin/index.html#include-in-token-scope) describes.
The exception is a default client scope with role scope mappings, which Keycloak leaves out of the token and out of the token response for a user who doesn't have any of its roles, as [Client scopes permissions](https://www.keycloak.org/docs/latest/server_admin/index.html#client-scopes-permissions) describes.
The token response can't name a scope that the profile doesn't request, and a response with `scope` must keep every custom scope that the profile requests, as [Token responses](/kong-harnesses/identity-provider/checks/#token-responses) describes.

**Include in token scope** is a setting of the shared client scope, so a change to it changes the `scope` claim for every other client linked to that scope.
In the **Client scopes** tab of the {{site.kong_harnesses}} client, find each default client scope that the profile doesn't request and that has **Include in token scope** on, as [Link client scope with the client](https://www.keycloak.org/docs/latest/server_admin/index.html#_client_scopes_linking) describes.
For each of these scopes, make the change in the first row of the following table that applies to it:

{% table %}
columns:
  - title: When the scope
    key: when
  - title: Change
    key: change
rows:
  - when: "Doesn't have mappers or role scope mappings that the {{site.kong_harnesses}} client needs"
    change: "Unlink the scope from the client."
  - when: "Can have **Include in token scope** off for every other client linked to it"
    change: "Turn **Include in token scope** off on the scope."
  - when: "Must keep **Include in token scope** on for another client, and doesn't have role scope mappings"
    change: "Unlink the scope, and add its mappers to the [dedicated client scope](https://www.keycloak.org/docs/latest/server_admin/index.html#_client_scopes_dedicated) of the client."
  - when: "Must keep **Include in token scope** on for another client, and has role scope mappings"
    change: |
      Create a client scope with the same mappers and role scope mappings, and turn **Include in token scope** off on it.
      Link the new scope as a default client scope only to the {{site.kong_harnesses}} client, and unlink the shared scope.
      The dedicated client scope doesn't work here, because it applies its mappers without the role check of a client scope with role scope mappings.
{% endtable %}

Keep `openid` and `offline_access` in the scopes that the profile requests.
`openid` is a protocol value, so it doesn't have a client scope to link.
Link each other scope that the profile requests to the client as a default client scope, or as an optional client scope, which Keycloak applies because the profile requests it.
For example, link `profile` and `email` when the profile uses the default `--scope` list.

Keep **Include in token scope** on for each custom scope that the profile requests, because the token response must keep it.
If such a custom scope has role scope mappings, Keycloak leaves it out of the token and out of `scope` for a user who doesn't have any of its roles, so the sign-in of that user fails.
Check that each user who signs in has at least one role of each such scope.
For `profile`, `email`, `offline_access` and the other scopes that [Token responses](/kong-harnesses/identity-provider/checks/#token-responses) lists as exceptions, the setting can be on or off.

## Microsoft Entra ID

Microsoft Entra ID needs the following settings for the {{site.kong_harnesses}} client:

* Issuer: Use the issuer of your tenant, `https://login.microsoftonline.com/TENANT_ID/v2.0`, not `common`, `organizations` or `consumers`.
* Client: Don't add a client secret.
  The discovery document doesn't list `none` in `token_endpoint_auth_methods_supported`, so test the client with `--public-client-evidence deployment`, as [Discovery document](/kong-harnesses/identity-provider/#discovery-document) describes.
* Callback: Register the callback under **Mobile and desktop applications**, as [Configure desktop apps that call web APIs](https://learn.microsoft.com/en-us/entra/identity-platform/scenario-desktop-app-configuration) describes.
  Entra ID ignores the port only for a `localhost` callback, and doesn't accept `[::1]`, as [Redirect URI best practices](https://learn.microsoft.com/en-us/entra/identity-platform/reply-url) describes.
  Register one `localhost` callback for each path.
  Don't register several `localhost` callbacks that differ only by port, because Entra ID then uses only one of them, as [localhost exceptions](https://learn.microsoft.com/en-us/entra/identity-platform/reply-url#localhost-exceptions) describes.
  The Azure portal doesn't accept an `http` callback with `127.0.0.1`, so register a `localhost` callback there.
  To register a `127.0.0.1` callback, add it to `publicClient.redirectUris` in the [application manifest](https://learn.microsoft.com/en-us/entra/identity-platform/reference-microsoft-graph-app-manifest#publicclient-attribute), with the port that the profile uses.
  Keep the other redirect URIs in the list, because each `127.0.0.1` port is its own redirect URI in the same app registration.
  The following example shows the `publicClient` attribute with one `127.0.0.1` callback:

  ```json
  "publicClient": {
    "redirectUris": [
      "http://127.0.0.1:9876/callback"
    ]
  }
  ```

* Audience: Set `--audience` to the Application ID URI of the gateway API, and set `--audience-parameter none`.
  The gateway API must expose a delegated scope, as [Add a scope](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-configure-app-expose-web-apis#add-a-scope) describes.
  Add the delegated permission of the gateway API to the client, as [Configure app permissions for a web API](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-configure-app-access-web-apis#add-permissions-to-access-your-web-api) describes:

  1. In the sidebar of the client app registration, click **API permissions**.
  1. Click **Add a permission**.
  1. Click the **My APIs** tab.
  1. Select the gateway API.
  1. Select **Delegated permissions**.
  1. Select the permission of the gateway API.
  1. Click **Add permissions**.

  Grant admin consent if the tenant or the API scope needs it.
  Give the full URI of the API scope, such as `api://API_ID/access_as_user`, with its own `--scope` flag, as [Gateway audience](/kong-harnesses/identity-provider/#gateway-audience) describes.
* Token version: Set `api.requestedAccessTokenVersion` to `2` in the [manifest](https://learn.microsoft.com/en-us/entra/identity-platform/reference-microsoft-graph-app-manifest) of the gateway API.
  Entra ID then issues v2.0 access tokens, which have the application ID of the gateway API, a GUID, in `aud`.
  Put this GUID in `config.audience_required`.
* Access token lifetime: Entra ID issues access tokens for 60 to 90 minutes by default, as [Configurable token lifetimes](https://learn.microsoft.com/en-us/entra/identity-platform/configurable-token-lifetimes#access-tokens) describes.
  For these default lifetimes, set `--max-token-lifetime-seconds 5400`.
  If a token lifetime policy applies to the gateway API, set the value to the longest access token lifetime of that policy.

## PingFederate

PingFederate needs the following settings for the {{site.kong_harnesses}} client:

* Issuer: Use the `issuer` value from the [OpenID Provider configuration](https://docs.pingidentity.com/pingfederate/12.3/developers_reference_guide/pf_openid_provider_config_endpoint.html) of PingFederate, which is the base URL of the deployment, such as `https://PINGFEDERATE_HOST`.
  Include the port when it isn't 443, such as `https://PINGFEDERATE_HOST:9031`.
* Client: Create an OAuth client with **Client Authentication** set to **None**, and select only the **Authorization Code** and **Refresh Token** grant types.
  Select **Require Proof Key for Code Exchange (PKCE)** in the client, as [Configuring OAuth clients](https://docs.pingidentity.com/pingfederate/12.3/administrators_reference_guide/pf_configuring_oauth_clients.html) describes.
  {{site.kong_harnesses}} always sends `S256`.
  To refuse the `plain` method for every client of the server, select **Disallow the Plain PKCE Code Challenge Method** in the [authorization server settings](https://docs.pingidentity.com/pingfederate/12.3/administrators_reference_guide/help_authorizationserversettingstasklet_oauthauthorizationserversettingsstate.html).
  The discovery document can leave out `none` in `token_endpoint_auth_methods_supported`, as in the example of the [OpenID Provider configuration](https://docs.pingidentity.com/pingfederate/12.3/developers_reference_guide/pf_openid_provider_config_endpoint.html).
  If it does, add `none` to the discovery template, or test the client with `--public-client-evidence deployment`, as [Discovery document](/kong-harnesses/identity-provider/#discovery-document) describes.
* ID token: Configure an OpenID Connect policy in **Applications** > **OAuth** > **OpenID Connect Policy Management**, as the prerequisites of [Create an OAuth or OpenID Connect application in PingFederate](https://docs.pingidentity.com/solution-guides/customer_use_cases/htg_oidc_app_setup_pf.html) list.
  In the **Policy** list of the client, select that policy, or keep the default policy if it applies.
* Scopes: Define each scope that the profile requests, such as `openid`, `profile` and `email`, as a common scope or as an exclusive scope of the client, as [Scopes and scope management](https://docs.pingidentity.com/pingfederate/12.3/administrators_reference_guide/pf_scopes_and_scope_management.html) describes.
  PingFederate refuses a scope that the client can't use with an `invalid_scope` error.
* Audience: Keep `--audience-parameter resource`, and create a JWT access token management instance for the gateway, as [Configuring an access token management instance](https://docs.pingidentity.com/pingfederate/12.3/administrators_reference_guide/pf_configuring_access_token_management_instance.html) describes.
  Sign its access tokens with an asymmetric key, and select **Publish Keys to the PingFederate JWKS Endpoint**, so that the gateway can find the key.
  Set its **Type Header Value** to `at+jwt`, and set its **Issuer Claim Value** to the `issuer` of the discovery document, because the instance leaves `iss` out of the access token when this value is empty.
  Add the `--audience` value to its **Resource URIs**, and set its **Audience Claim Value** to the `--audience` value.
  Select the instance as the **Default Access Token Manager** of the client, as [Configuring OAuth clients](https://docs.pingidentity.com/pingfederate/12.3/administrators_reference_guide/pf_configuring_oauth_clients.html) describes, because the code exchange and the renewal request don't send `resource`.
  Also select the instance as the **Access Token Manager** of the OpenID Connect policy of the client, as [Configuring OpenID Connect policies](https://docs.pingidentity.com/pingfederate/12.3/administrators_reference_guide/help_policymanagementtasklet_policymanagementstate.html) describes.
* Access token lifetime: The JWT access token management instance sets the lifetime in whole minutes, and it issues access tokens for 120 minutes by default, as [Configuring an access token management instance](https://docs.pingidentity.com/pingfederate/12.3/administrators_reference_guide/pf_configuring_access_token_management_instance.html) describes.
  Set its **Token Lifetime** from 7 to 60 minutes, or keep 120 minutes and set `--max-token-lifetime-seconds 7200`.
