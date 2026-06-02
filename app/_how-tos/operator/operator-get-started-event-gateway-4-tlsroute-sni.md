---
title: Deploy Kong Event Gateway with TLSRoute and SNI
description: Deploy Kong Event Gateway behind a Kubernetes Gateway using TLS passthrough and SNI routing.
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
  show_works_on: true
  skip_product: true
  operator:
    konnect:
      auth: true

tldr:
  q: How do I deploy Kong Event Gateway in a production-oriented topology?
  a: Front the Event Gateway with a `Gateway` and `TLSRoute`, terminate TLS in Kong Event Gateway, and route virtual clusters with SNI.

next_steps:
  - text: Learn more about Kong Event Gateway
    url: /event-gateway/
---

This deployment pattern uses a single TLS listener at the Kubernetes edge and routes Kafka traffic by SNI inside Kong Event Gateway.

Use this pattern when you want:

- one public Kafka listener
- TLS passthrough at the Kubernetes `Gateway`
- broker metadata advertised as DNS names on a single port

## Install the Gateway API CRDs

If your cluster doesn't already have the Kubernetes Gateway API CRDs installed, install them now:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v{{ site.gwapi_version }}/standard-install.yaml --server-side
```

## Create a `GatewayConfiguration` and `GatewayClass`

Create a managed `Gateway` class for the TLSRoute example. This `Gateway` is provisioned through {{ site.konnect_short_name }}, so the `GatewayConfiguration` should reference the `KonnectAPIAuthConfiguration` created in the prerequisites:

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

## Create a second `KonnectEventGateway`

This guide uses a separate control plane so that it can run alongside the `portMapping` example:

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

## Create the backend cluster, virtual cluster, and listener

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

## Create the TLS certificate, Secret, and listener policies

Generate a certificate that covers the wildcard broker hostnames and bootstrap hostname advertised by the SNI policy:

```bash
openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout ./keg-tls.key \
  -out ./keg-tls.crt \
  -days 365 \
  -subj "/CN=keg.test.local" \
  -addext "subjectAltName=DNS:*.vc-tls-1.keg.test.local,DNS:bootstrap.vc-tls-1.keg.test.local"
```

Create a TLS Secret from the generated certificate and key, then add the label used by Kong secrets:

```bash
kubectl create secret tls sni-listener-tls \
  -n kong \
  --cert=./keg-tls.crt \
  --key=./keg-tls.key

kubectl label secret sni-listener-tls \
  -n kong \
  konghq.com/secret=true \
  --overwrite
```

Apply the two listener policies:

```bash
cat <<'EOF' | kubectl apply -f -
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
EOF
```

## Create consume and produce policies

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

## Deploy the `KegDataPlane`, `Gateway`, and `TLSRoute`

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
---
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
      port: 9092
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
---
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

Export the `Gateway` address:

```bash
export GATEWAY_IP=$(kubectl get gateway kong-keg -n kong -o jsonpath='{.status.addresses[0].value}')
echo $GATEWAY_IP
```

Check the TLSRoute conditions:

```bash
kubectl get tlsroute keg-tls -n kong \
  -o jsonpath='{range .status.parents[0].conditions[*]}{.type}={.status}{" "}{end}{"\n"}'
```

## Smoke test with Kafka metadata

For local testing, create host aliases for the advertised broker hostnames and request metadata with `kcat`:

```bash
kubectl run kcat-tlsroute --rm -i --restart=Never --image=edenhill/kcat:1.7.1 -n kong \
  --overrides='{"spec":{"hostAliases":[{"ip":"'"${GATEWAY_IP}"'","hostnames":["bootstrap.vc-tls-1.keg.test.local","broker-0.vc-tls-1.keg.test.local","broker-1.vc-tls-1.keg.test.local","broker-2.vc-tls-1.keg.test.local"]}]}}' \
  --command -- kcat -b bootstrap.vc-tls-1.keg.test.local:9092 \
  -X security.protocol=SSL \
  -X enable.ssl.certificate.verification=false \
  -L
```

You should see all brokers advertised on port `9092` with DNS names based on the virtual cluster `dnsLabel`.
