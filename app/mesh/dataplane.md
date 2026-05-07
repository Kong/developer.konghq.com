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

The `Dataplane` resource configures a [data plane proxy](/mesh/data-plane-proxy/) (also called a sidecar). The proxy runs alongside each workload and handles all inbound and outbound traffic for that workload.

On Kubernetes, {{site.mesh_product_name}} generates `Dataplane` resources automatically when the sidecar is injected into a Pod. On Universal, you must create `Dataplane` resources manually to register workloads with the mesh.

Each `Dataplane` belongs to exactly one mesh.

## Examples

The following examples show common `Dataplane` configurations for Universal deployments. On Kubernetes, {{site.mesh_product_name}} generates these resources automatically.

### Basic Dataplane with single inbound

Register a workload that exposes a single HTTP port:

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

### Dataplane with multiple inbounds

Configure a `Dataplane` for a workload that exposes more than one port:

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

### Dataplane with outbounds and no transparent proxying

Declare each upstream service the workload calls as an explicit outbound listener:

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

### Dataplane with transparent proxying

Use [transparent proxying](/mesh/transparent-proxying/) so the workload reaches mesh services by their service name without declaring outbounds:

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

### Dataplane with service probes

Configure [health probes](/mesh/policies/service-health-probes/) so {{site.mesh_product_name}} can detect when the workload becomes unhealthy and stop routing traffic to it:

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

### Dataplane with advertised address

Set an advertised address when the proxy runs in a private network, such as a Docker container:

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

### Delegated gateway Dataplane

Register an existing API gateway (such as {{site.base_gateway}}) as a delegated gateway that fronts the mesh:

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

### Built-in gateway Dataplane

Run a [built-in gateway](/mesh/built-in-gateway/) for ingress traffic, configured through `MeshGateway` resources:

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

## Schema

{% json_schema Dataplane type=proto %}
