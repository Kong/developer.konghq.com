---
title: "Platform Tour: Testing"
permalink: /how-to/platform-tour-testing/
content_type: how_to
description: "How this platform tests its own docs and its own plugin examples before either one ships."
products:
  - gateway
  - ai-gateway
works_on:
  - on-prem
  - konnect
tools:
  - deck
tags:
  - ai
  - konnect
tldr:
  q: What does this page demonstrate?
  a: Two separate real testing systems on this platform. One runs how-to steps against a live gateway. One checks plugin config examples against real schemas. This page shows where each one's coverage actually stops.
related_resources:
  - text: "Platform Tour: the hub"
    url: /internal/platform-tour-landing/
  - text: "Platform Tour: the how-to page"
    url: /how-to/platform-tour/
  - text: "Platform Tour: the reference page"
    url: /reference/platform-tour-reference/
  - text: "Platform Tour: the demo plugin"
    url: /plugins/platform-tour-demo/
  - text: "Platform Tour: Shipping"
    url: /reference/platform-tour-pipeline/
prereqs:
  entities:
    services:
      - example-service
seo_noindex: true
---

{% include platform-tour/orientation.md part=4 %}

This platform has two separate, real testing systems: one for **how-to instructions**, one for **plugin config
examples**. They check different things and run differently.

## System 1: how-to steps, tested against kong gateway


**The two-stage pipeline** (`tools/automated-tests/`):

1. **Extraction** (`instructions/extractor.js`): opens the *live rendered page* in a real Playwright browser,
   not the source Markdown, and collects every `[data-test-step]` / `[data-test-setup]` element, in document
   order, filtered by `data-deployment-topology` so a Konnect run skips on-prem-only steps and vice versa.
2. **Execution** (`run.js` + `docker/`): runs the extracted steps for real, inside Docker, against a real,
   version-pinned Kong Gateway. `config/runtimes.yaml` defines exactly which Gateway versions get tested, per
   deployment model (`on-prem`, `konnect`) and per product (`gateway`, `ai-gateway`, `kic`, `operator`,
   `event-gateway`.



## System 2: plugin config examples, checked against schemas

*`tools/plugin-examples-validator`: checking `config:` blocks against `app/_schemas/gateway/plugins/` using
Ajv, a JSON Schema validation library.*

Every plugin ships one or more `examples/*.yaml` files with a `config:` block. This validator compiles each
plugin's real JSON Schema and checks the example's config against it. A wrong field name, a wrong type, or a
value outside an `enum` fails the build with the exact field and reason.

**Real output, from running it against this whole repo:**

```
$ node tools/plugin-examples-validator/index.js
Using schema version: 3.15
Found 500 example files

Skipped: 24
Errors: 0

All plugin examples are valid.
```
