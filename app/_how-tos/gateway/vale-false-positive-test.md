---
# Bug 1 + Kongterms: `title` is not in Keys.txt, survives into pass 2.
# Kongterms fires because "Kong Gateway" should be {{site.base_gateway}}.
# But Liquid variables don't interpolate in YAML frontmatter.
title: "Configure Kong Gateway for Rate Limiting"

permalink: /how-to/vale-false-positive-test/
content_type: how_to

# Bug 1 + Kongterms + Terms: `description` is also not in Keys.txt.
# - Kongterms fires on "Kong Gateway"
# - Terms fires on "utilize" (should be "use") and "timezone" (should be "time zone")
# - Bug 3 (replaceAll): `cohere` in Dictionary.txt is a substring of `coherent`.
#   After replaceAll('cohere', ''): "coherent" → "nt". Spelling fires on "nt".
description: "Learn how to utilize Kong Gateway to enforce coherent rate limiting across all timezone regions."

products:
  - gateway

works_on:
  - on-prem
  - konnect

tools:
  - deck

# Bug 2 + Kongterms + Relativeurls: `tldr` IS in Keys.txt, so `tldr:` is stripped.
# The `q:` and `a:` children survive as orphaned text.
# - Kongterms fires on "Kong Gateway" in q:
# - Relativeurls fires on the absolute developer.konghq.com URL in a:
#   (scope: raw means it checks everything, including orphaned frontmatter children)
tldr:
  q: How do I configure Kong Gateway for rate limiting?
  a: Enable the Rate Limiting plugin as described in [the docs](https://developer.konghq.com/gateway/rate-limiting/).

# Bug 2 + Kongterms: `related_resources` IS in Keys.txt, so `related_resources:` is stripped.
# `- text:` and `url:` children survive. "Kong Gateway" and "Kong Ingress Controller"
# in text values trigger Kongterms.
related_resources:
  - text: "Rate limiting in Kong Gateway"
    url: /gateway/rate-limiting/
  - text: "Kong Ingress Controller configuration"
    url: /kic/rate-limiting/

# Bug 2 + Kongterms: `prereqs` IS in Keys.txt. The `inline:` children survive.
# The `title:` child "Set up a Kong Gateway service" triggers Kongterms.
prereqs:
  inline:
    - title: Set up a Kong Gateway service
      include_content: prereqs/gateway/service
---

## Enable rate limiting

Enable the [Rate Limiting plugin](/plugins/rate-limiting/) on your Service.

{% entity_examples %}
entities:
  plugins:
    - name: rate-limiting
      config:
        minute: 5
        hour: 1000
{% endentity_examples %}

## Architecture

<!-- Bug 4: {% mermaid %} is not in BlockIgnores. Vale lints node labels as prose.
     "Kong Gateway" in the node label fires base.Kongterms. -->
The following diagram shows how {{site.base_gateway}} handles traffic.

{% mermaid %}
flowchart LR
  A(Client)
  B(Kong Gateway)
  C(Upstream service)
  A --request--> B --> C
{% endmermaid %}

## Configuration options

<!-- Bug 4: {% table %} is not in BlockIgnores. Vale lints all YAML inside the block
     as prose. "Kong Gateway" in the description row fires base.Kongterms. -->
The following table describes the available options.

{% table %}
columns:
  - title: Option
    key: option
  - title: Description
    key: description
rows:
  - option: "`minute`"
    description: "Maximum requests per minute Kong Gateway allows through to the upstream."
  - option: "`hour`"
    description: "Maximum requests per hour before Kong Gateway returns a 429."
{% endtable %}

## Create a control plane

<!-- Bug 4: {% konnect_api_request %} is not in BlockIgnores. Vale lints the YAML
     body as prose. "Kong Gateway" in the description field fires base.Kongterms. -->
Issue a request to create a new control plane.

{% konnect_api_request %}
url: /v2/control-planes/
method: POST
status_code: 201
body:
  name: my-control-plane
  description: A Kong Gateway control plane for rate limiting.
{% endkonnect_api_request %}

## Validate

Send a request to confirm the rate limit is active:

{% validation rate-limit-check %}
iterations: 6
url: '/anything'
{% endvalidation %}
