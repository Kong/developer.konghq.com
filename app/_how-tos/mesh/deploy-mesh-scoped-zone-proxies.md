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
  mesh: '3.0'

products:
  - mesh

works_on:
  - on-prem

series:
  id: mesh-scoped-zone-proxy
  position: 1
tldr:
  q: How do I deploy mesh-scoped zone ingress and zone egress with per-mesh Helm values?
  a: |
    1. Create a `Mesh` and a `MeshIdentity` on the global control plane, which runs in Universal mode.
    1. Install each zone control plane with a `kuma.meshes[]` entry.
    1. {{site.mesh_product_name}} renders a per-mesh Deployment and Service for each role, and generates the Dataplane listeners automatically.

faqs:
  - q: How do I list the per-mesh Deployments and Services?
    a: |
      Query `kong-mesh-system` filtered by mesh label:

      ```sh
      kubectl --context $ZONE1_PROFILE -n kong-mesh-system get deploy,svc -l kuma.io/mesh=default
      ```

      You'll see a `kong-mesh-default-ingress` and `kong-mesh-default-egress` Deployment, each with a matching Service.
      A second mesh produces another pair named after its mesh.

  - q: How do I confirm the Services carry the zone-proxy-type label?
    a: |
      ```sh
      kubectl --context $ZONE1_PROFILE -n kong-mesh-system get svc \
        -l k8s.kuma.io/zone-proxy-type -L k8s.kuma.io/zone-proxy-type
      ```

  - q: How do I confirm the ingress Services are NodePort?
    a: |
      Run the following for each zone and note the published port:

      ```sh
      kubectl --context $ZONE1_PROFILE -n kong-mesh-system get svc kong-mesh-default-ingress \
        -o jsonpath='{.spec.type}{"\t"}{.spec.ports[0].nodePort}{"\n"}'
      kubectl --context $ZONE2_PROFILE -n kong-mesh-system get svc kong-mesh-default-ingress \
        -o jsonpath='{.spec.type}{"\t"}{.spec.ports[0].nodePort}{"\n"}'
      ```

  - q: How do I inspect the MeshZoneAddress resources?
    a: |
      Query the global control plane with [kongctl](/kongctl/):

      ```sh
      kongctl get mesh meshzoneaddresses --mesh default -o yaml
      ```

      Each entry's `spec.address` and `spec.port` should use the shared Docker bridge IPs and the published ingress `NodePort` values.

  - q: How do I view the zone proxy Dataplane resources?
    a: |
      ```sh
      kongctl get mesh dataplanes --mesh default
      ```

prereqs:
  skip_product: true
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: minikube
      content: |
        This series requires [minikube](https://minikube.sigs.k8s.io/docs/start/) with the Docker driver to run two local Kubernetes zone clusters.
    - title: kongctl
      content: |
        The global control plane runs in Universal mode, so you manage its resources with [kongctl](/kongctl/). You also need `docker`, and `jq` to decode the control plane's bootstrap admin token.

cleanup:
  inline:
    - title: Clean up {{site.mesh_product_name}} resources
      content: |
        Delete the two minikube profiles, the global control plane containers, and the shared Docker network:

        ```sh
        minikube delete -p guide-mz-zone-1
        minikube delete -p guide-mz-zone-2
        docker rm -f guide-mz-global guide-mz-postgres
        docker network rm guide-mz-net
        ```
---

Zone ingresses and zone egresses are mesh-scoped.
Declare them in your zone control plane values under `kuma.meshes[]`.
Each entry creates a Deployment, Service, and `Dataplane` for that mesh, and the zone proxies carry per-mesh workload identities so policies can target them directly.

This guide walks through a global control plane and two zone control planes, each deploying a zone ingress and zone egress through `kuma.meshes[]`.
The global control plane runs in Universal mode backed by Postgres, because a Kubernetes-native global control plane is not supported.
The two zone control planes run on Kubernetes, using the minikube Docker driver and one shared Docker bridge so every component can reach the others directly.

## Set up the shared network

1. Export the profile names, the shared Docker network, and the static IPs:

   ```sh
   export MZ_NETWORK=guide-mz-net
   export ZONE1_PROFILE=guide-mz-zone-1
   export ZONE2_PROFILE=guide-mz-zone-2
   export GLOBAL_IP=192.168.240.11
   export POSTGRES_IP=192.168.240.10
   export ZONE1_IP=192.168.240.21
   export ZONE2_IP=192.168.240.31
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

## Deploy the global control plane

The global control plane runs in Universal mode and stores its resources in Postgres.
Both run as containers on the shared bridge, so the zone clusters can reach the KDS port directly.

1. Start Postgres:

   ```sh
   docker run --detach --name guide-mz-postgres --hostname postgres \
     --network $MZ_NETWORK --ip $POSTGRES_IP \
     --env POSTGRES_USER=kong \
     --env POSTGRES_PASSWORD=pass123 \
     --env POSTGRES_DB=global \
     postgres:16
   ```

1. Run the schema migration:

   ```sh
   docker run --rm --network $MZ_NETWORK \
     --env KUMA_STORE_TYPE=postgres \
     --env KUMA_STORE_POSTGRES_HOST=postgres \
     --env KUMA_STORE_POSTGRES_PORT=5432 \
     --env KUMA_STORE_POSTGRES_USER=kong \
     --env KUMA_STORE_POSTGRES_PASSWORD=pass123 \
     --env KUMA_STORE_POSTGRES_DB_NAME=global \
     kong/kuma-cp:{{page.latest_release.version}} migrate up
   ```

1. Start the global control plane:

   ```sh
   docker run --detach --name guide-mz-global --hostname global-control-plane \
     --network $MZ_NETWORK --ip $GLOBAL_IP \
     --publish 5681:5681 --publish 5685:5685 \
     --env KUMA_MODE=global \
     --env KUMA_ENVIRONMENT=universal \
     --env KUMA_DEFAULTS_SKIP_MESH_CREATION=true \
     --env KUMA_STORE_TYPE=postgres \
     --env KUMA_STORE_POSTGRES_HOST=postgres \
     --env KUMA_STORE_POSTGRES_PORT=5432 \
     --env KUMA_STORE_POSTGRES_USER=kong \
     --env KUMA_STORE_POSTGRES_PASSWORD=pass123 \
     --env KUMA_STORE_POSTGRES_DB_NAME=global \
     kong/kuma-cp:{{page.latest_release.version}} run
   ```

   Port `5681` serves the HTTP API and the GUI, and port `5685` serves KDS.
   We're skipping default mesh creation because we'll apply a custom `Mesh` in the next step.

1. Point `kongctl` at the global control plane:

   ```sh
   export MZ_ADMIN_TOKEN="$(docker exec guide-mz-global \
     wget --quiet --output-document - http://127.0.0.1:5681/global-secrets/admin-user-token \
     | jq --raw-output .data | base64 --decode)"

   export KONGCTL_DEFAULT_KONNECT_MESH_CONTROL_PLANE_URL=http://127.0.0.1:5681
   export KONGCTL_DEFAULT_KONNECT_MESH_CONTROL_PLANE_TOKEN="$MZ_ADMIN_TOKEN"
   ```

   Every `kongctl` command in this guide reads those two variables, so you don't have to repeat `--control-plane-url` and `--control-plane-token` each time.

   If the token endpoint returns nothing, the control plane is still starting. Wait a few seconds and retry.

1. Export the KDS address that the zone control planes will connect to:

   ```sh
   export KDS_ADDRESS=grpcs://${GLOBAL_IP}:5685
   ```

   The global control plane is now reachable at `${GLOBAL_IP}:5685` from both minikube clusters on the shared bridge.

## Create the mesh on the global control plane

Because the global control plane runs in Universal mode, its resources use the Universal format (`type`, `name`, `mesh`, `spec`) rather than Kubernetes manifests.

1. Create the mesh and allow all traffic:

   ```sh
   echo 'type: Mesh
   name: default
   ---
   type: MeshTrafficPermission
   name: allow-all
   mesh: default
   spec:
     targetRef:
       kind: Mesh
     rules:
       - default:
           allow:
             - spiffeID:
                 type: Prefix
                 value: "spiffe://default."' | kongctl apply mesh -f -
   ```

   This rule allows traffic from any workload identity whose SPIFFE trust domain starts with `default.`.
   That includes the mesh-scoped zone proxies and the demo workloads in both zones.

## Create a MeshIdentity

Zone egress listeners need a workload identity to terminate mTLS for cross-zone traffic.
Apply a `MeshIdentity` on the global control plane:

```sh
echo 'type: MeshIdentity
name: identity
mesh: default
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
        enabled: true' | kongctl apply mesh -f -
```

The resource will sync to every zone automatically.

{:.info}
> `insecureAllowSelfSigned: true` keeps the demo simple by using the bundled CA.
> For production, follow the [`MeshIdentity` guide](/mesh/issue-identity-with-meshidentity-spire/) to integrate a SPIRE trust domain or an external CA.

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

A `MeshTrust` spec holds only a `trustDomain` and a list of `caBundles`, so read those two fields from the zone and build a fresh resource on the global control plane. Select the source by the `kuma.io/origin: zone` label, which is the trust the local zone created. Resources synced back from the global control plane carry `kuma.io/origin: global`, and publishing one of those would send the wrong zone's CA.

1. Export zone-1's trust bundle and apply it to the global CP:

   ```sh
   kongctl apply mesh -f - <<EOF
   type: MeshTrust
   name: trust-of-zone-1
   mesh: default
   labels:
     kuma.io/origin: global
   spec:
     trustDomain: $(kubectl --context $ZONE1_PROFILE -n kong-mesh-system get meshtrust -l kuma.io/origin=zone,kuma.io/mesh=default -o jsonpath='{.items[0].spec.trustDomain}')
     caBundles: $(kubectl --context $ZONE1_PROFILE -n kong-mesh-system get meshtrust -l kuma.io/origin=zone,kuma.io/mesh=default -o jsonpath='{.items[0].spec.caBundles}')
   EOF
   ```

   The `caBundles` value is emitted as JSON, which is valid YAML flow syntax, so it drops straight into the document.

1. Export zone-2's trust bundle and apply it to the global CP:

   ```sh
   kongctl apply mesh -f - <<EOF
   type: MeshTrust
   name: trust-of-zone-2
   mesh: default
   labels:
     kuma.io/origin: global
   spec:
     trustDomain: $(kubectl --context $ZONE2_PROFILE -n kong-mesh-system get meshtrust -l kuma.io/origin=zone,kuma.io/mesh=default -o jsonpath='{.items[0].spec.trustDomain}')
     caBundles: $(kubectl --context $ZONE2_PROFILE -n kong-mesh-system get meshtrust -l kuma.io/origin=zone,kuma.io/mesh=default -o jsonpath='{.items[0].spec.caBundles}')
   EOF
   ```

The global control plane syncs these trust bundles to all zones, enabling cross-zone certificate validation.

## Verify cross-zone traffic

1. Create the demo app configuration:

   {% capture demo %}{% include /md/mesh/v3/demo.md %}{% endcapture %}{{demo | indent}}

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

1. Find the name of the zone-2 ingress proxy. The global control plane sees every proxy in both zones:

   ```sh
   kongctl get mesh dataplanes --mesh default
   ```

   The zone ingress is the entry named after the `kong-mesh-default-ingress` Deployment, carrying the `kuma.io/zone: zone-2` tag.

1. Read that proxy's Envoy request counters, using the name from the previous step:

   ```sh
   kongctl get mesh inspect dataplane <zone-2-ingress-name> --mesh default --type stats | grep upstream_rq_total
   ```

   The counter for the zone-2 `demo-app` cluster should be greater than zero, which confirms the cross-zone request arrived through the ingress rather than being served locally.
   The follow-up guide shows how to inspect zone-egress-specific traffic on top of this setup.
