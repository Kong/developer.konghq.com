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

Auth0, Keycloak, Microsoft Entra ID and PingFederate each need a few provider-specific settings for the {{site.kong_harnesses}} client, in addition to the [client settings](/kong-harnesses/identity-provider/#client-settings) that every identity provider needs.
{{site.kong_harnesses}} isn't tested with these identity providers, so test sign-in and token renewal in a non-production deployment before you give the profile to developers.

## Auth0

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Value
    key: value
rows:
  - setting: "`--issuer`"
    value: "`https://YOUR_AUTH0_DOMAIN/`, with the trailing slash."
  - setting: Application
    value: "Create a **Native** application. Auth0 registers it as a public client, without a client secret."
  - setting: Offline access
    value: "In the API of the gateway, enable **Allow Offline Access**."
  - setting: Audience
    value: "Register the gateway as an API with an identifier that is an absolute URI, such as `https://gateway.example.com/api`. Set `--audience` to it, and set `--audience-parameter audience`."
  - setting: Access token lifetime
    value: "Auth0 issues access tokens for 24 hours by default, so set `--max-token-lifetime-seconds 86400`. Or set the token lifetime of the API from 365 to 3600 seconds."
{% endtable %}

* If **User-Delegated Access** of the API is **Per-app authorization**, grant the native application access to the API.
* If you use rotating refresh tokens, keep **Rotation Overlap Period** at 0.
* Keep **Non-Verifiable Callback URI End-User Confirmation** enabled, under **Advanced** > **OAuth** in the application settings. Auth0 then asks for a confirmation at sign-in with a loopback callback.

## Keycloak

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Value
    key: value
rows:
  - setting: "`--issuer`"
    value: "The `issuer` of the realm discovery document, such as `https://KEYCLOAK_HOST/realms/REALM_NAME`, with a context path such as `/auth` if you use one."
  - setting: Client
    value: "Create an OpenID Connect client with **Client authentication** off and **Standard flow** on. Set **PKCE Method** to `S256`."
  - setting: Public client check
    value: "The discovery document doesn't list `none` by default, so test the client, then create the profile with `--public-client-evidence deployment`."
  - setting: Offline access
    value: "Keep `offline_access` as an optional client scope of the client, and give users the realm role `offline_access`."
  - setting: Audience
    value: "Set `--audience-parameter none`. In the dedicated client scope of the client, add an Audience mapper with **Included Custom Audience** set to the `--audience` value, **Add to access token** on, and **Add to ID token** off."
  - setting: Access token lifetime
    value: "Set **Access Token Lifespan** of the realm or the client from 7 to 60 minutes."
{% endtable %}

* Link each scope that the profile requests, such as `profile` and `email`, to the client.
* **Revoke Refresh Token** can stay off. If you turn it on, keep **Refresh Token Max Reuse** at 0.
* If the sign-in fails with "the identity provider granted a scope that the profile did not request", find each default client scope of the client that the profile doesn't request. Unlink it from the client, or turn off **Include in token scope** in it. Do the second only when no other client linked to that scope needs the setting on.

## Microsoft Entra ID

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Value
    key: value
rows:
  - setting: "`--issuer`"
    value: "`https://login.microsoftonline.com/TENANT_ID/v2.0`, not `common`, `organizations` or `consumers`."
  - setting: Client
    value: "Register the callback under **Mobile and desktop applications**, and don't add a client secret. The discovery document doesn't list `none`, so test the client, then create the profile with `--public-client-evidence deployment`."
  - setting: Callback
    value: "Entra ID ignores the port only for `localhost`, and doesn't accept `[::1]`. Register one `localhost` callback for each path. For a `127.0.0.1` callback, add it to `publicClient.redirectUris` in the application manifest, because the portal doesn't accept it."
  - setting: Audience
    value: "Set `--audience` to the Application ID URI of the gateway API, and set `--audience-parameter none`. Expose a delegated scope in the API, add it under **API permissions** of the client, and give its full URI, such as `api://API_ID/access_as_user`, with its own `--scope` flag."
  - setting: Token version
    value: "Set `api.requestedAccessTokenVersion` to `2` in the manifest of the gateway API. The access token then has the application ID of the API, a GUID, in `aud`. Put that GUID in `config.audience_required`."
  - setting: Access token lifetime
    value: "Entra ID issues access tokens for 60 to 90 minutes by default, so set `--max-token-lifetime-seconds 5400`, or the longest lifetime of your token lifetime policy."
{% endtable %}

Grant admin consent if the tenant or the API scope needs it.

## PingFederate

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Value
    key: value
rows:
  - setting: "`--issuer`"
    value: "The `issuer` of the OpenID Provider configuration, which is the base URL of the deployment, with the port when it isn't 443, such as `https://PINGFEDERATE_HOST:9031`."
  - setting: Client
    value: "Create an OAuth client with **Client Authentication** set to **None**, the **Authorization Code** and **Refresh Token** grant types only, and **Require Proof Key for Code Exchange (PKCE)** selected."
  - setting: Public client check
    value: "The discovery document can leave out `none`. Add it to the discovery template, or test the client, then create the profile with `--public-client-evidence deployment`."
  - setting: Scopes
    value: "Define each scope that the profile requests, such as `openid`, `profile`, `email` and `offline_access`, as a common scope or an exclusive scope of the client."
  - setting: ID token
    value: "Configure an OpenID Connect policy under **Applications** > **OAuth** > **OpenID Connect Policy Management**, and select it in the client."
  - setting: Audience
    value: "Keep `--audience-parameter resource`, and create a JWT access token management instance for the gateway. See the following steps."
  - setting: Access token lifetime
    value: "The instance issues access tokens for 120 minutes by default. Set its **Token Lifetime** from 7 to 60 minutes, or set `--max-token-lifetime-seconds 7200`."
{% endtable %}

To set the audience, configure the JWT access token management instance:

1. Sign its access tokens with an asymmetric key, and select **Publish Keys to the PingFederate JWKS Endpoint**.
1. Set **Type Header Value** to `at+jwt`, and **Issuer Claim Value** to the `issuer` of the discovery document.
1. Add the `--audience` value to **Resource URIs**, and set **Audience Claim Value** to the same value.
1. Select the instance as the **Default Access Token Manager** of the client, and as the **Access Token Manager** of its OpenID Connect policy.
