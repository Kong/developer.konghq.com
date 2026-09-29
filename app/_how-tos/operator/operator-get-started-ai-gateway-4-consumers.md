---
title: Add AI Consumers with {{site.operator_product_name}}
description: Use AIGatewayConsumer, AIGatewayConsumerCredential, and AIGatewayConsumerGroup to authenticate downstream clients and enforce per-Consumer controls on your {{ site.ai_gateway }} deployment.
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
  operator: '2.3'
  ai-gateway: '2.0'

works_on:
  - konnect

prereqs:
  skip_product: true

tldr:
  q: How do I add AI consumers with {{site.operator_product_name}}?
  a: |
    Create an `AIGatewayAuthStrategy` and attach it to your AI Model via `spec.apiSpec.model.access.authStrategies`. 

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

This guide builds on the [AI Policy step](/operator/get-started/ai-gateway/policy/) and introduces consumer-level authentication to the running {{ site.ai_gateway }} deployment. Before creating AI Consumers, you configure an `AIGatewayAuthStrategy` that defines the authentication scheme, then attach it to an AI Model via `spec.apiSpec.model.access.authStrategies`. Authentication is enforced per-AI Model, not globally. An AI Model without an AI Auth Strategy reference accepts unauthenticated traffic.

With AI Consumers in place you can:

- Issue API keys per team and revoke them independently
- Enforce per-consumer `AIGatewayPolicy` rules such as different allowlists per team
- Group AI Consumers with `AIGatewayConsumerGroup` to target shared AI Policies, model access controls, and analytics attribution at the group level
- Attribute usage and cost to a specific AI Consumer in the {{ site.konnect_short_name }} analytics dashboard

## Create an `AIGatewayAuthStrategy`

The `AIGatewayAuthStrategy` resource configures the authentication scheme {{ site.ai_gateway_name }} uses to verify downstream clients. This example uses API key authentication.

1. Create a key-auth AI Auth Strategy:

   ```bash
   echo '
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
           keyNames:
             - x-api-key
   ' | kubectl apply -f -
   ```

1. Wait for the AI Auth Strategy to be ready:

   ```bash
   kubectl wait aigatewayauthstrategy/key-auth-provider -n kong \
     --for=condition=Programmed=True \
     --timeout=5m
   ```

## Attach the AI Auth Strategy to the AI Model

An `AIGatewayAuthStrategy` takes effect only when it is attached to an AI Model via `spec.apiSpec.model.access.authStrategies`. Patch the AI Model you created in the [deployment step](/operator/get-started/ai-gateway/deploy/) to enable authentication:

```bash
kubectl patch aigatewaymodel gpt-4o-mini -n kong \
  --type=merge \
  -p '{"spec":{"apiSpec":{"model":{"access":{"authStrategies":[{"name":"key-auth-provider"}]}}}}}'
```

Wait for the AI Model to be reconciled with the updated configuration:

```bash
kubectl wait aigatewaymodel/gpt-4o-mini -n kong \
  --for=condition=Programmed=True \
  --timeout=5m
```

## Create an AI Consumer

The `AIGatewayConsumer` resource registers a downstream client with the {{ site.ai_gateway }} control plane in {{ site.konnect_short_name }}.

1. Create an AI Consumer for your platform engineering team:

   ```bash
   echo '
   apiVersion: aiconfiguration.konghq.com/v1alpha1
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

1. Wait for the AI Consumer to be reconciled:

   ```bash
   kubectl wait aigatewayconsumer/team-platform -n kong \
     --for=condition=Programmed=True \
     --timeout=5m
   ```

## Attach an API key credential

The `AIGatewayConsumerCredential` resource attaches an API key to an `AIGatewayConsumer`. Store the key in a Kubernetes Secret first; {{site.operator_product_name}} reads the value from the Secret and never stores it in plain text.

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
   apiVersion: aiconfiguration.konghq.com/v1alpha1
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

1. Wait for the credential to be reconciled:

   ```bash
   kubectl wait aigatewayconsumercredential/team-platform-key-auth -n kong \
     --for=condition=Programmed=True \
     --timeout=5m
   ```

{:.info}
> **Credentials are immutable:** `AIGatewayConsumerCredential` only supports create and delete; updates are not propagated. To rotate a key, delete the credential and create a new one.

## Test authentication


Send an authenticated request using the API key:

```bash
curl -s -o /dev/null -w "%{http_code}\n" \
  http://$AIGW_HOST:8000/v1/chat/completions \
  -H "x-api-key: my-platform-team-api-key" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"How do I configure a Kong service?"}]}'
```

Send an unauthenticated request:

```bash
curl -s -o /dev/null -w "%{http_code}\n" \
  http://$AIGW_HOST:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"How do I configure a Kong service?"}]}'
```

You should get a `401 Unauthorized`.

## Group AI Consumers with an AI Consumer Group

`AIGatewayConsumerGroup` is a named set of AI Consumers that you can target as a unit. Use AI Consumer Groups to:

- Apply shared AI Policies to a team via `spec.apiSpec.policies` on the AI Consumer Group — each entry is an object with a `name` field referencing an `AIGatewayPolicy` by its Kubernetes resource name, which is useful for AI Policies scoped with `global: Disabled`
- Restrict or allow group access to individual AI Models via `spec.apiSpec.model.access.acls` on the `AIGatewayModel`
- Attribute usage across multiple AI Consumers to a single AI Consumer Group in {{ site.konnect_short_name }} analytics

AI Consumer membership is declared on the `AIGatewayConsumer`, not on the AI Consumer Group. Use `spec.consumerGroups` on the AI Consumer to reference the AI Consumer Groups it belongs to.

1. Create an AI Consumer Group:

   ```bash
   echo '
   apiVersion: aiconfiguration.konghq.com/v1alpha1
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
       policies: []
   ' | kubectl apply -f -
   ```

1. Wait for the AI Consumer Group to be reconciled:

   ```bash
   kubectl wait aigatewayconsumergroup/platform-team-group -n kong \
     --for=condition=Programmed=True \
     --timeout=5m
   ```

1. Enroll the AI Consumer in the AI Consumer Group by patching the consumer resource:

   ```bash
   kubectl patch aigatewayconsumer team-platform -n kong \
     --type=merge \
     -p '{"spec":{"consumerGroups":[{"name":"platform-team-group"}]}}'
   ```

1. Wait for the AI Consumer to reconcile with the updated AI Consumer Group membership:

   ```bash
   kubectl wait aigatewayconsumer/team-platform -n kong \
     --for=condition=Programmed=True \
     --timeout=5m
   ```

1. Confirm both resources are visible:

   ```bash
   kubectl get aigatewayconsumer,aigatewayconsumergroup -n kong
   ```

## Inspect AI Consumer status

List all AI Consumers and their reconciliation status:

```bash
kubectl get aigatewayconsumer -n kong
```

You should see an output like the following:
NAME            ID                                     PROGRAMMED   AGE
team-platform   <konnect-id>                           True         2m

Describe an AI Consumer to see the full status and any reconciliation errors:

```bash
kubectl describe aigatewayconsumer/team-platform -n kong
```
