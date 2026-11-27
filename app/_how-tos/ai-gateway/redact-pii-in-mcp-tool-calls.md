---
title: Redact PII in MCP tool calls
content_type: how_to
permalink: /ai-gateway/redact-pii-in-mcp-tool-calls/

description: Use the AI MCP Sanitizer Policy to redact personally identifiable information (PII) in the arguments an agent sends to an MCP tool and in the result the tool returns.

products:
  - ai-gateway

works_on:
  - konnect

min_version:
  ai-gateway: '2.4'

tools:
  - kongctl

entities:
  - ai-mcp-server
  - ai-policy

tags:
  - ai
  - mcp
  - security
  - dlp

tldr:
  q: How do I keep PII out of MCP tool calls?
  a: |
    Start the AI PII Anonymizer service, then create an AI MCP Sanitizer [AI Policy](/ai-gateway/entities/ai-policy/) that targets `tool_arguments` and `tool_results`, and attach it to an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/).
    {{site.ai_gateway}} then sends the tool server placeholders instead of the PII in the arguments, and returns placeholders instead of the PII in the result.

related_resources:
  - text: AI MCP Sanitizer Policy
    url: /ai-gateway/policies/ai-mcp-sanitizer/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
  - text: Map a RESTful API to MCP tools
    url: /ai-gateway/map-api-to-mcp-tools/
  - text: AI audit log reference
    url: /ai-gateway/ai-audit-log-reference/#ai-mcp-sanitizer-logs

prereqs:
  inline:
    - title: Petstore API
      include_content: prereqs/third-party/swagger-petstore
    - title: Node.js
      content: |
        This tutorial uses the [MCP Inspector CLI](https://modelcontextprotocol.io/docs/tools/inspector#cli) to call MCP tools. Install [Node.js](https://nodejs.org/) so you can run it with `npx`.

cleanup:
  inline:
    - title: Stop the PII service
      content: |
        ```sh
        docker rm -f ai-pii-service
        ```
        {: data-test-cleanup="block" }
    - title: Stop Petstore API
      include_content: cleanup/third-party/swagger-petstore
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway
---

## Start the AI PII Anonymizer service

The AI MCP Sanitizer Policy sends the text it sanitizes to the [AI PII Anonymizer service](/ai-gateway/policies/ai-mcp-sanitizer/#ai-pii-anonymizer-service). Run the English image on the same Docker network as the data plane:

```sh
docker run -d \
  --name ai-pii-service \
  --network kong-ai-quickstart-net \
  kong/ai-pii-service:v0.4.0-en
```
{: data-test-step="block" }

The data plane reaches the service by its container name, `ai-pii-service`, on port `8080`.

## Create the AI MCP Sanitizer Policy and an AI MCP Server

Create the AI MCP Sanitizer Policy and an AI MCP Server that exposes two Petstore operations as MCP tools. The AI MCP Server references the Policy, so the Policy applies to every `tools/call` request to this server.

The Policy redacts email addresses and phone numbers. It targets both `tool_arguments` and `tool_results`, and `recover_redacted` must be `false` when you target `tool_results`.

{% entity_examples %}
ai_gateway_policies:
  - ref: mcp-sanitizer
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: mcp-sanitizer
    display_name: MCP sanitizer
    type: ai-mcp-sanitizer
    config:
      anonymize:
        - email
        - phone
      sanitize_targets:
        - tool_arguments
        - tool_results
      host: ai-pii-service
      port: 8080
      recover_redacted: false
      stop_on_error: true

ai_gateway_mcp_servers:
  - ref: petstore-mcp
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: petstore-mcp
    display_name: Petstore API
    type: conversion-listener
    enabled: true
    policies:
      - !ref mcp-sanitizer#name
    config:
      url: http://host.docker.internal:8080/api/v3
      route:
        paths:
          - /petstore
    tools:
      - name: add-pet
        description: Add a pet
        method: POST
        path: /petstore/pet
        request_body:
          content:
            application/json:
              schema:
                type: object
                properties:
                  id:
                    type: integer
                  name:
                    type: string
                  photoUrls:
                    type: array
                    items:
                      type: string
                  status:
                    type: string
      - name: get-pet-by-id
        description: Get a pet by ID
        method: GET
        path: /petstore/pet/{petId}
        parameters:
          - name: petId
            in: path
            required: true
            schema:
              type: integer
            description: ID of the pet to retrieve
{% endentity_examples %}

## Add a pet that contains PII through the AI MCP Server

Call the `add-pet` tool with a pet name that contains an email address and a phone number:

<!--vale off-->
{% validation custom-command %}
command: |
  npx -y @modelcontextprotocol/inspector@0.22.0 --cli \
    http://localhost:8000/petstore \
    --transport http --method tools/call \
    --tool-name add-pet \
    --tool-arg 'body={"id":9001,"name":"Rex, owner jane.doe@example.com, 415-555-0132","photoUrls":["https://example.com/rex.png"],"status":"available"}'
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

## Add a pet that contains PII directly to the Petstore API

Add a second pet directly to the Petstore API, so that its name doesn't go through the Policy:

```sh
curl -s -X POST http://localhost:8080/api/v3/pet \
  -H 'Content-Type: application/json' \
  -d '{"id":9002,"name":"Milo, owner john.smith@example.com","photoUrls":["https://example.com/milo.png"],"status":"available"}'
```
{: data-test-step="block" }

## Validate

Check that the Policy redacted the tool call arguments and the tool call result.

### Check the tool call arguments

Read the first pet directly from the Petstore API, without going through {{site.ai_gateway}}, to see what the tool server stored:

<!--vale off-->
{% validation custom-command %}
command: |
  curl -s http://localhost:8080/api/v3/pet/9001 | jq -r '.name'
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

The tool server stored placeholders instead of the email address and phone number:

```text
Rex, owner PLACEHOLDER2, PLACEHOLDER1
```
{:.no-copy-code}

### Check the tool call result

Call the `get-pet-by-id` tool for the second pet:

<!--vale off-->
{% validation custom-command %}
command: |
  npx -y @modelcontextprotocol/inspector@0.22.0 --cli \
    http://localhost:8000/petstore \
    --transport http --method tools/call \
    --tool-name get-pet-by-id \
    --tool-arg path_petId=9002 | jq -r '.content[0].text' | jq -r '.name'
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

The Petstore API stored the email address, but the result that the agent receives contains a placeholder instead:

```text
Milo, owner PLACEHOLDER1
```
{:.no-copy-code}
