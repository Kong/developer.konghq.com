---
title: Rewriting paths

description: |
  Rewrite the request path before sending it to your upstream service.

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
  - text: Rewriting hosts
    url: /kubernetes-ingress-controller/reference/host-manipulation/
  
breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Reference
---

Users have the following options to modify the default path handling behavior:

* Remove the path prefix using `strip-path`
* {% new_in 3.2 %} Rewrite using Gateway API's `URLRewrite` filter
* Rewrite using regular expressions
* Add a path prefix using the `path` annotation

### Strip the path

{:.info}
> This is the default behavior of {{ site.kic_product_name }}. Set `konghq.com/strip-path="false"` to disable this behavior

Add the [`konghq.com/strip-path` annotation](/kubernetes-ingress-controller/reference/annotations/#konghq-com-strip-path) to your Ingress, which strips the path component of the Route/Ingress, leaving the remainder of the path at the root:

{% navtabs api %}
{% navtab "Gateway API" %}
```bash
kubectl patch httproute NAME --type merge \
  -p '{"metadata":{"annotations":{"konghq.com/strip-path":"true"}}}'
```
{% endnavtab %}
{% navtab "Ingress" %}
```bash
kubectl patch ingress NAME --type merge \
  -p '{"metadata":{"annotations":{"konghq.com/strip-path":"true"}}}'
```
{% endnavtab %}
{% endnavtabs %}

If your routing rule contains `path: /user`, a request to `GET /user/details` will have the routing rule path stripped leaving `GET /details` in the request to the upstream.

{% table %}
columns:
  - title: HTTPRoute/Ingress path
    key: path
  - title: Original Request
    key: original
  - title: Upstream Request
    key: upstream
rows:
  - path: /
    original: /example/here
    upstream: /example/here
  - path: /example
    original: /example/here
    upstream: /here
  - path: /example/here
    original: /example/here
    upstream: /
{% endtable %}

### Rewriting the path

In many cases, stripping the path prefix is not enough. Internal systems contain URLs that are not suitable for external publication. {{ site.kic_product_name }} can transparently rewrite the URLs to provide a user friendly interface to external consumers.

### Using the konghq.com/rewrite annotation

{:.warning}
> This feature requires the [`RewriteURIs` feature gate](/kubernetes-ingress-controller/reference/feature-gates/) to be activated and only works with `Ingress` resources

Add the `konghq.com/rewrite` annotation to your Ingress, which allows you set a specific path for the upstream request. Any regex matches defined in your Route definition are usable (see the [annotation documentation](/kubernetes-ingress-controller/reference/annotations/#konghq-com-rewrite) for more information):

```bash
kubectl patch ingress NAME --type merge \
  -p '{"metadata":{"annotations":{"konghq.com/rewrite":"/hello/world"}}}'
```

Any query string parameters in the incoming request are left untouched.

{% table %}
columns:
  - title: Original Request
    key: original
  - title: Upstream Request
    key: upstream
rows:
  - original: /
    upstream: /hello/world
  - original: /example
    upstream: /hello/world
  - original: /example?demo=true
    upstream: /hello/world?demo=true
{% endtable %}

You can use the `konghq.com/rewrite` annotation with regular expressions to capture input parameters and pass them to the upstream. See the [rewriting paths with the konghq.com/rewrite annotation](/kubernetes-ingress-controller/routing/rewriting-paths/) how-to for more details.

#### Using Gateway API filters

You can replace the full path for a request by adding the `URLRewrite` filter with `path.replaceFullPath` to your `HTTPRoute`.

```yaml
...
filters:
- type: URLRewrite
  urlRewrite:
    path:
      type: ReplaceFullPath
      replaceFullPath: /rewritten-path
```

Alternatively, you can add the `URLRewrite` filter with `path.replacePrefixMatch` to your `HTTPRoute` rule to rewrite the path prefix.

See the [URLRewrite filter documentation](https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io%2fv1.HTTPPathModifier)
for more information.

```yaml
...
rules:
  - matches:
      - path:
          type: PathPrefix # Only PathPrefix path type is supported with URLRewrite filter using path.type == ReplacePrefixMatch.
          value: /old-prefix
    filters:
     - type: URLRewrite
       urlRewrite:
         path:
           type: ReplacePrefixMatch
           replacePrefixMatch: /new-prefix
```

### Prepend a path
Add the [`konghq.com/path` annotation](/kubernetes-ingress-controller/reference/annotations/#konghq-com-path) to your Service, which prepends that value to the upstream path:

```bash
kubectl patch service NAME -p '{"metadata":{"annotations":{"konghq.com/path":"/api"}}}'
```

{% table %}
columns:
  - title: Original Request
    key: original
  - title: Upstream Request
    key: upstream
rows:
  - original: /
    upstream: /api
  - original: /example
    upstream: /api/example
  - original: /example?demo=true
    upstream: /api/example?demo=true
{% endtable %}