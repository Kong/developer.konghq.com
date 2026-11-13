---
title: Universal control plane
description: "Running kuma-cp outside Kubernetes: modes, stores, and joining a zone to a global control plane."
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
  - text: Universal data plane
    url: /mesh/universal-data-plane/
  - text: "{{site.mesh_product_name}} CLI"
    url: /mesh/cli/
  - text: MeshIdentity
    url: /mesh/policies/meshidentity/
  - text: "Concepts: Control plane"
    url: /mesh/concepts/#control-plane
  - text: Architecture overview
    url: /mesh/architecture-overview/
min_version:
  mesh: '3.0'
---

A Universal control plane is `kuma-cp` running with `environment: universal` against a store
that isn't Kubernetes. This page covers choosing a mode and a store, and joining a zone to a
global control plane.

For more information about Universal mode, see
[{{site.mesh_product_name}} on Universal](/mesh/universal/).

## Modes

The following modes are available when deploying a Universal control plane:

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

A global control plane cannot run on Kubernetes. `mode: global` is rejected with
`environment: kubernetes`, and rejected again with `store.type: kubernetes`. It must run
`environment: universal` against a non-Kubernetes store (PostgreSQL in any real deployment),
even if the `kuma-cp` process itself is deployed onto a Kubernetes cluster.

## Stores

The following store types are available when deploying a Universal control plane:

{% table %}
columns:
  - title: "`store.type`"
    key: type
  - title: Use case
    key: use
rows:
  - type: "`postgres`"
    use: "Production. The only store that survives a restart and supports more than one control plane instance."
  - type: "`memory`"
    use: "A single instance, for trying things out. Everything is lost when the process stops."
  - type: "`kubernetes`"
    use: "Only for a zone control plane running inside a cluster. Not valid for `mode: global`."
{% endtable %}

Configure PostgreSQL under `store.postgres`, or through the matching environment variables:

```yaml
store:
  type: postgres
  postgres:
    host: postgres.internal
    port: 5432
    user: kuma
    dbName: kuma
    tls:
      mode: verifyCa
      caPath: /etc/kuma/postgres-ca.pem
```

`verifyCa` and `verifyFull` need `caPath`; without it, startup fails with `CAPath cannot be
empty`.

Every field has a `KUMA_STORE_POSTGRES_*` equivalent: `KUMA_STORE_POSTGRES_HOST`,
`_PORT`, `_USER`, `_PASSWORD`, `_DB_NAME`. Provide the password with
`KUMA_STORE_POSTGRES_PASSWORD`. The config file doesn't expand environment variables, so a
value like `${POSTGRES_PASSWORD}` is used literally.

## Single-zone configuration

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

Migrate the database:

```sh
kuma-cp migrate up --config-file kuma-cp.yaml
```

Start the control plane:

```sh
kuma-cp run --config-file kuma-cp.yaml
```

Run `kuma-cp migrate up` against a new or upgraded PostgreSQL database before starting the
control plane. Otherwise it refuses to start with `database is not migrated`.

The control plane exposes the API on port 5681 and the data plane server on port 5678. Proxies connect to
the second, and `kongctl` and the GUI use the first. The API enforces RBAC, and treats only requests
from the control plane host itself as admin. From anywhere else, pass a user token
with `kongctl`'s `--control-plane-token`.

## Joining a zone to a global control plane

To join a zone, name it and point it at the global control plane's KDS address:

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

The zone `name` is mandatory and has to be a valid [RFC 1035 DNS label](https://www.rfc-editor.org/info/rfc1035/). 
The name appears in every resource the zone owns, in KRIs, and is what a
[`MeshMultiZoneService`](/mesh/meshmultizoneservice/) selects zones by.

`globalAddress` takes `grpc://` or `grpcs://`. Use
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

## Proxy authentication

`dpServer.authn.dpProxy.type` decides how the data plane server authenticates a proxy. The control plane sets it
from the environment automatically: `serviceAccountToken` on Kubernetes, `dpToken` on
Universal.

On Universal that means every proxy, including the zone proxies that carry cross-zone traffic,
presents a data plane token:

```sh
kongctl create mesh dataplane-token --name backend-01 --workload backend --valid-for 24h > /etc/kuma/token
```

For more information, see [Universal data plane](/mesh/universal-data-plane/).

## Generated resources

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
    controls: "How often the control plane reconciles `MeshService` resources from `Dataplane` labels. 2s by default; `0` disables generation and hands you the resources to manage."
  - setting: "`KUMA_MESH_SERVICE_DELETION_GRACE_PERIOD`"
    controls: "How long a generated `MeshService` survives after its last proxy disappears. 1h by default."
  - setting: "`KUMA_IPAM_MESH_SERVICE_CIDR`"
    controls: "The VIP range for `MeshService`. `241.0.0.0/8` by default."
  - setting: "`KUMA_IPAM_MESH_EXTERNAL_SERVICE_CIDR`"
    controls: "The VIP range for `MeshExternalService`. `242.0.0.0/8` by default."
{% endtable %}

Neither generator runs on a global control plane, or against a Kubernetes store.

## Issuing identities

A mesh issues workload identities through [`MeshIdentity`](/mesh/policies/meshidentity/). 
The difference between Universal and Kubernetes is the default SPIFFE path: 
* `/workload/{workload}` on Universal,
* `/ns/{namespace}/sa/{service-account}` on Kubernetes

The workload name comes from the `kuma.io/workload` label on the `Dataplane`.

Without a `MeshIdentity`, proxies get no certificate and therefore no mTLS.

## Monitoring

The Monitoring Assignment Discovery Service (MADS) that Prometheus uses to discover proxies, runs
only in Universal mode. `controlPlane.madsServer.enabled` applies
only when `controlPlane.environment` is `universal`.
