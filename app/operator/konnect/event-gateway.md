---
title: "Kong Event Gateway"
description: "Deploy and validate Kong Event Gateway resources with {{ site.operator_product_name }}"
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
  operator: '2.1'

---

{{ site.operator_product_name }} can reconcile Kong Event Gateway resources to {{ site.konnect_short_name }} and deploy a matching `KegDataPlane` in your Kubernetes cluster.

If you want a step-by-step setup that you can apply directly to a cluster, start with the [Kong Event Gateway getting started guide](/operator/get-started/event-gateway/install/).

At a high level, the operator manages three layers:

- A `KonnectEventGateway` control plane in `konnect.konghq.com/v1alpha1`
- Event Gateway configuration resources in `configuration.konghq.com/v1alpha1`
- A `KegDataPlane` workload in `eventgateway.konghq.com/v1alpha1`

This page describes the resource model and two deployment patterns:

- `LoadBalancer` plus `portMapping` for local validation and simple environments
- `Gateway` plus `TLSRoute` plus SNI routing for production-oriented deployments

## Resource model

These resources form a typical Event Gateway deployment:

| Resource | API group | Purpose |
|---|---|---|
| `KonnectEventGateway` | `konnect.konghq.com/v1alpha1` | Creates the Event Gateway control plane in {{ site.konnect_short_name }} |
| `EventGatewayBackendCluster` | `configuration.konghq.com/v1alpha1` | Describes the upstream Kafka cluster |
| `EventGatewayVirtualCluster` | `configuration.konghq.com/v1alpha1` | Defines the virtual cluster presented to clients |
| `EventGatewayListener` | `configuration.konghq.com/v1alpha1` | Declares listener addresses and ports |
| `EventGatewayListenerPolicy` | `configuration.konghq.com/v1alpha1` | Configures routing and TLS behavior on the listener |
| `EventGatewayVirtualClusterConsumePolicy` | `configuration.konghq.com/v1alpha1` | Applies consume-side policy to a virtual cluster |
| `EventGatewayVirtualClusterProducePolicy` | `configuration.konghq.com/v1alpha1` | Applies produce-side policy to a virtual cluster |
| `KegDataPlane` | `eventgateway.konghq.com/v1alpha1` | Deploys the Event Gateway data plane in Kubernetes |

The references flow in this order:

1. `EventGatewayBackendCluster.spec.gatewayRef` points to a `KonnectEventGateway`
2. `EventGatewayVirtualCluster.spec.eventGatewayBackendClusterRef` points to an `EventGatewayBackendCluster`
3. `EventGatewayListener.spec.gatewayRef` points to the same `KonnectEventGateway`
4. `EventGatewayListenerPolicy.spec.eventGatewayListenerRef` points to an `EventGatewayListener`
5. Consume and produce policies point to an `EventGatewayVirtualCluster`
6. `KegDataPlane.spec.controlPlaneRef` points to the `KonnectEventGateway`

## Deployment patterns

There are two practical ways to expose Kong Event Gateway with the operator.

### Pattern 1: `LoadBalancer` plus `portMapping`

This pattern is a good fit for local validation, lab environments, and simple deployments where exposing one port per broker is acceptable.

The listener policy uses `forwardToVirtualCluster.config.type: portMapping` and the `KegDataPlane` exposes a `LoadBalancer` Service with one port for bootstrap traffic and one port for each broker.

For example:

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
> Set `advertisedHost` explicitly. The current CRD requires it, and Kafka clients use it when resolving broker metadata after bootstrap.

In a three-broker Kafka cluster, the data plane Service typically exposes:

- `9092` for bootstrap
- `9093` for broker 0
- `9094` for broker 1
- `9095` for broker 2

This pattern was validated with `kcat -L` against a `LoadBalancer` Service, and the returned metadata advertised the bootstrap endpoint on port `9092` and the brokers on ports `9093` through `9095`.

### Pattern 2: `Gateway` plus `TLSRoute` plus SNI

This is the production-oriented pattern.

In this model:

- A Kubernetes `Gateway` exposes a single TLS listener
- A `TLSRoute` forwards encrypted traffic to the `KegDataPlane` Service
- An `EventGatewayListenerPolicy` with `type: tlsServer` terminates TLS in Kong Event Gateway
- A second `EventGatewayListenerPolicy` with `forwardToVirtualCluster.config.type: sni` routes clients to the correct virtual cluster based on SNI

This keeps the public edge to a single port and returns broker metadata as stable DNS names instead of distinct ports.

For example:

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

With a virtual cluster `dnsLabel` of `vc-tls-1`, clients receive metadata similar to:

- `bootstrap.vc-tls-1.keg.example.com:9092`
- `broker-0.vc-tls-1.keg.example.com:9092`
- `broker-1.vc-tls-1.keg.example.com:9092`
- `broker-2.vc-tls-1.keg.example.com:9092`

This pattern was validated with `kcat -L` through a `Gateway` and `TLSRoute`, with all brokers advertised on the same TLS port and differentiated only by DNS name.

{:.info}
> In production, configure wildcard DNS so that the advertised bootstrap and broker hostnames resolve to the `Gateway` address.

## Minimal resource flow

The following manifests show the minimal shape of a single virtual cluster deployment.

Create the Event Gateway control plane:

```yaml
apiVersion: konnect.konghq.com/v1alpha1
kind: KonnectEventGateway
metadata:
  name: cp-event-1
  namespace: kong
spec:
  apiSpec:
    name: cp-event-1
  konnect:
    authRef:
      name: konnect-api-auth
```

Create the backend cluster:

```yaml
apiVersion: configuration.konghq.com/v1alpha1
kind: EventGatewayBackendCluster
metadata:
  name: default-backend-cluster
  namespace: kong
spec:
  gatewayRef:
    type: namespacedRef
    namespacedRef:
      name: cp-event-1
  apiSpec:
    name: default_backend_cluster
    bootstrapServers:
      - kafka-cluster.kafka.svc.cluster.local:9092
    authentication:
      type: anonymous
      anonymous: {}
    insecureAllowAnonymousVirtualClusterAuth: Enabled
    tls:
      enabled: Disabled
```

Create the virtual cluster:

```yaml
apiVersion: configuration.konghq.com/v1alpha1
kind: EventGatewayVirtualCluster
metadata:
  name: example-virtual-cluster
  namespace: kong
spec:
  eventGatewayBackendClusterRef:
    type: namespacedRef
    namespacedRef:
      name: default-backend-cluster
  apiSpec:
    name: example_virtual_cluster
    dnsLabel: vcluster-1
    aclMode: passthrough
    authentication:
      - type: anonymous
    namespace:
      prefix: "vc1_"
      mode: hide_prefix
```

Attach consume and produce policies:

```yaml
apiVersion: configuration.konghq.com/v1alpha1
kind: EventGatewayVirtualClusterConsumePolicy
metadata:
  name: example-virtual-cluster-consume-policy
  namespace: kong
spec:
  eventGatewayVirtualClusterRef:
    type: namespacedRef
    namespacedRef:
      name: example-virtual-cluster
  apiSpec:
    type: modifyHeaders
    modifyHeaders:
      name: example_consume_policy
      config:
        actions:
          - op: set
            set:
              key: x-kong-consume-policy
              value: example
---
apiVersion: configuration.konghq.com/v1alpha1
kind: EventGatewayVirtualClusterProducePolicy
metadata:
  name: example-virtual-cluster-produce-policy
  namespace: kong
spec:
  eventGatewayVirtualClusterRef:
    type: namespacedRef
    namespacedRef:
      name: example-virtual-cluster
  apiSpec:
    type: modifyHeaders
    modifyHeaders:
      name: example_produce_policy
      config:
        actions:
          - op: set
            set:
              key: x-kong-produce-policy
              value: example
```

Deploy the data plane:

```yaml
apiVersion: eventgateway.konghq.com/v1alpha1
kind: KegDataPlane
metadata:
  name: my-event-gateway-dp
  namespace: kong
spec:
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: cp-event-1
```

## Validation

Once the manifests are applied, verify that the operator has programmed every resource:

```bash
kubectl get -n kong \
  konnecteventgateway \
  eventgatewaybackendcluster \
  eventgatewayvirtualcluster \
  eventgatewaylistener \
  eventgatewaylistenerpolicy \
  eventgatewayvirtualclusterconsumepolicy \
  eventgatewayvirtualclusterproducepolicy \
  kegdataplane
```

All Konnect-backed resources should report `PROGRAMMED=True`, and `KegDataPlane` should report `READY=True`.

For the `TLSRoute` pattern, also verify the Gateway API resources:

```bash
kubectl get gateway,tlsroute -n kong
```

## Smoke testing with kcat

For the `LoadBalancer` plus `portMapping` pattern:

```bash
kubectl run kcat-portmap --rm -i --restart=Never --image=edenhill/kcat:1.7.1 -n kong \
  --command -- kcat -b ${LB_IP}:9092 -L
```

Expect the bootstrap listener on `:9092` and each broker on its own port.

For the `Gateway` plus `TLSRoute` plus SNI pattern:

```bash
kubectl run kcat-tlsroute --rm -i --restart=Never --image=edenhill/kcat:1.7.1 -n kong \
  --overrides='{"spec":{"hostAliases":[{"ip":"'"${GATEWAY_IP}"'","hostnames":["bootstrap.vc-tls-1.keg.example.com","broker-0.vc-tls-1.keg.example.com","broker-1.vc-tls-1.keg.example.com","broker-2.vc-tls-1.keg.example.com"]}]}}' \
  --command -- kcat -b bootstrap.vc-tls-1.keg.example.com:9092 \
  -X security.protocol=SSL \
  -X enable.ssl.certificate.verification=false \
  -L
```

Expect all brokers to be advertised on port `9092`, each with a unique DNS hostname.

## Choosing a pattern

Use `LoadBalancer` plus `portMapping` when:

- you need a fast local validation loop
- you can expose one port per broker
- a stable external IP is acceptable for clients

Use `Gateway` plus `TLSRoute` plus SNI when:

- you want a production-oriented edge pattern
- you need a single public Kafka listener
- you want broker metadata returned as DNS names on one port
- you plan to front multiple virtual clusters behind one entrypoint

## Related resources

- [Gateway API](/operator/dataplanes/gateway-api/)
- [Managed Gateways](/operator/dataplanes/managed-gateways/)
- [Cross namespace references](/operator/konnect/cross-namespace-references/)
