---
title: "Forward proxy support"
content_type: reference
layout: reference

description: "Route outbound traffic from {{site.ai_gateway}} Policies through a forward proxy to operate in network-isolated environments without breaking load balancing, streaming, WebSocket, or HTTP/2."

breadcrumbs:
  - /ai-gateway/

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - konnect-api


min_version:
  ai-gateway: '2.0'

tags:
  - ai
  - network
  - security

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
---

## What is forward proxy support?

In network-isolated deployments, {{site.ai_gateway}} cannot open direct outbound connections to LLM providers or auxiliary services. Forward proxy support lets you route outbound requests from AI Models and AI MCP Servers through a controlled HTTP forward proxy so that inference traffic, semantic operations, and guardrail checks continue to work behind a strict egress policy.

A `proxy` record can be added to the `config` that names the proxy host, port, scheme, excluded hosts, and optional credentials. When configured, all outbound requests issued by that AI Model or MCP Server are sent through the specified proxy host. Existing capabilities such as [load balancing](/ai-gateway/load-balancing/), health checking, [streaming](/ai-gateway/streaming/), WebSocket, and HTTP/2 continue to work.

## How forward proxy support works

{{site.ai_gateway}} sends three categories of outbound request. A `proxy` can be applied to all three, using a different mechanism depending on where the request originates.

The three request categories are:

- **Inference**: requests from clients to LLM providers, proxied by an [AI Model](/ai-gateway/entities/ai-model/) through the native {{site.base_gateway}} upstream path. This is the majority of {{site.ai_gateway}} traffic. Load balancing, health checks, retries, streaming, WebSocket, and HTTP/2 all continue to function when forward proxy support is active. Upstream keepalive is disabled while the forward proxy is active, so inference connections are not reused across requests targeting different upstream peers.
- **Identity auth**: cloud identity authentication issued by provider SDKs. AWS Bedrock SigV4 signing, Azure and GCP managed identity token acquisition, when targets require managed identity.
- **Auxiliary calls**: direct HTTP calls from semantic, RAG, guardrail, sanitizer, and compressor Policies to their external services. For example, an embeddings service, AWS Bedrock Guardrails, Azure Content Safety, Lakera, GCP Model Armor, or a configured custom endpoint.

<!--vale off-->
{% mermaid %}
flowchart LR
  Client --> AIModel
  Client --> Aux
  subgraph Gateway_Group[Kong AI Gateway]
    subgraph Policies[AI Entities]
      AIModel[AI Model]
      Aux[AI MCP Server]
    end
  end
  AIModel -- inference --> Proxy[Forward proxy]
  AIModel -- "identity auth" --> Proxy
  Aux -- "MCP calls" --> Proxy
  Proxy --> LLM[LLM providers]
  Proxy --> CloudAPI[Cloud platform APIs]
  Proxy --> AuxSvc[Upstream MCP]
  style Policies stroke-dasharray: 5 5
{% endmermaid %}
> _Figure 1: Outbound traffic from {{site.ai_gateway}} Policies routed through a forward proxy._
<!--vale on-->

When `proxy` is set on an entity, every outbound request that entity issues goes through the configured proxy.

## Relationship to the Forward Proxy Advanced plugin

{{site.base_gateway}} also provides the [Forward Proxy Advanced plugin](/plugins/forward-proxy/) for routing non-AI upstream traffic through an intermediary HTTP proxy. For non-AI services use the Forward Proxy Advanced plugin.

The Forward Proxy Advanced plugin takes over the request before the balancer phase runs, which works for standard Kong Services but not with behavior that {{site.ai_gateway}} depends on: upstream load balancing, health check reporting, retries, WebSocket upgrades, and HTTP/2 request bodies.

For any Service that serves traffic through an AI Model or MCP Server you should use `proxy` instead, so the balancer phase continues to run normally. Load balancing across LLM targets, streaming, real-time API traffic, and HTTP/2 inference requests all remain functional when the forward proxy is active and you have configured `proxy`.

## Proxy configuration fields

AI Models and MCP Servers accept the same `proxy` records at the top level of their `config` block.

<!--vale off-->
{% table %}
columns:
  - title: Field
    key: field
  - title: Type
    key: type
  - title: Description
    key: description
rows:
  - field: "`http_proxy_host`"
    type: "host"
    description: "Hostname of the forward proxy used for HTTP upstreams. Must be set together with `http_proxy_port`."
  - field: "`http_proxy_port`"
    type: "port"
    description: "Port of the forward proxy used for HTTP upstreams. Must be set together with `http_proxy_host`."
  - field: "`https_proxy_host`"
    type: "host"
    description: "Hostname of the forward proxy used for HTTPS upstreams. Must be set together with `https_proxy_port`."
  - field: "`https_proxy_port`"
    type: "port"
    description: "Port of the forward proxy used for HTTPS upstreams. Must be set together with `https_proxy_host`."
  - field: "`proxy_scheme`"
    type: "string"
    description: "Scheme used to connect to the forward proxy itself. One of `http` or `https`. Defaults to `http`."
  - field: "`auth_username`"
    type: "string"
    description: "Username for proxy authentication. Optional. Referenceable from a [Vault](/gateway/entities/vault/)."
  - field: "`auth_password`"
    type: "string"
    description: "Password for proxy authentication. Optional. Encrypted at rest and referenceable from an [AI Vault](/gateway/entities/vault/)."
  - field: "`no_proxy`"
    type: "list"
    description: "Comma-separated list of hosts that should not be proxied."
{% endtable %}
<!--vale on-->

Two validation rules apply to the record:

- `http_proxy_host` and `http_proxy_port` must both be set or both be absent.
- `https_proxy_host` and `https_proxy_port` must both be set or both be absent.

## Configuration

### Set up a forward proxy

You can use [Squid](https://www.squid-cache.org/) to create a simple forward proxy for testing. 

In the following examples `secure.mycompany` is used as the `visible_hostname` for the forward proxy.

1. Create minimal config file for Squid:
  ```
  echo '
  # Allow your local machine
  acl localnet src 172.0.0.0/8     # Docker bridge network range

  acl SSL_ports port 443
  acl Safe_ports port 80 443

  http_access deny !Safe_ports
  http_access allow localnet
  http_access allow localhost
  http_access deny all

  http_port 3128

  access_log /var/log/squid/access.log combined
  cache_log /var/log/squid/cache.log
  ' > squid.conf
  ```
1. Create a docker compose file:
  ```
  echo '
  services:
  squid:
    image: ubuntu/squid
    container_name: squid
    ports:
      - "3128:3128"
    volumes:
      - ./squid.conf:/etc/squid/squid.conf:ro
    networks:
      proxy-net:
        aliases:
          - secure.mycompany   # ← the named host

  networks:
    proxy-net:
      driver: bridge
  ' > docker-compose.yml
  ```
1. Add the  proxy to your hosts:
  ```
  echo "127.0.0.1   secure.mycompany" | sudo tee -a /etc/hosts
  ```
1. Run Squid using docker:
  ```
  docker compose up -d
  ```

### Gateway

{% include md/ai-gateway/v2/konnect-aigw-setup.md %}

### AI Model

1. Create an [AI Provider](/ai-gateway/entities/ai-provider/) entity to define your LLM service and store authentication credentials:

  <!-- vale off -->
  {% konnect_api_request %}
  url: /v1/ai-gateways/$AI_GATEWAY_ID/providers
  status_code: 201
  method: POST
  headers:
    - 'Content-Type: application/json'
    - 'Accept: application/json, application/problem+json'
  body:
    type: openai
    display_name: generic-openai
    name: generic-openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: Bearer $OPENAI_API_KEY
  {% endkonnect_api_request %}
  <!-- vale on -->

1. Create an [AI Model](/ai-gateway/entities/ai-model/) entity and specify your forward proxy host:

  <!-- vale off -->
  {% konnect_api_request %}
  url: /v1/ai-gateways/$AI_GATEWAY_ID/models
  status_code: 201
  method: POST
  headers:
    - 'Content-Type: application/json'
    - 'Accept: application/json, application/problem+json'
  body:
    display_name: my-gpt-4o
    name: my-gpt-4o
    type: model
    formats:
      - type: openai
    config:
      route:
        paths:
          - /v1
      model: {}
      proxy:
        http_proxy_host: secure.mycompany
        http_proxy_port: 443
        proxy_scheme: http
    targets:
      - name: gpt-4o
        provider: generic-openai
        config:
          type: openai
    policies: []
    capabilities:
      - generate
  {% endkonnect_api_request %}
  <!-- vale on -->

1. Send a chat request, this will be forwarded to your proxy service and return an error:

  <!-- vale off -->
  {% validation request-check %}
  url: /v1/chat/completions
  status_code: 200
  method: POST
  headers:
      - 'Accept: application/json'
      - 'Content-Type: application/json'
      - 'Authorization: Bearer $OPENAI_API_KEY'
  body:
    messages:
    - role: "user"
      content: "Say this is a test!"
  {% endvalidation %}
  <!-- vale on -->

1. Examine the Squid logs to verify your requests:
  ```
  docker exec -it squid tail -f /var/log/squid/access.log
  ```

### AI MCP Server

1. Create an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) entity that exposes the [WeatherAPI](https://www.weatherapi.com/) through a single MCP tool:

  <!-- vale off -->
  {% konnect_api_request %}
  url: /v1/ai-gateways/$AI_GATEWAY_ID/mcp-servers
  status_code: 201
  method: POST
  headers:
    - 'Content-Type: application/json'
    - 'Accept: application/json, application/problem+json'
  body:
    display_name: Weather API
    name: weather-mcp
    type: conversion-listener
    enabled: true
    policies: []
    acl_attribute_type: consumer
    acls:
      allow:
        - __never_match__
    default_tool_acls:
      deny:
        - __never_match__
    config:
      url: https://api.weatherapi.com/v1/current.json
      route:
        paths:
          - /weather
      logging:
        payloads: false
        statistics: true
      server:
        timeout: 60000
      proxy:
        http_proxy_host: secure.mycompany
        http_proxy_port: 8080
        proxy_scheme: http
    tools:
      - name: get-current-weather
        description: Get current weather for a location
        method: GET
        path: /weather
        query:
          key:
            - $WEATHERAPI_API_KEY
        parameters:
          - name: q
            in: query
            required: true
            schema:
              type: string
            description: Location query. Accepts US Zipcode, UK Postcode, Canada Postalcode, IP address, latitude/longitude, or city name.
  {% endkonnect_api_request %}
  <!-- vale on -->

1. Call `get-current-weather`, this will be forwarded to your proxy service and return an error:

  ```sh
  curl -i -X POST http://localhost:8000/weather \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json, text/event-stream' \
    --data '{
      "jsonrpc":"2.0",
      "id":1,
      "method":"tools/call",
      "params":{
        "name":"get-current-weather",
        "arguments":{
          "query_q":"London"
        }
      }
    }'
  ```

1. Examine the Squid logs to verify your requests:
  ```
  docker exec -it squid tail -f /var/log/squid/access.log
  ```

## Supported Policies

When forward proxy support is enabled on AI Models and MCP Servers this effects Policies applied to that entity.

The following Policies are supported:

<!--vale off-->
{% table %}
columns:
  - title: Traffic
    key: traffic
  - title: Policies
    key: policies
  - title: Proxied destination
    key: service
rows:
  - traffic: "Embeddings and semantic operations"
    policies: |
      - [AI Semantic Cache](ai-gateway/policies/ai-semantic-cache/)
      - [AI Semantic Prompt Guard](ai-gateway/policies/ai-semantic-prompt-guard/)
      - [AI Semantic Response Guard](ai-gateway/policies/ai-semantic-response-guard/)
      - [AI RAG Injector](ai-gateway/policies/ai-rag-injector/)
    service: "The configured embeddings service"
  - traffic: "Prompt compression and sanitization"
    policies: |
      - [AI Prompt Compressor](ai-gateway/policies/ai-prompt-compressor/)
      - [AI Sanitizer](ai-gateway/policies/ai-sanitizer/)
    service: "The configured `compressor_url` or `sanitizer_url`"
  - traffic: "Guardrail services"
    policies: |
      - [AI AWS Guardrails](ai-gateway/policies/ai-aws-guardrails/)
      - [AI Azure Content Safety](ai-gateway/policies/ai-azure-content-safety/)
      - [AI Lakera Guard](ai-gateway/policies/ai-lakera-guard/)
      - [AI GCP Model Armor](ai-gateway/policies/ai-gcp-model-armor/)
      - [AI Custom Guardrail](ai-gateway/policies/ai-custom-guardrail/)
    service: "Managed or custom guardrail service"
{% endtable %}
<!--vale on-->

## Limitations

- Connections to vector databases (such as pgvector, Redis Vector, or Pinecone) use native database protocols rather than HTTP and are not routed through the forward proxy. If these connections must traverse a forward proxy, you should handle it at the network layer.
- The [AI Request Transformer](/ai-gateway/policies/ai-request-transformer/), [AI Response Transformer](/ai-gateway/policies/ai-response-transformer/), and [AI LLM as a Judge](/ai-gateway/policies/ai-llm-as-judge/) Policies keep their existing flat proxy fields (`http_proxy_host`, `http_proxy_port`, `https_proxy_host`, `https_proxy_port`) and do not accept a `proxy` record. They do not expose `auth_username`, `auth_password`, `proxy_scheme`, or `https_verify`, so proxy authentication and HTTPS-scheme proxies are unavailable for their traffic.
