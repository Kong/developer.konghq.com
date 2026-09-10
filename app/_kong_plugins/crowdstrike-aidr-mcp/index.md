---
title: 'CrowdStrike Falcon AIDR MCP'
name: 'CrowdStrike Falcon AIDR MCP'

content_type: plugin

publisher: crowdstrike
description: 'Inspect Model Context Protocol tool listings, tool call inputs, and tool outputs against CrowdStrike Falcon AIDR policies, blocking malicious or sensitive traffic before it reaches the client or MCP server'

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

third_party: true
source_code_url: 'https://github.com/crowdstrike/aidr-kong'
support_url: 'https://supportportal.crowdstrike.com'

icon: falcon.svg

tags:
  - security
  - ai

search_aliases:
  - crowdstrike-aidr-mcp
  - crowdstrike falcon
  - aidr
  - ai detection and response
  - mcp security
  - model context protocol security

min_version:
  gateway: '3.8'

related_resources:
  - text: CrowdStrike Falcon AIDR documentation
    url: https://pangea.cloud/docs/aidr
  - text: CrowdStrike Falcon AIDR Request plugin
    url: /plugins/crowdstrike-aidr-request/
  - text: CrowdStrike Falcon AIDR Response plugin
    url: /plugins/crowdstrike-aidr-response/
---

The {{page.name}} plugin inspects [Model Context Protocol](https://modelcontextprotocol.io/) (MCP) traffic flowing through {{site.base_gateway}} to an MCP server, evaluating tool listings, tool call inputs, and tool outputs against CrowdStrike's AIDR policies in real time.
Traffic that violates your security policies is blocked at the gateway. No changes to the MCP client or server are required.

Integrating the {{page.name}} plugin into your {{site.base_gateway}} allows you to:
* **Detect malicious tool descriptions**: Inspect the tools an MCP server advertises for prompt injection payloads hidden in tool metadata.
* **Block malicious tool call inputs**: Evaluate tool call arguments against your AIDR policies before the tool executes.
* **Prevent sensitive data exfiltration**: Inspect tool call outputs for PII, credentials, and other sensitive content before it reaches the client.
* **Centralize AI security visibility**: Stream audit events to the CrowdStrike Falcon AIDR console and Next-Gen SIEM without modifying your application.

You can also use this plugin together with the [CrowdStrike Falcon AIDR Request](/plugins/crowdstrike-aidr-request/) and [CrowdStrike Falcon AIDR Response](/plugins/crowdstrike-aidr-response/) plugins to protect LLM chat traffic in addition to MCP tool traffic.

{:.warning}
> **Note**: This plugin is built for {{site.ai_gateway}} running on {{site.base_gateway}}. It has not been validated against {{site.ai_gateway}} 2.0.

## How it works

The {{page.name}} plugin inspects the following MCP JSON-RPC 2.0 event types as they pass through {{site.base_gateway}}:

* `tool_listing`: Inspects the list of tools an MCP server advertises in response to a `tools/list` request, detecting malicious tool descriptions such as prompt injection embedded in tool metadata.
* `tool_input`: Inspects tool call arguments in a `tools/call` request before the tool executes, blocking malicious inputs before they reach the MCP server.
* `tool_output`: Inspects the tool result an MCP server returns, blocking sensitive data exfiltration in tool output before it reaches the client.

`initialize`, `ping`, and other non-tool MCP methods pass through without inspection.

<!-- vale off-->
{% mermaid %}
sequenceDiagram
autonumber
    participant Client
    participant Plugin as {{site.base_gateway}}<br/>AIDR MCP plugin
    participant AIDR as CrowdStrike Falcon AIDR
    participant MCP as MCP Server

    Client->>Plugin: tools/list, tools/call request
    Plugin->>AIDR: Submit event against AIDR policies
    AIDR->>Plugin: Verdict

    alt If tool_input is flagged
        Plugin->>Client: Return JSON-RPC error
    else If request is allowed
        Plugin->>MCP: Forward request
        MCP->>Plugin: Return tool result or tool listing
        Plugin->>AIDR: Submit tool_listing or tool_output against AIDR policies
        AIDR->>Plugin: Verdict
        alt If tool_listing or tool_output is flagged
            Plugin->>Client: Return JSON-RPC error
        else If response is allowed
            Plugin->>Client: Return tool result or tool listing
        end
    end
{% endmermaid %}
<!-- vale on-->

_**Figure 1**: Request and response flow showing how the {{page.name}} plugin evaluates MCP tool listings, tool call inputs, and tool outputs against CrowdStrike Falcon AIDR policies. Flagged events are blocked with a JSON-RPC error, while allowed traffic is forwarded or returned._

{:.warning}
> MCP JSON-RPC 2.0 only uses `POST` requests.
When applied to a Route, restrict the Route to so it accepts `POST` methods only.

### Using {{page.name}} with the AI MCP Proxy plugin

The [AI MCP Proxy](/plugins/ai-mcp-proxy/) plugin and the {{page.name}} plugin can be used together on the same Service.
The {{page.name}} plugin runs at priority 950, before AI MCP Proxy's priority 820, so `tool_input` inspection always fires first.

AI MCP Proxy operates in four modes, and the mode determines which AIDR inspection events fire:

{% table %}
columns:
  - title: Mode
    key: mode
  - title: tool_input
    key: tool_input
  - title: tool_listing
    key: tool_listing
  - title: tool_output
    key: tool_output
  - title: Notes
    key: notes
rows:
  - mode: "`passthrough-listener`"
    tool_input: "Yes"
    tool_listing: "Yes"
    tool_output: "Yes"
    notes: "Proxies to an upstream MCP server through {{site.base_gateway}}'s normal proxy pipeline. All three events are inspected."
  - mode: "`conversion-listener`"
    tool_input: "Yes"
    tool_listing: "Yes"
    tool_output: "Yes"
    notes: "Converts REST API endpoints to MCP tools and proxies through {{site.base_gateway}}'s normal proxy pipeline. All three events are inspected."
  - mode: "`listener`"
    tool_input: "Yes"
    tool_listing: "No"
    tool_output: "No"
    notes: "Aggregates tools from `conversion-only` plugins entirely within its own access phase and returns the response using `kong.response.exit()`. The response phase doesn't fire, so `tool_listing` and `tool_output` can't be inspected."
  - mode: "`conversion-only`"
    tool_input: "N/A"
    tool_listing: "N/A"
    tool_output: "N/A"
    notes: "Defines tools for use by a `listener` plugin. Doesn't handle incoming MCP requests directly."
{% endtable %}

`passthrough-listener` and `conversion-listener` modes are fully supported.
`listener` mode provides `tool_input` coverage only.

## Install the {{page.name}} plugin

LuaRock name: `crowdstrike-aidr-mcp`.
The {{page.name}} plugin is built from source using the `luarocks` utility bundled with {{site.base_gateway}}.
It depends on the `kong-plugin-crowdstrike-aidr-shared` library, which is included in the same repository.

### Prerequisites

Before installing the plugin, ensure you have the following:

* [CrowdStrike customer account](https://www.crowdstrike.com/en-us/login/) in one of the following clouds: US-1, US-2, or EU-1
* [**AIDR for Agents** Falcon subscription](https://pangea.cloud/docs/aidr/get-started/agents)
* [**AIDR Admin** role](https://pangea.cloud/docs/aidr#roles-and-permissions) assigned to your Falcon user for the current customer account
* HTTP access to AIDR API origins
* A running {{site.base_gateway}} installation

#### Register a Kong Collector in AIDR

Register a collector in the [AIDR console](https://aidr.pangea.cloud) to obtain the API key and base URL required to configure the plugin.

1. In the AIDR console, go to the **Collectors** page.
1. Click **Collector**.
1. Choose **Gateway** as the collector type, select **Kong**, and click **Next**.
1. Configure the collector:
   * **Collector Name**: Enter a descriptive name to appear in dashboards and reports.
   * **Logging**: Select whether to log full tool call content, or metadata only.
   * **Policy** *(optional)*: Assign a policy to apply detection rules to traffic. You can select an existing policy, create one on the **Policies** page, or select **No Policy, Log Only** to record activity without applying detection rules.
1. Click **Save** to complete registration.

After saving, open the **Config** tab on the collector details page and copy your **API key** and **AIDR base URL**.
You'll need these when enabling the plugin.

### Installation steps

The following installation steps install and build the `crowdstrike-aidr-mcp` plugin and the `crowdstrike-aidr-shared` library.

{:.info}
> **Note**: If you also want to protect LLM chat traffic, you can install the [CrowdStrike Falcon AIDR Request](/plugins/crowdstrike-aidr-request/) and [CrowdStrike Falcon AIDR Response](/plugins/crowdstrike-aidr-response/) plugins at the same time by adding their packages to the same build.

{% navtabs 'deployment' %}
{% navtab "Konnect" %}

In {{site.konnect_short_name}} hybrid mode, upload the plugin schema to the control plane and deploy the plugin code to each data plane node using a custom Docker image.

1. Clone the plugin repository:

   ```sh
   git clone https://github.com/crowdstrike/aidr-kong.git
   ```

1. Navigate into the repository:

   ```sh
   cd aidr-kong
   ```

1. Set the credentials in your environment:

   ```sh
   export KONNECT_CP_ID="your-control-plane-id"
   export KONNECT_TOKEN="your-konnect-pat"
   ```

1. Upload the {{page.name}} plugin schema using the [Konnect API](/api/konnect/control-planes/):

   ```sh
   curl -X POST \
     "https://us.api.konghq.com/v2/control-planes/${KONNECT_CP_ID}/core-entities/plugin-schemas" \
     --header "Authorization: Bearer ${KONNECT_TOKEN}" \
     --header "Content-Type: application/json" \
     --data "{\"lua_schema\": $(jq -Rs . kong/plugins/crowdstrike-aidr-mcp/schema.lua)}"
   ```

Your control plane ID is visible in the URL when viewing the control plane in {{site.konnect_short_name}}, or on the control plane's overview page.

1. Build the custom {{site.base_gateway}} image using the Dockerfile in the repository:

   ```sh
   docker build -t kong-aidr-plugins:latest .
   ```

1. Run the image as a {{site.konnect_short_name}} data plane node.

   The cluster certificate, key, and CP/telemetry endpoints are provided by {{site.konnect_short_name}} when you click **Add Data Plane Node** in {{site.konnect_short_name}} API Gateway:

   ```sh
   docker run -d \
     --name kong-aidr-dataplane \
     --restart unless-stopped \
     -e "KONG_ROLE=data_plane" \
     -e "KONG_DATABASE=off" \
     -e "KONG_CLUSTER_MTLS=pki" \
     -e "KONG_CLUSTER_CONTROL_PLANE=YOUR_CP_ENDPOINT:443" \
     -e "KONG_CLUSTER_SERVER_NAME=YOUR_CP_ENDPOINT" \
     -e "KONG_CLUSTER_TELEMETRY_ENDPOINT=YOUR_TELEMETRY_ENDPOINT:443" \
     -e "KONG_CLUSTER_TELEMETRY_SERVER_NAME=YOUR_TELEMETRY_ENDPOINT" \
     -e "KONG_CLUSTER_CERT=/PATH/TO/YOUR_CLUSTER_CERT" \
     -e "KONG_CLUSTER_CERT_KEY=/PATH/TO/YOUR_CLUSTER_CERT_KEY" \
     -e "KONG_LUA_SSL_TRUSTED_CERTIFICATE=system" \
     -e "KONG_KONNECT_MODE=on" \
     -e "KONG_ROUTER_FLAVOR=expressions" \
     -e "KONG_PLUGINS=bundled,crowdstrike-aidr-mcp" \
     -p 8000:8000 \
     -p 8443:8443 \
     kong-aidr-plugins:latest
   ```

1. Confirm the node appears as connected in the API Gateway UI before proceeding.

{% endnavtab %}
{% navtab "Docker" %}

1. Build a custom {{site.base_gateway}} image with the plugin installed from the source repository:

   ```dockerfile
   FROM kong/kong-gateway:latest

   USER root

   COPY ./kong /kong
   COPY ./kong-plugin-crowdstrike-aidr-*.rockspec /

   RUN luarocks make kong-plugin-crowdstrike-aidr-shared-*.rockspec \
   && luarocks make kong-plugin-crowdstrike-aidr-mcp-*.rockspec

   ENV KONG_PLUGINS=bundled,crowdstrike-aidr-mcp

   USER kong

   ENTRYPOINT ["/entrypoint.sh"]
   EXPOSE 8000 8443 8001 8444
   STOPSIGNAL SIGQUIT
   HEALTHCHECK --interval=10s --timeout=10s --retries=10 CMD kong health
   CMD ["kong", "docker-start"]
   ```

1. Clone the plugin repository:

   ```sh
   git clone https://github.com/crowdstrike/aidr-kong.git
   ```

1. Navigate into the repository:

   ```sh
   cd aidr-kong
   ```

1. Build the image:

   ```sh
   docker build -t kong-plugin-crowdstrike-aidr .
   ```

{:.warning}
> This Dockerfile is purposely abbreviated to show only the plugin installation piece.
To launch {{site.base_gateway}} completely with all dependencies, configuration, and optionally a database, install the plugin `.rockspec` files locally using `luarocks`, then see the [Gateway with Docker Compose installation](/gateway/install/docker/) instructions, adjusting the file by adding `KONG_PLUGINS: bundled,crowdstrike-aidr-mcp` under `environment`.

{% endnavtab %}
{% navtab "kong.conf" %}

1. Clone the plugin repository:

   ```sh
   git clone https://github.com/crowdstrike/aidr-kong.git
   ```

1. Navigate into the repository:

   ```sh
   cd aidr-kong
   ```

1. Install the shared library dependency:

   ```sh
   luarocks make kong-plugin-crowdstrike-aidr-shared-*.rockspec
   ```

1. Install the {{page.name}} plugin:

   ```sh
   luarocks make kong-plugin-crowdstrike-aidr-mcp-*.rockspec
   ```

1. In your [`kong.conf`](/gateway/configuration/), append the plugin name to the `plugins` field. Make sure the field isn't commented out:

   ```
   plugins = bundled,crowdstrike-aidr-mcp
   ```

1. Restart {{site.base_gateway}}:

   ```sh
   kong restart
   ```

{% endnavtab %}
{% endnavtabs %}

## Enable the plugin

After installing the plugin, [enable the CrowdStrike Falcon AIDR MCP plugin](/plugins/crowdstrike-aidr-mcp/examples/enable-crowdstrike-aidr-mcp/) on a Route.

Restrict the Route to `POST` requests, since MCP JSON-RPC 2.0 uses only `POST`.

## Test the plugin

After enabling the plugin, verify it's inspecting MCP traffic as expected.

Send a `tools/list` request:

```sh
curl -s -X POST http://localhost:8000/your-mcp-route \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "tools/list", "id": 1, "params": {}}'
```

A `tool_listing` event is sent to AIDR with the server's tool definitions.
If a tool description contains a prompt injection payload, AIDR detects it and the plugin returns a JSON-RPC error to the client instead of the tool listing.

Send a `tools/call` request:

```sh
curl -s -X POST http://localhost:8000/your-mcp-route \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "tools/call", "id": 2, "params": {"name": "get_weather", "arguments": {"location": "New York"}}}'
```

This request triggers both a `tool_input` event, evaluated before the MCP server executes the tool, and a `tool_output` event, evaluated against the tool's result.
If the arguments or the result contain a malicious payload or sensitive data such as PII, AIDR detects it and the plugin blocks the call or the response.

The events also appear in the AIDR console under your collector.

## View collector data in AIDR

{% include_cached /plugins/crowdstrike-aidr/view-collector-data.md %}