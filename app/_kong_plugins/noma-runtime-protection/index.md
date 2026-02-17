---
title: 'Noma Runtime Protection'
name: 'Noma Runtime Protection'

content_type: plugin

publisher: noma
description: "AI-DR runtime protection for all OpenAI-compliant modules through your {{site.ai_gateway_name}}"

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

third_party: true

support_url: https://noma.security

icon: noma-runtime-protection.svg

search_aliases:
  - noma-runtime-protection
  - noma security
  - noma ai runtime protection
  - ai-dr
  - ai detection and response

---

[Noma](https://noma.security)'s {{site.ai_gateway_name}} plugin offers full AI detection & response (AI-DR) runtime protection to all OpenAI-compliant modules through your {{site.ai_gateway_name}}.
It allows you to leverage Noma’s AI-DR service to classify, flag, and block a wide range of security risks in real-time.

Integrating the Noma plugin into your {{site.ai_gateway}} allows you to:
* **Centralize security oversight**: Automatically stream AI traffic data to the Noma Security Console for comprehensive audit trails and behavioral analysis.
* **Enforce policy in real time**: Use Noma’s AI-DR to evaluate every interaction, enabling you to redact PCI, PII, mask sensitive data, and block non-compliant requests instantly (optional).

The Noma plugin provides a high-performance, low-footprint solution for AI security. 
By processing traffic after SSL termination, it enables Noma to inspect prompts and responses in real time and apply critical security guardrails across your AI workflows.

## Install the Noma Runtime Protection plugin

The Noma Runtime Protection plugin is available as a LuaRocks module or as a set of Lua source files.

### Prerequisites

Before enabling the plugin, you need to obtain assets from Noma and set up {{site.ai_gateway}}.

Noma assets:
* Obtain the Noma plugin `.rock` file or set of Lua files from your Noma Technical Account Manager.
* Contact your Noma TAM for the client ID and client secret.

## Installation steps

{% navtabs 'deployment' %}
{% navtab "Konnect" %}

{{site.konnect_short_name}} requires the custom plugin’s `schema.lua` file to create a plugin entry in the plugin catalog for your control plane.
Upload the `schema.lua` file from the downloaded zip file to create a configurable entity in {{site.konnect_short_name}}:

1. In the {{site.konnect_short_name}} menu, click **API Gateway**.
1. Click a control plane.
1. From the control plane's menu, click **Plugins**.
1. Click **New Plugin**.
1. Click **Custom Plugin**.
1. Upload the `schema.lua` file for your plugin.
1. Check that your file displays correctly in the preview, then click **Save**.
1. After uploading a schema to {{site.konnect_short_name}}, upload the `schema.lua` and `handler.lua` files from the downloaded zip archive to each {{site.base_gateway}} data plane node. 
   If a data plane node doesn’t have these files, the plugin won’t be able to run on that node.
1. Follow the Dockerfile installation instructions on this page (switch tabs) to get your plugin set up on each node. 

You can now configure this custom plugin like any other plugin in {{site.konnect_short_name}}.

{% endnavtab %}
{% navtab "Docker" %}

If you are using Docker, see the following example Dockerfile for installing the Noma Runtime Protection plugin. 
Make sure to adjust the filenames and {{site.base_gateway}} image tag for your own installation:

```docker
FROM kong/kong-gateway:latest

USER root

RUN \apt-get update && \apt-get install unzip -y

WORKDIR /usr/kong/noma

RUN apt update && apt-get install -y build-essential git curl unzip

RUN bash -c 'mkdir -pv {noma-runtime-protection}'

COPY ./noma-runtime-protection.zip noma-runtime-protection/noma-runtime-protection.zip

RUN unzip noma-runtime-protection/noma-runtime-protection.zip -d noma-runtime-protection && rm noma-runtime-protection/noma-runtime-protection.zip

RUN cd noma-runtime-protection && luarocks make

USER kong
```
{% endnavtab %}
{% navtab "kong.conf" %}

If you obtained the plugin `.rock` file from your Noma Technical Account Manager, you can install the plugin directly via Luarocks and load it into {{site.base_gateway}} using the Kong configuration file.

1. Install the Noma Runtime Protection plugin:

   ```sh
   luarocks install kong-plugin-noma-runtime-protection-0.1.0-1.all.rock
   ```

1. Update your loaded plugins list in {{site.base_gateway}}.

   In your [`kong.conf`](/gateway/configuration/), append `noma-runtime-protection` to the `plugins` field. 
   Make sure the field isn't commented out.

   ```yaml
   plugins = bundled,noma-runtime-protection
   ```

1. Restart {{site.base_gateway}}:

   ```sh
   kong restart
   ```

{% endnavtab %}
{% endnavtabs %}

Next, set up {{site.ai_gateway}} and enable the plugin.

## Enabling the plugin

After installing the plugin, you will need the following {{site.base_gateway}} entity configuration:
1. [Set up {{site.ai_gateway}}](/ai-gateway/get-started/) by creating a Service, a Route, and enabling the AI Proxy plugin.
1. [Create a Consumer and an auth key](/how-to/enable-key-authentication-on-a-service-with-kong-gateway/) to identify the application/client calling the API.
1. [Group Consumers](/gateway/entities/consumer-group/) (Optional): If you want to set up shared runtime policies, group your Consumers into Consumer Groups.
1. [Enable the Noma AI Runtime Security plugin](/plugins/noma-runtime-protection/examples/enable-noma-runtime-protection/).

## Monitoring vs blocking mode

The plugin can run in one of the following modes, configured using the [`config.monitor_mode`](./reference/#schema--monitor-mode) parameter:
* `monitor`: AI-DR runs asynchronously. Monitors and logs requests, but doesn't block them. Has no impact on request latency.
* `blocking`: AI-DR runs synchronously. Requests/responses may be rejected based on the verdict.

## Troubleshooting

If the Noma plugin isn't behaving as expected, use the following sections to identify and resolve common issues.

Look for `[noma-runtime-protection]` prefixes to identify specific Lua errors or HTTP handshake failures.

### Synchronization and "Plugin Not Found" errors

**Symptoms:** You see the Noma plugin in {{site.konnect_short_name}}, but requests fail
with a `500 Internal Server Error`, or the data plane logs show `plugin 'noma-runtime-protection' not found`.

**Possible solutions**:
* **Hybrid sync check**: Ensure the `.rock` file was installed on every data plane node.
If you have a cluster of 5 nodes, all 5 must have the plugin code.
* **Environment variable check**: If you are using Docker or Kubernetes, ensure
`KONG_PLUGINS` environment variable includes `noma-runtime-protection`. For example:

    ```
    PLUGINS=bundled,noma-runtime-protection
    ```
* **Lua Path**: Verify the plugin is in {{site.base_gateway}}'s search path by running:

    ```sh
    luarocks list | grep noma
    ```

### Connectivity issues

**Symptoms:** Requests are delayed, or Noma's console isn't showing any new inferences.

**Possible solutions:**
* **Egress rules**: Ensure your {{site.base_gateway}} nodes have outbound HTTPS access (port 443) to `api.noma.security`.
* **Credential validation**: Double-check your client ID and client secret. If these are incorrect, the plugin will fail to authenticate with the Noma API.
* **Timeout settings**: If you are using blocking mode (synchronous), ensure your [`proxy_timeout`](/gateway/configuration/#proxy-timeout) settings in `kong.conf` aren't too aggressive, as the plugin
must wait for a verdict from Noma.

### Entity mapping (Noma application ID)

**Symptoms**: Traffic is appearing in the Noma Console, but it's all grouped under a
generic name.

**Possible solutions**:
* **Consumer identification:** By default, Noma uses the {{site.base_gateway}} application ID. 
If you haven't assigned a Consumer to the request (for example, you applied the plugin
globally without auth), you'll get a generic `'kong'` application ID.

* **Explicit ID:** If you want specific grouping, manually enter a unique string in the
`Application ID` field within the Noma plugin configuration in {{site.base_gateway}}.

### Policy is not blocking (monitor mode)

**Symptoms**: Malicious prompts are being flagged in the Noma Console but are not being blocked at the Gateway.

**Possible solutions**:
* **Mode check**: Verify that [`config.monitor_mode`](./reference/#schema--monitor-mode) is off (`false`).
    * Monitor mode ON: asynchronous (log only).
    * Monitor mode OFF: synchronous (enforce/block).

