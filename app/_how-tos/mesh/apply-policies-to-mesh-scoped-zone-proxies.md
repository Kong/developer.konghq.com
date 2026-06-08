---
title: 'Apply policies to mesh-scoped zone proxies'
description: 'Target mesh-scoped zone ingress and zone egress with MeshTrafficPermission, MeshMetric, and MeshAccessLog.'
content_type: how_to
permalink: /mesh/zone-proxy-policies/
bread-crumbs:
  - /mesh/
related_resources:
  - text: 'Deploy mesh-scoped zone proxies'
    url: '/mesh/zone-proxies/'
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

tldr:
  q: How do I target mesh-scoped zone proxies with {{site.mesh_product_name}} policies?
  a: |
    1. Reuse the three-cluster setup from [Deploy mesh-scoped zone proxies](/mesh/zone-proxies/).
    1. Find the zone proxy Dataplanes and their listener names.
    1. Apply policies to the zone proxies and verify them through Envoy stats, metrics, and access logs.

prereqs:
  inline:
    - title: Deploy mesh-scoped zone proxies
      content: |
        Follow [Deploy mesh-scoped zone proxies](/mesh/zone-proxies/) and leave the three minikube clusters running.
---

This guide reuses the `GLOBAL_PROFILE`, `ZONE1_PROFILE`, and `ZONE2_PROFILE` variables from [Deploy mesh-scoped zone proxies](/mesh/zone-proxies/).
Zone proxies appear as `Dataplane` resources, so you target them with `targetRef` labels and, when needed, a listener name.

## Find the zone proxy Dataplanes and listener names

Zone proxy Dataplanes include these labels:
- `kuma.io/listener-zoneingress: enabled`
- `kuma.io/listener-zoneegress: enabled`

Inspect the Dataplanes to see which labels are present and to find the listener names for your environment.
In the example output below, the ingress listener is `10001` and the egress listener is `10002`.

1. Inspect the zone proxy Dataplanes:

   ```sh
   kubectl --context $GLOBAL_PROFILE get dataplane -A -o json
   ```

## Apply MeshTrafficPermission to zone egress

1. Create a simple HTTP service in zone-1 and register it as a `MeshExternalService`:

   ```sh
   kubectl --context $ZONE1_PROFILE create namespace kuma-demo-ext \
     --dry-run=client -o yaml | kubectl --context $ZONE1_PROFILE apply -f -

   echo 'apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: external-service-kube
     namespace: kuma-demo-ext
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
     namespace: kuma-demo-ext
   spec:
     selector:
       app: external-service-kube
     ports:
       - port: 80
         targetPort: 5678' | kubectl --context $ZONE1_PROFILE apply -f -

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
       - address: external-service-kube.kuma-demo-ext.svc.cluster.local
         port: 80' | kubectl --context $ZONE1_PROFILE apply -f -
   ```

1. Create a disposable curl client:

   ```sh
   kubectl --context $ZONE1_PROFILE create namespace mtp-client \
     --dry-run=client -o yaml | kubectl --context $ZONE1_PROFILE apply -f -

   kubectl --context $ZONE1_PROFILE label namespace mtp-client \
     kuma.io/sidecar-injection=enabled --overwrite

   kubectl --context $ZONE1_PROFILE -n mtp-client run debug-client \
     --image=curlimages/curl:8.12.1 \
     --restart=Never \
     --command -- sleep 3600

   kubectl --context $ZONE1_PROFILE -n mtp-client wait \
     --for=condition=ready pod/debug-client --timeout=120s
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

1. Send the request through zone egress:

   ```sh
   kubectl --context $ZONE1_PROFILE -n mtp-client exec debug-client -c debug-client -- \
     curl -sv --max-time 15 http://external-service-kube.extsvc.mesh.local
   ```

1. Check the RBAC stats on the zone-1 egress:

   ```sh
   kubectl --context $ZONE1_PROFILE -n kong-mesh-system exec deploy/kong-mesh-default-egress -c kuma-sidecar -- \
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
   kubectl --context $ZONE2_PROFILE -n kong-mesh-system exec deploy/kong-mesh-default-ingress -c kuma-sidecar -- \
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

1. Apply a `MeshAccessLog` that logs the zone-2 `demo-app` SNI to a file on the ingress proxy:

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
               value: sni.msvc.default.zone-2.kuma-demo.demo-app.5000
         default:
           backends:
             - type: File
               file:
                 path: /tmp/zone-2-demo-app.log
                 format:
                   type: Plain
                   plain: "sni=%REQUESTED_SERVER_NAME%"' | \
     kubectl --context $GLOBAL_PROFILE apply -f -
   ```

1. Remove any previous log file, send the cross-zone request again, and read the latest access log entry:

   ```sh
   kubectl --context $ZONE2_PROFILE -n kong-mesh-system exec deploy/kong-mesh-default-ingress -c kuma-sidecar -- \
     rm -f /tmp/zone-2-demo-app.log

   kubectl --context $ZONE1_PROFILE -n kuma-demo exec deploy/demo-app -c demo-app -- \
     wget -qO- http://demo-app.kuma-demo.svc.zone-2.mesh.local:5000/ >/dev/null

   kubectl --context $ZONE2_PROFILE -n kong-mesh-system exec deploy/kong-mesh-default-ingress -c kuma-sidecar -- \
     tail -n 1 /tmp/zone-2-demo-app.log
   ```

   The log line should contain:

   ```text
   sni=sni.msvc.default.zone-2.kuma-demo.demo-app.5000
   ```
   {:.no-copy-code}

## Next steps

If you want to target a different zone proxy, keep the same pattern:
- narrow `targetRef.kind: Dataplane` with `kuma.io/listener-zoneingress` or `kuma.io/listener-zoneegress`
- add `kuma.io/zone` when you want one specific zone
- inspect `.spec.networking.listeners[].name` on the zone proxy `Dataplane` and use that listener name in `sectionName` when you want one exact listener
