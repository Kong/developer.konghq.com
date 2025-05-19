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
---

{: data-deployment-topology="konnect" }
## Konnect setup

{:.info}
> For UI setup instructions to install {{ site.kic_product_name }} on {{ site.konnect_short_name }}, use the [Gateway Manager setup UI](https://cloud.konghq.com/us/gateway-manager/create-control-plane).

To create a {{ site.kic_product_name }} in {{ site.konnect_short_name }} deployment, you need the following items:

1. A {{ site.kic_product_name }} Control Plane, including the Control Plane URL
1. An mTLS certificate for {{ site.kic_product_name }} to talk to {{ site.konnect_short_name }}

{% include k8s/kic-konnect-install.md %}

## Install Kong

Kong provides Helm charts to install {{ site.kic_product_name }}. Add the Kong charts repo and update to the latest version:

```bash
helm repo add kong https://charts.konghq.com
helm repo update
```

The default values file installs {{ site.kic_product_name }} in [Gateway Discovery](#) mode with a DB-less {{ site.base_gateway }}. This is the recommended deployment topology.

Run `helm upgrade --install` to install {{ site.kic_product_name }}:

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
Server: kong/3.9.0

{"message":"no Route matched with those values"}
```
