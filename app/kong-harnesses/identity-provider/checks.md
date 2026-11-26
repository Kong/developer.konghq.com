---
title: "Identity provider checks in {{site.kong_harnesses}}"
description: "The checks that {{site.kong_harnesses}} makes on the URLs, discovery document, signing keys, token responses and ID tokens of an OpenID Connect identity provider."
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
  - text: Identity provider settings for kong-harnesses
    url: /kong-harnesses/identity-provider/providers/
---

When `profile create` or `kong-harnesses login` fails, the error names the setting of your identity provider to change.
Find your message in the following table, change the setting, and run the command again.
For the client settings, see [Register {{site.kong_harnesses}} in your identity provider](/kong-harnesses/identity-provider/).

## Fix a sign-in error

The error text is lowercase, and some messages start with `OIDC login:`.

{% table %}
columns:
  - title: What you see
    key: message
  - title: What to change
    key: fix
rows:
  - message: "`the identity provider denied access; the account may not be assigned to the provider client or allowed by its access policy`"
    fix: "Assign the user to the client in the identity provider, and check its access policy."
  - message: "`the identity provider rejected the requested scopes`"
    fix: "Allow the scopes of the profile for the client, by default `openid`, `profile`, `email` and `offline_access`."
  - message: "`the provider client is not allowed to use the authorization-code flow`"
    fix: "Turn on the authorization code grant for the client."
  - message: "`the identity provider required a sign-in or consent step that was not completed`"
    fix: "Complete the sign-in or consent step in the browser."
  - message: "`another program on this computer, such as another sign-in, is using the sign-in callback address`"
    fix: "Give each profile a different port. See [Port conflicts](#port-conflicts)."
  - message: "`the token endpoint did not return a usable refresh token`"
    fix: "Turn on the refresh token grant for the client, and allow the `offline_access` scope."
  - message: "`the token endpoint did not return a bearer token`"
    fix: "Issue `Bearer` access tokens. A type such as `DPoP` fails the sign-in."
  - message: "`the granted scopes do not satisfy the selected profile`"
    fix: "Allow every scope that the profile requests for the client."
  - message: "`the identity provider granted a scope that the profile did not request`"
    fix: "Remove that scope from the client. On Keycloak, put the Audience mapper on the dedicated scope of the client, or turn off **Include in token scope**."
  - message: "`the identity provider issued an access token that lives less than 365 seconds`"
    fix: "Set the access token lifespan in the identity provider to at least 365 seconds."
  - message: "`the identity provider issued an access token that lives longer than the profile's max_access_token_lifetime_seconds`"
    fix: "Raise it with `profile create --max-token-lifetime-seconds`, or shorten the lifespan in the identity provider."
  - message: "`the identity provider's discovery does not list none in token_endpoint_auth_methods_supported`"
    fix: "For a client without a secret, test the client, then create the profile with `--public-client-evidence deployment`. See [Discovery document](#discovery-document)."
  - message: "`the ID token failed validation`"
    fix: "See [What kong-harnesses validates](#what-kong-harnesses-validates)."
  - message: "`issuer metadata incompatible`"
    fix: "Compare the discovery document with [Discovery document](#discovery-document)."
  - message: "`issuer discovery unavailable`"
    fix: "Check that the identity provider answers at the issuer URL, and that its certificate is trusted. See [HTTP responses](#http-responses)."
  - message: "`browser launch failed`"
    fix: "Run `kong-harnesses login --no-browser`, and open the printed address in a browser on the same computer."
{% endtable %}

If your message isn't in the table, run [`kong-harnesses doctor`](/kong-harnesses/doctor/).

## Port conflicts

When another program listens on the callback address and port, the sign-in stops with an `AUTH_TEMPORARY` error that says that the callback address is in use.
On Windows, the error also appears when Windows reserved the port, for example for Hyper-V, even if no program listens on it.
Two sign-ins conflict when they need the same address and port, also with different paths, and a `localhost` callback conflicts with a `127.0.0.1` callback on the same port.
To fix it, give each profile that signs in at the same time a different port in `--redirect-uri`.

To list the TCP ports that Windows reserved, run these commands in PowerShell:

```powershell
netsh interface ipv4 show excludedportrange protocol=tcp
netsh interface ipv6 show excludedportrange protocol=tcp
```

## Discovery document

The discovery document is a JSON file that your identity provider publishes at the issuer URL plus `/.well-known/openid-configuration`.
It tells {{site.kong_harnesses}} where to send the sign-in and the token requests, and which features the provider supports.
{{site.kong_harnesses}} reads it when you run `profile create`, and again at each sign-in.

To check yours, open that address in a browser.
The sign-in is refused unless the document has the following members:

{% table %}
columns:
  - title: Member
    key: member
  - title: Must be
    key: value
  - title: Checked
    key: checked
rows:
  - member: "`issuer`"
    value: "The issuer of the profile, character by character, including a trailing slash."
    checked: Always
  - member: "`authorization_endpoint`, `token_endpoint`, `jwks_uri`"
    value: "A URL."
    checked: Always
  - member: "`response_types_supported`"
    value: "A list that includes `code`."
    checked: Always
  - member: "`id_token_signing_alg_values_supported`"
    value: "A list that includes at least one of `RS256`, `RS384`, `RS512`, `PS256`, `PS384`, `PS512`, `ES256`, `ES384` or `ES512`."
    checked: Always
  - member: "`code_challenge_methods_supported`"
    value: "A list that includes `S256`."
    checked: Only when the document has it
  - member: "`grant_types_supported`"
    value: "A list that includes `authorization_code` and `refresh_token`."
    checked: Only when the document has it
  - member: "`token_endpoint_auth_methods_supported`"
    value: "A list that includes `none`. `--public-client-evidence deployment` skips this check."
    checked: Only when the document has it
{% endtable %}

At each sign-in, {{site.kong_harnesses}} reads the document again.
If `authorization_endpoint`, `token_endpoint`, `jwks_uri` or `revocation_endpoint` no longer matches the value in the profile, the sign-in fails until you create the profile again and give it to developers.

A document without the optional members is accepted, but then {{site.kong_harnesses}} can't tell that the identity provider supports the feature.
For example, without `code_challenge_methods_supported`, check yourself that the token endpoint refuses a code exchange without a valid `S256` code verifier.

## HTTP responses

{{site.kong_harnesses}} sends requests to the identity provider over TLS 1.2 or later, and doesn't follow redirects.
The TLS certificate must chain to the system trust store of each developer computer, because the gateway CA bundle of a profile doesn't apply to the identity provider.
If the identity provider uses a private CA, add the CA to that trust store.

At renewal, when the token endpoint answers with the error `invalid_grant`, {{site.kong_harnesses}} removes the saved refresh token, and the developer must sign in again.
For other errors, the renewal fails and the refresh token stays for the next renewal.

## What {{site.kong_harnesses}} validates

At sign-in, {{site.kong_harnesses}} checks:

* **The authorization response:** it comes back to the callback with the `state` of the sign-in. When it has `iss`, the value is the issuer of the profile.
* **The token response:** it has an access token, a `Bearer` token type, a refresh token and `expires_in`. When it has `scope`, it keeps every custom scope that the profile requests, and names no scope that the profile didn't request. The standard scopes are `openid`, `profile`, `email`, `address`, `phone`, `offline_access`, `groups` and `device_sso`.
* **The ID token:** it is signed with an algorithm from the discovery document, with a key from `jwks_uri`. `iss` is the issuer of the profile, `aud` is only the client ID, `nonce` is the nonce of the sign-in request, and the token hasn't expired. {{site.kong_harnesses}} doesn't tolerate clock differences, so keep the clock of the computer correct.

A renewal checks the token response again.
For the limits of each profile value, see [Sign-in fields](/kong-harnesses/profile-file/#sign-in-fields).
