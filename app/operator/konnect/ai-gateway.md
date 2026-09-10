---
title: "{{ site.ai_gateway_name }} with {{ site.operator_product_name }}"
description: "Understand the Kubernetes resources that make up an {{ site.ai_gateway_name }} deployment managed by {{ site.operator_product_name }}"
content_type: reference
layout: reference

breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: Key Concepts

products:
  - operator

min_version:
  operator: '2.3'

related_resources:
  - text: Deploy {{ site.ai_gateway_name }} with {{ site.operator_product_name }}
    url: /operator/get-started/ai-gateway/install/
  - text: "{{ site.ai_gateway_name }} overview"
    url: /ai-gateway/
  - text: AI Model Providers
    url: /ai-gateway/entities/ai-model-provider/
  - text: AI Models
    url: /ai-gateway/entities/ai-model/
  - text: AI Policies
    url: /ai-gateway/entities/ai-policy/
  - text: AI Data Plane Certificates
    url: /ai-gateway/entities/ai-data-plane-certificate/
  - text: AI Consumers
    url: /ai-gateway/entities/ai-consumer/
  - text: Load balancing with AI Proxy Advanced
    url: /ai-gateway/load-balancing/
  - text: Cross namespace references
    url: /operator/konnect/cross-namespace-references/

---

{{ site.operator_product_name }} manages {{ site.ai_gateway_name }} using a set of Kubernetes Custom Resource Definitions (CRDs). Each CRD maps to a concept in the {{ site.ai_gateway }} control plane; you declare the desired state in Kubernetes, and {{site.operator_product_name}} reconciles it with {{ site.konnect_short_name }}.

{{site.operator_product_name}} manages three distinct layers:

- **Control plane**: `KonnectAIGateway` provisions and owns the {{ site.ai_gateway }} control plane in {{ site.konnect_short_name }}. All other resources reference it as their parent.
- **Configuration resources**: `AIGatewayModelProvider`, `AIGatewayModel`, `AIGatewayPolicy`, `AIGatewayAuthStrategy`, `AIGatewayConsumer`, `AIGatewayConsumerCredential`, `AIGatewayConsumerGroup`, and `AIGatewayAgent` declare what the gateway does: which LLM providers to connect to, which model routes to expose, what Policies to enforce, which authentication schemes to accept, and which clients may access it.
- **Data plane**: `AIGatewayDataPlaneCertificate` and `AIGatewayDataPlane` run the traffic-handling binary inside your cluster. When you create an `AIGatewayDataPlane`, {{site.operator_product_name}} automatically provisions the mTLS certificate and registers it with the control plane.

## Resource model

The following table describes the resource model:
<!--vale off-->
{% table %}
columns:
  - title: Resource
    key: resource
  - title: API group
    key: api_group
  - title: Purpose
    key: purpose
rows:
  - resource: "`KonnectAIGateway`"
    api_group: "`konnect.konghq.com/v1alpha1`"
    purpose: Creates the {{ site.ai_gateway }} control plane in {{ site.konnect_short_name }}
  - resource: "`AIGatewayModelProvider`"
    api_group: "`aiconfiguration.konghq.com/v1alpha1`"
    purpose: Configures an upstream LLM provider (OpenAI, Anthropic, Azure, Gemini, etc.)
  - resource: "`AIGatewayModel`"
    api_group: "`aiconfiguration.konghq.com/v1alpha1`"
    purpose: Defines an AI Model Route, its capabilities, and which AI Provider targets it
  - resource: "`AIGatewayPolicy`"
    api_group: "`aiconfiguration.konghq.com/v1alpha1`"
    purpose: "Applies an AI Policy to the gateway (for example: prompt guard, sanitizer, rate limiting)"
  - resource: "`AIGatewayAuthStrategy`"
    api_group: "`aiconfiguration.konghq.com/v1alpha1`"
    purpose: Configures the gateway authentication scheme (`key-auth` or `openid-connect`)
  - resource: "`AIGatewayConsumer`"
    api_group: "`aiconfiguration.konghq.com/v1alpha1`"
    purpose: Registers a downstream client identity for authentication and access control
  - resource: "`AIGatewayConsumerCredential`"
    api_group: "`aiconfiguration.konghq.com/v1alpha1`"
    purpose: Attaches an API key credential to an `AIGatewayConsumer`
  - resource: "`AIGatewayConsumerGroup`"
    api_group: "`aiconfiguration.konghq.com/v1alpha1`"
    purpose: Groups AI Consumers together and applies shared AI Policies at the group level
  - resource: "`AIGatewayAgent`"
    api_group: "`aiconfiguration.konghq.com/v1alpha1`"
    purpose: Configures an agent endpoint for A2A or HTTP agent traffic
  - resource: "`AIGatewayMCPServer`"
    api_group: "`aiconfiguration.konghq.com/v1alpha1`"
    purpose: Exposes a REST API or an upstream MCP server as MCP tools
  - resource: "`AIGatewayDataPlaneCertificate`"
    api_group: "`aiconfiguration.konghq.com/v1alpha1`"
    purpose: Registers a TLS certificate used by the data plane to authenticate with the control plane (auto-created by `AIGatewayDataPlane`)
  - resource: "`AIGatewayDataPlane`"
    api_group: "`aigateway.konghq.com/v1alpha1`"
    purpose: Deploys the {{ site.ai_gateway }} data plane in Kubernetes and provisions the mTLS certificate automatically
{% endtable %}
<!--vale on-->

## How resources reference each other

All configuration resources anchor to the `KonnectAIGateway` as their root via `spec.aiGatewayRef`. Consumer credentials attach to the AI Consumer entities, not directly to the control plane.

1. `AIGatewayModelProvider.spec.aiGatewayRef` → `KonnectAIGateway`
2. `AIGatewayModel.spec.aiGatewayRef` → `KonnectAIGateway`
3. `AIGatewayModel.spec.apiSpec.model.targets[].provider` → `AIGatewayModelProvider` (by name)
4. `AIGatewayPolicy.spec.aiGatewayRef` → `KonnectAIGateway`
5. `AIGatewayAuthStrategy.spec.aiGatewayRef` → `KonnectAIGateway`
6. `AIGatewayConsumer.spec.aiGatewayRef` → `KonnectAIGateway`
7. `AIGatewayConsumerCredential.spec.aiGatewayConsumerRef` → `AIGatewayConsumer`
8. `AIGatewayConsumerGroup.spec.aiGatewayRef` → `KonnectAIGateway`
9. `AIGatewayAgent.spec.aiGatewayRef` → `KonnectAIGateway`
10. `AIGatewayMCPServer.spec.aiGatewayRef` → `KonnectAIGateway`
11. `AIGatewayMCPServer.spec.apiSpec.listener.sources[]` → other `AIGatewayMCPServer` resources (by name; `conversion-only` or `upstream-server` type only)
12. `AIGatewayDataPlaneCertificate.spec.aiGatewayRef` → `KonnectAIGateway`
13. `AIGatewayDataPlane.spec.controlPlaneRef` → `KonnectAIGateway`

## Supported providers

`AIGatewayModelProvider` supports the following upstream LLM providers via `spec.apiSpec.type`:

<!--vale off-->
{% table %}
columns:
  - title: Provider
    key: provider
  - title: "`type` value"
    key: type
rows:
  - provider: Anthropic
    type: "`anthropic`"
  - provider: AWS Bedrock
    type: "`bedrock`"
  - provider: Azure OpenAI
    type: "`azure`"
  - provider: Cerebras
    type: "`cerebras`"
  - provider: Cohere
    type: "`cohere`"
  - provider: DashScope (Alibaba)
    type: "`dashscope`"
  - provider: Databricks
    type: "`databricks`"
  - provider: DeepSeek
    type: "`deepseek`"
  - provider: Google Gemini
    type: "`gemini`"
  - provider: Google Vertex AI
    type: "`vertex`"
  - provider: Hugging Face
    type: "`huggingface`"
  - provider: Kimi
    type: "`kimi`"
  - provider: Llama2
    type: "`llama2`"
  - provider: Mistral
    type: "`mistral`"
  - provider: Ollama
    type: "`ollama`"
  - provider: OpenAI
    type: "`openai`"
  - provider: Vercel
    type: "`vercel`"
  - provider: vLLM
    type: "`vllm`"
  - provider: xAI
    type: "`xai`"
{% endtable %}
<!--vale on-->

## Working with resources

Each resource type is covered end-to-end in the getting started series:

- **AI Providers and AI Models**: [Deploy {{ site.ai_gateway_name }}](/operator/get-started/ai-gateway/deploy/) covers `AIGatewayModelProvider`, `AIGatewayModel`, and `AIGatewayDataPlane`.
- **AI Policies**: [Apply AI Policies](/operator/get-started/ai-gateway/policy/) covers `AIGatewayPolicy`, including global and model-scoped enforcement.
- **AI Auth Strategies and AI Consumers**: [Add AI Consumers](/operator/get-started/ai-gateway/consumers/) covers `AIGatewayAuthStrategy`, `AIGatewayConsumer`, `AIGatewayConsumerCredential`, and `AIGatewayConsumerGroup`.
- **AI Agents**: `AIGatewayAgent` supports `a2a` and `http` agent types. Set `spec.apiSpec.type` to the agent protocol and `spec.apiSpec.config.url` to the upstream agent URL.
- **Routing and load balancing**: [Route to a model using a selector](#route-to-a-model-using-a-selector) and [Load balancing across targets](#load-balancing-across-targets) cover `config.route.model` and `config.balancer` on `AIGatewayModel`.
- **MCP tools**: [Exposing tools with AIGatewayMCPServer](#exposing-tools-with-aigatewaymcpserver) covers the five `AIGatewayMCPServer` types.

## Route to a model using a selector

{{site.operator_product_name}} always places a model selector in front of an AI Model's targets, even when a single `AIGatewayModel` is the only one on its route. By default, the selector matches the request body's `model` field against the AI Model's own name (`spec.apiSpec.model.name`). **A request whose `model` value doesn't match never reaches any target** — it falls through instead of being proxied. This is why every request in the [deploy](/operator/get-started/ai-gateway/deploy/) and [policy](/operator/get-started/ai-gateway/policy/) guides includes `"model": "gpt-4o-mini"`: that value is what the selector uses to activate this AI Model, not just metadata for the upstream provider.

To accept a client-side alias instead of the AI Model's own name, set `config.route.model`:

- `values`: the alias to match, as a single-item list. When omitted, the AI Model's own name is used.
- `bodyParam`, `headerParam`, or `pathParam`: which part of the request to match the alias against — a JSON body property, a header, or a named regex capture group in `paths`, respectively. Set at most one of these; when none are set, the request body's `model` property is matched by default.

The following configuration accepts a client-side alias in the request body's `model` field:

```yaml
config:
  route:
    paths:
      - /v1
    model:
      values:
        - my-gpt-4o
```

With this configuration, a client that sends `"model": "my-gpt-4o"` in the request body is routed to this AI Model, regardless of the upstream provider model name on its targets.

To match on a header instead of the body, set `headerParam`:

```yaml
config:
  route:
    paths:
      - /v1
    model:
      headerParam: x-model-route
      values:
        - my-gpt-4o
```

A client that sends the header `x-model-route: my-gpt-4o` is routed to this AI Model.

{:.warning}
> **`config.route.model` is a different mechanism from `config.route.headers` and `config.route.paths`.** The latter are Kong's native route-matching criteria — they decide whether a request reaches this AI Model's route at all. `config.route.model` runs after the route matches, to select which AI Model's targets handle the request when multiple AI Models share a route. Setting `config.route.headers` to gate a route by header presence does not make that header usable as a model alias source, and combining the two produces a proxy error instead of the expected routing behavior.

## Load balancing across targets

An `AIGatewayModel` can define multiple `targets`, and `config.balancer` controls how requests are distributed across them once the AI Model is selected. Set `config.balancer.algorithm` to one of:

<!--vale off-->
{% table %}
columns:
  - title: Algorithm
    key: algorithm
  - title: Purpose
    key: purpose
rows:
  - algorithm: "`round-robin`"
    purpose: Distributes requests across targets by weight.
  - algorithm: "`consistent-hashing`"
    purpose: Routes requests with the same header value to the same target (sticky sessions).
  - algorithm: "`least-connections`"
    purpose: Routes to the target with the fewest in-flight requests.
  - algorithm: "`lowest-usage`"
    purpose: Routes to the target with the lowest measured token or cost usage.
  - algorithm: "`lowest-latency`"
    purpose: Routes to the target with the lowest observed latency.
  - algorithm: "`priority`"
    purpose: Routes to the highest-priority group of targets, falling back to lower-priority groups when a group is unavailable.
  - algorithm: "`semantic`"
    purpose: Routes based on similarity between the prompt and each target's `semanticDescription`, using an embeddings model and a vector database.
{% endtable %}
<!--vale on-->

See [Load balancing with AI Proxy Advanced](/ai-gateway/load-balancing/) for a full description of each algorithm's behavior and tradeoffs — the algorithms and their semantics are the same; only the configuration surface differs.

## Exposing tools with AIGatewayMCPServer

`AIGatewayMCPServer` exposes tools over the [Model Context Protocol](https://modelcontextprotocol.io/) (MCP), either by converting a REST API's endpoints into MCP tools, or by proxying an existing MCP server. Set `spec.apiSpec.type` to one of five types:

<!--vale off-->
{% table %}
columns:
  - title: Type
    key: type
  - title: Client-facing?
    key: client_facing
  - title: Purpose
    key: purpose
rows:
  - type: "`conversion-only`"
    client_facing: "No"
    purpose: Converts a REST API's endpoints into a named set of MCP tools. Not reachable directly — exposed through a `listener`'s `sources`.
  - type: "`upstream-server`"
    client_facing: "No"
    purpose: Registers an existing, third-party MCP server as a backend, with its own tool list. Not reachable directly — exposed through a `listener`'s `sources`.
  - type: "`listener`"
    client_facing: "Yes"
    purpose: Aggregates tools from one or more `conversion-only`/`upstream-server` resources (named in `sources`) and exposes them together at one route.
  - type: "`conversion-listener`"
    client_facing: "Yes"
    purpose: A `conversion-only` and a `listener` combined into a single resource, for a REST API that doesn't need to share tools across multiple listeners.
  - type: "`passthrough-listener`"
    client_facing: "Yes"
    purpose: Proxies MCP protocol traffic straight through to an upstream MCP server, unconverted, with its own tool list and access control.
{% endtable %}
<!--vale on-->

Every type shares `name`, `displayName`, `enabled`, `labels`, `policies`, and a `config.route.paths` list, alongside a type-specific `tools` list and `config.url` (the upstream to convert or proxy). `listener`, `conversion-listener`, and `passthrough-listener` also accept an `access` block, gating the endpoint by `AIGatewayConsumerGroup` ACLs or auth strategy, the same way `spec.apiSpec.model.access` does on `AIGatewayModel`.

The following configuration converts two REST endpoints into MCP tools, then exposes them behind an ACL-gated listener:

```yaml
kind: AIGatewayMCPServer
apiVersion: aiconfiguration.konghq.com/v1alpha1
metadata:
  name: flights-tools
  namespace: kong
spec:
  aiGatewayRef:
    type: namespacedRef
    namespacedRef:
      name: my-ai-gateway-cp
  apiSpec:
    type: conversion-only
    conversion-only:
      name: flights-tools
      displayName: Flights API tools
      enabled: Enabled
      config:
        url: https://flights-api.example.com/openapi.json
        route:
          paths:
            - /mcp/flights
      tools:
        - name: search_flights
          description: Search available flights by origin, destination, and date
          method: GET
          path: /flights
        - name: get_flight_status
          description: Get real-time status for a given flight number
          method: GET
          path: /flights/{flightNumber}/status
---
kind: AIGatewayMCPServer
apiVersion: aiconfiguration.konghq.com/v1alpha1
metadata:
  name: flights-mcp-listener
  namespace: kong
spec:
  aiGatewayRef:
    type: namespacedRef
    namespacedRef:
      name: my-ai-gateway-cp
  apiSpec:
    type: listener
    listener:
      name: flights-mcp-listener
      displayName: Flights MCP listener
      enabled: Enabled
      sources:
        - flights-tools
      access:
        aclAttributeType: consumer
      config:
        route:
          paths:
            - /mcp/flights
```

A `passthrough-listener` or `upstream-server` follows the same shape, but its `config.url` points at a real MCP server instead of a REST API, and its `tools` entries don't need `method`/`path` (those are inherent to the upstream server's own tool definitions).

## AIGatewayAuthStrategy

`AIGatewayAuthStrategy` configures the authentication scheme the gateway uses to verify downstream clients. Two types are supported: `key-auth` (API key) and `openid-connect` (OIDC).

The following is an example key auth AI Auth Strategy configuration:

```yaml
apiVersion: aiconfiguration.konghq.com/v1alpha1
kind: AIGatewayAuthStrategy
metadata:
  name: key-auth-provider
  namespace: kong
spec:
  aiGatewayRef:
    type: namespacedRef
    namespacedRef:
      name: my-ai-gateway-cp
  apiSpec:
    type: key-auth
    key-auth:
      name: key-auth-provider
      displayName: API Key Authentication
      config:
        hideCredentials: Enabled
```


OIDC client secrets use a `SensitiveDataSource` value in a list. Store the secret in Kubernetes and reference it:

```bash
kubectl create secret generic oidc-client-secret \
  --from-literal=clientSecret=<your-client-secret> \
  -n kong
kubectl label secret oidc-client-secret konghq.com/secret=true -n kong
```

The following is an example OpenID Connect AI Auth Strategy configuration:

```yaml
apiVersion: aiconfiguration.konghq.com/v1alpha1
kind: AIGatewayAuthStrategy
metadata:
  name: oidc-provider
  namespace: kong
spec:
  aiGatewayRef:
    type: namespacedRef
    namespacedRef:
      name: my-ai-gateway-cp
  apiSpec:
    type: openid-connect
    openid-connect:
      name: oidc-provider
      displayName: OpenID Connect Authentication
      config:
        issuer: https://your-idp.example.com/.well-known/openid-configuration
        clientID:
          - your-client-id
        clientSecret:
          - type: secretRef
            secretRef:
              name: oidc-client-secret
              key: clientSecret
```

## Securing provider credentials

Provider API keys must not appear as plain text in manifests committed to source control. The `AIGatewayModelProvider` `config.auth` fields accept a `SensitiveDataSource` value with two modes:

```yaml
# Inline (development only — avoid committing)
value:
  type: inline
  value: "Bearer sk-xxxx"

# Secret reference (recommended for production)
value:
  type: secretRef
  secretRef:
    name: my-secret
    key: token
```

For teams already using a secrets manager (HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager), [External Secrets Operator](https://external-secrets.io/) syncs secrets into Kubernetes automatically and rotates them without redeploying the `AIGatewayModelProvider`.

## Inspecting resource status

All {{ site.ai_gateway }} CRDs expose a `Programmed` status condition. Check the reconciliation state of all resources at once:

```bash
kubectl get \
  konnectaigateway,aigatewaymodelprovider,aigatewaymodel,aigatewaypolicy,aigatewayauthstrategy,aigatewaydataplane \
  -n kong
```

Describe any resource to see the full status and any operator error messages:

```bash
kubectl describe konnectaigateway/my-ai-gateway-cp -n kong
```

## Troubleshooting

###  AI Provider not reconciling

The provider depends on the `KonnectAIGateway` being `Programmed=True` first. Check the control plane status, then verify the {{site.konnect_short_name}} auth Secret it references is correctly formed.

### AI Model Route unreachable

Confirm the `AIGatewayDataPlane` pod is running and the `LoadBalancer` address is assigned:

```bash
kubectl get pods,svc -n kong -l gateway-operator.konghq.com/managed-by-name=my-ai-gateway-dp
```

### AI Policy not taking effect

Verify `spec.aiGatewayRef.namespacedRef.name` matches your `KonnectAIGateway` name exactly. Describe the AI Policy to surface any reconciliation errors:

```bash
kubectl describe aigatewaypolicy -n kong
```

### {{site.operator_product_name}} LOGS

For any resource stuck in a non-`Programmed` state, check the {{site.operator_product_name}} logs:

```bash
kubectl logs -n kong-system \
  -l app.kubernetes.io/name=kong-operator \
  --since=10m
```
