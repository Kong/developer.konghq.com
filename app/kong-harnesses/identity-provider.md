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
It then renews the access token in the background with a refresh token, so the developer doesn't sign in again until the identity provider refuses the refresh token.
For this to work, register one client for {{site.kong_harnesses}} in the identity provider, and put its values in the profile that you create with [`kong-harnesses profile create`](/kong-harnesses/profile/create/).

{{site.kong_harnesses}} is tested with Okta.
For the Okta steps, see the prerequisites of [Set up {{ site.claude_code }} with kong-harnesses](/ai-gateway/set-up-claude-code-with-kong-harnesses/).
Other OIDC identity providers need the same settings.

## Client settings

The following table lists the settings of the client and the profile flag that matches each one.

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
    value: "`code`."
    flag: "None"
  - setting: PKCE
    value: "Required, with the `S256` method."
    flag: "None"
  - setting: ID token signature
    value: "An asymmetric algorithm. See [Discovery document](#discovery-document)."
    flag: "None"
  - setting: Callback, also called the redirect URI
    value: |
      `http://localhost:9876/callback`, or the value that you set in the profile.
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
      From 6 minutes to 1 hour by default.
      See [Access token lifetime](#access-token-lifetime).
    flag: "`--max-token-lifetime-seconds`"
{% endtable %}

## Callback

The callback is the address on the developer's computer that the identity provider sends the browser back to after the sign-in.
{{site.kong_harnesses}} listens on that address during `kong-harnesses login`, so the developer must open the sign-in page in a browser on the same computer.

Register the callback as an exact value, not as a pattern.
The callback in the client must match the callback in the profile character by character.
For example, a profile with `http://127.0.0.1:9876/callback` fails to sign in when the client has `http://localhost:9876/callback`.
`kong-harnesses profile get` and `kong-harnesses doctor` show the callback of a profile, so you can compare it with the client.

To use another callback, set `--redirect-uri` when you create the profile.
The value must:

* Use `http`.
* Have the host `localhost`, `127.0.0.1` or `[::1]`.
* Have a port from 1 to 65535.
* Have a path of 2 to 256 characters that starts with `/`, such as `/callback`.
  The path can have letters, digits, `-`, `.`, `_`, `~` and `/`, but not `//`, `.` or `..` segments.
* Not have a query or a fragment.

Some identity providers have their own rules for a loopback callback.
For example, Microsoft Entra ID ignores the port of a `localhost` callback and doesn't accept `[::1]`.

Two sign-ins on the same computer can't use the same callback address at the same time.
A second sign-in stops with a message that another program is using the callback address.
It works again when the first sign-in ends.
Profiles with different callback addresses can sign in at the same time.

## Offline access and renewal

{{site.kong_harnesses}} renews the access token with a refresh token.
The sign-in fails if the identity provider doesn't issue a refresh token.
Give the client the refresh token grant type, and allow the `offline_access` scope for it.
In Auth0, also turn on **Allow Offline Access** in the API of the gateway.

A profile requests `openid`, `profile`, `email` and `offline_access` by default.
When you set `--scope`, your list replaces the defaults, so give each scope that you need with its own `--scope` flag, up to 16 scopes.
`profile create` refuses a list without `openid` or `offline_access`.

The identity provider can rotate the refresh token on each use, or keep the same one.
{{site.kong_harnesses}} saves each new refresh token that it gets.
When the identity provider refuses a refresh token with `invalid_grant`, for example because it expired or because you revoked it, {{site.kong_harnesses}} removes the sign-in, and the developer must run `kong-harnesses login` again.

When the discovery document lists a `revocation_endpoint`, `profile create` saves it in the profile.
For what `logout` does with it, see [`kong-harnesses logout`](/kong-harnesses/logout/).

## Gateway audience

The gateway checks the audience of an access token when the `openid-connect` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) sets [`config.audience_required`](/ai-gateway/entities/ai-auth-strategy/#schema-aigateway-auth-strategy-open-idconnect-config-config-audience-required).
Set `config.audience_required` to the value that the identity provider puts in the `aud` claim of its access tokens.

Set `--audience` in the profile to the audience that {{site.kong_harnesses}} requests.
The value must be an absolute URI, such as `api://default`.
It is often the same as the `aud` claim, but not always.
For example, Microsoft Entra ID v2.0 access tokens have the application ID of the API, a GUID, in `aud`.

Identity providers read the audience from the sign-in request in different ways.
Set `--audience-parameter` to match your identity provider:

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
      If the identity provider selects the gateway API through a scope, as Microsoft Entra ID does, give every scope with `--scope`: the default scopes and the scope of the gateway API.
{% endtable %}

{{site.kong_harnesses}} doesn't check the audience of the access token.
If the identity provider ignores the audience in the request and doesn't set it in another way, its access tokens don't get the gateway audience, and the gateway refuses them.
For example, Keycloak ignores the `resource` parameter.
In Keycloak, add a client scope with an Audience mapper that sets the gateway audience, and give that client scope to the client.
Before you give the profile to developers, check that an access token from the client has the gateway audience in its `aud` claim.

## Discovery document

{{site.kong_harnesses}} reads the OIDC discovery document of the identity provider when you create the profile and when a developer signs in through the browser.
The issuer URL must use `https`.
It must also match the `issuer` value in the discovery document character by character, including a trailing slash.

`profile create` refuses a discovery document that doesn't have these values:

* An `https` URL in `authorization_endpoint`, `token_endpoint` and `jwks_uri`.
* The `code` response type in `response_types_supported`.
* At least one of `RS256`, `RS384`, `RS512`, `PS256`, `PS384`, `PS512`, `ES256`, `ES384` or `ES512` in `id_token_signing_alg_values_supported`.
  {{site.kong_harnesses}} doesn't accept symmetric algorithms, such as `HS256`.

It also refuses a discovery document that lists one of these capabilities without the value that {{site.kong_harnesses}} needs:

* The `S256` PKCE method in `code_challenge_methods_supported`.
* The `authorization_code` and `refresh_token` grant types in `grant_types_supported`.
* The `none` method, for a public client, in `token_endpoint_auth_methods_supported`.

A discovery document that leaves out one of these three fields passes the check, but this doesn't prove that the identity provider supports the capability.
Test the sign-in and a renewal in a test deployment before you give the profile to developers.

Some identity providers, such as Microsoft Entra ID, don't list `none` even for a public client.
For them, first check in a test deployment that the client is public and signs in without a client secret.
Then add `--public-client-evidence deployment` to `profile create`.
The flag skips only the check for `none`.

## Access token lifetime

{{site.kong_harnesses}} reads the lifetime of each access token from the `expires_in` value of the token response, at sign-in and at renewal.
It refuses a lifetime under 360 seconds, which is 6 minutes.
It also refuses a lifetime over the limit of the profile, which is 3600 seconds, or 1 hour, by default.

The defaults of identity providers differ.
For example, Keycloak issues access tokens for 5 minutes, Auth0 for 24 hours, and Microsoft Entra ID for 60 to 90 minutes.
In Keycloak, raise the access token lifespan to at least 6 minutes.
If your identity provider issues longer access tokens, set `--max-token-lifetime-seconds` to the lifetime that it issues, up to 86400 seconds.
After a change to this value, developers must run `kong-harnesses login` again.

## Create the profile

Create a profile with the values of the client:

```sh
kong-harnesses profile create \
  --name PROFILE_NAME \
  --issuer ISSUER_URL \
  --client-id CLIENT_ID \
  --audience AUDIENCE \
  --gateway-origin GATEWAY_URL \
  --model MODEL_ID
```

Add `--redirect-uri`, `--scope`, `--audience-parameter`, `--public-client-evidence` or `--max-token-lifetime-seconds` when your identity provider needs them.
