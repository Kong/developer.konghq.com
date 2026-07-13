---
title: Install {{site.operator_product_name}} for {{ site.ai_gateway_name }}
description: Install {{site.operator_product_name}} with the {{ site.ai_gateway }} data plane controller enabled and prepare a Kubernetes cluster for {{ site.ai_gateway_name }}.
content_type: how_to
permalink: /operator/get-started/ai-gateway/install/

series:
  id: operator-get-started-ai-gateway
  position: 1

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
  ai-gateway: '2.0'

works_on:
  - konnect

prereqs:
  show_works_on: true
  skip_product: true
  operator:
    controllers: [AIGATEWAYDATAPLANE]
    konnect:
      auth: true

tldr:
  q: How do I install {{site.operator_product_name}} for {{ site.ai_gateway_name }}?
  a: Install {{site.operator_product_name}} with `--set env.ENABLE_CONTROLLER_AIGATEWAYDATAPLANE=true` to enable the {{ site.ai_gateway }} data plane controller, then store your {{site.konnect_short_name}} credentials in a Kubernetes Secret.

next_steps:
  - text: Deploy {{ site.ai_gateway_name }}
    url: /operator/get-started/ai-gateway/deploy/

related_resources:
  - text: "{{ site.ai_gateway_name }} with {{ site.operator_product_name }}"
    url: /operator/konnect/ai-gateway/
  - text: "{{ site.ai_gateway_name }} overview"
    url: /ai-gateway/
  - text: Cross namespace references
    url: /operator/konnect/cross-namespace-references/

tags:
  - install
  - helm
  - ai

---

This guide walks through a complete {{ site.ai_gateway_name }} setup using {{site.operator_product_name}} and {{site.konnect_short_name}}.

By the end of the series, you will have:

- A {{site.konnect_short_name}} {{ site.ai_gateway_name }} control plane
- An AI Model Provider (OpenAI) and an AI Model route
- An {{ site.ai_gateway_name }} data plane running in Kubernetes
- AI Prompt Guard Policies enforcing content governance
- Authenticated AI Consumers with per-team API keys

## Create the Kubernetes namespace

Create the namespace used throughout this series:

```bash
kubectl create namespace kong
```

## Install {{site.operator_product_name}}

Install {{site.operator_product_name}} with the {{ site.ai_gateway }} data plane controller enabled:

{% include prereqs/products/operator.md raw=true v_maj=2 %}

## Verify {{ site.ai_gateway }} CRDs

Confirm the {{ site.ai_gateway }} CRDs are registered in the cluster:

```bash
kubectl get crd | grep -E "aigateway|aigatewaydataplane"
```

You should see entries for `konnectaigateways`, `aigatewaymodelproviders`, `aigatewaymodels`, `aigatewaypolicies`, `aigatewayidentityproviders`, `aigatewayconsumers`, `aigatewayconsumercredentials`, `aigatewayconsumergroups`, `aigatewayagents`, `aigatewaydataplanecertificates`, and `aigatewaydataplanes`.
