---
title: 'OAuth 2.0 Introspection'
name: 'OAuth 2.0 Introspection'

content_type: plugin

publisher: kong-inc
description: 'Integrate Kong with a third-party OAuth 2.0 Authorization Server'


products:
    - gateway

works_on:
    - on-prem
    - konnect

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: oauth2-introspection.png

categories:
  - authentication

search_aliases:
  - oauth2-introspection
---

Validate access tokens sent by developers using a third-party OAuth 2.0
Authorization Server by leveraging its introspection endpoint
([RFC 7662](https://tools.ietf.org/html/rfc7662)). This plugin assumes that
the Consumer already has an access token that will be validated against a
third-party OAuth 2.0 server.

{:.info}
> **Note**: The [OpenID Connect Plugin](/plugins/openid-connect/) supports
OAuth 2.0 Token Introspection as well and offers functionality beyond
this plugin, such as restricting access by scope.

## How it works

1. The client uses the third-party OAuth 2.0 server to generate an access token, and uses it to make a request through {{site.base_gateway}}.
1. The third-party OAuth 2.0 server leverages the OAuth 2.0 Introspection plugin to validate the client's access token.
1. If the token is valid, {{site.base_gateway}} proxies the request to the upstream service, which sends the response back to the client through {{site.base_gateway}}.

## Associate the response with a Consumer

To associate the introspection response resolution with a {{site.base_gateway}} Consumer, provision the Consumer with the same `username` returned by the introspection endpoint response.

## Upstream headers

When a client has been authenticated, the plugin appends the following headers to the request before proxying it to the upstream API/microservice.
Use these headers to identify the consumer in your code:

- `X-Consumer-ID`, the ID of the consumer on Kong (if matched)
- `X-Consumer-Custom-ID`, the `custom_id` of the consumer (if matched and if existing)
- `X-Consumer-Username`, the `username of` the consumer (if matched and if existing)
- `X-Anonymous-Consumer`, set to true if authentication fails, and the `anonymous` consumer is set instead.
- `X-Credential-Scope`, as returned by the Introspection response (if any)
- `X-Credential-Client-ID`, as returned by the Introspection response (if any)
- `X-Credential-Identifier`, as returned by the Introspection response (if any)
- `X-Credential-Token-Type`, as returned by the Introspection response (if any)
- `X-Credential-Exp`, as returned by the Introspection response (if any)
- `X-Credential-Iat`, as returned by the Introspection response (if any)
- `X-Credential-Nbf`, as returned by the Introspection response (if any)
- `X-Credential-Sub`, as returned by the Introspection response (if any)
- `X-Credential-Aud`, as returned by the Introspection response (if any)
- `X-Credential-Iss`, as returned by the Introspection response (if any)
- `X-Credential-Jti`, as returned by the Introspection response (if any)

Additionally, any claims specified in `config.custom_claims_forward` are also forwarded with the `X-Credential-` prefix.

{:.info}
> **Note:** If authentication fails, the plugin doesn't set any `X-Credential-*` headers.
It appends `X-Anonymous-Consumer: true` and sets the `anonymous` consumer instead.


