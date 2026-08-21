---
title: Map a RESTful API to MCP tools
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/

description: Learn how to create an MCP Server entity in {{site.ai_gateway}} to convert any RESTful API into MCP tools.

products:
  - ai-gateway

series:
  id: mcp-conversion-2-0
  position: 1

permalink: /ai-gateway/map-api-to-mcp-tools/

works_on:
  - konnect

min_version:
  ai-gateway: '2.0'

entities:
  - ai-mcp-server

tags:
  - ai
  - mcp

tldr:
  q: How do I turn an existing REST API into MCP tools?
  a: |
    Create an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) entity in {{site.ai_gateway}}, and it automatically converts your REST API endpoints into MCP tools that any MCP-compatible AI assistant can call, no custom server code required.

    This tutorial shows you how to create an AI MCP Server entity using kongctl to expose a REST API as MCP tools, and how to call those tools from an MCP client.
tools:
  - kongctl

prereqs:
  konnect:
    - name: KONG_TRACING_INSTRUMENTATIONS
    - name: KONG_TRACING_SAMPLING_RATE
---

## Run a sample API to expose

Before creating an [MCP Server](/ai-gateway/entities/ai-mcp-server/) entity, you’ll need an upstream HTTP API to expose. For this tutorial, use the [Swagger Petstore](https://github.com/swagger-api/swagger-petstore) sample API running in Docker. This allows you to test the entity without relying on an external service. The Petstore API comes pre-loaded with 10 pets across the `available`, `pending`, and `sold` statuses, which the API exposes through the `/pet/findByStatus` and `/pet/{petId}` endpoints.

```sh
docker run -d \
  --name swagger-petstore \
  -p 8080:8080 \
  swaggerapi/petstore3:latest
```
{:data-test-step="block"}

The MCP Server entity will convert this API's endpoints into MCP tool definitions.

## Create an MCP Server entity

With the Petstore API running, create an [MCP Server](/ai-gateway/entities/ai-mcp-server/) entity configured as a `conversion-listener` to expose the endpoints `/pet/findByStatus` and `/pet/{petId}` as MCP tools.
The following example maps the Petstore API operations to MCP tool definitions that the client can invoke.

{% entity_examples %}
ai_gateway_mcp_servers:
  - ref: petstore-mcp
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: petstore-mcp
    display_name: "Petstore API"
    type: conversion-listener
    enabled: true
    policies: []
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

Two details of this configuration are worth calling out:

- **Route stripping**: `route.paths` (`/petstore`) is the prefix clients must hit for the {{site.ai_gateway}} to match this entity, so every tool's `path` includes it. Before forwarding upstream, the gateway strips that prefix and appends what's left (for example, `/pet/findByStatus`) to `config.url`.
- **Parameters**: {{site.ai_gateway}} builds each tool's input schema from its `parameters` list, prefixing every parameter name with its `in` location: `path_<name>` for path parameters, `query_<name>` for query parameters.

## Verify that the endpoints are available as tools

Use [MCP Inspector CLI](https://modelcontextprotocol.io/docs/tools/inspector#cli) to verify that the MCP server exposes `get-pet-by-id` and `get-pets-by-status` as tools:

<!--vale off-->
{% validation custom-command %}
command: |
  npx -y @modelcontextprotocol/inspector@0.22.0 --cli \
    http://localhost:8000/petstore \
    --transport http --method tools/list |  jq -r '.tools[].name'
expected:
  return_code: 0
render_output: false
message: |
  get-pet-by-id
  get-pets-by-status
{% endvalidation %}
<!--vale on-->

You should see the following output:

```text
get-pet-by-id
get-pets-by-status
```
{:.no-copy-code}

## Validate the configuration

Let's call the `get-pets-by-status` tool to see which pets are available:

<!--vale off-->
{% validation custom-command %}
command: |
  npx -y @modelcontextprotocol/inspector@0.22.0 --cli \
    http://localhost:8000/petstore \
    --transport http --method tools/call \
    --tool-name get-pets-by-status \
    --tool-arg query_status=available | jq -r '.content[0].text' | jq -c '.[]'
expected:
  return_code: 0
render_output: false
message: |
  {"id":1,"category":{"id":2,"name":"Cats"},"name":"Cat 1","photoUrls":["url1","url2"],"tags":[{"id":1,"name":"tag1"},{"id":2,"name":"tag2"}],"status":"available"}
  {"id":2,"category":{"id":2,"name":"Cats"},"name":"Cat 2","photoUrls":["url1","url2"],"tags":[{"id":1,"name":"tag2"},{"id":2,"name":"tag3"}],"status":"available"}
  {"id":4,"category":{"id":1,"name":"Dogs"},"name":"Dog 1","photoUrls":["url1","url2"],"tags":[{"id":1,"name":"tag1"},{"id":2,"name":"tag2"}],"status":"available"}
  {"id":7,"category":{"id":4,"name":"Lions"},"name":"Lion 1","photoUrls":["url1","url2"],"tags":[{"id":1,"name":"tag1"},{"id":2,"name":"tag2"}],"status":"available"}
  {"id":8,"category":{"id":4,"name":"Lions"},"name":"Lion 2","photoUrls":["url1","url2"],"tags":[{"id":1,"name":"tag2"},{"id":2,"name":"tag3"}],"status":"available"}
  {"id":9,"category":{"id":4,"name":"Lions"},"name":"Lion 3","photoUrls":["url1","url2"],"tags":[{"id":1,"name":"tag3"},{"id":2,"name":"tag4"}],"status":"available"}
  {"id":10,"category":{"id":3,"name":"Rabbits"},"name":"Rabbit 1","photoUrls":["url1","url2"],"tags":[{"id":1,"name":"tag3"},{"id":2,"name":"tag4"}],"status":"available"}
{% endvalidation %}
<!--vale on-->

You should see the following output:

```text
{"id":1,"category":{"id":2,"name":"Cats"},"name":"Cat 1","photoUrls":["url1","url2"],"tags":[{"id":1,"name":"tag1"},{"id":2,"name":"tag2"}],"status":"available"}
{"id":2,"category":{"id":2,"name":"Cats"},"name":"Cat 2","photoUrls":["url1","url2"],"tags":[{"id":1,"name":"tag2"},{"id":2,"name":"tag3"}],"status":"available"}
{"id":4,"category":{"id":1,"name":"Dogs"},"name":"Dog 1","photoUrls":["url1","url2"],"tags":[{"id":1,"name":"tag1"},{"id":2,"name":"tag2"}],"status":"available"}
{"id":7,"category":{"id":4,"name":"Lions"},"name":"Lion 1","photoUrls":["url1","url2"],"tags":[{"id":1,"name":"tag1"},{"id":2,"name":"tag2"}],"status":"available"}
{"id":8,"category":{"id":4,"name":"Lions"},"name":"Lion 2","photoUrls":["url1","url2"],"tags":[{"id":1,"name":"tag2"},{"id":2,"name":"tag3"}],"status":"available"}
{"id":9,"category":{"id":4,"name":"Lions"},"name":"Lion 3","photoUrls":["url1","url2"],"tags":[{"id":1,"name":"tag3"},{"id":2,"name":"tag4"}],"status":"available"}
{"id":10,"category":{"id":3,"name":"Rabbits"},"name":"Rabbit 1","photoUrls":["url1","url2"],"tags":[{"id":1,"name":"tag3"},{"id":2,"name":"tag4"}],"status":"available"}
```
{:.no-copy-code}

Now, we can check the details of `Lion 1` - `id:7` - by calling the `get-pet-by-id` tool:

<!--vale off-->
{% validation custom-command %}
command: |
  npx -y @modelcontextprotocol/inspector@0.22.0 --cli \
    http://localhost:8000/petstore \
    --transport http --method tools/call \
    --tool-name get-pet-by-id \
    --tool-arg path_petId=7 | jq -r '.content[0].text' | jq -c '.'
expected:
  return_code: 0
message: |
  {"id":7,"category":{"id":4,"name":"Lions"},"name":"Lion 1","photoUrls":["url1","url2"],"tags":[{"id":1,"name":"tag1"},{"id":2,"name":"tag2"}],"status":"available"}
render_output: false
{% endvalidation %}
<!--vale on-->

You should see the following response:

```text
{"id":7,"category":{"id":4,"name":"Lions"},"name":"Lion 1","photoUrls":["url1","url2"],"tags":[{"id":1,"name":"tag1"},{"id":2,"name":"tag2"}],"status":"available"}
```
{:.no-copy-code}

You can validate this result against the [Swagger Petstore API source](https://github.com/swagger-api/swagger-petstore).
