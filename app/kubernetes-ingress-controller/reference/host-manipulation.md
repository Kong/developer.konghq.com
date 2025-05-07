---
title: Rewriting hosts

description: |
  Customize the Host header that is sent to your upstream service.

content_type: reference
layout: reference

products:
  - kic

works_on:
  - on-prem
  - konnect

related_resources:
  - text: Using the konghq.com/rewrite annotation
    url: /kubernetes-ingress-controller/routing/rewriting-paths/
  - text: Rewriting paths
    url: /kubernetes-ingress-controller/reference/path-manipulation/

breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Reference
---

{{ site.kic_product_name }} provides two annotations for manipulating the `Host` header. These annotations allow for three different behaviours:

* Preserve the user-provided `Host` header
* Default to the `Host` of the upstream service
* Explicitly set the `Host` header to a known value

{% capture preserve_host %}
{% navtabs api %}
{% navtab "Gateway API" %}
```bash
kubectl patch httproute NAME --type merge -p '{"metadata":{"annotations":{"konghq.com/preserve-host":"false"}}}'
```
{% endnavtab %}
{% navtab "Ingress" %}
```bash
kubectl patch ingress NAME -p '{"metadata":{"annotations":{"konghq.com/preserve-host":"false"}}}'
``` 
{% endnavtab %}
{% endnavtabs %}
{% endcapture %}

### Preserve the Host header

{{ site.kic_product_name }} preserves the hostname in the request by default.

```bash
curl -H 'Host:kong.example' "$PROXY_IP/echo?details=true"
```

```text
HTTP request details
---------------------
Protocol: HTTP/1.1
Host: kong.example
Method: GET
URL: /?details=true
```

The `Host` header in the request to the upstream matches the `Host` header in the request to {{ site.base_gateway }}.

### Use the upstream Host name

You can disable `preserve-host` if you want the `Host` header to contain the upstream hostname of your service.

Add the `konghq.com/preserve-host` annotation to your Route:

{{ preserve_host }}

The `Host` header in the response now contains the upstream host and port.

```text
HTTP request details
---------------------
Protocol: HTTP/1.1
Host: 192.168.194.11:1027
Method: GET
URL: /?details=true
```
### Set the Host header explicitly

#### Using Gateway API {% new_in 3.2 %}

You can set the Host header explicitly when using Gateway API's HTTPRoute with [`URLRewrite`](https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io%2fv1.HTTPURLRewriteFilter) 
filter's `hostname` field. You only need to add a `URLRewrite` filter to your HTTPRoute rule.

```yaml
...
filters:
- type: URLRewrite
  urlRewrite:
    hostname: internal.myapp.example.com
```

#### Using the `konghq.com/host-header` annotation

You can set the Host header explicitly if needed by disabling `konghq.com/preserve-host` and setting the `konghq.com/host-header` annotation.

1. Add the [`konghq.com/preserve-host` annotation](/kubernetes-ingress-controller/reference/annotations/#konghq-com-preserve-host) to your Ingress, to disable `preserve-host` and send the hostname provided in the `host-header` annotation:

{{ preserve_host | indent }}

1. Add the [`konghq.com/host-header` annotation](/kubernetes-ingress-controller/reference/annotations/#konghq-com-host-header) to your Service, which sets
  the `Host` header directly:

   ```bash
   kubectl patch service NAME -p '{"metadata":{"annotations":{"konghq.com/host-header":"internal.myapp.example.com"}}}'
   ```

1. Make a `curl` request with a `Host` header:

   ```bash
   curl -H 'Host:kong.example' "$PROXY_IP/echo?details=true"
   ```

   The request upstream now uses the header from the `host-header` annotation:
   ```
   HTTP request details
   ---------------------
   Protocol: HTTP/1.1
   Host: internal.myapp.example.com:1027
   Method: GET
   URL: /?details=true
   ```