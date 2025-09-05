---
title: Mesh HTTP Route
name: MeshHttpRoutes
products:
    - mesh
description: "Alter and redirect HTTP requests depending on where the request is coming from and where it's going to."
content_type: plugin
type: policy
icon: meshhttproute.png
---


The `MeshHTTPRoute` policy allows altering and redirecting HTTP requests
depending on where the request is coming from and where it's going to.

## TargetRef support matrix

{% if_version gte:2.6.x %}
{% tabs %}
{% tab Sidecar %}
{% if_version lte:2.8.x %}
| `targetRef`           | Allowed kinds                                            |
| --------------------- | -------------------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
| `to[].targetRef.kind` | `MeshService`                                            |
{% endif_version %}
{% if_version eq:2.9.x %}
| `targetRef`           | Allowed kinds                                            |
| --------------------- | -------------------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `MeshSubset`                                     |
| `to[].targetRef.kind` | `MeshService`                                            |
{% endif_version %}
{% if_version gte:2.10.x %}
| `targetRef`           | Allowed kinds                                 |
| --------------------- | --------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `Dataplane`, `MeshSubset(deprecated)` |
| `to[].targetRef.kind` | `MeshService`                                 |
{% endif_version %}
{% endtab %}

{% tab Builtin Gateway %}
| `targetRef`             | Allowed kinds                                            |
| ----------------------- | -------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshGateway`, `MeshGateway` with listener `tags`|
| `to[].targetRef.kind`   | `Mesh`                                                   |
{% endtab %}

{% tab Delegated Gateway %}
{% if_version lte:2.8.x %}
| `targetRef`           | Allowed kinds                                            |
| --------------------- | -------------------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
| `to[].targetRef.kind` | `MeshService`                                            |
{% endif_version %}
{% if_version gte:2.9.x %}
| `targetRef`           | Allowed kinds                                            |
| --------------------- | -------------------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `MeshSubset`                                     |
| `to[].targetRef.kind` | `MeshService`                                            |
{% endif_version %}
{% endtab %}

{% endtabs %}

{% endif_version %}
{% if_version lte:2.5.x %}

| TargetRef type    | top level | to  | from |
| ----------------- | --------- | --- | ---- |
| Mesh              | ✅        | ❌  | ❌   |
| MeshSubset        | ✅        | ❌  | ❌   |
| MeshService       | ✅        | ✅  | ❌   |
| MeshServiceSubset | ✅        | ❌  | ❌   |

{% endif_version %}

If you don't understand this table you should read [matching docs](/docs/{{ page.release }}/policies/introduction).

## Configuration

Unlike others outbound policies `MeshHTTPRoute` doesn't contain `default` directly in the `to` array.
The `default` section is nested inside `rules`, so the policy structure looks like this:

```yaml
spec:
  to:
    - targetRef: {...}
      rules:
        - matches: [...] # various ways to match an HTTP request (path, method, query)
          default: # configuration applied for the matched HTTP request
            filters: [...]
            backendRefs: [...]
```

{% tip %}
Remember to tag your `Service` ports with `appProtocol: http` to use
them in a `MeshHTTPRoute`!
{% endtip %}

### Gateways

In order to route HTTP traffic for a MeshGateway, you need to target the
MeshGateway in `spec.targetRef` and set `spec.to[].targetRef.kind: Mesh`.

### Interactions with `MeshTCPRoute`

`MeshHTTPRoute` takes priority over [`MeshTCPRoute`](../meshtcproute) when a proxy is targeted by both and the matching `MeshTCPRoute` is ignored.

### Interactions with `TrafficRoute`

`MeshHTTPRoute` takes priority over [`TrafficRoute`](../traffic-route) when a proxy is targeted by both policies.

All legacy policies like `Retry`, `TrafficLog`, `Timeout` etc. only match on routes defined by `TrafficRoute`.
All new recommended policies like `MeshRetry`, `MeshAccessLog`, `MeshTimeout` etc. match on routes defined by `MeshHTTPRoute` and `TrafficRoute`.

If you don't use legacy policies, it's recommended to remove any existing `TrafficRoute`.
Otherwise, it's recommended to migrate to new policies and then removing `TrafficRoute`.  

## Merging

When several `MeshHTTPRoute` policies target the same data plane proxy they're merged.
Similar to the new policies the merging order is determined by
[the top level targetRef](/docs/{{ page.release }}/policies/introduction).
The difference is in `spec.to[].rules`.
{{site.mesh_product_name}} treats `rules` as a key-value map
where `matches` is a key and `default` is a value. For example MeshHTTPRoute policies:

```yaml
# MeshHTTPRoute-1
rules:
  - matches: # key-1
      - path:
          type: Exact
          name: /orders
        method: GET
    default: CONF_1 # value
  - matches: # key-2
      - path:
          type: Exact
          name: /payments
        method: POST
    default: CONF_2 # value
---
# MeshHTTPRoute-2
rules:
  - matches: # key-3
      - path:
          type: Exact
          name: /orders
        method: GET
    default: CONF_3 # value
  - matches: # key-4
      - path:
          type: Exact
          name: /payments
        method: POST
    default: CONF_4 # value
```

merged in the following list of rules:

```yaml
rules:
  - matches:
      - path:
          type: Exact
          name: /orders
        method: GET
    default: merge(CONF_1, CONF_3) # because 'key-1' == 'key-3'
  - matches:
      - path:
          type: Exact
          name: /payments
        method: POST
    default: merge(CONF_2, CONF_4) # because 'key-2' == 'key-4'
```

## All policy options

### Matches

- **`path`** - (optional) - HTTP path to match the request on
  - **`type`** - one of `Exact`, {% if_version gte:2.3.x %}`PathPrefix`{% endif_version %}{% if_version lte:2.2.x %}`Prefix`{% endif_version %}, `RegularExpression`
  - **`value`** - actual value that's going to be matched depending on the `type`
- **`method`** - (optional) - HTTP2 method, available values are
  `CONNECT`, `DELETE`, `GET`, `HEAD`, `OPTIONS`, `PATCH`, `POST`, `PUT`, `TRACE`
- **`queryParams`** - (optional) - list of HTTP URL query parameters. Multiple matches are combined together
  such that all listed matches must succeed
  - **`type`** - one of `Exact` or `RegularExpression`
  - **`name`** - name of the query parameter
  - **`value`** - actual value that's going to be matched depending on the `type`

### Default conf

- **`filters`** - (optional) - a list of modifications applied to the matched request
  - **`type`** - available values are `RequestHeaderModifier`, `ResponseHeaderModifier`,
    `RequestRedirect`, `URLRewrite`.
  - **`requestHeaderModifier`** - [HeaderModifier](#header-modification), must be set if the `type` is `RequestHeaderModifier`.
  - **`responseHeaderModifier`** - [HeaderModifier](#header-modification), must be set if the `type` is `ResponseHeaderModifier`.
  - **`requestRedirect`** - must be set if the `type` is `RequestRedirect`
    - **`scheme`** - one of `http` or `http2`
    - **`hostname`** - is the fully qualified domain name of a network host. This
      matches the RFC 1123 definition of a hostname with 1 notable exception that
      numeric IP addresses are not allowed.
    - **`port`** - is the port to be used in the value of the `Location` header in
      the response. When empty, port (if specified) of the request is used.
    - **`statusCode`** - is the HTTP status code to be used in response. Available values are
      `301`, `302`, `303`, `307`, `308`.
  - **`urlRewrite`** - must be set if the `type` is `URLRewrite`
    - **`hostname`** - (optional) - is the fully qualified domain name of a network host. This
      matches the RFC 1123 definition of a hostname with 1 notable exception that
      numeric IP addresses are not allowed.
    - **`path`** - (optional)
      - **`type`** - one of `ReplaceFullPath`, `ReplacePrefixMatch`
      - **`replaceFullPath`** - must be set if the `type` is `ReplaceFullPath`
      - **`replacePrefixMatch`** - must be set if the `type` is `ReplacePrefixMatch`
  - **`requestMirror`** - must be set if the `type` is `RequestMirror`
    - **`percentage`** - percentage of requests to mirror. If not specified, all requests to the target cluster will be mirrored.
    - **`backendRef`** - [BackendRef](#backends), destination to mirror request to
- **`backendRefs`** - [BackendRef](#backends) (optional), list of destinations to redirect requests to

### Header modification

- **`set`** - (optional) - list of headers to set. Overrides value if the header exists.
  - **`name`** - header's name
  - **`value`** - header's value
- **`add`** - (optional) - list of headers to add. Appends value if the header exists.
  - **`name`** - header's name
  - **`value`** - header's value
- **`remove`** - (optional) - list of headers' names to remove

### Backends

- **`kind`** - one of `MeshService`, `MeshServiceSubset`{% if_version gte:2.9.x %}, `MeshExtenalService`{% endif_version %}
- **`name`** - service name
- **`tags`** - service tags, must be specified if the `kind` is `MeshServiceSubset`
- **`weight`** - when a request matches the route, the choice of an upstream cluster
  is determined by its weight. Total weight is a sum of all weights in `backendRefs` list.
