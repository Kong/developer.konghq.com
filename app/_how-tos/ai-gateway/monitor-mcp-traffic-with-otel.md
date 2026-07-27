---
title: Monitor MCP traffic with OpenTelemetry
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
  - text: OpenTelemetry Policy
    url: /ai-gateway/policies/opentelemetry/
  - text: Gen AI OpenTelemetry metrics reference
    url: /ai-gateway/ai-otel-metrics/
  - text: Map a RESTful API to MCP tools
    url: /ai-gateway/map-api-to-mcp-tools/

description: Attach an OpenTelemetry Policy to an MCP Server entity to export OTLP metrics for MCP tool traffic to a collector.

products:
  - ai-gateway

series:
  id: mcp-conversion-2-0
  position: 2

permalink: /ai-gateway/monitor-mcp-traffic-with-otel/

works_on:
  - konnect

min_version:
  ai-gateway: '2.0'

entities:
  - ai-mcp-server
  - ai-policy

tags:
  - ai
  - mcp
  - observability

tldr:
  q: How do I export OpenTelemetry metrics for MCP tool traffic in {{site.ai_gateway}}?
  a: |
    Attach an [OpenTelemetry Policy](/ai-gateway/policies/opentelemetry/) to an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) entity to export `kong.gen_ai.mcp.*` and `mcp.*` OTLP metrics for MCP tool traffic to a collector.
    Set `config.metrics.endpoint` and `config.metrics.enable_ai_metrics` on the Policy to send this data to your observability backend.

tools:
  - kongctl

prereqs:
  inline:
    - title: OpenTelemetry Collector
      content: |
        Launch a local OpenTelemetry Collector that listens on port 4318 and writes received data to a text file:

        ```sh
        docker run \
          --name otel-collector \
          -p 127.0.0.1:4318:4318 \
          otel/opentelemetry-collector:0.141.0 \
          2>&1 | tee collector-output.txt
        ```

        In a new terminal, keep the container running so it can receive metrics from {{site.ai_gateway}}.
      icon_url: /assets/icons/opentelemetry.svg

cleanup:
  inline:
    - title: Stop the OpenTelemetry Collector
      content: |
        ```sh
        docker rm -f otel-collector
        ```
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway

---
## Attach an OpenTelemetry Policy to the MCP Server entity

By default, an AI Policy applies to every resource on your {{site.ai_gateway}}. Setting `global` to `false` changes that: the `otel-mcp` Policy now only takes effect on entities that explicitly list it, instead of applying gateway-wide.

The `marketplace-mcp` entity does exactly that by referencing `otel-mcp` in its `policies` list. As a result, every request that goes through `marketplace-mcp` is measured and exported as metrics to the collector you started earlier. The `service.name` value under `resource_attributes` is just a label attached to that exported data, so if you're running multiple {{site.ai_gateway}}s or services into the same collector, you can tell which one a given metric came from.

```sh
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
ai_gateway_policies:
  - ref: otel-mcp
    ai_gateway: !lookup {id: $AI_GATEWAY_ID}
    name: otel-mcp
    display_name: "otel-mcp"
    type: opentelemetry
    enabled: true
    global: false
    config:
      traces_endpoint: http://host.docker.internal:4318/v1/traces
      metrics:
        endpoint: http://host.docker.internal:4318/v1/metrics
        enable_ai_metrics: true
      resource_attributes:
        service.name: kong-mcp

ai_gateway_mcp_servers:
  - ref: marketplace-mcp
    ai_gateway: !lookup {id: $AI_GATEWAY_ID}
    name: marketplace-mcp
    display_name: "Marketplace API"
    type: conversion-listener
    enabled: true
    policies:
      - !ref otel-mcp#name
    access:
      acl_attribute_type: consumer
      acls:
        allow: []
      default_tool_acls:
        deny: []
    config:
      url: http://host.docker.internal:3000
      route:
        paths:
          - /marketplace
      logging:
        payloads: true
        statistics: true
      server:
        timeout: 60000
    tools:
      - name: get-users
        description: Get users
        method: GET
        path: /marketplace/users
        parameters:
          - name: id
            in: query
            required: false
            schema:
              type: string
            description: Optional user ID
      - name: get-orders-for-user
        description: Get orders for a user
        method: GET
        path: /marketplace/orders
        parameters:
          - description: User ID to filter orders
            in: query
            name: userid
            required: true
            schema:
              type: string
EOF
```
{:.collapsible}

## Generate MCP traffic

Using the `marketplace-mcp` connection you already set up in ChatWise:

1. Start a new chat.
1. Click the **hammer icon** to enable MCP tools, and enable `marketplace-mcp` from the dropdown.
1. Enter the following in the ChatWise chat:

   ```text
   What did Fiona Clark order?
   ```

## Validate metrics

Search `collector-output.txt` for `kong.gen_ai.mcp` to find the emitted metrics. You should see data like the following:

```
Metric #8
Descriptor:
     -> Name: kong.gen_ai.mcp.response.size
     -> Description: Size of AI MCP response body
     -> Unit: By
     -> DataType: Histogram
     -> AggregationTemporality: Cumulative
HistogramDataPoints #0
Data point attributes:
     -> kong.workspace.name: Str(default)
     -> kong.route.name: Str(marketplace-mcp-route)
     -> mcp.method.name: Str(tools/call)
     -> gen_ai.tool.name: Str(get-orders-for-user)
     -> kong.service.name: Str(marketplace-mcp)
Count: 1
Sum: 2175.000000

Metric #10
Descriptor:
     -> Name: mcp.server.operation.duration
     -> Description: MCP request/notification duration as observed on the receiver
     -> Unit: s
     -> DataType: Histogram
     -> AggregationTemporality: Cumulative
HistogramDataPoints #3
Data point attributes:
     -> gen_ai.operation.name: Str(execute_tool)
     -> kong.workspace.name: Str(default)
     -> kong.route.name: Str(marketplace-mcp-route)
     -> mcp.method.name: Str(tools/call)
     -> gen_ai.tool.name: Str(get-orders-for-user)
     -> kong.service.name: Str(marketplace-mcp)
Count: 1
Sum: 0.037000
```
{:.collapsible}

`kong.route.name` carries a `-route` suffix because {{site.ai_gateway}} auto-generates a Route for the MCP Server entity.

{:.info}
> See [MCP metrics](/ai-gateway/ai-otel-metrics/#mcp-metrics) for the full metric reference.

{:.success}
> **MCP Metrics in {{site.konnect_short_name}}**
>
> You can also view MCP traffic metrics without setting up a collector, using {{site.konnect_short_name}} Analytics:
> 1. Go to **Observability > Dashboards**.
> 1. Click **Create dashboard > Create from template**.
> 1. Select the **Agentic analytics** dashboard. This dashboard highlights which tools are called most frequently, breaks down tool usage by consumer, and tracks average latency per tool over time, helping teams operating MCP-enabled services understand usage patterns and identify performance bottlenecks.
> 1. Click **Use template** to see MCP tool usage, total MCP requests, total MCP errors, and other statisticss.