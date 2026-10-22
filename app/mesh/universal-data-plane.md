---
title: Universal data plane
description: "Running kuma-dp on a VM or container host: the Dataplane resource, tokens, transparent proxying, and health."
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
  - text: Universal control plane
    url: /mesh/universal-control-plane/
  - text: MeshService
    url: /mesh/meshservice/
  - text: "{{site.mesh_product_name}} CLI"
    url: /mesh/cli/
---

On Universal a proxy is made up of two pieces: 
* A `Dataplane` resource describing what the workload exposes and consumes
* A `kuma-dp` process running beside it

Kubernetes derives both from a Pod. On Universal, you declare them.

## Minimal proxy configuration

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

Apply it with:

```sh
kongctl apply mesh -f backend-01.yaml
```

Then issue a token:

```sh
kongctl create mesh dataplane-token --name backend-01 --workload backend --valid-for 24h > /etc/kuma/token
```

Start the process:

```sh
kuma-dp run \
  --cp-address https://control-plane.internal:5678 \
  --dataplane-file backend-01.yaml \
  --dataplane-token-file /etc/kuma/token
```

`--dataplane-file` applies the resource as the proxy starts, so the two steps can collapse into
one. Applying it ahead of time suits configuration management; passing it inline suits an
immutable image that templates the file at boot.

## Labels and policy selection

`labels` on the `Dataplane` are the only identity a policy can select on:

{% table %}
columns:
  - title: Label
    key: label
  - title: Effect
    key: effect
rows:
  - label: "`kuma.io/workload`"
    effect: "Names the workload this proxy belongs to. The control plane generates one `MeshService` per distinct value, and the SPIFFE ID defaults to `/workload/{value}`. Without it, the control plane generates no `MeshService` and the workload has nothing for a policy or route to target. It must be a valid [RFC 1035 DNS label](https://www.rfc-editor.org/info/rfc1035/)."
  - label: "Your own labels"
    effect: "Anything else you set (`app`, `version`, `team`) is what `spec.targetRef.labels` and `MeshService.spec.selector.dataplaneLabels` match on."
{% endtable %}

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
    meaning: "The name of the port, which is what a policy's `sectionName` refers to. Defaults to the port number as a string."
  - field: "`protocol`"
    meaning: | 
      `tcp`, `http`, `http2`, or `grpc`. 
      
      An inbound with no `protocol` is treated as unknown and served as plain TCP. It loses every L7 filter: 
      * `MeshTimeout`'s HTTP timeouts
      * `MeshFaultInjection` entirely
      * `MeshRateLimit`'s HTTP limits
      * HTTP access log fields
      * HTTP-aware routing
      
      Nothing rejects the `Dataplane`, so the only sign is the policies quietly not applying.
  - field: "`servicePort`"
    meaning: "Where traffic is forwarded, if it differs from `port`."
  - field: "`serviceAddress`"
    meaning: "The address traffic is forwarded to, if the application isn't on `networking.address`."
  - field: "`state`"
    meaning: "`Ready` or `NotReady`."
{% endtable %}

`networking.address` must be a real address: not empty, and not `0.0.0.0` or `::`. The admin port,
if set, has to differ from every inbound and outbound port.

## Outbounds

With transparent proxying on, you list destinations in
[`transparentProxying.reachableBackends`](#transparent-proxying) instead of binding ports.
Without it, each destination the workload calls needs an entry that binds a local port.

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

`backendRef` is required. `kind` can be `MeshService`, `MeshExternalService`, or `MeshMultiZoneService`, and the
reference takes at least one of `name` or `labels`. If both are set, `labels` wins. `port` is required unless
`kind` is `MeshExternalService`.

## Transparent proxying

Transparent proxying intercepts the workload's traffic, and is what makes a Universal proxy
behave like a Kubernetes sidecar. It needs iptables rules on the host. 

Install them as root with `kumactl install transparent-proxy`, which excludes the user
`kuma-dp` runs as (by default the user `kuma-dp` or UID `5678`, which must already exist):

```sh
sudo kumactl install transparent-proxy --kuma-dp-user kuma-dp
```

Then start `kuma-dp` as that user with the `--transparent-proxy` flag:

```sh
sudo runuser -u kuma-dp -- kuma-dp run \
  --cp-address https://control-plane.internal:5678 \
  --dataplane-file backend-01.yaml \
  --dataplane-token-file /etc/kuma/token \
  --transparent-proxy
```

To customize the redirect ports, excluded ports, and DNS redirection, write them to a config file:

```yaml
kumaDPUser: kuma-dp
redirect:
  inbound:
    port: 15006
    excludePorts: [9901]
  outbound:
    port: 15001
    excludePorts: [5432]
  dns:
    enabled: true
```

Pass the file to `kumactl install transparent-proxy` with `--config`:

```sh
sudo kumactl install transparent-proxy --config /etc/kuma/transparent-proxy.yaml
```

Then pass the same file to `kuma-dp` with `--transparent-proxy-config` in place of
`--transparent-proxy`, so the control plane knows the redirect ports:

```sh
sudo runuser -u kuma-dp -- kuma-dp run \
  --cp-address https://control-plane.internal:5678 \
  --dataplane-file backend-01.yaml \
  --dataplane-token-file /etc/kuma/token \
  --transparent-proxy-config /etc/kuma/transparent-proxy.yaml
```

`--transparent-proxy-config` takes a file, a comma-separated list of files, or `-` for stdin,
and can be repeated (later values override earlier ones).

With transparent proxying on, the embedded DNS proxy (`--dns-enabled`, on by default) lets the
workload resolve mesh hostnames. The workload reaches destinations by name rather than by a local port.

`reachableBackends` lists what the proxy can reach. Without it (and without outbounds), the
proxy reaches nothing, unless the control plane sets `KUMA_DEFAULTS_RESTRICT_OUTBOUND=false`.
The proxy also drops destinations outside the mesh unless a `MeshExternalService` or a
`MeshPassthrough` policy allows them.

```yaml
networking:
  transparentProxying:
    reachableBackends:
      refs:
        - kind: MeshService
          labels:
            kuma.io/display-name: postgres
          port: 5432
        - kind: MeshService
          labels:
            app: orders
```

Each ref takes `kind` and `labels`. Select a destination by name with the
`kuma.io/display-name` label. `port` is optional and requires `labels`.

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

The control plane excludes an inbound the proxy considers unhealthy from endpoint discovery, so traffic stops
reaching it. An inbound with no `serviceProbe` and no reported `health` is treated as healthy.

## Zone proxies

An ordinary `Dataplane` that declares zone proxy listeners carries cross-zone traffic:

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

`type` can be `ZoneIngress` or `ZoneEgress`. Listeners can sit alongside inbounds on the same `Dataplane`.

These proxies authenticate with a data plane token.

## Tokens

A data plane token proves which proxy is connecting. Bind it as narrowly as the deployment
allows:

* Bind it to one named proxy of a workload:

  ```sh
  kongctl create mesh dataplane-token --name backend-01 --workload backend --valid-for 24h
  ```

* Bind it to a workload, for an autoscaling group whose instance names vary:

  ```sh
  kongctl create mesh dataplane-token --workload backend --valid-for 24h
  ```

Once a `MeshIdentity` derives the proxy's identity from `kuma.io/workload`,
the token must carry `--workload`. 
Proxies that are already connected keep running until they reconnect, so bind tokens to
the workload from the start. `--tag` matches the `Dataplane`'s `labels`, and `--valid-for`
bounds the lifetime.

The token goes to `kuma-dp` as `--dataplane-token-file`. `kongctl` writes it with no trailing
newline so it can be redirected straight into that file.

## Generated resources

Once the `Dataplane` is applied and the proxy is connected, the zone control plane generates the
`MeshService` for its `kuma.io/workload` value, allocates a VIP and hostname, and creates the
matching `Workload` resource (checked every two seconds by default). 
Make sure to always keep the `Dataplane` resources accurate.
