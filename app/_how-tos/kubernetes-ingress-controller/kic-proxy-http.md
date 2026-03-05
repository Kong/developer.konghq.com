---
title: Proxy HTTP Traffic
description: "Route HTTP requests to services in your cluster using HTTPRoute or Ingress"
content_type: how_to
related_resources:
  - text: All KIC documentation
    url: /index/kubernetes-ingress-controller/

permalink: /kubernetes-ingress-controller/routing/http/
breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Routing


products:
  - kic

works_on:
  - on-prem
  - konnect

entities:
  - service
  - route

tags:
  - routing
 
tldr:
  q: How do I route HTTP traffic with {{ site.kic_product_name }}?
  a: Create an `HTTPRoute` or `Ingress` resource, which will then be converted into a [{{ site.base_gateway }} Service](/gateway/entities/service/) and [Route](/gateway/entities/route/).

prereqs:
  kubernetes:
    gateway_api: true
  entities:
    services:
      - echo-service

cleanup:
  inline:
    - title: Uninstall KIC from your cluster
      include_content: cleanup/products/kic
      icon_url: /assets/icons/kubernetes.svg
---

## Create an HTTPRoute

To route HTTP traffic, you need to create an `HTTPRoute` or an `Ingress` resource pointing at your Kubernetes `Service`:
<!--vale off-->
{% httproute %}
name: echo
matches:
  - path: /echo
    service: echo
    port: 1027
skip_host: true
{% endhttproute %}
<!--vale on-->
## Validate your configuration

{% validation kubernetes-wait-for %}
kind: httproute
resource: echo
{% endvalidation %}

Once the resource has been reconciled, you'll be able to call the `/echo` endpoint and {{ site.base_gateway }} will route the request to the `echo` service:

{% validation request-check %}
url: /echo
status_code: 200
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}
