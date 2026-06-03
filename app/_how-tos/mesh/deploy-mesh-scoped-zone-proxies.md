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
  - text: 'Apply policies to mesh-scoped zone proxies'
    url: '/mesh/zone-proxy-policies/'

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
        You will need [minikube](https://minikube.sigs.k8s.io/docs/start/) with the Docker driver to run three local Kubernetes clusters (one global and two zones).

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

Starting in {{site.mesh_product_name}} 2.14, zone ingress and zone egress are **mesh-scoped**.
Instead of the cluster-scoped `kuma.ingress.enabled` / `kuma.egress.enabled` Helm keys, you declare a `kuma.meshes[]` list in your zone control plane's values.
Each entry renders its own Deployment, Service, and Dataplane for that mesh, and zone proxies now carry per-mesh workload identity so policies can target them directly.

This guide walks through a fresh three-cluster setup: a global control plane and two zone control planes, each deploying a zone ingress and zone egress through the new `kuma.meshes[]` configuration.
It uses the minikube Docker driver and one shared Docker bridge so the three clusters can reach each other directly through `NodePort` Services.
That removes the need for `minikube tunnel`, `host.minikube.internal`, and `externalIPs` workarounds.

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

1. Create the shared Docker bridge if it does not already exist:

   ```sh
   docker network inspect $MZ_NETWORK >/dev/null 2>&1 || \
     docker network create --driver bridge --subnet 192.168.240.0/24 $MZ_NETWORK
   ```

{:.info}
> On Docker Desktop, a third Docker-driver minikube profile can leave `kube-proxy` crashlooping with `failed complete: too many open files`.
> If that happens, raise the shared Linux VM's inotify limits once, then restart the affected profile:
>
> ```sh
> docker run --rm --privileged alpine \
>   sysctl -w fs.inotify.max_user_instances=8192 fs.inotify.max_user_watches=524288
> ```

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

   We skip default mesh creation because we will apply a custom `Mesh` in the next step.
   `NodePort` makes the zone sync endpoint reachable on the shared Docker bridge without a tunnel.

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
     rules:
       - default:
           allow:
             - spiffeID:
                 type: Prefix
                 value: "spiffe://default."' | kubectl --context $GLOBAL_PROFILE apply -f -
   ```

   This rule allows any workload identity whose SPIFFE trust domain starts with `default.`.
   That includes the mesh-scoped zone proxies and the demo workloads in both zones.

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
        enabled: true' | kubectl --context $GLOBAL_PROFILE apply -f -{% endraw %}
```

{:.info}
> `insecureAllowSelfSigned: true` keeps the demo simple by using the bundled CA.
> For production, follow the [`MeshIdentity` guide](/mesh/mesh-identity/) to integrate a SPIRE trust domain or an external CA.

## Deploy zone-1 with mesh-scoped zone proxies

A `kuma.meshes[]` entry tells the chart which mesh the zone proxies belong to.
Each entry renders its own Deployment, Service, and ServiceAccount for the ingress and egress roles.

1. Start the zone-1 cluster on the shared Docker bridge:

   ```sh
   minikube start -p $ZONE1_PROFILE --driver=docker --network=$MZ_NETWORK --static-ip=$ZONE1_IP
   ```

1. Save the following as `zone-1-values.yaml`:

   ```yaml
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
   ```

   `service.spec` is still available for additional `Service` fields such as `externalIPs` or `loadBalancerSourceRanges`,
   but the chart does not expose a dedicated per-mesh `nodePort` override.
   When the Service type is `NodePort`, Kubernetes assigns the port automatically and the `meshzoneaddress` controller advertises the resulting `${ZONE1_IP}:<nodePort>` address for you.
   You no longer need `externalIPs` or a host-level tunnel.

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

1. Save the following as `zone-2-values.yaml`:

   ```yaml
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
The `MeshIdentity` controller appends a content hash to the trust name (for example, `identity-xf4d5dz5c4w47645`), so look it up by label rather than hardcoding the name.
For cross-zone mTLS to work, each zone must trust the other zone's CA.
Republish each zone's trust bundle to the global control plane so it syncs everywhere.

The `jq` filter selects only resources where `kuma.io/origin: zone`, which is the trust the local zone created.
Resources synced back from the global control plane carry `kuma.io/origin: global` and must be excluded - otherwise you'd republish the wrong zone's CA.

1. Export zone-1's trust bundle and apply it to the global CP:

   ```sh
  kubectl --context $ZONE1_PROFILE -n kong-mesh-system get meshtrust -o json | \
     jq '.items[] | select(.metadata.labels["kuma.io/origin"] == "zone") |
         .metadata.name = "trust-of-zone-1" |
         .metadata.labels["kuma.io/origin"] = "global" |
         del(.metadata.resourceVersion, .metadata.uid, .metadata.creationTimestamp, .metadata.generation, .metadata.ownerReferences)' | \
    kubectl --context $GLOBAL_PROFILE apply -f -
   ```

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

## Inspect what the chart produced

1. List the per-mesh Deployments and Services in zone-1:

   ```sh
  kubectl --context $ZONE1_PROFILE -n kong-mesh-system get deploy,svc -l kuma.io/mesh=default
   ```

   You'll see a `kong-mesh-default-ingress` and `kong-mesh-default-egress` Deployment, each with a matching Service.
   A second mesh would produce another pair named after its mesh.

1. Confirm the Services carry the new `k8s.kuma.io/zone-proxy-type` label.
   The Pod controller watches this label and generates the Dataplane listeners from it:

   ```sh
  kubectl --context $ZONE1_PROFILE -n kong-mesh-system get svc \
     -l k8s.kuma.io/zone-proxy-type -L k8s.kuma.io/zone-proxy-type
   ```

1. Confirm that each ingress Service is a `NodePort` and note the published port:

  ```sh
  kubectl --context $ZONE1_PROFILE -n kong-mesh-system get svc kong-mesh-default-ingress \
    -o jsonpath='{.spec.type}{"\t"}{.spec.ports[0].nodePort}{"\n"}'

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

  These addresses should match the shared Docker bridge you created earlier, not `127.0.0.1`.

1. From the global control plane, look at the Dataplanes.
  Zone proxies are now ordinary `Dataplane` resources with `networking.listeners[]` entries instead of separate `ZoneIngress` or `ZoneEgress` resources:

  ```sh
  kubectl --context $GLOBAL_PROFILE get dataplane -A
  ```

1. Confirm that no legacy zone proxy resources exist.
  Both lists should be empty:

  ```sh
  kubectl --context $GLOBAL_PROFILE get zoneingresses,zoneegresses -A
  ```
  {:.no-copy-code}

## Verify cross-zone traffic

1. Deploy the {{site.mesh_product_name}} demo app into each zone:

  ```sh
  for ctx in $ZONE1_PROFILE $ZONE2_PROFILE; do
    kubectl --context $ctx create namespace kuma-demo \
      --dry-run=client -o yaml | kubectl --context $ctx apply -f -
    kubectl --context $ctx label namespace kuma-demo \
      kuma.io/sidecar-injection=enabled --overwrite
    kubectl --context $ctx apply -f https://raw.githubusercontent.com/kumahq/kuma-counter-demo/refs/heads/master/demo.yaml
  done
  ```

1. From a `demo-app` pod in zone-1, request the `demo-app` Service in zone-2 using its cross-zone hostname.
   The `demo-app` image ships with `wget` but not `curl`:

   ```sh
  kubectl --context $ZONE1_PROFILE -n kuma-demo exec deploy/demo-app -c demo-app -- \
     wget -qO- http://demo-app.kuma-demo.svc.zone-2.mesh.local:5000/
   ```

   The request leaves zone-1 through the zone egress, enters zone-2 through the zone ingress, and hits the `demo-app` pod there.

   {:.info}
  > If the request times out, re-check the `MeshZoneAddress` output and confirm the ingress Services still publish the expected `NodePort` values.

1. Port-forward the zone-2 ingress to the local machine:

  ```sh
  kubectl --context $ZONE2_PROFILE -n kong-mesh-system \
    port-forward deploy/kong-mesh-default-ingress 9903:9902
  ```

1. Reset the counters, send the cross-zone request again, and inspect the ingress Envoy cluster stats:

  ```sh
  curl -s -X POST http://127.0.0.1:9903/reset_counters

  kubectl --context $ZONE1_PROFILE -n kuma-demo exec deploy/demo-app -c demo-app -- \
    wget -qO- http://demo-app.kuma-demo.svc.zone-2.mesh.local:5000/ >/dev/null

  curl -s 'http://127.0.0.1:9903/stats?format=json&filter=demo-app' | \
    jq '.stats[] | select(.name | test("upstream_rq_total"))'
  ```

  `upstream_rq_total` for the zone-2 `demo-app` ingress cluster should be greater than zero.
  The follow-up guide shows how to inspect zone-egress-specific traffic on top of this setup.

  {:.info}
  > On Kubernetes, port `9902` is the readiness reporter proxy for the Envoy admin API.
  > It forwards `/stats`, `/config_dump`, and `/reset_counters` to the underlying admin socket.

## Next steps

Follow [Apply policies to mesh-scoped zone proxies](/mesh/zone-proxy-policies/) to add `MeshTrafficPermission`, `MeshMetric`, and `MeshAccessLog` on top of this three-cluster setup.
<!--- Read the [`MeshIdentity`](/mesh/mesh-identity/) guide to switch the bundled CA for a production issuer.-->
