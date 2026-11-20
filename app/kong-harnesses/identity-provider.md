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
It then renews the access token in the background with a refresh token, so the developer signs in once.
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
    value: "A public client, such as a native application, without a client secret."
    flag: "`--client-id`"
  - setting: Grant types
    value: "Authorization code and refresh token."
    flag: ""
  - setting: PKCE
    value: "Required, with the `S256` method."
    flag: ""
  - setting: Callback, also called the redirect URI
    value: "`http://localhost:9876/callback`, or the value that you set in the profile. See [Callback](#callback)."
    flag: "`--redirect-uri`"
  - setting: Scopes
    value: "`openid`, `profile`, `email` and `offline_access`. `offline_access` is required. See [Offline access and renewal](#offline-access-and-renewal)."
    flag: "`--scope`"
  - setting: Audience
    value: "The audience that the gateway accepts. See [Gateway audience](#gateway-audience)."
    flag: "`--audience`, `--audience-parameter`"
  - setting: Access token lifetime
    value: "From 6 minutes to 1 hour, or up to the longest lifetime that the profile accepts. See [Access token lifetime](#access-token-lifetime)."
    flag: "`--max-token-lifetime-seconds`"
{% endtable %}

## Callback

The callback is the address on the developer's computer that the identity provider sends the browser back to after the sign-in.
{{site.kong_harnesses}} listens on that address during `kong-harnesses login`, so the developer must open the sign-in page in a browser on the same computer.

The identity provider compares the callback character by character.
Register the exact value that the profile uses.
`localhost`, `127.0.0.1` and `[::1]` are different values to the identity provider, so a profile with `http://127.0.0.1:9876/callback` fails to sign in when the client has `http://localhost:9876/callback`.
`kong-harnesses profile get` and `kong-harnesses doctor` show the callback of a profile, so you can compare it with the client.

To use another callback, set `--redirect-uri` when you create the profile.
The value must:

* Use `http`.
* Have the host `localhost`, `127.0.0.1` or `[::1]`.
* Have a port.
* Have a path, such as `/callback`.

The callback uses one port, so on a computer that several developers share, only one of them can sign in at a time.
A second sign-in stops with a message that another program is using the callback address.
It works again when the first sign-in ends.

## Offline access and renewal

{{site.kong_harnesses}} renews the access token with a refresh token.
The sign-in fails if the identity provider doesn't issue a refresh token.
Give the client the refresh token grant type, and allow the `offline_access` scope for it.
{{site.kong_harnesses}} always requests `offline_access`, and `profile create` refuses a scope list without it.

The identity provider can rotate the refresh token on each use, or keep the same one.
{{site.kong_harnesses}} saves each new refresh token that it gets.
When the identity provider refuses a refresh token, for example because it expired or because you revoked it, the developer must run `kong-harnesses login` again.

`kong-harnesses logout` revokes the refresh token at the identity provider when the discovery document of the identity provider lists a `revocation_endpoint`.
Otherwise, `logout` only removes the sign-in from the computer.
An access token that the identity provider already issued stays valid until it expires.

## Gateway audience

The gateway accepts an access token only for its own audience.
Set `audience_required` in the `openid-connect` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) and `--audience` in the profile to the same value.

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
    description: "Default. The sign-in request sends the audience in the `resource` parameter of RFC 8707."
  - value: "`audience`"
    description: "The sign-in request sends the audience in the `audience` parameter. Use this value for an identity provider that reads `audience`, such as Auth0."
  - value: "`none`"
    description: "The sign-in request doesn't send the audience. Use this value when the client registration sets the audience, such as in Microsoft Entra ID. Pass every scope with `--scope`, the default scopes and the scope of the gateway API, so that the access token gets the audience."
{% endtable %}

{{site.kong_harnesses}} doesn't check the audience of the access token.
If the identity provider ignores the audience in the request, its access tokens don't get the gateway audience, and the gateway refuses them.
Before you give the profile to developers, check that an access token from the client has the gateway audience in its `aud` claim.

The Hermes Agent plugin sends the audience in the `audience` parameter and requests only the default scopes.
A profile that sets up Hermes Agent needs `--audience-parameter audience` and the default scopes.

## Discovery document

{{site.kong_harnesses}} reads the OIDC discovery document of the identity provider when you create the profile and at each sign-in.
The issuer URL must use `https`.
It must also match the `issuer` value in the discovery document character by character, including a trailing slash.

`profile create` refuses a discovery document that lists a capability without the value that {{site.kong_harnesses}} needs:

* The `S256` PKCE method in `code_challenge_methods_supported`.
* The `authorization_code` and `refresh_token` grant types in `grant_types_supported`.
* The `none` method, for a public client, in `token_endpoint_auth_methods_supported`.

A discovery document that leaves out one of these fields passes the check.
Some identity providers, such as Microsoft Entra ID, don't list `none` even for a public client.
For them, add `--public-client-evidence deployment` to `profile create`.
The flag skips only the check for `none`.

## Access token lifetime

{{site.kong_harnesses}} refuses an access token that lasts less than 6 minutes, at sign-in and at renewal.
It also refuses an access token that lasts longer than the profile allows, by default 1 hour.
If your identity provider issues longer access tokens, set `--max-token-lifetime-seconds` to the lifetime that it issues, up to 86400 seconds.
After a change to this value, developers must run `kong-harnesses login` again.

## Create the profile

Create a profile with the values of the client:

```sh
kong-harnesses profile create \
  --name <profile-name> \
  --issuer <issuer-url> \
  --client-id <client-id> \
  --audience <audience> \
  --gateway-origin <gateway-url> \
  --model <model-id>
```

Add `--redirect-uri`, `--scope`, `--audience-parameter`, `--public-client-evidence` or `--max-token-lifetime-seconds` when your identity provider needs them.
