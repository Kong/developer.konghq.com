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

{{site.kong_harnesses}} signs a developer in to your [OpenID Connect (OIDC)](/ai-gateway/openid-connect/) identity provider in the browser, with the authorization code flow and [Proof Key for Code Exchange (PKCE)](https://www.rfc-editor.org/rfc/rfc7636).
It gets new access tokens with a refresh token, so the developer doesn't sign in for each one.
Register one client for {{site.kong_harnesses}} in the identity provider, and put its values in the profile that you create with [`kong-harnesses profile create`](/kong-harnesses/profile/create/).

{{site.kong_harnesses}} is tested with Okta.
For the Okta steps, see the prerequisites of [Set up {{ site.claude_code }} with kong-harnesses](/ai-gateway/set-up-claude-code-with-kong-harnesses/).
For Auth0, Keycloak, Microsoft Entra ID and PingFederate, see [Identity provider settings](/kong-harnesses/identity-provider/providers/).
Other OIDC identity providers need the same kinds of settings.

## Client settings

Register the {{site.kong_harnesses}} client in the identity provider with the following settings, and set the matching `profile create` flags.

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Value
    key: value
  - title: Profile flag
    key: flag
rows:
  - setting: Issuer
    value: |
      The issuer URL of the identity provider, exactly as its discovery document lists it, with a trailing slash when the document has one.
      See [Discovery document](/kong-harnesses/identity-provider/checks/#discovery-document).
    flag: "`--issuer`"
  - setting: Client type
    value: |
      A public client, such as a native application.
      The client doesn't have a client secret.
    flag: "No flag"
  - setting: Client ID
    value: "The ID that the identity provider gives the client."
    flag: "`--client-id`"
  - setting: Grant types
    value: "Authorization code and refresh token."
    flag: "No flag"
  - setting: Response type
    value: |
      `code`, with the authorization code in the query of the callback.
      If the identity provider has a response mode setting, select `query`.
    flag: "No flag"
  - setting: Token type
    value: |
      `Bearer`, at sign-in and at renewal.
      A token type other than `Bearer`, such as `DPoP`, fails the sign-in and the renewal.
    flag: "No flag"
  - setting: PKCE
    value: "Required, with the `S256` method, which {{site.kong_harnesses}} always sends."
    flag: "No flag"
  - setting: ID token signature
    value: |
      An RSA or ECDSA algorithm, such as `RS256` or `ES256`.
      See [ID token](/kong-harnesses/identity-provider/checks/#id-token).
    flag: "No flag"
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
{{site.kong_harnesses}} waits up to 2 minutes for the browser callback, so the developer must finish the steps in the browser within that time.
At each sign-in in the browser, {{site.kong_harnesses}} sends `prompt=consent` to ask for the consent screen, but the identity provider can skip it.
For the checks on the callback request, see [Callback](/kong-harnesses/identity-provider/checks/#callback).

Register the callback of the profile in the client as an exact value, not as a pattern.
Use the same host, port and path in the client.
If your identity provider ignores the port when it matches a loopback callback, as [RFC 8252](https://www.rfc-editor.org/rfc/rfc8252#section-7.3) allows, the port that you register can differ from the port in the profile.
[`kong-harnesses profile get`](/kong-harnesses/profile/get/) and [`kong-harnesses doctor`](/kong-harnesses/doctor/) show the callback of a profile.

To use another callback, set `--redirect-uri` to a value that meets these rules:

* It uses `http`.
* Its host is `localhost`, `127.0.0.1` or `[::1]`.
* Its port is from 1 to 65535, without a zero at the start.
* Its path has 2 to 256 characters and starts with `/`, such as `/callback`.
  The path can have letters, digits, `-`, `.`, `_`, `~` and `/`, but it can't have `//` or a `.` or `..` segment, and it can't end with `/`.
* It doesn't have user information, a query or a fragment.

For a `localhost` callback, {{site.kong_harnesses}} listens on `127.0.0.1`, and also on `[::1]` when the computer has it.
Two sign-ins on the same computer conflict when they need the same address and port, even with different paths.
For example, a `localhost` callback and a `127.0.0.1` callback on the same port conflict.
To let several profiles sign in at the same time, give each profile a different port.

{% navtabs "callback-port-conflicts" %}
{% navtab "macOS and Linux" %}

When another program, such as another sign-in, listens on the callback address and port, the sign-in stops with an `AUTH_TEMPORARY` error that says that the sign-in callback address is in use.

{% endnavtab %}
{% navtab "Windows" %}

When another program, such as another sign-in, listens on the callback address and port, or when Windows reserved the port, the sign-in stops with an `AUTH_TEMPORARY` error that says that the sign-in callback address is in use.
The error also names the commands that list the reserved ports.

To list the TCP ports that Windows reserved for IPv4, run this command:

```powershell
netsh interface ipv4 show excludedportrange protocol=tcp
```

To list the TCP ports that Windows reserved for IPv6, run this command:

```powershell
netsh interface ipv6 show excludedportrange protocol=tcp
```

{% endnavtab %}
{% endnavtabs %}

## Offline access and renewal

The sign-in fails if the identity provider doesn't issue a refresh token.
Give the client the refresh token grant type and the `offline_access` scope.

When you set `--scope`, your list replaces the defaults, so give each scope that you need with its own `--scope` flag.
For the rules of the list, see [Sign-in fields](/kong-harnesses/profile-file/#sign-in-fields).
For the checks on the `scope` value and the other fields of a token response, see [Token responses](/kong-harnesses/identity-provider/checks/#token-responses).

{{site.kong_harnesses}} saves each new refresh token, so the identity provider can rotate refresh tokens or keep the same one.
When the identity provider refuses a refresh token, for example because it expired or because you revoked it, the developer must run [`kong-harnesses login`](/kong-harnesses/login/) again.
For the responses that remove the saved sign-in, see [HTTP responses](/kong-harnesses/identity-provider/checks/#http-responses).

To revoke the refresh token when a developer signs out, see [`kong-harnesses logout`](/kong-harnesses/logout/).

## Gateway audience

The gateway checks the audience of an access token when the `openid-connect` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) sets [`config.audience_required`](/ai-gateway/openid-connect/#authorization).
Set `config.audience_required` to a list that contains the gateway audience.
Use the value that the identity provider puts in the claim that `config.audience_claim` selects.
The default claim is `aud`.

Set `--audience` in the profile to an absolute URI that identifies the gateway, such as `https://gateway.example.com/api`.
The profile needs this value with every `--audience-parameter` value, including `none`.
For the rules of the value, see [Sign-in fields](/kong-harnesses/profile-file/#sign-in-fields).
The `aud` claim of the access token can differ from the `--audience` value.

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
      The sign-in request sends the audience in the `resource` parameter of [RFC 8707](https://www.rfc-editor.org/rfc/rfc8707).
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
If the identity provider ignores the audience in the request and doesn't set it in another way, its access tokens don't get the gateway audience.
A gateway with `config.audience_required` refuses these access tokens.
{{site.kong_harnesses}} sends the audience only in the authorization request in the browser, not in the code exchange or the renewal request.

Before you give the profile to developers, check that the gateway accepts access tokens from a sign-in and from a renewal.

## Discovery document

[`profile create`](/kong-harnesses/profile/create/) reads the OIDC discovery document of the identity provider, and refuses a document that doesn't meet the rules in [Discovery document](/kong-harnesses/identity-provider/checks/#discovery-document) of the checks page.

Some identity providers list `token_endpoint_auth_methods_supported` in the discovery document without `none`, even for a public client.
For them, first test a separate client in a non-production deployment, with `--public-client-evidence deployment` in its profile, and check that it signs in and renews its access token without a client secret.
After the test passes, create the production profile with the flag, which skips only the check for `none`.

## Access token lifetime

{{site.kong_harnesses}} reads the lifetime from `expires_in` in the token response, at sign-in and at renewal.
It refuses a lifetime under 365 seconds, so that a renewed access token still has at least 360 seconds left when a client gets it.
If the identity provider sets the lifetime in whole minutes, use at least 7 minutes.
{{site.kong_harnesses}} also refuses a lifetime over the limit of the profile, 3600 seconds by default.

If your identity provider issues longer access tokens, find the longest access token lifetime in its policy, and set `--max-token-lifetime-seconds` to that value, from 365 to 86400 seconds.
If the policy allows more than 86400 seconds, reduce it to 86400 seconds.

## Create the profile

To create and publish a profile with your identity provider settings, see [Profile creation](/kong-harnesses/profiles-for-administrators/#profile-creation) and [`kong-harnesses profile create`](/kong-harnesses/profile/create/).
A change to a sign-in value of the profile, such as `--issuer`, `--client-id`, `--redirect-uri`, `--scope`, `--audience` or `--max-token-lifetime-seconds`, changes the security identity of the profile.
For which fields belong to the security identity, and how `profile create` and [`profile import`](/kong-harnesses/profile/import/) handle changes while a client uses the profile, see [Security identity](/kong-harnesses/profile-file/#security-identity).
