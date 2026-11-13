---
title: Deploy {{ site.event_gateway }} with port mapping
description: Deploy {{ site.event_gateway }} with a `LoadBalancer` Service and port-based broker mapping.
content_type: how_to
permalink: /operator/get-started/event-gateway/port-mapping/

series:
  id: operator-get-started-event-gateway
  position: 2

breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: Get Started

products:
  - operator
  
min_version:
  operator: '2.2'

works_on:
  - konnect
  - on-prem

prereqs:
  show_works_on: true
  skip_product: true
  operator:
    konnect:
      auth: true

tldr:
  q: How do I deploy Kong Event Gateway with {{site.operator_product_name}}?
  a: |
    With {{site.konnect_short_name}}, create a `KonnectEventGateway`, backend cluster, virtual cluster, listener, `KegDataPlane`, listener policy, and consume and produce policies.
    For on-prem (Tech Preview), create an `OnPremEventGateway` served by your `GWAdmin` instead, attach the backend cluster and listener to it with `spec.parentRef`, and set `spec.controlPlaneRef.type: onpremNamespacedRef` on the `KegDataPlane`.

next_steps:
  - text: Learn more about {{ site.event_gateway }}
    url: /event-gateway/

related_resources:
  - text: "{{ site.event_gateway }} with {{ site.operator_product_name }}"
    url: /operator/event-gateway/
  - text: Backend clusters
    url: /event-gateway/entities/backend-cluster/
  - text: Virtual clusters
    url: /event-gateway/entities/virtual-cluster/
  - text: Listeners
    url: /event-gateway/entities/listener/
  - text: Policies
    url: /event-gateway/entities/policy/
  - text: Configure SNI routing with {{ site.event_gateway }}
    url: /event-gateway/configure-sni-routing/
---

This deployment pattern is the simplest way to validate {{ site.event_gateway }}.

It exposes a `LoadBalancer` Service and uses `portMapping` so that Kafka clients connect through one bootstrap port and one port per broker. For production environments, we recommend using {{ site.base_gateway }} with {{ site.operator_product_name }} to set up a TLSRoute and an SNI wildcard.

{% on_prem %}
content: |
  {% include operator/event-gateway-on-prem-tech-preview.md %}
{% endon_prem %}

{% konnect %}
title: Create the `KonnectEventGateway`
step: true
content: |
  The `KonnectEventGateway` resource creates the Event Gateway control plane in {{site.konnect_short_name}} and gives the rest of the resources in this guide a parent to attach to.

  1. Create the `KonnectEventGateway` resource:

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

  1. Wait for the resource to be ready:

     ```bash
     kubectl wait konnecteventgateway/cp-event-1 -n kong \
       --for=condition=Programmed=True \
       --timeout=10m
     ```
{% endkonnect %}

{% on_prem %}
title: Create the `OnPremEventGateway`
step: true
content: |
  The `OnPremEventGateway` resource is the on-prem {{ site.event_gateway_short }} control plane, and gives the rest of the resources in this guide a parent to attach to. It doesn't create any Pods. {{site.operator_product_name}} collects the resources attached to it and pushes their configuration to the gw-admin Pods of the `GWAdmin` you created in the [install guide](/operator/get-started/event-gateway/install/).

  1. Create the `OnPremEventGateway` resource:

     ```bash
     echo '
     apiVersion: eventgateway.konghq.com/v1alpha1
     kind: OnPremEventGateway
     metadata:
       name: cp-event-1
       namespace: kong
     spec:
       gwAdminRef:
         name: gw-admin
     ' | kubectl apply -f -
     ```

  1. Wait for the resource to be ready:

     ```bash
     kubectl wait onpremeventgateway/cp-event-1 -n kong \
       --for=condition=Programmed=True \
       --timeout=5m
     ```

     If the `OnPremEventGateway` doesn't become `Programmed`, check its `GWAdminResolved` condition. It reports `NotFound` when the `GWAdmin` doesn't exist, and `NotReady` while gw-admin has no running Pod.
{% endon_prem %}

## Create the backend cluster

The `EventGatewayBackendCluster` resource tells {{ site.event_gateway }} which upstream Kafka cluster to connect to. In this example, it points at the Bitnami Kafka bootstrap Service in the `kafka` namespace. For more information, see the [backend cluster docs](/event-gateway/entities/backend-cluster/).

1. Create the `EventGatewayBackendCluster` resource:

   {% konnect %}
   content: |
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
   indent: 3
   {% endkonnect %}

   {% on_prem %}
   content: |
     Set `spec.parentRef` to the `OnPremEventGateway`, with its `group` and `kind`:

     ```bash
     echo '
     apiVersion: configuration.konghq.com/v1alpha1
     kind: EventGatewayBackendCluster
     metadata:
       name: default-backend-cluster
       namespace: kong
     spec:
       parentRef:
         group: eventgateway.konghq.com
         kind: OnPremEventGateway
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
   indent: 3
   {% endon_prem %}

1. Wait for the resource to be ready:

   ```bash
   kubectl wait eventgatewaybackendcluster/default-backend-cluster -n kong \
     --for=condition=Programmed=True \
     --timeout=10m
   ```

## Create the virtual cluster and listener

The `EventGatewayVirtualCluster` resource is the Kafka-facing cluster your clients connect to, while the `EventGatewayListener` resource opens the network ports that accept those client connections. For more information, see the [virtual cluster docs](/event-gateway/entities/virtual-cluster/) and [listener docs](/event-gateway/entities/listener/).

1. Create the `EventGatewayVirtualCluster` and `EventGatewayListener` resources:

   {% konnect %}
   content: |
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
   indent: 3
   {% endkonnect %}

   {% on_prem %}
   content: |
     The virtual cluster attaches to its backend cluster, so only the listener references the `OnPremEventGateway`:

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
       parentRef:
         group: eventgateway.konghq.com
         kind: OnPremEventGateway
         name: cp-event-1
     ' | kubectl apply -f -
     ```
   indent: 3
   {% endon_prem %}

1. Wait for the resources to be ready:

   ```bash
   kubectl wait eventgatewayvirtualcluster/example-virtual-cluster -n kong \
     --for=condition=Programmed=True \
     --timeout=10m

   kubectl wait eventgatewaylistener/example-listener -n kong \
     --for=condition=Programmed=True \
     --timeout=10m
   ```

## Deploy the `KegDataPlane`

The `KegDataPlane` resource runs {{ site.event_gateway }} inside Kubernetes. In the port-mapping pattern, it exposes a `LoadBalancer` Service with one bootstrap port and one port per broker.

{% konnect %}
content: |
  Deploy the `KegDataPlane`:

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
{% endkonnect %}

{% on_prem %}
content: |
  1. Deploy the `KegDataPlane`. Set `spec.controlPlaneRef.type` to `onpremNamespacedRef` to attach it to the `OnPremEventGateway`:

     ```bash
     echo '
     apiVersion: eventgateway.konghq.com/v1alpha1
     kind: KegDataPlane
     metadata:
       name: my-event-gateway-dp
       namespace: kong
     spec:
       controlPlaneRef:
         type: onpremNamespacedRef
         onpremNamespacedRef:
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

     {{site.operator_product_name}} issues the data plane a client certificate and registers it on gw-admin. The data plane uses it to pull its configuration from gw-admin.

  1. Wait for the data plane to be ready:

     ```bash
     kubectl wait kegdataplane/my-event-gateway-dp -n kong \
       --for=condition=Ready=True \
       --timeout=5m
     ```
{% endon_prem %}

## Export the `LoadBalancer` address

The listener policy needs an explicit `advertisedHost`. Export the `LoadBalancer` IP from the Kafka Service:

```bash
export KAFKA_LB_HOST=$(kubectl get service my-event-gateway-dp-kafka -n kong \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $KAFKA_LB_HOST
```

## Create the listener policy

The `EventGatewayListenerPolicy` connects the listener to the virtual cluster. In this mode, `portMapping` maps one external bootstrap port and one external port per broker. For more information, see the [{{ site.event_gateway_short }} policy docs](/event-gateway/entities/policy/).

1. Create the `EventGatewayListenerPolicy` resource. Set `destination.name` to the name of the `EventGatewayVirtualCluster` resource, `example-virtual-cluster`, not to its `apiSpec.name`:

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
               name: example-virtual-cluster
     eventGatewayListenerRef:
       type: namespacedRef
       namespacedRef:
         name: example-listener
   ' | kubectl apply -f -
   ```

1. Wait for the resource to be ready:

   ```bash
   kubectl wait eventgatewaylistenerpolicy/example-listener-policy -n kong \
     --for=condition=Programmed=True \
     --timeout=10m
   ```

## Create consume and produce policies

These optional virtual-cluster policies let you shape consume and produce traffic independently. This example adds a header on each path so you can verify the policies are attached. For more information, see the [{{ site.event_gateway_short }} policy docs](/event-gateway/policies/).

1. Create the `EventGatewayVirtualClusterConsumePolicy` and `EventGatewayVirtualClusterProducePolicy` resources:

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

1. Wait for the resources to be ready:

   ```bash
   kubectl wait eventgatewayvirtualclusterconsumepolicy/example-virtual-cluster-consume-policy -n kong \
     --for=condition=Programmed=True \
     --timeout=10m

   kubectl wait eventgatewayvirtualclusterproducepolicy/example-virtual-cluster-produce-policy -n kong \
     --for=condition=Programmed=True \
     --timeout=10m
   ```

## Smoke test with Kafka metadata

Run `kcat` in the cluster and request broker metadata:

```bash
kubectl run kcat-portmap --rm -i --restart=Never --image=edenhill/kcat:1.7.1 -n kong \
  --command -- kcat -b ${KAFKA_LB_HOST}:9092 -L
```

You should see one bootstrap endpoint on port `9092` and one port per broker on `9093`, `9094`, and `9095`, for example:

```text
Metadata for all topics (from broker -1: 127.0.0.0:9092/bootstrap):
 3 brokers:
  broker 0 at 127.0.0.0:9093
  broker 1 at 127.0.0.0:9094
  broker 2 at 127.0.0.0:9095 (controller)
 0 topics:
pod "kcat-portmap" deleted from kong namespace
```
{:.no-copy-code}

## Produce and consume a record

Create a topic, produce a record, and consume it back through {{ site.event_gateway }} with `kafkactl`:

```bash
kubectl run kafkactl-roundtrip --rm -i --restart=Never \
  --image=deviceinsight/kafkactl:v5.21.0 -n kong \
  --env=BROKERS=${KAFKA_LB_HOST}:9092 \
  --command -- sh -c '
    kafkactl create topic orders --partitions 1 --replication-factor 3 &&
    kafkactl produce orders --value hello &&
    sleep 3 &&
    kafkactl consume orders --from-beginning --exit --print-headers'
```

The `sleep` gives the new topic's metadata time to propagate before the consumer reads it. The consumed record carries the headers that both policies added:

```text
x-kong-consume-policy:example,x-kong-produce-policy:example#hello
```
{:.no-copy-code}

The virtual cluster hides its `vc1_` prefix from clients: in the backend Kafka cluster, the topic is named `vc1_orders`.
