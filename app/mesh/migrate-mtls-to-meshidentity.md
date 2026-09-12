---
title: "Migrate mesh mTLS to MeshIdentity"
description: "Move workload certificate issuance, trust, TLS mode, and authorization from Mesh.mtls to MeshIdentity before upgrading to {{site.mesh_product_name}} 3."
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/
tags:
  - migration
  - upgrade
  - security
  - mtls
related_resources:
  - text: Migrate policies to {{site.mesh_product_name}} 3
    url: /mesh/migrate-policies-to-3/
  - text: MeshIdentity reference
    url: /mesh/policies/meshidentity/
  - text: MeshTrust reference
    url: /mesh/policies/meshtrust/
  - text: MeshTrafficPermission reference
    url: /mesh/policies/meshtrafficpermission/
---

In {{site.mesh_product_name}} 2.x, the `mtls` block on a `Mesh` chooses a certificate
authority (CA), issues workload certificates, and contributes to the TLS mode for the whole
mesh. In {{site.mesh_product_name}} 3, those responsibilities belong to separate resources:

| Responsibility | 2.x configuration | 3.x configuration |
| --- | --- | --- |
| Issue a workload certificate | `Mesh.mtls.enabledBackend` and `backends` | `MeshIdentity` |
| Publish trusted CA bundles | Implicit in the enabled mesh CA | `MeshTrust` |
| Accept strict or permissive inbound TLS | `mtls.backends[].mode` | `MeshTLS` |
| Authorize a client identity | `MeshTrafficPermission.from` and data plane tags | `MeshTrafficPermission.rules[].default.allow[].spiffeID` |

This is not a field-for-field rewrite. Migrate the four responsibilities together while the
control planes are still running 2.x.

{:.warning}
> Complete this migration for every proxy before upgrading a zone to 3.x. During the 2.x
> transition, once the issuing identity publishes a `MeshTrust`, the control plane also adds the
> legacy mesh CA so old and new workload certificates can coexist. That bridge is removed in
> 3.x. A partially migrated mesh can no longer establish mTLS between legacy and `MeshIdentity`
> workloads after the upgrade.

## Migration workflow

Use this order for each mesh:

1. Upgrade to the latest supported 2.x release in your upgrade path. The control planes must
   support both `Mesh.mtls` and `MeshIdentity` for the rolling migration.
1. Record the enabled CA backend, certificate expiry, TLS mode, and effective traffic
   permissions.
1. On 2.x, finish the
   [migration to `meshServices.mode: Exclusive`](/mesh/v2/meshservice/#migration).
   `MeshIdentity` needs `MeshService` identities during the transition.
1. Create a temporary, non-issuing `MeshIdentity` for the whole mesh. This publishes the
   SPIFFE IDs that workloads will use later without replacing their current certificates.
1. Rewrite `MeshTrafficPermission` to authorize those SPIFFE IDs. If the mesh is permissive,
   also create a `MeshTLS` policy that preserves that behavior.
1. Create an issuing `MeshIdentity` for a small set of workloads and validate both allowed and
   denied traffic.
1. Expand the issuing identity to every workload in the mesh.
1. Confirm that every connected proxy reports the new identity, then remove the temporary
   identity and the `Mesh.mtls` configuration.
1. Upgrade a non-production zone and repeat the traffic checks before upgrading the remaining
   zones.

## Record the current mTLS behavior

Start with the enabled backend, not every backend stored on the mesh:

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  meshServices:
    mode: Exclusive
  mtls:
    enabledBackend: ca-1
    backends:
      - name: ca-1
        type: builtin
        mode: STRICT
        dpCert:
          rotation:
            expiration: 1d
```

Record these values before changing anything:

- The `enabledBackend` and its `type`.
- Whether its `mode` is `STRICT` or `PERMISSIVE`.
- The leaf certificate expiration under `dpCert.rotation.expiration`.
- For a `provided` backend, the certificate and private-key Secret names.
- Every `MeshTrafficPermission` that currently allows traffic into the mesh.

Only the enabled backend issues certificates. Do not translate inactive backends unless they
represent a CA that the new mesh must continue to trust.

## Publish the future SPIFFE IDs

Create a `MeshIdentity` with no `provider`. It calculates identities for
`MeshService.spec.identities`, but does not issue certificates or replace the legacy mesh
identity.

An empty `dataplane` selector covers every proxy:

{% navtabs "environment" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshIdentity
metadata:
  name: migration-spiffe-ids
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default
spec:
  selector:
    dataplane: {}
```

{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: MeshIdentity
name: migration-spiffe-ids
mesh: default
spec:
  selector:
    dataplane: {}
```

{% endnavtab %}
{% endnavtabs %}

This example uses the default SPIFFE ID templates:

- Kubernetes:
  `spiffe://<mesh>.<zone>.mesh.local/ns/<namespace>/sa/<service-account>`
- Universal: `spiffe://<mesh>.<zone>.mesh.local/workload/<workload>`

To use custom `spiffeID.trustDomain` or `spiffeID.path` templates, add the same values to the
temporary and issuing identities. Although the API accepts later template changes, those
changes can invalidate existing trust and permission assumptions. Keep the templates stable
during this migration and plan any identity-format change as a separate transition.

The temporary identity is expected to report `Ready=False` with the reason `PartiallyReady`.
Its `SpiffeIDProvider` condition must be `True`; that condition confirms that it is publishing
SPIFFE IDs without issuing certificates.

## Preserve authorization and permissive TLS

Complete the
[`MeshTrafficPermission` migration](/mesh/migrate-policies-to-3/#meshtrafficpermission)
before selecting a workload with the issuing identity. A proxy using `MeshIdentity` is
authorized through `rules[].default.allow[].spiffeID`; a legacy `from` rule does not authorize
that new identity.

Preserve the existing authorization boundary. For example, if workloads in one Kubernetes
namespace were allowed before the migration, match their new SPIFFE ID prefix rather than
temporarily allowing the entire mesh:

```yaml
type: MeshTrafficPermission
name: allow-orders-clients
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: orders
  rules:
    - default:
        allow:
          - spiffeID:
              type: Prefix
              value: spiffe://default.zone-1.mesh.local/ns/kong-mesh-demo/
```

Substitute the trust domain and path published by your `MeshIdentity`. Test at least one client
that should be allowed and one that should be denied before expanding the issuing identity.

### Preserve permissive mode

No `MeshTLS` policy means `Strict` for a workload with a `MeshIdentity`. If the enabled 2.x
backend uses `mode: PERMISSIVE`, create this policy before the issuing identity selects any
workload:

```yaml
type: MeshTLS
name: preserve-permissive-mode
mesh: default
spec:
  rules:
    - default:
        mode: Permissive
```

A mesh already using `STRICT` does not need a `MeshTLS` policy to preserve its mode.

## Create the issuing identity

Choose the provider that replaces the enabled backend:

| 2.x backend | 3.x provider | Migration choice |
| --- | --- | --- |
| `builtin` | `Bundled` with `autogenerate.enabled: true` | Generate a new CA and publish it through `MeshTrust`. |
| `provided` | `Bundled` with `ca` | Reference the existing certificate and private-key Secrets where possible. |
| `acmpca` | `ACMPCA` | Move the backend settings to the matching enterprise provider. |
| `certmanager` | `CertManager` | Move the issuer settings to the matching enterprise provider. |
| `vault` | `Vault` | Move the Vault settings to the matching enterprise provider. |

The examples below cover `builtin` and `provided`. An external issuer can publish trust through
its own provider integration, so follow that provider's trust instructions instead of assuming
that it creates a PEM-backed `MeshTrust`.

The former `enabledBackend` becomes the identity selected by
`spec.selector.dataplane.matchLabels`. If several identities match a proxy, the selector with
the most labels wins; ties are resolved by identity name.

### Replace a built-in CA

Start with a selector that matches a canary workload. Replace `app: payments` with a label
present on the data plane proxies you want to test:

{% navtabs "environment" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshIdentity
metadata:
  name: default-identity
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default
spec:
  selector:
    dataplane:
      matchLabels:
        app: payments
  provider:
    type: Bundled
    bundled:
      autogenerate:
        enabled: true
      insecureAllowSelfSigned: true
      meshTrustCreation: Enabled
      certificateParameters:
        expiry: 24h
```

{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: MeshIdentity
name: default-identity
mesh: default
spec:
  selector:
    dataplane:
      matchLabels:
        app: payments
  provider:
    type: Bundled
    bundled:
      autogenerate:
        enabled: true
      insecureAllowSelfSigned: true
      meshTrustCreation: Enabled
      certificateParameters:
        expiry: 24h
```

{% endnavtab %}
{% endnavtabs %}

`certificateParameters.expiry` replaces `dpCert.rotation.expiration` for leaf certificates.
The control plane generates a new CA for this identity and creates the corresponding
`MeshTrust`. The old and new CAs remain trusted during the 2.x migration window.

{:.warning}
> When you later give both the temporary and issuing identities an empty selector, their
> specificity is equal and the alphabetically first name wins. The names in this guide make
> `default-identity` win over `migration-spiffe-ids`. If you use different names, confirm that
> the issuing identity wins before expanding it to the whole mesh.

### Keep a provided CA

To continue using an existing CA, reference its certificate and private key:

```yaml
type: MeshIdentity
name: default-identity
mesh: default
spec:
  selector:
    dataplane:
      matchLabels:
        app: payments
  provider:
    type: Bundled
    bundled:
      ca:
        certificate:
          type: Secret
          secretRef:
            kind: Secret
            name: mesh-ca-cert
        privateKey:
          type: Secret
          secretRef:
            kind: Secret
            name: mesh-ca-key
      meshTrustCreation: Enabled
      certificateParameters:
        expiry: 24h
```

Set `insecureAllowSelfSigned: true` only when the supplied certificate is self-signed and you
have accepted that trust model. The certificate and private key must exist before the identity
is created.

## Validate the canary

Do not expand the selector until all of these checks pass:

1. The issuing `MeshIdentity` reports `Provider=True` and `Ready=True`. For a provider that
   generates `MeshTrust`, `MeshTrustCreated` is also `True`.
1. The required trust configuration is available. For a generated `MeshTrust`, the resource
   exists and its `spec.trustDomain` matches the domain in the canary certificate's SPIFFE URI.
1. The canary's `DataplaneInsight.mTLS.issuedBackend` identifies the new `MeshIdentity`, and
   its certificate has a future expiration time.
1. The canary's `MeshService.spec.identities` includes its new SPIFFE ID.
1. An intended client can reach the canary, an unauthorized client is denied, and any required
   plaintext client behaves according to `MeshTLS`.
1. Traffic succeeds in both directions between the canary and a workload still using the legacy
   mesh identity.

In a multi-zone deployment, perform the trust and mixed-identity traffic checks across zone
boundaries too. The migration is not ready to expand until every zone has received the new
`MeshTrust`.

## Expand the identity to the whole mesh

After the canary succeeds, change only the selector on the issuing identity:

```yaml
spec:
  selector:
    dataplane: {}
```

Leave its name, provider, trust domain, and SPIFFE ID path unchanged. Wait for every connected
proxy to report that this `MeshIdentity` issued its certificate.

Proxies receive new identity material over the existing control plane connection; restarting
all workloads at once is not the migration mechanism. Investigate any proxy that still reports
the legacy backend before continuing.

## Remove the legacy configuration

Remove the temporary `migration-spiffe-ids` identity after the issuing identity covers every
workload. Then remove `spec.mtls` from the `Mesh` manifest:

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec: {}
```

Keep other `Mesh.spec` fields that your mesh uses; the example only shows that `mtls` is no
longer present.

Read the `Mesh` back from the API, repeat the allowed and denied traffic tests, and check every
connected proxy once more. Only then is the mesh ready for its first 3.x zone upgrade.

{:.info}
> The old `<mesh>.ca-builtin-*` Secrets are not deleted during the upgrade. Leave them in place
> until the migration and rollback window have closed, then remove them according to your
> credential-retention process.

## Migration is complete when

- Every workload is selected by an issuing `MeshIdentity`.
- Every issuing identity is ready and its required `MeshTrust` is available in every zone.
- `MeshTrafficPermission` rules authorize the intended SPIFFE IDs.
- `MeshTLS` preserves any required permissive behavior.
- No connected proxy reports a certificate from the legacy mesh CA backend.
- The stored `Mesh` and the source-controlled manifest no longer contain `mtls`.
- Allowed, denied, plaintext, and cross-zone traffic behave as designed.
