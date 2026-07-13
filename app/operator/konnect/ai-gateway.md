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
  operator: '2.2'

related_resources:
  - text: Deploy {{ site.ai_gateway_name }} with {{ site.operator_product_name }}
    url: /operator/get-started/ai-gateway/install/
  - text: "{{ site.ai_gateway_name }} overview"
    url: /ai-gateway/
  - text: AI providers
    url: /ai-gateway/entities/ai-provider/
  - text: AI models
    url: /ai-gateway/entities/ai-model/
  - text: AI policies
    url: /ai-gateway/entities/ai-policy/
  - text: AI data plane certificates
    url: /ai-gateway/entities/ai-data-plane-certificate/
  - text: AI consumers
    url: /ai-gateway/entities/ai-consumer/
  - text: Cross namespace references
    url: /operator/konnect/cross-namespace-references/

---

{{ site.operator_product_name }} manages {{ site.ai_gateway_name }} using a set of Kubernetes Custom Resource Definitions (CRDs). Each CRD maps to a concept in the {{ site.ai_gateway }} control plane — you declare the desired state in Kubernetes, and the operator reconciles it with {{ site.konnect_short_name }}.

The operator manages three distinct layers:

**Control plane** — `KonnectAIGateway` provisions and owns the {{ site.ai_gateway }} control plane in {{ site.konnect_short_name }}. All other resources reference it as their parent.

**Configuration resources** — `AIGatewayModelProvider`, `AIGatewayModel`, `AIGatewayPolicy`, `AIGatewayIdentityProvider`, `AIGatewayConsumer`, `AIGatewayConsumerCredential`, `AIGatewayConsumerGroup`, and `AIGatewayAgent` declare what the gateway does: which LLM providers to connect to, which model routes to expose, what policies to enforce, which authentication schemes to accept, and which clients may access it.

**Data plane** — `AIGatewayDataPlaneCertificate` and `AIGatewayDataPlane` run the traffic-handling binary inside your cluster. When you create an `AIGatewayDataPlane`, the operator automatically provisions the mTLS certificate and registers it with the control plane.

## Resource model

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
    api_group: "`konnect.konghq.com/v1alpha1`"
    purpose: Configures an upstream LLM provider (OpenAI, Anthropic, Azure, Gemini, etc.)
  - resource: "`AIGatewayModel`"
    api_group: "`konnect.konghq.com/v1alpha1`"
    purpose: Defines a model route, its capabilities, and which provider targets it
  - resource: "`AIGatewayPolicy`"
    api_group: "`konnect.konghq.com/v1alpha1`"
    purpose: Applies a policy to the gateway (e.g. prompt guard, sanitizer, rate limiting)
  - resource: "`AIGatewayIdentityProvider`"
    api_group: "`konnect.konghq.com/v1alpha1`"
    purpose: Configures the gateway authentication scheme (`key-auth` or `openid-connect`)
  - resource: "`AIGatewayConsumer`"
    api_group: "`konnect.konghq.com/v1alpha1`"
    purpose: Registers a downstream client identity for authentication and access control
  - resource: "`AIGatewayConsumerCredential`"
    api_group: "`konnect.konghq.com/v1alpha1`"
    purpose: Attaches an API key credential to an `AIGatewayConsumer`
  - resource: "`AIGatewayConsumerGroup`"
    api_group: "`konnect.konghq.com/v1alpha1`"
    purpose: Groups consumers together and applies shared policies at the group level
  - resource: "`AIGatewayAgent`"
    api_group: "`konnect.konghq.com/v1alpha1`"
    purpose: Configures an agent endpoint for A2A or HTTP agent traffic
  - resource: "`AIGatewayDataPlaneCertificate`"
    api_group: "`configuration.konghq.com/v1alpha1`"
    purpose: Registers a TLS certificate used by the data plane to authenticate with the control plane (auto-created by `AIGatewayDataPlane`)
  - resource: "`AIGatewayDataPlane`"
    api_group: "`aigateway.konghq.com/v1alpha1`"
    purpose: Deploys the {{ site.ai_gateway }} data plane in Kubernetes and provisions the mTLS certificate automatically
{% endtable %}
<!--vale on-->

## How resources reference each other

All configuration resources anchor to the `KonnectAIGateway` as their root via `spec.aiGatewayRef`. Consumer credentials attach to consumers, not directly to the control plane.

1. `AIGatewayModelProvider.spec.aiGatewayRef` → `KonnectAIGateway`
2. `AIGatewayModel.spec.aiGatewayRef` → `KonnectAIGateway`
3. `AIGatewayModel.spec.apiSpec.api.targets[].provider` → `AIGatewayModelProvider` (by name)
4. `AIGatewayPolicy.spec.aiGatewayRef` → `KonnectAIGateway`
5. `AIGatewayIdentityProvider.spec.aiGatewayRef` → `KonnectAIGateway`
6. `AIGatewayConsumer.spec.aiGatewayRef` → `KonnectAIGateway`
7. `AIGatewayConsumerCredential.spec.aiGatewayConsumerRef` → `AIGatewayConsumer`
8. `AIGatewayConsumerGroup.spec.aiGatewayRef` → `KonnectAIGateway`
9. `AIGatewayAgent.spec.aiGatewayRef` → `KonnectAIGateway`
10. `AIGatewayDataPlaneCertificate.spec.aiGatewayRef` → `KonnectAIGateway`
11. `AIGatewayDataPlane.spec.controlPlaneRef` → `KonnectAIGateway`

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

Each resource type is covered hands-on in the getting started series:

- **Providers and models** — [Deploy {{ site.ai_gateway_name }}](/operator/get-started/ai-gateway/deploy/) covers `AIGatewayModelProvider`, `AIGatewayModel`, and `AIGatewayDataPlane`.
- **Policies** — [Apply AI policies](/operator/get-started/ai-gateway/policy/) covers `AIGatewayPolicy`, including global and model-scoped enforcement.
- **Identity providers and consumers** — [Add AI consumers](/operator/get-started/ai-gateway/consumers/) covers `AIGatewayIdentityProvider`, `AIGatewayConsumer`, `AIGatewayConsumerCredential`, and `AIGatewayConsumerGroup`.
- **Agents** — `AIGatewayAgent` supports `a2a` and `http` agent types. Set `spec.apiSpec.type` to the agent protocol and `spec.apiSpec.config.url` to the upstream agent URL.

## AIGatewayIdentityProvider

`AIGatewayIdentityProvider` configures the authentication scheme the gateway uses to verify downstream clients. Two types are supported: `key-auth` (API key) and `openid-connect` (OIDC).

**Key-auth identity provider**

```yaml
apiVersion: konnect.konghq.com/v1alpha1
kind: AIGatewayIdentityProvider
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

**OpenID Connect identity provider**

OIDC client secrets use a `SensitiveDataSource` value in a list — store the secret in Kubernetes and reference it:

```bash
kubectl create secret generic oidc-client-secret \
  --from-literal=clientSecret=<your-client-secret> \
  -n kong
kubectl label secret oidc-client-secret konghq.com/secret=true -n kong
```

```yaml
apiVersion: konnect.konghq.com/v1alpha1
kind: AIGatewayIdentityProvider
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
  konnectaigateway,aigatewaymodelprovider,aigatewaymodel,aigatewaypolicy,aigatewayidentityprovider,aigatewaydataplane \
  -n kong
```

Describe any resource to see the full status and any operator error messages:

```bash
kubectl describe konnectaigateway/my-ai-gateway-cp -n kong
```

## Troubleshooting

**Provider not reconciling**

The provider depends on the `KonnectAIGateway` being `Programmed=True` first. Check the control plane status, then verify the Konnect auth Secret it references is correctly formed.

**Model route unreachable**

Confirm the `AIGatewayDataPlane` pod is running and the `LoadBalancer` address is assigned:

```bash
kubectl get pods,svc -n kong -l app.kubernetes.io/name=my-ai-gateway-dp
```

**Policy not taking effect**

Verify `spec.aiGatewayRef.namespacedRef.name` matches your `KonnectAIGateway` name exactly. Describe the policy to surface any reconciliation errors:

```bash
kubectl describe aigatewaypolicy -n kong
```

**Operator logs**

For any resource stuck in a non-`Programmed` state, check the operator logs:

```bash
kubectl logs -n kong-system \
  -l app.kubernetes.io/name=kong-operator \
  --since=10m
```
