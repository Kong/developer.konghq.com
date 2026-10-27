---
title: Connect a second zone
content_type: how_to
permalink: /mesh/connect-a-second-zone/
description: Start a second Kubernetes cluster, connect it to the Kong Air global control plane in {{site.konnect_short_name}} as zone2, and deploy zone proxies for kong-air-mesh.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
tools:
  - konnect-api
  - kongctl
products:
  - mesh
works_on:
  - konnect
tags:
  - multi-zone
  - kubernetes
  - helm
min_version:
  mesh: '3.0'
series:
  id: mesh-kong-air-scenario
  position: 7
tldr:
  q: How do I add a second zone to my mesh?
  a: |
    1. Start a second Kubernetes cluster.
    2. Give the zone its own system account token with the `Connector` role on the global control plane.
    3. Install a zone control plane named `zone2` with Helm, with the same `meshes` entry as `zone1`.
    4. Check that both zones are online and that `zone2` received `kong-air-mesh`.
related_resources:
  - text: Multi-zone architecture
    url: /mesh/multi-zone-architecture/
  - text: Resource scoping
    url: /mesh/resource-scoping/
  - text: Mesh-scoped zone proxies
    url: /mesh/mesh-scoped-zone-proxies/
  - text: Architecture overview
    url: /mesh/architecture-overview/
  - text: Deploy mesh-scoped zone proxies
    url: /mesh/zone-proxies/
---

Kong Air runs its services in more than one region.
In this guide, you connect a second Kubernetes zone, `zone2`, to the same global control plane as `zone1`.

To learn more about what this guide does, read the following reference pages:

* [Multi-zone architecture](/mesh/multi-zone-architecture/): what a second zone adds to the deployment
* [Resource scoping](/mesh/resource-scoping/): which control plane owns each resource
* [Mesh-scoped zone proxies](/mesh/mesh-scoped-zone-proxies/): how traffic enters and leaves a zone

## Start the zone2 cluster

1. Save the `kubectl` context of `zone1`, so that later commands can target each zone:

   ```sh
   export ZONE1_CONTEXT=$(kubectl config current-context)
   ```

1. Start a second minikube cluster on the same Docker network as `zone1`, so that the two zones can reach each other:

   ```sh
   export ZONE1_IP=$(minikube ip -p mesh-zone)
   minikube start -p mesh-zone-2 --driver=docker --network=mesh-zone --static-ip="${ZONE1_IP%.*}.3"
   export ZONE2_CONTEXT=mesh-zone-2
   ```

   On a shared network, minikube would give the new node the same IP address as the `zone1` node, so `--static-ip` picks the next free address in the `zone1` subnet.
   `--driver=docker` keeps minikube from falling back to a driver that doesn't support `--network`.

## Give zone2 credentials to connect

{% include md/mesh/v3/how-tos/give-zone-credentials.md zone="zone2" var_prefix="ZONE2_" %}

## Install the zone2 control plane

1. Create the namespace for the zone control plane:

   ```sh
   kubectl --context "$ZONE2_CONTEXT" create namespace kong-mesh-system
   ```

1. Store the system account token in the `token` key of a Kubernetes secret named `cp-token`:

   ```sh
   kubectl --context "$ZONE2_CONTEXT" create secret generic cp-token \
     -n kong-mesh-system \
     --from-literal=token="$ZONE2_CONTROL_PLANE_TOKEN"
   ```

1. Create the Helm values file.
   It matches the values you used for `zone1` in [Install {{site.mesh_product_name}} and deploy Kong Air](/mesh/install-kong-mesh-and-deploy-kong-air/), except for the zone name:

   ```sh
   cat <<EOF > zone2-values.yaml
   kuma:
     controlPlane:
       mode: zone
       zone: zone2
       kdsGlobalAddress: $CONTROL_PLANE_URL
       konnect:
         cpId: $CONTROL_PLANE_ID
       zoneToken:
         secretName: cp-token
         key: token
       envVars:
         KUMA_DEFAULTS_RESTRICT_OUTBOUND: "false"
     meshes:
       - name: kong-air-mesh
         ingress:
           enabled: true
           service:
             type: NodePort
         egress:
           enabled: true
   EOF
   ```

1. Install the {{site.mesh_product_name}} zone control plane in `zone2` and wait for it to be ready:

   ```sh
   helm upgrade --install --kube-context "$ZONE2_CONTEXT" \
     --namespace kong-mesh-system \
     kong-mesh kong-mesh/kong-mesh -f zone2-values.yaml
   kubectl --context "$ZONE2_CONTEXT" wait -n kong-mesh-system --for=condition=ready pod \
     --selector=app=kong-mesh-control-plane --timeout=90s
   ```

1. o switch back to the `zone1` context:

   ```sh
   kubectl config use-context "$ZONE1_CONTEXT"
   ```

## Validate

{% include md/mesh/v3/how-tos/verify-zone-connection-kongctl.md zones="zone1,zone2" %}

Then confirm that `zone2` received `kong-air-mesh` from the global control plane:

```sh
kubectl --context "$ZONE2_CONTEXT" get meshes
```

The output lists `kong-air-mesh`.
