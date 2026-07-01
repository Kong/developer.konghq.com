---
title: Route A2A agent traffic through Kong AI Gateway
content_type: how_to
permalink: /ai-gateway/get-started-with-ai-agent/
description: Create an AI Agent entity in {{site.ai_gateway}} to proxy Agent-to-Agent (A2A) protocol traffic
products:
  - ai-gateway

works_on:
  - konnect

min_version:
  ai-gateway: '2.0'

entities:
  - ai-agent

tags:
  - get-started
  - ai
  - a2a

tldr:
  q: How do I route A2A agent traffic through {{site.ai_gateway}}?
  a: |
    When agents need to communicate with other agents, route the traffic through {{site.ai_gateway}} to apply authentication, rate limiting, observability, and content policies at the gateway layer.
    Create an [AI Agent](/ai-gateway/entities/ai-agent/) entity that exposes your upstream agent at a gateway route and attach policies for logging, security, and traffic control.
    The gateway proxies A2A JSON-RPC requests, discovers agent capabilities through Agent Cards, and exports metrics and payloads as observability spans.

    This tutorial shows you how to set up an AI Agent entity in {{site.konnect_product_name}} using the {{site.konnect_product_name}} API and how to test A2A traffic flowing through the gateway.

tools:
  - konnect-api

prereqs:
  inline:
    - title: OpenAI API key
      content: |
        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Export your key:
           ```bash
           export DECK_OPENAI_API_KEY='YOUR_OPENAI_API_KEY'
           ```

    - title: A2A agent
      include_content: prereqs/a2a-kongair-agent

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Agent entity reference
    url: /ai-gateway/entities/ai-agent/
  - text: A2A protocol specification
    url: https://a2a-protocol.org/latest/

cleanup:
  inline:
    - title: Stop the A2A agent
      content: |
        ```bash
        docker compose down
        docker rm -f a2a-kongair-agent
        ```

    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway

faqs:
  - q: What is the A2A protocol?
    a: The Agent-to-Agent (A2A) protocol is an open standard originally developed by Google that defines how AI agents communicate with each other. It uses JSON-RPC over HTTP and supports capability discovery through Agent Cards, task lifecycle management, multi-turn conversations, and streaming responses. See the [A2A protocol documentation](https://a2a-protocol.org/latest/) for the full specification.

  - q: How is A2A different from MCP?
    a: MCP (Model Context Protocol) standardizes how agents connect to tools, APIs, and data sources. A2A standardizes how agents communicate with other agents. They are complementary. Use MCP for agent-to-tool communication and A2A for agent-to-agent communication.

  - q: Can I add authentication to the A2A endpoint?
    a: Yes. Create an AI Policy like [OpenID Connect](/ai-gateway/policies/openid-connect/) for authentication and attach it to the agent. The AI Agent entity handles A2A protocol concerns independently of authentication.

  - q: How do I enable request/response logging?
    a: Set `config.logging.payloads` to `true` and `config.logging.statistics` to `true` in the agent config to log A2A request and response bodies along with metrics.

---

## Create an AI Agent entity

Create an [AI Agent](/ai-gateway/entities/ai-agent/) entity that proxies A2A traffic to your upstream agent.

<!-- vale off -->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/agents
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  display_name: Kong Air Flight Booking Agent
  name: kongair-flight-booking-agent
  type: a2a
  enabled: true
  config:
    url: http://a2a-agent:10000
    route:
      paths:
        - /a2a
      methods:
        - POST
      protocols:
        - http
        - https
      strip_path: true
    logging:
      payloads: true
      statistics: true
      max_payload_size: 1048576
    max_request_body_size: 8388608
{% endkonnect_api_request %}
<!-- vale on -->

Save the agent ID from the response:

```bash
export AGENT_ID='your-agent-id-from-response'
```

The agent is now accessible at the `/a2a` route and proxies A2A JSON-RPC requests to the upstream agent running at `http://a2a-agent:10000`.

## Retrieve the Agent Card

A2A agents expose their capabilities through an Agent Card at the `/.well-known/agent-card.json` endpoint.

Retrieve it through the gateway:

```bash
curl -X GET "http://localhost:8000/a2a/.well-known/agent-card.json" \
  --no-progress-meter --fail-with-body
```

The response shows the agent's capabilities, skills, and supported protocols:

```json
{
  "name": "KongAir OpenAI Agent",
  "version": "1.0.0",
  "description": "An A2A-compatible agent powered by LangGraph and OpenAI that queries KongAir APIs for flights, routes, bookings, and loyalty info.",
  "protocolVersion": "0.3.0",
  "capabilities": {
    "pushNotifications": false,
    "streaming": false
  },
  "defaultInputModes": ["text", "text/plain"],
  "defaultOutputModes": ["text", "text/plain"],
  "preferredTransport": "JSONRPC",
  "url": "http://a2a-agent:10000/",
  "skills": [
    {
      "id": "search_routes",
      "name": "Search KongAir routes",
      "description": "Find KongAir routes between airports.",
      "examples": [
        "Show me routes from SFO to JFK",
        "Find flights from LHR to SFO"
      ],
      "tags": ["kongair", "flights", "travel", "routes"]
    }
  ]
}
```

## Send an A2A request

Send a `message/send` JSON-RPC request to test the agent:

```bash
curl -X POST "http://localhost:8000/a2a" \
  -H "Content-Type: application/json" \
  --json '{
    "jsonrpc": "2.0",
    "id": "1",
    "method": "message/send",
    "params": {
      "message": {
        "kind": "message",
        "messageId": "msg-001",
        "role": "user",
        "parts": [
          {
            "kind": "text",
            "text": "What flights are available on route KA-123?"
          }
        ]
      }
    }
  }'
```

A successful response (status 200) contains the agent's reply:

```json
{
  "jsonrpc": "2.0",
  "id": "1",
  "result": {
    "message": {
      "kind": "message",
      "messageId": "msg-002",
      "role": "assistant",
      "parts": [
        {
          "kind": "text",
          "text": "Route KA-123 has 5 available flights today..."
        }
      ]
    }
  }
}
```

