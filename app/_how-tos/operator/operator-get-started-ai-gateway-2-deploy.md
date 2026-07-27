---
title: Deploy {{ site.ai_gateway_name }} with {{site.operator_product_name}}
description: Create an {{ site.ai_gateway }} control plane, configure an AI provider and model, and deploy the data plane in Kubernetes.
content_type: how_to
permalink: /operator/get-started/ai-gateway/deploy/
tech_preview: true
series:
  id: operator-get-started-ai-gateway
  position: 2

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
  show_works_on: true
  skip_product: true
  operator:
    konnect:
      auth: true

tldr:
  q: How do I deploy {{ site.ai_gateway_name }} with {{site.operator_product_name}}?
  a: Create a `KonnectAIGateway`, store your provider API key in a Kubernetes Secret, add an `AIGatewayModelProvider` and `AIGatewayModel`, then deploy an `AIGatewayDataPlane`. {{site.operator_product_name}} provisions the mTLS certificate automatically.

next_steps:
  - text: Apply AI policies
    url: /operator/get-started/ai-gateway/policy/
  - text: "{{ site.ai_gateway_name }} resource reference"
    url: /operator/konnect/ai-gateway/

related_resources:
  - text: "{{ site.ai_gateway_name }} with {{ site.operator_product_name }}"
    url: /operator/konnect/ai-gateway/
  - text: AI providers
    url: /ai-gateway/entities/ai-provider/
  - text: AI models
    url: /ai-gateway/entities/ai-model/
  - text: AI policies
    url: /ai-gateway/entities/ai-policy/
---

This guide deploys a full {{ site.ai_gateway }} stack on Kubernetes using {{site.operator_product_name}}.

## Create the `KonnectAIGateway`

The `KonnectAIGateway` resource creates the {{ site.ai_gateway }} control plane in {{site.konnect_short_name}} and serves as the parent for all other resources in this guide.

1. Create the `KonnectAIGateway` resource:

   ```bash
   echo '
   apiVersion: konnect.konghq.com/v1alpha1
   kind: KonnectAIGateway
   metadata:
     name: my-ai-gateway-cp
     namespace: kong
   spec:
     apiSpec:
       name: my-ai-gateway-cp
       displayName: My AI Gateway
       description: AI Gateway control plane managed by Kubernetes
     konnect:
       authRef:
         name: konnect-api-auth
   ' | kubectl apply -f -
   ```

1. Wait for the resource to be ready:

   ```bash
   kubectl wait konnectaigateway/my-ai-gateway-cp -n kong \
     --for=condition=Programmed=True \
     --timeout=10m
   ```

## Create an AI Model Provider

The `AIGatewayModelProvider` resource configures authentication and connection details for an upstream LLM provider. This example uses OpenAI.

1. Store your OpenAI API key in a Kubernetes Secret. The value includes the `Bearer` prefix because it is used directly as an HTTP Authorization header:

   ```bash
   kubectl create secret generic openai-credentials \
     --from-literal=token="Bearer ${OPENAI_API_KEY}" \
     -n kong
   kubectl label secret openai-credentials konghq.com/secret=true -n kong
   ```

1. Create the `AIGatewayModelProvider` resource, referencing the Secret:

   ```bash
   echo '
   apiVersion: konnect.konghq.com/v1alpha1
   kind: AIGatewayModelProvider
   metadata:
     name: openai-provider
     namespace: kong
   spec:
     aiGatewayRef:
       type: namespacedRef
       namespacedRef:
         name: my-ai-gateway-cp
     apiSpec:
       type: openai
       openai:
         name: openai-provider
         displayName: OpenAI
         config:
           auth:
             headers:
               - name: Authorization
                 value:
                   type: secretRef
                   secretRef:
                     name: openai-credentials
                     key: token
   ' | kubectl apply -f -
   ```

1. Wait for the resource to be ready:

   ```bash
   kubectl wait aigatewaymodelprovider/openai-provider -n kong \
     --for=condition=Programmed=True \
     --timeout=10m
   ```

## Create an AI Model

The `AIGatewayModel` resource defines a Route and maps it to one or more provider targets. Clients send inference requests to the path configured here.

1. Create the `AIGatewayModel` resource:

   ```bash
   echo '
   apiVersion: konnect.konghq.com/v1alpha1
   kind: AIGatewayModel
   metadata:
     name: gpt-4o-mini
     namespace: kong
   spec:
     aiGatewayRef:
       type: namespacedRef
       namespacedRef:
         name: my-ai-gateway-cp
     apiSpec:
       type: model
       model:
         name: gpt-4o-mini
         displayName: GPT-4o Mini
         enabled: Enabled
         formats:
           - type: openai
         capabilities:
           - generate
         config:
           model:
             alias: gpt-4o-mini
           route:
             paths:
               - /v1
         targets:
           - name: gpt-4o-mini
             provider: openai-provider
             config:
               type: openai
               openai:
                 upstreamURL: https://api.openai.com/v1/chat/completions
   ' | kubectl apply -f -
   ```

1. Wait for the resource to be ready:

   ```bash
   kubectl wait aigatewaymodel/gpt-4o-mini -n kong \
     --for=condition=Programmed=True \
     --timeout=10m
   ```

## Deploy the `AIGatewayDataPlane`

The `AIGatewayDataPlane` resource runs the {{ site.ai_gateway }} binary inside your Kubernetes cluster. It exposes a `LoadBalancer` Service on port `8000` for inference requests.

{{site.operator_product_name}} automatically provisions the mTLS certificate and registers it with the control plane — there is no need to create an `AIGatewayDataPlaneCertificate` manually.

1. Deploy the `AIGatewayDataPlane`:

   ```bash
   echo '
   apiVersion: aigateway.konghq.com/v1alpha1
   kind: AIGatewayDataPlane
   metadata:
     name: my-ai-gateway-dp
     namespace: kong
   spec:
     controlPlaneRef:
       type: konnectNamespacedRef
       konnectNamespacedRef:
         name: my-ai-gateway-cp
     deployment:
       replicas: 1
     network:
       services:
         ingress:
           type: LoadBalancer
           ports:
             - name: http
               port: 8000
               targetPort: 8000
   ' | kubectl apply -f -
   ```

1. Wait for the data plane to be ready:

   ```bash
   kubectl wait aigatewaydataplane/my-ai-gateway-dp -n kong \
     --for=condition=Ready=True \
     --timeout=10m
   ```

## Validate

Export the `LoadBalancer` address:

```bash
export AIGW_HOST=$(kubectl get service my-ai-gateway-dp-ingress -n kong \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $AIGW_HOST
```

Send a request to the AI Model Route you configured:

```bash
curl -s http://$AIGW_HOST:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o-mini",
    "messages": [{"role": "user", "content": "Hello from Kong AI Gateway!"}]
  }'
```

You should receive a response from OpenAI routed through the {{ site.ai_gateway }} data plane.
