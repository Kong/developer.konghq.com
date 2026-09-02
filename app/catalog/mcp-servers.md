---
title: "MCP servers in {{site.konnect_catalog}}"
content_type: reference
layout: reference

products:
    - catalog
    - ai-gateway

breadcrumbs:
  - /catalog/

works_on:
  - konnect

search_aliases:
  - mcp

description: An MCP server is an interface in {{site.konnect_catalog}} that represents an MCP server your organization builds or consumes. Learn how to create and manage MCP servers.

related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: "MCP registries (tech preview)"
    url: /catalog/mcp-registry/
  - text: "AI Models"
    url: /catalog/ai-models/

faqs:
  - q: |
      {% include faqs/mcp-server-vs-registry.md section='question' %}
    a: |
      {% include faqs/mcp-server-vs-registry.md section='answer' %}
---

As teams build MCP servers for AI agents, those servers are often embedded directly in agent code, defined in local configuration files, or scattered across repositories, with no shared record of what already exists.
{{site.konnect_catalog}} gives you a single place to see every MCP server across your organization, so you don't have to track each one down in a separate tool to know what it does or how to connect to it.
An MCP server is an interface in {{site.konnect_catalog}} that represents an MCP server your organization builds or consumes.

You can create an MCP server in {{site.konnect_catalog}} in a few ways:
* Define it manually, filling out its details yourself.
* Paste an existing server's JSON definition.
* Import it from [{{site.ai_gateway}} 2.0](/ai-gateway/), by linking an existing [{{site.ai_gateway}} MCP server](/ai-gateway/entities/ai-mcp-server/) as the source.
* (Coming soon) Connect to a running MCP server, and have {{site.konnect_short_name}} fetch its definition directly.

When an MCP server is linked to {{site.ai_gateway}} 2.0, the link indicates that {{site.ai_gateway}} is protecting and proxying that server.
An MCP server that isn't linked can still exist in {{site.konnect_catalog}} as part of your organization's inventory. 
The absence of a link can also help you identify MCP servers that aren't yet protected by {{site.ai_gateway}} and could be candidates to govern with it.

The link is a snapshot, not a live sync: if you change the linked server's configuration in {{site.ai_gateway}}, the MCP server in {{site.konnect_catalog}} isn't automatically updated to match.

## Create an MCP server

{% navtabs "create-mcp-server" %}
{% navtab "{{site.konnect_short_name}} API" %}
Send a POST request to the `/mcp-servers` endpoint to create an empty MCP server:
<!--vale off-->
{% konnect_api_request %}
url: /v1/mcp-servers
status_code: 201
method: POST
body:
    name: my-mcp
    display_name: My MCP
    description: Customer support triage MCP server
extract_body:
    - name: 'id'
      variable: MCP_ID
capture:
  - variable: MCP_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

Add the MCP server's capabilities and access methods by sending a POST request to the `/mcp-servers/{mcpId}/versions` endpoint:
<!--vale off-->
{% konnect_api_request %}
url: /v1/mcp-servers/$MCP_ID/versions
status_code: 201
method: POST
body:
    version: 1.0.0
    tools:
      - name: get_forecast
        description: Multi-day forecast for a location.
        input_schema:
            type: object
    resources:
      - name: forecast-docs
        uri: file://forecast-docs.txt
        description: Reference documentation describing forecast data fields and units.
        mime_type: text/plain
    prompts:
      - name: summarize_forecast
        description: Summarize the forecast for a location over a date range.
        arguments:
          - name: location
            description: The location to summarize the forecast for.
            required: true
    remotes:
      - type: streamable-http
        url: https://mcp.example.com/weather
    packages:
      - registry:
            type: npm
        identifier: "@example/weather-mcp-server"
        version: 1.0.0
        transport:
            type: stdio
{% endkonnect_api_request %}
<!--vale on-->

(Optional) Link the MCP server to a server on {{site.ai_gateway}} by sending a POST request to the `/mcp-servers/{mcpId}/implementations` endpoint:
<!--vale off-->
{% konnect_api_request %}
url: /v1/mcp-servers/$MCP_ID/implementations
status_code: 201
method: POST
body:
    implementation:
        type: ai-gateway
        config:
            gateway_control_plane_id: $CONTROL_PLANE_ID
            gateway_mcp_server_id: $GATEWAY_MCP_SERVER_ID
{% endkonnect_api_request %}
<!--vale on-->
{% endnavtab %}
{% navtab "{{site.konnect_short_name}} UI" %}
1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. From the **New** dropdown menu, select **MCP server**.
1. Under **Data source**, select one of the following:
   1. To fill out the server's details yourself, select **Define manually**.
   1. To populate details from an existing server's definition, select **Paste JSON**, then in the **Version, capabilities, and access methods** field, paste the definition. Only `version` is required.
   1. To create the server from an MCP interface already configured in {{site.ai_gateway}} 2.0, select **Import from AI gateway**, then:
      1. From the **AI gateway** dropdown menu, select your {{site.ai_gateway}} control plane.
      1. From the **MCP server** dropdown menu, select the server you want to import.
1. In the **Display name** field, enter a name for your MCP server, for example `My MCP server`.
1. In the **Name** field, enter a unique identifier for the MCP server, for example `my-new-mcp-server`. This must contain only lowercase letters, numbers, hyphens, and periods.
1. (Optional) In the **Description** field, describe the purpose of your MCP server.
1. (Optional) Click **Add labels**, and do the following:
   1. In the **Key** field, enter a label key.
   1. In the **Value** field, enter a label value.
   1. (Optional) Click **Add another label** to add more labels.
1. Click **Next**.
1. If you didn't select **Paste JSON**, in the **Version** field, enter a version number for your MCP server, for example `1.0.0`.
1. (Optional) Under **Capabilities**, click **New capability**, and select one of the following:
   * **Tool**: Outlines how your server takes actions. 
     1. In the **Name** field, enter a unique identifier for the tool. 
     1. In the **Input schema** field, enter the JSON schema defining the tool's expected parameters. 
     1. (Optional) Fill in **Title**, **Description**, **Output schema**, and **Annotations**.
     1. Click **Add**, then repeat to add more capabilities.
   * **Resource**: To share server context through documents, logs, and other data. 
     1. In the **URI** field, enter a unique identifier for the resource, for example `file://example.txt`. 
     1. In the **Name** field, enter a name for the resource. 
     1. (Optional) Fill in **Title**, **Description**, **mimeType**, and **Size (bytes)**.
     1. Click **Add**, then repeat to add more capabilities.
   * **Prompt**: Define a reusable workflow with preset inputs. 
     1. In the **Name** field, enter a unique identifier for the prompt. 
     1. (Optional) Fill in **Title**, **Description**, and a comma-separated list of **Arguments**, for example `language, focus_area, severity_threshold`.
     1. Click **Add**, then repeat to add more capabilities.
1. (Optional) Under **Access methods**, click **New access method**, and select one of the following:
   * **Remote**: Describes a hosted MCP server endpoint. 
     1. In the **Remote URL** field, enter the server's endpoint, for example `https://example.com/mcp`. 
     1. From the **Transport type** dropdown menu, select a transport type. 
     1. (Optional) In the **Headers** field, enter headers as a JSON array of objects, for example, to pass an authorization token:
        ```json
        [
          {
            "name": "Authorization",
            "value": "Bearer ${token}"
          }
        ]
        ```
     1. Click **Add**, then repeat to add more access methods.
   * **Package**, to describe a run-it-yourself distribution option. 
      1. In the **Package identifier** field, enter the package name or URL, for example `@modelcontextprotocol/mcp-server`. 
      1. From the **Transport type** and **Package type** dropdown menus, select the applicable types. 
      1. (Optional) Fill in **Registry base URL** and **Package version**. If you leave **Package version** blank, the package uses the server's version.
      1. Click **Add**, then repeat to add more access methods.
1. Click **Save**.
{% endnavtab %}
{% endnavtabs %}

{% comment %}
## MCP server analytics

When you create an MCP server in {{site.konnect_catalog}}, you can see analytics for that server in addition to the details you configured.
{% endcomment %}
