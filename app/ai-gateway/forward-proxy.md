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

In network-isolated deployments, {{site.ai_gateway}} cannot open direct outbound connections to LLM providers or auxiliary services. Forward proxy support lets {{site.ai_gateway}} Policys route their outbound requests through a controlled HTTP forward proxy so that inference traffic, semantic operations, and guardrail checks continue to work behind a strict egress policy.

A shared `proxy_config` record can be added to each {{site.ai_gateway}} Policy that names the proxy host, port, scheme, and optional credentials. When configured, all outbound requests issued by that Policy go through the proxy. Existing capabilities such as [load balancing](/ai-gateway/load-balancing/), health checking, [streaming](/ai-gateway/streaming/), WebSocket, and HTTP/2 continue to work.

## How forward proxy support works

{{site.ai_gateway}} Policies issue three categories of outbound request. `proxy_config` applies to all three, using a different mechanism depending on where the request originates.

The three request categories are:

- **Inference**: requests from clients to LLM providers, proxied by [AI Proxy Advanced](ai-gateway/policies/ai-proxy-advanced/) through the native {{site.base_gateway}} upstream path. This is the majority of {{site.ai_gateway}} traffic. Load balancing, health checks, retries, streaming, WebSocket, and HTTP/2 all continue to function when forward proxy support is active. Upstream keepalive is disabled while the forward proxy is active, so inference connections are not reused across requests targeting different upstream peers.
- **Identity auth**: cloud identity authentication issued by provider SDKs. AWS Bedrock SigV4 signing, Azure and GCP managed identity token acquisition, when targets require managed identity.
- **Auxiliary calls**: direct HTTP calls from semantic, RAG, guardrail, sanitizer, and compressor Policies to their external services. For example, an embeddings service, AWS Bedrock Guardrails, Azure Content Safety, Lakera, GCP Model Armor, or a configured custom endpoint.

<!--vale off-->
{% mermaid %}
flowchart LR
  Client --> AIProxy
  Client --> Aux
  subgraph Gateway_Group[Kong AI Gateway]
    subgraph Policies[AI Policies]
      AIProxy[AI Proxy Advanced]
      Aux[Auxiliary Policies]
    end
  end
  AIProxy -- inference --> Proxy[Forward proxy]
  AIProxy -- "identity auth" --> Proxy
  Aux -- "auxiliary calls" --> Proxy
  Proxy --> LLM[LLM providers]
  Proxy --> CloudAPI[Cloud platform APIs]
  Proxy --> AuxSvc[Auxiliary services]
  style Policies stroke-dasharray: 5 5
{% endmermaid %}
> _Figure 1: Outbound traffic from {{site.ai_gateway}} Policies routed through a forward proxy._
<!--vale on-->

When `proxy_config` is set on a Policy, every outbound request that Policy issues goes through the configured proxy.

## Relationship to the Forward Proxy Advanced plugin

{{site.base_gateway}} also provides the [Forward Proxy Advanced plugin](/plugins/forward-proxy/) for routing non-AI upstream traffic through an intermediary HTTP proxy. For non-AI services use the Forward Proxy Advanced plugin.

The Forward Proxy Advanced plugin takes over the request before the balancer phase runs, which works for standard Kong Services but not with behavior that {{site.ai_gateway}} depends on: upstream load balancing, health check reporting, retries, WebSocket upgrades, and HTTP/2 request bodies.

For any Service that serves traffic through a {{site.ai_gateway}} Policy you should use `proxy_config` instead, so the balancer phase continues to run normally. Load balancing across LLM targets, streaming, real-time API traffic, and HTTP/2 inference requests all remain functional when the forward proxy is active and you have configured `proxy_config`. 

## Supported Policies

`proxy_config` is set per-Policy. Enabling forward proxy support on AI Proxy Advanced does not apply to other {{site.ai_gateway}} Policies attached to the same Route. You should configure it on every Policy whose external calls need to traverse the forward proxy.

The following Policies expose `proxy_config`. The record structure and behavior are identical across all of them.

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
  - traffic: "Inference requests to LLM providers"
    policies: |
      - [AI Proxy Advanced](ai-gateway/policies/ai-proxy-advanced/)
    service: "LLM provider APIs"
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

## proxy_config fields

Every Policy in the supported list accepts the same `proxy_config` record at the top level of its `config` block.

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

{:.info}
> `https_verify` defaults to `false`. When `proxy_scheme` is `https`, set `https_verify: true` in production so the proxy's TLS certificate is validated.

{:.warning}
> When `proxy_scheme` is `https` and the global `tls_certificate_verify` flag is enabled, `https_verify` cannot be set to `false`. Config load fails.

## Configuration

The minimal configuration adds a `proxy_config` block to any supported Policy. The same block applies unchanged across Policies: configure it once per Policy instance that needs to reach external services through the proxy.


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

## Limitations

- Connections to vector databases (such as pgvector, Redis Vector, or Pinecone) use native database protocols rather than HTTP and are not routed through the forward proxy. If these connections must traverse a forward proxy, you should handle it at the network layer.
- The [AI Request Transformer](ai-gateway/policies/ai-request-transformer/), [AI Response Transformer](ai-gateway/policies/ai-response-transformer/), and [AI LLM as a Judge](ai-gateway/policies/ai-llm-as-judge/) Policies keep their existing flat proxy fields (`http_proxy_host`, `http_proxy_port`, `https_proxy_host`, `https_proxy_port`) and do not accept a `proxy_config` record. They do not expose `auth_username`, `auth_password`, `proxy_scheme`, or `https_verify`, so proxy authentication and HTTPS-scheme proxies are unavailable for their traffic.
