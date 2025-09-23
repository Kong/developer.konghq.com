---
title: Proxy UDP traffic by port
description: "Route UDP requests to services in your cluster using UDPRoute or UDPIngress"
content_type: how_to
related_resources:
  - text: All KIC documentation
    url: /index/kubernetes-ingress-controller/

permalink: /kubernetes-ingress-controller/routing/udp-by-port/
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
  - udp
  - routing

tldr:
  q: How do I route UDP traffic with {{ site.kic_product_name }}?
  a: Create a `UDPRoute` or `UDPIngress` resource, which will then be converted in to a [{{ site.base_gateway }} Service](/gateway/entities/service/) and [Route](/gateway/entities/route/).

prereqs:
  kubernetes:
    gateway_api: experimental
  entities:
    services:
      - udp-service

cleanup:
  inline:
    - title: Uninstall KIC from your cluster
      include_content: cleanup/products/kic
      icon_url: /assets/icons/kubernetes.svg
---

## Add UDP listens

{{site.base_gateway}} doesn't include any UDP listen configuration by default. To expose UDP listens, update the Deployment’s environment variables and port configuration.

1. Set the `KONG_STREAM_LISTEN` environment variable and expose port `9999` in the Deployment:

    ```bash
    kubectl patch deploy -n kong kong-gateway --patch '{
      "spec": {
        "template": {
          "spec": {
            "containers": [
              {
                "name": "proxy",
                "env": [
                  {
                    "name": "KONG_STREAM_LISTEN",
                    "value": "0.0.0.0:9999 udp"
                  }
                ],
                "ports": [
                  {
                    "containerPort": 9999,
                    "name": "stream9999",
                    "protocol": "UDP"
                  }
                ]
              }
            ]
          }
        }
      }
    }'
    ```

1.  Update the proxy Service to indicate the new ports:

    ```bash
    kubectl patch service -n kong kong-gateway-proxy --patch '{
      "spec": {
        "ports": [
          {
            "name": "stream9999",
            "port": 9999,
            "protocol": "UDP",
            "targetPort": 9999
          }
        ]
      }
    }'
    ```

## Route UDP traffic

To expose the service to the outside world, create a UDPRoute resource for Gateway APIs or a UDPIngress resource for Ingress.

{% navtabs api %}
{% navtab "Gateway API" %}

To reconcile the `UDPRoute`, configure an additional UDP listener on your `Gateway` resource:

```bash
kubectl patch -n kong --type=json gateway kong -p='[
    {
        "op":"add",
        "path":"/spec/listeners/-",
        "value":{
            "name":"stream9999",
            "port":9999,
            "protocol":"UDP",
            "allowedRoutes": {
                "namespaces": {
                  "from": "All"
                }
            }
        }
    }
]'
```

Next, create a `UDPRoute`:

```bash
echo "apiVersion: gateway.networking.k8s.io/v1alpha2
kind: UDPRoute
metadata:
  name: tftp
  namespace: kong
spec:
  parentRefs:
  - name: kong
    namespace: kong
  rules:
  - backendRefs:
    - name: tftp
      port: 9999
" | kubectl apply -f -
```

{% endnavtab %}
{% navtab "Ingress" %}

{:.warning}
> **Important: UDPIngress Deprecation Notice**
>
> The `UDPIngress` custom resource is **deprecated** as of {{site.kic_product_name}} 3.5 and will be **completely removed in {{ site.operator_product_name }} 2.0.0**. This resource was created to address limitations of the traditional Kubernetes Ingress API, but since the Gateway API has reached maturity and widespread adoption, it's now redundant.
>
> **Migration is required** before upgrading to {{ site.operator_product_name }} 2.0.0. Use the [Migrating from Ingress to Gateway API](/kubernetes-ingress-controller/migrate/ingress-to-gateway/) guide to migrate your existing `UDPIngress` resource to its Gateway API equivalents (`UDPIngress` → `Gateway` + `UDPRoute`).

```bash
echo "apiVersion: configuration.konghq.com/v1beta1
kind: UDPIngress
metadata:
  name: tftp
  namespace: kong
  annotations:
    kubernetes.io/ingress.class: kong
spec:
  rules:
  - backend:
      serviceName: tftp
      servicePort: 9999
    port: 9999
" | kubectl apply -f -
```

{% endnavtab %}
{% endnavtabs %}

This configuration routes traffic to UDP port `9999` on the
{{site.base_gateway}} proxy to port `9999` on the TFTP test server.

## Validate your configuration

Send a TFTP request through the proxy:

```bash
curl -s tftp://$PROXY_IP:9999/hello
```

The results should look like this:

```text
Hostname: tftp-5849bfd46f-nqk9x

Request Information:
  client_address=10.244.0.1
  client_port=39364
  real path=/hello
  request_scheme=tftp
```
