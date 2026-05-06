---
title: Dataplane
description: Defines configuration for data plane proxies (sidecars) that handle service mesh traffic.

content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

tags:
  - data-plane
  - service-mesh

related_resources:
  - text: Data plane proxy
    url: /mesh/data-plane-proxy/
  - text: Configure the data plane on Kubernetes
    url: /mesh/data-plane-kubernetes/
  - text: Configure the data plane on Universal
    url: /mesh/data-plane-universal/
  - text: Transparent proxying
    url: /mesh/transparent-proxying/
  - text: Service health probes
    url: /mesh/policies/service-health-probes/
  - text: Built-in gateways
    url: /mesh/built-in-gateway/
---

The `Dataplane` resource defines the configuration of a [data plane proxy](/mesh/concepts/#data-plane) (also called a sidecar). A data plane proxy runs next to each workload and handles all inbound and outbound traffic for that workload.

On Kubernetes, {{site.mesh_product_name}} automatically generates `Dataplane` resources when pods are injected with the sidecar. On Universal, you must manually create `Dataplane` resources to register workloads with the mesh.

Each `Dataplane` belongs to exactly one mesh.

## Examples

### Basic Dataplane with single inbound (Universal)

{% navtabs "environment" %}
{% navtab "Universal" %}

```yaml
type: Dataplane
mesh: default
name: web-01
networking:
  address: 192.168.0.1
  inbound:
    - port: 8080
      servicePort: 8080
      tags:
        kuma.io/service: web
        kuma.io/protocol: http
        version: v1
```

{% endnavtab %}
{% endnavtabs %}

### Dataplane with multiple inbounds (Universal)

When a workload exposes multiple ports:

{% navtabs "environment" %}
{% navtab "Universal" %}

```yaml
type: Dataplane
mesh: default
name: backend-01
networking:
  address: 192.168.0.2
  inbound:
    - port: 8080
      servicePort: 8080
      tags:
        kuma.io/service: backend-http
        kuma.io/protocol: http
    - port: 9090
      servicePort: 9090
      tags:
        kuma.io/service: backend-grpc
        kuma.io/protocol: grpc
```

{% endnavtab %}
{% endnavtabs %}

### Dataplane with outbounds (Universal, without transparent proxying)

{% navtabs "environment" %}
{% navtab "Universal" %}

```yaml
type: Dataplane
mesh: default
name: web-01
networking:
  address: 192.168.0.1
  inbound:
    - port: 8080
      servicePort: 8080
      tags:
        kuma.io/service: web
        kuma.io/protocol: http
  outbound:
    - port: 10001
      tags:
        kuma.io/service: backend
    - port: 10002
      tags:
        kuma.io/service: database
```

{% endnavtab %}
{% endnavtabs %}

### Dataplane with transparent proxying (Universal)

{% navtabs "environment" %}
{% navtab "Universal" %}

```yaml
type: Dataplane
mesh: default
name: web-01
networking:
  address: 192.168.0.1
  inbound:
    - port: 8080
      servicePort: 8080
      tags:
        kuma.io/service: web
        kuma.io/protocol: http
  transparentProxying:
    redirectPortInbound: 15006
    redirectPortOutbound: 15001
    reachableServices:
      - backend
      - database
```

{% endnavtab %}
{% endnavtabs %}

### Dataplane with service probes (Universal)

{% navtabs "environment" %}
{% navtab "Universal" %}

```yaml
type: Dataplane
mesh: default
name: web-01
networking:
  address: 192.168.0.1
  inbound:
    - port: 8080
      servicePort: 8080
      tags:
        kuma.io/service: web
        kuma.io/protocol: http
      serviceProbe:
        interval: 10s
        timeout: 2s
        unhealthyThreshold: 3
        healthyThreshold: 1
        tcp: {}
```

{% endnavtab %}
{% endnavtabs %}

### Dataplane with advertised address (Universal)

For proxies in private networks (like Docker):

{% navtabs "environment" %}
{% navtab "Universal" %}

```yaml
type: Dataplane
mesh: default
name: web-01
networking:
  address: 172.17.0.2
  advertisedAddress: 10.0.0.1
  inbound:
    - port: 8080
      servicePort: 8080
      tags:
        kuma.io/service: web
        kuma.io/protocol: http
```

{% endnavtab %}
{% endnavtabs %}

### Delegated gateway Dataplane

{% navtabs "environment" %}
{% navtab "Universal" %}

```yaml
type: Dataplane
mesh: default
name: kong-gateway
networking:
  address: 192.168.0.10
  gateway:
    type: DELEGATED
    tags:
      kuma.io/service: kong-gateway
```

{% endnavtab %}
{% endnavtabs %}

### Builtin gateway Dataplane

{% navtabs "environment" %}
{% navtab "Universal" %}

```yaml
type: Dataplane
mesh: default
name: edge-gateway
networking:
  address: 192.168.0.10
  gateway:
    type: BUILTIN
    tags:
      kuma.io/service: edge-gateway
```

{% endnavtab %}
{% endnavtabs %}

## All options

{% schema_viewer Dataplane type=proto %}
