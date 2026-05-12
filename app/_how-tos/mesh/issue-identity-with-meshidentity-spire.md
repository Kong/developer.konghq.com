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
    - title: Install {{site.mesh_product_name}} with Spire support
      content: |
        Install the {{site.mesh_product_name}} control plane with Helm. Enable the Kubernetes Spire injector on the control plane to use Spire as an identity provider:

        ```sh
        helm repo add kong-mesh https://kong.github.io/kong-mesh-charts
        helm repo update
        helm upgrade \
          --install \
          --create-namespace \
          --namespace kong-mesh-system \
          --set "controlPlane.envVars.KUMA_RUNTIME_KUBERNETES_INJECTOR_SPIRE_ENABLED=true" \
          kong-mesh kong-mesh/kong-mesh
        kubectl wait -n kong-mesh-system --for=condition=ready pod --selector=app=kong-mesh-control-plane --timeout=90s
        ```
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
           ```
    - title: Deploy the demo application
      include_content: prereqs/kubernetes/mesh-demo
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

`MeshIdentity` manages identity issuance. Even though Spire issues the identity and manages the trust, you still create a `MeshIdentity` to configure the data planes to use the identity managed by Spire.

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

## Test connectivity

{% include mesh/meshidentity/test-connectivity.md %}

## Allow traffic

{% include mesh/meshidentity/allow-traffic.md %}

## Validate

{% include mesh/meshidentity/validate.md %}
