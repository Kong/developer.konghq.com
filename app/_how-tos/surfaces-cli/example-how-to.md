---
title: "TODO: Task title that starts with a verb, for example Create an AI Model with {{site.surfaces_cli}}"
description: "TODO: One sentence that says what the reader can do after this guide."
content_type: how_to
# TODO: Use a permalink that describes the task, for example /surfaces-cli/create-an-ai-model/.
permalink: /surfaces-cli/example-how-to/
breadcrumbs:
  - /surfaces-cli/

# products + works_on add the Konnect token and "AI Gateway running" prereqs.
# tools adds the "Install Surfaces CLI" prereq from app/_includes/prereqs/tools/surfaces-cli.md.
products:
  - ai-gateway

works_on:
  - konnect

tools:
  - surfaces-cli

# TODO: Add the lowest AI Gateway version this guide works with, for example:
# min_version:
#   ai-gateway: '2.0'

tags:
  - ai
  - cli

tldr:
  q: "TODO: The question this guide answers, for example How do I create an AI Model with {{site.surfaces_cli}}?"
  a: |
    TODO: Two or three sentences that answer the question. Name the commands the reader runs.

automated_tests: false

prereqs:
  inline:
    - title: "TODO: Third-party prerequisite, for example an LLM provider API key"
      content: |
        <!-- TODO: Add one inline prereq for each external account, key, or file the guide needs. If the guide needs none, delete this prereq. -->
        1. TODO: Tell the reader how to get the key.
        1. Export the key to an environment variable:
           ```bash
           export TODO_API_KEY='YOUR_API_KEY'
           ```
      icon_url: /assets/icons/code.svg

cleanup:
  inline:
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway
      icon_url: /assets/icons/gateway.svg

related_resources:
  - text: "{{site.surfaces_cli}} CLI reference"
    url: /index/surfaces-cli/#cli-references
  - text: AI Management
    url: /ai-management/
  # TODO: Link the AI Gateway entities this guide creates, for example /ai-gateway/entities/ai-model/.
---

<!-- TEMPLATE: Copy this file for each new how-to. Name the file after the
permalink slug. Each step is an H2 that starts with a verb. Keep one action per
step. The prerequisites box is built from the frontmatter, so do not repeat
install or Konnect setup steps here. Always end with a Validate step. -->

## TODO: First step, for example Create an AI Model Provider

TODO: One or two sentences that say what this step does and why. Link the entity the first time you name it.

```sh
surfaces-cli TODO
```

## TODO: Second step

TODO: One or two sentences that say what this step does.

```sh
surfaces-cli TODO
```

## Validate

<!-- TEMPLATE: Use custom-command to test CLI output. To send traffic through
AI Gateway instead, use {% raw %}{% validation request-check %}{% endraw %}, as in
app/_how-tos/ai-gateway/route-openai-traffic-to-bedrock-mantle.md. -->

TODO: Tell the reader what this test proves.

{% validation custom-command %}
command: surfaces-cli TODO
expected:
  return_code: 0
render_output: false
{% endvalidation %}

TODO: Show or describe the output that shows success.
