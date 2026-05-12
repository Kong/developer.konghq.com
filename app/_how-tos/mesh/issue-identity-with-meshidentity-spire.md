---
title: Issue identity with MeshIdentity Spire provider
description: Learn how to issue SPIFFE-compliant identities using MeshIdentity with the Spire provider and configure MeshTrafficPermission with SPIFFE ID matching.
content_type: how_to
permalink: /mesh/issue-identity-with-meshidentity-spire/
products:
  - mesh
works_on:
  - on-prem
breadcrumbs:
  - /mesh/
tags:
  - security
min_version:
  mesh: '2.12'
tldr:
  q: How do I issue identity with the MeshIdentity Spire provider?
  a: Install Spire and configure it to issue SPIFFE identities, apply a `MeshIdentity` with the Spire provider, then apply a `MeshTrafficPermission` with SPIFFE ID prefix matching to allow traffic between workloads.
prereqs:
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: A running Kubernetes cluster
      include_content: prereqs/kubernetes/mesh-cluster
    - title: Install {{site.mesh_product_name}} with demo configuration
      include_content: prereqs/kubernetes/mesh-quickstart
    - title: Install Spire
      content: |
        1. Install the Spire CRDs:

           ```sh
           helm upgrade --install --create-namespace -n spire spire-crds spire-crds \
             --repo https://spiffe.github.io/helm-charts-hardened/
           ```

        1. Install Spire with the trust domain `default.default.mesh.local`. You'll use this trust domain later when you configure `MeshIdentity`:

           ```sh
           helm upgrade --install -n spire spire spire \
             --repo https://spiffe.github.io/helm-charts-hardened/ \
             --set "global.spire.trustDomain=default.default.mesh.local" \
             --set "global.spire.tools.kubectl.tag=v1.31.11"
           kubectl wait -n spire --for=condition=ready pod --all --timeout=90s
           ```
cleanup:
  inline:
    - title: Clean up {{site.mesh_product_name}}
      include_content: cleanup/products/mesh
related_resources:
  - text: Issue identity with MeshIdentity bundled provider
    url: /mesh/issue-identity-with-meshidentity/
  - text: MeshIdentity policy
    url: /mesh/policies/meshidentity/
  - text: MeshTrust policy
    url: /mesh/policies/meshtrust/
next_steps:
  - text: Issue identity with the bundled provider
    url: /mesh/issue-identity-with-meshidentity/
  - text: MeshTrafficPermission with SPIFFE ID matchers
    url: /mesh/policies/meshtrafficpermission/
---

{:.warning}
> This guide covers an experimental feature.

The [`MeshIdentity`](/mesh/policies/meshidentity/) policy issues identities for selected data planes. This approach is [SPIFFE](https://spiffe.io/docs/latest/spiffe-about/overview/)-compliant. In this guide, you'll issue identities using [Spire](https://spiffe.io/docs/latest/spire-about/spire-concepts/) as the identity provider, where Spire issues identities and manages the trust externally.

{% include mesh/meshidentity/concepts.md %}

## Enable Spire injection on the control plane

The {{site.mesh_product_name}} sidecar injector adds the Spire workload API socket to data plane pods at creation time. This behavior is disabled by default. Enable it on the control plane:

```sh
kubectl set env -n kong-mesh-system deploy/kong-mesh-control-plane \
  KUMA_RUNTIME_KUBERNETES_INJECTOR_SPIRE_ENABLED=true
kubectl rollout status -n kong-mesh-system deploy/kong-mesh-control-plane
```

## Configure Spire

Configure Spire to issue identities in the `kong-mesh-demo` namespace. This specifies a SPIFFE ID template that uses the configured trust domain, namespace, and [service account](https://kubernetes.io/docs/concepts/security/service-accounts/) name:

```sh
echo "apiVersion: spire.spiffe.io/v1alpha1
kind: ClusterSPIFFEID
metadata:
  name: spire-registration
spec:
  podSelector:
    matchLabels:
      kuma.io/mesh: default
  spiffeIDTemplate: '{% raw %}spiffe://{{ .TrustDomain }}/ns/{{ .PodMeta.Namespace }}/sa/{{ .PodSpec.ServiceAccountName }}{% endraw %}'
  workloadSelectorTemplates:
    - 'k8s:ns:kong-mesh-demo'" | kubectl apply -f -
```

## Issue identities

{:.info}
> For `MeshIdentity` to work, `meshServices.mode: Exclusive` must be set on the `Mesh` resource. This value is already configured in the demo `Mesh`.

The roles are divided as follows:

- `MeshIdentity` declares which identity provider the data planes should use and how.
- Spire issues the identity and manages the trust.
 
This is why you create a `MeshIdentity` to configure the data planes and specify that Spire manages the identity.

To issue identities in a mesh using Spire, create this resource:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshIdentity
metadata:
  name: identity-spire
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default
    kuma.io/origin: zone
spec:
  selector:
    dataplane:
      matchLabels: {}
  spiffeID:
    trustDomain: default.default.mesh.local
    path: '{% raw %}/ns/{{ .Namespace }}/sa/{{ .ServiceAccount }}{% endraw %}'
  provider:
    type: Spire
    spire: {}" | kubectl apply -f -
```

`MeshIdentity` uses `selector` to choose the data planes that receive identities. In this example, the selector issues identity to all data planes in the mesh.

`spiffeID` defines templates for workload SPIFFE IDs. The trust domain must match the trust domain you configured in Spire (`default.default.mesh.local`). The path template combines the namespace and service account. Example SPIFFE ID: `spiffe://default.default.mesh.local/ns/kong-mesh-demo/sa/default`.

The `provider` field contains identity provider-specific configuration. This guide uses the `Spire` provider.

## Restart the demo application

Restart the demo pods so they're recreated with the Spire workload API socket and pick up the Spire-issued identity:

```sh
kubectl rollout restart -n kong-mesh-demo deployment/demo-app deployment/kv
```

{:.warning}
> Wait until the Pods are restarted before moving on to the next step.

## Test connectivity

{% include mesh/meshidentity/test-connectivity.md %}

## Allow traffic

{% include mesh/meshidentity/allow-traffic.md %}

## Validate

{% include mesh/meshidentity/validate.md %}
