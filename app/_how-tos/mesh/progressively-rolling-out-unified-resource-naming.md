---
title: Progressively roll out unified resource naming
description: Enable unified resource naming for predictable Envoy stats that map directly to mesh resources.
content_type: how_to
permalink: /mesh/progressively-rolling-out-unified-resource-naming/
products:
  - mesh
breadcrumbs:
  - /mesh/
works_on:
  - on-prem
tags:
  - observability
tldr:
  q: How do I progressively roll out unified resource naming?
  a: Apply a `ContainerPatch` to one workload, verify stats, then roll out cluster-wide with a default patch list or global feature flag.
prereqs:
  inline:
    - title: Deploy the Kubernetes demo environment
      content: |
        Complete the [Deploy Kong Mesh on Kubernetes](/mesh/kubernetes/) quickstart.

        Before you continue, verify that the `demo-app` Service is running:

        ```sh
        kubectl get svc -n kuma-demo demo-app
        ```
---

By default, Envoy resources and stats in {{site.mesh_product_name}} use mixed, legacy formats. Names often do not line up with the {{site.mesh_product_name}} resources that produced them, which makes dashboards noisy and troubleshooting slower. For example, a query like:

```text
sum:envoy.cluster.upstream_rq.count{service:my-example-service, !envoy_cluster:kuma_*, !envoy_cluster:meshtrace_*, !envoy_cluster:access_log_sink} by {envoy_cluster}.as_count()
```

is not intuitive and does not point cleanly back to the right {{site.mesh_product_name}} resource. Different resources and their related stats often look unrelated, even when they describe the same traffic path.

Starting with Kong Mesh 2.12, you can adopt a unified resource naming scheme that makes names predictable, consistent, and directly tied to {{site.mesh_product_name}} resources. This improves observability, simplifies queries, and makes it much easier to understand what is happening in the mesh.

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

This patch configures every sidecar that references it to set an environment variable that turns on the unified naming feature.

## Enable unified naming for one workload

Apply the patch to a workload by updating the Deployment pod template annotation. This lets you enable the feature progressively, service by service.

```sh
kubectl patch -n kuma-demo deployment demo-app -p '{"spec":{"template":{"metadata":{"annotations":{"kuma.io/container-patches":"enable-feature-unified-resource-naming"}}}}}'
```

After this update, Kubernetes rolls out new Pods that include the patched sidecar configuration.

To disable the feature later for that workload:

```sh
kubectl patch -n kuma-demo deployment demo-app \
  -p '{"spec":{"template":{"metadata":{"annotations":{"kuma.io/container-patches":""}}}}}'
```

Set the annotation to an empty value if you want to keep the key in place, or remove the annotation entirely if you want a clean pod template:

```sh
kubectl patch -n kuma-demo deployment demo-app --type=json \
  -p='[{"op":"remove","path":"/spec/template/metadata/annotations/kuma.io~1container-patches"}]'
```

## Verify unified naming

Inspect sidecar stats to confirm that unified naming is applied.

1. In one terminal, port-forward to the `demo-app` Pod:

   ```sh
   POD=$(kubectl get pod -n kuma-demo -l app=demo-app -o jsonpath='{.items[0].metadata.name}')
   kubectl port-forward -n kuma-demo pod/$POD 9901:9901
   ```

1. In another terminal, inspect stats:

   ```sh
   curl -s localhost:9901/stats | grep -i kri
   ```

   This command filters for `kri` entries, which are part of the unified resource naming format.

You should see entries that map directly to {{site.mesh_product_name}} resources, for example:

```text
cluster.kri_msvc_default_us-east-2_kuma-demo_demo-app_http
```

In this format, `msvc` identifies a `MeshService`, while the remaining segments identify the mesh, zone, namespace, Service name, and section.

These names show the `MeshService` resource (`demo-app`) and section (`http`) clearly, making them easier to connect back to the original {{site.mesh_product_name}} resource.

You can also inspect cluster names for confirmation:

```sh
curl -s localhost:9901/clusters | head -n 50
```

## Choose a cluster-wide enablement mode

### Option A: Use a default ContainerPatch

Set a default list of patches that the injector applies when a workload does not specify its own list. This approach makes the feature opt-out: it is applied everywhere unless you explicitly disable it.

<!-- vale off -->
{% cpinstall envVar %}
controlPlane.envVars.KUMA_RUNTIME_KUBERNETES_INJECTOR_CONTAINER_PATCHES=enable-feature-unified-resource-naming
{% endcpinstall %}
<!-- vale on -->

Per-workload overrides:

```sh
kubectl patch -n kuma-demo deployment demo-app \
  -p '{"spec":{"template":{"metadata":{"annotations":{"kuma.io/container-patches":""}}}}}'
```

```sh
kubectl patch -n kuma-demo deployment demo-app \
  -p '{"spec":{"template":{"metadata":{"annotations":{"kuma.io/container-patches":"my-custom-patch-1,my-custom-patch-2"}}}}}'
```

### Option B: Use the global feature flag

Enable unified naming for every injected workload. This makes the feature mandatory and removes the ability to disable it on a per-workload basis.

<!-- vale off -->
{% cpinstall dpFeatures %}
dataPlane.features.unifiedResourceNaming: true
{% endcpinstall %}
<!-- vale on -->

## Understand the benefits of unified naming

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

Unified naming improves traceability and reduces the time required to understand what a stat refers to. With a progressive rollout, you can safely validate the new scheme in your environment, then move to a cluster-wide rollout when you are ready.

## Validate the rollout

Send a request to the sidecar stats endpoint:

<!-- vale off -->
{% validation request-check %}
url: '/stats'
on_prem_url: localhost:9901
status_code: 200
method: GET
{% endvalidation %}
<!-- vale on -->

Then run the following command and confirm that cluster names include the `kri_msvc_` prefix and your mesh resource names:

```sh
curl -s localhost:9901/stats | grep -i 'kri_msvc_'
```
