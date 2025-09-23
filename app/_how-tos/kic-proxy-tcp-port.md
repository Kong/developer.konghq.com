---
title: Proxy TCP traffic by port
description: "Route TCP requests to services in your cluster based on the incoming port using TCPRoute or TCPIngress"
content_type: how_to
related_resources:
  - text: All KIC documentation
    url: /index/kubernetes-ingress-controller/

permalink: /kubernetes-ingress-controller/routing/tcp-by-port/
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
  - tcp
  - routing

tldr:
  q: How do I route TCP traffic with {{ site.kic_product_name }}?
  a: Create a `TCPRoute` or `TCPIngress` resource, which will then be converted in to a [{{ site.base_gateway }} Service](/gateway/entities/service/) and [Route](/gateway/entities/route/).

prereqs:
  kubernetes:
    gateway_api: experimental
  entities:
    services:
      - echo-service

cleanup:
  inline:
    - title: Uninstall KIC from your cluster
      include_content: cleanup/products/kic
      icon_url: /assets/icons/kubernetes.svg
---

{% include /k8s/configure-tcp-listen.md plaintext=true tls=false %}

## Route TCP traffic

To publicly expose the Service, create a `TCPRoute` resource for Gateway APIs or a `TCPIngress` resource for Ingress.

{% navtabs api %}
{% navtab "Gateway API" %}

To reconcile the `TCPRoute`, configure an additional TCP listener on your `Gateway` resource:

```bash
kubectl patch -n kong --type=json gateway kong -p='[
    {
        "op":"add",
        "path":"/spec/listeners/-",
        "value":{
            "name":"stream9000",
            "port":9000,
            "protocol":"TCP"
        }
    }
]'
```

Next, create a `TCPRoute`:

```bash
echo "apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TCPRoute
metadata:
  name: echo-plaintext
  namespace: kong
spec:
  parentRefs:
  - name: kong
    sectionName: stream9000
  rules:
  - backendRefs:
    - name: echo
      port: 1025
" | kubectl apply -f -
```

{% endnavtab %}
{% navtab "Ingress" %}

{:.warning}
> **Important: TCPIngress Deprecation Notice**
>
> The `TCPIngress` custom resource is **deprecated** as of {{site.kic_product_name}} 3.5 and will be **completely removed in {{ site.operator_product_name }} 2.0.0**. This resource was created to address limitations of the traditional Kubernetes Ingress API, but since the Gateway API has reached maturity and widespread adoption, it's now redundant.
>
> **Migration is required** before upgrading to {{ site.operator_product_name }} 2.0.0. Use the [Migrating from Ingress to Gateway API](/kubernetes-ingress-controller/migrate/ingress-to-gateway/) guide to migrate your existing `TCPIngress` resource to its Gateway API equivalents (`TCPIngress` → `Gateway` + `TCPRoute` + `TLSRoute`).

```bash
echo "apiVersion: configuration.konghq.com/v1beta1
kind: TCPIngress
metadata:
  name: echo-plaintext
  namespace: kong
  annotations:
    kubernetes.io/ingress.class: kong
spec:
  rules:
  - port: 9000
    backend:
      serviceName: echo
      servicePort: 1025
" | kubectl apply -f -
```

{% endnavtab %}
{% endnavtabs %}

This configuration instructs {{site.base_gateway}} to forward all traffic it
receives on port 9000 to the `echo` Service on port 1025.

## Validate your configuration

You can now test your Route using `telnet`:

```shell
telnet $PROXY_IP 9000
```

After you connect, type some text that you want as a response from the echo Service.

```
Trying 192.0.2.3...
Connected to 192.0.2.3.
Escape character is '^]'.
Welcome, you are connected to node gke-harry-k8s-dev-pool-1-e9ebab5e-c4gw.
Running on Pod echo-844545646c-gvmkd.
In namespace default.
With IP address 192.0.2.7.
This text will be echoed back.
This text will be echoed back.
^]
telnet> Connection closed.
```
{:.no-copy-code}

To exit, press `ctrl+]` then `ctrl+d`.
