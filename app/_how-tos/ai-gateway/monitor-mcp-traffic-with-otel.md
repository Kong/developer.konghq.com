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
  q: How do I monitor MCP tool traffic in {{site.ai_gateway}}?
  a: |
    To monitor MCP tool traffic, attach an [OpenTelemetry Policy](/ai-gateway/policies/opentelemetry/) to an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) entity. {{site.ai_gateway}} automatically sends metrics like tool call counts, response sizes, and request durations to your observability backend, with no code changes required.

    This tutorial shows you how to attach the Policy using kongctl, generate some MCP traffic, and see the resulting metrics in a local OpenTelemetry Collector.

tools:
  - kongctl

prereqs:
  inline:
    - title: OpenTelemetry Collector
      include_content: md/ai-gateway/v2/prereqs/opentelemetry-collector
      icon_url: /assets/icons/opentelemetry.svg

cleanup:
  inline:
    - title: Stop the OpenTelemetry Collector
      content: |
        ```sh
        docker rm -f otel-collector
        ```
        {: data-test-cleanup="block" }
      icon_url: /assets/icons/opentelemetry.svg
    - title: Stop Petstore API
      include_content: cleanup/third-party/swagger-petstore
      icon_url: '/assets/icons/code.svg'
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway
      icon_url: '/assets/icons/ai-gateway.svg'
---

## Attach an OpenTelemetry Policy to the MCP Server entity

By default, an AI Policy applies to every resource on your {{site.ai_gateway}}. Setting `global` to `false` changes that: the `otel-mcp` Policy  only takes effect on entities that explicitly list it, instead of applying to all entities.

The `petstore-mcp` entity does this by referencing `otel-mcp` in its `policies` list. As a result, every request that goes through `petstore-mcp` is measured and exported as metrics to the collector you started earlier. The `service.name` value under `resource_attributes` is a label attached to that exported data, so if you're running multiple {{site.ai_gateway}}s or services into the same collector, you can tell which one a given metric came from.

{% entity_examples %}
ai_gateway_policies:
  - ref: otel-mcp
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: otel-mcp
    display_name: "otel-mcp"
    type: opentelemetry
    enabled: true
    global: false
    config:
      traces_endpoint: http://otel-collector:4318/v1/traces
      metrics:
        endpoint: http://otel-collector:4318/v1/metrics
        enable_ai_metrics: true
      resource_attributes:
        service.name: kong-mcp

ai_gateway_mcp_servers:
  - ref: petstore-mcp
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: petstore-mcp
    display_name: "Petstore API"
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
      url: http://host.docker.internal:8080/api/v3
      route:
        paths:
          - /petstore
      logging:
        payloads: false
      server:
        timeout: 60000
    tools:
      - name: get-pets-by-status
        description: Find pets by status
        method: GET
        path: /petstore/pet/findByStatus
        parameters:
          - name: status
            in: query
            required: true
            schema:
              type: string
              enum:
                - available
                - pending
                - sold
            description: Status value to filter pets by
      - name: get-pet-by-id
        description: Get a pet by ID
        method: GET
        path: /petstore/pet/{petId}
        parameters:
          - description: ID of the pet to retrieve
            in: path
            name: petId
            required: true
            schema:
              type: integer
{% endentity_examples %}

## Generate MCP traffic

Now, we can check the details of `Dog 1` (`id:4`) by calling the `get-pet-by-id` tool:

<!--vale off-->
{% validation custom-command %}
command: |
  npx -y @modelcontextprotocol/inspector@0.22.0 --cli \
    http://localhost:8000/petstore \
    --transport http --method tools/call \
    --tool-name get-pet-by-id \
    --tool-arg path_petId=4 | jq -r '.content[0].text' | jq -c '.'
expected:
  return_code: 0
message: |
  {"id":4,"category":{"id":1,"name":"Dogs"},"name":"Dog 1","photoUrls":["url1","url2"],"tags":[{"id":1,"name":"tag1"},{"id":2,"name":"tag2"}],"status":"available"}
render_output: false
{% endvalidation %}
<!--vale on-->

You should see the following response:

```text
{"id":4,"category":{"id":1,"name":"Dogs"},"name":"Dog 1","photoUrls":["url1","url2"],"tags":[{"id":1,"name":"tag1"},{"id":2,"name":"tag2"}],"status":"available"}
```
{:.no-copy-code .wrap}

## Validate metrics

Check the collector's logs for `kong.gen_ai.mcp` to find the emitted metrics:

{:.info}
> Allow a few seconds for the collector to export metrics after traffic generation.


{% validation custom-command %}
command: |
  docker logs otel-collector 2>&1 | grep -A 15 kong.gen_ai.mcp
expected:
  return_code: 0
render_output: false
{% endvalidation %}

You should see data like the following:

```sh
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
     -> kong.route.name: Str(petstore-mcp-route)
     -> mcp.method.name: Str(tools/call)
     -> gen_ai.tool.name: Str(get-pet-by-id)
     -> kong.service.name: Str(petstore-mcp)
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
     -> kong.route.name: Str(petstore-mcp-route)
     -> mcp.method.name: Str(tools/call)
     -> gen_ai.tool.name: Str(get-pet-by-id)
     -> kong.service.name: Str(petstore-mcp)
Count: 1
Sum: 0.037000
```
{:.collapsible .no-copy-code}

`kong.route.name` carries a `-route` suffix because {{site.ai_gateway}} auto-generates a Route for the MCP Server entity.

See [MCP metrics](/ai-gateway/ai-otel-metrics/#mcp-metrics) for the full metric reference.

{:.success}
> **MCP Metrics in {{site.konnect_short_name}}**
>
> You can also view MCP traffic metrics without setting up a collector, using {{site.konnect_short_name}} Analytics:
> 1. Go to **Observability > Dashboards**.
> 1. Click **Create dashboard > Create from template**.
> 1. Select the **Agentic analytics** dashboard. This dashboard highlights which tools are called most frequently, breaks down tool usage by consumer, and tracks average latency per tool over time, helping teams operating MCP-enabled services understand usage patterns and identify performance bottlenecks.
> 1. Click **Use template** to see MCP tool usage, total MCP requests, total MCP errors, and other statistics.
