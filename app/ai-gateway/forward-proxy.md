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

In network-isolated deployments, {{site.ai_gateway}} cannot open direct outbound connections to LLM providers or auxiliary services. Forward proxy support lets you route outbound requests from [AI Models](/ai-gateway/entities/ai-model/) and [AI MCP Servers](/ai-gateway/entities/ai-mcp-server/) through a controlled HTTP forward proxy so that inference traffic, semantic operations, and guardrail checks continue to work behind a strict egress policy.

Outbound requests issued by an AI Model or MCP Server can be sent through the specified proxy host by setting a `proxy` record in their `config` that names the proxy host, port, scheme, excluded hosts, and optionally credentials. Existing capabilities such as [load balancing](/ai-gateway/load-balancing/), health checking, [streaming](/ai-gateway/streaming/), WebSocket, and HTTP/2 continue to work.

## How forward proxy support works

{{site.ai_gateway}} sends three categories of outbound request. A `proxy` can be applied to all three, using a different mechanism depending on where the request originates.

The three request categories are:

- **Inference**: Requests from clients to LLM providers, proxied by an [AI Model](/ai-gateway/entities/ai-model/) through the {{site.ai_gateway}}. This is the majority of {{site.ai_gateway}} traffic. Load balancing, health checks, retries, streaming, WebSocket, and HTTP/2 all continue to function when forward proxy support is active. Upstream keepalive is disabled while the forward proxy is active, so inference connections are not reused across requests targeting different upstream peers.
- **Identity auth**: Cloud identity authentication issued by provider SDKs. This includes, AWS Bedrock SigV4 signing, Azure and GCP managed identity token acquisition when targets require managed identity.
- **Auxiliary calls**: Direct HTTP calls from semantic, RAG, guardrail, sanitizer, and compressor Policies to their external services. For example, an embeddings service, AWS Bedrock Guardrails, Azure Content Safety, Lakera, GCP Model Armor, or a configured custom endpoint.

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

When `proxy` is set on an AI Model or MCP Server entity, every outbound request that entity issues goes through the configured proxy.

## Relationship to the Forward Proxy Advanced plugin

{{site.base_gateway}} also provides the [Forward Proxy Advanced plugin](/plugins/forward-proxy/) for routing non-AI upstream traffic through an intermediary HTTP proxy. For non-AI services use the Forward Proxy Advanced plugin.

The Forward Proxy Advanced plugin takes over the request before the balancer phase runs, which works for standard Gateway Services but not with behavior that {{site.ai_gateway}} depends on: upstream load balancing, health check reporting, retries, WebSocket upgrades, and HTTP/2 request bodies.

For {{site.ai_gateway}} traffic through an AI Model or MCP Server entity, you should use the native `proxy` configuration instead. This ensures the balancer phase continues to run normally. Load balancing across LLM targets, streaming, real-time API traffic, and HTTP/2 inference requests all remain functional when the forward proxy is active and you have configured `proxy`.

## Proxy configuration fields

AI Models accept a `proxy` record at the top level of their `config` block. MCP Servers only accept it when their `type` is `passthrough-listener`. `conversion-listener` and `listener` type MCP Servers do not currently support forward proxy configuration at all.

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
  - field: "`http_proxy`"
    type: "object"
    description: "The forward proxy used for HTTP upstreams. An object with `host` and `port` fields."
  - field: "`https_proxy`"
    type: "object"
    description: "The forward proxy used for HTTPS upstreams. An object with `host` and `port` fields."
  - field: "`proxy_scheme`"
    type: "string"
    description: "Scheme used to connect to the forward proxy itself. Currently only `http` is supported. Defaults to `http`."
  - field: "`auth`"
    type: "object"
    description: "Credentials for proxy authentication. An object with `username` and `password` fields. Both are optional and referenceable from an [AI Vault](/ai-gateway/entities/ai-vault/#how-do-i-reference-secrets)."
  - field: "`no_proxy`"
    type: "string"
    description: "Comma-separated list of hosts that should not be proxied."
{% endtable %}
<!--vale on-->

Two validation rules apply to the record:

- If `http_proxy` is set, both `host` and `port` must be set.
- If `https_proxy` is set, both `host` and `port` must be set.

### Supported Policies

You can also configure AI Policies to use your forward proxy by setting the same `proxy` records at the top level of their `config` block.

The following AI Policies are supported:

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
      - [AI Semantic Cache](/ai-gateway/policies/ai-semantic-cache/)
      - [AI Semantic Prompt Guard](/ai-gateway/policies/ai-semantic-prompt-guard/)
      - [AI Semantic Response Guard](/ai-gateway/policies/ai-semantic-response-guard/)
    service: "The configured embeddings service"
  - traffic: "Prompt compression and sanitization"
    policies: |
      - [AI Prompt Compressor](/ai-gateway/policies/ai-prompt-compressor/)
      - [AI Sanitizer](/ai-gateway/policies/ai-sanitizer/)
    service: "The configured `compressor_url` or `sanitizer_url`"
  - traffic: "Guardrail services"
    policies: |
      - [AI AWS Guardrails](/ai-gateway/policies/ai-aws-guardrails/)
      - [AI Azure Content Safety](/ai-gateway/policies/ai-azure-content-safety/)
      - [AI Lakera Guard](/ai-gateway/policies/ai-lakera-guard/)
      - [AI GCP Model Armor](/ai-gateway/policies/ai-gcp-model-armor/)
      - [AI Custom Guardrail](/ai-gateway/policies/ai-custom-guardrail/)
    service: "Managed or custom guardrail service"
{% endtable %}
<!--vale on-->

## Configuration

### Set up a forward proxy

You can use [Squid](https://www.squid-cache.org/) to create a simple forward proxy for testing.

Squid runs as its own Docker container, separate from the {{site.ai_gateway}} data plane container. In the following examples, the data plane reaches Squid through `host.docker.internal`, the special hostname that Docker Desktop and OrbStack resolve to the host machine from inside any container. This works because the compose file below publishes Squid's port to the host, so any container — including the {{site.ai_gateway}} data plane, which runs in its own separate Docker network — can reach it via the host machine, without needing to share a Docker network or edit your machine's hosts file.

{:.warning}
> In a production deployment your forward proxy should authenticate users, including {{site.ai_gateway}}.  To do this. set `auth_username` and `auth_password`. You can reference secrets from an [AI Vault](/ai-gateway/entities/ai-vault/#how-do-i-reference-secrets).

1. Create a minimal config file for Squid:

    ```
    echo '
    # Allow your local machine. Different container runtimes (Docker Desktop, OrbStack, Colima)
    # allocate bridge networks in different private ranges, so this allows all of them.
    acl localnet src 10.0.0.0/8
    acl localnet src 172.16.0.0/12
    acl localnet src 192.168.0.0/16

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
    ' > docker-compose.yml
    ```
1. Run Squid using docker:

    ```
    docker compose up -d
    ```

### {{site.ai_gateway}}

{% include md/ai-gateway/v2/konnect-aigw-setup.md %}

### AI Model

1. Create an [AI Provider](/ai-gateway/entities/ai-model-provider/) entity to define your LLM service and store authentication credentials:

    ```
    kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
    _defaults:
      kongctl:
        namespace: ai-gateway-get-started

    ai_gateways:
      - ref: ai-quickstart
        name: ai-quickstart
        display_name: "ai-quickstart"

    ai_gateway_model_providers:
      - ref: generic-anthropic
        ai_gateway: ai-quickstart
        name: generic-anthropic
        display_name: "generic-anthropic"
        type: anthropic
        config:
          auth:
            type: basic
            headers:
              - name: x-api-key
                value: !env ANTHROPIC_API_KEY
    EOF
    ```

1. Create an [AI Model](/ai-gateway/entities/ai-model/) entity and specify your forward proxy host:

    ```
    kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
    _defaults:
      kongctl:
        namespace: ai-gateway-get-started

    ai_gateways:
      - ref: ai-quickstart
        name: ai-quickstart
        display_name: "ai-quickstart"

    ai_gateway_models:
      - ref: my-claude
        ai_gateway: ai-quickstart
        name: my-claude
        display_name: "my-claude"
        type: model
        formats:
          - type: anthropic
        config:
          route:
            paths:
              - /
          proxy:
            http_proxy:
              host: host.docker.internal
              port: 3128
            https_proxy:
              host: host.docker.internal
              port: 3128
            proxy_scheme: http
          model:
            alias: my-claude
        targets:
          - name: claude-opus-4-8
            provider: generic-anthropic
            config:
              type: anthropic
        policies: []
        capabilities:
          - generate
    EOF
    ```

1. Send a chat request. This will be forwarded through your proxy service to Anthropic:

   <!-- vale off -->
   {% capture chat-request %}
   {% validation request-check %}
   url: /v1/messages
   status_code: 200
   method: POST
   headers:
     - 'Accept: application/json'
     - 'Content-Type: application/json'
     - 'Authorization: Bearer $ANTHROPIC_API_KEY'
   body:
     model: my-claude
     max_tokens: 100
     messages:
     - role: "user"
       content: "Say this is a test!"
   {% endvalidation %}
   {% endcapture %}
   {{ chat-request | indent: 3 }}
   <!-- vale on -->

1. Examine the Squid logs to verify your requests:

    ```
    docker exec -it squid tail -f /var/log/squid/access.log
    ```

### AI MCP Server

1. Create an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) entity that exposes the [WeatherAPI](https://www.weatherapi.com/) through a single MCP tool:

   <!-- vale off -->
   {% capture mcp-server %}
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
   {% endcapture %}
   {{ mcp-server | indent: 3 }}
   <!-- vale on -->

1. This MCP Server does not route through your forward proxy, since `conversion-listener` doesn't support it. Calling `get-current-weather` reaches WeatherAPI directly:

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

## Limitations

- Connections to vector databases (such as pgvector, Redis Vector, or Pinecone) use native database protocols rather than HTTP and are not routed through the forward proxy. If these connections must traverse a forward proxy, you should handle it at the network layer.
- The [AI Request Transformer](/ai-gateway/policies/ai-request-transformer/), [AI Response Transformer](/ai-gateway/policies/ai-response-transformer/), and [AI LLM as a Judge](/ai-gateway/policies/ai-llm-as-judge/) Policies keep their existing flat proxy fields (`http_proxy_host`, `http_proxy_port`, `https_proxy_host`, `https_proxy_port`) and do not accept a `proxy` record. They do not expose `auth_username`, `auth_password`, `proxy_scheme`, or `https_verify`, so proxy authentication and HTTPS-scheme proxies are unavailable for their traffic.
