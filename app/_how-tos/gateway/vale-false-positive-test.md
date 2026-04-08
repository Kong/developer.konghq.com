---
# Bug 1: `title` is not in Keys.txt, so it survives into pass 2.
# Kongterms.yml will demand {{site.base_gateway}} instead of "Kong Gateway".
title: "Configure Kong Gateway for Rate Limiting"

permalink: /how-to/vale-false-positive-test/
content_type: how_to

# Bug 1: `description` is also not in Keys.txt.
# Same Kongterms false positive as title.
#
# Bug 3: index.js strips Dictionary.txt words via raw replaceAll() — a substring match.
# `cohere` is in Dictionary.txt. `coherent` contains `cohere` as a substring.
# After stripping: "coherent" → "nt". Vale then flags "nt" as a misspelling.
description: "Learn how to configure Kong Gateway to rate limit consumers with a coherent policy using the Admin API."

products:
  - gateway

works_on:
  - on-prem
  - konnect

tools:
  - deck

# Bug 2: `tldr` IS in Keys.txt, so the `tldr:` line is stripped.
# But the `q:` and `a:` children are indented sub-keys — the single-line
# regex `^\\s*tldr:.*$` does not remove them. They survive as orphaned text
# and Kongterms fires on "Kong Gateway" in the question.
tldr:
  q: How do I configure Kong Gateway for rate limiting?
  a: Enable the Rate Limiting plugin on a Service or Route in Kong Gateway.

# Bug 2: `related_resources` IS in Keys.txt, so `related_resources:` is stripped.
# The `- text:` and `url:` children are indented and are NOT removed by the regex.
# "Kong Gateway" in the text value triggers Kongterms in pass 2.
related_resources:
  - text: "Rate limiting in Kong Gateway"
    url: /gateway/rate-limiting/
  - text: "Kong Ingress Controller configuration"
    url: /kic/rate-limiting/

# Bug 2: `prereqs` IS in Keys.txt. The `inline:` and its children survive.
# The `title:` child value "Set up a Kong Gateway service" contains "Kong Gateway"
# and will trigger Kongterms.
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

## Validate

Send a request to confirm the rate limit is active:

{% validation rate-limit-check %}
iterations: 6
url: '/anything'
{% endvalidation %}
