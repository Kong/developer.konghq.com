---
title: Proxy HTTPS Traffic with TLS Termination
description: "Route HTTPS requests to services in your cluster using HTTPRoute or Ingress"
content_type: how_to

permalink: /kubernetes-ingress-controller/routing/https-tls-termination/
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
  q: How do I route HTTPS traffic with {{ site.kic_product_name }}?
  a: Create an `HTTPRoute` or `Ingress` resource, which will then be converted into a [{{ site.base_gateway }} Service](/gateway/entities/service/) and [Route](/gateway/entities/route/). Specify a Kubernetes Secret containing a TLS certificate to terminate HTTPS requests using {{ site.base_gateway }}.

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

## Generate a TLS certificate

{% include /k8s/create-certificate.md namespace='kong' hostname='demo.example.com' cert_required=true %}

## Route HTTPs traffic

To listen for HTTPS traffic, configure an additional TLS listener on your `Gateway` resource:

```bash
kubectl patch -n kong --type=json gateway kong -p='[
    {
        "op":"add",
        "path":"/spec/listeners/-",
        "value":{
            "name": "https",
            "port": 443,
            "protocol":"HTTPS",
            "hostname":"demo.example.com",
            "allowedRoutes": {
              "namespaces": {
                "from": "All"
              }
            },
            "tls": {
              "mode": "Terminate",
              "certificateRefs":[{
                "group":"",
                "kind":"Secret",
                "name":"demo.example.com"
              }]
            }
        }
    }
]'
```
{: data-test-step="block"}

## Create an HTTPRoute

To route HTTP traffic, you need to create an `HTTPRoute` or an `Ingress` resource pointing at your Kubernetes `Service`.


<!--vale off-->
{% httproute %}
name: echo
matches:
  - path: /echo
    service: echo
    port: 1027
hostname: demo.example.com
section_name: https
{% endhttproute %}
<!--vale on-->
## Validate your configuration

{% validation kubernetes-wait-for %}
kind: httproute
resource: echo
{% endvalidation %}


Once the resource has been reconciled, you'll be able to call the `/echo` endpoint and {{ site.base_gateway }} will route the request to the `echo` service.

{% validation request-check %}
url: /echo
insecure: true
headers:
  - "Host: demo.example.com"
status_code: 200
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}
