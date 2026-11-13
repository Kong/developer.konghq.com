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
  
min_version:
  operator: '2.2'

works_on:
  - konnect
  - on-prem

prereqs:
  show_works_on: true
  skip_product: true
  inline:
    - title: "On-prem: {{ site.ee_product_name }} license"
      topology: on-prem
      content: |
        With an on-prem control plane, the {{ site.base_gateway }} data plane behind the `Gateway` needs a {{ site.ee_product_name }} license to accept configuration. Without one, it runs in read-only mode and the `Gateway` never becomes `Programmed`.

        Save your license as `license.json` in your working directory. This is a different license from the {{ site.event_gateway_short }} license that gw-admin uses.
      icon_url: /assets/icons/gateway.svg

cleanup:
  inline:
    - title: Delete the resources created in this guide
      topology: konnect
      content: |
        Delete the {{ site.event_gateway }} resources, the `Gateway` resources, and the {{ site.konnect_short_name }} authentication configuration:

        ```bash
        kubectl delete -n kong --ignore-not-found \
          tlsroute/keg-tls \
          service/keg-tls-dp-kafka \
          gateway/kong-keg \
          gatewayconfiguration/kong-configuration \
          eventgatewaylistenerpolicy/sni-tls-server \
          eventgatewaylistenerpolicy/sni-forward \
          eventgatewaylistenerpolicy/example-listener-policy \
          eventgatewayvirtualclusterconsumepolicy/example-virtual-cluster-tls-consume-policy \
          eventgatewayvirtualclusterconsumepolicy/example-virtual-cluster-consume-policy \
          eventgatewayvirtualclusterproducepolicy/example-virtual-cluster-tls-produce-policy \
          eventgatewayvirtualclusterproducepolicy/example-virtual-cluster-produce-policy \
          eventgatewayvirtualcluster/example-virtual-cluster-tls \
          eventgatewayvirtualcluster/example-virtual-cluster \
          eventgatewaylistener/sni-listener \
          eventgatewaylistener/example-listener \
          eventgatewaybackendcluster/default-backend-cluster-tls \
          eventgatewaybackendcluster/default-backend-cluster \
          kegdataplane/keg-tls-dp \
          kegdataplane/my-event-gateway-dp \
          secret/sni-listener-tls \
          konnecteventgateway/cp-event-tls \
          konnecteventgateway/cp-event-1 \
          konnectapiauthconfiguration/konnect-api-auth

        kubectl delete --ignore-not-found gatewayclass/kong
        ```
        {: data-test-cleanup="block" }
      icon_url: /assets/icons/kubernetes.svg

    - title: Delete the resources created in this guide
      topology: on-prem
      content: |
        Delete the {{ site.event_gateway }} resources and the `Gateway` resources. Delete the `OnPremEventGateway` resources before the `GWAdmin`, so that {{site.operator_product_name}} can remove their configuration from gw-admin:

        ```bash
        kubectl delete -n kong --ignore-not-found \
          tlsroute/keg-tls \
          gateway/kong-keg \
          gatewayconfiguration/kong-configuration \
          eventgatewaylistenerpolicy/sni-tls-server \
          eventgatewaylistenerpolicy/sni-forward \
          eventgatewaylistenerpolicy/example-listener-policy \
          eventgatewayvirtualclusterconsumepolicy/example-virtual-cluster-tls-consume-policy \
          eventgatewayvirtualclusterconsumepolicy/example-virtual-cluster-consume-policy \
          eventgatewayvirtualclusterproducepolicy/example-virtual-cluster-tls-produce-policy \
          eventgatewayvirtualclusterproducepolicy/example-virtual-cluster-produce-policy \
          eventgatewayvirtualcluster/example-virtual-cluster-tls \
          eventgatewayvirtualcluster/example-virtual-cluster \
          eventgatewaylistener/sni-listener \
          eventgatewaylistener/example-listener \
          eventgatewaybackendcluster/default-backend-cluster-tls \
          eventgatewaybackendcluster/default-backend-cluster \
          kegdataplane/keg-tls-dp \
          kegdataplane/my-event-gateway-dp \
          secret/sni-listener-tls \
          onpremeventgateway/cp-event-tls \
          onpremeventgateway/cp-event-1

        kubectl delete -n kong --ignore-not-found gwadmin/gw-admin secret/gw-admin-license
        kubectl delete --ignore-not-found gatewayclass/kong konglicense/kong-license
        ```
        {: data-test-cleanup="block" }
      icon_url: /assets/icons/kubernetes.svg

    - title: Delete the namespaces
      content: |
        ```bash
        helm uninstall kong-operator -n kong-system
        kubectl delete namespace kafka kong kong-system
        ```
      icon_url: /assets/icons/kubernetes.svg

tldr:
  q: How do I deploy {{ site.event_gateway }} in a production-oriented topology?
  a: |
    Front {{ site.event_gateway_short }} with a `Gateway` and `TLSRoute`, terminate TLS in {{ site.event_gateway_short }}, and route virtual clusters with SNI.
    For on-prem (Tech Preview), attach the {{ site.event_gateway_short }} resources to an `OnPremEventGateway`, and apply a `KongLicense` for the {{ site.base_gateway }} data plane behind the `Gateway`.

next_steps:
  - text: Learn more about {{ site.event_gateway }} resources
    url: /operator/event-gateway/

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

{% on_prem %}
content: |
  {% include operator/event-gateway-on-prem-tech-preview.md %}
{% endon_prem %}

{% konnect %}
title: Create a GatewayConfiguration and GatewayClass
step: true
content: |
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
{% endkonnect %}

{% on_prem %}
title: Create a GatewayConfiguration and GatewayClass
step: true
content: |
  Create a managed `Gateway` class for the TLSRoute example. Without `spec.konnect`, {{site.operator_product_name}} runs the control plane of the `Gateway` itself.

  1. Apply a `KongLicense` for the {{ site.base_gateway }} data plane, from the `license.json` file in your working directory:

     ```bash
     echo "
     apiVersion: configuration.konghq.com/v1alpha1
     kind: KongLicense
     metadata:
       name: kong-license
     rawLicenseString: '$(cat ./license.json)'
     " | kubectl apply -f -
     ```

  1. Create the `GatewayConfiguration` and `GatewayClass` resources:

     ```bash
     echo '
     apiVersion: gateway-operator.konghq.com/{{ site.operator_gatewayconfiguration_api_version }}
     kind: GatewayConfiguration
     metadata:
       name: kong-configuration
       namespace: kong
     spec:
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
{% endon_prem %}

{% konnect %}
title: Create a second KonnectEventGateway
step: true
content: |
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
{% endkonnect %}

{% on_prem %}
title: Create a second OnPremEventGateway
step: true
content: |
  This guide uses a separate control plane so that it can run alongside the `portMapping` example. Both `OnPremEventGateway` resources are served by the same `GWAdmin`.

  1. Create the `OnPremEventGateway` resource:

     ```bash
     echo '
     apiVersion: eventgateway.konghq.com/v1alpha1
     kind: OnPremEventGateway
     metadata:
       name: cp-event-tls
       namespace: kong
     spec:
       gwAdminRef:
         name: gw-admin
     ' | kubectl apply -f -
     ```

  1. Wait for the resource to be ready:

     ```bash
     kubectl wait onpremeventgateway/cp-event-tls -n kong \
       --for=condition=Programmed=True \
       --timeout=5m
     ```
{% endon_prem %}

## Create the backend cluster, virtual cluster, and listener

1. Create the `EventGatewayBackendCluster`, `EventGatewayVirtualCluster`, and `EventGatewayListener` that define how Kafka traffic connects through the `cp-event-tls` control plane:

   {% konnect %}
   content: |
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
   indent: 3
   {% endkonnect %}

   {% on_prem %}
   content: |
     ```bash
     echo '
     apiVersion: configuration.konghq.com/v1alpha1
     kind: EventGatewayBackendCluster
     metadata:
       name: default-backend-cluster-tls
       namespace: kong
     spec:
       parentRef:
         group: eventgateway.konghq.com
         kind: OnPremEventGateway
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
       parentRef:
         group: eventgateway.konghq.com
         kind: OnPremEventGateway
         name: cp-event-tls
     ' | kubectl apply -f -
     ```
   indent: 3
   {% endon_prem %}

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
   export TLS_CRT=$(base64 < tls.crt | tr -d '\n')
   export TLS_KEY=$(base64 < tls.key | tr -d '\n')
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

1. Apply the listener policies. The TLS server policy reads the certificate and key from the `tls.crt` and `tls.key` keys of the Secret. The SNI forwarding policy sets `advertisedPort` to `19092`, the port of the `Gateway` listener that you create later, because clients connect to the advertised brokers through the `Gateway`:

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
                   key: tls.crt
               key:
                 type: secretRef
                 secretRef:
                   name: sni-listener-tls
                   key: tls.key
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
             advertisedPort: 19092
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

## Deploy the KegDataPlane

For the TLSRoute pattern, the `KegDataPlane` stays internal to the cluster. The Kafka listener is exposed as a `ClusterIP` Service because the Kubernetes `Gateway` will be the public entrypoint.

{% konnect %}
content: |
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
{% endkonnect %}

{% on_prem %}
content: |
  1. Deploy the `KegDataPlane`:

     ```bash
     echo '
     apiVersion: eventgateway.konghq.com/v1alpha1
     kind: KegDataPlane
     metadata:
       name: keg-tls-dp
       namespace: kong
     spec:
       controlPlaneRef:
         type: onpremNamespacedRef
         onpremNamespacedRef:
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

  1. Wait for the data plane to be ready:

     ```bash
     kubectl wait kegdataplane/keg-tls-dp -n kong \
       --for=condition=Ready=True \
       --timeout=5m
     ```
{% endon_prem %}

## Create the Kubernetes Gateway

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

## Attach a TLSRoute to the Gateway

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

1. Wait for the `Gateway` to be programmed, then export its address:

   ```bash
   kubectl wait gateway/kong-keg -n kong --for=condition=Programmed=True --timeout=5m
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

You should see all brokers advertised on port `19092` with DNS names based on the virtual cluster `dnsLabel`, for example:

```text
Metadata for all topics (from broker -1: ssl://bootstrap.vc-tls-1.keg.test.local:19092/bootstrap):
 3 brokers:
  broker 0 at broker-0.vc-tls-1.keg.test.local:19092
  broker 1 at broker-1.vc-tls-1.keg.test.local:19092
  broker 2 at broker-2.vc-tls-1.keg.test.local:19092 (controller)
 0 topics:
```
{:.no-copy-code}

## Produce and consume a record

Create a topic, produce a record, and consume it back through the `Gateway` with `kafkactl`:

```bash
kubectl run kafkactl-tlsroute --rm -i --restart=Never --image=deviceinsight/kafkactl:v5.21.0 -n kong \
  --overrides='{"spec":{"hostAliases":[{"ip":"'"${GATEWAY_IP}"'","hostnames":["bootstrap.vc-tls-1.keg.test.local","broker-0.vc-tls-1.keg.test.local","broker-1.vc-tls-1.keg.test.local","broker-2.vc-tls-1.keg.test.local"]}]}}' \
  --env=BROKERS=bootstrap.vc-tls-1.keg.test.local:19092 \
  --env=TLS_ENABLED=true \
  --env=TLS_INSECURE=true \
  --command -- sh -c '
    kafkactl create topic orders --partitions 1 --replication-factor 3 &&
    kafkactl produce orders --value hello &&
    sleep 3 &&
    kafkactl consume orders --from-beginning --exit --print-headers'
```

The `sleep` gives the new topic's metadata time to propagate before the consumer reads it. The consumed record carries the headers that both policies added:

```text
x-kong-consume-policy:tlsroute,x-kong-produce-policy:tlsroute#hello
```
{:.no-copy-code}
