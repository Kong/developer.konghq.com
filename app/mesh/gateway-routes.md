---
title: "Configuring built-in routes with MeshHTTPRoute and MeshTCPRoute"
description: "Reference for configuring HTTP and TCP routing through built-in gateways using MeshHTTPRoute and MeshTCPRoute, including hostname matching and weighted backends."
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/
tags:
  - routing
  - service-mesh
  - tcp
min_version:
  mesh: '2.9'
related_resources:
  - text: Set up a built-in gateway
    url: /how-to/set-up-a-built-in-mesh-gateway/
  - text: Built-in gateways
    url: /mesh/built-in-gateway/
  - text: Configuring built-in listeners
    url: /mesh/gateway-listeners/
  - text: MeshHTTPRoute policy
    url: /mesh/policies/meshhttproute/
  - text: MeshTCPRoute policy
    url: /mesh/policies/meshtcproute/
---

To configure how traffic is forwarded from a listener to your mesh services, use [`MeshHTTPRoute`](/mesh/policies/meshhttproute/) and [`MeshTCPRoute`](/mesh/policies/meshtcproute/).

Using these route resources with a gateway requires using [`spec.targetRef`](/mesh/policies-introduction/) to target gateway data plane proxies.

{:.info}
> When using [`MeshHTTPRoute`](/mesh/policies/meshhttproute/) and [`MeshTCPRoute`](/mesh/policies/meshtcproute/) with built-in gateways, `spec.to[].targetRef` is restricted to `kind: Mesh`.

## MeshHTTPRoute

Here's an example of a `MeshHTTPRoute` resource:

{% policy_yaml use_meshservice=true %}
```yaml
type: MeshHTTPRoute
name: edge-gateway-route
mesh: default
spec:
  targetRef:
    kind: MeshGateway
    name: edge-gateway
    tags: # optional, for selecting specific listeners
      port: http-8080
  to:
    - targetRef:
        kind: Mesh
      hostnames: # optional, limit rules to specific domains
        - example.com
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /
          default:
            backendRefs:
              - kind: MeshService
                name: demo-app
                namespace: kuma-demo
                port: 5000
```
{% endpolicy_yaml %}

### Listener hostname

[`MeshGateway`](/mesh/meshgateway/) listeners have an optional `hostname` field that limits the traffic accepted by the listener depending on the protocol:

* HTTP: Host header must match
* TLS: SNI must match
* HTTPS: Both SNI and host must match

When attaching routes to specific listeners, the routes are isolated from each other. If we consider the following listeners:

```yaml
conf:
  listeners:
  - port: 8080
    protocol: HTTP
    hostname: foo.example.com
    tags:
      hostname: foo
  - port: 8080
    protocol: HTTP
    hostname: *.example.com
    tags:
      hostname: wild
```

Along with the following [`MeshHTTPRoute`](/mesh/policies/meshhttproute/) rule:

{% policy_yaml use_meshservice=true %}
```yaml
type: MeshHTTPRoute
name: http-route
mesh: default
spec:
  targetRef:
    kind: MeshGateway
    name: edge-gateway
    tags:
      hostname: wild
  to:
    - targetRef:
        kind: Mesh
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /
          default:
            backendRefs:
              - kind: MeshService
                name: example
                namespace: app
                port: 8080
```
{% endpolicy_yaml %}

This route explicitly attaches to the second listener with `hostname: *.example.com`.

This means that requests to `foo.example.com`, which match the first listener because it's more specific, will return a 404 because there are no routes attached for that listener.

### Route hostnames

[`MeshHTTPRoute`](/mesh/policies/meshhttproute/) rules can specify an additional list of hostnames to further limit the traffic handled by those rules. For example:

{% policy_yaml use_meshservice=true %}
```yaml
type: MeshHTTPRoute
name: http-route
mesh: default
spec:
  targetRef:
    kind: MeshGateway
    name: edge-gateway
  to:
    - targetRef:
        kind: Mesh
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /
          default:
            backendRefs:
              - kind: MeshService
                name: example-v1
                namespace: app
                port: 8080
    - targetRef:
        kind: Mesh
      hostnames:
        - dev.example.com
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /
          default:
            backendRefs:
              - kind: MeshService
                name: example-v2
                namespace: app
                port: 8080
```
{% endpolicy_yaml %}

This route would send all traffic to `dev.example.com` to the `v2` backend but other traffic to `v1`.

## `MeshTCPRoute`

If your traffic isn't HTTP, you can use [`MeshTCPRoute`](/mesh/policies/meshtcproute/) to balance traffic between services:

{% policy_yaml use_meshservice=true %}
```yaml
type: MeshTCPRoute
name: tcp-route
mesh: default
spec:
  targetRef:
    kind: MeshGateway
    name: edge-gateway
  to:
    - targetRef:
        kind: Mesh
      rules:
        - default:
            backendRefs:
              - kind: MeshService
                name: example-v1
                namespace: app
                port: 8080
                weight: 90
              - kind: MeshService
                name: example-v2
                namespace: app
                port: 8080
                weight: 10
```
{% endpolicy_yaml %}
