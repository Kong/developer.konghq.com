---
title: "Forward proxy support"
content_type: reference
layout: reference

description: "Route outbound traffic from {{site.ai_gateway}} plugins through a forward proxy to operate in network-isolated environments without breaking load balancing, streaming, WebSocket, or HTTP/2."

breadcrumbs:
  - /ai-gateway/

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

tools:
  - deck
  - admin-api
  - konnect-api
  - kic
  - terraform

# TODO: confirm the minimum Gateway version with engineering before publishing.
# min_version:
#   gateway: '<version>'

plugins:
  - ai-proxy-advanced
  - ai-semantic-cache
  - ai-semantic-prompt-guard
  - ai-semantic-response-guard
  - ai-rag-injector
  - ai-prompt-compressor
  - ai-sanitizer
  - ai-aws-guardrails
  - ai-azure-content-safety
  - ai-lakera-guard
  - ai-gcp-model-armor
  - ai-custom-guardrail

tags:
  - ai
  - network
  - security

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/
  - text: Forward Proxy Advanced plugin
    url: /plugins/forward-proxy/
---

## What is forward proxy support?

In network-isolated deployments, {{site.ai_gateway}} cannot open direct outbound connections to LLM providers or auxiliary services. Forward proxy support lets {{site.ai_gateway}} plugins route their outbound requests through a controlled HTTP forward proxy so inference traffic, semantic operations, and guardrail checks continue to work behind strict egress policy.

A shared `proxy_config` record, added to every affected {{site.ai_gateway}} plugin, names the proxy host, port, scheme, and optional credentials. When configured, all outbound requests issued by that plugin go through the proxy. Existing capabilities such as [load balancing](/ai-gateway/load-balancing/), health checking, [streaming](/ai-gateway/streaming/), WebSocket, and HTTP/2 continue to work.

## How forward proxy support works

{{site.ai_gateway}} plugins issue three categories of outbound request. `proxy_config` applies to all three, though the underlying mechanism differs depending on where the request originates.

<!--vale off-->
{% mermaid %}
flowchart LR
  subgraph Gateway_Group[Kong AI Gateway]
    subgraph Plugins[AI Plugins]
      AIProxy[AI Proxy Advanced]
      Semantic[Semantic plugins]
      Transform[Compressor and sanitizer]
      Guardrails[Guardrail plugins]
    end
  end
  Client --> AIProxy
  Client --> Semantic
  Client --> Transform
  Client --> Guardrails
  AIProxy -- inference ---> Proxy[Forward proxy]
  Semantic -- embeddings ---> Proxy
  Transform -- compression and sanitization --> Proxy
  Guardrails -- guardrail checks --> Proxy
  Proxy ---> LLM[LLM providers]
  Proxy ---> Aux[Auxiliary services]
  style Plugins stroke-dasharray: 5 5
{% endmermaid %}
> _Figure 1: Outbound traffic from {{site.ai_gateway}} plugins routed through a forward proxy._
<!--vale on-->

The three request categories are:

- **Inference traffic**: requests from clients to LLM providers, proxied by [AI Proxy Advanced](/plugins/ai-proxy-advanced/). This is the majority of {{site.ai_gateway}} traffic. It runs through the native {{site.base_gateway}} upstream path, so load balancing, health checks, retries, streaming, WebSocket, and HTTP/2 all continue to function when the proxy is active.
- **Embeddings and semantic operations**: requests from semantic plugins to the embeddings service used for cache lookups, RAG retrieval, and prompt or response guarding.
- **Security and transformation calls**: requests from guardrail, sanitizer, and compressor plugins to their external services (AWS Bedrock Guardrails, Azure Content Safety, Lakera, GCP Model Armor, or a custom endpoint).

When `proxy_config` is set on a plugin, every outbound request that plugin issues goes through the configured proxy.

## Supported plugins

The following plugins expose `proxy_config`. The record structure and behavior are identical across all of them.

<!--vale off-->
{% table %}
columns:
  - title: Traffic
    key: traffic
  - title: Plugins
    key: plugins
rows:
  - traffic: "Inference requests to LLM providers"
    plugins: |
      - [AI Proxy Advanced](/plugins/ai-proxy-advanced/)
  - traffic: "Embeddings and semantic operations"
    plugins: |
      - [AI Semantic Cache](/plugins/ai-semantic-cache/)
      - [AI Semantic Prompt Guard](/plugins/ai-semantic-prompt-guard/)
      - [AI Semantic Response Guard](/plugins/ai-semantic-response-guard/)
      - [AI RAG Injector](/plugins/ai-rag-injector/)
  - traffic: "Prompt compression and sanitization"
    plugins: |
      - [AI Prompt Compressor](/plugins/ai-prompt-compressor/)
      - [AI Sanitizer](/plugins/ai-sanitizer/)
  - traffic: "Guardrail services"
    plugins: |
      - [AI AWS Guardrails](/plugins/ai-aws-guardrails/)
      - [AI Azure Content Safety](/plugins/ai-azure-content-safety/)
      - [AI Lakera Guard](/plugins/ai-lakera-guard/)
      - [AI GCP Model Armor](/plugins/ai-gcp-model-armor/)
      - [AI Custom Guardrail](/plugins/ai-custom-guardrail/)
{% endtable %}
<!--vale on-->

## proxy_config fields

Every plugin in the supported list accepts the same `proxy_config` record at the top level of its `config` block.

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
    description: "Password for proxy authentication. Optional. Encrypted at rest and referenceable from a [Vault](/gateway/entities/vault/)."
  - field: "`https_verify`"
    type: "boolean"
    description: "Whether to verify the forward proxy's TLS certificate when `proxy_scheme` is `https`. Defaults to `false`."
{% endtable %}
<!--vale on-->

Two validation rules apply to the record:

- `http_proxy_host` and `http_proxy_port` must both be set or both be absent.
- `https_proxy_host` and `https_proxy_port` must both be set or both be absent.

{:.warning}
> When `proxy_scheme` is `https` and the global `tls_certificate_verify` flag is enabled, `https_verify` cannot be set to `false`.

## Configuration

The minimal configuration adds a `proxy_config` block to any supported plugin. The same block applies unchanged across plugins: configure it once per plugin instance that needs to reach external services through the proxy.

{% entity_example %}
type: plugin
data:
  name: ai-proxy-advanced
  config:
    targets:
      - model:
          provider: openai
          name: gpt-5.1
        auth:
          header_name: Authorization
          header_value: Bearer ${openai_key}
        route_type: llm/v1/chat
    proxy_config:
      http_proxy_host: proxy.internal
      http_proxy_port: 3128
      https_proxy_host: proxy.internal
      https_proxy_port: 3128
      proxy_scheme: http
      auth_username: ${proxy_user}
      auth_password: ${proxy_password}
      https_verify: false
variables:
  openai_key:
    value: $OPENAI_API_KEY
    description: The API key to use to connect to OpenAI.
  proxy_user:
    value: $FORWARD_PROXY_USER
    description: Username for the corporate forward proxy.
  proxy_password:
    value: $FORWARD_PROXY_PASSWORD
    description: Password for the corporate forward proxy.
{% endentity_example %}

## Relationship to the Forward Proxy Advanced plugin

{{site.base_gateway}} also ships the [Forward Proxy Advanced plugin](/plugins/forward-proxy/) for routing non-AI upstream traffic through an intermediary HTTP proxy. That plugin takes over the request before the balancer phase runs, which works for standard Kong Services but breaks behavior that {{site.ai_gateway}} depends on: upstream load balancing, health check reporting, retries, WebSocket upgrades, and HTTP/2 request bodies.

{{site.ai_gateway}} plugins use `proxy_config` instead so the balancer phase continues to run normally. Load balancing across LLM targets, streaming, real-time API traffic, and HTTP/2 inference requests all remain functional when the forward proxy is active. Apply the Forward Proxy Advanced plugin to non-AI Services only; use `proxy_config` on any Service that serves traffic through an {{site.ai_gateway}} plugin.

## Limitations

- Connections to vector databases (pgvector, Redis Vector, Pinecone) use native database protocols rather than HTTP and are not routed through the forward proxy. If these connections must traverse a proxy, handle it at the network layer.
- The [AI Request Transformer](/plugins/ai-request-transformer/), [AI Response Transformer](/plugins/ai-response-transformer/), and [AI LLM as a Judge](/plugins/ai-llm-as-judge/) plugins keep their existing flat proxy fields (`http_proxy_host`, `http_proxy_port`, `https_proxy_host`, `https_proxy_port`) and do not accept a `proxy_config` record. Authentication to the proxy and HTTPS proxy schemes are not available on these three plugins.
