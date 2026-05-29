---
title: Deploy Kong Event Gateway with port mapping
description: Deploy Kong Event Gateway with a `LoadBalancer` Service and port-based broker mapping.
content_type: how_to
permalink: /operator/get-started/event-gateway/port-mapping/

series:
  id: operator-get-started-event-gateway
  position: 3

breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: Get Started

products:
  - operator

works_on:
  - konnect

prereqs:
  show_works_on: true
  skip_product: true
  operator:
    konnect:
      auth: true

tldr:
  q: How do I deploy Kong Event Gateway with {{site.operator_product_name}}?
  a: Create a `KonnectEventGateway`, backend cluster, virtual cluster, listener, `KegDataPlane`, listener policy, and consume and produce policies.
---

This deployment pattern is the simplest way to validate Kong Event Gateway locally.

It exposes a `LoadBalancer` Service and uses `portMapping` so that Kafka clients connect through one bootstrap port and one port per broker.

## Create the `KonnectEventGateway`

```bash
echo '
apiVersion: konnect.konghq.com/v1alpha1
kind: KonnectEventGateway
metadata:
  name: cp-event-1
  namespace: kong
spec:
  apiSpec:
    name: cp-event-1
    description: Event Gateway control plane managed by Kubernetes
  konnect:
    authRef:
      name: konnect-api-auth
' | kubectl apply -f -
```

## Create the backend cluster

```bash
echo '
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
' | kubectl apply -f -
```

## Create the virtual cluster and listener

```bash
echo '
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
---
apiVersion: configuration.konghq.com/v1alpha1
kind: EventGatewayListener
metadata:
  name: example-listener
  namespace: kong
spec:
  apiSpec:
    name: example_listener
    addresses:
      - 0.0.0.0
    ports:
      - "9092-9095"
  gatewayRef:
    type: namespacedRef
    namespacedRef:
      name: cp-event-1
' | kubectl apply -f -
```

## Deploy the `KegDataPlane`

```bash
echo '
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
  network:
    services:
      kafka:
        type: LoadBalancer
        ports:
          - name: kafka
            port: 9092
            targetPort: 9092
          - name: broker-1
            port: 9093
            targetPort: 9093
          - name: broker-2
            port: 9094
            targetPort: 9094
          - name: broker-3
            port: 9095
            targetPort: 9095
' | kubectl apply -f -
```

Wait for the data plane to be ready:

```bash
kubectl wait kegdataplane/my-event-gateway-dp -n kong \
  --for=condition=Ready=True \
  --timeout=10m
```

## Export the `LoadBalancer` address

The listener policy needs an explicit `advertisedHost`. Export the `LoadBalancer` IP from the Kafka Service:

```bash
export KAFKA_LB_HOST=$(kubectl get service my-event-gateway-dp-kafka -n kong \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $KAFKA_LB_HOST
```

## Create the listener policy

```bash
echo '
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
          advertisedHost: '"$KAFKA_LB_HOST"'
          bootstrapPort: at_start
          destination:
            name: example_virtual_cluster
  eventGatewayListenerRef:
    type: namespacedRef
    namespacedRef:
      name: example-listener
' | kubectl apply -f -
```

## Create consume and produce policies

```bash
echo '
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
      description: Add a marker header to consumed records
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
      description: Add a marker header to produced records
      config:
        actions:
          - op: set
            set:
              key: x-kong-produce-policy
              value: example
' | kubectl apply -f -
```

## Validation

Wait for the Konnect-backed resources to become programmed:

```bash
kubectl wait -n kong \
  konnecteventgateway/cp-event-1 \
  eventgatewaybackendcluster/default-backend-cluster \
  eventgatewayvirtualcluster/example-virtual-cluster \
  eventgatewaylistener/example-listener \
  eventgatewaylistenerpolicy/example-listener-policy \
  eventgatewayvirtualclusterconsumepolicy/example-virtual-cluster-consume-policy \
  eventgatewayvirtualclusterproducepolicy/example-virtual-cluster-produce-policy \
  --for=jsonpath='{.status.conditions[?(@.type=="Programmed")].status}'=True \
  --timeout=10m
```

Check the resource status:

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

## Smoke test with Kafka metadata

Run `kcat` in the cluster and request broker metadata:

```bash
kubectl run kcat-portmap --rm -i --restart=Never --image=edenhill/kcat:1.7.1 -n kong \
  --command -- kcat -b ${KAFKA_LB_HOST}:9092 -L
```

You should see one bootstrap endpoint on port `9092` and one port per broker on `9093`, `9094`, and `9095`.

Continue to [Deploy Kong Event Gateway with TLSRoute and SNI](/operator/get-started/event-gateway/tlsroute-sni/) for the production-oriented pattern.
