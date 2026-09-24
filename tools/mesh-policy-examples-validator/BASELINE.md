# Provider-schema baseline

The recorded state of the provider-schema rule over a full mesh build:
`KONG_PRODUCTS=mesh exe/build` into a clean `dist/`, then
`node index.js --skip external-services@v2` from the tool directory. A
`--terraform-validate=gate` run reports the same findings as gating; in the
default `warn` mode every remaining finding is advisory and the run exits
zero. The grammar rule reports zero findings on every published terraform
block.

This record is the input for the follow-up change that flips the default mode
to `gate`: fix one of the classes in the list that follows, rerun, and remove
it from this list.

## Skipped: external-services@v2

The pinned provider (`kong/konnect-beta` 0.22.0) has no resource for the legacy
`ExternalService` policy. `konnect_mesh_external_service` models
`MeshExternalService` (spec: match, endpoints, tls), not the legacy policy
(tags, networking), so no rendered block for it can validate. The same pages
also carry a pre-existing Kubernetes-tab transform defect (`spec:` renders
empty on both v2 external-services examples), which the skip also keeps out of
the run; that defect needs its own fix in the Kubernetes renderer.

## Int-or-string wrapper attributes (19 findings)

The provider models CRD int-or-string fields as wrapper objects, so the plain
rendered scalar cannot validate:

- `meshfaultinjection` (7): `abort.percentage`, `delay.percentage` expect
  `{ integer = ... }` or `{ str = ... }`.
- `meshcircuitbreaker` (2): `outlier_detection.detectors.success_rate.standard_deviation_factor`
  expects the same wrapper.
- `meshloadbalancingstrategy` (2): `percentage` in the strategy load
  balancers.
- `meshtrace` (5): `general.sampled_percentage` and related fields.
- `meshaccesslog` (2), `meshhttproute` (1): the same wrapper shape on their
  percentage fields.

Fixing this needs the Terraform renderer to know which fields the provider
models as wrappers, which the schema-agnostic renderer does not have today.

## JSON string patches (2 findings)

`meshproxypatch` examples `adjust-a-timeout` (latest) and
`time-out-adjustment` (v2) set `jsonPatches[].value: 15s`. The provider
validates the value as JSON (RFC 7159) and `15s` is not a JSON value; the
Kuma CRD accepts it. Fixing the source example would also change the
Kubernetes and Universal tabs, which this change does not touch.
