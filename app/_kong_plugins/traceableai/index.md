---
title: 'Traceable.ai'
name: 'Traceable.ai'

content_type: plugin
tier: enterprise
publisher: traceable-ai
description: 'API security with inline request blocking and data capture'


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.4'

# on_prem:
#   - hybrid
#   - db-less
#   - traditional
# konnect_deployments:
#   - hybrid
#   - cloud-gateways
#   - serverless

third_party: true
premium_partner: true

support_url: https://support.traceable.ai

icon: traceableai.svg

search_aliases:
  - traceable ai
  - traceableai

tags:
  - tracing
---

Traceable's Kong plugin lets Traceable capture a copy of the API traffic, both request and response data, that is flowing through {{site.base_gateway}}. The plugin then forwards the data to a locally running [Traceable module extension (TME)](https://docs.traceable.ai/docs/kong).

Using this data, Traceable is able to create a security posture profile of APIs hosted on {{site.base_gateway}}.
Based on its findings, the Traceable plugin can also block traffic coming from malicious actors and IPs into {{site.base_gateway}}.

## Install the Traceable plugin

### Prerequisites

The Traceable Kong Plugin requires a Traceable Platform Agent to be deployed in your environment.
For complete deployment instructions of the Traceable Platform Agent, visit the [traceable.ai docs site](https://docs.traceable.ai/docs/k8s).

### Install

Once you have deployed a Traceable Platform Agent, you are ready to install the plugin using the LuaRocks package manager:

1. Install the Traceable plugin:

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
