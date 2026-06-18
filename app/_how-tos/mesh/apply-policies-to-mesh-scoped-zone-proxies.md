---
title: 'Apply policies to mesh-scoped zone proxies'
description: 'Target mesh-scoped zone ingress and zone egress with MeshTrafficPermission, MeshMetric, and MeshAccessLog.'
content_type: how_to
permalink: /mesh/zone-proxy-policies/
breadcrumbs:
  - /mesh/
related_resources:
  - text: 'Mesh Traffic Permission'
    url: '/mesh/policies/meshtrafficpermission/'
  - text: 'Mesh Metric'
    url: '/mesh/policies/meshmetric/'
  - text: 'Mesh Access Log'
    url: '/mesh/policies/meshaccesslog/'

min_version:
  mesh: '2.14'

products:
  - mesh

series:
  id: mesh-scoped-zone-proxy
  position: 2

tldr:
  q: How do I target mesh-scoped zone proxies with {{site.mesh_product_name}} policies?
  a: |
    1. Find the zone proxy `Dataplane` resources and their listener names.
    1. Apply policies to the zone proxies and verify them through Envoy stats, metrics, and access logs.

faqs:
  - q: How do I target a different zone proxy?
    a: |
      Use the same pattern as this guide:
      - Narrow `targetRef.kind: Dataplane` with `kuma.io/listener-zoneingress` or `kuma.io/listener-zoneegress`.
      - Add `kuma.io/zone` to target one specific zone.
      - Inspect `.spec.networking.listeners[].name` on the generated `Dataplane` and use that value as `sectionName` to target one exact listener.
---

Mesh-scoped zone proxies are ordinary `Dataplane` resources, so you must select them with policy `targetRef` labels instead of legacy `ZoneIngress` or `ZoneEgress` resources.

## Find the zone proxy Dataplanes and listener names

{{site.mesh_product_name}} computes two `Dataplane` labels for mesh-scoped zone proxies:
- `kuma.io/listener-zoneingress: enabled`
- `kuma.io/listener-zoneegress: enabled`

Inspect the Dataplanes to see which labels are present and to find the listener names for your environment.
In the example output below, the ingress listener is `10001` and the egress listener is `10002`.

1. Inspect the zone proxy Dataplanes:

   ```sh
   kubectl --context $GLOBAL_PROFILE get dataplane -A -o json
   ```

## Target MeshTrafficPermission at the zone egress

1. Create the namespace for the external service:

   ```sh
   kubectl --context $ZONE1_PROFILE create namespace kong-mesh-demo-ext \
     --dry-run=client -o yaml | kubectl --context $ZONE1_PROFILE apply -f -
   ```

1. Deploy the external service:

   ```sh
   echo 'apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: external-service-kube
     namespace: kong-mesh-demo-ext
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: external-service-kube
     template:
       metadata:
         labels:
           app: external-service-kube
       spec:
         containers:
           - name: http-echo
             image: hashicorp/http-echo:1.0.0
             args: ["-text=external-service-kube"]
             ports:
               - containerPort: 5678
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: external-service-kube
     namespace: kong-mesh-demo-ext
   spec:
     selector:
       app: external-service-kube
     ports:
       - port: 80
         targetPort: 5678' | kubectl --context $ZONE1_PROFILE apply -f -
   ```

1. Register the external service as a `MeshExternalService`:

   ```sh
   echo 'apiVersion: kuma.io/v1alpha1
   kind: MeshExternalService
   metadata:
     name: external-service-kube
     namespace: kong-mesh-system
     labels:
       kuma.io/origin: zone
       kuma.io/mesh: default
   spec:
     match:
       type: HostnameGenerator
       port: 80
       protocol: http
     endpoints:
       - address: external-service-kube.kong-mesh-demo-ext.svc.cluster.local
         port: 80' | kubectl --context $ZONE1_PROFILE apply -f -
   ```

1. Apply a `MeshTrafficPermission` that targets the zone-1 egress listener directly.
   The default is `10002`:

   ```sh
   echo 'apiVersion: kuma.io/v1alpha1
   kind: MeshTrafficPermission
   metadata:
     name: deny-external-service-kube
     namespace: kong-mesh-system
     labels:
       kuma.io/mesh: default
   spec:
     targetRef:
       kind: Dataplane
       labels:
         kuma.io/listener-zoneegress: enabled
         kuma.io/zone: zone-1
       sectionName: "10002"
     rules:
       - default:
           deny:
             - sni:
                 type: Exact
                 value: sni.extsvc.default.zone-1.kong-mesh-system.external-service-kube.80' | \
     kubectl --context $GLOBAL_PROFILE apply -f -
   ```

1. Send the request through zone egress from the zone-1 `demo-app` pod:

   ```sh
   kubectl --context $ZONE1_PROFILE -n kong-mesh-demo exec deploy/demo-app -c demo-app -- \
     wget -qO /dev/null http://external-service-kube.extsvc.mesh.local
   ```

   The request should be denied by the egress policy.

1. Check the RBAC stats on the zone-1 egress:

   ```sh
   kubectl --context $ZONE1_PROFILE -n kong-mesh-system \
     exec deploy/kong-mesh-default-egress -c kuma-sidecar -- \
     wget -qO- 'http://127.0.0.1:9902/stats?filter=external-service-kube.*rbac'
   ```

   The request should be denied, and `rbac.denied` should increase for the external-service cluster.

## Add MeshMetric to zone ingress

Apply `MeshMetric` to the zone-2 ingress and read the Prometheus endpoint from inside the sidecar.

1. Apply a `MeshMetric` that targets the zone-2 ingress:

   ```sh
   echo 'apiVersion: kuma.io/v1alpha1
   kind: MeshMetric
   metadata:
     name: zone-2-ingress-metrics
     namespace: kong-mesh-system
     labels:
       kuma.io/mesh: default
   spec:
     targetRef:
       kind: Dataplane
       labels:
         kuma.io/listener-zoneingress: enabled
         kuma.io/zone: zone-2
     default:
       backends:
         - type: Prometheus
           prometheus:
             port: 5670
             path: /metrics
             tls:
               mode: Disabled' | \
     kubectl --context $GLOBAL_PROFILE apply -f -
   ```

1. Read the metrics from the zone-2 ingress sidecar:

   ```sh
   kubectl --context $ZONE2_PROFILE -n kong-mesh-system \
     exec deploy/kong-mesh-default-ingress -c kuma-sidecar -- \
     sh -c '
       POD_IP=$(hostname -i | awk "{print \$1}")
       wget -qO- "http://$POD_IP:5670/metrics" | \
         grep "kuma_proxy_role=\"zone-ingress\"" | sed -n "1,10p"
     '
   ```

   You should see Envoy metrics labeled `kuma_proxy_role="zone-ingress"`.

## Add MeshAccessLog to zone ingress

Zone ingress does not terminate mTLS.
Match the traffic by SNI.

1. Apply a `MeshAccessLog` that logs the zone-2 `demo-app` SNI to the ingress proxy's stdout:

   ```sh
   echo 'apiVersion: kuma.io/v1alpha1
   kind: MeshAccessLog
   metadata:
     name: zone-2-ingress-log
     namespace: kong-mesh-system
     labels:
       kuma.io/mesh: default
   spec:
     targetRef:
       kind: Dataplane
       labels:
         kuma.io/listener-zoneingress: enabled
         kuma.io/zone: zone-2
       sectionName: "10001"
     rules:
       - matches:
           - sni:
               type: Exact
               value: sni.msvc.default.zone-2.kong-mesh-demo.demo-app.5000
         default:
           backends:
             - type: File
               file:
                 path: /dev/stdout
                 format:
                   type: Plain
                   plain: "zone-ingress-sni=%REQUESTED_SERVER_NAME%"' | \
     kubectl --context $GLOBAL_PROFILE apply -f -
   ```

1. Send the cross-zone request again:

   ```sh
   kubectl --context $ZONE1_PROFILE -n kong-mesh-demo exec deploy/demo-app -c demo-app -- \
     wget -qO /dev/null http://demo-app.kong-mesh-demo.svc.zone-2.mesh.local:5000/
   ```

1. Check the ingress proxy logs for the access log entry:

   ```sh
   kubectl --context $ZONE2_PROFILE -n kong-mesh-system logs deploy/kong-mesh-default-ingress \
     -c kuma-sidecar | grep "zone-ingress-sni"
   ```

   The output should contain:

   ```text
   zone-ingress-sni=sni.msvc.default.zone-2.kong-mesh-demo.demo-app.5000
   ```
   {:.no-copy-code}
