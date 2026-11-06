---
title: Install {{site.operator_product_name}} for {{ site.ai_gateway_name }}
description: Install {{site.operator_product_name}} with the {{ site.ai_gateway }} controllers enabled and prepare a Kubernetes cluster for {{ site.ai_gateway_name }}, with either a {{site.konnect_short_name}} or an on-premises control plane.
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
  operator: '2.4'
  ai-gateway: '2.0'

works_on:
  - konnect
  - on-prem

prereqs:
  show_works_on: true
  skip_product: true
  enterprise: true
  operator:
    controllers: [AIGATEWAYDATAPLANE]
    on_prem_controllers: [ONPREMAIGATEWAY]
  inline:
    - title: "On-premises: Kubernetes cluster and {{ site.ee_product_name }} license"
      topology: on-prem
      include_content: /md/operator/ai-gateway/prereqs/on-prem-cluster
      icon_url: /assets/icons/kubernetes.svg

tldr:
  q: How do I install {{site.operator_product_name}} for {{ site.ai_gateway_name }}?
  a: |
    Install {{site.operator_product_name}} using Kong's `kong-operator` chart with `--set env.ENABLE_CONTROLLER_AIGATEWAYDATAPLANE=true` to enable the {{ site.ai_gateway }} data plane controller.
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

This guide walks through a complete {{ site.ai_gateway_name }} setup using {{site.operator_product_name}}. 

By the end of the series, you will have:

{% konnect %}
content: |
  - A {{site.konnect_short_name}} {{ site.ai_gateway_name }} control plane
{% endkonnect %}
{% on_prem %}
content: |
  - An on-premises {{ site.ai_gateway_name }} control plane run by {{site.operator_product_name}}
{% endon_prem %}

- An AI Model Provider (OpenAI) and an AI Model
- An {{ site.ai_gateway_name }} data plane running in Kubernetes
- AI Prompt Guard Policies enforcing content governance
- Authenticated AI Consumers with per-team API keys

## Create the Kubernetes namespace

Create the namespace used throughout this series:

```bash
kubectl create namespace kong
```
{: data-test-step="block" }

## Install {{site.operator_product_name}}

{% include operator/rapid-release.md %}

{% include prereqs/products/operator.md raw=true v_maj=2 chart_version=site.data.products.operator.rapid.chart %}

## Verify {{ site.ai_gateway }} CRDs

Confirm the {{ site.ai_gateway }} CRDs are registered in the cluster:

```bash
kubectl get crd | grep -E "aigateway|aigatewaydataplane"
```
{: data-test-step="block" }

You should see entries for `konnectaigateways`, `onpremaigateways`, `aigatewaymodelproviders`, `aigatewaymodels`, `aigatewaypolicies`, `aigatewayauthstrategies`, `aigatewayconsumers`, `aigatewayconsumercredentials`, `aigatewayconsumergroups`, `aigatewayagents`, `aigatewaydataplanecertificates`, and `aigatewaydataplanes`.

{% on_prem %}
title: Verify the on-premises controller and license
step: true
content: |
  Confirm that the `KongLicense` was picked up by {{site.operator_product_name}}:

  ```bash
  kubectl get konglicense kong-license \
    -o jsonpath='{.status.controllers[0].conditions[?(@.type=="Programmed")].status}'
  ```

  The command prints `True`. {{site.operator_product_name}} injects this license into every `AIGatewayDataPlane` that references an `OnPremAIGateway`. A data plane started without a license still runs, but reports `LicenseValid=False` with the message `No enabled KongLicense resource found; the gateway will run without a license`.

  Confirm that the `OnPremAIGateway` controller is enabled:

  ```bash
  kubectl get deployment -n kong-system kong-operator-kong-operator-controller-manager \
    -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="KONG_OPERATOR_ENABLE_CONTROLLER_ONPREMAIGATEWAY")].value}'
  ```

  The command prints `true`. If it prints nothing, the operator was installed without `--set env.ENABLE_CONTROLLER_ONPREMAIGATEWAY=true`. An `OnPremAIGateway` you create in that state is never reconciled and stays at `Ready=Unknown`.
{% endon_prem %}
