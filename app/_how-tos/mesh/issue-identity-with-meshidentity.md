---
title: Issue identity with MeshIdentity bundled provider
description: Learn how to issue SPIFFE-compliant identities using MeshIdentity with the bundled provider and configure MeshTrafficPermission with SPIFFE ID matching.
content_type: how_to
permalink: /mesh/issue-identity-with-meshidentity/
products:
  - mesh
works_on:
  - on-prem
breadcrumbs:
  - /mesh/
tags:
  - security
tldr:
  q: How do I issue identity with the MeshIdentity bundled provider?
  a: Apply a `MeshIdentity` with the bundled provider to issue workload identities, inspect the auto-generated `MeshTrust`, then apply a `MeshTrafficPermission` with SPIFFE ID prefix matching to allow traffic between workloads.
prereqs:
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: A running Kubernetes cluster
      include_content: prereqs/kubernetes/mesh-cluster
    - title: Install {{site.mesh_product_name}} with demo configuration
      include_content: prereqs/kubernetes/mesh-quickstart
cleanup:
  inline:
    - title: Clean up {{site.mesh_product_name}}
      include_content: cleanup/products/mesh
related_resources:
  - text: Issue identity with MeshIdentity Spire provider
    url: /mesh/meshidentity-spire/
  - text: MeshIdentity policy
    url: /mesh/policies/meshidentity/
  - text: MeshTrust policy
    url: /mesh/policies/meshtrust/
next_steps:
  - text: Issue identity with the Spire provider
    url: /mesh/meshidentity-spire/
  - text: MeshTrafficPermission with SPIFFE ID matchers
    url: /mesh/policies/meshtrafficpermission/
---

{:.warning}
> This guide covers an experimental feature.

The [`MeshIdentity`](/mesh/policies/meshidentity/) policy issues identities for selected data planes. This approach is [SPIFFE](https://spiffe.io/docs/latest/spiffe-about/overview/)-compliant and works with [Spire](/mesh/meshidentity-spire/). In this guide, you'll issue identities using the bundled provider.

In {{site.mesh_product_name}}, there are two identity concepts:

* [Identity](/mesh/concepts/#identity): A workload identity is the name encoded in its certificate, and this identity is valid only if the certificate is signed by a trust.
* [Trust](/mesh/concepts/#trust): Trust defines which identities you accept as valid through trusted certificate authorities (CA) that issue those identities. Each trust belongs to a trust domain, and a [mesh](/mesh/mesh/) can contain multiple trusts.

## Issue identities

{:.info}
> For `MeshIdentity` to work, `meshServices.mode: Exclusive` must be set on the `Mesh` resource. This value is already configured in the [demo `Mesh`](#install-kong-mesh-with-demo-configuration).

`MeshIdentity` manages identity issuance. To issue a new identity in a mesh, create this resource:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshIdentity
metadata:
  name: identity
  namespace: {{ site.mesh_namespace }}
  labels:
    kuma.io/mesh: default
spec:
  selector:
    dataplane:
      matchLabels: {}
  spiffeID:
    trustDomain: '{% raw %}{{ .Mesh }}.{{ .Zone }}.mesh.local{% endraw %}'
    path: '{% raw %}/ns/{{ .Namespace }}/sa/{{ .ServiceAccount }}{% endraw %}'
  provider:
    type: Bundled
    bundled:
      meshTrustCreation: Enabled
      insecureAllowSelfSigned: true
      certificateParameters:
        expiry: 24h
      autogenerate:
        enabled: true" | kubectl apply -f -
```

`MeshIdentity` uses `selector` to choose the data planes that receive identities. In this example, the selector issues identity to all data planes in the mesh.

`spiffeID` defines templates for workload SPIFFE IDs. In this example, the trust domain template combines the mesh name, zone name, and `.mesh.local`. The path template combines the namespace and service account.

The `provider` field contains identity provider-specific configuration. This guide uses the `Bundled` provider. This configuration enables [`MeshTrust`](/mesh/policies/meshtrust/) generation, allows self-signed certificates, and sets the certificate expiry time to 24h.

## Inspect trust configuration

The `MeshIdentity` creates a `MeshTrust` resource.

1. Verify that the `MeshTrust` exists:

   ```sh
   kubectl get meshtrusts -n {{ site.mesh_namespace }}
   ```

   You should see the following output:

   ```text
   NAME       AGE
   identity   45s
   ```
   {:.no-copy-code}

1. Inspect the full generated `MeshTrust` resource:

   ```sh
   kubectl get meshtrust identity -n {{ site.mesh_namespace }} -oyaml
   ```

   The generated `MeshTrust` should look like this:

   ```yaml
   apiVersion: kuma.io/v1alpha1
   kind: MeshTrust
   metadata:
     labels:
       kuma.io/env: kubernetes
       kuma.io/mesh: default
       kuma.io/origin: zone
       kuma.io/zone: default
     name: identity
     namespace: {{ site.mesh_namespace }}
   spec:
     caBundles:
     - pem:
         value: |
           -----BEGIN CERTIFICATE-----
           ...
           -----END CERTIFICATE-----
       type: Pem
     origin:
       kri: kri_mid_default_default_{{ site.mesh_namespace }}_identity_
     trustDomain: default.default.mesh.local
   ```
   {:.no-copy-code}

In the generated `MeshTrust`, the control plane generates the `caBundle`, and the `trustDomain` comes from the `MeshIdentity` template. The `origin` value specifies the KRI (Kuma Resource Identifier) of the `MeshIdentity` that generated this trust.

## Test connectivity

1. Port-forward the `demo-app` service on port `5050`:

   ```sh
   kubectl port-forward svc/demo-app -n kong-mesh-demo 5050:5050
   ```

1. In a new terminal, send a request to `demo-app`:

   ```sh
   curl -XPOST localhost:5050/api/counter
   ```
   
   You should see an error like this:
   
   ```json
   {
     "instance": "d11ee97a4b45ff3a7b59091d1612b7f7",
     "status": 500,
     "title": "failed to retrieve zone",
     "type": "https://github.com/kumahq/kuma-counter-demo/blob/main/ERRORS.md#INTERNAL-ERROR"
   }
   ```
   {:.no-copy-code}

Issuing identity to workloads enables mTLS. Zero trust is the default behavior, so without a [`MeshTrafficPermission`](/mesh/policies/meshtrafficpermission/) to allow traffic, these errors are expected.

## Allow traffic

Create a `MeshTrafficPermission`:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: mtp
  namespace: kong-mesh-demo
  labels:
    kuma.io/mesh: default
spec:
  rules:
    - default:
        allow:
          - spiffeID:
              type: Prefix
              value: spiffe://default.default.mesh.local/ns/kong-mesh-demo" | kubectl apply -f -
```

This `MeshTrafficPermission` uses SPIFFE ID matching to allow traffic from workloads whose SPIFFE ID starts with `spiffe://default.default.mesh.local/ns/kong-mesh-demo`.

## Validate

Send another request:

```sh
curl -XPOST localhost:5050/api/counter
```

You should see the following output:

```json
{"counter":1,"zone":""}
```
{:.no-copy-code}
