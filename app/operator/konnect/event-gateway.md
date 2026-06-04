---
title: "{{ site.event_gateway }} with {{ site.operator_product_name }}"
description: "Deploy and validate {{ site.event_gateway }} resources with {{ site.operator_product_name }}"
content_type: reference
layout: reference
products:
  - operator
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: Key Concepts

min_version:
  operator: '2.2'

related_resources:
  - text: Deploy {{ site.event_gateway }} with port mapping
    url: /operator/get-started/event-gateway/port-mapping/
  - text: Deploy {{ site.event_gateway }} with TLSRoute and SNI
    url: /operator/get-started/event-gateway/tlsroute-sni/
  - text: "{{ site.event_gateway }} architecture"
    url: /event-gateway/architecture/
  - text: Backend clusters
    url: /event-gateway/entities/backend-cluster/
  - text: Virtual clusters
    url: /event-gateway/entities/virtual-cluster/
  - text: Listeners
    url: /event-gateway/entities/listener/
  - text: Policies
    url: /event-gateway/entities/policy/
  - text: Gateway API
    url: /operator/dataplanes/gateway-api/
  - text: Cross namespace references
    url: /operator/konnect/cross-namespace-references/

---

{{ site.operator_product_name }} reconciles {{ site.event_gateway }} resources and deploys a matching `KegDataPlane` workload in your Kubernetes cluster.

For a step-by-step walkthrough you can apply directly to a cluster, see the [{{ site.event_gateway }} getting started guide](/operator/get-started/event-gateway/install/).

The operator manages three layers:

- A `KonnectEventGateway` control plane in `konnect.konghq.com/v1alpha1`
- {{ site.event_gateway_short }} configuration resources in `configuration.konghq.com/v1alpha1`
- A `KegDataPlane` workload in `eventgateway.konghq.com/v1alpha1`

## Resource model

{% table %}
columns:
  - title: Resource
    key: resource
  - title: API group
    key: api_group
  - title: Purpose
    key: purpose
rows:
  - resource: "`KonnectEventGateway`"
    api_group: "`konnect.konghq.com/v1alpha1`"
    purpose: Creates the {{ site.event_gateway_short }} control plane in {{ site.konnect_short_name }}
  - resource: "`EventGatewayBackendCluster`"
    api_group: "`configuration.konghq.com/v1alpha1`"
    purpose: Describes the upstream Kafka cluster
  - resource: "`EventGatewayVirtualCluster`"
    api_group: "`configuration.konghq.com/v1alpha1`"
    purpose: Defines the virtual cluster presented to clients
  - resource: "`EventGatewayListener`"
    api_group: "`configuration.konghq.com/v1alpha1`"
    purpose: Declares listener addresses and ports
  - resource: "`EventGatewayListenerPolicy`"
    api_group: "`configuration.konghq.com/v1alpha1`"
    purpose: Configures routing and TLS behavior on the listener
  - resource: "`EventGatewayVirtualClusterConsumePolicy`"
    api_group: "`configuration.konghq.com/v1alpha1`"
    purpose: Applies consume-side policy to a virtual cluster
  - resource: "`EventGatewayVirtualClusterProducePolicy`"
    api_group: "`configuration.konghq.com/v1alpha1`"
    purpose: Applies produce-side policy to a virtual cluster
  - resource: "`KegDataPlane`"
    api_group: "`eventgateway.konghq.com/v1alpha1`"
    purpose: Deploys the {{ site.event_gateway_short }} data plane in Kubernetes
{% endtable %}

Resources reference each other in this order:

1. `EventGatewayBackendCluster.spec.gatewayRef` points to a `KonnectEventGateway`
2. `EventGatewayVirtualCluster.spec.eventGatewayBackendClusterRef` points to an `EventGatewayBackendCluster`
3. `EventGatewayListener.spec.gatewayRef` points to the same `KonnectEventGateway`
4. `EventGatewayListenerPolicy.spec.eventGatewayListenerRef` points to an `EventGatewayListener`
5. Consume and produce policies point to an `EventGatewayVirtualCluster`
6. `KegDataPlane.spec.controlPlaneRef` points to the `KonnectEventGateway`

## Deployment patterns

There are two ways to expose {{ site.event_gateway }} with the operator:
* [`LoadBalancer` with `portMapping`](#loadbalancer-with-portmapping). Use this pattern if:
  * you need a fast local validation loop
  * you can expose one port per broker
  * a stable external IP is acceptable for clients
* [`Gateway` with `TLSRoute` and SNI](#gateway-with-tlsroute-and-sni). Use this pattern if:
  * you want a production-oriented edge pattern
  * you need a single public Kafka listener
  * you want broker metadata returned as DNS names on one port
  * you plan to front multiple virtual clusters behind one entrypoint


### `LoadBalancer` with `portMapping`

This pattern suits local validation and simple deployments where exposing one port per broker is acceptable. The `KegDataPlane` exposes a `LoadBalancer` Service with one port for bootstrap traffic and one port per broker.

The listener policy uses `forwardToVirtualCluster.config.type: portMapping`:

```yaml
apiVersion: configuration.konghq.com/v1alpha1
kind: EventGatewayListenerPolicy
metadata:
  name: example-listener-policy
  namespace: kong
spec:
  apiSpec:
    type: forwardToVirtualCluster
    forwardToVirtualCluster:
      name: forward
      config:
        type: portMapping
        portMapping:
          advertisedHost: "10.0.1.1"
          bootstrapPort: at_start
          destination:
            name: example_virtual_cluster
  eventGatewayListenerRef:
    type: namespacedRef
    namespacedRef:
      name: example-listener
```

{:.info}
> Set `advertisedHost` explicitly. Kafka clients use it when resolving broker metadata after bootstrap.

In a three-broker cluster, the data plane Service exposes:

- `9092` for bootstrap
- `9093` for broker 0
- `9094` for broker 1
- `9095` for broker 2

For a full deployment walkthrough, see [Deploy {{ site.event_gateway }} with port mapping](/operator/get-started/event-gateway/port-mapping/).

### `Gateway` with `TLSRoute` and SNI

This is the production-oriented pattern. A single TLS listener at the Kubernetes edge routes Kafka traffic to the correct virtual cluster by SNI:

- A Kubernetes `Gateway` exposes a single TLS listener
- A `TLSRoute` forwards encrypted traffic to the `KegDataPlane` Service
- An `EventGatewayListenerPolicy` with `type: tlsServer` terminates TLS in {{ site.event_gateway }}
- A second `EventGatewayListenerPolicy` with `forwardToVirtualCluster.config.type: sni` routes clients by SNI

This keeps the public edge to a single port and returns broker metadata as stable DNS names instead of distinct ports.

The SNI forwarding policy looks like this:

```yaml
apiVersion: configuration.konghq.com/v1alpha1
kind: EventGatewayListenerPolicy
metadata:
  name: sni-forward
  namespace: kong
spec:
  apiSpec:
    type: forwardToVirtualCluster
    forwardToVirtualCluster:
      name: forward_sni
      config:
        type: sni
        sni:
          sniSuffix: ".keg.example.com"
          brokerHostFormat:
            type: per_cluster_suffix
          advertisedPort: 9092
  eventGatewayListenerRef:
    type: namespacedRef
    namespacedRef:
      name: sni-listener
```

With a virtual cluster `dnsLabel` of `vc-tls-1`, clients receive metadata like:

- `bootstrap.vc-tls-1.keg.example.com:9092`
- `broker-0.vc-tls-1.keg.example.com:9092`
- `broker-1.vc-tls-1.keg.example.com:9092`
- `broker-2.vc-tls-1.keg.example.com:9092`

{:.info}
> In production, configure wildcard DNS so that the advertised bootstrap and broker hostnames resolve to the `Gateway` address.

For a full deployment walkthrough, see [Deploy {{ site.event_gateway }} with TLSRoute and SNI](/operator/get-started/event-gateway/tlsroute-sni/).


