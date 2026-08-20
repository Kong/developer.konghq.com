---
title: "Platform Tour: Reference Pages"
permalink: /reference/platform-tour-reference/
content_type: reference
layout: gateway_entity
description: "A real reference page demonstrating a mermaid diagram, an auto-generated entity schema table, and a real Run in Insomnia button."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tags:
  - konnect
schema:
  api: gateway/admin-ee
  path: /schemas/Service
api_specs:
  - gateway/admin-ee
  - konnect/control-planes-config
seo_noindex: true
related_resources:
  - text: "Platform Tour: the hub"
    url: /internal/platform-tour-landing/
  - text: "Platform Tour: the how-to page"
    url: /how-to/platform-tour/
  - text: "Platform Tour: the demo plugin"
    url: /plugins/platform-tour-demo/
  - text: "Platform Tour: Testing"
    url: /how-to/platform-tour-testing/
  - text: "Platform Tour: Shipping"
    url: /reference/platform-tour-pipeline/
  - text: Gateway Service entity reference
    url: /gateway/entities/service/
---

{% include platform-tour/orientation.md part=2 %}

This page exists to show what a reference page can do beyond prose and tables: a diagram rendered from plain
text, and a parameter table that isn't written by anyone. It's fetched live from the same product data Konnect
itself uses. Look for a real **Run in Insomnia** button, generated from the `api_specs:` in this page's own
frontmatter.

## One YAML block, several outputs, as a diagram

*Same mechanism as [part 1](/how-to/platform-tour/)'s `{% raw %}{% entity_example %}{% endraw %}` demo, redrawn here as `{% raw %}{% mermaid %}{% endraw %}` diagram instead of clickable tabs.*

**Writer types:**

{% raw %}
```liquid
{% mermaid %}
flowchart LR
    A[entity_example: service] --> B(decK)
    A --> C(Admin API)
    A --> D(Konnect API)
    A --> E(KIC, Kong Ingress Controller)
    A --> F(Terraform)
{% endmermaid %}
```
{% endraw %}

**Renders as (live):**

{% mermaid %}
flowchart LR
    A[entity_example: service] --> B(decK)
    A --> C(Admin API)
    A --> D(Konnect API)
    A --> E(KIC, Kong Ingress Controller)
    A --> F(Terraform)
{% endmermaid %}

## Schema

The parameter table that follows is fetched using the spec renderer and pulling the actual schema

This page's frontmatter includes:

{% raw %}
```yaml
schema:
  api: gateway/admin-ee
  path: /schemas/Service
```
{% endraw %}

This is the output: 

{% entity_schema %}

## Plugin docs, generated the same way

Every one of Kong's 134 plugins gets an overview, config reference, and changelog page generated from its schema: 134 of 134, 100%. 

- [Rate Limiting Advanced: overview](/plugins/rate-limiting-advanced/)
- [Rate Limiting Advanced: config reference](/plugins/rate-limiting-advanced/reference/)
- [Rate Limiting Advanced: changelog](/plugins/rate-limiting-advanced/changelog/)
- [Rate Limiting Advanced: a real example](/plugins/rate-limiting-advanced/examples/throttle-requests/)

## See the rest of the tour

- [1. The how-to page](/how-to/platform-tour/): entity_example tabs, the Konnect/on-prem switch, a validation block that doubles as an automated test.
- [3. The demo plugin](/plugins/platform-tour-demo/): a brand-new plugin, built from three files, plus a real gap in the config validator.
- [4. Testing](/how-to/platform-tour-testing/): two real testing systems, side by side, with their actual coverage.
- [5. Shipping](/reference/platform-tour-pipeline/): a real PR preview URL, automated Vale checks, and the CDN that serves production.
- [The tour hub](/internal/platform-tour-landing/): cards, tabs, a table, this same diagram's cousin, and content nobody typed by hand.
