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
  - text: Identity provider checks in kong-harnesses
    url: /kong-harnesses/identity-provider/checks/
---

{{site.kong_harnesses}} signs developers in to your [OpenID Connect (OIDC)](/ai-gateway/openid-connect/) identity provider in the browser, with the authorization code flow and [Proof Key for Code Exchange (PKCE)](https://www.rfc-editor.org/rfc/rfc7636).
It renews their access tokens with a refresh token, so they don't sign in again each time.
This page lists the settings that the client in your identity provider needs, and the profile flags that carry them.

{{site.kong_harnesses}} is tested with Okta.
For the Okta steps, see the prerequisites of [Set up {{ site.claude_code }} with kong-harnesses](/ai-gateway/set-up-claude-code-with-kong-harnesses/).
For Auth0, Keycloak, Microsoft Entra ID and PingFederate, see [Identity provider settings](/kong-harnesses/identity-provider/providers/).
Other OIDC identity providers need the same kinds of settings.

## Client settings

Register the client in the identity provider with these settings:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Value
    key: value
rows:
  - setting: Client type
    value: "A public client, such as a native application, without a client secret."
  - setting: Grant types
    value: "Authorization code and refresh token."
  - setting: Response type
    value: "`code`, in the query of the callback. If there is a response mode setting, select `query`."
  - setting: PKCE
    value: "Required, with the `S256` method."
  - setting: Token type
    value: "`Bearer`. A token type such as `DPoP` fails the sign-in and the renewal."
  - setting: ID token signature
    value: "An RSA or ECDSA algorithm, such as `RS256` or `ES256`."
  - setting: Callback, also called the redirect URI
    value: "`http://localhost:9876/callback` by default. See [Callback](#callback)."
{% endtable %}

Set these values in the profile:

{% table %}
columns:
  - title: Profile flag
    key: flag
  - title: Value
    key: value
rows:
  - flag: "`--issuer`"
    value: |
      The issuer URL of the identity provider, exactly as its discovery document lists it, with a trailing slash when the document has one.
      See [Discovery document and token lifetime](#discovery-document-and-token-lifetime).
  - flag: "`--client-id`"
    value: "The ID that the identity provider gives the client."
  - flag: "`--redirect-uri`"
    value: "The callback, if you don't use the default."
  - flag: "`--scope`"
    value: "By default, `openid`, `profile`, `email` and `offline_access`. See [Offline access and renewal](#offline-access-and-renewal)."
  - flag: "`--audience`, `--audience-parameter`"
    value: "The audience of the gateway. See [Gateway audience](#gateway-audience)."
  - flag: "`--max-token-lifetime-seconds`"
    value: "From 365 to 3600 seconds by default. See [Discovery document and token lifetime](#discovery-document-and-token-lifetime)."
{% endtable %}

## Callback

The callback is the address on the developer's computer that the browser returns to after the sign-in.
{{site.kong_harnesses}} listens on it during [`kong-harnesses login`](/kong-harnesses/login/), so the developer must finish the sign-in in a browser on the same computer within 2 minutes.

Register the callback of the profile in the client as an exact value, not as a pattern.
To use another callback, set `--redirect-uri`, as [Sign-in fields](/kong-harnesses/profile-file/#sign-in-fields) describes.
If the sign-in stops with an `AUTH_TEMPORARY` error that says that the callback address is in use, see [Port conflicts](/kong-harnesses/identity-provider/checks/#port-conflicts).

## Offline access and renewal

The sign-in fails if the identity provider doesn't issue a refresh token.
Give the client the refresh token grant type and the `offline_access` scope.
When you set `--scope`, your list replaces the defaults, needs `openid` and `offline_access`, and has at most 16 scopes.

When the identity provider refuses a refresh token with `invalid_grant`, the developer must run [`kong-harnesses login`](/kong-harnesses/login/) again.

## Gateway audience

The gateway checks the audience of an access token when the `openid-connect` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) sets [`config.audience_required`](/ai-gateway/openid-connect/#authorization).
Set `config.audience_required` to a list that contains the value that the identity provider puts in the claim that `config.audience_claim` selects, `aud` by default.
Set `--audience` in the profile to an absolute URI that identifies the gateway, such as `https://gateway.example.com/api`.

Set `--audience-parameter` to match how your identity provider reads the audience from the sign-in request:

{% table %}
columns:
  - title: Value
    key: value
  - title: Description
    key: description
rows:
  - value: "`resource`"
    description: "Sends the audience in the `resource` parameter of [RFC 8707](https://www.rfc-editor.org/rfc/rfc8707). This is the default."
  - value: "`audience`"
    description: "Sends the audience in the `audience` parameter."
  - value: "`none`"
    description: "Doesn't send the audience. Use this when the client, the authorization server or a scope sets it. If a scope selects the gateway API, add it with `--scope`."
{% endtable %}

{{site.kong_harnesses}} doesn't check the audience of the access token.
If the identity provider doesn't set it, a gateway with `config.audience_required` refuses the token.
Before you give the profile to developers, check that the gateway accepts access tokens from a sign-in and from a renewal.

## Discovery document and token lifetime

{{site.kong_harnesses}} reads the discovery document from the issuer URL plus `/.well-known/openid-configuration`, and refuses one that doesn't meet the [discovery document checks](/kong-harnesses/identity-provider/checks/#discovery-document).
If your identity provider lists `token_endpoint_auth_methods_supported` without `none` for a public client, test a separate client with `--public-client-evidence deployment`, then use the flag in the production profile.

The access token must last from 365 seconds to the limit of the profile, 3600 seconds by default.
If the identity provider sets the lifetime in whole minutes, use at least 7 minutes.
To allow longer access tokens, set `--max-token-lifetime-seconds` to the longest lifetime in the policy, up to 86400 seconds.

## Next steps

Create the profile with [`kong-harnesses profile create`](/kong-harnesses/profile/create/), and publish it as [Profile creation](/kong-harnesses/profiles-for-administrators/#profile-creation) describes.
A change to a sign-in value of the profile changes its [security identity](/kong-harnesses/profile-file/#security-identity).
