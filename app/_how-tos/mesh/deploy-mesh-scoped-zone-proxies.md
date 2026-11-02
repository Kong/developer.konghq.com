---
title: 'Deploy mesh-scoped zone proxies'
description: 'Deploy {{site.mesh_product_name}} zone ingress and zone egress with per-mesh Helm values in two Kubernetes zones connected to a {{site.konnect_short_name}} global control plane.'
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

  - q: "What do I do if Docker Desktop fails with `failed complete: too many open files` while starting a minikube profile?"
    a: |
      Raise the inotify limits in the Docker Desktop VM:

      ```sh
      docker run --rm --privileged alpine \
        sysctl -w fs.inotify.max_user_instances=8192 fs.inotify.max_user_watches=524288
      ```

      Then restart the affected profile.

prereqs:
  inline:
    - title: Helm
      include_content: prereqs/helm

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

        Leave the zone working directory and delete it:

        ```sh
        cd "$(dirname "$MESH_INSTALL_DIR")"
        rm -rf "$MESH_INSTALL_DIR"
        ```
    - title: Delete the control plane
      include_content: cleanup/products/mesh/v3/control-plane-api
    - title: Delete the zone-1 system account
      include_content: cleanup/products/mesh/v3/system-account-api
    - title: Delete the zone-2 system account
      content: |
        Delete the `mesh-zone-2` system account:

        ```sh
        curl --fail-with-body -sS -X DELETE \
          "https://global.api.konghq.com/v3/system-accounts/$ZONE2_ACCOUNT_ID" \
          -H "Authorization: Bearer $KONNECT_TOKEN"
        ```
---

This guide connects two Kubernetes zones to a {{site.konnect_short_name}}-managed global control plane, then deploys a zone ingress and zone egress in each zone through `kuma.meshes[]`.

## Create a global control plane in {{site.konnect_short_name}}

{% include md/mesh/v3/how-tos/create-global-control-plane.md %}

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

1. Start the zone-1 minikube cluster on the shared Docker bridge:

   ```sh
   minikube start -p $ZONE1_PROFILE --driver=docker --network=$MZ_NETWORK --static-ip=$ZONE1_IP
   ```

1. Start the zone-2 minikube cluster on the shared Docker bridge:

   ```sh
   minikube start -p $ZONE2_PROFILE --driver=docker --network=$MZ_NETWORK --static-ip=$ZONE2_IP
   ```

## Connect zone-1

{% include md/mesh/v3/how-tos/give-zone-credentials.md %}

{% include md/mesh/v3/how-tos/deploy-zone-control-plane.md platform="kubernetes" kube_context="$ZONE1_PROFILE" zone_proxies=true %}

## Connect zone-2

{% include md/mesh/v3/how-tos/give-zone-credentials.md zone="zone-2" var_prefix="ZONE2_" %}

{% include md/mesh/v3/how-tos/deploy-zone-control-plane.md platform="kubernetes" zone="zone-2" var_prefix="ZONE2_" values_file="zone-2-values.yaml" kube_context="$ZONE2_PROFILE" additional_zone=true zone_proxies=true %}

## Verify the zone connections

{% include md/mesh/v3/how-tos/verify-zone-connection-kongctl.md zones="zone-1,zone-2" %}

## Create a mesh and secure the test traffic

{% include md/mesh/v3/how-tos/create-mesh-and-permission.md kube_context="$ZONE1_PROFILE" %}

1. Apply the same permission in zone-2:

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

## Deploy zone proxies

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
   Kubernetes assigns the port automatically, and the zone control plane publishes the resulting `<node IP>:<nodePort>` address in a `MeshZoneAddress`. Other zones use that address to reach this zone's ingress.

   To deploy zone proxies for additional meshes, append more entries to `kuma.meshes`.

1. Add the zone proxies to both zone releases:

   ```sh
   for ctx in $ZONE1_PROFILE $ZONE2_PROFILE; do
     helm upgrade kong-mesh kong-mesh/kong-mesh --kube-context $ctx \
       --namespace kong-mesh-system --version "{{page.latest_release.version}}" \
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

   You should see one entry for each zone, with its ingress `NodePort`.

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

Both zones get a `client` and a `server`, starting with zone-1.

### Deploy the applications in zone-1

{% include md/mesh/v3/how-tos/deploy-test-applications.md kube_context="$ZONE1_PROFILE" %}


### Deploy the applications in zone-2

{% include md/mesh/v3/how-tos/deploy-test-applications.md kube_context="$ZONE2_PROFILE" additional_zone=true %}

The client's `kuma.io/reachable-backends` annotation selects the `server` `MeshService` by its `kuma.io/display-name` and `k8s.kuma.io/namespace` labels.
Those labels also match the `server` `MeshService` synced from the other zone, so the client gets an outbound for both.

## Validate

1. From the `client` pod in zone-1, request the `server` in zone-2 using its cross-zone hostname:

   ```sh
   kubectl --context $ZONE1_PROFILE -n kong-mesh-demo exec deployment/client -c client -- \
     curl --fail --max-time 10 http://server.kong-mesh-demo.svc.zone-2.mesh.local/
   ```

   You should get the nginx welcome page.
   The request goes from the zone-1 sidecar straight to the zone-2 zone ingress, at the address in zone-2's `MeshZoneAddress`.

   {:.info}
   > If the request fails, check that:
   > * zone-2 has a `MeshZoneAddress` with the expected `NodePort`
   > * Both `MeshTrust` copies exist
   > * The zone-2 `MeshTrafficPermission` is in place

1. Confirm that the request went through the zone-2 ingress by reading its Envoy stats through the zone-2 control plane API.
   Port-forward the zone-2 control plane API in the background:

   ```sh
   kubectl --context $ZONE2_PROFILE -n kong-mesh-system port-forward svc/kong-mesh-control-plane 5681:5681 > /dev/null 2>&1 &
   export PORT_FORWARD_PID=$!
   ```

1. Look up the zone-2 ingress pod:

   ```sh
   export INGRESS_POD=$(kubectl --context $ZONE2_PROFILE -n kong-mesh-system get pod \
     -l app=kong-mesh-konnect-demo-ingress -o jsonpath='{.items[0].metadata.name}')
   ```

1. Get the zone-2 admin token. The stats endpoint requires a user that can view stats:

   ```sh
   export ZONE2_ADMIN_TOKEN=$(kubectl --context $ZONE2_PROFILE -n kong-mesh-system get secret admin-user-token \
     -o jsonpath='{.data.value}' | base64 -d)
   ```

1. Read the ingress pod's connection count for the `server` cluster:

   ```sh
   curl -sS --fail --retry 5 --retry-delay 1 --retry-connrefused \
     -H "Authorization: Bearer $ZONE2_ADMIN_TOKEN" \
     "http://localhost:5681/meshes/konnect-demo/dataplanes/${INGRESS_POD}.kong-mesh-system/stats" | \
     grep 'kong-mesh-demo_server_80.upstream_cx_total'
   ```

   You should see a count greater than zero for the zone-2 `server` cluster:

   ```text
   cluster.kri_msvc_konnect-demo_zone-2_kong-mesh-demo_server_80.upstream_cx_total: 1
   ```
   {:.no-copy-code}

   Run the cross-zone request again and the counter increases.

1. Stop the port-forward:

   ```sh
   kill $PORT_FORWARD_PID
   ```
