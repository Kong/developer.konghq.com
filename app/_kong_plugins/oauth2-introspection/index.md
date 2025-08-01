---
title: 'OAuth 2.0 Introspection'
name: 'OAuth 2.0 Introspection'

content_type: plugin
tier: enterprise
publisher: kong-inc
description: 'Integrate {{site.base_gateway}} with a third-party OAuth 2.0 Authorization Server'


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

tags:
  - authentication
  - oauth2

search_aliases:
  - oauth2-introspection
  - OAuth 2.0

related_resources:
  - text: "{{site.base_gateway}} authentication"
    url: /gateway/authentication/
  - text: OAuth 2.0 Authentication plugin
    url: /plugins/oauth2/reference/
  - text: Configure the OAuth 2.0 Introspection plugin with Kong Identity
    url: /how-to/configure-kong-identity-oauth-introspection/

min_version:
  gateway: '1.0'
---

You can validate access tokens sent by developers using a third-party OAuth 2.0
Authorization Server by leveraging its introspection endpoint
([RFC 7662](https://tools.ietf.org/html/rfc7662)). This plugin assumes that
the [Consumer](/gateway/entities/consumer/) already has an access token that will be validated against a
third-party OAuth 2.0 server.

{:.info}
> **Note**: The [OpenID Connect Plugin](/plugins/openid-connect/) supports
OAuth 2.0 Token Introspection as well and offers functionality beyond
this plugin, such as restricting access by scope.

## How the OAuth 2.0 Introspection works

1. The client uses the third-party OAuth 2.0 server to generate an access token, and uses it to make a request through {{site.base_gateway}}.
1. The third-party OAuth 2.0 server leverages the OAuth 2.0 Introspection plugin to validate the client's access token.
1. If the token is valid, {{site.base_gateway}} proxies the request to the upstream service, which sends the response back to the client through {{site.base_gateway}}.
<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client
    participant oauth as OAuth 2.0 server
    participant kong as {{site.base_gateway}} with <br> Introspection plugin
    participant upstream as Upstream service
    activate client
    activate oauth
    client->>oauth: request access token
    oauth->>client: generate access token
    activate kong
    client->>kong: send request with<br>access token
    deactivate client
    kong->>oauth: send access token <br>for verification
    oauth->>kong: verify access token
    activate upstream
    kong->>upstream: send request with<br>access token
    upstream->>kong: response
    deactivate upstream
    activate client
    kong->>client: response
    deactivate kong
    deactivate client
{% endmermaid %}
<!--vale on-->
## Associate the response with a Consumer

To associate the introspection response resolution with a {{site.base_gateway}} Consumer, provision the Consumer with the same `username` as the one returned by the introspection endpoint response.

## Upstream headers

When a client has been authenticated, the plugin appends the following headers to the request before proxying it to the upstream API/microservice.
Use these headers to identify the Consumer in your code:

- `X-Consumer-ID`, the ID of the Consumer on {{site.base_gateway}} (if matched)
- `X-Consumer-Custom-ID`, the `custom_id` of the Consumer (if matched and if existing)
- `X-Consumer-Username`, the `username of` the Consumer (if matched and if existing)
- `X-Anonymous-Consumer`, set to true if authentication fails, and the `anonymous` Consumer is set instead.
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
It appends `X-Anonymous-Consumer: true` and sets the `anonymous` Consumer instead.


