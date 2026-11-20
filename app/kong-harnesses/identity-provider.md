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
  - text: Identity provider settings for kong-harnesses
    url: /kong-harnesses/identity-provider/providers/
---

{{site.kong_harnesses}} signs a developer in to your OpenID Connect (OIDC) identity provider in the browser, with the authorization code flow and PKCE.
It gets new access tokens with a refresh token, so the developer doesn't sign in for each one.
Register one client for {{site.kong_harnesses}} in the identity provider, and put its values in the profile that you create with [`kong-harnesses profile create`](/kong-harnesses/profile/create/).

{{site.kong_harnesses}} is tested with Okta.
For the Okta steps, see the prerequisites of [Set up {{ site.claude_code }} with kong-harnesses](/ai-gateway/set-up-claude-code-with-kong-harnesses/).
For Auth0, Keycloak, Microsoft Entra ID and PingFederate, see [Identity provider settings](/kong-harnesses/identity-provider/providers/).
Other OIDC identity providers need the same kinds of settings.

## Client settings

Register the client with these settings, and set the matching profile flags.

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
      From 365 to 3600 seconds by default.
      See [Access token lifetime](#access-token-lifetime).
    flag: "`--max-token-lifetime-seconds`"
{% endtable %}

## Callback

The callback is the address on the developer's computer that the browser returns to after the sign-in.
{{site.kong_harnesses}} listens on that address while the developer signs in with [`kong-harnesses login`](/kong-harnesses/login/) or [`kong-harnesses setup`](/kong-harnesses/setup/), so the developer must open the sign-in page in a browser on the same computer.
The developer must finish the sign-in in the browser within 2 minutes.
At each sign-in in the browser, {{site.kong_harnesses}} sends `prompt=consent` to ask for the consent screen, but the identity provider can skip it.
{{site.kong_harnesses}} ignores callback parameters that it doesn't use.
When the callback has an `iss` value, it must match the issuer of the profile.
When the discovery document sets `authorization_response_iss_parameter_supported` to `true`, the callback must have an `iss` value.

Register the callback of the profile in the client as an exact value, not as a pattern.
Use the same host, port and path in the client.
If your identity provider ignores the port when it matches a loopback callback, as RFC 8252 allows, the port that you register can differ from the port in the profile.
[`kong-harnesses profile get`](/kong-harnesses/profile/get/) and [`kong-harnesses doctor`](/kong-harnesses/doctor/) show the callback of a profile.

To use another callback, set `--redirect-uri`.
The value must:

* Use `http`.
* Have the host `localhost`, `127.0.0.1` or `[::1]`.
* Have a port from 1 to 65535, without zeros at the start.
* Have a path of 2 to 256 characters that starts with `/`, such as `/callback`.
  The path can have letters, digits, `-`, `.`, `_`, `~` and `/`, but it can't have `//` or a `.` or `..` segment, and it can't end with `/`.
* Not have user information, a query or a fragment.

For a `localhost` callback, {{site.kong_harnesses}} listens on `127.0.0.1`, and also on `[::1]` when the computer has it.
Two sign-ins on the same computer conflict when they need the same address and port, even with different paths.
For example, a `localhost` callback and a `127.0.0.1` callback on the same port conflict.
A second sign-in stops with an `AUTH_TEMPORARY` error that says that the sign-in callback address is in use.
On Windows, a port that Windows reserved gives the same error.
To list the reserved ports, run `netsh interface ipv4 show excludedportrange protocol=tcp` and `netsh interface ipv6 show excludedportrange protocol=tcp`.
To let several profiles sign in at the same time, give each profile a different port.

## Offline access and renewal

The sign-in fails if the identity provider doesn't issue a refresh token.
Give the client the refresh token grant type and the `offline_access` scope.

When you set `--scope`, your list replaces the defaults, so give each scope that you need with its own `--scope` flag, up to 16 scopes.
[`profile create`](/kong-harnesses/profile/create/) refuses a list without `openid` or `offline_access`.

When the token response has a `scope` value, it can't be empty, and each scope in it must match a different scope that the profile requests.
A returned scope matches a requested scope when it is the same, when it is the same after {{site.kong_harnesses}} decodes its percent escapes, or when it is the last path segment of exactly one requested URI scope, such as `access_as_user` for `api://API_ID/access_as_user`.
The response must also keep each scope that the profile requests, other than `openid`, `profile`, `email`, `address`, `phone`, `offline_access`, `groups` or `device_sso`.
These rules also apply at renewal, where each listed scope must also match a scope in the last accepted list.
At first, that list is the requested scopes that the sign-in response matched, or the scopes of the profile when the response doesn't list scopes.
After each renewal that lists scopes, it is the requested scopes that the renewal response matched.
A renewal response without `scope` keeps the last accepted list.
A response with a `scope` value that breaks these rules fails the sign-in or the renewal.

{{site.kong_harnesses}} saves each new refresh token, so the identity provider can rotate refresh tokens or keep the same one.
When the identity provider refuses a refresh token with `invalid_grant`, for example because it expired or because you revoked it, the developer must run [`kong-harnesses login`](/kong-harnesses/login/) again.

For the revocation at sign-out, see [`kong-harnesses logout`](/kong-harnesses/logout/).

## Gateway audience

The gateway checks the audience of an access token when the `openid-connect` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) sets [`config.audience_required`](/ai-gateway/openid-connect/#authorization).
Set `config.audience_required` to a list that contains the gateway audience, as the identity provider puts it in the claim that `config.audience_claim` selects, `aud` by default.

Set `--audience` in the profile to the gateway audience.
The profile always needs this value, even with `--audience-parameter none`.
The value must be an absolute URI, such as `api://default`.
The `aud` claim can be a different value.

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
      Use this value for an identity provider that reads `audience`.
  - value: "`none`"
    description: |
      The sign-in request doesn't send the audience.
      Use this value when the client, the authorization server or a scope sets the audience.
      If the identity provider selects the gateway API through a scope, give that scope with `--scope`, together with `openid`, `offline_access` and each other scope that you need.
{% endtable %}

{{site.kong_harnesses}} doesn't check the audience of the access token.
If the identity provider ignores the audience in the request and doesn't set it in another way, its access tokens don't get the gateway audience, and a gateway with `config.audience_required` refuses them.
{{site.kong_harnesses}} sends the audience only in the authorization request in the browser, not in the code exchange or the renewal request, so check that the access tokens from both of them also have the gateway audience.

Before you give the profile to developers, check that the gateway accepts access tokens from a sign-in and from a renewal.

## Discovery document

{{site.kong_harnesses}} reads the OIDC discovery document of the identity provider when you create the profile.
The issuer URL must be a canonical `https` URL without a query, with the same rules as the endpoint URLs in the following list, and match the `issuer` value in the discovery document character by character, including a trailing slash.

[`profile create`](/kong-harnesses/profile/create/) refuses a discovery document that doesn't meet these rules:

* The document has `response_types_supported` and `id_token_signing_alg_values_supported`, and each is a nonempty JSON array of unique strings.
  `grant_types_supported`, `token_endpoint_auth_methods_supported` and `code_challenge_methods_supported` follow the same rule when the document lists them.
* A canonical `https` URL in `authorization_endpoint`, `token_endpoint` and `jwks_uri`, and also in `revocation_endpoint` when the document lists it.
  A canonical URL has at most 2,048 bytes of visible ASCII characters without `\`, and a lowercase host.
  It doesn't have the port `443`, a port with a zero at the start, user information, a fragment or a `.` or `..` path segment.
  Its percent encoding uses uppercase hexadecimal digits, and it doesn't encode a letter, a digit, `-`, `.`, `_`, `~`, `\` or a control character.
* No parameter that {{site.kong_harnesses}} sets in the query of `authorization_endpoint`: `response_type`, `client_id`, `redirect_uri`, `scope`, `state`, `nonce`, `code_challenge`, `code_challenge_method`, `resource`, `audience` or `prompt`.
* The `code` response type in `response_types_supported`.
* At least one of `RS256`, `RS384`, `RS512`, `PS256`, `PS384`, `PS512`, `ES256`, `ES384` or `ES512` in `id_token_signing_alg_values_supported`.
  Configure the client to sign ID tokens with one of these algorithms that the discovery document also lists.
* When the discovery document lists `authorization_response_iss_parameter_supported`, it must be `true` or `false`.
* When the discovery document lists one of these fields, the field must have the value that {{site.kong_harnesses}} needs:
  * The `S256` PKCE method in `code_challenge_methods_supported`.
  * The `authorization_code` and `refresh_token` grant types in `grant_types_supported`.
  * The `none` method, for a public client, in `token_endpoint_auth_methods_supported`.

{{site.kong_harnesses}} accepts a discovery document that leaves out any of these three fields, but a missing field doesn't prove the capability.
For example, without `code_challenge_methods_supported`, check that the token endpoint refuses a code exchange without a valid `S256` code verifier.

Some identity providers omit `none` from the advertised methods for public clients.
For them, first test a separate client in a non-production deployment, with `--public-client-evidence deployment` in its profile, and check that it signs in and renews its access token without a client secret.
After the test passes, create the production profile with the flag, which skips only the check for `none`.
Developers who already signed in must then run [`kong-harnesses login`](/kong-harnesses/login/) again.

Each sign-in in the browser runs the same checks again.
The sign-in also fails when an endpoint that `profile create` saved in the profile differs from the current discovery document.
The revocation endpoint counts only when the profile has one.
If an endpoint changes and the new discovery document passes the checks, create the profile again.

## Access token lifetime

{{site.kong_harnesses}} reads the lifetime from `expires_in` in the token response, at sign-in and at renewal.
It refuses a lifetime under 365 seconds, because a renewed access token must still have 360 seconds left when a client gets it.
If the identity provider sets the lifetime in whole minutes, use at least 7 minutes.
{{site.kong_harnesses}} also refuses a lifetime over the limit of the profile, 3600 seconds by default.

If your identity provider issues longer access tokens, find the longest access token lifetime in its policy, and set `--max-token-lifetime-seconds` to that value, from 365 to 86400 seconds.
If the policy allows more than 86400 seconds, reduce it to 86400 seconds.
After a change to this value, developers who already signed in must run [`kong-harnesses login`](/kong-harnesses/login/) again.

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
