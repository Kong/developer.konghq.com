---
title: 'Deploy mesh-scoped zone proxies'
description: 'Deploy {{site.mesh_product_name}} zone ingress and zone egress with per-mesh Helm values. Each entry in `kuma.meshes[]` creates the Deployment, Service, and Dataplane listeners for one mesh.'
content_type: how_to
permalink: /mesh/zone-proxies/
breadcrumbs:
  - /mesh/
related_resources:
  - text: 'Multi-zone deployment'
    url: '/mesh/mesh-multizone-service-deployment/'

min_version:
  mesh: '2.14'

products:
  - mesh

series:
  id: mesh-scoped-zone-proxy
  position: 1

tldr:
  q: How do I deploy mesh-scoped zone ingress and zone egress with per-mesh Helm values?
  a: |
    1. Create a `Mesh` with `spec.meshServices.mode: Exclusive` and a `MeshIdentity` on the global control plane.
    1. Install each zone control plane with a `kuma.meshes[]` entry.
    1. {{site.mesh_product_name}} renders a per-mesh Deployment and Service for each role, and generates the Dataplane listeners automatically.

prereqs:
  skip_product: true
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: minikube
      content: |
        This series requires [minikube](https://minikube.sigs.k8s.io/docs/start/) with the Docker driver to run three local Kubernetes clusters (one global and two zones).

cleanup:
  inline:
    - title: Clean up {{site.mesh_product_name}} resources
      content: |
        Delete the three minikube profiles and the shared Docker network:

        ```sh
        minikube delete -p guide-mz-global
        minikube delete -p guide-mz-zone-1
        minikube delete -p guide-mz-zone-2
        docker network rm guide-mz-net
        ```
---

Starting in {{site.mesh_product_name}} 2.14, zone ingresses and zone egresses are mesh-scoped.
Declare them in your zone control plane values under `kuma.meshes[]`.
Each entry creates a Deployment, Service, and Dataplane for that mesh, and the zone proxies carry per-mesh workload identities so policies can target them directly.

This guide walks through a three-cluster setup: a global control plane and two zone control planes, each deploying a zone ingress and zone egress through `kuma.meshes[]`.
It uses the minikube Docker driver and one shared Docker bridge so the three clusters can reach each other directly through `NodePort` Services.

## Start the global control plane cluster

1. Export the profile names, the shared Docker network, the static node IPs, and the fixed KDS `NodePort`:

   ```sh
   export MZ_NETWORK=guide-mz-net
   export GLOBAL_PROFILE=guide-mz-global
   export ZONE1_PROFILE=guide-mz-zone-1
   export ZONE2_PROFILE=guide-mz-zone-2
   export GLOBAL_IP=192.168.240.11
   export ZONE1_IP=192.168.240.21
   export ZONE2_IP=192.168.240.31
   export KDS_NODEPORT=30685
   ```

1. Create the shared Docker bridge:

   ```sh
   docker network inspect $MZ_NETWORK >/dev/null 2>&1 || \
     docker network create --driver bridge --subnet 192.168.240.0/24 $MZ_NETWORK
   ```

   {:.info}
   > If Docker Desktop fails with `failed complete: too many open files` while starting a profile, run:
   >
   > ```sh
   > docker run --rm --privileged alpine \
   >   sysctl -w fs.inotify.max_user_instances=8192 fs.inotify.max_user_watches=524288
   > ```
   >
   > Then restart the affected profile.

1. Create a new minikube cluster for the global control plane:

   ```sh
   minikube start -p $GLOBAL_PROFILE --driver=docker --network=$MZ_NETWORK --static-ip=$GLOBAL_IP
   ```

## Deploy the global control plane

1. Install the global control plane:

   ```sh
   helm repo add kong-mesh https://kong.github.io/kong-mesh-charts
   helm repo update
   helm install --kube-context $GLOBAL_PROFILE --create-namespace --namespace kong-mesh-system \
     --set kuma.controlPlane.mode=global \
     --set kuma.controlPlane.defaults.skipMeshCreation=true \
     --set kuma.controlPlane.globalZoneSyncService.type=NodePort \
     --set kuma.controlPlane.globalZoneSyncService.nodePort=$KDS_NODEPORT \
     kong-mesh kong-mesh/kong-mesh
   ```

   We're skipping default mesh creation because we'll apply a custom `Mesh` in the next step.

1. Wait for the control plane to become ready:

   ```sh
   kubectl --context $GLOBAL_PROFILE -n kong-mesh-system wait \
     --for=condition=ready pod --selector=app=kong-mesh-control-plane --timeout=120s
   ```

1. Export the KDS address that the zone control planes will connect to:

   ```sh
   export KDS_ADDRESS=grpcs://${GLOBAL_IP}:${KDS_NODEPORT}
   ```

   The global control plane is now reachable at `${GLOBAL_IP}:${KDS_NODEPORT}` from the other two minikube clusters.

## Create the mesh on the global control plane

Zone proxy listeners are only generated when the mesh uses the `MeshService` exclusive mode.
Without this, the zone proxies install but produce no listeners.

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
     rules:
       - default:
           allow:
             - spiffeID:
                 type: Prefix
                 value: "spiffe://default."' | kubectl --context $GLOBAL_PROFILE apply -f -
   ```

   This rule allows traffic from any workload identity whose SPIFFE trust domain starts with `default.`.
   That includes the mesh-scoped zone proxies and the demo workloads in both zones.

## Create a MeshIdentity

Zone egress listeners need a workload identity to terminate mTLS for cross-zone traffic.
Apply a `MeshIdentity` on the global control plane:

```sh
echo 'apiVersion: kuma.io/v1alpha1
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
    trustDomain: "{% raw %}{{ .Mesh }}.{{ .Zone }}.mesh.local{% endraw %}"
  provider:
    type: Bundled
    bundled:
      meshTrustCreation: Enabled
      insecureAllowSelfSigned: true
      certificateParameters:
        expiry: 24h
      autogenerate:
        enabled: true' | kubectl --context $GLOBAL_PROFILE apply -f -
```

The resource will sync to every zone automatically.

{:.info}
> `insecureAllowSelfSigned: true` keeps the demo simple by using the bundled CA.
> For production, follow the [`MeshIdentity` guide](/mesh/mesh-identity/) to integrate a SPIRE trust domain or an external CA.

## Deploy zone-1 with mesh-scoped zone proxies

A `kuma.meshes[]` entry defines which mesh the zone proxies belong to.
Each entry creates its own Deployment, Service, and ServiceAccount for the ingress and egress roles.

1. Start the zone-1 cluster on the shared Docker bridge:

   ```sh
   minikube start -p $ZONE1_PROFILE --driver=docker --network=$MZ_NETWORK --static-ip=$ZONE1_IP
   ```

1. Create the values file for zone-1:

   ```sh
   cat <<EOF > zone-1-values.yaml
   kuma:
     controlPlane:
       mode: zone
       zone: zone-1
       kdsGlobalAddress: ${KDS_ADDRESS}
       tls:
         kdsZoneClient:
           skipVerify: true
     meshes:
       - name: default
         ingress:
           enabled: true
           service:
             type: NodePort
         egress:
           enabled: true
   EOF
   ```

   Set the ingress Service type to `NodePort` so the other minikube clusters can reach it on the shared Docker network.
   Kubernetes assigns the port automatically, and `MeshZoneAddress` advertises the resulting `${ZONE1_IP}:<nodePort>` address for you.

   To deploy zone proxies for additional meshes, append more entries to `kuma.meshes`.

1. Install the zone control plane together with the zone ingress and egress for `default`:

   ```sh
   helm install --kube-context $ZONE1_PROFILE --create-namespace --namespace kong-mesh-system \
     -f zone-1-values.yaml \
     kong-mesh kong-mesh/kong-mesh
   ```

## Deploy zone-2

1. Start the zone-2 cluster on the shared Docker bridge:

   ```sh
   minikube start -p $ZONE2_PROFILE --driver=docker --network=$MZ_NETWORK --static-ip=$ZONE2_IP
   ```

1. Create the values file for zone-2:

   ```sh
   cat <<EOF > zone-2-values.yaml
   kuma:
     controlPlane:
       mode: zone
       zone: zone-2
       kdsGlobalAddress: ${KDS_ADDRESS}
       tls:
         kdsZoneClient:
           skipVerify: true
     meshes:
       - name: default
         ingress:
           enabled: true
           service:
             type: NodePort
         egress:
           enabled: true
   EOF
   ```

   Zone-2 follows the same pattern.
   Kubernetes allocates the ingress `NodePort`, and `MeshZoneAddress` publishes the resulting `${ZONE2_IP}:<nodePort>` endpoint.

1. Install the zone control plane and its zone proxies:

   ```sh
   helm install --kube-context $ZONE2_PROFILE --create-namespace --namespace kong-mesh-system \
     -f zone-2-values.yaml \
     kong-mesh kong-mesh/kong-mesh
   ```

## Propagate trust between zones

Each zone generates a `MeshTrust` containing its local CA bundle.
The `MeshIdentity` controller appends a content hash to the trust name (for example, `identity-xf4d5dz5c4w47645`), so you should look it up by label rather than hardcoding the name.
For cross-zone mTLS to work, each zone must trust the other zone's CA.
Publish each zone's trust bundle to the global control plane so it syncs everywhere.

1. Export zone-1's trust bundle and apply it to the global CP:

   ```sh
   kubectl --context $ZONE1_PROFILE -n kong-mesh-system get meshtrust -o json | \
     jq '.items[] | select(.metadata.labels["kuma.io/origin"] == "zone") |
         .metadata.name = "trust-of-zone-1" |
         .metadata.labels["kuma.io/origin"] = "global" |
         del(.metadata.resourceVersion, .metadata.uid, .metadata.creationTimestamp, .metadata.generation, .metadata.ownerReferences)' | \
     kubectl --context $GLOBAL_PROFILE apply -f -
   ```

   The `jq` filter selects only resources where `kuma.io/origin: zone`, which is the trust the local zone created.
   Resources synced back from the global control plane carry `kuma.io/origin: global` and must be excluded, otherwise you would publish the wrong zone's CA.

1. Export zone-2's trust bundle and apply it to the global CP:

   ```sh
   kubectl --context $ZONE2_PROFILE -n kong-mesh-system get meshtrust -o json | \
     jq '.items[] | select(.metadata.labels["kuma.io/origin"] == "zone") |
         .metadata.name = "trust-of-zone-2" |
         .metadata.labels["kuma.io/origin"] = "global" |
         del(.metadata.resourceVersion, .metadata.uid, .metadata.creationTimestamp, .metadata.generation, .metadata.ownerReferences)' | \
     kubectl --context $GLOBAL_PROFILE apply -f -
   ```

The global control plane syncs these trust bundles to all zones, enabling cross-zone certificate validation.

## Inspect the zone proxy resources

1. List the per-mesh Deployments and Services in zone-1:

   ```sh
   kubectl --context $ZONE1_PROFILE -n kong-mesh-system get deploy,svc -l kuma.io/mesh=default
   ```

   You'll see a `kong-mesh-default-ingress` and `kong-mesh-default-egress` Deployment, each with a matching Service.
   A second mesh would produce another pair named after its mesh.

1. Confirm the Services carry the `k8s.kuma.io/zone-proxy-type` label:

   ```sh
   kubectl --context $ZONE1_PROFILE -n kong-mesh-system get svc \
     -l k8s.kuma.io/zone-proxy-type -L k8s.kuma.io/zone-proxy-type
   ```

1. Confirm that the zone-1 ingress Service is a `NodePort` and note the published port:

   ```sh
   kubectl --context $ZONE1_PROFILE -n kong-mesh-system get svc kong-mesh-default-ingress \
     -o jsonpath='{.spec.type}{"\t"}{.spec.ports[0].nodePort}{"\n"}'
   ```

1. Confirm that the zone-2 ingress Service is a `NodePort` and note the published port:

   ```sh
   kubectl --context $ZONE2_PROFILE -n kong-mesh-system get svc kong-mesh-default-ingress \
     -o jsonpath='{.spec.type}{"\t"}{.spec.ports[0].nodePort}{"\n"}'
   ```

1. Inspect the `MeshZoneAddress` resources on the global control plane.
   They are namespaced resources, so query `kong-mesh-system` explicitly:

   ```sh
   kubectl --context $GLOBAL_PROFILE -n kong-mesh-system get meshzoneaddress -o json | \
     jq -r '.items[] |
       [
         .metadata.labels["kuma.io/zone"],
         .metadata.name,
         (.spec.address + ":" + (.spec.port | tostring))
       ] | @tsv'
   ```

   These addresses should use the shared Docker bridge IPs and the published ingress `NodePort` values.

1. From the global control plane, look at the zone proxy `Dataplane` resources:

   ```sh
   kubectl --context $GLOBAL_PROFILE get dataplane -A
   ```

## Verify cross-zone traffic

1. Create the demo app configuration:

   {% capture demo %}{% include /mesh/demo.md %}{% endcapture %}{{demo | indent}}

1. Deploy the {{site.mesh_product_name}} demo app into each zone:

   ```sh
   for ctx in $ZONE1_PROFILE $ZONE2_PROFILE; do
     kubectl --context $ctx apply -f demo.yaml
   done
   ```

1. Wait for the demo app to become ready in both zones:

   ```sh
   for ctx in $ZONE1_PROFILE $ZONE2_PROFILE; do
     kubectl --context $ctx -n kong-mesh-demo wait \
       --for=condition=available deployment --all --timeout=120s
   done
   ```

1. From a `demo-app` pod in zone-1, request the `demo-app` Service in zone-2 using its cross-zone hostname:

   ```sh
   kubectl --context $ZONE1_PROFILE -n kong-mesh-demo exec deploy/demo-app -c demo-app -- \
     wget -qO /dev/null http://demo-app.kong-mesh-demo.svc.zone-2.mesh.local:5000/
   ```

   The request leaves zone-1 through the zone egress, enters zone-2 through the zone ingress, and hits the `demo-app` pod there.

   {:.info}
   > If the request times out, re-check the `MeshZoneAddress` output and confirm the ingress Services still publish the expected `NodePort` values.

1. Reset the stats counters on the zone-2 ingress:

   ```sh
   kubectl --context $ZONE2_PROFILE -n kong-mesh-system \
     exec deploy/kong-mesh-default-ingress -c kuma-sidecar -- \
     wget -qO- --post-data='' 'http://127.0.0.1:9902/reset_counters'
   ```

1. Send the cross-zone request again:

   ```sh
   kubectl --context $ZONE1_PROFILE -n kong-mesh-demo exec deploy/demo-app -c demo-app -- \
     wget -qO /dev/null http://demo-app.kong-mesh-demo.svc.zone-2.mesh.local:5000/
   ```

1. Inspect the ingress Envoy cluster stats:

   ```sh
   kubectl --context $ZONE2_PROFILE -n kong-mesh-system \
     exec deploy/kong-mesh-default-ingress -c kuma-sidecar -- \
     wget -qO- 'http://127.0.0.1:9902/stats?format=json&filter=demo-app' | \
     jq '.stats[] | select(.name | strings | test("upstream_rq_total"))'
   ```

   `upstream_rq_total` for the zone-2 `demo-app` ingress cluster should be greater than zero.
   The follow-up guide shows how to inspect zone-egress-specific traffic on top of this setup.
