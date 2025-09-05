---
title: 'Kong Spec Expose'
name: 'Kong Spec Expose'

content_type: plugin

publisher: optum
description: "Expose OAS/Swagger/etc. specifications of auth protected APIs proxied by Kong"

products:
    - gateway

works_on:
    - on-prem

third_party: true

support_url: https://github.com/Optum/kong-spec-expose/issues

source_code_url: https://github.com/Optum/kong-spec-expose/

license_type: Apache-2.0

icon: optum.png

search_aliases:
    - optum

min_version:
  gateway: '1.0'
---

The Kong Spec Expose plugin lets you expose an OpenAPI Spec (OAS), Swagger, or other specification of auth-protected upstream services fronted using {{site.base_gateway}}.

## How it works

API providers need a means of exposing the specifications of their services while maintaining authentication on the service itself.
The Kong Spec Expose plugin solves this problem by doing the following:

1. The plugin enables a Kong Admin to specify the endpoint of their API specification.
2. The plugin validates that the proxy request is a `GET` method, and will validate the proxy request ends with `/specz`. If these two requirements are met, the endpoint returns the specification of the upstream service with Content-Type header identical to what the upstream service exposes.

## Install the Kong Spec Expose plugin

{% include_cached /plugins/install-third-party.md name=page.name slug=page.slug rock="kong-spec-expose" %}