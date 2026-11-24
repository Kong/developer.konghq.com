---
title: Authorize and rate limit requests by IdP claims
permalink: /how-to/authorize-and-rate-limit-by-idp-claims/
content_type: how_to

related_resources:
  - text: OpenID Connect in {{site.base_gateway}}
    url: /gateway/openid-connect/
  - text: CEL-based authorization using token claims
    url: /plugins/openid-connect/#cel-based-authorization-using-token-claims
  - text: Conditional expressions for plugins
    url: /gateway/plugins/conditions/
  - text: CEL reference
    url: /gateway/plugins/expressions/
  - text: Dynamic plugin config with CEL
    url: /gateway/plugins/expressible-fields/
  - text: OpenID Connect tutorials
    url: /how-to/?query=openid-connect

plugins:
  - openid-connect
  - acl
  - rate-limiting-advanced

entities:
  - route
  - service
  - plugin

products:
  - gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.17'

tools:
  - deck

prereqs:
  entities:
    services:
      - example-service
    routes:
      - example-route
  inline:
    - title: Set up Keycloak
      include_content: prereqs/auth/oidc/keycloak-consumer-group
      icon_url: /assets/icons/keycloak.svg

tags:
  - authentication
  - authorization
  - openid-connect
  - traffic-control
search_aliases:
  - oidc
  - cel

description: Use the claims in a validated OpenID Connect token to decide who can reach a Service and how much they can send, without creating a Consumer or Principal for each caller.

tldr:
  q: How do I authorize and rate limit callers by what their identity provider says about them, instead of by Consumer or Principal?
  a: |
    Enable the [OpenID Connect plugin](/plugins/openid-connect/) to validate each caller's token, then read that token's claims in CEL with `access_token.claims`.

    Use those claims in the [ACL plugin](/plugins/acl/)'s `allow_when` field to decide who can reach the Service.
    Then, use them in a [Rate Limiting Advanced](/plugins/rate-limiting-advanced/) plugin's `expressions` field to give each caller their own counter and limit.
    
    Because every decision comes from the token, {{site.base_gateway}} doesn't need a Consumer or a Principal for each caller.

faqs:
  - q: Can I use an identity provider other than Keycloak?
    a: |
      Yes. The OpenID Connect plugin works with any OIDC-compliant provider.
      Replace the issuer and client credentials with values from your provider, and change the claim names in the expressions to the ones your provider issues.
  - q: What happens if the token doesn't have the claim that an expression reads?
    a: |
      The ACL plugin's `has()` check evaluates to `false`, so the plugin denies the request.
      The `expressions.limit` check returns `5`.
      If the token doesn't have a `sub` claim, `expressions.custom_key` fails to evaluate, and the plugin uses the static `config.custom_key` value.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Generate salt token

{% include how-tos/steps/deck-salt-token.md %}

## Enable the OpenID Connect plugin

Using the Keycloak and {{site.base_gateway}} configuration from the [prerequisites](#prerequisites), enable the [OpenID Connect plugin](/plugins/openid-connect/) on the `example-service` Service.

The plugin uses the client credentials grant, validates the token that Keycloak issues, and makes the token's claims available to the plugins that run after it.

{% entity_examples %}
entities:
  plugins:
    - name: openid-connect
      service: example-service
      config:
        issuer: ${issuer}
        auth_methods:
          - client_credentials
        cache_tokens_salt: ${salt-token}
variables:
  issuer:
    value: $ISSUER
  salt-token:
    value: $TOKEN_SALT
{% endentity_examples %}

In this example:
* `issuer`: Connects the plugin to your identity provider (IdP), in this case the sample Keycloak app.
* `auth_methods`: Uses the client credentials grant.

The plugin doesn't map the token to a Consumer, Consumer Group, or Principal.
A validated token is enough to pass authentication.

{:.info}
> Your identity provider's issuer URL has to be reachable from the data plane that runs {{site.base_gateway}}, because that's where token validation happens.

## Authorize callers by claim

In this setup, authentication and authorization are separate.
The OpenID Connect plugin accepts any valid token from Keycloak.
The [ACL plugin](/plugins/acl/)'s `allow_when` field restricts the Service to callers with `tier: gold`:

{% entity_examples %}
entities:
  plugins:
    - name: acl
      service: example-service
      config:
        allow_when:
          - 'has(access_token.claims.tier) && access_token.claims.tier == "gold"'
{% endentity_examples %}

The `has()` check prevents an evaluation error when the token doesn't have a `tier` claim.
For more information, see [null handling](/gateway/plugins/expressions/#null-handling) in the CEL expressions reference.

## Rate limit callers by claim

Enable the [Rate Limiting Advanced](/plugins/rate-limiting-advanced/) plugin with a counter key and a limit that both come from the caller's token:

{% entity_examples %}
entities:
  plugins:
    - name: rate-limiting-advanced
      service: example-service
      config:
        identifier: ip
        namespace: idp-claims
        custom_key: unknown-caller
        limit:
          - 5
        window_size:
          - 60
        strategy: local
      expressions:
        custom_key: access_token.claims.sub
        limit:
          - '(has(access_token.claims.tier) && access_token.claims.tier == "gold") ? 100 :5'
{% endentity_examples %}

In this example:
* `expressions.custom_key`: Keys the counter on the `sub` claim, so each caller gets their own counter without a Consumer or Principal.
* `expressions.limit`: Gives `gold` callers 100 requests per minute and everyone else 5.
* `config.custom_key` and `config.limit`: Static fallbacks that the plugin uses when an expression can't be evaluated.
  We recommend a low fallback limit, because a caller whose token doesn't have the expected claims is then restricted instead of unlimited.
* `config.namespace`: Groups this plugin's counters. Set it explicitly with decK or in DB-less mode, so the namespace isn't regenerated on every update.
* `config.window_size`: Set in `config` only, because `window_size` isn't an [expressible field](/gateway/plugins/expressible-fields/#expressible-config-fields).

## Validate

Send a request with the wrong client secret to verify that {{site.base_gateway}} rejects it:

<!--vale off-->
{% validation request-check %}
url: /anything
method: GET
status_code: 401
headers:
  - 'Authorization: Basic {{ "kong:wrong-secret" | base64 }}'
display_headers: true
{% endvalidation %}
<!--vale on-->

You should see a `401` response.

Now send the same request with the Keycloak client's credentials.
{{site.base_gateway}} runs the client credentials grant against Keycloak, validates the token it gets back, and makes its claims available to the ACL and Rate Limiting Advanced plugins:

<!--vale off-->
{% validation request-check %}
url: /anything
method: GET
status_code: 200
headers:
  - 'Authorization: Basic {{ "kong:$CLIENT_SECRET" | base64 }}'
display_headers: true
{% endvalidation %}
<!--vale on-->

This time, the request succeeds with a 200, because the token carries `tier: gold` and the ACL plugin allows it.

Check the `RateLimit-Limit` response header:

```
RateLimit-Limit: 100
```
{:.no-copy-code}

The limit is `100` because `expressions.limit` read the `tier` claim, instead of using the static fallback of `5` in `config.limit`.
The plugin keys the counter on the `sub` claim, so every caller gets their own counter.
