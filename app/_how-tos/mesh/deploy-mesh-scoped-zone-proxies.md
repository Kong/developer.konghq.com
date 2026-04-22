---
title: 'Deploy mesh-scoped zone proxies'
description: 'Deploy {{site.mesh_product_name}} zone ingress and zone egress using the new per-mesh Helm configuration. Each entry in `kuma.meshes[]` renders its own Deployment, Service, and Dataplane listeners, replacing the cluster-scoped `kuma.ingress` and `kuma.egress` keys.'
content_type: how_to
permalink: /mesh/zone-proxies/
bread-crumbs:
  - /mesh/
related_resources:
  - text: 'Multi-zone deployment'
    url: '/mesh/mesh-multizone-service-deployment/'

min_version:
  mesh: '2.14'

products:
  - mesh

tldr:
  q: How do I deploy mesh-scoped zone ingress and zone egress with the new Helm configuration?
  a: |
    1. Create a `Mesh` with `spec.meshServices.mode: Exclusive` and a `MeshIdentity` on the global control plane.
    1. Install each zone control plane with a `kuma.meshes[]` entry.
    1. {{site.mesh_product_name}} renders a per-mesh Deployment and Service for each role, and generates the Dataplane listeners automatically.

prereqs:
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: minikube
      content: |
        You will need [minikube](https://minikube.sigs.k8s.io/docs/start/) to run three local Kubernetes clusters (one global and two zones).

cleanup:
  inline:
    - title: Clean up {{site.mesh_product_name}} resources
      content: |
        Delete the three minikube profiles:

        ```sh
        minikube delete -p mesh-global
        minikube delete -p mesh-zone-1
        minikube delete -p mesh-zone-2
        ```
---

Starting in {{site.mesh_product_name}} 2.14, zone ingress and zone egress are **mesh-scoped**.
Instead of the cluster-scoped `kuma.ingress.enabled` / `kuma.egress.enabled` Helm keys, you declare a `kuma.meshes[]` list in your zone control plane's values.
Each entry renders its own Deployment, Service, and Dataplane for that mesh, and zone proxies now carry per-mesh workload identity so policies can target them directly.

This guide walks through a fresh three-cluster setup: a global control plane and two zone control planes, each deploying a zone ingress and zone egress through the new `kuma.meshes[]` configuration.

## Start the global control plane cluster

1. Create a new minikube cluster for the global control plane:

   ```sh
   minikube start -p mesh-global
   ```

1. Start a minikube tunnel so the `LoadBalancer` services we create later get an external address:

   {:.info}
   > Using `nohup` lets the tunnel continue running if your terminal session ends.
   > The `--bind-address=0.0.0.0` flag exposes the tunnel to other minikube clusters via `host.minikube.internal`.

   ```sh
   nohup minikube tunnel -p mesh-global --bind-address=0.0.0.0 &
   ```

## Deploy the global control plane

1. Install the global control plane:

   ```sh
   helm repo add kong-mesh https://kong.github.io/kong-mesh-charts
   helm repo update
   helm install --kube-context mesh-global --create-namespace --namespace kong-mesh-system \
     --set kuma.controlPlane.mode=global \
     --set kuma.controlPlane.defaults.skipMeshCreation=true \
     kong-mesh kong-mesh/kong-mesh
   ```

   We skip default mesh creation because we will apply a custom `Mesh` in the next step.

1. Wait for the control plane to become ready:

   ```sh
   kubectl --context mesh-global -n kong-mesh-system wait \
     --for=condition=ready pod --selector=app=kong-mesh-control-plane --timeout=120s
   ```

1. Export the KDS address that the zone control planes will connect to:

   ```sh
   export EXTERNAL_IP=host.minikube.internal
   ```

   {:.info}
   > Outside minikube, resolve the `kong-mesh-global-zone-sync` service address instead:
   >
   > ```sh
   > export EXTERNAL_IP=$(kubectl --context mesh-global -n kong-mesh-system \
   >   get svc kong-mesh-global-zone-sync -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
   > ```

## Create the mesh on the global control plane

Zone proxy listeners are only generated when the mesh uses `MeshService` exclusive mode.
If you skip this, the zone proxies install but produce no listeners.

1. Create the mesh and allow all traffic:

   ```sh
   echo 'apiVersion: kuma.io/v1alpha1
   kind: Mesh
   metadata:
     name: default
   spec:
     meshServices:
       mode: Exclusive
   ---
   apiVersion: kuma.io/v1alpha1
   kind: MeshTrafficPermission
   metadata:
     name: allow-all
     namespace: kong-mesh-system
     labels:
       kuma.io/mesh: default
   spec:
     targetRef:
       kind: Mesh
     from:
       - targetRef:
           kind: Mesh
         default:
           action: Allow' | kubectl --context mesh-global apply -f -
   ```

## Create a MeshIdentity

Zone egress listeners need a workload identity to terminate mTLS for cross-zone traffic.
Apply a `MeshIdentity` on the global control plane so it syncs to every zone.

```sh
{% raw %}echo 'apiVersion: kuma.io/v1alpha1
kind: MeshIdentity
metadata:
  name: identity
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
spec:
  selector:
    dataplane:
      matchLabels: {}
  spiffeID:
    trustDomain: "{{ .Mesh }}.{{ .Zone }}.mesh.local"
  provider:
    type: Bundled
    bundled:
      meshTrustCreation: Enabled
      insecureAllowSelfSigned: true
      certificateParameters:
        expiry: 24h
      autogenerate:
        enabled: true' | kubectl --context mesh-global apply -f -{% endraw %}
```

{:.info}
> `insecureAllowSelfSigned: true` keeps the demo simple by using the bundled CA.
> For production, follow the [`MeshIdentity` guide](/mesh/mesh-identity/) to integrate a SPIRE trust domain or an external CA.

## Deploy zone-1 with mesh-scoped zone proxies

A `kuma.meshes[]` entry tells the chart which mesh the zone proxies belong to.
Each entry renders its own Deployment, Service, and ServiceAccount for the ingress and egress roles.

1. Start the zone-1 cluster and its tunnel:

   ```sh
   minikube start -p mesh-zone-1
   nohup minikube tunnel -p mesh-zone-1 --bind-address=0.0.0.0 &
   ```

1. Save the following as `zone-1-values.yaml`, replacing `${EXTERNAL_IP}` with the value you exported earlier:

   ```yaml
   kuma:
     controlPlane:
       mode: zone
       zone: zone-1
       kdsGlobalAddress: grpcs://${EXTERNAL_IP}:5685
       tls:
         kdsZoneClient:
           skipVerify: true
     meshes:
       - name: default
         ingress:
           enabled: true
         egress:
           enabled: true
   ```

   To deploy zone proxies for additional meshes, append more entries to `kuma.meshes`.

1. Install the zone control plane together with the zone ingress and egress for `default`:

   ```sh
   helm install --kube-context mesh-zone-1 --create-namespace --namespace kong-mesh-system \
     -f zone-1-values.yaml \
     kong-mesh kong-mesh/kong-mesh
   ```

## Deploy zone-2 with the same configuration

1. Start the zone-2 cluster and its tunnel:

   ```sh
   minikube start -p mesh-zone-2
   nohup minikube tunnel -p mesh-zone-2 --bind-address=0.0.0.0 &
   ```

1. Save the following as `zone-2-values.yaml`, replacing `${EXTERNAL_IP}` with the value you exported earlier:

   ```yaml
   kuma:
     controlPlane:
       mode: zone
       zone: zone-2
       kdsGlobalAddress: grpcs://${EXTERNAL_IP}:5685
       tls:
         kdsZoneClient:
           skipVerify: true
     meshes:
       - name: default
         ingress:
           enabled: true
           service:
             port: 10002
         egress:
           enabled: true
   ```

   {:.info}
   > Zone-2's ingress uses port `10002` so it doesn't collide with zone-1's ingress on port `10001` when both tunnels publish to the same host address.

1. Install the zone control plane and its zone proxies:

   ```sh
   helm install --kube-context mesh-zone-2 --create-namespace --namespace kong-mesh-system \
     -f zone-2-values.yaml \
     kong-mesh kong-mesh/kong-mesh
   ```

## Patch the ingress Services for cross-cluster routing

Minikube tunnels assign `127.0.0.1` as the external IP, which doesn't route between clusters.
Patch each zone's ingress Service to advertise `host.minikube.internal`'s IP instead.

1. Get the host IP that all minikube clusters can reach:

   ```sh
   export HOST_IP=$(minikube ssh -p mesh-zone-1 -- getent hosts host.minikube.internal | awk '{print $1}')
   echo $HOST_IP
   ```

1. Patch the ingress Service in zone-1:

   ```sh
   kubectl --context mesh-zone-1 -n kong-mesh-system patch svc kong-mesh-default-ingress \
     --type merge -p "{\"spec\":{\"externalIPs\":[\"$HOST_IP\"]}}"
   ```

1. Patch the ingress Service in zone-2:

   ```sh
   kubectl --context mesh-zone-2 -n kong-mesh-system patch svc kong-mesh-default-ingress \
     --type merge -p "{\"spec\":{\"externalIPs\":[\"$HOST_IP\"]}}"
   ```

The `MeshZoneAddress` controller will pick up the new external IP and regenerate the address resources.

## Propagate trust between zones

Each zone generates a `MeshTrust` containing its local CA bundle.
For cross-zone mTLS to work, each zone must trust the other zone's CA.
Republish each zone's trust bundle to the global control plane so it syncs everywhere.

1. Export zone-1's trust bundle and apply it to the global CP:

   ```sh
   kubectl --context mesh-zone-1 -n kong-mesh-system get meshtrust identity -o yaml | \
     sed 's/name: identity/name: trust-of-zone-1/' | \
     sed '/resourceVersion:/d' | \
     sed '/uid:/d' | \
     sed '/creationTimestamp:/d' | \
     sed '/generation:/d' | \
     sed 's/kuma.io\/origin: zone/kuma.io\/origin: global/' | \
     kubectl --context mesh-global apply -f -
   ```

1. Export zone-2's trust bundle and apply it to the global CP:

   ```sh
   kubectl --context mesh-zone-2 -n kong-mesh-system get meshtrust identity -o yaml | \
     sed 's/name: identity/name: trust-of-zone-2/' | \
     sed '/resourceVersion:/d' | \
     sed '/uid:/d' | \
     sed '/creationTimestamp:/d' | \
     sed '/generation:/d' | \
     sed 's/kuma.io\/origin: zone/kuma.io\/origin: global/' | \
     kubectl --context mesh-global apply -f -
   ```

The global control plane syncs these trust bundles to all zones, enabling cross-zone certificate validation.

## Inspect what the chart produced

1. List the per-mesh Deployments and Services in zone-1:

   ```sh
   kubectl --context mesh-zone-1 -n kong-mesh-system get deploy,svc -l kuma.io/mesh=default
   ```

   You'll see a `kong-mesh-default-ingress` and `kong-mesh-default-egress` Deployment, each with a matching Service.
   A second mesh would produce another pair named after its mesh.

1. Confirm the Services carry the new `k8s.kuma.io/zone-proxy-type` label.
   The Pod controller watches this label and generates the Dataplane listeners from it:

   ```sh
   kubectl --context mesh-zone-1 -n kong-mesh-system get svc \
     -l k8s.kuma.io/zone-proxy-type -L k8s.kuma.io/zone-proxy-type
   ```

1. From the global control plane, look at the Dataplanes.
   Zone proxies are now ordinary `Dataplane` resources with `networking.listeners[]` entries instead of separate `ZoneIngress` or `ZoneEgress` resources:

   ```sh
   kubectl --context mesh-global get dataplane -A
   ```

1. Confirm that no legacy zone proxy resources exist.
   Both lists should be empty:

   ```sh
   kubectl --context mesh-global get zoneingresses,zoneegresses -A
   ```
   {:.no-copy-code}

1. Inspect the `MeshZoneAddress` resources.
   The `meshzoneaddress` controller in each zone generates these automatically from the zone ingress Service's external address, so remote zones can route to them:

   ```sh
   kubectl --context mesh-zone-1 get meshzoneaddress -A
   kubectl --context mesh-zone-2 get meshzoneaddress -A
   ```

## Verify cross-zone traffic

1. Deploy the {{site.mesh_product_name}} demo app into each zone:

   ```sh
   for ctx in mesh-zone-1 mesh-zone-2; do
     kubectl --context $ctx create namespace kuma-demo \
       --dry-run=client -o yaml | kubectl --context $ctx apply -f -
     kubectl --context $ctx label namespace kuma-demo \
       kuma.io/sidecar-injection=enabled --overwrite
     kubectl --context $ctx apply -f https://raw.githubusercontent.com/kumahq/kuma-counter-demo/refs/heads/master/demo.yaml
   done
   ```

1. From a `demo-app` pod in zone-1, curl the `demo-app` Service in zone-2 using its cross-zone hostname:

   ```sh
   kubectl --context mesh-zone-1 -n kuma-demo exec deploy/demo-app -c demo-app -- \
     curl -s http://demo-app.kuma-demo.svc.zone-2.mesh.local:5050/
   ```

   The request leaves zone-1 through the zone egress, enters zone-2 through the zone ingress, and hits the `demo-app` pod there.

   {:.info}
   > If the request times out, check that the minikube tunnels are still running.
   > Tunnels can become unresponsive after sleep/wake cycles; restart them with `minikube tunnel -p <profile> --bind-address=0.0.0.0`.

1. Confirm the traffic passed through the zone-2 zone ingress by reading its sidecar stats:

   ```sh
   kubectl --context mesh-zone-2 -n kong-mesh-system exec deploy/kong-mesh-default-ingress -c kuma-sidecar -- \
     wget -qO- 'localhost:9901/stats?filter=upstream_rq_total'
   ```

   `upstream_rq_total` for the `demo-app` cluster should be greater than zero.

## Next steps

<!--- Target individual zone proxy listeners from policies with `sectionName` - covered in a follow-up guide.-->
<!--- Read the [`MeshIdentity`](/mesh/mesh-identity/) guide to switch the bundled CA for a production issuer.-->
