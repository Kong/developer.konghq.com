---
title: "Get started with {{site.surfaces_cli}}"
description: "TODO: One sentence that says what the reader can do after this guide."
content_type: how_to
permalink: /surfaces-cli/get-started/
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
  - get-started

tldr:
  q: "How do I get started with {{site.surfaces_cli}}?"
  a: |
    TODO: Two or three sentences that summarize the steps in this guide.

automated_tests: false

prereqs:
  inline:
    - title: "{{site.surfaces_cli}} authentication"
      content: |
        <!-- TODO: If the automatic prereqs set every credential that the CLI needs, delete this prereq. -->
        1. TODO: Tell the reader how to get the credential.
        1. Export the credential to an environment variable:
           ```bash
           export TODO_VARIABLE='YOUR_VALUE'
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

next_steps:
  - text: "{{site.surfaces_cli}} CLI reference"
    url: /index/surfaces-cli/#cli-references
---

<!-- TEMPLATE: The get-started guide shows the shortest path from install to one
working result. Each step is an H2 that starts with a verb. Keep one action per
step. The prerequisites box is built from the frontmatter, so do not repeat
install or Konnect setup steps here. -->

## Authenticate {{site.surfaces_cli}}

TODO: Tell the reader how to connect the CLI to {{site.konnect_short_name}}.

```sh
surfaces-cli TODO
```

## Run your first command

TODO: Tell the reader which command to run and what it does.

```sh
surfaces-cli TODO
```

## Validate

TODO: Tell the reader how to confirm that the previous step worked.

{% validation custom-command %}
command: surfaces-cli TODO
expected:
  return_code: 0
render_output: false
{% endvalidation %}

TODO: Show or describe the output that shows success.
