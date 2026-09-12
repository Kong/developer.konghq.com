---
title: Deploy a Universal control plane
description: Running kuma-cp outside Kubernetes — modes, stores, and joining a zone to a global control plane.
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/
tags:
  - deployment-topologies
  - service-mesh
related_resources:
  - text: "{{site.mesh_product_name}} on Universal"
    url: /mesh/universal/
  - text: Deploy a Universal data plane proxy
    url: /mesh/universal-data-plane/
  - text: "{{site.mesh_product_name}} CLI"
    url: /mesh/cli/
  - text: MeshIdentity
    url: /mesh/policies/meshidentity/
---

A Universal control plane is `kuma-cp` running with `environment: universal` against a store
that is not Kubernetes. This page covers choosing a mode and a store, and joining a zone to a
global control plane.

For what Universal changes about running workloads, see
[{{site.mesh_product_name}} on Universal](/mesh/universal/).

## Modes

{% table %}
columns:
  - title: "`mode`"
    key: mode
  - title: What it is
    key: what
rows:
  - mode: "`zone`"
    what: "A control plane that serves data plane proxies. The default, and what a single-zone deployment runs."
  - mode: "`global`"
    what: "A control plane that holds policy and federates it to zones over KDS. It serves no proxies of its own."
{% endtable %}

`standalone` is removed. It behaved identically to `zone`, so rename it: `kuma-cp` fails config
validation at startup otherwise, and the Helm chart fails at template time.

{:.warning}
> A Global control plane cannot run on Kubernetes. `mode: global` is rejected with
> `environment: kubernetes`, and rejected again with `store.type: kubernetes`. It must run
> `environment: universal` against a non-Kubernetes store — PostgreSQL in any real deployment —
> even if the `kuma-cp` process itself is deployed onto a Kubernetes cluster. Zone control
> planes on Kubernetes are unaffected.

## Stores

{% table %}
columns:
  - title: "`store.type`"
    key: type
  - title: Use
    key: use
rows:
  - type: "`postgres`"
    use: "Production. The only store that survives a restart and supports more than one control plane instance."
  - type: "`memory`"
    use: "A single instance, for trying things out. Everything is lost when the process stops."
  - type: "`kubernetes`"
    use: "Only for a zone control plane running inside a cluster. Not valid for `mode: global`."
{% endtable %}

PostgreSQL is configured under `store.postgres`, or through the matching environment variables:

```yaml
store:
  type: postgres
  postgres:
    host: postgres.internal
    port: 5432
    user: kuma
    password: ${POSTGRES_PASSWORD}
    dbName: kuma
    tls:
      mode: verifyCa
```

Every field has a `KUMA_STORE_POSTGRES_*` equivalent — `KUMA_STORE_POSTGRES_HOST`,
`_PORT`, `_USER`, `_PASSWORD`, `_DB_NAME` — which is usually how the password is supplied.

## A single zone

The smallest useful configuration is a zone control plane with a store:

```yaml
environment: universal
mode: zone
store:
  type: postgres
  postgres:
    host: postgres.internal
    port: 5432
    user: kuma
    dbName: kuma
```

```sh
kuma-cp run --config-file kuma-cp.yaml
```

The control plane exposes the API on 5681 and the data plane server on 5678. Proxies connect to
the second; `kongctl` and the GUI talk to the first.

## Joining a zone to a global control plane

A zone joins by naming itself and pointing at the global control plane's KDS address:

```yaml
environment: universal
mode: zone
multizone:
  zone:
    name: zone-1
    globalAddress: grpcs://global.internal:5685
    kds:
      rootCaFile: /etc/kuma/global-ca.pem
store:
  type: postgres
  postgres:
    host: postgres.internal
    port: 5432
    user: kuma
    dbName: kuma
```

The zone `name` is mandatory and has to be a valid RFC 1035 DNS label — lower-case letters,
digits and dashes, starting with a letter. It is not cosmetic: the name is stamped onto every
resource the zone owns, appears in KRIs, and is what a
[MeshMultiZoneService](/mesh/meshmultizoneservice/) selects zones by.

`globalAddress` takes `grpc://` or `grpcs://`; anything else is rejected at startup. Use
`grpcs` and give `kds.rootCaFile` the CA that signed the global control plane's certificate.

The global control plane itself needs no zone block:

```yaml
environment: universal
mode: global
store:
  type: postgres
  postgres:
    host: postgres-global.internal
    port: 5432
    user: kuma
    dbName: kuma
```

## How proxies authenticate

`dpServer.authn.dpProxy.type` decides how the data plane server authenticates a proxy. It is set
from the environment automatically: `serviceAccountToken` on Kubernetes, `dpToken` on
Universal.

On Universal that means every proxy — including the zone proxies that carry cross-zone traffic —
presents a **dataplane token**:

```sh
kongctl create mesh dataplane-token --name backend-01 --valid-for 24h > /etc/kuma/token
```

Zone tokens are no longer accepted by the data plane server. If you previously relied on
`dpServer.authn.zoneProxy.type: none` to let zone proxies connect without one, they need a
dataplane token now. `dpServer.authn.zoneProxy` no longer affects anything.

See [Deploy a Universal data plane proxy](/mesh/universal-data-plane/) for binding a token
narrowly enough to be worth having.

## What the control plane generates

A zone control plane on a non-Kubernetes store generates `MeshService` and `Workload` resources
from the `kuma.io/workload` label on each `Dataplane`, and allocates VIPs and hostnames for
them.

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Controls
    key: controls
rows:
  - setting: "`KUMA_MESH_SERVICE_GENERATION_INTERVAL`"
    controls: "How often `MeshService` resources are reconciled from `Dataplane` labels. 2s by default; `0` disables generation and hands you the resources to manage."
  - setting: "`KUMA_MESH_SERVICE_DELETION_GRACE_PERIOD`"
    controls: "How long a generated `MeshService` survives after its last proxy disappears. 1h by default."
  - setting: "`KUMA_IPAM_MESH_SERVICE_CIDR`"
    controls: "The VIP range for `MeshService`. `241.0.0.0/8` by default."
  - setting: "`KUMA_IPAM_MESH_EXTERNAL_SERVICE_CIDR`"
    controls: "The VIP range for `MeshExternalService`. `242.0.0.0/8` by default."
{% endtable %}

Neither generator runs on a Global control plane, or against a Kubernetes store.

## Issuing identities

A mesh issues workload identities through [MeshIdentity](/mesh/policies/meshidentity/), the same
on Universal as on Kubernetes. What differs is the default SPIFFE path: `/workload/{workload}`
on Universal, against `/ns/{namespace}/sa/{service-account}` on Kubernetes. The workload name
comes from the `kuma.io/workload` label on the `Dataplane`.

Without a `MeshIdentity`, proxies get no certificate and therefore no mTLS —
`Mesh.mtls` is removed in 3.0 and is no longer an identity source.

## Monitoring

MADS, the Monitoring Assignment Discovery Service Prometheus uses to discover proxies, runs
**only** in Universal mode. It no longer starts on a Kubernetes control plane whatever
`KUMA_MONITORING_ASSIGNMENT_SERVER_ENABLED` says, and `controlPlane.madsServer.enabled` applies
only when `controlPlane.environment` is `universal`.

So on Universal, MADS on port 5676 remains the way Prometheus finds proxies to scrape.
