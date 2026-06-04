---
title: Deploy {{ site.event_gateway }} with TLSRoute and SNI
description: Deploy {{ site.event_gateway }} behind a Kubernetes Gateway using TLS passthrough and SNI routing.
content_type: how_to
permalink: /operator/get-started/event-gateway/tlsroute-sni/

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
  skip_product: true

tldr:
  q: How do I deploy {{ site.event_gateway }} in a production-oriented topology?
  a: Front {{ site.event_gateway_short }} with a `Gateway` and `TLSRoute`, terminate TLS in {{ site.event_gateway_short }}, and route virtual clusters with SNI.

next_steps:
  - text: Learn more about {{ site.event_gateway }} resources
    url: /operator/konnect/event-gateway/

related_resources:
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
  - text: Gateway API
    url: /operator/dataplanes/gateway-api/
---

This deployment pattern uses a single TLS listener at the Kubernetes edge and routes Kafka traffic by SNI inside {{ site.event_gateway }}.

Use this pattern when you want:

- one public Kafka listener
- TLS passthrough at the Kubernetes `Gateway`
- broker metadata advertised as DNS names on a single port

## Create a `GatewayConfiguration` and `GatewayClass`

Create a managed `Gateway` class for the TLSRoute example. This `Gateway` is provisioned through {{ site.konnect_short_name }}, so the `GatewayConfiguration` should reference the `KonnectAPIAuthConfiguration` created in the [prerequisites](/operator/get-started/event-gateway/port-mapping/#create-a-konnectapiauthconfiguration-resource).

1. Create the `GatewayConfiguration` and `GatewayClass` resources:

   ```bash
   echo '
   apiVersion: gateway-operator.konghq.com/{{ site.operator_gatewayconfiguration_api_version }}
   kind: GatewayConfiguration
   metadata:
     name: kong-configuration
     namespace: kong
   spec:
     konnect:
       authRef:
         name: konnect-api-auth
     dataPlaneOptions:
       deployment:
         podTemplateSpec:
           spec:
             containers:
               - name: proxy
                 image: kong/kong-gateway:{{ site.data.gateway_latest.release }}
   ---
   apiVersion: gateway.networking.k8s.io/v1
   kind: GatewayClass
   metadata:
     name: kong
   spec:
     controllerName: konghq.com/gateway-operator
     parametersRef:
       group: gateway-operator.konghq.com
       kind: GatewayConfiguration
       name: kong-configuration
       namespace: kong
   ' | kubectl apply -f -
   ```

1. Wait for the `GatewayClass` to be accepted:

   ```bash
   kubectl wait gatewayclass/kong \
     --for=condition=Accepted=True \
     --timeout=5m
   ```

## Create a second `KonnectEventGateway`

This guide uses a separate control plane so that it can run alongside the `portMapping` example.

1. Create the `KonnectEventGateway` resource:

   ```bash
   echo '
   apiVersion: konnect.konghq.com/v1alpha1
   kind: KonnectEventGateway
   metadata:
     name: cp-event-tls
     namespace: kong
   spec:
     apiSpec:
       name: cp-event-tls
       description: Event Gateway control plane for TLSRoute and SNI
     konnect:
       authRef:
         name: konnect-api-auth
   ' | kubectl apply -f -
   ```

1. Wait for the resource to be ready:

   ```bash
   kubectl wait konnecteventgateway/cp-event-tls -n kong \
     --for=condition=Programmed=True \
     --timeout=10m
   ```

## Create the backend cluster, virtual cluster, and listener

1. Create the `EventGatewayBackendCluster`, `EventGatewayVirtualCluster`, and `EventGatewayListener` that define how Kafka traffic connects through the `cp-event-tls` control plane:

   ```bash
   echo '
   apiVersion: configuration.konghq.com/v1alpha1
   kind: EventGatewayBackendCluster
   metadata:
     name: default-backend-cluster-tls
     namespace: kong
   spec:
     gatewayRef:
       type: namespacedRef
       namespacedRef:
         name: cp-event-tls
     apiSpec:
       name: default_backend_cluster_tls
       bootstrapServers:
         - kafka-cluster.kafka.svc.cluster.local:9092
       authentication:
         type: anonymous
         anonymous: {}
       insecureAllowAnonymousVirtualClusterAuth: Enabled
       tls:
         enabled: Disabled
   ---
   apiVersion: configuration.konghq.com/v1alpha1
   kind: EventGatewayVirtualCluster
   metadata:
     name: example-virtual-cluster-tls
     namespace: kong
   spec:
     eventGatewayBackendClusterRef:
       type: namespacedRef
       namespacedRef:
         name: default-backend-cluster-tls
     apiSpec:
       name: example_virtual_cluster_tls
       dnsLabel: vc-tls-1
       aclMode: passthrough
       authentication:
         - type: anonymous
       namespace:
         prefix: "vctls_"
         mode: hide_prefix
   ---
   apiVersion: configuration.konghq.com/v1alpha1
   kind: EventGatewayListener
   metadata:
     name: sni-listener
     namespace: kong
   spec:
     apiSpec:
       name: sni_listener
       addresses:
         - 0.0.0.0
       ports:
         - "9092"
     gatewayRef:
       type: namespacedRef
       namespacedRef:
         name: cp-event-tls
   ' | kubectl apply -f -
   ```

1. Wait for the resources to be ready:

   ```bash
   kubectl wait eventgatewaybackendcluster/default-backend-cluster-tls -n kong \
     --for=condition=Programmed=True \
     --timeout=10m

   kubectl wait eventgatewayvirtualcluster/example-virtual-cluster-tls -n kong \
     --for=condition=Programmed=True \
     --timeout=10m

   kubectl wait eventgatewaylistener/sni-listener -n kong \
     --for=condition=Programmed=True \
     --timeout=10m
   ```

## Create the TLS Secret and listener policies

1. Generate a self-signed TLS certificate for `*.keg.test.local`. This wildcard covers all broker and bootstrap hostnames across every virtual cluster on this listener:

   ```bash
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
     -keyout tls.key -out tls.crt \
     -subj "/CN=keg.test.local" \
     -addext "subjectAltName=DNS:*.keg.test.local"
   ```

1. Export the certificate and key as base64-encoded environment variables:

   ```bash
   export TLS_CRT=$(cat tls.crt | base64)
   export TLS_KEY=$(cat tls.key | base64)
   ```

1. Create the TLS Secret:

   ```bash
   echo '
   apiVersion: v1
   kind: Secret
   metadata:
     name: sni-listener-tls
     namespace: kong
     labels:
       konghq.com/secret: "true"
   type: kubernetes.io/tls
   data:
     tls.crt: '"$TLS_CRT"'
     tls.key: '"$TLS_KEY"'
   ' | kubectl apply -f -
   ```

1. Apply the listener policies:

   ```bash
   echo '
   apiVersion: configuration.konghq.com/v1alpha1
   kind: EventGatewayListenerPolicy
   metadata:
     name: sni-tls-server
     namespace: kong
   spec:
     apiSpec:
       type: tlsServer
       tlsServer:
         name: tls_server
         enabled: Enabled
         config:
           allowPlaintext: Disabled
           versions:
             min: TLSv1.2
             max: TLSv1.3
           certificates:
             - certificate:
                 type: secretRef
                 secretRef:
                   name: sni-listener-tls
               key:
                 type: secretRef
                 secretRef:
                   name: sni-listener-tls
     eventGatewayListenerRef:
       type: namespacedRef
       namespacedRef:
         name: sni-listener
   ---
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
             sniSuffix: ".keg.test.local"
             brokerHostFormat:
               type: per_cluster_suffix
             advertisedPort: 9092
     eventGatewayListenerRef:
       type: namespacedRef
       namespacedRef:
         name: sni-listener
   ' | kubectl apply -f -
   ```

1. Wait for the listener policies to be ready:

   ```bash
   kubectl wait eventgatewaylistenerpolicy/sni-tls-server -n kong \
     --for=condition=Programmed=True \
     --timeout=10m

   kubectl wait eventgatewaylistenerpolicy/sni-forward -n kong \
     --for=condition=Programmed=True \
     --timeout=10m
   ```

## Create consume and produce policies

These policies add a marker header to consumed and produced records so you can verify they are attached.

1. Create the consume and produce policies:

   ```bash
   echo '
   apiVersion: configuration.konghq.com/v1alpha1
   kind: EventGatewayVirtualClusterConsumePolicy
   metadata:
     name: example-virtual-cluster-tls-consume-policy
     namespace: kong
   spec:
     eventGatewayVirtualClusterRef:
       type: namespacedRef
       namespacedRef:
         name: example-virtual-cluster-tls
     apiSpec:
       type: modifyHeaders
       modifyHeaders:
         name: example_tls_consume_policy
         description: Add a marker header to consumed records for the TLSRoute example
         config:
           actions:
             - op: set
               set:
                 key: x-kong-consume-policy
                 value: tlsroute
   ---
   apiVersion: configuration.konghq.com/v1alpha1
   kind: EventGatewayVirtualClusterProducePolicy
   metadata:
     name: example-virtual-cluster-tls-produce-policy
     namespace: kong
   spec:
     eventGatewayVirtualClusterRef:
       type: namespacedRef
       namespacedRef:
         name: example-virtual-cluster-tls
     apiSpec:
       type: modifyHeaders
       modifyHeaders:
         name: example_tls_produce_policy
         description: Add a marker header to produced records for the TLSRoute example
         config:
           actions:
             - op: set
               set:
                 key: x-kong-produce-policy
                 value: tlsroute
   ' | kubectl apply -f -
   ```

1. Wait for the resources to be ready:

   ```bash
   kubectl wait eventgatewayvirtualclusterconsumepolicy/example-virtual-cluster-tls-consume-policy -n kong \
     --for=condition=Programmed=True \
     --timeout=10m

   kubectl wait eventgatewayvirtualclusterproducepolicy/example-virtual-cluster-tls-produce-policy -n kong \
     --for=condition=Programmed=True \
     --timeout=10m
   ```

## Deploy the `KegDataPlane`

For the TLSRoute pattern, the `KegDataPlane` stays internal to the cluster. The Kafka listener is exposed as a `ClusterIP` Service because the Kubernetes `Gateway` will be the public entrypoint.

Deploy the `KegDataPlane`:

```bash
echo '
apiVersion: eventgateway.konghq.com/v1alpha1
kind: KegDataPlane
metadata:
  name: keg-tls-dp
  namespace: kong
spec:
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: cp-event-tls
  network:
    services:
      kafka:
        type: ClusterIP
        ports:
          - name: kafka
            port: 9092
            targetPort: 9092
' | kubectl apply -f -
```

## Create the Kubernetes `Gateway`

Create a `Gateway` that listens for TLS traffic on port `19092`. It uses TLS passthrough so that {{ site.event_gateway }} still terminates TLS with the certificate you configured earlier.

1. Create the `Gateway`:

   ```bash
   echo '
   apiVersion: gateway.networking.k8s.io/v1
   kind: Gateway
   metadata:
     name: kong-keg
     namespace: kong
   spec:
     gatewayClassName: kong
     listeners:
       - name: kafka-tls
         protocol: TLS
         port: 19092
         hostname: "*.keg.test.local"
         tls:
           mode: Passthrough
           certificateRefs: []
         allowedRoutes:
           namespaces:
             from: Same
           kinds:
             - group: gateway.networking.k8s.io
               kind: TLSRoute
   ' | kubectl apply -f -
   ```

1. Wait for the `Gateway` to be accepted:

   ```bash
   kubectl wait gateway/kong-keg -n kong --for=condition=Accepted=True --timeout=5m
   ```

## Attach a `TLSRoute` to the `Gateway`

The `TLSRoute` binds the wildcard Kafka hostnames to the internal Kafka Service exposed by the `KegDataPlane`.

Create the `TLSRoute`:

```bash
echo '
apiVersion: gateway.networking.k8s.io/v1
kind: TLSRoute
metadata:
  name: keg-tls
  namespace: kong
spec:
  parentRefs:
    - group: gateway.networking.k8s.io
      kind: Gateway
      name: kong-keg
      namespace: kong
      sectionName: kafka-tls
  hostnames:
    - "*.vc-tls-1.keg.test.local"
  rules:
    - backendRefs:
        - group: ""
          kind: Service
          name: keg-tls-dp-kafka
          port: 9092
' | kubectl apply -f -
```

## Validation

1. Export the `Gateway` address:

   ```bash
   export GATEWAY_IP=$(kubectl get gateway kong-keg -n kong -o jsonpath='{.status.addresses[0].value}')
   echo $GATEWAY_IP
   ```

1. Check the TLSRoute conditions:

   ```bash
   kubectl get tlsroute keg-tls -n kong \
     -o jsonpath='{range .status.parents[0].conditions[*]}{.type}={.status}{" "}{end}{"\n"}'
   ```

## Smoke test with Kafka metadata

For local testing, create host aliases for the advertised broker hostnames and request metadata with `kcat`:

```bash
kubectl run kcat-tlsroute --rm -i --restart=Never --image=edenhill/kcat:1.7.1 -n kong \
  --overrides='{"spec":{"hostAliases":[{"ip":"'"${GATEWAY_IP}"'","hostnames":["bootstrap.vc-tls-1.keg.test.local","broker-0.vc-tls-1.keg.test.local","broker-1.vc-tls-1.keg.test.local","broker-2.vc-tls-1.keg.test.local"]}]}}' \
  --command -- kcat -b bootstrap.vc-tls-1.keg.test.local:19092 \
  -X security.protocol=SSL \
  -X enable.ssl.certificate.verification=false \
  -L
```

You should see all brokers advertised on port `19092` with DNS names based on the virtual cluster `dnsLabel`.
