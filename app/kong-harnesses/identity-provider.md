---
title: "Register {{site.kong_harnesses}} in your identity provider"
description: "The client settings that an OpenID Connect identity provider needs so that {{site.kong_harnesses}} can sign developers in and renew their access tokens."
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

related_resources:
  - text: Set up {{ site.claude_code }} with kong-harnesses
    url: /ai-gateway/set-up-claude-code-with-kong-harnesses/
  - text: kong-harnesses profile create
    url: /kong-harnesses/profile/create/
  - text: AI Auth Strategy entity
    url: /ai-gateway/entities/ai-auth-strategy/
---

{{site.kong_harnesses}} signs a developer in to your OpenID Connect (OIDC) identity provider in the browser, with the authorization code flow and PKCE.
When it needs a new access token, it gets one with a refresh token, so the developer doesn't sign in for each access token.
Register one client for {{site.kong_harnesses}} in the identity provider, and put its values in the profile that you create with [`kong-harnesses profile create`](/kong-harnesses/profile/create/).

{{site.kong_harnesses}} is tested with Okta.
The settings for Keycloak, Auth0, Microsoft Entra ID and PingFederate come from their documentation, and they aren't tested.
For the Okta steps, see the prerequisites of [Set up {{ site.claude_code }} with kong-harnesses](/ai-gateway/set-up-claude-code-with-kong-harnesses/).
Other OIDC identity providers need the same kinds of settings.

## Client settings

Register the client with these settings, and set the matching flag when you create the profile.

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Value
    key: value
  - title: Profile flag
    key: flag
rows:
  - setting: Client type
    value: |
      A public client, such as a native application.
      The client doesn't have a client secret.
    flag: "None"
  - setting: Client ID
    value: "The ID that the identity provider gives the client."
    flag: "`--client-id`"
  - setting: Grant types
    value: "Authorization code and refresh token."
    flag: "None"
  - setting: Response type
    value: |
      `code`, with the authorization code in the query of the callback.
      If the identity provider has a response mode setting, select `query`.
    flag: "None"
  - setting: Token type
    value: |
      `Bearer`, at sign-in and at renewal.
      A client that requires DPoP or another token type fails.
    flag: "None"
  - setting: PKCE
    value: "Required, with the `S256` method."
    flag: "None"
  - setting: ID token signature
    value: |
      An RSA or ECDSA algorithm, such as `RS256` or `ES256`.
      See [Discovery document](#discovery-document).
    flag: "None"
  - setting: Callback, also called the redirect URI
    value: |
      `http://localhost:9876/callback` by default.
      See [Callback](#callback).
    flag: "`--redirect-uri`"
  - setting: Scopes
    value: |
      By default, `openid`, `profile`, `email` and `offline_access`.
      `openid` and `offline_access` are required.
      See [Offline access and renewal](#offline-access-and-renewal).
    flag: "`--scope`"
  - setting: Audience
    value: |
      The audience of the gateway.
      See [Gateway audience](#gateway-audience).
    flag: "`--audience`, `--audience-parameter`"
  - setting: Access token lifetime
    value: |
      The `expires_in` value of the identity provider must be in the range that the profile accepts, more than 360 and at most 3600 seconds by default.
      `--max-token-lifetime-seconds` sets the highest lifetime that the profile accepts.
      See [Access token lifetime](#access-token-lifetime).
    flag: "`--max-token-lifetime-seconds`"
{% endtable %}

## Callback

The callback is the address on the developer's computer that the identity provider sends the browser back to after the sign-in.
{{site.kong_harnesses}} listens on that address while the developer signs in with [`kong-harnesses login`](/kong-harnesses/login/) or [`kong-harnesses setup`](/kong-harnesses/setup/), so the developer must open the sign-in page in a browser on the same computer.
At each sign-in in the browser, {{site.kong_harnesses}} sends `prompt=consent` to ask for the consent screen, but the identity provider can skip it.
For example, Keycloak shows it only when consent is on for the client, and Auth0 can show a confirmation prompt for a loopback callback, such as `localhost` or `127.0.0.1`, even when **Allow Skipping User Consent** is on in the API.
Microsoft Entra ID shows the consent screen at each sign-in.

Register the callback of the profile in the client as an exact value, not as a pattern.
The profile uses one fixed port.
Use the same host, port and path in the client, unless your identity provider accepts any port for a loopback callback, as RFC 8252 allows.
For example, a profile with `http://127.0.0.1:9876/callback` fails to sign in when the client has `http://localhost:9876/callback`.
[`kong-harnesses profile get`](/kong-harnesses/profile/get/) and [`kong-harnesses doctor`](/kong-harnesses/doctor/) show the callback of a profile, so you can compare it with the client.

To use another callback, set `--redirect-uri` when you create the profile.
The value must:

* Use `http`.
* Have the host `localhost`, `127.0.0.1` or `[::1]`.
* Have a port from 1 to 65535, without zeros at the start.
* Have a path of 2 to 256 characters that starts with `/`, such as `/callback`.
  The path can have letters, digits, `-`, `.`, `_`, `~` and `/`, but it can't have `//` or a `.` or `..` segment, and it can't end with `/`.
* Not have a query or a fragment.

Microsoft Entra ID ignores the port only for a `localhost` callback, and doesn't accept `[::1]`.
In Entra ID, register the callback under **Mobile and desktop applications**.
The Azure portal doesn't accept an `http` callback with `127.0.0.1`, so register a `localhost` callback there.
To register a `127.0.0.1` callback in Entra ID, add it to `publicClient.redirectUris` in the application manifest, and include the port that the profile uses:

```json
"publicClient": {
  "redirectUris": [
    "http://127.0.0.1:9876/callback"
  ]
}
```

During a sign-in, {{site.kong_harnesses}} listens on the port of the callback.
For a `localhost` callback, it listens on `127.0.0.1`, and also on `[::1]` when the computer has it.
Two sign-ins on the same computer conflict when they need the same address and port, even with different paths.
For example, a profile with a `localhost` callback and a profile with a `127.0.0.1` callback on the same port conflict, because both listen on `127.0.0.1`.
A second sign-in stops with an error that has this message:

```text
another program on this computer, such as another sign-in, is using the sign-in callback address
```
{:.no-copy-code}

To let several profiles sign in at the same time, give each profile a different port.

## Offline access and renewal

The sign-in fails if the identity provider doesn't issue a refresh token.
Give the client the refresh token grant type, and allow the `offline_access` scope for it.
In Keycloak, keep `offline_access` as an optional client scope of the client, and check that users have the realm role `offline_access` and that the client scope includes it.
In Auth0, also turn on **Allow Offline Access** in the API of the gateway.

A profile requests `openid`, `profile`, `email` and `offline_access` by default.
When you set `--scope`, your list replaces the defaults, so give each scope that you need with its own `--scope` flag, up to 16 scopes.
`profile create` refuses a list without `openid` or `offline_access`.

When the token response lists scopes, each scope must be one that the profile requests.
The response must also keep each scope that the profile requests, other than `openid`, `profile`, `email`, `address`, `phone`, `offline_access`, `groups` or `device_sso`.
These rules also apply at renewal, where each listed scope must also be one in the last accepted scope list.
At first, that list is the scopes of the sign-in response, or the scopes of the profile when the response doesn't list scopes.
After each renewal that lists scopes, it is the scopes of that response.
Otherwise, the sign-in or the renewal fails.

{{site.kong_harnesses}} saves each new refresh token, so the identity provider can rotate refresh tokens or keep the same one.
When the identity provider refuses a refresh token with `invalid_grant`, for example because it expired or because you revoked it, the developer must run `kong-harnesses login` again.

When the discovery document lists a `revocation_endpoint`, `profile create` saves it in the profile.
For what `logout` does with it, see [`kong-harnesses logout`](/kong-harnesses/logout/).

## Gateway audience

The gateway checks the audience of an access token when the `openid-connect` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) sets `config.audience_required`.
For this setting, see [Authorization](/ai-gateway/openid-connect/#authorization).
Set `config.audience_required` to a list that contains the value that the identity provider puts in the `aud` claim of its access tokens.

Set `--audience` in the profile to the gateway audience.
The profile always needs this value, even with `--audience-parameter none`.
The value must be an absolute URI, such as `api://default`.
The `aud` claim can be a different value.
For example, a Microsoft Entra ID v2.0 access token has the application ID of the API, a GUID, in `aud`, and a v1.0 access token can have the application ID or the Application ID URI.

Set `--audience-parameter` to match how your identity provider reads the audience from the sign-in request:

{% table %}
columns:
  - title: Value
    key: value
  - title: Description
    key: description
rows:
  - value: "`resource`"
    description: |
      The sign-in request sends the audience in the `resource` parameter of RFC 8707.
      This is the default value.
  - value: "`audience`"
    description: |
      The sign-in request sends the audience in the `audience` parameter.
      Use this value for an identity provider that reads `audience`, such as Auth0.
  - value: "`none`"
    description: |
      The sign-in request doesn't send the audience.
      Use this value when the client, the authorization server or a scope sets the audience.
      If the identity provider selects the gateway API through a scope, give that scope with `--scope`, together with `openid`, `offline_access` and each other scope that you need.
{% endtable %}

{{site.kong_harnesses}} doesn't check the audience of the access token.
If the identity provider ignores the audience in the request and doesn't set it in another way, its access tokens don't get the gateway audience, and the gateway refuses them.
{{site.kong_harnesses}} sends the audience only in the authorization request in the browser, so check that the identity provider keeps the gateway audience in the access tokens that it issues at the code exchange and at renewal, or sets it in another way.

These settings give the access token the gateway audience in some identity providers:

* Auth0: Register the gateway as an API, with an identifier that is an absolute URI, such as `https://gateway.example.com/api`.
  Set `--audience` to the identifier of the API, and set `--audience-parameter audience`.
* Keycloak: It ignores the `resource` parameter by default, so set `--audience-parameter none`.
  In the dedicated client scope of the client, add an Audience mapper, and set its **Included Custom Audience** to the `--audience` value.
  Use the dedicated client scope, because {{site.kong_harnesses}} refuses a token response with a scope that the profile doesn't request.
* Microsoft Entra ID: Set `--audience` to the Application ID URI of the gateway API, and set `--audience-parameter none`.
  For v2.0 access tokens, put the application ID of the gateway API, a GUID, in `config.audience_required`.
  Give the client the delegated permission of the gateway API, and grant admin consent if the tenant or the API scope needs it.
  Give the full URI of the API scope with `--scope`, together with `openid`, `offline_access` and each other scope that you need.
* PingFederate: Keep `--audience-parameter resource`, and create a JWT access token management instance for the gateway.
  Sign its access tokens with an asymmetric key, and set its **Type Header Value** to `at+jwt`.
  Add the `--audience` value to its **Resource URIs**, and set its **Audience Claim Value** to the `--audience` value.
  Select the instance in the OpenID Connect policy of the client and as the **Default Access Token Manager** of the client, because the renewal request doesn't send `resource`.

Before you give the profile to developers, check that the gateway accepts an access token from a sign-in, and an access token from a renewal.

## Discovery document

{{site.kong_harnesses}} reads the OIDC discovery document of the identity provider when you create the profile and when a developer signs in through the browser.
The issuer URL must use `https`.
It must also match the `issuer` value in the discovery document character by character, including a trailing slash.
For Microsoft Entra ID, use the issuer of your tenant, `https://login.microsoftonline.com/TENANT_ID/v2.0`, not `common` or `organizations`.

`profile create` refuses a discovery document that doesn't meet these rules:

* An `https` URL in `authorization_endpoint`, `token_endpoint` and `jwks_uri`, and also in `revocation_endpoint` when the document lists it.
* The `code` response type in `response_types_supported`.
* At least one of `RS256`, `RS384`, `RS512`, `PS256`, `PS384`, `PS512`, `ES256`, `ES384` or `ES512` in `id_token_signing_alg_values_supported`.
  {{site.kong_harnesses}} doesn't accept other algorithms, such as `HS256` or `EdDSA`.
  Configure the client to sign ID tokens with one of these algorithms that the discovery document also lists.
* When the discovery document lists `authorization_response_iss_parameter_supported`, it must be `true` or `false`.
  When it is `true`, the callback must have an `iss` value that matches the issuer of the profile.
* When the discovery document lists one of these fields, the field must have the value that {{site.kong_harnesses}} needs:
  * The `S256` PKCE method in `code_challenge_methods_supported`.
  * The `authorization_code` and `refresh_token` grant types in `grant_types_supported`.
  * The `none` method, for a public client, in `token_endpoint_auth_methods_supported`.

{{site.kong_harnesses}} accepts a discovery document that leaves out one of these three fields.
A missing field doesn't prove the capability.
For example, if the discovery document leaves out `code_challenge_methods_supported`, check that the token endpoint refuses a code exchange without a valid `S256` code verifier.

Some identity providers, such as Microsoft Entra ID, don't list `none` even for a public client.
For them, first use a separate test client in a non-production deployment.
If you use {{site.kong_harnesses}} for the test, set `--public-client-evidence deployment` in the test profile.
Check that the test client signs in and renews its access token without a client secret.
After the test passes, add `--public-client-evidence deployment` to the production profile.
The flag skips only the check for `none`.

At each sign-in in the browser, `kong-harnesses login` and `kong-harnesses setup` run the same checks again.
They also compare the endpoints that `profile create` saved in the profile with the current discovery document, and the revocation endpoint only when the profile has one.
If a saved endpoint changes and the new discovery document passes the checks, create the profile again.

## Access token lifetime

{{site.kong_harnesses}} reads the lifetime of each access token from the `expires_in` value of the token response, at sign-in and at renewal.
It refuses a lifetime of 360 seconds, which is 6 minutes, or less, so the identity provider must issue access tokens for more than 6 minutes, such as 10 minutes.
At renewal, the new access token must also have at least 6 minutes left after {{site.kong_harnesses}} saves the new refresh token.
It also refuses a lifetime over the limit of the profile, which is 3600 seconds, or 1 hour, by default.

By default, Keycloak issues access tokens for 5 minutes, Auth0 for 24 hours, and Microsoft Entra ID for 60 to 90 minutes.
In Keycloak, raise the access token lifespan.
If your identity provider issues longer access tokens, find the longest access token lifetime in its policy, and set `--max-token-lifetime-seconds` to that value, up to 86400 seconds.
If the policy allows more than 86400 seconds, reduce it to 86400 seconds.
After a change to this value, developers must run `kong-harnesses login` again.

## Create the profile

Create a profile with the client settings, the gateway origin and the model ID:

```sh
kong-harnesses profile create \
  --name PROFILE_NAME \
  --issuer ISSUER_URL \
  --client-id CLIENT_ID \
  --audience AUDIENCE \
  --gateway-origin GATEWAY_ORIGIN \
  --model MODEL_ID
```

Add `--redirect-uri`, `--scope`, `--audience-parameter`, `--public-client-evidence` or `--max-token-lifetime-seconds` when your identity provider needs them.
