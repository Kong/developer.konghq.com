---
title: Progressively roll out unified resource naming
description: Enable unified resource naming for predictable Envoy stats that map directly to mesh resources.
content_type: how_to
permalink: /mesh/progressively-roll-out-unified-resource-naming/

breadcrumbs:
  - /mesh/

min_version:
  mesh: '2.12'

products:
  - mesh

works_on:
  - on-prem

tags:
  - observability

tldr:
  q: How do I progressively roll out unified resource naming?
  a: Apply a `ContainerPatch` to one workload, verify stats, then roll out cluster-wide with a default patch list or global feature flag.

faqs:
  - q: How do I disable the feature for a workload?
    a: |
      You have two options:

      * Set the annotation to an empty value to keep the key in place:

        ```sh
        kubectl patch -n kong-mesh-demo deployment demo-app -p '{"spec":{"template":{"metadata":{"annotations":{"kuma.io/container-patches":""}}}}}'
        ```

      * Remove the annotation entirely for a clean pod template:

        ```sh
        kubectl patch -n kong-mesh-demo deployment demo-app --type=json \
          -p='[{"op":"remove","path":"/spec/template/metadata/annotations/kuma.io~1container-patches"}]'
        ```
  - q: How do I enable unified naming for every workload without per-workload opt-out?
    a: |
      Upgrade the {{site.mesh_product_name}} Helm release to turn on the global feature flag. This approach makes the feature mandatory and removes the ability to disable it on a per-workload basis.

      ```sh
      helm upgrade \
        --install \
        --create-namespace \
        --namespace {{ site.mesh_namespace }} \
        --set "kuma.dataPlane.features.unifiedResourceNaming=true" \
        {{ site.mesh_helm_install_name }} {{ site.mesh_helm_repo }}
      ```
  - q: How do I override the default patch list for a specific workload?
    a: |
      After setting a default patch list cluster-wide, you can override it per workload in two ways.

      Clear the annotation to disable unified naming for a workload:

      ```sh
      kubectl patch -n kong-mesh-demo deployment demo-app \
        -p '{"spec":{"template":{"metadata":{"annotations":{"kuma.io/container-patches":""}}}}}'
      ```

      Or set the annotation to a different patch list to apply custom patches instead:

      ```sh
      kubectl patch -n kong-mesh-demo deployment demo-app \
        -p '{"spec":{"template":{"metadata":{"annotations":{"kuma.io/container-patches":"my-custom-patch-1,my-custom-patch-2"}}}}}'
      ```

prereqs:
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: A running Kubernetes cluster
      include_content: prereqs/kubernetes/mesh-cluster
    - title: Install {{site.mesh_product_name}} with demo configuration
      include_content: prereqs/kubernetes/mesh-quickstart
---

By default, Envoy resources and stats in {{site.mesh_product_name}} use mixed, legacy formats. Names often don't line up with the {{site.mesh_product_name}} resources that produce them, which makes dashboards noisy and troubleshooting slower. For example, the following query isn't intuitive and doesn't point cleanly back to the right {{site.mesh_product_name}} resource:

```text
sum:envoy.cluster.upstream_rq.count{service:my-example-service, !envoy_cluster:kuma_*, !envoy_cluster:meshtrace_*, !envoy_cluster:access_log_sink} by {envoy_cluster}.as_count()
```
{:.no-copy-code}

Different resources and their related stats often look unrelated, even when they describe the same traffic path.

Starting with {{site.mesh_product_name}} 2.12, you can adopt a unified resource naming scheme that makes names predictable, consistent, and directly tied to {{site.mesh_product_name}} resources. This scheme improves observability, simplifies queries, and makes it easier to understand what's happening in the mesh:

{% table %}
columns:
  - title: Before
    key: before
  - title: After
    key: after
rows:
  - before: Mixed legacy and Envoy-native names
    after: Consistent scheme aligned with {{site.mesh_product_name}} resources
  - before: Hard to correlate stats with owners
    after: Direct mapping back to `MeshService` and related resources
  - before: Complex, exclusion-heavy queries
    after: Simple, predictable queries and labels
{% endtable %}

With a progressive rollout, you can validate the new scheme on a single workload, then move to a cluster-wide rollout when you're ready.

## Create a ContainerPatch

Apply a `ContainerPatch` resource that enables unified naming on the sidecar:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: ContainerPatch
metadata:
  name: enable-feature-unified-resource-naming
  namespace: {{ site.mesh_namespace | default: "kuma-system" }}
spec:
  sidecarPatch:
  - op: add
    path: /env/-
    value: '{
      \"name\": \"KUMA_DATAPLANE_RUNTIME_UNIFIED_RESOURCE_NAMING_ENABLED\",
      \"value\": \"true\"
    }'" | kubectl apply -f -
```

The patch configures every sidecar that references it to set an environment variable that turns on the unified naming feature.

## Enable unified naming for one workload

Apply the patch to a workload by updating the Deployment pod template annotation. This lets you enable the feature progressively, service by service.

1. Add the `kuma.io/container-patches` annotation to the `demo-app` Deployment:

   ```sh
   kubectl patch -n kong-mesh-demo deployment demo-app -p '{"spec":{"template":{"metadata":{"annotations":{"kuma.io/container-patches":"enable-feature-unified-resource-naming"}}}}}'
   ```

   Kubernetes rolls out new Pods that include the patched sidecar configuration.

1. Wait for the new Pod to become ready before continuing:

   ```sh
   kubectl wait -n kong-mesh-demo --for=condition=ready pod --selector=app=demo-app --timeout=90s
   ```

## Verify unified naming

Inspect sidecar stats to confirm that unified naming is applied.

1. In one terminal, port-forward to the `demo-app` Pod:

   ```sh
   POD=$(kubectl get pod -n kong-mesh-demo -l app=demo-app -o jsonpath='{.items[0].metadata.name}')
   kubectl port-forward -n kong-mesh-demo pod/$POD 9901:9901
   ```

1. In another terminal, inspect stats:

   ```sh
   curl -s localhost:9901/stats | grep -i kri
   ```

   The command filters for `kri` entries, which are part of the unified resource naming format.

   You should see entries that map directly to {{site.mesh_product_name}} resources, for example:

   ```text
   cluster.kri_msvc_default_default_kong-mesh-demo_demo-app-v1_5050
   ```
   {:.no-copy-code}

   In this format, `msvc` identifies a `MeshService`, and the remaining segments identify the mesh, zone, namespace, Service name, and section. This example shows the `MeshService` resource (`demo-app-v1`) and section (`5050`) clearly, making it easy to connect the stat back to the original {{site.mesh_product_name}} resource.

1. Inspect cluster names for confirmation:

   ```sh
   curl -s localhost:9901/clusters | head -n 50
   ```

## Roll out cluster-wide

After you confirm the feature works on a single workload, set a default list of patches that the injector applies when a workload doesn't specify its own list. This approach makes the feature opt-out: the injector applies it everywhere unless you explicitly disable it.

Upgrade the {{site.mesh_product_name}} Helm release to set the default patch list on the injector:

```sh
helm upgrade \
  --install \
  --create-namespace \
  --namespace {{ site.mesh_namespace }} \
  --set "kuma.controlPlane.envVars.KUMA_RUNTIME_KUBERNETES_INJECTOR_CONTAINER_PATCHES=enable-feature-unified-resource-naming" \
  {{ site.mesh_helm_install_name }} {{ site.mesh_helm_repo }}
```

## Validate the rollout

1. Check that the sidecar stats endpoint is reachable:

   ```sh
   curl -i -X GET localhost:9901/stats
   ```

   The response returns a `200` status code.

1. Confirm that cluster names include the `kri_msvc_` prefix and your mesh resource names:

   ```sh
   curl -s localhost:9901/stats | grep -i 'kri_msvc_'
   ```
