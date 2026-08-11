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
examples**. They check different things and run differently. They also don't have the same coverage, which is
worth slowing down for. Both matter for the same reason: a docs platform that can silently publish something
wrong is worse than no platform at all.

## System 1: how-to steps, tested against a real gateway

*`{% raw %}{% validation %}{% endraw %}`, present on 202 of 468 how-to guides (43%).*

[Part 1 of this tour](/how-to/platform-tour/) already showed the mechanism up close: a
`{% raw %}{% validation %}{% endraw %}` block renders a visible step and a hidden `data-test-step` JSON payload
at the same time. That page didn't have room for what actually consumes that payload, end to end.

**The two-stage pipeline** (`tools/automated-tests/`):

1. **Extraction** (`instructions/extractor.js`): opens the *live rendered page* in a real Playwright browser,
   not the source Markdown, and collects every `[data-test-step]` / `[data-test-setup]` element, in document
   order, filtered by `data-deployment-topology` so a Konnect run skips on-prem-only steps and vice versa.
2. **Execution** (`run.js` + `docker/`): runs the extracted steps for real, inside Docker, against a real,
   version-pinned Kong Gateway. `config/runtimes.yaml` defines exactly which Gateway versions get tested, per
   deployment model (`on-prem`, `konnect`) and per product (`gateway`, `ai-gateway`, `kic`, `operator`,
   `event-gateway`).

**Where this system's coverage stops:** it only exists for pages carrying
`{% raw %}{% validation %}{% endraw %}` blocks, 43%, not 100%. It also tests the *instructions*, not the
*product*. If a how-to's curl command is correct but the concept explanation is wrong, this pipeline has
nothing to say about that. And it runs on a daily schedule (`automated-tests.yaml`), not on every pull request.
See [part 5](/reference/platform-tour-pipeline/) for the full list of what does and doesn't gate a PR.

{% konnect %}
content: |
  ```sh
  KONNECT_TOKEN=$KONNECT_TOKEN DEPLOYMENT_MODEL='konnect' PRODUCTS='gateway' npm run run-tests
  ```
{% endkonnect %}

{% on_prem %}
content: |
  ```sh
  GATEWAY_VERSION='3.9' DEPLOYMENT_MODEL='on-prem' PRODUCTS='gateway' npm run run-tests
  ```
{% endon_prem %}

## System 2: plugin config examples, checked against real schemas

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

**Where this system's coverage stops:** this is a real, specific gap, not a hypothetical one. 24 of the
plugins with example files get skipped outright, including this tour's own
[demo plugin](/plugins/platform-tour-demo/). The validator only has schemas for Kong's first-party plugins
(`app/_schemas/gateway/plugins/`, synced from the real Gateway source). Third-party plugins, including Moesif,
Kong Upstream JWT, 22 others, and this demo plugin, ship their own local `schema.json`, and this tool never
reads it. Their examples render correctly, but nothing currently checks their `config:` block against anything.
See [Platform Tour: the demo plugin](/plugins/platform-tour-demo/) for exactly where that boundary sits in the
code.

## The honest comparison

| | How-to steps | Plugin config examples |
|---|---|---|
| Checks | Does the instruction work, against a real gateway | Does the config match the real schema |
| Runs against | A live, running Kong Gateway | A static JSON Schema, no gateway needed |
| Coverage | 202 of 468 how-tos (43%) | 476 of 500 example files (95.2%, 24 skipped) |
| Blind spot | 57% of how-tos have no automated check at all | First-party only: third-party plugin configs are never checked |

Neither system covers everything, and neither claims to. That's worth knowing before you trust a number on
this platform, or repeat one to someone else. Consistent and verified aren't the same guarantee. 43% and 95.2%
mark where that guarantee currently ends, not a finish line. It grows every time someone adds a
`{% raw %}{% validation %}{% endraw %}` block or a first-party plugin schema. That's also the next thing a
docs writer would actually do.

That's how much of the *content* gets verified. [Part 5](/reference/platform-tour-pipeline/) follows the same
commit the rest of the way: into a real PR preview, past a set of automated checks, and out onto a real CDN.
