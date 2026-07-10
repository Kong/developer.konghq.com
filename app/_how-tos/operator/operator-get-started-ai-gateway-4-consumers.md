---
title: Add AI consumers with {{site.operator_product_name}}
description: Use AIGatewayConsumer, AIGatewayConsumerCredential, and AIGatewayConsumerGroup to authenticate downstream clients and enforce per-consumer controls on your AI Gateway deployment.
content_type: how_to
permalink: /operator/get-started/ai-gateway/consumers/

series:
  id: operator-get-started-ai-gateway
  position: 4

breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: Get Started

products:
  - operator

min_version:
  operator: '2.2'

works_on:
  - konnect

prereqs:
  show_works_on: true
  skip_product: true
  operator:
    konnect:
      auth: true

tldr:
  q: How do I add AI consumers with {{site.operator_product_name}}?
  a: |
    Create an `AIGatewayConsumer` with `spec.apiSpec.type: api-key`, store the key in a Kubernetes Secret, then create an `AIGatewayConsumerCredential` referencing it. Use `AIGatewayConsumerGroup` to apply shared policies to multiple consumers at once.

next_steps:
  - text: "{{ site.ai_gateway_name }} resource reference"
    url: /operator/konnect/ai-gateway/

related_resources:
  - text: "{{ site.ai_gateway_name }} with {{ site.operator_product_name }}"
    url: /operator/konnect/ai-gateway/
  - text: AI consumers
    url: /ai-gateway/entities/ai-consumer/
  - text: Cross namespace references
    url: /operator/konnect/cross-namespace-references/

tags:
  - ai
  - security

---

This guide builds on the [policy step](/operator/get-started/ai-gateway/policy/) and introduces consumer-level authentication to the running {{ site.ai_gateway }} deployment. Before creating consumers, you configure an `AIGatewayIdentityProvider` that tells the gateway which authentication scheme to use.

With consumers in place you can:

- issue API keys per team and revoke them independently
- enforce per-consumer `AIGatewayPolicy` rules such as different allowlists per team
- group consumers with `AIGatewayConsumerGroup` to apply shared policies at the group level
- attribute usage and cost to a specific consumer in the {{ site.konnect_short_name }} analytics dashboard

## Create an `AIGatewayIdentityProvider`

The `AIGatewayIdentityProvider` resource configures the authentication scheme the gateway uses to verify downstream clients. This example uses API key authentication.

1. Create a key-auth identity provider:

   ```bash
   echo '
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
   ' | kubectl apply -f -
   ```

1. Wait for the identity provider to be ready:

   ```bash
   kubectl wait aigatewayidentityprovider/key-auth-provider -n kong \
     --for=condition=Programmed=True \
     --timeout=5m
   ```

## Create an AI consumer

The `AIGatewayConsumer` resource registers a downstream client with the {{ site.ai_gateway }} control plane in {{ site.konnect_short_name }}.

1. Create a consumer for your platform engineering team:

   ```bash
   echo '
   apiVersion: konnect.konghq.com/v1alpha1
   kind: AIGatewayConsumer
   metadata:
     name: team-platform
     namespace: kong
   spec:
     aiGatewayRef:
       type: namespacedRef
       namespacedRef:
         name: my-ai-gateway-cp
     apiSpec:
       name: team-platform
       displayName: Platform Engineering
       type: api-key
   ' | kubectl apply -f -
   ```

1. Wait for the consumer to be reconciled:

   ```bash
   kubectl wait aigatewayconsumer/team-platform -n kong \
     --for=condition=Programmed=True \
     --timeout=5m
   ```

## Attach an API key credential

The `AIGatewayConsumerCredential` resource attaches an API key to an `AIGatewayConsumer`. Store the key in a Kubernetes Secret first — the operator reads the value from the Secret and never stores it in plain text.

1. Create the Secret:

   ```bash
   kubectl create secret generic team-platform-key \
     --from-literal=api-key=my-platform-team-api-key \
     -n kong
   kubectl label secret team-platform-key konghq.com/secret=true -n kong
   ```

1. Create the credential resource:

   ```bash
   echo '
   apiVersion: konnect.konghq.com/v1alpha1
   kind: AIGatewayConsumerCredential
   metadata:
     name: team-platform-key-auth
     namespace: kong
   spec:
     aiGatewayConsumerRef:
       type: namespacedRef
       namespacedRef:
         name: team-platform
     apiSpec:
       name: team-platform-key-auth
       displayName: Platform Team API Key
       type: api-key
       apiKey:
         type: secretRef
         secretRef:
           name: team-platform-key
           key: api-key
   ' | kubectl apply -f -
   ```

{:.info}
> **Credentials are immutable:** `AIGatewayConsumerCredential` only supports create and delete — updates are not propagated. To rotate a key, delete the credential and create a new one.

## Test authentication

Export the data plane address if you no longer have it set from the previous step:

```bash
export AIGW_HOST=$(kubectl get service my-ai-gateway-dp -n kong \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

Authenticated request using the API key:

```bash
curl -s -o /dev/null -w "%{http_code}\n" \
  http://${AIGW_HOST}:8080/v1/chat/completions \
  -H "apikey: my-platform-team-api-key" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"Hello from the platform team"}]}'
```

Unauthenticated request — expect `401 Unauthorized`:

```bash
curl -s -o /dev/null -w "%{http_code}\n" \
  http://${AIGW_HOST}:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"Hello"}]}'
```

## Group consumers with a consumer group

`AIGatewayConsumerGroup` lets you apply shared policies to multiple consumers at once. For example, you can attach a rate-limiting or topic-allowlist policy to an entire team group instead of configuring it per consumer.

1. Create a consumer group and attach an existing policy by name:

   ```bash
   echo '
   apiVersion: konnect.konghq.com/v1alpha1
   kind: AIGatewayConsumerGroup
   metadata:
     name: platform-team-group
     namespace: kong
   spec:
     aiGatewayRef:
       type: namespacedRef
       namespacedRef:
         name: my-ai-gateway-cp
     apiSpec:
       name: platform-team-group
       displayName: Platform Team
       policies:
         - injection-guard
   ' | kubectl apply -f -
   ```

1. Wait for the group to be reconciled:

   ```bash
   kubectl wait aigatewayconsumergroup/platform-team-group -n kong \
     --for=condition=Programmed=True \
     --timeout=5m
   ```

1. Confirm both resources are visible:

   ```bash
   kubectl get aigatewayconsumer,aigatewayconsumergroup -n kong
   ```

## Inspect consumer status

List all consumers and their reconciliation status:

```bash
kubectl get aigatewayconsumer -n kong
```

Describe a consumer to see the full status and any reconciliation errors:

```bash
kubectl describe aigatewayconsumer/team-platform -n kong
```
