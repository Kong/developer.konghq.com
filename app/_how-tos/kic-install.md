---
title: Install {{ site.kic_product_name }}
description: Run {{ site.kic_product_name }} with {{ site.konnect_short_name }} or on-prem using Helm
content_type: how_to
permalink: /kubernetes-ingress-controller/install/
breadcrumbs:
  - /kubernetes-ingress-controller/

series:
  id: kic-get-started
  position: 1

related_resources:
  - text: All KIC documentation
    url: /index/kubernetes-ingress-controller/

products:
  - kic

works_on:
  - on-prem
  - konnect

entities: []

tldr:
  q: How do I install {{ site.kic_product_name }}?
  a: |
    ```bash
    helm install kong kong/ingress -n kong --create-namespace
    ```

prereqs:
  skip_product: true
  expand_accordion: false
  kubernetes:
    gateway_api: true
    gateway_api_optional: true

cleanup:
  inline:
    - title: Uninstall KIC from your cluster
      include_content: cleanup/products/kic
      icon_url: /assets/icons/kubernetes.svg
faqs:
  - q: Why is my KIC instance read-only in {{site.konnect_short_name}}?
    a: |
      Because Kubernetes resources are the source of truth for configuring {{ site.base_gateway }} in Kubernetes, the KIC instance configuration in {{site.konnect_short_name}} is marked as read-only. This prevents configuration drift in {{ site.base_gateway }} caused by changes made outside the Ingress or Kubernetes Gateway API.

      For example, if a Route is created via the Kubernetes Gateway API and then modified in {{site.base_gateway}}, those changes wouldn't be reflected in the CRD and would conflict with the desired state defined in the CRD.
  - q: I'm using AWS CDK, can I manage Kong resources with CDK instead of {{ site.kic_product_name }}?
    a: |
      Currently, you can't manage Kong resources via AWS CDK. We recommend managing Kong configurations by [deploying decK](/deck/) or custom automation (for example, Lambda functions) through CDK that interact with the [Admin API](/admin-api/). 

tags:
  - install
  - helm
---

{: data-deployment-topology="konnect" }
## Konnect setup

{:.info}
> For UI setup instructions to install {{ site.kic_product_name }} on {{ site.konnect_short_name }}, use the [control plane setup UI](https://cloud.konghq.com/gateway-manager/create-gateway).

To create a {{ site.kic_product_name }} in {{ site.konnect_short_name }} deployment, you need the following items:

1. A {{ site.kic_product_name }} control plane, including the control plane URL.
1. An mTLS certificate for {{ site.kic_product_name }} to talk to {{ site.konnect_short_name }}.

{% include k8s/kic-konnect-install.md %}

## Install Kong

Kong provides Helm charts to install {{ site.kic_product_name }}. Add the Kong charts repo and update to the latest version:

```bash
helm repo add kong https://charts.konghq.com
helm repo update
```

The default values file installs {{ site.kic_product_name }} in [Gateway Discovery](#) mode with a DB-less {{ site.base_gateway }}. This is the recommended deployment topology.

Run the following command to install {{ site.kic_product_name }}:

{: data-deployment-topology="konnect" }
```bash
helm upgrade --install kong kong/ingress -n kong --values ./values.yaml
```

{: data-deployment-topology="on-prem" }
```bash
helm install kong kong/ingress -n kong --create-namespace
```

## Test connectivity to Kong

Call the proxy IP:

```bash
export PROXY_IP=$(kubectl get svc --namespace kong kong-gateway-proxy -o jsonpath='{range .status.loadBalancer.ingress[0]}{@.ip}{@.hostname}{end}')
curl -i $PROXY_IP
```

You will receive an `HTTP 404` response as there are no routes configured:

```
HTTP/1.1 404 Not Found
Content-Type: application/json; charset=utf-8
Connection: keep-alive
Content-Length: 48
X-Kong-Response-Latency: 0
Server: kong/{{site.latest_gateway_oss_version}}

{"message":"no Route matched with those values"}
```
