---
title: 'Harness WAAP'
name: 'Harness WAAP'

content_type: plugin
tier: enterprise
publisher: harness
description: 'Capture full API/AI traffic in {{site.base_gateway}}, assess security posture, and block attacks with inline enforcement'


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.4'

third_party: true
premium_partner: true

support_url: https://www.harness.io/support

icon: traceableai.svg

search_aliases:
  - traceable ai
  - traceableai

tags:
  - tracing
---

The Harness Web Application & API Protection (WAAP) by Traceable plugin lets Harness WAAP capture a copy of the API traffic, both request and response data, that is flowing through {{site.base_gateway}}. The plugin then forwards the data to a locally running [Traceable module extension (TME)](https://docs.traceable.ai/docs/kong).


Using this data, {{page.name}} is able to create a security posture profile of APIs hosted on {{site.base_gateway}}.
Based on its findings, the {{page.name}} plugin can also block traffic coming from malicious actors and IPs into {{site.base_gateway}}.

## Install the {{page.name}} plugin

### Prerequisites

The {{page.name}} plugin requires a [Traceable Platform Agent (TPA)](https://docs.traceable.ai/docs/tpa) to be deployed in your environment.
For complete agent deployment instructions, visit the [Harness docs site](https://docs.traceable.ai/docs/k8s).

### Install

Once you have deployed a Traceable Platform Agent, you are ready to install the plugin using the LuaRocks package manager:

1. Install the {{page.name}} plugin:

   ```sh
   luarocks install kong-plugin-traceable
   ```

2. Update your loaded plugins list in {{site.base_gateway}}.

   In your [`kong.conf`](/gateway/configuration/), append `traceable` to the `plugins` field. Make sure the field isn't commented out.

   ```yaml
   plugins = bundled,traceable
   ```

3. Restart {{site.base_gateway}}:

   ```sh
   kong restart
   ```
