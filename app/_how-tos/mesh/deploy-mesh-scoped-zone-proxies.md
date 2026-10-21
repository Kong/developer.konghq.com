---
title: 'Deploy mesh-scoped zone proxies'
description: 'Deploy {{site.mesh_product_name}} zone ingress and zone egress with per-mesh Helm values in two Kubernetes zones connected to a {{site.konnect_short_name}} global control plane. Each entry in `kuma.meshes[]` creates the Deployment, Service, and Dataplane listeners for one mesh.'
content_type: how_to
permalink: /mesh/zone-proxies/
breadcrumbs:
  - /mesh/
related_resources:
  - text: 'Mesh-scoped zone proxies reference'
    url: '/mesh/mesh-scoped-zone-proxies/'
  - text: 'MeshMultiZoneService'
    url: '/mesh/meshmultizoneservice/'
  - text: 'Connect a Kubernetes zone to {{site.konnect_short_name}} with the API'
    url: '/mesh/connect-kubernetes-zone-to-konnect-api/'

min_version:
  mesh: '3.0'

products:
  - mesh

works_on:
  - konnect

tools:
  - konnect-api
  - kongctl

tags:
  - service-mesh

series:
  id: mesh-scoped-zone-proxy
  position: 1
tldr:
  q: How do I deploy mesh-scoped zone ingress and zone egress with per-mesh Helm values?
  a: |
    1. Create a {{site.konnect_short_name}} global control plane, a `Mesh`, and a `MeshIdentity`.
    1. Connect each zone control plane, then add a `kuma.meshes[]` entry to its Helm values.
    1. {{site.mesh_product_name}} renders a per-mesh Deployment and Service for each role, generates the Dataplane listeners, and publishes the zone ingress address in a `MeshZoneAddress`.

faqs:
  - q: How do I list the per-mesh Deployments and Services?
    a: |
      Query `kong-mesh-system` filtered by mesh label:

      ```sh
      kubectl --context $ZONE1_PROFILE -n kong-mesh-system get deploy,svc -l kuma.io/mesh=konnect-demo
      ```

      You'll see a `kong-mesh-konnect-demo-ingress` and `kong-mesh-konnect-demo-egress` Deployment, each with a matching Service.
      A second mesh produces another pair named after its mesh.

  - q: How do I confirm the Services carry the zone-proxy-type label?
    a: |
      ```sh
      kubectl --context $ZONE1_PROFILE -n kong-mesh-system get svc \
        -l k8s.kuma.io/zone-proxy-type -L k8s.kuma.io/zone-proxy-type
      ```

  - q: How do I confirm the ingress Services are NodePort?
    a: |
      Run the following for each zone and note the published port.

      For zone-1:

      ```sh
      kubectl --context $ZONE1_PROFILE -n kong-mesh-system get svc kong-mesh-konnect-demo-ingress \
        -o jsonpath='{.spec.type}{"\t"}{.spec.ports[0].nodePort}{"\n"}'
      ```

      For zone-2:

      ```sh
      kubectl --context $ZONE2_PROFILE -n kong-mesh-system get svc kong-mesh-konnect-demo-ingress \
        -o jsonpath='{.spec.type}{"\t"}{.spec.ports[0].nodePort}{"\n"}'
      ```

  - q: How do I inspect the MeshZoneAddress resources?
    a: |
      On a Kubernetes zone, `MeshZoneAddress` resources live in `kong-mesh-system`, next to the ingress Service.
      Each zone sees its own resource and the ones synced from the other zones:

      ```sh
      kubectl --context $ZONE1_PROFILE -n kong-mesh-system get meshzoneaddresses \
        -o custom-columns='ZONE:.metadata.labels.kuma\.io/zone,ADDRESS:.spec.address,PORT:.spec.port'
      ```

      The addresses should use the shared Docker bridge IPs and the published ingress `NodePort` values.
      If a zone is missing, check the events on its ingress Service for a `NoPublicAddress` warning.

  - q: How do I view the zone proxy Dataplane resources?
    a: |
      Zone proxies are regular `Dataplane` resources in the zone's system namespace:

      ```sh
      kubectl --context $ZONE1_PROFILE -n kong-mesh-system get dataplanes
      ```

prereqs:
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: Docker, kubectl, and minikube
      content: |
        This guide requires [Docker](https://docs.docker.com/get-docker/), [`kubectl`](https://kubernetes.io/docs/tasks/tools/), and [minikube](https://minikube.sigs.k8s.io/docs/start/) with the Docker driver to run two local Kubernetes clusters, one for each zone.
    - title: Network access
      content: |
        Confirm the minikube nodes have outbound access on port 443 to your regional {{site.konnect_short_name}} KDS endpoint, `$KONNECT_REGION.mesh.sync.konghq.com`.

cleanup:
  inline:
    - title: Clean up the zones
      content: |
        Delete the zone-1 minikube profile:

        ```sh
        minikube delete -p guide-mz-zone-1
        ```

        Delete the zone-2 minikube profile:

        ```sh
        minikube delete -p guide-mz-zone-2
        ```

        Delete the shared Docker network:

        ```sh
        docker network rm guide-mz-net
        ```
    - title: Delete the {{site.konnect_short_name}} control plane
      content: |
        In {{site.konnect_short_name}}, delete the `example-cp` control plane created for this guide. Deleting the control plane also removes its mesh configuration. Revoke the zone tokens and delete the `mesh-zone-1` and `mesh-zone-2` system accounts. Review the files in `MESH_INSTALL_DIR` and remove the credentials when no longer needed.
---

Zone ingresses and zone egresses are mesh-scoped.
Declare them in your zone control plane values under `kuma.meshes[]`.
Each entry creates a Deployment, Service, and Dataplane for that mesh, and the zone proxies carry per-mesh workload identities so policies can target them directly.

This guide connects two Kubernetes zones to a {{site.konnect_short_name}}-managed global control plane, then deploys a zone ingress and zone egress in each zone through `kuma.meshes[]`.
It uses the minikube Docker driver and one shared Docker bridge so the two zones can reach each other's zone ingress directly through `NodePort` Services.

Set the region where you will create the global control plane:

```sh
export KONNECT_REGION='us'
```

## Create a global control plane in {{site.konnect_short_name}}

{% include md/mesh/how-tos/create-global-control-plane.md %}

## Check the global control plane version

{% include md/mesh/how-tos/check-control-plane-version.md %}

## Start the zone clusters

1. Export the profile names, the shared Docker network, and the static node IPs:

   ```sh
   export MZ_NETWORK=guide-mz-net
   export ZONE1_PROFILE=guide-mz-zone-1
   export ZONE2_PROFILE=guide-mz-zone-2
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

1. Start the zone-1 minikube cluster on the shared Docker bridge:

   ```sh
   minikube start -p $ZONE1_PROFILE --driver=docker --network=$MZ_NETWORK --static-ip=$ZONE1_IP
   ```

1. Start the zone-2 minikube cluster on the shared Docker bridge:

   ```sh
   minikube start -p $ZONE2_PROFILE --driver=docker --network=$MZ_NETWORK --static-ip=$ZONE2_IP
   ```

1. Point `kubectl` at zone-1. The following zone-1 steps use the current context:

   ```sh
   kubectl config use-context $ZONE1_PROFILE
   ```

## Connect zone-1

{% include md/mesh/how-tos/give-zone-credentials.md %}

{% include md/mesh/how-tos/deploy-zone-control-plane.md platform="kubernetes" zone_proxies=true %}

## Connect zone-2

Zone-2 gets its own system account and token, and its own values file with `zone: zone-2`.

1. Create the system account:

   ```sh
   export ZONE2_ACCOUNT_ID=$(curl --fail-with-body -sS -X POST https://global.api.konghq.com/v3/system-accounts \
     -H "Authorization: Bearer $KONNECT_TOKEN" \
     -H 'Content-Type: application/json' \
     -d '{"name":"mesh-zone-2","description":"Connect zone-2","konnect_managed":false}' | jq -r .id)
   ```

1. Assign the account the `Connector` role:

   ```sh
   curl --fail-with-body -sS -X POST \
     "https://global.api.konghq.com/v3/system-accounts/$ZONE2_ACCOUNT_ID/assigned-roles" \
     -H "Authorization: Bearer $KONNECT_TOKEN" \
     -H 'Content-Type: application/json' \
     -d '{"role_name":"Connector","entity_type_name":"Mesh Control Planes","entity_id":"'"$CONTROL_PLANE_ID"'","entity_region":"'"$KONNECT_REGION"'"}'
   ```

1. Create the account's token:

   ```sh
   export ZONE2_CONTROL_PLANE_TOKEN=$(curl --fail-with-body -sS -X POST \
     "https://global.api.konghq.com/v3/system-accounts/$ZONE2_ACCOUNT_ID/access-tokens" \
     -H "Authorization: Bearer $KONNECT_TOKEN" \
     -H 'Content-Type: application/json' \
     -d '{"name":"zone-2","expires_at":"'"$TOKEN_EXPIRES_AT"'"}' | jq -r .token)
   ```

1. Create the system namespace in zone-2:

   ```sh
   kubectl --context $ZONE2_PROFILE create namespace kong-mesh-system
   ```

1. Store the token in zone-2:

   ```sh
   kubectl --context $ZONE2_PROFILE -n kong-mesh-system create secret generic cp-token \
     --from-literal=token="$ZONE2_CONTROL_PLANE_TOKEN"
   ```

1. Create the values file for zone-2:

   ```sh
   cat <<EOF > zone-2-values.yaml
   kuma:
     controlPlane:
       mode: zone
       zone: zone-2
       kdsGlobalAddress: $CONTROL_PLANE_URL
       konnect:
         cpId: $CONTROL_PLANE_ID
       zoneToken:
         secretName: cp-token
         key: token
   EOF
   ```

1. Install the zone control plane in zone-2:

   ```sh
   helm upgrade --install kong-mesh kong-mesh/kong-mesh --kube-context $ZONE2_PROFILE \
     --namespace kong-mesh-system --version "$MESH_CHART_VERSION" \
     --values zone-2-values.yaml --wait --timeout 5m
   ```

## Verify the zone connections

{% include md/mesh/how-tos/verify-zone-connection.md %}

`zone-2` should also appear in the list with an **Online** status.

## Create a mesh and secure the test traffic

{% include md/mesh/how-tos/create-mesh-and-permission.md %}

The permission you just applied covers zone-1 only.
Apply the same permission in zone-2, where the `server` that the cross-zone request reaches runs:

```sh
cat <<'EOF' | kubectl --context $ZONE2_PROFILE apply -f -
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: client-to-server
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: konnect-demo
    kuma.io/origin: zone
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: server
  rules:
    - default:
        allow:
          - spiffeID:
              type: Exact
              value: spiffe://konnect-demo.mesh.local/ns/kong-mesh-demo/sa/client
EOF
```

## Deploy mesh-scoped zone proxies

A `kuma.meshes[]` entry defines which mesh the zone proxies belong to.
Each entry creates its own Deployment, Service, and ServiceAccount for the ingress and egress roles.
The mesh must already exist: the chart doesn't create it.

1. Create a values file that enables both roles for `konnect-demo`:

   ```sh
   cat <<EOF > zone-proxies-values.yaml
   kuma:
     meshes:
       - name: konnect-demo
         ingress:
           enabled: true
           service:
             type: NodePort
         egress:
           enabled: true
   EOF
   ```

   Set the ingress Service type to `NodePort` so the other minikube cluster can reach it on the shared Docker network.
   Kubernetes assigns the port automatically, and the zone control plane publishes the resulting `<node IP>:<nodePort>` address in a `MeshZoneAddress` for you.
   Other zones use that address to reach this zone's ingress.

   To deploy zone proxies for additional meshes, append more entries to `kuma.meshes`.

1. Add the zone proxies to both zone releases:

   ```sh
   for ctx in $ZONE1_PROFILE $ZONE2_PROFILE; do
     helm upgrade kong-mesh kong-mesh/kong-mesh --kube-context $ctx \
       --namespace kong-mesh-system --version "$MESH_CHART_VERSION" \
       --reuse-values --values zone-proxies-values.yaml
   done
   ```

1. Wait for the zone proxies to become available in both zones:

   ```sh
   for ctx in $ZONE1_PROFILE $ZONE2_PROFILE; do
     kubectl --context $ctx -n kong-mesh-system wait \
       --for=condition=available deployment -l kuma.io/mesh=konnect-demo --timeout=180s
   done
   ```

1. Confirm that each zone published a `MeshZoneAddress` and received the other zone's:

   ```sh
   kubectl --context $ZONE1_PROFILE -n kong-mesh-system get meshzoneaddresses \
     -o custom-columns='ZONE:.metadata.labels.kuma\.io/zone,ADDRESS:.spec.address,PORT:.spec.port'
   ```

   You should see one entry for `zone-1` at `${ZONE1_IP}` and one for `zone-2` at `${ZONE2_IP}`, each with its ingress `NodePort`.

## Propagate trust between zones

Each zone generates its own CA for the `MeshIdentity` and publishes it in a zone-local `MeshTrust`.
The two zones share the `konnect-demo.mesh.local` trust domain, but they don't share a CA, and a zone's `MeshTrust` isn't synced to the other zones.
For cross-zone mTLS to work, each zone must trust the other zone's CA.

1. Read each zone's trust domain and CA bundle:

   ```sh
   export TRUST_DOMAIN=$(kubectl --context $ZONE1_PROFILE -n kong-mesh-system get meshtrust \
     -l kuma.io/mesh=konnect-demo,kuma.io/origin=zone -o jsonpath='{.items[0].spec.trustDomain}')
   export ZONE1_CA=$(kubectl --context $ZONE1_PROFILE -n kong-mesh-system get meshtrust \
     -l kuma.io/mesh=konnect-demo,kuma.io/origin=zone -o jsonpath='{.items[0].spec.caBundles[0].pem.value}')
   export ZONE2_CA=$(kubectl --context $ZONE2_PROFILE -n kong-mesh-system get meshtrust \
     -l kuma.io/mesh=konnect-demo,kuma.io/origin=zone -o jsonpath='{.items[0].spec.caBundles[0].pem.value}')
   ```

   The `kuma.io/origin=zone` selector returns the trust that the zone itself created.
   Read both CAs before the next step: once you add the other zone's trust, the selector matches two resources.

1. Add zone-1's CA to zone-2:

   ```sh
   cat <<EOF | kubectl --context $ZONE2_PROFILE apply -f -
   apiVersion: kuma.io/v1alpha1
   kind: MeshTrust
   metadata:
     name: trust-from-zone-1
     namespace: kong-mesh-system
     labels:
       kuma.io/mesh: konnect-demo
   spec:
     trustDomain: $TRUST_DOMAIN
     caBundles:
       - type: Pem
         pem:
           value: |
   $(printf '%s\n' "$ZONE1_CA" | sed 's/^/          /')
   EOF
   ```

1. Add zone-2's CA to zone-1:

   ```sh
   cat <<EOF | kubectl --context $ZONE1_PROFILE apply -f -
   apiVersion: kuma.io/v1alpha1
   kind: MeshTrust
   metadata:
     name: trust-from-zone-2
     namespace: kong-mesh-system
     labels:
       kuma.io/mesh: konnect-demo
   spec:
     trustDomain: $TRUST_DOMAIN
     caBundles:
       - type: Pem
         pem:
           value: |
   $(printf '%s\n' "$ZONE2_CA" | sed 's/^/          /')
   EOF
   ```

   Proxies trust every CA listed for a trust domain, so each zone now accepts certificates issued in either zone.

## Deploy the test applications

Run the following commands once in zone-1, which is the current context.
Then switch with `kubectl config use-context $ZONE2_PROFILE` and run them again, so that both zones have a `client` and a `server`:

{% include md/mesh/how-tos/deploy-test-applications.md %}

The client's `kuma.io/reachable-backends` annotation selects the `server` `MeshService` by its `kuma.io/display-name` and `k8s.kuma.io/namespace` labels.
Those labels also match the `server` `MeshService` synced from the other zone, so the client gets an outbound for both.

## Verify cross-zone traffic

1. From the `client` pod in zone-1, request the `server` in zone-2 using its cross-zone hostname:

   ```sh
   kubectl --context $ZONE1_PROFILE -n kong-mesh-demo exec deployment/client -c client -- \
     curl --fail --max-time 10 http://server.kong-mesh-demo.svc.zone-2.mesh.local/
   ```

   Expect the nginx welcome page.
   The request goes from the zone-1 sidecar straight to the zone-2 zone ingress, at the address in zone-2's `MeshZoneAddress`.
   The ingress forwards it to the `server` pod there without terminating mTLS.
   Cross-zone requests don't go through the zone egress: the egress only carries traffic to a [`MeshExternalService`](/mesh/meshexternalservice/), and since this guide doesn't define one, it has no listener yet.

   {:.info}
   > If the request fails, check that zone-2 has a `MeshZoneAddress` with the expected `NodePort`, that both `MeshTrust` copies exist, and that the zone-2 `MeshTrafficPermission` is in place.
   > The control plane builds remote `MeshService` endpoints only when the mesh has a `MeshIdentity` and the destination zone has a `MeshZoneAddress`.
   > When the address is missing, the zone-1 control plane logs `no MeshZoneAddress found for zone`.

1. Confirm that the request went through the zone-2 ingress by reading its Envoy stats through the zone-2 control plane API.
   Envoy's admin API isn't reachable over TCP in the proxy container, so use the control plane's inspect endpoint instead.
   In a separate terminal, port-forward the zone-2 control plane API:

   ```sh
   kubectl --context $ZONE2_PROFILE -n kong-mesh-system port-forward svc/kong-mesh-control-plane 5681:5681
   ```

1. Look up the zone-2 ingress pod:

   ```sh
   export INGRESS_POD=$(kubectl --context $ZONE2_PROFILE -n kong-mesh-system get pod \
     -l app=kong-mesh-konnect-demo-ingress -o jsonpath='{.items[0].metadata.name}')
   ```

1. Read the ingress pod's connection count for the `server` cluster:

   ```sh
   curl -s "http://localhost:5681/meshes/konnect-demo/dataplanes/${INGRESS_POD}.kong-mesh-system/stats" | \
     grep 'kong-mesh-demo_server_80.upstream_cx_total'
   ```

   `upstream_cx_total` for the zone-2 `server` cluster on the ingress should be greater than zero.
   Run the cross-zone request again and the counter increases.
