---
title: "{{ site.operator_product_name }} Changelog"
description: "New features, bug fixes and breaking changes for {{ site.operator_product_name }}"
content_type: reference
layout: reference
products:
  - operator
breadcrumbs:
  - /operator/
  - index: operator
    section: Reference

---

Changelog for supported {{ site.operator_product_name }} versions.

## 2.1.1

**Release date**: 2026-02-19

### Fixes

- Fix setting up indices for HTTPRoute and Gateway when Konnect controllers are disabled.
  [#3234](https://github.com/Kong/kong-operator/pull/3234)
- Fix v2 module
  [#3353](https://github.com/Kong/kong-operator/pull/3353)
- Bump Go to 1.25.7
  [#3235](https://github.com/Kong/kong-operator/pull/3235)
- Name of Konnect Gateway Control Plane resource created in Konnect matches
  the name of the corresponding `KonnectGatewayControlPlane` resource in Kubernetes
  (the same random suffix is added). It prevents collisions in Konnect.
  [#3357](https://github.com/Kong/kong-operator/pull/3357)
- Use the same defaults for `preserve_host` and `strip_path` in for Konnect Gateway Control Plane
  as in self-managed.
  [#3366](https://github.com/Kong/kong-operator/pull/3366)
- Fix not resetting resource errors in ControlPlane's DB mode from previous `Update()`
  calls to prevent stale errors from leaking into subsequent calls.
  [#3369](https://github.com/Kong/kong-operator/pull/3369)

## 2.1.0

**Release date**: 2026-02-05

### Added

- Gateway: Added support for static naming of Gateway resources via the
  `konghq.com/operator-static-naming` annotation. When set to `true`, the
  DataPlane, ControlPlane, and KonnectGatewayControlPlane resources will be
  named exactly as the Gateway resource instead of using auto-generated names.
  [#3015](https://github.com/Kong/kong-operator/issues/3015)
- HybridGateway: Added support to PathPrefixMatch for the `URLRewrite` `HTTPRoute` filter.
  [#3039](https://github.com/Kong/kong-operator/pull/3039)
- HybridGateway: Added comprehensive HTTPRoute converter tests to improve translation stability.
  [#3111](https://github.com/Kong/kong-operator/pull/3111)
- Support cross namespace references from `KongPluginBinding` to `KongPlugin`.
  For this reference to be allowed, a `KongReferenceGrant` resource must be created
  in the namespace of the `KongPlugin`, allowing access for the `KongPluginBinding`.
  [#3108](https://github.com/Kong/kong-operator/pull/3108)
- HybridGateway: Added support to PathPrefixMatch for the `RequestRedirect` `HTTPRoute` filter.
  [#3065](https://github.com/Kong/kong-operator/pull/3065)
- Support cross namespace references from `KongRoute` to `KongService`.
  For this reference to be allowed, a `KongReferenceGrant` resource must be created
  in the namespace of the `KongService`, allowing access for the `KongRoute`.
  [#3125](https://github.com/Kong/kong-operator/pull/3125)
- Gracefully handle network errors when communicating with Konnect API.
  When a network error occurs during Konnect API operations, the operator
  will patch the resource status conditions to indicate the failure and
  requeue the reconciliation for a later retry.
  [#3184](https://github.com/Kong/kong-operator/pull/3184)
- `DataPlane`: Enable incremental config sync by default when using Konnect as control plane.
  This improves performance of config syncs for large configurations.
  [#2759](https://github.com/Kong/kong-operator/pull/2759)
- `KongCertificate`: Add support for sourcing certificates from Kubernetes Secrets.
  This allows users to define KongCertificates that reference existing Kubernetes
  Secrets containing TLS certificate and key data, instead of embedding them inline.
  [#2802](https://github.com/Kong/kong-operator/pull/2802)  
- `KongCACertificate`: Add support for sourcing CA certificates from Kubernetes Secrets.
  This allows users to define KongCACertificates that references existing Kubernetes
  Secrets containing TLS CA certificate instead of embedding them inline
  [#2482](https://github.com/Kong/kong-operator/pull/2842)
- `KongReferenceGrant` CRD has been added to allow cross-namespace references
  among Konnect entities API. This new resource is to be intended as the Kong
  version of the original Gateway API `ReferenceGrant` CRD.
  [#2855](https://github.com/Kong/kong-operator/pull/2855)
- Hybrid Gateway: specify the protocol field of the generated `KongService` resources
  [#2872](https://github.com/Kong/kong-operator/pull/2872)
- Hybrid Gateway: the creation and deletion of the Kong resources derived from `HTTPRoute`s is now
  performed in multiple steps that account for dependencies among the generated resources.
  [#2857](https://github.com/Kong/kong-operator/pull/2857)
- Added support for cross namespace references between the following Konnect
  entities and `KonnectGatewayControlPlane`

  - `KongService`
  - `KongRoute`
  - `KongUpstream`
  - `KongCertificate`
  - `KongCACertificate`
  - `KongConsumer`
  - `KongConsumerGroup`
  - `KongKey`
  - `KongKeySet`
  - `KongVault`
  - `KongDataPlaneClientCertificate`

  To allow these references, users need to define a `KongReferenceGrant` resource
  in the namespace of the referenced resource, allowing access to the
  `KonnectGatewayControlPlane`.
  [#2892](https://github.com/Kong/kong-operator/pull/2892)
  [#2913](https://github.com/Kong/kong-operator/pull/2913)
  [#3033](https://github.com/Kong/kong-operator/pull/3033)
  [#3040](https://github.com/Kong/kong-operator/pull/3040)
  [#3044](https://github.com/Kong/kong-operator/pull/3044)
  [#3064](https://github.com/Kong/kong-operator/pull/3064)
  [#3069](https://github.com/Kong/kong-operator/pull/3069)
  [#3052](https://github.com/Kong/kong-operator/pull/3052)
  [#3082](https://github.com/Kong/kong-operator/pull/3082)
  [#3086](https://github.com/Kong/kong-operator/pull/3086)
- Added support for cross namespace references between the following Konnect
  entities and `core` `Secret`

  - `KongCertificate`
  - `KongCACertificate`

  To allow these references, users need to define a `KongReferenceGrant` resource
  in the namespace of the referenced resource, allowing access to the
  `Secret`.
  [#2904](https://github.com/Kong/kong-operator/pull/2904)
- Hybrid Gateway: The operator now supports configuring TLS termination on Gateway listeners
  in hybrid mode.When you define a TLS listener on a Gateway resource, the operator will
  automatically create the necessary KongCertificate and KongSNI resources to configure the data plane.
  This allows for managing TLS certificates for Gateways in a Kubernetes-native way.
  [#2915](https://github.com/Kong/kong-operator/pull/2915)
- Cross-namespace references from `KonnectGatewayControlPlane` to
  `KonnectAPIAuthConfiguration` are allowed now and require `KongReferenceGrant`.
  Similarly cross-namespace references from `HTTPRoute` to `Service` are also
  supported and require `ReferenceGrant` in place.
  [#2483](https://github.com/Kong/kong-operator/issues/2483)
- Hybrid Gateway support: Gateway API objects bound to `Gateway`s programmed in Konnect
  are converted into Konnect entities and used to configure the hybrid `DataPlane`.
  [#2134](https://github.com/Kong/kong-operator/pull/2134)
  [#2143](https://github.com/Kong/kong-operator/pull/2143)
  [#2177](https://github.com/Kong/kong-operator/pull/2177)
  [#2260](https://github.com/Kong/kong-operator/pull/2260)
- Add comprehensive HTTPRoute reconciliation that translates Gateway API
  HTTPRoutes into Kong-specific resources for hybrid gateway deployments.
  [#2308](https://github.com/Kong/kong-operator/pull/2308)
- Hybrid Gateway: add support to HTTPRoute hostnames translation
  [#2346](https://github.com/Kong/kong-operator/pull/2346)
  - Enforce state and cleanup for Kong entities
  - Introduced managedfields package for structured merge diff, including compare, extract, prune, and schema utilities with comprehensive tests.
  - Refactored builder and converter logic for KongRoute, KongService, KongTarget, KongUpstream, and HTTPRoute.
  - Enhanced metadata labeling and reconciliation logic for HTTPRoute; added resource ownership tracking via watches.
  - Added generated schema in zz_generated_schema.go for resource types.
  - Improved and extended unit tests for hybridgateway components.
  [2355](https://github.com/Kong/kong-operator/pull/2355)
- Hybrid Gateway: add Konnect specific fields to `GatewayConfiguration` CRD.
  [#2390](https://github.com/Kong/kong-operator/pull/2390)
  [#2405](https://github.com/Kong/kong-operator/pull/2405)
- Hybrid Gateway: implement granular accepted and programmed conditions for HTTPRoute status
  This commit introduces comprehensive support for "Accepted" and "Programmed" status conditions
  on HTTPRoute resources in the hybridgateway controller. The new logic evaluates each ParentReference
  for controller ownership, Gateway/GatewayClass support, listener matching, and resource programming
  status. For every relevant Kong resource (KongRoute, KongService, KongTarget, KongUpstream, KongPlugin, KongPluginBinding),
  the controller sets detailed programmed conditions, providing clear feedback on which resources are operational
  and which are not.
  The update also refactors builder and metadata logic to ensure labels and annotations are correctly set for
  all managed resources, and improves test coverage for label, annotation, and hostname intersection handling.
  Legacy status controller code is removed, and the reconciliation flow is streamlined to use the new status
  enforcement and translation logic.
  This enables more robust troubleshooting and visibility for users, ensuring HTTPRoute status accurately reflects
  the readiness and configuration of all associated Kong resources.
  [#2400](https://github.com/Kong/kong-operator/pull/2400)
- ManagedFields: improve pruning of empty fields in unstructured objects
  - Enhance pruneEmptyFields to recursively remove empty maps from slices and maps, including those that become empty after nested pruning.
  - Update logic to remove empty slices and zero-value fields more robustly.
  - Expand and refine unit tests in prune_test.go to cover all edge cases, including:
    - Nested empty maps and slices
    - Removal of empty maps from slices
    - Handling of mixed-type slices
    - Deeply nested pruning scenarios
    - Preservation of non-map elements in slices
  [#2413](https://github.com/Kong/kong-operator/pull/2413)
- Entity Adoption support: support adopting an existing entity from Konnect to
  a Kubernetes custom resource for managing the existing entity by KO.
  - Add adoption options to the CRDs supporting adopting entities from Konnect.
    [#2336](https://github.com/Kong/kong-operator/pull/2336)
  - Add `adopt.mode` field to the CRDs that support adopting existing entities.
    Supported modes:
    - `match`: read-only adoption. The operator adopts the referenced remote entity
      only when this CR's spec matches the remote configuration
      (no writes to the remote system).
      If they differ, adoption fails and the operator does not take ownership until
      the spec is aligned.
    - `override`: The operator overrides the remote entity with the spec in the CR.
    [#2421](https://github.com/Kong/kong-operator/pull/2421)
    [#2424](https://github.com/Kong/kong-operator/pull/2424)
  - Implement the general handling process of adopting an existing entity and
    adoption procedure for `KongService`s in `match` and `override` mode.
    [#2424](https://github.com/Kong/kong-operator/pull/2424)
  - Implement the Match mode for adoption for Konnect cloud gateway entities
    [#2429](https://github.com/Kong/kong-operator/pull/2429)
  - Implement adoption support for `KongCertificate`, `KongCACertificate` and `KongSNI`
    [#2484](https://github.com/Kong/kong-operator/pull/2484)
  - Implement adoption support for `KongVault`.
    [#2490](https://github.com/Kong/kong-operator/pull/2490)
  - Implement adoption for `KongKey` and `KongKeySet` resources
    [#2487](https://github.com/Kong/kong-operator/pull/2487)
  - Implement adoption support for `KongConsumer` and `KongConsumerGroup`
    [#2493](https://github.com/Kong/kong-operator/pull/2493)
  - Implement adoption for `KongPluginBinding`.
    [#2492](https://github.com/Kong/kong-operator/pull/2492)
  - Implement adoption support for `KongCredentialAPIKey`, `KongCredentialBasicAuth`, `KongCredentialACL`, `KongCredentialJWT`, and `KongCredentialHMAC`
    [#2494](https://github.com/Kong/kong-operator/pull/2494)
  - Implement adoption support for `KongDataPlaneClientCertificate`.
    [#2678](https://github.com/Kong/kong-operator/pull/2678)
- HybridGateway:
  - Added controller-runtime watches for Gateway and GatewayClass resources to the hybridgateway controller.
  - HTTPRoutes are now reconciled when related Gateway or GatewayClass resources change.
  - Improved event mapping and indexing logic for efficient reconciliation.
  - Added unit tests for new watch and index logic.
  [#2419](https://github.com/Kong/kong-operator/pull/2419)
- Provision hybrid Gateway: implement support for provisioning hybrid Gateways with
  gateway api `Gateway` and `GatewayConfiguration` resources.
  [#2457](https://github.com/Kong/kong-operator/pull/2457)
- Add support to HTTPRoute RequestRedirect filter
  [#2470](https://github.com/Kong/kong-operator/pull/2470)
- Add CLI flag `--enable-fqdn-mode` to enable Fully Qualified Domain Name (FQDN)
  mode for service discovery. When enabled, Kong targets are configured to use
  service FQDNs (e.g., `service.namespace.svc.cluster.local`) instead of
  individual pod endpoint IPs.
  [#2607](https://github.com/Kong/kong-operator/pull/2607)
- Gateway: support per-Gateway infrastructure configuration
  [GEP-1867](https://gateway-api.sigs.k8s.io/geps/gep-1867/) via
  `GatewayConfiguration` CRD.
  [#2653](https://github.com/Kong/kong-operator/pull/2653)
- HybridGateway: reworked generated resources lifecycle management. HTTPRoute ownership on the resources
  is now tracked through the `gateway-operator.konghq.com/hybrid-routes` annotation. The same generated
  resource can now be shared among different HTTPRoutes.
  [#2656](https://github.com/Kong/kong-operator/pull/2656)
- HybridGateway: implemented `ExtensionRef` filters to allow reference of self-managed plugins from
  `HTTPRoute`s' filters.
  [#2715](https://github.com/Kong/kong-operator/pull/2715)
- `KonnectAPIAuthConfiguration` resources now have automatic finalizer management
  to prevent deletion when they are actively referenced by other Konnect resources
  (`KonnectGatewayControlPlane`, `KonnectCloudGatewayNetwork`, `KonnectExtension`).
  The finalizer `konnect.konghq.com/konnectapiauth-in-use` is automatically added
  when references exist and removed when all referencing resources are deleted.
  [#2726](https://github.com/Kong/kong-operator/pull/2726)
- Add the following configuration flags for setting the maximum number of concurrent
  reconciliation requests that can be processed by each controller group:
  - `--max-concurrent-reconciles-dataplane-controller` for DataPlane controllers.
  - `--max-concurrent-reconciles-controlplane-controller` for ControlPlane controllers.
  - `--max-concurrent-reconciles-gateway-controller` for Gateway controllers.

  NOTE: Konnect entities controllers still respect the
  `--konnect-controller-max-concurrent-reconciles` flag.
  [#2652](https://github.com/Kong/kong-operator/pull/2652)

### Changed

- Removed the `KonnectID` type of control plane reference in CRDs for Konnect
  entities as it is not supported.
  [#2966](https://github.com/Kong/kong-operator/pull/2966)
- Move management of bootstrapping CA certificate (that is used for signing
  certificates for ControlPlane - DataPlane communication) to Helm Chart,
  deprecate flags `--cluster-ca-key-type` and  `--cluster-ca-key-size` now
  those values are inferred automatically based on the CA certificate Secret.
  Read more in Helm Chart release notes.
  [#3084](https://github.com/Kong/kong-operator/pull/3084)
- HybridGateway: Include readable backend context in generated KongService and
  KongUpstream names (with stable hashes) to improve UX in Konnect.
  [#3121](https://github.com/Kong/kong-operator/pull/3121)
- kong/kong-gateway v3.12 is the default proxy image. [#2391](https://github.com/Kong/kong-operator/pull/2391)
- For Hybrid `Gateway`s the operator does not run the `ControlPlane` anymore, as
  the `DataPlane` is configured to use `Koko` as Konnect control plane.
  [#2253](https://github.com/Kong/kong-operator/pull/2253)
- HybridGateway auto-generated resource names has been revised.
  [#2566](https://github.com/Kong/kong-operator/pull/2566)
- Update Gateway API to 1.4.0 and k8s libraries to 1.34.
  [#2451](https://github.com/Kong/kong-operator/pull/2451)
- `DataPlane`'s `spec.network.services.ingress.ports` now allows up to 64 ports
  to be specified. This aligns `DataPlane` with Gateway APIs' `Gateway`.
  [#2722](https://github.com/Kong/kong-operator/pull/2722)
- In Konnect controllers, ignore `NotFound` errors when removing the finalizer
  from the resource.
  [#2911](https://github.com/Kong/kong-operator/pull/2911)

### Fixes

- Fix validation logic for dataplane ports in admission policy.
  [#3031](https://github.com/Kong/kong-operator/pull/3031)
- Add maxLength and pattern validations for `KongConsumer` and `KongConsumerGroup` fields.
  [#3109](https://github.com/Kong/kong-operator/pull/3109)
- Gateway: Sort Gateway/DataPlane status addresses deterministically with hostname-first priority.
  [#3110](https://github.com/Kong/kong-operator/pull/3110)
- HybridGateway: Fixed the logic of translating `HTTPRoute` path matches to
  paths in the generated `KongRoute`.
  [#2996](https://github.com/Kong/kong-operator/pull/2996)
- HybridGateway: Add the `~*` prefix to mark the header should be matched by
  regular expression in the translated `KongRoute` when the `HTTPRoute`'s header
  match has the `RegularExpression` type.
  [#2995](https://github.com/Kong/kong-operator/pull/2995)
- Fixes a panic in KonnectExtension controller when Control Plane is not found.
  [#3054](https://github.com/Kong/kong-operator/pull/3054)
- Fixed an issue where users could set the secret of configmap label selectors
  to empty when the other one was left non-empty.
  [#2810](https://github.com/Kong/kong-operator/pull/2810)
- Handle Konnect API 429 rate limit responses by requeuing resources with
  the appropriate retry-after duration from the response header.
  [#2856](https://github.com/Kong/kong-operator/pull/2856)
- Hybrid Gateway: generate a single KongRoute for each HTTPRoute Rule
  [#2417](https://github.com/Kong/kong-operator/pull/2417)
- Fix issue with deletion of `KonnectExtension` when the referenced
  `KonnectGatewayControlPlane` is deleted (it used to hang indefinitely).
  [#2423](https://github.com/Kong/kong-operator/pull/2423)
- Hybrid Gateway: add watchers for KongPlugin and KongPluginBinding
  [#2427](https://github.com/Kong/kong-operator/pull/2427)
- Hybrid Gateway: attach KongService generation to BackendRefs and fix filter/plugin conversion.
  [#2456](https://github.com/Kong/kong-operator/pull/2456)
- Translate `healthchecks.threshold` in `KongUpstreamPolicy` to the
  `healthchecks.threshold` field in Kong upstreams.
  [#2662](https://github.com/Kong/kong-operator/pull/2662)
- Reject CA Secrets with multiple PEM certs.
  [#2671](https://github.com/Kong/kong-operator/pull/2671)
- Fix the default values of `combinedServicesFromDifferentHTTPRoutes` and
  `drainSupport` in `ControlPlaneTranslationOptions` not being set correctly.
  [#2589](https://github.com/Kong/kong-operator/pull/2589)
- Fix random, unexpected and invalid validation error during validation of `HTTPRoute`s
  for `Gateway`s configured in different namespaces with `GatewayConfiguration` that
  has field `spec.controlPlaneOptions.watchNamespaces.type` set to `own`.
  [#2717](https://github.com/Kong/kong-operator/pull/2717)
- Gateway controllers now watch changes on Secrets referenced by
  `spec.listeners.tls.certificateRef`, ensuring Gateway status conditions
  are updated when referenced certificates change.
  [#2661](https://github.com/Kong/kong-operator/pull/2661)

## 2.0.7

**Release date**: 2026-02-19

### Fixed

- Fixed an issue where users could set the secret of configmap label selectors
  to empty when the other one was left non-empty.
  [#2815](https://github.com/Kong/kong-operator/pull/2815)
- Bump Go to 1.25.7 and fix v2 module
  [#3355](https://github.com/Kong/kong-operator/pull/3355)

## 2.0.6

**Release date**: 2025-12-01

### Fixes

- Translate `healtchchecks.thershold` in `KongUpstreamPolicy` to the
  `healthchecks.thershold` field in Kong upstreams.
  [#2662](https://github.com/Kong/kong-operator/pull/2662)
- Fix random, unexpected and invalid validation error during validation of `HTTPRoute`s
  for `Gateway`s configured in different namespaces with `GatewayConfiguration` that
  has field `spec.controlPlaneOptions.watchNamespaces.type` set to `own`.
  [#2717](https://github.com/Kong/kong-operator/pull/2717)
- Reject CA Secrets with multiple PEM certs.
  [#2671](https://github.com/Kong/kong-operator/pull/2671)
- Gateway controllers now watch changes on Secrets referenced by
  `spec.listeners.tls.certificateRef`, ensuring Gateway status conditions
  are updated when referenced certificates change.
  [#2661](https://github.com/Kong/kong-operator/pull/2661)
- Trigger reconciliation events on `KongPlugin`s upon changes on `KongPluginBinding`.
  [#2637](https://github.com/Kong/kong-operator/pull/2637)

## 2.0.5

**Release date**: 2025-10-17

### Fixes

- Fix `DataPlane`'s volumes and volume mounts patching when specified by user
  [#2425](https://github.com/Kong/kong-operator/pull/2425)
- Do not cleanup `null`s in the configuration of plugins with Kong running in
  DBLess mode in the translator of ingress-controller. This enables user to use
  explicit `null`s in plugins.
  [#2459](https://github.com/Kong/kong-operator/pull/2459)

## 2.0.4

**Release date**: 2025-10-03

### Fixes

- Fix problem with starting operator when Konnect is enabled and conversion webhook disabled.
  [#2392](https://github.com/Kong/kong-operator/issues/2392)

## 2.0.3

**Release date**: 2025-09-30

### Fixes

- Do not validate `Secret`s and `ConfigMap`s that are used internally by the operator.
  This prevents issues when those resources are created during bootstrapping of the
  operator, before the validating webhook is ready.
  [#2356](https://github.com/Kong/kong-operator/pull/2356)
- Add the `status.clusterType` in `KonnectGatewayControlPlane` and set it when
  KO attached the `KonnectGatewayControlPlane` with the control plane in
  Konnect. The `KonnectExtension` now get the cluster type to fill its
  `status.konnect.clusterType` from the `statusType` of `KonnectGatewayControlPlane`
  to fix the incorrect cluster type filled in the status when the control plane
  is mirrored from an existing control plane in Konnect.
  [#2343](https://github.com/Kong/kong-operator/pull/2343)

## 2.0.2

**Release date**: 2025-09-22

### Fixes

- Cleanup old objects when new `ControlPlane` is ready.
  Remove old finalizers from `ControlPlane` when cleanup is done.
  [#2317](https://github.com/Kong/kong-operator/pull/2317)
- Mark `Gateway`'s listeners as Programmed when `DataPlane` and its `Services` are ready.
  This prevents downtime during KGO -> KO upgrades and in upgrades between KO versions.
  [#2317](https://github.com/Kong/kong-operator/pull/2317)

## 2.0.1

**Release date**: 2025-09-17

### Fixes

- Fix incorrect error handling during cluster CA secret creation.
  [#2250](https://github.com/Kong/kong-operator/pull/2250)
- `DataPlane` is now marked as ready when `status.AvailableReplicas` is at least equal to `status.Replicas`.
  [#2291](https://github.com/Kong/kong-operator/pull/2291)

## 2.0.0

**Release date**: 2025-09-09

> KGO becomes KO, which stands for Kong Operator. Kubernetes Gateway Operator and Kubernetes Ingress Controller
> become a single product. Furthermore, Kong Operator provides all features that used to be reserved for the
> Enterprise flavor of Kong Gateway Operator.

### Breaking Changes

- `KonnectExtension` has been bumped to `v1alpha2` and the Control plane reference via plain `KonnectID`
  has been removed. `Mirror` `GatewayControlPlane` resource is now the only way to reference remote
  control planes in read-only.
  [#1711](https://github.com/kong/kong-operator/pull/1711)
- Rename product from Kong Gateway Operator to Kong Operator.
  [#1767](https://github.com/Kong/kong-operator/pull/1767)
- Add `--cluster-domain` flag and set default to `'cluster.local'`
  This commit introduces a new `--cluster-domain` flag to the KO binary, which is now propagated to the ingress-controller.
  The default value for the cluster domain is set to `'cluster.local'`, whereas previously it was an empty string (`''`).
  This is a breaking change, as any code or configuration relying on the previous default will now use `'cluster.local'`
  unless explicitly overridden.
  [#1870](https://github.com/Kong/kong-operator/pull/1870)
- Introduce `ControlPlane` in version `v2alpha1`
  - Usage of the last valid config for fallback configuration is enabled by default,
    can be adjusted in the `spec.translation.fallbackConfiguration.useLastValidConfig` field.
    [#1939](https://github.com/Kong/kong-operator/issues/1939)
- `ControlPlane` `v2alpha1` has been replaced by `ControlPlane` `v2beta1`.
  `GatewayConfiguration` `v2alpha1` has been replaced by `GatewayConfiguration` `v2beta1`.
  [#2008](https://github.com/Kong/kong-operator/pull/2008)
- Add flags `--secret-label-selector` and `--config-map-label-selector` to
  filter watched `Secret`s and `ConfigMap`s. Only secrets or configMaps with
  the given label to `true` are reconciled by the controllers.
  For example, if `--secret-label-selector` is set to `konghq.com/secret`,
  only `Secret`s with the label `konghq.com/secret=true` are reconciled.
  The default value of the two labels are set to `konghq.com/secret` and
  `konghq.com/configmap`.
  [#1922](https://github.com/Kong/kong-operator/pull/1922)
- `GatewayConfiguration` `v1beta1` has been replaced by the new API version `v2alpha1`.
  The `GatewayConfiguration` `v1beta1` is still available but has been marked as
  deprecated.
  [#1792](https://github.com/Kong/kong-operator/pull/1972)
- Removed `KongIngress`, `TCPIngress` and `UDPIngress` CRDs together with their controllers.
  For migration guidance from these resources to Gateway API, please refer to the
  [migration documentation](https://developer.konghq.com/kubernetes-ingress-controller/migrate/ingress-to-gateway/).
  [#1971](https://github.com/Kong/kong-operator/pull/1971)
- Change env vars prefix from `GATEWAY_OPERATOR_` to `KONG_OPERATOR_`.
  `GATEWAY_OPERATOR_` prefixed env vars are still accepted but reported as deprecated.
  [#2004](https://github.com/Kong/kong-operator/pull/2004)

### Added

- Support for `cert-manager` certificate provisioning for webhooks in Helm Chart.
  [#2122](https://github.com/Kong/kong-operator/pull/2122)
- Support specifying labels to filter watched `Secret`s and `ConfigMap`s of
  each `ControlPlane` by `spec.objectFilters.secrets.matchLabels` and
  `spec.objectFilters.configMaps.matchLabels`. Only secrets or configmaps that
  have the labels matching the specified labels in spec are reconciled.
  If Kong operator has also flags `--secret-label-selector` or
  `--config-map-label-selector` set, the controller for each `ControlPlane` also
  requires reconciled secrets or configmaps to set the labels given in the flags
  to `true`.
  [#1982](https://github.com/Kong/kong-operator/pull/1982)
- Add conversion webhook for `KonnectGatewayControlPlane` to support seamless conversion
  between old `v1alpha1` and new `v1alpha2` API versions.
  [#2023](https://github.com/Kong/kong-operator/pull/2023)
- Add Konnect related configuration fields to `ControlPlane` spec, allowing fine-grained
  control over Konnect integration settings including consumer synchronization, licensing
  configuration, node refresh periods, and config upload periods.
  [#2009](https://github.com/Kong/kong-operator/pull/2009)
- Added `OptionsValid` condition to `ControlPlane`s' status. The status is set to
  `True` if the `ControlPlane`'s options in its `spec` is valid and set to `False`
  if the options are invalid against the operator's configuration.
  [#2070](https://github.com/Kong/kong-operator/pull/2070)
- Added `APIConversion` interface to bootstrap Gateway API support in Konnect hybrid
  mode.
  [#2134](https://github.com/Kong/kong-operator/pull/2134)
- Move implementation of ControlPlane Extensions mechanism and DataPlaneMetricsExtension from EE.
  [#1583](https://github.com/kong/kong-operator/pull/1583)
- Move implementation of certificate management for Konnect DPs from EE.
  [#1590](https://github.com/kong/kong-operator/pull/1590)
- `ControlPlane` status fields `controllers` and `featureGates` are filled in with
  actual configured values based on the defaults and the `spec` fields.
  [#1771](https://github.com/kong/kong-operator/pull/1771)
- Added the following CLI flags to control operator's behavior:
  - `--cache-sync-timeout` to control controller-runtime's time limit set to wait for syncing caches.
    [#1818](https://github.com/kong/kong-operator/pull/1818)
  - `--cache-sync-period` to control controller-runtime's cache sync period.
    [#1846](https://github.com/kong/kong-operator/pull/1846)
- Support the following configuration for running control plane managers in
  the `ControlPlane` CRD:
  - Specifying the delay to wait for Kubernetes object caches sync before
    updating dataplanes by `spec.cache.initSyncDuration`
    [#1858](https://github.com/Kong/kong-operator/pull/1858)
  - Specifying the period and timeout of syncing Kong configuration to dataplanes
    by `spec.dataplaneSync.interval` and `spec.dataplaneSync.timeout`
    [#1886](https://github.com/Kong/kong-operator/pull/1886)
  - Specifying the combined services from HTTPRoutes feature via
    by `spec.translation.combinedServicesFromDifferentHTTPRoutes`
    [#1934](https://github.com/Kong/kong-operator/pull/1934)
  - Specifying the drain support by `spec.translation.drainSupport`
    [#1940](https://github.com/Kong/kong-operator/pull/1940)
- Introduce flags `--apiserver-host` for API, `--apiserver-qps` and
  `--apiserver-burst` to control the QPS and burst (rate-limiting) for the
  Kubernetes API server client.
  [#1887](https://github.com/Kong/kong-operator/pull/1887)
- Introduce the flag `--emit-kubernetes-events` to enable/disable the creation of
  Kubernetes events in the `ControlPlane`. The default value is `true`.
  [#1888](https://github.com/Kong/kong-operator/pull/1888)
- Added the flag `--enable-controlplane-config-dump` to enable debug server for
  dumping Kong configuration translated from `ControlPlane`s and flag
  `--controlplane-config-dump-bind-address` to set the bind address of server.
  You can access `GET /debug/controlplanes` to list managed `ControlPlane`s and
  get response like `{"controlPlanes":[{"namespace":"default","name":"kong-12345","id":"abcd1234-..."}]}`
  listing the namespace, name and UID of managed `ControlPlane`s.
  Calling `GET /debug/controlplanes/namespace/{namespace}/name/{name}/config/{req_type}`
  can dump Kong configuration of a specific `ControlPlane`. This endpoint is
  only available when the `ControlPlane`'s `spec.configDump.state` is set to `enabled`.
  The `{req_type}` stands for the request type of dumping configuration.
  Supported `{req_type}`s are:
  - `successful` for configuration in the last successful application.
  - `failed` for configuration in the last failed application.
  - `fallback` for configuration applied in the last fallback procedure.
  - `raw-error` for raw errors returned from the dataplane in the last failed
     application.
  - `diff-report` for summaries of differences between the last applied
     configuration and the confiugration in the dataplane before that application.
     It requires the `ControlPlane` set `spec.configDump.dumpSensitive` to `enabled`.
  [#1894](https://github.com/Kong/kong-operator/pull/1894)
- Introduce the flag `--watch-namespaces` to specify which namespaces the operator
  should watch for configuration resources.
  The default value is `""` which makes the operator watch all namespaces.
  This flag is checked against the `ControlPlane`'s `spec.watchNamespaces`
  field during `ControlPlane` reconciliation and if incompatible, `ControlPlane`
  reconciliation returns with an error.
  [#1958](https://github.com/Kong/kong-operator/pull/1958)
  [#1974](https://github.com/Kong/kong-operator/pull/1974)
- Refactored Konnect extension processing for `ControlPlane` and `DataPlane` resources
  by introducing the `ExtensionProcessor` interface.
  This change enables KonnecExtensions for `ControlPlane v2alpha1`.
  [#1978](https://github.com/Kong/kong-operator/pull/1978)

### Changes

- `ControlPlane` provisioned conditions' reasons have been renamed to actually reflect
  the new operator architecture. `PodsReady` is now `Provisioned` and `PodsNotReady`
  is now `ProvisioningInProgress`.
  [#1985](https://github.com/Kong/kong-operator/pull/1985)
- Vendor gateway-operator CRDs locally and switch Kustomize to use the vendored source.
  [#2195](https://github.com/Kong/kong-operator/pull/2195)
- `kong/kong-gateway` v3.11 is the default proxy image.
  [#2212](https://github.com/Kong/kong-operator/pull/2212)

### Fixes

- Do not check "Programmed" condition in status of `Gateway` listeners in
  extracting certificates in controlplane's translation of Kong configuration.
  This fixes the disappearance of certificates when deployment status of
  `DataPlane` owned by the gateway (including deletion of pods, rolling update
  of dataplane deployment, scaling of dataplane and so on).
  [#2038](https://github.com/Kong/kong-operator/pull/2038)
- Correctly assume default Kong router flavor is `traditional_compatible` when
  `KONG_ROUTER_FLAVOR` is not set. This fixes incorrectly populated
  `GatewayClass.status.supportedFeatures` when the default was assumed to be
  `expressions`.
  [#2043](https://github.com/Kong/kong-operator/pull/2043)
- Support setting exposed nodeport of the dataplane service for `Gateway`s by
  `nodePort` field in `spec.listenersOptions`.
  [#2058](https://github.com/Kong/kong-operator/pull/2058)
- Fixed lack of `instance_name` and `protocols` reconciliation for `KongPluginBinding` when reconciling against Konnect.
  [#1681](https://github.com/kong/kong-operator/pull/1681)
- The `KonnectExtension` status is kept updated when the `KonnectGatewayControlPlane` is deleted and
  re-created. When this happens, the `KonnectGatewayControlPlane` sees its Konnect ID changed, as well
  as the endpoints. All this data is constantly enforced into the `KonnectExtension` status.
  [#1684](https://github.com/kong/kong-operator/pull/1684)
- Fix the issue that invalid label value causing ingress controller fails to
  store the license from Konnect into `Secret`.
  [#1976](https://github.com/Kong/kong-operator/pull/1976)
- Fixed a missing watch in `GatewayClass` reconciler for related `GatewayConfiguration` resources.
  [#2161](https://github.com/Kong/kong-operator/pull/2161)

## 1.6.2

**Release date**: 2025-07-11

### Fixes

- Ignore the `ForbiddenError` in `sdk-konnect-go` returned from running CRUD
  operations against Konnect APIs. This prevents endless reconciliation when an
  operation is not allowed (due to e.g. exhausted quota).
  [#1811](https://github.com/Kong/kong-operator/pull/1811)

## 1.6.1

**Release date**: 2025-05-22

## Changed

- Allowed the `kubectl rollout restart` operation for Deployment resources created via DataPlane CRD.
  [#1660](https://github.com/kong/kong-operator/pull/1660)

## 1.6.0

**Release date**: 2025-05-07

### Added

- In `KonnectGatewayControlPlane` fields `Status.Endpoints.ControlPlaneEndpoint`
  and `Status.Endpoints.TelemetryEndpoint` are filled with respective values from Konnect.
  [#1415](https://github.com/kong/kong-operator/pull/1415)
- Add `namespacedRef` support for referencing networks in `KonnectCloudGatewayDataPlaneGroupConfiguration`
  [#1423](https://github.com/kong/kong-operator/pull/1423)
- Introduced new CLI flags:
  - `--logging-mode` (or `GATEWAY_OPERATOR_LOGGING_MODE` env var) to set the logging mode (`development` can be set
    for simplified logging).
  - `--validate-images` (or `GATEWAY_OPERATOR_VALIDATE_IMAGES` env var) to enable ControlPlane and DataPlane image
    validation (it's set by default to `true`).
  [#1435](https://github.com/kong/kong-operator/pull/1435)
- Add support for `-enforce-config` for `ControlPlane`'s `ValidatingWebhookConfiguration`.
  This allows to use operator's `ControlPlane` resources in AKS clusters.
  [#1512](https://github.com/kong/kong-operator/pull/1512)
- `KongRoute` can be migrated from serviceless to service bound and vice versa.
  [#1492](https://github.com/kong/kong-operator/pull/1492)
- Add `KonnectCloudGatewayTransitGateway` controller to support managing Konnect
  transit gateways.
  [#1489](https://github.com/kong/kong-operator/pull/1489)
- Added support for setting `PodDisruptionBudget` in `GatewayConfiguration`'s `DataPlane` options.
  [#1526](https://github.com/kong/kong-operator/pull/1526)
- Added `spec.watchNamespace` field to `ControlPlane` and `GatewayConfiguration` CRDs
  to allow watching resources only in the specified namespace.
  When `spec.watchNamespace.type=list` is used, each specified namespace requires
  a `WatchNamespaceGrant` that allows the `ControlPlane` to watch resources in the specified namespace.
  Aforementioned list is extended with `ControlPlane`'s own namespace which doesn't
  require said `WatchNamespaceGrant`.
  [#1388](https://github.com/kong/kong-operator/pull/1388)
  [#1410](https://github.com/kong/kong-operator/pull/1410)
  [#1555](https://github.com/kong/kong-operator/pull/1555)
  For more information on this please see: https://developer.konghq.com/operator/reference/control-plane-watch-namespaces/#controlplane-s-watchnamespaces-field
- Implemented `Mirror` and `Origin` `KonnectGatewayControlPlane`s.
  [#1496](https://github.com/kong/kong-operator/pull/1496)

### Changes

- Deduce `KonnectCloudGatewayDataPlaneGroupConfiguration` region based on the attached
  `KonnectAPIAuthConfiguration` instead of using a hardcoded `eu` value.
  [#1409](https://github.com/kong/kong-operator/pull/1409)
- Support `NodePort` as ingress service type for `DataPlane`
  [#1430](https://github.com/kong/kong-operator/pull/1430)
- Allow setting `NodePort` port number for ingress service for `DataPlane`.
  [#1516](https://github.com/kong/kong-operator/pull/1516)
- Updated `kubernetes-configuration` dependency for adding `scale` subresource for `DataPlane` CRD.
  [#1523](https://github.com/kong/kong-operator/pull/1523)
- Bump `kong/kubernetes-configuration` dependency to v1.4.0
  [#1574](https://github.com/kong/kong-operator/pull/1574)

### Fixes

- Fix setting the defaults for `GatewayConfiguration`'s `ReadinessProbe` when only
  timeouts and/or delays are specified. Now the HTTPGet field is set to `/status/ready`
  as expected with the `Gateway` scenario.
  [#1395](https://github.com/kong/kong-operator/pull/1395)
- Fix ingress service name not being applied when using `GatewayConfiguration`.
  [#1515](https://github.com/kong/kong-operator/pull/1515)
- Fix ingress service port name setting.
  [#1524](https://github.com/kong/kong-operator/pull/1524)

## 1.5.1

**Release date**: 2025-04-01

### Added

- Add `namespacedRef` support for referencing networks in `KonnectCloudGatewayDataPlaneGroupConfiguration`
  [#1425](https://github.com/kong/kong-operator/pull/1425)
- Set `ControlPlaneRefValid` condition to false when reference to `KonnectGatewayControlPlane` is invalid
  [#1421](https://github.com/kong/kong-operator/pull/1421)

### Changes

- Deduce `KonnectCloudGatewayDataPlaneGroupConfiguration` region based on the attached
  `KonnectAPIAuthConfiguration` instead of using a hardcoded `eu` value.
  [#1417](https://github.com/kong/kong-operator/pull/1417)
- Bump `kong/kubernetes-configuration` dependency to v1.3.

## 1.5.0

**Release date**: 2025-03-11

### Breaking Changes

- Added check of whether using `Secret` in another namespace in `AIGateway`'s
  `spec.cloudProviderCredentials` is allowed. If the `AIGateway` and the `Secret`
  referenced in `spec.cloudProviderCredentials` are not in the same namespace,
  there MUST be a `ReferenceGrant` in the namespace of the `Secret` that allows
  the `AIGateway`s to reference the `Secret`.
  This may break usage of `AIGateway`s that is already using `Secret` in
  other namespaces as AI cloud provider credentials.
  [#1161](https://github.com/kong/kong-operator/pull/1161)
- Migrate KGO CRDs to the kubernetes-configuration repo.
  With this migration process, we have removed the `api` and `pkg/clientset` from the KGO repo.
  This is a breaking change which requires manual action for projects that use operator's Go APIs.
  In order to migrate please use the import paths from the [kong/kubernetes-configuration][kubernetes-configuration] repo instead.
  For example:
  `github.com/kong/kong-operator/api/v1beta1` becomes
  `github.com/kong/kubernetes-configuration/api/gateway-operator/v1beta1`.
  [#1148](https://github.com/kong/kong-operator/pull/1148)
- Support for the `konnect-extension.gateway-operator.konghq.com` CRD has been interrupted. The new
  API `konnect-extension.konnect.konghq.com` must be used instead. The migration path is described in
  the [Kong documentation](https://developer.konghq.com/operator/konnect/reference/migrate-1.4-1.5/).
  [#1183](https://github.com/kong/kong-operator/pull/1183)
- Migrate KGO CRDs conditions to the kubernetes-configuration repo.
  With this migration process, we have moved all conditions from the KGO repo to [kubernetes-configuration][kubernetes-configuration].
  This is a breaking change which requires manual action for projects that use operator's Go conditions types.
  In order to migrate please use the import paths from the [kong/kubernetes-configuration][kubernetes-configuration] repo instead.
  [#1281](https://github.com/kong/kong-operator/pull/1281)
  [#1305](https://github.com/kong/kong-operator/pull/1305)
  [#1306](https://github.com/kong/kong-operator/pull/1306)
  [#1318](https://github.com/kong/kong-operator/pull/1318)

[kubernetes-configuration]: https://github.com/Kong/kubernetes-configuration

### Added

- Added `Name` field in `ServiceOptions` to allow specifying name of the
  owning service. Currently specifying ingress service of `DataPlane` is
  supported.
  [#966](https://github.com/kong/kong-operator/pull/966)
- Added support for global plugins with `KongPluginBinding`'s `scope` field.
  The default value is `OnlyTargets` which means that the plugin will be
  applied only to the targets specified in the `targets` field. The new
  alternative is `GlobalInControlPlane` that will make the plugin apply
  globally in a control plane.
  [#1052](https://github.com/kong/kong-operator/pull/1052)
- Added `-cluster-ca-key-type` and `-cluster-ca-key-size` CLI flags to allow
  configuring cluster CA private key type and size. Currently allowed values:
  `rsa` and `ecdsa` (default).
  [#1081](https://github.com/kong/kong-operator/pull/1081)
- The `GatewayClass` Accepted Condition is set to `False` with reason `InvalidParameters`
  in case the `.spec.parametersRef` field is not a valid reference to an existing
  `GatewayConfiguration` object.
  [#1021](https://github.com/kong/kong-operator/pull/1021)
- The `SupportedFeatures` field is properly set in the `GatewayClass` status.
  It requires the experimental version of Gateway API (as of v1.2.x) installed in
  your cluster, and the flag `--enable-gateway-api-experimental` set.
  [#1010](https://github.com/kong/kong-operator/pull/1010)
- Added support for `KongConsumer` `credentials` in Konnect entities support.
  Users can now specify credentials for `KongConsumer`s in `Secret`s and reference
  them in `KongConsumer`s' `credentials` field.
  - `basic-auth` [#1120](https://github.com/kong/kong-operator/pull/1120)
  - `key-auth` [#1168](https://github.com/kong/kong-operator/pull/1168)
  - `acl` [#1187](https://github.com/kong/kong-operator/pull/1187)
  - `jwt` [#1208](https://github.com/kong/kong-operator/pull/1208)
  - `hmac` [#1222](https://github.com/kong/kong-operator/pull/1222)
- Added prometheus metrics for Konnect entity operations in the metrics server:
  - `gateway_operator_konnect_entity_operation_count` for number of operations.
  - `gateway_operator_konnect_entity_operation_duration_milliseconds` for duration of operations.
  [#953](https://github.com/kong/kong-operator/pull/953)
- Added support for `KonnectCloudGatewayNetwork` CRD which can manage Konnect
  Cloud Gateway Network entities.
  [#1136](https://github.com/kong/kong-operator/pull/1136)
- Reconcile affected `KonnectExtension`s when the `Secret` used as Dataplane
  certificate is modified. A secret must have the `konghq.com/konnect-dp-cert`
  label to trigger the reconciliation.
  [#1250](https://github.com/kong/kong-operator/pull/1250)
- When the `DataPlane` is configured in Konnect, the `/status/ready` endpoint
  is set as the readiness probe.
  [#1235](https://github.com/kong/kong-operator/pull/1253)
- Added support for `KonnectDataPlaneGroupConfiguration` CRD which can manage Konnect
  Cloud Gateway DataPlane Group configurations entities.
  [#1186](https://github.com/kong/kong-operator/pull/1186)
- Supported `KonnectExtension` to attach to Konnect control planes by setting
  namespace and name of `KonnectGatewayControlPlane` in `spec.konnectControlPlane`.
  [#1254](https://github.com/kong/kong-operator/pull/1254)
- Added support for `KonnectExtension`s on `ControlPlane`s.
  [#1262](https://github.com/kong/kong-operator/pull/1262)
- Added support for `KonnectExtension`'s `status` `controlPlaneRefs` and `dataPlaneRefs`
  fields.
  [#1297](https://github.com/kong/kong-operator/pull/1297)
- Added support for `KonnectExtension`s on `Gateway`s via `GatewayConfiguration`
  extensibility.
  [#1292](https://github.com/kong/kong-operator/pull/1292)
- Added `-enforce-config` flag to enforce the configuration of the `ControlPlane`
  and `DataPlane` `Deployment`s.
  [#1307](https://github.com/kong/kong-operator/pull/1307)
- Added Automatic secret provisioning for `KonnectExtension` certificates.
  [#1304](https://github.com/kong/kong-operator/pull/1304)

### Changed

- `KonnectExtension` does not require `spec.serverHostname` to be set by a user
  anymore - default is set to `konghq.com`.
  [#947](https://github.com/kong/kong-operator/pull/947)
- Support KIC 3.4
  [#972](https://github.com/kong/kong-operator/pull/972)
- Allow more than 1 replica for `ControlPlane`'s `Deployment` to support HA deployments of KIC.
  [#978](https://github.com/kong/kong-operator/pull/978)
- Removed support for the migration of legacy labels so upgrading the operator from 1.3 (or older) to 1.5.0,
  should be done through 1.4.1
  [#976](https://github.com/kong/kong-operator/pull/976)
- Move `ControlPlane` `image` validation to CRD CEL rules.
  [#984](https://github.com/kong/kong-operator/pull/984)
- Remove usage of `kube-rbac-proxy`.
  Its functionality of can be now achieved by using the new flag `--metrics-access-filter`
  (or a corresponding `GATEWAY_OPERATOR_METRICS_ACCESS_FILTER` env).
  The default value for the flag is `off` which doesn't restrict the access to the metrics
  endpoint. The flag can be set to `rbac` which will configure KGO to verify the token
  sent with the request.
  For more information on this migration please consult
  [kubernetes-sigs/kubebuilder#3907][kubebuilder_3907].
  [#956](https://github.com/kong/kong-operator/pull/956)
- Move `DataPlane` ports validation to `ValidationAdmissionPolicy` and `ValidationAdmissionPolicyBinding`.
  [#1007](https://github.com/kong/kong-operator/pull/1007)
- Move `DataPlane` db mode validation to CRD CEL validation expressions.
  With this change only the `KONG_DATABASE` environment variable directly set in
  the `podTemplateSpec` is validated. `EnvFrom` is not evaluated anymore for this validation.
  [#1049](https://github.com/kong/kong-operator/pull/1049)
- Move `DataPlane` promotion in progress validation to CRD CEL validation expressions.
  This is relevant for `DataPlane`s with BlueGreen rollouts enabled only.
  [#1054](https://github.com/kong/kong-operator/pull/1054)
- Move `DataPlane`'s rollout strategy validation of disallowed `AutomaticPromotion`
  to CRD CEL validation expressions.
  This is relevant for `DataPlane`s with BlueGreen rollouts enabled only.
  [#1056](https://github.com/kong/kong-operator/pull/1056)
- Move `DataPlane`'s rollout resource strategy validation of disallowed `DeleteOnPromotionRecreateOnRollout`
  to CRD CEL validation expressions.
  This is relevant for `DataPlane`s with BlueGreen rollouts enabled only.
  [#1065](https://github.com/kong/kong-operator/pull/1065)
- The `GatewayClass` Accepted Condition is set to `False` with reason `InvalidParameters`
  in case the `.spec.parametersRef` field is not a valid reference to an existing
  `GatewayConfiguration` object.
  [#1021](https://github.com/kong/kong-operator/pull/1021)
- Validating webhook is now disabled by default. At this point webhook doesn't
  perform any validations.
  These were all moved either to CRD CEL validation expressions or to the
  `ValidationAdmissionPolicy`.
  Flag remains in place to not cause a breaking change for users that rely on it.
  [#1066](https://github.com/kong/kong-operator/pull/1066)
- Remove `ValidatingAdmissionWebhook` from the operator.
  As of now, all the validations have been moved to CRD CEL validation expressions
  or to the `ValidationAdmissionPolicy`.
  All the flags that were configuring the webhook are now deprecated and do not
  have any effect.
  They will be removed in next major release.
  [#1100](https://github.com/kong/kong-operator/pull/1100)
- Konnect entities that are attached to a Konnect CP through a `ControlPlaneRef`
  do not get an owner relationship set to the `ControlPlane` anymore hence
  they are not deleted when the `ControlPlane` is deleted.
  [#1099](https://github.com/kong/kong-operator/pull/1099)
- Remove the owner relationship between `KongService` and `KongRoute`.
  [#1178](https://github.com/kong/kong-operator/pull/1178)
- Remove the owner relationship between `KongTarget` and `KongUpstream`.
  [#1279](https://github.com/kong/kong-operator/pull/1279)
- Remove the owner relationship between `KongCertificate` and `KongSNI`.
  [#1285](https://github.com/kong/kong-operator/pull/1285)
- Remove the owner relationship between `KongKey`s and `KongKeysSet`s and `KonnectGatewayControlPlane`s.
  [#1291](https://github.com/kong/kong-operator/pull/1291)
- Check whether an error from calling Konnect API is a validation error by
  HTTP status code in Konnect entity controller. If the HTTP status code is
  `400`, we consider the error as a validation error and do not try to requeue
  the Konnect entity.
  [#1226](https://github.com/kong/kong-operator/pull/1226)
- Credential resources used as Konnect entities that are attached to a `KongConsumer`
  resource do not get an owner relationship set to the `KongConsumer` anymore hence
  they are not deleted when the `KongConsumer` is deleted.
  [#1259](https://github.com/kong/kong-operator/pull/1259)

[kubebuilder_3907]: https://github.com/kubernetes-sigs/kubebuilder/discussions/3907

### Fixes

- Fix `DataPlane`s with `KonnectExtension` and `BlueGreen` settings. Both the Live
  and preview deployments are now customized with Konnect-related settings.
  [#910](https://github.com/kong/kong-operator/pull/910)
- Remove `RunAsUser` specification in jobs to create webhook certificates
  because Openshift does not specifying `RunAsUser` by default.
  [#964](https://github.com/kong/kong-operator/pull/964)
- Fix watch predicates for types shared between KGO and KIC.
  [#948](https://github.com/kong/kong-operator/pull/948)
- Fix unexpected error logs caused by passing an odd number of arguments to the logger
  in the `KongConsumer` reconciler.
  [#983](https://github.com/kong/kong-operator/pull/983)
- Fix checking status when using a `KonnectGatewayControlPlane` with KIC CP type
  as a `ControlPlaneRef`.
  [#1115](https://github.com/kong/kong-operator/pull/1115)
- Fix setting `DataPlane`'s readiness probe using `GatewayConfiguration`.
  [#1118](https://github.com/kong/kong-operator/pull/1118)
- Fix handling Konnect API conflicts.
  [#1176](https://github.com/kong/kong-operator/pull/1176)

## 1.4.2

**Release date**: 2025-01-23

### Fixes

- Bump `kong/kubernetes-configuration` dependency to v1.0.8 that fixes the issue with `spec.headers`
  in `KongRoute` CRD by aligning to the expected schema (instead of `map[string]string`, it should be
  `map[string][]string`).
  Please make sure you update the KGO channel CRDs accordingly in your cluster:
  `kustomize build github.com/Kong/kubernetes-configuration/config/crd/gateway-operator\?ref=v1.0.8 | kubectl apply -f -`
  [#1072](https://github.com/kong/kong-operator/pull/1072)

## 1.4.1

**Release date**: 2024-11-28

### Fixes

- Fix setting the `ServiceAccountName` for `DataPlane`'s `Deployment`.
  [#897](https://github.com/kong/kong-operator/pull/897)
- Fixed setting `ExternalTrafficPolicy` on `DataPlane`'s ingress `Service` when
  the requested value is empty.
  [#898](https://github.com/kong/kong-operator/pull/898)
- Set 0 members on `KonnectGatewayControlPlane` which type is set to group.
  [#896](https://github.com/kong/kong-operator/pull/896)
- Fixed a `panic` in `KonnectAPIAuthConfigurationReconciler` occurring when nil
  response was returned by Konnect API when fetching the organization information.
  [#901](https://github.com/kong/kong-operator/pull/901)
- Bump sdk-konnect-go version to 0.1.10 to fix handling global API endpoints.
  [#894](https://github.com/kong/kong-operator/pull/894)

## 1.4.0

**Release date**: 2024-10-31

### Added

- Proper `User-Agent` header is now set on outgoing HTTP requests.
  [#387](https://github.com/kong/kong-operator/pull/387)
- Introduce `KongPluginInstallation` CRD to allow installing custom Kong
  plugins distributed as container images.
  [#400](https://github.com/kong/kong-operator/pull/400), [#424](https://github.com/kong/kong-operator/pull/424), [#474](https://github.com/kong/kong-operator/pull/474), [#560](https://github.com/kong/kong-operator/pull/560), [#615](https://github.com/kong/kong-operator/pull/615), [#476](https://github.com/kong/kong-operator/pull/476)
- Extended `DataPlane` API with a possibility to specify `PodDisruptionBudget` to be
  created for the `DataPlane` deployments via `spec.resources.podDisruptionBudget`.
  [#464](https://github.com/kong/kong-operator/pull/464)
- Add `KonnectAPIAuthConfiguration` reconciler.
  [#456](https://github.com/kong/kong-operator/pull/456)
- Add support for Konnect tokens in `Secrets` in `KonnectAPIAuthConfiguration`
  reconciler.
  [#459](https://github.com/kong/kong-operator/pull/459)
- Add `KonnectControlPlane` reconciler.
  [#462](https://github.com/kong/kong-operator/pull/462)
- Add `KongService` reconciler for Konnect control planes.
  [#470](https://github.com/kong/kong-operator/pull/470)
- Add `KongUpstream` reconciler for Konnect control planes.
  [#593](https://github.com/kong/kong-operator/pull/593)
- Add `KongConsumer` reconciler for Konnect control planes.
  [#493](https://github.com/kong/kong-operator/pull/493)
- Add `KongRoute` reconciler for Konnect control planes.
  [#506](https://github.com/kong/kong-operator/pull/506)
- Add `KongConsumerGroup` reconciler for Konnect control planes.
  [#510](https://github.com/kong/kong-operator/pull/510)
- Add `KongCACertificate` reconciler for Konnect CA certificates.
  [#626](https://github.com/kong/kong-operator/pull/626)
- Add `KongCertificate` reconciler for Konnect Certificates.
  [#643](https://github.com/kong/kong-operator/pull/643)
- Added command line flags to configure the certificate generator job's images.
  [#516](https://github.com/kong/kong-operator/pull/516)
- Add `KongPluginBinding` reconciler for Konnect Plugins.
  [#513](https://github.com/kong/kong-operator/pull/513), [#535](https://github.com/kong/kong-operator/pull/535)
- Add `KongTarget` reconciler for Konnect Targets.
  [#627](https://github.com/kong/kong-operator/pull/627)
- Add `KongVault` reconciler for Konnect Vaults.
  [#597](https://github.com/kong/kong-operator/pull/597)
- Add `KongKey` reconciler for Konnect Keys.
  [#646](https://github.com/kong/kong-operator/pull/646)
- Add `KongKeySet` reconciler for Konnect KeySets.
  [#657](https://github.com/kong/kong-operator/pull/657)
- Add `KongDataPlaneClientCertificate` reconciler for Konnect DataPlaneClientCertificates.
  [#694](https://github.com/kong/kong-operator/pull/694)
- The `KonnectExtension` CRD has been introduced. Such a CRD can be attached
  to a `DataPlane` via the extensions field to have a konnect-flavored `DataPlane`.
  [#453](https://github.com/kong/kong-operator/pull/453),
  [#578](https://github.com/kong/kong-operator/pull/578),
  [#736](https://github.com/kong/kong-operator/pull/736)
- Entities created in Konnect are now labeled (or tagged for those that does not
  support labels) with origin Kubernetes object's metadata: `k8s-name`, `k8s-namespace`,
  `k8s-uid`, `k8s-generation`, `k8s-kind`, `k8s-group`, `k8s-version`.
  [#565](https://github.com/kong/kong-operator/pull/565)
- Add `KongService`, `KongRoute`, `KongConsumer`, and `KongConsumerGroup` watchers
  in the `KongPluginBinding` reconciler.
  [#571](https://github.com/kong/kong-operator/pull/571)
- Annotating the following resource with the `konghq.com/plugins` annotation results in
  the creation of a managed `KongPluginBinding` resource:
  - `KongService` [#550](https://github.com/kong/kong-operator/pull/550)
  - `KongRoute` [#644](https://github.com/kong/kong-operator/pull/644)
  - `KongConsumer` [#676](https://github.com/kong/kong-operator/pull/676)
  - `KongConsumerGroup` [#684](https://github.com/kong/kong-operator/pull/684)
  These `KongPluginBinding`s are taken by the `KongPluginBinding` reconciler
  to create the corresponding plugin objects in Konnect.
- `KongConsumer` associated with `ConsumerGroups` is now reconciled in Konnect by removing/adding
  the consumer from/to the consumer groups.
  [#592](https://github.com/kong/kong-operator/pull/592)
- Add support for `KongConsumer` credentials:
  - basic-auth [#625](https://github.com/kong/kong-operator/pull/625)
  - API key [#635](https://github.com/kong/kong-operator/pull/635)
  - ACL [#661](https://github.com/kong/kong-operator/pull/661)
  - JWT [#678](https://github.com/kong/kong-operator/pull/678)
  - HMAC Auth [#687](https://github.com/kong/kong-operator/pull/687)
- Add support for `KongRoute`s bound directly to `KonnectGatewayControlPlane`s (serviceless routes).
  [#669](https://github.com/kong/kong-operator/pull/669)
- Allow setting `KonnectGatewayControlPlane`s group membership
  [#697](https://github.com/kong/kong-operator/pull/697)
- Apply Konnect-related customizations to `DataPlane`s that properly reference `KonnectExtension`
  resources.
  [#714](https://github.com/kong/kong-operator/pull/714)
- The KonnectExtension functionality is enabled only when the `--enable-controller-konnect`
  flag or the `GATEWAY_OPERATOR_ENABLE_CONTROLLER_KONNECT` env var is set.
  [#738](https://github.com/kong/kong-operator/pull/738)

### Fixes

- Fixed `ControlPlane` cluster wide resources not migrating to new ownership labels
  (introduced in 1.3.0) when upgrading the operator from 1.2 (or older) to 1.3.0.
  [#369](https://github.com/kong/kong-operator/pull/369)
- Requeue instead of reporting an error when a finalizer removal yields a conflict.
  [#454](https://github.com/kong/kong-operator/pull/454)
- Requeue instead of reporting an error when a GatewayClass status update yields a conflict.
  [#612](https://github.com/kong/kong-operator/pull/612)
- Guard object counters with checks whether CRDs for them exist
  [#710](https://github.com/kong/kong-operator/pull/710)
- Do not reconcile Gateways nor assign any finalizers when the referred GatewayClass is not supported.
  [#711](https://github.com/kong/kong-operator/pull/711)
- Fixed setting `ExternalTrafficPolicy` on `DataPlane`'s ingress `Service` during update and patch operations.
  [#750](https://github.com/kong/kong-operator/pull/750)
- Fixed setting `ExternalTrafficPolicy` on `DataPlane`'s ingress `Service`.
  Remove the default value (`Cluster`). Prevent setting this field for `ClusterIP` `Service`s.
  [#812](https://github.com/kong/kong-operator/pull/812)

### Changes

- Default version of `ControlPlane` is bumped to 3.3.1
  [#580](https://github.com/kong/kong-operator/pull/580)
- Default version of `DataPlane` is bumped to 3.8.0
  [#572](https://github.com/kong/kong-operator/pull/572)
- Gateway API has been bumped to v1.2.0
  [#674](https://github.com/kong/kong-operator/pull/674)

## 1.3.0

**Release date**: 2024-06-24

### Added

- Add `ExternalTrafficPolicy` to `DataPlane`'s `ServiceOptions`
  [#241](https://github.com/kong/kong-operator/pull/241)

### Breaking Changes

- Changes project layout to match `kubebuilder` `v4`. Some import paths (due to dir renames) have changed
  `apis` -> `api` and `controllers` -> `controller`.
  [#84](https://github.com/kong/kong-operator/pull/84)

### Changes

- `Gateway` do not have their `Ready` status condition set anymore.
  This aligns with Gateway API and its conformance test suite.
  [#246](https://github.com/kong/kong-operator/pull/246)
- `Gateway`s' listeners now have their `attachedRoutes` count filled in in status.
  [#251](https://github.com/kong/kong-operator/pull/251)
- Detect when `ControlPlane` has its admission webhook disabled via
  `CONTROLLER_ADMISSION_WEBHOOK_LISTEN` environment variable and ensure that
  relevant webhook resources are not created/deleted.
  [#326](https://github.com/kong/kong-operator/pull/326)
- The `OwnerReferences` on cluster-wide resources to indicate their owner are now
  replaced by a proper set of labels to identify `kind`, `namespace`, and
  `name` of the owning object.
  [#259](https://github.com/kong/kong-operator/pull/259)
- Default version of `ControlPlane` is bumped to 3.2.0
  [#327](https://github.com/kong/kong-operator/pull/327)

### Fixes

- Fix enforcing up to date `ControlPlane`'s `ValidatingWebhookConfiguration`
  [#225](https://github.com/kong/kong-operator/pull/225)

