---
title: Configure an ExternalService
description: "Expose a service located outside the Kubernetes cluster"
content_type: how_to
related_resources:
  - text: All KIC documentation
    url: /index/kubernetes-ingress-controller/

permalink: /kubernetes-ingress-controller/routing/external-service/
breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Routing

products:
  - kic

works_on:
  - on-prem
  - konnect

entities: []

tldr:
  q: How do I route traffic outside of my Kubernetes cluster?
  a: Configure an `ExternalName` service, then create a `HTTPRoute` to route traffic to the service.

prereqs:
  kubernetes:
    gateway_api: true

cleanup:
  inline:
    - title: Uninstall KIC from your cluster
      include_content: cleanup/products/kic
      icon_url: /assets/icons/kubernetes.svg
---

## Create an `ExternalName` Kubernetes service

```bash
echo '
kind: Service
apiVersion: v1
metadata:
  name: proxy-to-httpbin
  namespace: kong
spec:
  ports:
  - protocol: TCP
    port: 80
  type: ExternalName
  externalName: httpbin.konghq.com
' | kubectl apply -f -
```

## Create a HTTPRoute

To route HTTP traffic, you need to create a `HTTPRoute` or an `Ingress` resource pointing at your Kubernetes `Service`.

{% include /k8s/httproute.md release=page.release path='/httpbin' name='proxy-from-k8s-to-httpbin' service='proxy-to-httpbin' port='80' skip_host=true %}

## Validate your configuration

Once the resource has been reconciled, you'll be able to call the `/httpbin` endpoint and {{ site.base_gateway }} will route the request to the external `httpbin` service.

{% validation request-check %}
url: /httpbin/anything
status_code: 200
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}
