---
title: Manage workload identity and mTLS
content_type: how_to
permalink: /mesh/manage-workload-identity-and-mtls/
description: Inspect the workload identity and trust that Kong Air uses in one zone, then extend them to a second zone so proxies in each zone trust the other zone's certificates.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
products:
  - mesh
works_on:
  - konnect
min_version:
  mesh: '3.0'
series:
  id: mesh-kong-air-scenario
  position: 8
tldr:
  q: How do I extend workload identity and trust to a second zone?
  a: |
    Inspect the identity in your first zone, then extend it to a second zone:
    1. Check that the `MeshIdentity` initialized, and inspect the `MeshTrust` that its `Bundled` provider generated.
    2. Create the same `MeshIdentity` on the second zone, which generates its own CA and trust domain.
    3. Copy each zone's generated `MeshTrust` into the other zone, then confirm that each proxy's trust bundle includes both trust domains.
related_resources:
  - text: Multi-zone meshes
    url: /mesh/policies/meshidentity/#multi-zone-meshes
  - text: MeshTrust
    url: /mesh/policies/meshtrust/
  - text: Identity and trust across zones
    url: /mesh/multi-zone-architecture/#identity-and-trust-across-zones
  - text: MeshIdentity reference
    url: /mesh/policies/meshidentity/
  - text: MeshIdentity providers
    url: /mesh/policies/meshidentity/#providers
  - text: MeshTrafficPermission
    url: /mesh/policies/meshtrafficpermission/
---

A request between two Kong Air services succeeds only when all of the following are true:
* The caller presents a certificate with a Secure Production Identity Framework for Everyone (SPIFFE) ID, issued by [`MeshIdentity`](/mesh/policies/meshidentity/).
* The receiver trusts the issuing certificate authority (CA) through a [`MeshTrust`](/mesh/policies/meshtrust/).
* A [`MeshTrafficPermission`](/mesh/policies/meshtrafficpermission/) allows the caller.

Kong Air now runs a second zone, `zone2`, so all three must also hold across zones.

To learn more about what this guide does, read the following reference pages:

* [Multi-zone meshes](/mesh/policies/meshidentity/#multi-zone-meshes): why each zone has its own CA by default
* [MeshTrust](/mesh/policies/meshtrust/): how a zone trusts the CA of another zone
* [Identity and trust across zones](/mesh/multi-zone-architecture/#identity-and-trust-across-zones): what a cross-zone request needs

## Inspect the identity created in zone1

You created `kong-air-identity` on the `zone1` control plane, in the `{{site.mesh_namespace}}` namespace.
The `kong-air-identity` selector covers every data plane proxy in `kong-air-mesh`, including application sidecars and mesh-scoped zone proxies.

1. Check that `kong-air-identity` initialized.
   `MeshIdentity` reports three conditions, and all three must be `True`:

   ```sh
   kubectl get meshidentity kong-air-identity -n {{site.mesh_namespace}} \
     -o jsonpath='{range .status.conditions[*]}{.type}={.status}{"\n"}{end}'
   ```

   You should get the following result:

   ```text
   Provider=True
   MeshTrustCreated=True
   Ready=True
   ```
   {:.no-copy-code}

   Each condition reports one part of the setup:
   * `Provider`: The CA is usable.
   * `MeshTrustCreated`: The provider published a `MeshTrust`.
   * `Ready`: The identity can issue certificates.

1. Inspect the `MeshTrust` that the `Bundled` provider created.
   Because `kong-air-identity` sets `meshTrustCreation: Enabled`, the control plane creates a `MeshTrust` with the same name:

   ```sh
   kubectl get meshtrust kong-air-identity -n {{site.mesh_namespace}} \
     -o jsonpath='{.spec.trustDomain}{"\n"}{.spec.caBundles[0].type}{"\n"}'
   ```

   You should get the following result:

   ```text
   kong-air-mesh.zone1.mesh.local
   Pem
   ```
   {:.no-copy-code}

1. Confirm which `MeshIdentity` issued each workload's certificate:

   ```sh
   kubectl get dataplaneinsights -n kong-air-production \
     -o custom-columns='NAME:.metadata.name,ISSUER:.status.mTLS.issuedBackend,EXPIRES:.status.mTLS.certificateExpirationTime'
   ```

   Each `ISSUER` value contains `kong-air-identity`.
   An `ISSUER` of `<none>` means that the data plane proxy has no workload identity, for example because no `MeshIdentity` selector matches it.

## Apply the identity in the second zone

Create the same `kong-air-identity` on the `zone2` control plane.
You can only create a `MeshIdentity` in the system namespace.
In `zone2`, the default trust domain resolves to `kong-air-mesh.zone2.mesh.local`:

```sh
kubectl --context "$ZONE2_CONTEXT" apply -f - <<'EOF'
apiVersion: kuma.io/v1alpha1
kind: MeshIdentity
metadata:
  name: kong-air-identity
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  selector:
    dataplane:
      matchLabels:
        kuma.io/mesh: kong-air-mesh
  provider:
    type: Bundled
    bundled:
      insecureAllowSelfSigned: true
      autogenerate:
        enabled: true
      meshTrustCreation: Enabled
  spiffeID:
    path: /ns/{% raw %}{{ .Namespace }}{% endraw %}/sa/{% raw %}{{ .ServiceAccount }}{% endraw %}
EOF
```

For production, we recommend a managed CA or SPIRE instead of self-signed autogenerated CAs, because you control the CA lifecycle.
See [Providers](/mesh/policies/meshidentity/#providers).
This guide uses autogenerated CAs so you can see and test the trust relationship.

## Copy zone1 trust into zone2

A `MeshTrust` spec holds only a `trustDomain` and a list of `caBundles`, so the copy never includes the CA private key.
Create a `MeshTrust` named `kong-air-mesh-trust-of-zone1` in `zone2`, with the two fields read from the `zone1` `MeshTrust`:

```sh
kubectl --context "$ZONE2_CONTEXT" apply -f - <<EOF
apiVersion: kuma.io/v1alpha1
kind: MeshTrust
metadata:
  name: kong-air-mesh-trust-of-zone1
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  trustDomain: $(kubectl --context "$ZONE1_CONTEXT" get meshtrust kong-air-identity -n {{site.mesh_namespace}} -o jsonpath='{.spec.trustDomain}')
  caBundles: $(kubectl --context "$ZONE1_CONTEXT" get meshtrust kong-air-identity -n {{site.mesh_namespace}} -o jsonpath='{.spec.caBundles}')
EOF
```

## Copy zone2 trust into zone1

Create a `MeshTrust` named `kong-air-mesh-trust-of-zone2` in `zone1`, with the two fields read from the `zone2` `MeshTrust`:

```sh
kubectl --context "$ZONE1_CONTEXT" apply -f - <<EOF
apiVersion: kuma.io/v1alpha1
kind: MeshTrust
metadata:
  name: kong-air-mesh-trust-of-zone2
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  trustDomain: $(kubectl --context "$ZONE2_CONTEXT" get meshtrust kong-air-identity -n {{site.mesh_namespace}} -o jsonpath='{.spec.trustDomain}')
  caBundles: $(kubectl --context "$ZONE2_CONTEXT" get meshtrust kong-air-identity -n {{site.mesh_namespace}} -o jsonpath='{.spec.caBundles}')
EOF
```

With three or more zones, every zone needs one `MeshTrust` for each other zone whose certificates it accepts.
We recommend that you automate these copies.

## Validate

1. Confirm that each zone has its own generated `MeshTrust` and the copy from the other zone:

   ```sh
   kubectl --context "$ZONE1_CONTEXT" get meshtrust -n {{site.mesh_namespace}}
   kubectl --context "$ZONE2_CONTEXT" get meshtrust -n {{site.mesh_namespace}}
   ```

1. Confirm that each copied `MeshTrust` holds the other zone's trust domain:

   ```sh
   kubectl --context "$ZONE1_CONTEXT" get meshtrust kong-air-mesh-trust-of-zone2 \
     -n {{site.mesh_namespace}} -o jsonpath='{.spec.trustDomain}{"\n"}'
   kubectl --context "$ZONE2_CONTEXT" get meshtrust kong-air-mesh-trust-of-zone1 \
     -n {{site.mesh_namespace}} -o jsonpath='{.spec.trustDomain}{"\n"}'
   ```

   You should get the following result:

   ```text
   kong-air-mesh.zone2.mesh.local
   kong-air-mesh.zone1.mesh.local
   ```
   {:.no-copy-code}

1. Confirm that the zone control plane includes the copied `MeshTrust` in the trust bundle of each proxy.
   The `supportedBackends` field of each `DataplaneInsight` lists every `MeshTrust` in the mesh that the zone control plane knows:

   ```sh
   kubectl --context "$ZONE1_CONTEXT" get dataplaneinsights -n kong-air-production \
     -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.mTLS.supportedBackends}{"\n"}{end}'
   ```

   Every line contains two `kri_mtrust_` entries: one for the local identity and one for the copy from the other zone:

   ```text
   check-in-api-654c44bbdb-n55x8	["kri_mtrust_kong-air-mesh_zone1_kong-mesh-system_kong-air-identity_","kri_mtrust_kong-air-mesh_zone1_kong-mesh-system_kong-air-mesh-trust-of-zone2_"]
   ```
   {:.no-copy-code}
