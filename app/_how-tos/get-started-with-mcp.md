---
title: Get started with {{site.konnect_product_name}} MCP Server
content_type: how_to
permalink: /mcp/kong-mcp/get-started/
breadcrumbs:
    - /mcp/
description: Learn how to quickly get started with using {{site.konnect_product_name}} MCP Server

products:
    - gateway
    - ai-gateway

works_on:
    - konnect

plugins:
  - ai-proxy

entities:
  - plugin

tags:
    - get-started
    - ai

related_resources:
  - text: Kong MCP
    url: https://github.com/metorial/mcp-containers/blob/main/catalog/Kong/mcp-konnect/mcp-konnect/README.md

tldr:
  q: What is {{site.konnect_product_name}} MCP Server, and how can I get started with it?
  a: |

    With Kong's Model Context Protocol (MCP) Server, you can enable AI assistants like Claude to interact directly with {{site.konnect_product_name}}’s API Gateway. This integration allows you to query analytics data, inspect configuration details, and manage control planes—all through natural language conversation.

    This tutorial will help you get started with MCP by connecting an AI assistant to {{site.konnect_product_name}}.

    {:.info}
    > This quickstart is intended for experimentation with AI-assisted API management. Do not run it as-is in production.

tools:
    - deck

prereqs:
  entities:
    services:
        - example-service
    consumers:
        - single-consumer

  inline:
    - title: OpenAI
      content: |
        This tutorial uses the AI Proxy plugin with OpenAI. You'll need to [create an OpenAI account](https://auth.openai.com/create-account) and [get an API key](https://platform.openai.com/api-keys). Once you have your API key, create an environment variable:

        ```sh
        export OPENAI_KEY='YOUR-API-KEY'
        ```
      icon_url: /assets/icons/openai.svg
    - title: Claude account and Claude desktop
      content: |
        To complete this tutorial, you'll need to have a [Claude](https://claude.ai) account and [Claude desktop](https://claude.ai/download).
      icon_url: /assets/icons/third-party/claude.svg
    - title: Node.js
      content: |
        To use the [Kong MCP Server](https://github.com/Kong/mcp-konnect), you'll need Node.js 20.0 or later. Run `node --version` in your terminal to check your installed version.
      icon_url: /assets/icons/gateway.svg
cleanup:
  inline:
    - title: Clean up {{site.konnect_product_name}} environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.6'

faqs:
  - q: "Why am I getting a connection error for the {{site.konnect_short_name}} MCP server?"
    a: |
      * **Verify your API key** is valid and has the necessary permissions.
      * **Check the API region** is correctly specified (`KONNECT_REGION`).
      * **Ensure network access** to the Kong {{site.konnect_product_name}} API is not blocked by a firewall or proxy.

  - q: "Why am I seeing authentication errors for the {{site.konnect_short_name}} MCP server?"
    a: |
      * **Regenerate your API key** from the Kong {{site.konnect_product_name}} portal if it's expired or revoked.
      * **Confirm environment variables** like `KONNECT_ACCESS_TOKEN` are set and available to the process.

  - q: "Why is my data not found when using the {{site.konnect_short_name}} MCP server?"
    a: |
      * **Check resource IDs** used in your request (e.g., control plane or service IDs).
      * **Ensure the resources exist** in the correct control plane and region.
      * **Validate time ranges** used in analytics queries to ensure they cover a period with data.

automated_tests: false
---

## Check that {{site.base_gateway}} is running

{% include how-tos/steps/ping-gateway.md %}

## Configure Kong MCP Server

To get started with Kong MCP server, first clone the repository and install dependencies.

1. Clone the repository:

    ```bash
    git clone https://github.com/Kong/mcp-konnect.git
    cd mcp-konnect
    ```
2. Use `npm` to install the required packages:

    ```bash
    npm install
    ```

3. Compile the MCP server:

    ```bash
    npm run build
    ```

## Configure Claude desktop

Claude uses a configuration file to register custom MCP servers. You’ll need to **create** this file based on your operating system:

* **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
* **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

Now, add the following configuration to the file:

```json
{
  "mcpServers": {
    "kong-konnect": {
      "command": "node",
      "args": [
        "/absolute/path/to/mcp-konnect/build/index.js"
      ],
      "env": {
        "KONNECT_ACCESS_TOKEN": "YOUR_KONNECT_PAT",
        "KONNECT_REGION": "us"
      }
    }
  }
}
```

{:.warning}
> * Replace `/absolute/path/to/mcp-konnect/build/index.js` with the full path to your local MCP server build.
> * Make sure the `KONNECT_ACCESS_TOKEN` matches the one you set earlier.
> * Replace the `KONNECT_REGION` value with your geographic region. You can see a list of all {{site.konnect_short_name}} regions in the [Geographic regions](/konnect-platform/geos/#control-planes) documentation.

{:.success}
> **Use {{site.konnect_product_name}} MCP Server with Cursor**
>
> You can also use Kong {{site.konnect_short_name}} MCP with any other MCP client like Cursor. To do that:
> 1. Open Cursor desktop.
> 2. Go to **Cursor Settings > Tools & Integrations**.
> 3. Click **Add New MCP Server**.
> 4. Paste the MCP server configuration from the code block above in the `mcp.json` file.
> 5. Save the `mcp.json` file
> 6. Go back to the **Cursor Settings > Tools & Integrations** tab.
> 7. You should see `kong-konnect` in the MCP Tools with 10 tools available.

## Restart Claude desktop

After saving the `claude_desktop_config.json` file, restart Claude for Desktop. The Kong {{site.konnect_product_name}} tools will now be available for Claude to use in conversation.


## Analyze API traffic using Claude and Kong MCP Server

Now that you've configured Claude Desktop with the {{site.konnect_short_name}} MCP server, you can analyze API traffic.

### List all Control Planes

{% navtabs "list-all-control-planes" %}
{% navtab "Prompt" %}

Use this prompt to retrieve all control planes in your {{site.konnect_short_name}} organization:

```text
List all Control Planes in my {{site.konnect_product_name}} organization.
```
{% endnavtab %}
{% navtab "Sample response" %}

The following is a sample response from Kong MCP Server:

```json
{
  "metadata": {
    "pageSize": 100,
    "pageNumber": 1,
    "filters": {
      "name": null,
      "clusterType": null,
      "cloudGateway": null,
      "labels": null
    },
    "sort": null
  },
  "controlPlanes": [
    {
      "controlPlaneId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "name": "default",
      "description": "",
      "labels": {},
      "metadata": {
        "createdAt": "2022-10-06T23:54:23.695Z",
        "updatedAt": "2024-07-09T07:40:37.224Z"
      }
    }
  ]
}

```
{:.no-copy-code}
{% endnavtab %}
{% endnavtabs %}

### List Services in a Control Plane

{% navtabs "list-all-services-in-control-plane" %}
{% navtab "Prompt" %}

Once you’ve identified a control plane, ask Claude to list its services:

```text
List all services for the quickstart Control Plane.
```
{% endnavtab %}
{% navtab "Sample response" %}

```json
{
  "metadata": {
    "controlPlaneId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "size": 50,
    "offset": null
  },
  "services": [
    {
      "serviceId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "name": "AIManagerModelService_1747139045696",
      "host": "localhost",
      "port": 80,
      "protocol": "http",
      "retries": 5,
      "connectTimeout": 60000,
      "writeTimeout": 60000,
      "readTimeout": 60000,
      "tags": [
        "ai-manager-created"
      ],
      "enabled": true,
      "metadata": {
        "createdAt": 1747139045,
        "updatedAt": 1747139045
      }
    },
    ...
  ],
  "relatedTools": [
    "Use list-routes to find routes that point to these services",
    "Use list-plugins to see plugins configured for these services"
  ]
}
```
{:.no-copy-code}

{% endnavtab %}
{% endnavtabs %}

### Query API traffic for a Service

To analyze traffic and detect error trends, run a query like this:

{% navtabs "query-api-traffic" %}
{% navtab "Prompt" %}

```text
Show me all API requests for the example-service Gateway Service in the quickstart Control Plane in the last hour that had 5xx status codes.
```
{% endnavtab %}
{% navtab "Sample response" %}

```json
{
  "requests": [
    {
      "requestId": "ca19e138bf16f1678e5ecb0f253aba37",
      "timestamp": "2025-05-16T05:19:11.332Z",
      "httpMethod": "GET",
      "uri": "/v1/ingest",
      "statusCode": "500",
      "consumerId": null,
      "serviceId": "986dc7ab-6238-48d8-b989-78c5f4910066:5050365a-faf2-4269-b53d-aff042b9178e",
      "routeId": "986dc7ab-6238-48d8-b989-78c5f4910066:1055be1b-1677-47da-ba62-c6d5f8c25b90",
      "latency": {
        "totalMs": 6,
        "gatewayMs": 0,
        "upstreamMs": 6
      },
      "clientIp": "205.234.240.66",
      "apiProduct": null,
      "apiProductVersion": null,
      "applicationId": null,
      "authType": "",
      "headers": {
        "host": "5a385ad748.eu.tp.konghq.tech:443",
        "userAgent": ""
      },
      "dataPlane": {
        "nodeId": "986dc7ab-6238-48d8-b989-78c5f4910066:e4f2fa05-d918-4b53-8479-891157dc8499",
        "version": "3.11.0.0"
      },
      "controlPlane": {
        "id": "986dc7ab-6238-48d8-b989-78c5f4910066",
        "group": null
      }
      ...
    }
  ]
}
```
{:.no-copy-code}
{:.no-copy-code}

{% endnavtab %}
{% endnavtabs %}

## Troubleshoot Consumer issues

### List Consumers in a Control Plane

Start by getting the list of consumers for a control plane:

```text
List all Consumers for the quickstart Control Plane.
```

### Analyze requests by a specific Consumer

To view traffic made by a specific Consumer in the last 24 hours:

```text
Show me all requests made by the example-consumer Consumer in the last 24 hours.
```

### Identify common errors for a Consumer

Ask Claude to identify frequent issues experienced by that Consumer:

```text
What are the most common errors experienced by this Consumer?
```




