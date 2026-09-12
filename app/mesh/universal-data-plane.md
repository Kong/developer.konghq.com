---
title: Deploy a Universal data plane proxy
description: Running kuma-dp on a VM or container host — the Dataplane resource, tokens, transparent proxying, and health.
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
  - text: Deploy a Universal control plane
    url: /mesh/universal-control-plane/
  - text: MeshService
    url: /mesh/meshservice/
  - text: "{{site.mesh_product_name}} CLI"
    url: /mesh/cli/
---

On Universal a proxy is two things you provide: a `Dataplane` resource describing what the
workload exposes and consumes, and a `kuma-dp` process running beside it. Kubernetes derives
both from a Pod; here you declare them.

## A minimal proxy

The `Dataplane` resource:

```yaml
type: Dataplane
mesh: default
name: backend-01
labels:
  kuma.io/workload: backend
  app: backend
networking:
  address: 10.0.0.11
  inbound:
    - port: 8080
      name: http
      protocol: http
```

Applied with:

```sh
kongctl create mesh -f backend-01.yaml
```

Then a token, and the process:

```sh
kongctl create mesh dataplane-token --name backend-01 --valid-for 24h > /etc/kuma/token

kuma-dp run \
  --cp-address https://control-plane.internal:5678 \
  --dataplane-file backend-01.yaml \
  --dataplane-token-file /etc/kuma/token
```

`--dataplane-file` applies the resource as the proxy starts, so the two steps can collapse into
one. Applying it ahead of time suits configuration management; passing it inline suits an
immutable image that templates the file at boot.

## The labels are what policies see

`labels` on the `Dataplane` are the only identity a policy can select on. There are no
per-inbound tags any more.

Two labels do more than the rest:

{% table %}
columns:
  - title: Label
    key: label
  - title: Effect
    key: effect
rows:
  - label: "`kuma.io/workload`"
    effect: "Names the workload this proxy belongs to. The control plane generates one `MeshService` per distinct value, and the SPIFFE ID defaults to `/workload/{value}`. Without it, no `MeshService` is generated and the workload has nothing for a policy or route to target."
  - label: "Your own labels"
    effect: "Anything else you set — `app`, `version`, `team` — is what `spec.targetRef.labels` and `MeshService.spec.selector.dataplaneLabels` match on."
{% endtable %}

`kuma.io/workload` has to be a valid RFC 1035 DNS label, since it becomes a `MeshService` name.
A value with invalid characters is skipped, and the control plane logs
`couldn't generate MeshService from kuma.io/workload, contains invalid characters`.

## Inbounds

Each entry in `networking.inbound[]` is a port the workload serves.

{% table %}
columns:
  - title: Field
    key: field
  - title: Meaning
    key: meaning
rows:
  - field: "`port`"
    meaning: "The port. With transparent proxying, the port the application listens on; without it, the port Envoy binds."
  - field: "`name`"
    meaning: "Names the port, which is what a policy's `sectionName` refers to. Defaults to the port number as a string."
  - field: "`protocol`"
    meaning: "`tcp`, `http`, `http2` or `grpc`. **Set this.** See below."
  - field: "`servicePort`"
    meaning: "Where traffic is forwarded, if it differs from `port`."
  - field: "`serviceAddress`"
    meaning: "The address traffic is forwarded to, if the application is not on `networking.address`."
  - field: "`state`"
    meaning: "`Ready`, `NotReady`, or `Ignored` to keep the port out of policy targeting while still issuing the proxy a certificate for it."
{% endtable %}

{:.warning}
> An inbound with no `protocol` is treated as unknown and served as plain TCP. It loses every L7
> filter: `MeshTimeout`'s HTTP timeouts, `MeshFaultInjection` entirely, `MeshRateLimit`'s HTTP
> limits, HTTP access log fields, and HTTP-aware routing. The `kuma.io/protocol` tag used to fill
> this in and no longer does. Nothing rejects the `Dataplane`, so the only sign is the policies
> quietly not applying.

`networking.address` must be a real address — not empty, not `0.0.0.0` or `::`. The admin port,
if set, has to differ from every inbound and outbound port.

## Outbounds

With transparent proxying on, you declare no outbounds: the proxy intercepts traffic and
resolves destinations itself. Without it, each destination the workload calls needs an entry
that binds a local port.

```yaml
networking:
  address: 10.0.0.11
  inbound:
    - port: 8080
      name: http
      protocol: http
  outbound:
    - port: 5432
      backendRef:
        kind: MeshService
        name: postgres
        port: 5432
```

The application then connects to `127.0.0.1:5432` and the proxy carries it to the destination.

`backendRef` is required — an outbound without one is rejected with `backendRef: must be
defined`. `kind` is `MeshService`, `MeshExternalService` or `MeshMultiZoneService`, and the
reference takes **either** `name` **or** `labels`, never both: `either 'name' or 'labels' should
be specified`.

{:.warning}
> `networking.outbound[].tags` is removed. A stored `Dataplane` still carrying tags keeps being
> served, the tags are discarded, and no outbound listener is generated — so the workload loses
> connectivity to that destination with nothing reported. Rewrite these before upgrading.

## Transparent proxying

Transparent proxying removes the need to declare outbounds, and is what makes a Universal proxy
behave like a Kubernetes sidecar. It needs iptables rules on the host, which `kuma-dp` installs:

```sh
kuma-dp run \
  --cp-address https://control-plane.internal:5678 \
  --dataplane-file backend-01.yaml \
  --dataplane-token-file /etc/kuma/token \
  --transparent-proxy
```

`--transparent-proxy-config` takes a file, a comma-separated list of files, or `-` for stdin,
and can be repeated — later values override earlier ones. That is how the redirect ports,
excluded ranges and DNS settings are tuned.

With transparent proxying on, `--dns-enabled` runs the embedded DNS proxy so the workload
resolves mesh hostnames. Destinations are reached by name rather than by a local port.

`reachableBackends` narrows what the proxy is configured for. A proxy that only talks to two
destinations does not need clusters for the whole mesh, and saying so cuts its configuration
substantially:

```yaml
networking:
  transparentProxying:
    reachableBackends:
      refs:
        - kind: MeshService
          name: postgres
          port: 5432
        - kind: MeshService
          labels:
            app: orders
```

Each ref takes `name` or `labels`, and `namespace` requires `name`.

## Readiness

Kubernetes reports readiness from the Pod probe. On Universal, either report it from outside, or
have the proxy probe the application:

```yaml
networking:
  inbound:
    - port: 8080
      name: http
      protocol: http
      serviceProbe:
        tcp: {}
        interval: 5s
        timeout: 2s
        unhealthyThreshold: 3
        healthyThreshold: 1
```

An inbound the proxy considers unhealthy is excluded from endpoint discovery, so traffic stops
being sent to it. An inbound with no `health` block at all is treated as healthy.

## Zone proxies

Cross-zone traffic is carried by an ordinary `Dataplane` that declares zone proxy listeners
rather than by a separate proxy type. `kuma-dp run --proxy-type=ingress` exits with
`.ProxyType "ingress" is not supported`.

```yaml
type: Dataplane
mesh: default
name: zone-ingress-01
networking:
  address: 10.0.0.20
  listeners:
    - type: ZoneIngress
      address: 10.0.0.20
      port: 10001
      name: ingress
```

`type` is `ZoneIngress` or `ZoneEgress`; anything else is rejected with `type must be
ZoneIngress or ZoneEgress`. Listeners can sit alongside inbounds on the same `Dataplane`.

These proxies authenticate with a **dataplane token** like any other. Tokens issued as zone
tokens are no longer accepted.

## Tokens

A dataplane token proves which proxy is connecting. Bind it as narrowly as the deployment
allows:

```sh
# to one named proxy
kongctl create mesh dataplane-token --name backend-01 --valid-for 24h

# to a workload, for an autoscaling group whose instance names vary
kongctl create mesh dataplane-token --workload backend --valid-for 24h
```

A token bound only to a mesh authenticates **any** proxy in that mesh, which makes it worth
avoiding wherever instances can be named or labelled. `--tag` binds to tag values, and
`--valid-for` bounds the lifetime.

The token goes to `kuma-dp` as `--dataplane-token-file`. `kongctl` writes it with no trailing
newline so it can be redirected straight into that file.

## What you get without asking

Once the `Dataplane` is applied and the proxy is connected, the zone control plane generates the
`MeshService` for its `kuma.io/workload` value, allocates a VIP and hostname, and creates the
matching `Workload` resource — checked every two seconds by default.

So the ongoing task on Universal is keeping `Dataplane` resources accurate. The rest follows
from them. See [{{site.mesh_product_name}} on Universal](/mesh/universal/) for the full split of
what you own against what Kubernetes would have handled.
