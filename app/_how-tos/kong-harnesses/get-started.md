---
title: "Get started with {{site.kong_harnesses}}"
description: "TODO: One sentence that says what the reader can do after this guide."
content_type: how_to
permalink: /kong-harnesses/get-started/
breadcrumbs:
  - /kong-harnesses/

products:
  - ai-gateway

works_on:
  - konnect

tags:
  - ai
  - cli

tldr:
  q: "How do I get started with {{site.kong_harnesses}}?"
  a: |
    TODO: Two or three sentences that summarize the steps in this guide.

automated_tests: false

prereqs:
  skip_product: true
---

<!-- TEMPLATE: Copy this file for each new how-to. Each step is an H2 that
starts with a verb. End with a Validate step. -->

## TODO: First step

TODO: Tell the reader what this step does.

```sh
kong-harnesses TODO
```

## Validate

TODO: Tell the reader how to make sure that the previous step worked.

{% validation custom-command %}
command: kong-harnesses TODO
expected:
  return_code: 0
render_output: false
{% endvalidation %}
