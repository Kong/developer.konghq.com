---
title: "Check readiness for {{site.mesh_product_name}} 3.x"
description: "Audit a running {{site.mesh_product_name}} 2.x deployment for changes required before upgrading to {{site.mesh_product_name}} 3.x."
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/
tags:
  - migration
  - upgrade
related_resources:
  - text: Upgrade {{site.mesh_product_name}}
    url: /mesh/upgrade/
  - text: Migrate mesh mTLS to MeshIdentity
    url: /mesh/migrate-mtls-to-meshidentity/
  - text: Migrate zone proxies to {{site.mesh_product_name}} 3.x
    url: /mesh/migrate-zone-proxies-to-3/
  - text: Migrate policies to {{site.mesh_product_name}} 3.x
    url: /mesh/migrate-policies-to-3/
---

Before upgrading to {{site.mesh_product_name}} 3.x, run the {{site.mesh_product_name}} 3.x readiness checker against your
2.x control plane. The checker finds configuration that must change before the upgrade and writes
a self-contained HTML report that you can keep with your migration records.

Run it early to establish the migration work, then run it again on the latest supported 2.14 patch
after making the changes. Do not upgrade the first zone until the final report has no blockers or
coverage gaps and you have completed its manual checks.

{:.warning}
> A clean report covers only what the checker can read from the control plane. It does not prove
> that DNS, firewalls, certificates, gateways, external systems, or application traffic behave as
> intended. Complete the traffic validation in the relevant migration guides before upgrading.

## What the checker finds

The checker audits the control plane API for:

- Control planes and data plane proxies that are not on versions compatible with the upgrade.
- Legacy policies, services, gateways, zone proxies, and other resources removed in 3.x.
- `Mesh` settings replaced by MeshIdentity, MeshTrust, MeshMetric, MeshTrace, MeshAccessLog, and
  other resources.
- Policy target references, directions, and fields that 3.x removes or interprets differently.
- Control plane settings that must change before the upgrade.
- Resource names that do not meet the naming requirements in 3.x.

The report also lists checks that cannot be completed through the control plane API. Treat those
items as part of the migration, even when the automated findings are clear.

## Download the checker

These instructions use [`kong-mesh-v3-preflight` version `v0.6.6`](https://github.com/Kong/kong-mesh-v3-readiness/releases/tag/v0.6.6).

{% navtabs "readiness-checker-download" %}
{% navtab "macOS" %}

```sh
VERSION=v0.6.6
case "$(uname -m)" in
  arm64) ARCH=arm64 ;;
  x86_64) ARCH=amd64 ;;
  *) echo "Unsupported architecture: $(uname -m)"; exit 1 ;;
esac
ARCHIVE="kong-mesh-v3-preflight_darwin_${ARCH}.tar.gz"
curl -fLO "https://github.com/Kong/kong-mesh-v3-readiness/releases/download/${VERSION}/${ARCHIVE}"
curl -fLO "https://github.com/Kong/kong-mesh-v3-readiness/releases/download/${VERSION}/checksums.txt"
grep " ${ARCHIVE}$" checksums.txt | shasum -a 256 -c -
tar -xzf "${ARCHIVE}"
sudo install kong-mesh-v3-preflight /usr/local/bin/kong-mesh-v3-preflight
```

{% endnavtab %}
{% navtab "Linux" %}

```sh
VERSION=v0.6.6
case "$(uname -m)" in
  aarch64|arm64) ARCH=arm64 ;;
  x86_64) ARCH=amd64 ;;
  *) echo "Unsupported architecture: $(uname -m)"; exit 1 ;;
esac
ARCHIVE="kong-mesh-v3-preflight_linux_${ARCH}.tar.gz"
curl -fLO "https://github.com/Kong/kong-mesh-v3-readiness/releases/download/${VERSION}/${ARCHIVE}"
curl -fLO "https://github.com/Kong/kong-mesh-v3-readiness/releases/download/${VERSION}/checksums.txt"
grep " ${ARCHIVE}$" checksums.txt | sha256sum -c -
tar -xzf "${ARCHIVE}"
sudo install kong-mesh-v3-preflight /usr/local/bin/kong-mesh-v3-preflight
```

{% endnavtab %}
{% endnavtabs %}

Confirm that the binary is available and reports version `v0.6.6`:

```sh
kong-mesh-v3-preflight --version
```

You can also build the checker with Go. See the
[{{site.mesh_product_name}} 3.x readiness repository](https://github.com/Kong/kong-mesh-v3-readiness) for the source and
the complete flag reference.

## Choose the control plane to audit

- **Multi-zone:** Connect to the global control plane. A global audit checks its connected zone
  control plane versions and the zone configuration reported through insights, so use one report
  as the estate-wide starting point.
- **Single-zone:** Connect directly to the zone control plane.
- **One mesh:** Add `--mesh MESH_NAME` when investigating a mesh. Do not use a mesh-scoped report
  as the final estate-wide gate.

The checker reads `GET /config` to assess important control plane settings. In
{{site.mesh_product_name}}, that endpoint is protected by RBAC, so use a token that can read it.
Without the token, the checker records a coverage gap and returns an inconclusive result.

Export the control plane API address and a token that can read `GET /config`. Replace
`YOUR_TOKEN` with your token:

```sh
export KUMA_CONTROL_PLANE_URL='http://localhost:5681'
export KUMA_TOKEN='YOUR_TOKEN'
```

## Run the audit

If the Kubernetes control plane API is not already reachable, forward its API port in one
terminal:

```sh
kubectl -n {{site.mesh_namespace}} port-forward svc/{{site.mesh_cp_name}} 5681:5681
```

In another terminal, create the report:

```sh
kong-mesh-v3-preflight \
  --address "$KUMA_CONTROL_PLANE_URL" \
  --token "$KUMA_TOKEN" \
  --output mesh-3-readiness.html
```

Open `mesh-3-readiness.html`, then work through the automated findings and manual checks.

For a large deployment, the checker stops admitting resource items after its configured read
limit. A report that reaches that limit is inconclusive. Raise `--max-resource-reads` and rerun it
until every required collection is covered.

To compare versions, the checker looks up the latest 2.14 patch from the GitHub releases API. If
the machine running it can't reach GitHub, such as in an air-gapped environment, that check
becomes a coverage gap and the report is inconclusive. Pass the latest 2.14 patch version with
`--latest-version` instead.

Inspection of data plane Envoy configuration is disabled by default because it requires an
additional read for each proxy. If the deployment might use the legacy Envoy DNS filter, add
`--inspect-dataplanes NUMBER` and choose enough representative proxies to cover where that filter
could be configured. An audit without this option does not check for that filter.

## Interpret the result

The command exits with `0` whenever it produces a report, even when the report contains blockers
or coverage gaps. It exits with `2` only when the audit can't run, for example because of a
connection, authentication, or address error.

The report's status describes the audit result:

{% table %}
columns:
  - title: Status
    key: status
  - title: Meaning
    key: meaning
  - title: Next action
    key: next
rows:
  - status: "`clean`"
    meaning: "No automated blocker or coverage gap was found."
    next: "Complete the report's manual checks and validate traffic."
  - status: "`blockers`"
    meaning: "The checker found one or more upgrade blockers."
    next: "Resolve every blocker, then rerun the checker."
  - status: "`inconclusive`"
    meaning: "The audit is incomplete."
    next: "Resolve every coverage gap, then rerun the checker."
{% endtable %}

Use the finding type to continue the migration:

{% table %}
columns:
  - title: Finding
    key: finding
  - title: Continue with
    key: continue
rows:
  - finding: "Unsupported control plane or data plane version"
    continue: "[Upgrade {{site.mesh_product_name}}](/mesh/upgrade/) and the [version-specific upgrade notes](/mesh/version-specific-upgrade-notes/)"
  - finding: "`Mesh.mtls`, identity, trust, or identity-based permission"
    continue: "[Migrate mesh mTLS to MeshIdentity](/mesh/migrate-mtls-to-meshidentity/)"
  - finding: "`ZoneIngress`, `ZoneEgress`, or legacy zone routing"
    continue: "[Migrate zone proxies to {{site.mesh_product_name}} 3.x](/mesh/migrate-zone-proxies-to-3/)"
  - finding: "Legacy policy or incompatible policy field"
    continue: "[Migrate policies to {{site.mesh_product_name}} 3.x](/mesh/migrate-policies-to-3/)"
  - finding: "`ExternalService`"
    continue: "[MeshExternalService](/mesh/meshexternalservice/) and the [zone-proxy migration](/mesh/migrate-zone-proxies-to-3/)"
  - finding: "Legacy gateway resource"
    continue: "[Application ingress](/mesh/application-ingress/)"
  - finding: "Legacy service discovery or service selection"
    continue: "[MeshService](/mesh/meshservice/)"
{% endtable %}

One finding can require changes from more than one guide. For example, replacing `Mesh.mtls`
also requires identity-based MeshTrafficPermission rules, while MeshExternalService clients need
mesh-scoped zone egress before they switch to MeshIdentity.

## Use the final report as an upgrade gate

After completing the migrations, run an estate-wide audit again while every control plane is
still running the latest supported 2.14 patch. Before upgrading the first zone, confirm that:

- The report status is `clean`.
- The report contains no coverage gaps.
- Every manual check in the report is complete.
- The identity, authorization, routing, resilience, telemetry, cross-zone, and external-service
  paths relevant to the deployment pass their traffic tests.

Keep the final HTML report with the exported 2.x configuration and the deployment's migration
record. The checker audits a 2.x control plane; use the product validation steps after each control
plane upgrade rather than rerunning the preflight tool against 3.x.

## Generate a report in CI

Use JSON when the audit needs to gate an automated migration workflow. Because the command exits
with `0` even when it finds blockers, gate the workflow on the report's `status` field rather than
on the exit code:

```sh
kong-mesh-v3-preflight \
  --address "$KUMA_CONTROL_PLANE_URL" \
  --token "$KUMA_TOKEN" \
  --format json \
  --output mesh-3-readiness.json
```

You can render the captured data as HTML later without reconnecting to the control plane:

```sh
kong-mesh-v3-preflight \
  --from-json mesh-3-readiness.json \
  --format html \
  --output mesh-3-readiness.html
```
