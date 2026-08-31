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

icon: harness.svg

search_aliases:
  - traceable ai
  - traceableai

tags:
  - tracing

related_resources:
  - text: Harness AI Firewall plugin
    url: /plugins/harness-ai-firewall/
  - text: Premium partners
    url: /premium-partners/
---

The Harness Web Application & API Protection (WAAP) by Traceable plugin lets Harness WAAP capture a copy of API request and response traffic flowing through {{site.base_gateway}}. The plugin then forwards the data to a locally running [Traceable module extension (TME)](https://docs.traceable.ai/docs/kong).

Using this data, {{page.name}} is able to create a security posture profile of APIs hosted on {{site.base_gateway}}.
Based on its findings, the {{page.name}} plugin can also block traffic coming from malicious actors and IPs into {{site.base_gateway}}.

If your deployment routes traffic to AI-powered services, you can also attach the [Harness AI Firewall](/plugins/harness-ai-firewall/) plugin to the same Route or Service.
Harness AI Firewall shares this plugin's configuration to detect, redact, or block sensitive data in AI request and response traffic.

## Install the {{page.name}} plugin

### Prerequisites

The {{page.name}} plugin requires a [Traceable Platform Agent (TPA)](https://docs.traceable.ai/docs/tpa) to be deployed in your environment.
For complete agent deployment instructions, visit the [Traceable by Harness docs site](https://docs.traceable.ai/docs/tpa).

### Install

Once you have deployed a Traceable Platform Agent, you are ready to install the plugin.

{% navtabs 'install' %}
{% navtab "Self-managed" %}

1. Install the {{page.name}} plugin using the LuaRocks package manager:

   ```sh
   luarocks install kong-plugin-traceable
   ```

1. Update your loaded plugins list in {{site.base_gateway}}.

   In your [`kong.conf`](/gateway/configuration/), append `traceable` to the `plugins` field. Make sure the field isn't commented out.

   ```yaml
   plugins = bundled,traceable
   ```

1. Restart {{site.base_gateway}}:

   ```sh
   kong restart
   ```

{% endnavtab %}
{% navtab "Helm" %}

These steps apply to the Kong Kubernetes Ingress Controller.

1. Download and unpack the LuaRock:

   ```bash
   curl -fLO https://luarocks.org/manifests/traceableai/kong-plugin-traceable-2.3.0-1.src.rock
   ```

   ```bash
   luarocks unpack kong-plugin-traceable-2.3.0-1.src.rock
   ```

1. Create a configmap from the unpacked plugin files:

   ```bash
   kubectl create configmap -n kong kong-plugin-traceable --from-file ./kong-plugin-traceable-2.3.0-1/kong-plugin-traceable-2.3.0/kong/plugins/traceable/
   ```

1. In your Kong Helm values file, add the plugin name to the existing `env` key, and reference the configmap:

   ```yaml
   # This should be under the env key and should already exist.
   # If you have other third-party plugins, keep them in the list.
   plugins: bundled,traceable
   # Add this section at the very bottom of the file.
   plugins:
     configMaps:
     - name: kong-plugin-traceable
       pluginName: traceable
   ```

1. Upgrade the deployment with the updated values file:

   ```bash
   helm upgrade quickstart kong/kong --namespace kong --values kong-values.yaml
   ```

{% endnavtab %}
{% endnavtabs %}

If you also plan to use the [Harness AI Firewall](/plugins/harness-ai-firewall/) plugin, see its [Helm installation steps](/plugins/harness-ai-firewall/#install-the-harness-ai-firewall-plugin) for both plugins' configmaps in a single pass.
