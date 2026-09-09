---
title: Configure dynamic plugin config with CEL in {{site.base_gateway}}
permalink: /gateway/configure-dynamic-plugin-config-with-cel/
content_type: how_to

description: Learn how to set a Rate Limiting Advanced plugin's rate limit and rate limiting key per request, based on the authenticated Principal's metadata.
products:
    - gateway
    - identity

plugins:
  - rate-limiting-advanced

works_on:
    - konnect

entities:
  - plugin
  - service
  - route
  - principal

tags:
    - traffic-control
    - authentication

tools:
    - konnect-api

tldr:
  q: How do I compute a plugin's config from a CEL expression instead of a fixed value?
  a: |
    To compute a plugin's config from a CEL expression instead of a fixed value, set a config field's parallel `expressions.FIELD` entry to a CEL expression, alongside the field's ordinary static `config.FIELD` value. 
    {{site.base_gateway}} evaluates the expression per request. 
    If it succeeds, its result overrides the field for that request; if it fails, {{site.base_gateway}} falls back to the static `config` value.

    This guide computes Rate Limiting Advanced's `limit` and `custom_key` fields from a Principal's metadata, so each authenticated client gets their own rate limit and their own counter from a single plugin instance.

faqs:
  - q: What happens if a Principal is missing the metadata that an expression expects to find?
    a: |
      If the Principal is missing expected metadata, the expression fails to evaluate, and {{site.base_gateway}} falls back to the field's static `config` value for that request. 
      {{site.base_gateway}} doesn't raise an error, and the plugin still runs normally.

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
  inline:
    - title: Kong Identity directory
      include_content: prereqs/kong-identity-directory
      icon_url: /assets/icons/identity.svg
    - title: Konnect API
      include_content: prereqs/konnect-api-for-curl

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.16'

related_resources:
  - text: Dynamic plugin config with CEL
    url: /gateway/plugins/expressible-fields/
  - text: CEL expressions for plugins
    url: /gateway/plugins/expressions/
  - text: Rate Limiting Advanced plugin
    url: /plugins/rate-limiting-advanced/

automated_tests: false
---

## Create a Principal

{% include /how-tos/steps/principal.md %}

Set `rate_limit` and `partner_id` metadata on the Principal so the plugin's expressions have something to read:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals/$PRINCIPAL_ID
status_code: 200
method: PUT
body:
  display_name: "example-principal"
  description: "Example principal"
  metadata:
    rate_limit: 20
    partner_id: acme-rockets
{% endkonnect_api_request %}
<!--vale on-->

## Add key auth

Add an API key credential to the Principal so clients can authenticate with {{site.base_gateway}} using key authentication.

The following example sets a system-generated key (`v1`) and stores the key secret as `$KEY_SECRET`:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals/$PRINCIPAL_ID/api-keys
status_code: 201
method: POST
body:
  type: v1
capture:
  - variable: KEY_SECRET
    jq: ".secret"
{% endkonnect_api_request %}
<!--vale on-->

## Get the directory name

{% include /how-tos/steps/get-directory-name.md %}

## Configure the Key Auth plugin

Enable the [Key Auth](/plugins/key-auth/) plugin so clients can authenticate with an API key, and resolve the authenticated Principal for later plugins to read:

{% entity_examples %}
entities:
  plugins:
  - name: key-auth
    route: example-route
    config:
      identity_realms: []
      principals:
        enabled: true
        directory: ${directory_name}
variables:
  directory_name:
    value: $DIRECTORY_NAME
formats:
  - deck
{% endentity_examples %}

## Configure Rate Limiting Advanced with CEL expressions

`limit` and `custom_key` are [expressible config fields](/gateway/plugins/expressible-fields/#expressible-config-fields) on Rate Limiting Advanced. They both have parallel entries under `expressions`, alongside their static `config` values. 
Configure the plugin globally with:

* `identifier: principal`, so the plugin keys and limits by the authenticated Principal.
* A static `config.limit` and `config.custom_key`, used as the fallback whenever a request's expressions can't be evaluated.
* `expressions.limit` and `expressions.custom_key`, reading the authenticated Principal's `rate_limit` and `partner_id` metadata.

<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/plugins/
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: rate-limiting-advanced
  config:
    identifier: principal
    custom_key: unknown-partner
    limit:
      - 10
    window_size:
      - 60
    strategy: local
  expressions:
    custom_key: principal.metadata.partner_id
    limit:
      - principal.metadata.rate_limit
{% endkonnect_api_request %}
<!--vale on-->

{% comment %}
_to do: uncomment and replace API instructions once decK support is added_
{% entity_examples %}
entities:
  plugins:
    - name: rate-limiting-advanced
      config:
        identifier: principal
        custom_key: unknown-partner
        limit:
          - 10
        window_size:
          - 60
        strategy: local
      expressions:
        custom_key: principal.metadata.partner_id
        limit:
          - principal.metadata.rate_limit
formats:
  - deck
{% endentity_examples %}
{% endcomment %}

## Validate

Send a request with the API key stored in `$KEY_SECRET`:

{% validation request-check %}
url: /anything
method: GET
display_headers: true
headers:
  - "apikey: $KEY_SECRET"
status_code: 200
{% endvalidation %}

Check the `RateLimit-Limit` response header:

```
RateLimit-Limit: 20
```
{:.no-copy-code}

The limit is now `20` from `expressions.limit` instead of the static fallback value of `10` from `principal.metadata.rate_limit`. 

To see the static fallback take over, remove the Principal's `rate_limit` metadata:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals/$PRINCIPAL_ID
status_code: 200
method: PUT
body:
  display_name: "example-principal"
  description: "Example principal"
  metadata:
    partner_id: acme-rockets
{% endkonnect_api_request %}
<!--vale on-->

{:.warning}
> {{site.base_gateway}} caches a successfully authenticated Principal for the directory's configured `ttl_secs` (5 minutes at minimum, 10 minutes by default). Wait at least 5 minutes after the previous request before continuing, or the next request will still show the cached Principal's old metadata.

After the `ttl` has elapsed (5-10 minutes), send another request:
{% validation request-check %}
url: /anything
method: GET
display_headers: true
headers:
  - "apikey: $KEY_SECRET"
status_code: 200
{% endvalidation %}

With `rate_limit` no longer present on the Principal, `expressions.limit` fails to evaluate, and {{site.base_gateway}} falls back to the static `config.limit` value of `10`:

```
RateLimit-Limit: 10
```
{:.no-copy-code}


