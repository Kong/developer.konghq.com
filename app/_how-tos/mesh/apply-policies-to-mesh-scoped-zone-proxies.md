---
title: 'Apply policies to mesh-scoped zone proxies'
description: 'Target mesh-scoped zone ingress and zone egress with MeshTrafficPermission, MeshMetric, and MeshAccessLog using Dataplane labels and sectionName.'
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
    1. Reuse the three-cluster setup from `/mesh/zone-proxies/`.
    1. Select zone proxies with Dataplane labels such as `kuma.io/listener-zoneingress` and `kuma.io/listener-zoneegress`.
    1. Inspect the generated listener names, then verify zone-ingress observability directly through Envoy config and logs.

prereqs:
  inline:
    - title: Deploy mesh-scoped zone proxies
      content: |
        Follow [Deploy mesh-scoped zone proxies](/mesh/zone-proxies/) and leave the three minikube clusters running.
---

This guide reuses the `GLOBAL_PROFILE`, `ZONE1_PROFILE`, and `ZONE2_PROFILE` variables from [Deploy mesh-scoped zone proxies](/mesh/zone-proxies/).
Mesh-scoped zone proxies are ordinary `Dataplane` resources, so you select them with policy `targetRef` labels instead of legacy `ZoneIngress` or `ZoneEgress` resources.

## Inspect the stable zone proxy targets

Kuma computes two Dataplane labels for mesh-scoped zone proxies:
- `kuma.io/listener-zoneingress: enabled`
- `kuma.io/listener-zoneegress: enabled`

On Kubernetes, inspect the generated `Dataplane` resource to find the exact listener name for each zone proxy.
With the current chart output, the ingress listener is `10001` and the egress listener is `10002`.

1. Inspect the generated Dataplanes, confirm the zone proxy labels, and note the listener names:

   ```sh
   kubectl --context $GLOBAL_PROFILE get dataplane -A -o json | \
     jq '.items[] |
         select(.metadata.labels["kuma.io/listener-zoneingress"] == "enabled" or
                .metadata.labels["kuma.io/listener-zoneegress"] == "enabled") |
         {
           name: .metadata.name,
           zone: .metadata.labels["kuma.io/zone"],
           ingress: .metadata.labels["kuma.io/listener-zoneingress"],
           egress: .metadata.labels["kuma.io/listener-zoneegress"],
           listeners: [.spec.networking.listeners[].name]
         }'
   ```

## Target MeshTrafficPermission at zone egress

The bootstrap allow-all policy from the first guide uses `spec.rules`.
Zone proxy permissions use the same field, but with listener-specific selectors and matches.
`spec.from` and `spec.rules` are mutually exclusive, so use only one model per resource.

On zone egress, the destination is matched by SNI.

{:.warning}
> In the preview build used for this guide, the deny rule below did not yet change live traffic end-to-end.
> Use this section as the current targeting pattern for mesh-scoped zone egress while the enforcement issue is being investigated.

1. Create a simple unmeshed HTTP service in zone-1 and register it as a `MeshExternalService`:

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

1. Create a simple curl pod in the mesh namespace so you have a disposable client:

   ```sh
   kubectl --context $ZONE1_PROFILE -n kuma-demo run curl \
    --image=curlimages/curl:8.12.1 \
    --restart=Never \
    --command -- sleep 3600
   ```

1. Apply a `MeshTrafficPermission` that targets the zone-1 egress listener directly:

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

1. Use the curl pod to exercise the zone-egress cluster:

   ```sh
   kubectl --context $ZONE1_PROFILE -n kuma-demo exec pod/curl -- \
    curl -s http://external-service-kube.extsvc.mesh.local
   ```

   The current chart-generated zone-egress cluster name is:

   ```text
   cluster.kri_extsvc_default_zone-1_kong-mesh-system_external-service-kube_80
   ```
   {:.no-copy-code}

## Add MeshMetric to zone ingress

`MeshMetric` is proxy-wide.
On zone-proxy-only dataplanes it skips application scraping config and exposes the proxy role instead.

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
       applications:
         - name: ignored-on-zone-proxy
           path: /metrics
           port: 8888
       backends:
         - type: Prometheus
           prometheus:
             port: 5670
             path: /metrics
             tls:
               mode: Disabled' | \
     kubectl --context $GLOBAL_PROFILE apply -f -
   ```

1. Port-forward the zone-2 ingress admin endpoint if you don't already have it from the first guide:

   ```sh
   kubectl --context $ZONE2_PROFILE -n kong-mesh-system \
     port-forward deploy/kong-mesh-default-ingress 9903:9902
   ```

1. Inspect the dynamic config payload in Envoy's config dump:

   ```sh
   curl -s http://127.0.0.1:9903/config_dump | \
     jq -r '.. | strings? |
       select(test("_kuma:dynamicconfig|kuma.proxy_role|ignored-on-zone-proxy|applications"))'
   ```

   The output should:
   - include `_kuma:dynamicconfig`
   - include `"applications":null`
   - include `"kuma.proxy_role":"zone-ingress"`
   - not include `ignored-on-zone-proxy`

## Add MeshAccessLog to zone ingress

Zone ingress does not terminate mTLS.
That means the most reliable selector is the requested SNI, not downstream peer SAN fields.

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
- inspect `.spec.networking.listeners[].name` on the generated `Dataplane` and use that as `sectionName` when you want one exact listener
