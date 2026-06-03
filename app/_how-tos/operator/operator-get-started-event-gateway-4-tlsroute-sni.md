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
  - text: Learn more about Kong Event Gateway resources
    url: /operator/konnect/event-gateway/
---

This deployment pattern uses a single TLS listener at the Kubernetes edge and routes Kafka traffic by SNI inside Kong Event Gateway.

Use this pattern when you want:

- one public Kafka listener
- TLS passthrough at the Kubernetes `Gateway`
- broker metadata advertised as DNS names on a single port

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

## Create the TLS Secret and listener policies

Apply the TLS Secret and the two listener policies:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: sni-listener-tls
  namespace: kong
  labels:
    konghq.com/secret: "true"
type: kubernetes.io/tls
stringData:
  tls.crt: |
    -----BEGIN CERTIFICATE-----
    MIIDXjCCAkagAwIBAgIUI8Ky7F+DB3Cd/IMnfy1RkU8WHacwDQYJKoZIhvcNAQEL
    BQAwGTEXMBUGA1UEAwwOa2VnLnRlc3QubG9jYWwwHhcNMjYwNTEzMDgzODA0WhcN
    MjcwNTEzMDgzODA0WjAZMRcwFQYDVQQDDA5rZWcudGVzdC5sb2NhbDCCASIwDQYJ
    KoZIhvcNAQEBBQADggEPADCCAQoCggEBAOF9qFiLQvyGcf+NbTsHfeIf9qWt6LLH
    lpWHBDsAh7ES8I8VmkIjs1jfP52qK00LbTgYNaL2mjxkOPtspd6rATN3BvAPCLl4
    DY8Mn+x2QU8WzbyiPFyZF71qXfhuJyO3lQAbaiWHFwoVJN983USAAqRheutziiFa
    sLU47XT53rdFsjCVbZa0Tdmi6Ebw6605i0oEnD4S59TFOmkUY7QG2HsGsUmLPvCH
    +z1hA9kinR6l5x8zCjA8tcRp8lLkCT8cg/LTFzNF9MOBbzftwRKxxsvqN/KRWBaz
    w0+FpAoUQDsGhq6k+0AIK/xGr4BV6pKLVG/P3k6WJWeIJQQeYHXHu0ECAwEAAaOB
    nTCBmjAdBgNVHQ4EFgQUyLk8pd8F/DYmL6bi98H2yEfeCAcwHwYDVR0jBBgwFoAU
    yLk8pd8F/DYmL6bi98H2yEfeCAcwDwYDVR0TAQH/BAUwAwEB/zBHBgNVHREEQDA+
    ghkqLnZjLXRscy0xLmtlZy50ZXN0LmxvY2FsgiFib290c3RyYXAudmMtdGxzLTEu
    a2VnLnRlc3QubG9jYWwwDQYJKoZIhvcNAQELBQADggEBAMrhSf/KCI9Ap13C7MSF
    Kh/g0fQd/Vbt+K5duP4oCtc5BE0OTz2Xfo5OL1M0RcVCX8J7cQpMyJd/3q479M+v
    o5D1N0bkqGQjJQcBvLNgueYYX7BlA7FT/QN8N7jk0RpvdsmZMy2R2ShnJHh8ziQT
    gIb+w2ysnqaFnyVzFiGtssNEy2pY+ky+YwoZrD8ziYZK7+4JCWNZ2cMVOuoQVe2i
    Z0M3QLrWt02Cm91INSGP0wHTdFlHxsl9t7N4pQMBJKThsNOyGR+od/ERntDJV+bv
    XtlIoWBN69mqinxAj6tOAzdNvHcixQbHRzgjaw/eVStkcwx/JElLLwkte5azA6fs
    JsA=
    -----END CERTIFICATE-----
  tls.key: |
    -----BEGIN PRIVATE KEY-----
    MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDhfahYi0L8hnH/
    jW07B33iH/alreiyx5aVhwQ7AIexEvCPFZpCI7NY3z+dqitNC204GDWi9po8ZDj7
    bKXeqwEzdwbwDwi5eA2PDJ/sdkFPFs28ojxcmRe9al34bicjt5UAG2olhxcKFSTf
    fN1EgAKkYXrrc4ohWrC1OO10+d63RbIwlW2WtE3ZouhG8OutOYtKBJw+EufUxTpp
    FGO0Bth7BrFJiz7wh/s9YQPZIp0epecfMwowPLXEafJS5Ak/HIPy0xczRfTDgW83
    7cESscbL6jfykVgWs8NPhaQKFEA7BoaupPtACCv8Rq+AVeqSi1Rvz95OliVniCUE
    HmB1x7tBAgMBAAECggEAH8BDZQW7BCGO9MvpHmo9egqZKZbVkN2qIQT2014NkqFW
    7ow9Vo8osQdtMZoQEymxko1Uzs0dm7UFvGAonQmEQkcXhX8Acf6VyNefaeWe6EWO
    6RRec9rPbR8IpgjQtGakcZ7qm+fWloIIA/t/kVEweLgMiGc9Ay7+JI55tUJ9RLNP
    1xhY32G3NZvq8uCSiLr8zRLd0u3D6oT35/ZCE0AmDp1PSGPaG3MqZg9bkK86k2dk
    VwEUZkMYiQVkqFFKzstWy7PLFX/18GCHxQiomJFsjzIGLTRMXbmmqrmG+Sb4rT4F
    tlPiFyKE+zvctQG7TzzuVMDEQ99sj/X9f358yB3ixwKBgQDw2O1kYoy2FO3LN1Iz
    Uhm2viFCX90P1Sf1t2mcOtf895mk+9lILdv+V5H43CusQ1JHookFRwmQHgqTOywB
    OgGFX0sYrYJZBaEwVlU8/E83vEPQWDjjY99yBr6I6QOeNdnMlMWdxBQJFWx6vnSo
    4AxP7lKFgnk50GRxLt3vg4h7zwKBgQDvrWYri6lkJHBMy5yqRgbOjqmEqOhomvC0
    4GWrmj6JXCJiti7gtjMA7+BWCAsuF3c7M3GPMhu5rGdS1s5Tvdyxzl4ktGetBjnK
    PeSAANIAMgv2yFTx1DmAcpxUB9FDUeH6zC919eyBGV018KJ7xjHovbaFWIKk7qbw
    EZkvzqHL7wKBgCsl4dmzIhxYwYU/ovVYxwyLIXA/tl3oxSDrO/tmO12xihAZooKg
    3KHDVH5uC1DwOqRkxQFyCY+NIj3gQvDxUGZxfQWtyAVk0czUGq8zUIneq5N+yqpK
    MTS/apEilahZY2yYVpL+FszNzsJqroG2qd4EBzqt9kPaRrRUPiRzvxbXAoGAfs29
    nVJBp1LD+01KMKfl2AiQVThL5XP736ZNBBIR/fg51QHQIWEj8N34UWvmBlex5Cde
    cEUxd/VnoOM2vAVaKtQk6MRtiZQepQpDxxkoAaR4wfLRRjRiy7tXS/nq0/QRW/AF
    OCKJIvA5aV1LibKdGyar1zaxv/LnbWHSKwHmhg8CgYAV58R7rxp966W54nP71NCE
    NxISlWJ3W2HZ2pC3nP7LsUb92gMe8iAvM481dpOsdmz1flwHUEFFh2bXu/kYH3Nd
    XN0nb4gr22SDuJ4VEHLOdWs5pyYpICnYfUW6Jc6SoAfdlFouO5UKbiF53QxFY4Si
    BoGxByd8ti4RUrlSmSdROA==
    -----END PRIVATE KEY-----
---
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

## Deploy the `KegDataPlane`

For the TLSRoute pattern, the `KegDataPlane` stays internal to the cluster. The Kafka listener is exposed as a `ClusterIP` Service because the Kubernetes `Gateway` will be the public entrypoint:

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

```bash
kubectl wait kegdataplane/keg-tls-dp -n kong --for=condition=Ready=True --timeout=5m
```

## Create the Kubernetes `Gateway`

Create a `Gateway` that listens for TLS traffic on port `9092`. It uses TLS passthrough so that Kong Event Gateway still terminates TLS with the certificate you configured earlier:

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
' | kubectl apply -f -
```

```bash
kubectl wait gateway/kong-keg -n kong --for=condition=Programmed=True --timeout=5m
```

## Attach a `TLSRoute` to the `Gateway`

The `TLSRoute` binds the wildcard Kafka hostnames to the internal Kafka Service exposed by the `KegDataPlane`:

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

Wait for the Event Gateway resources to become programmed:

```bash
kubectl wait -n kong \
  konnecteventgateway/cp-event-tls \
  eventgatewaybackendcluster/default-backend-cluster-tls \
  eventgatewayvirtualcluster/example-virtual-cluster-tls \
  eventgatewaylistener/sni-listener \
  eventgatewaylistenerpolicy/sni-tls-server \
  eventgatewaylistenerpolicy/sni-forward \
  eventgatewayvirtualclusterconsumepolicy/example-virtual-cluster-tls-consume-policy \
  eventgatewayvirtualclusterproducepolicy/example-virtual-cluster-tls-produce-policy \
  --for=jsonpath='{.status.conditions[?(@.type=="Programmed")].status}'=True \
  --timeout=10m
```

Wait for the data plane and `Gateway`:

```bash
kubectl wait kegdataplane/keg-tls-dp -n kong \
  --for=condition=Ready=True \
  --timeout=10m

kubectl wait gateway/kong-keg -n kong \
  --for=condition=Programmed=True \
  --timeout=10m
```

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
