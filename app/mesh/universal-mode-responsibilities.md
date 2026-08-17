---
title: "Platform responsibilities in {{site.mesh_product_name}} Universal mode"
description: Compare what Kubernetes provides automatically against what you must provide yourself when running data plane proxies in Universal mode.

content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

works_on:
  - on-prem
  - konnect

tags:
  - universal-mode
  - data-plane

related_resources:
  - text: '{{site.mesh_product_name}} data plane on Universal'
    url: /mesh/data-plane-universal/
  - text: 'Data plane on Kubernetes'
    url: /mesh/data-plane-kubernetes/
  - text: '{{site.mesh_product_name}} on Amazon ECS'
    url: /mesh/ecs/
  - text: 'Transparent proxying'
    url: /mesh/transparent-proxying/
  - text: 'Service discovery'
    url: /mesh/service-discovery/
  - text: 'DNS'
    url: /mesh/dns/
  - text: 'Data plane proxy authentication'
    url: /mesh/data-plane-proxy-authentication/
---

A service mesh doesn't run in isolation. It relies on the platform underneath it to place workloads, give them an identity, restart them when they fail, and report when they're ready to serve traffic. On Kubernetes, that platform is already there. On Universal, there may be no platform at all beyond the operating system, so those jobs become yours.

This page sets out who owns what, so you can size the work before you choose Universal mode and know which existing pages document each task in depth.

## How Universal mode differs from Kubernetes

It helps to think about three parties rather than two:

{% table %}
columns:
  - title: Party
    key: party
  - title: What it covers
    key: covers
rows:
  - party: Platform
    covers: |
      The orchestrator. On Kubernetes this includes scheduling, restarts, workload identity, readiness signals, service inventory, cluster DNS, and network namespaces. On Universal it's whatever you already run — often just the operating system and your own automation.
  - party: "{{site.mesh_product_name}}"
    covers: |
      The data plane proxy, the control plane, and every policy you apply. This layer is the same in both modes. What differs is how much of the surrounding work {{site.mesh_product_name}} can automate for you.
  - party: You
    covers: |
      Everything the platform doesn't provide and {{site.mesh_product_name}} doesn't automate. On Kubernetes this is a short list. On Universal it's the subject of this page.
{% endtable %}

{:.info}
> Universal mode is fully supported, and the policy and data plane layer is identical in both modes. Universal is how non-Kubernetes workloads — VMs, bare metal, and [Amazon ECS tasks](/mesh/ecs/) — join the same mesh as your Kubernetes workloads, with the same mTLS, the same policies, and the same observability.

## Responsibility matrix

### Proxy deployment and lifecycle

{% table %}
columns:
  - title: Capability
    key: capability
  - title: On Kubernetes
    key: k8s
  - title: What {{site.mesh_product_name}} does
    key: mesh
  - title: What you do on Universal
    key: you
rows:
  - capability: Sidecar added to the workload
    k8s: An admission webhook adds the sidecar container to the Pod, and the kubelet runs it.
    mesh: Generates the sidecar specification.
    you: Install and launch `kuma-dp` alongside every application instance.
  - capability: Injection is opt-in per workload
    k8s: The `kuma.io/sidecar-injection` label on the Pod or the Namespace. Injection is off unless the label enables it.
    mesh: Reads the label.
    you: No equivalent. You decide per host or per process.
  - capability: The `Dataplane` resource
    k8s: A controller creates and updates it from the Pod, and owns it through a Kubernetes owner reference.
    mesh: Turns the resource into proxy configuration in both modes.
    you: Author the YAML yourself — address, inbounds, ports, and tags — then either apply it up front or pass it to `kuma-dp run`.
  - capability: Proxy name
    k8s: Derived from the Pod name and namespace, which are injected as environment variables.
    mesh: —
    you: Pass `--name` and `--mesh`, or set them in the `Dataplane` YAML.
  - capability: Restart after a crash
    k8s: The kubelet restarts the container.
    mesh: Nothing. If Envoy exits, `kuma-dp` exits with it.
    you: Supervise `kuma-dp` with systemd or an equivalent process manager and give it a restart policy. {{site.mesh_product_name}} doesn't ship a unit file.
  - capability: Cleaning up stale resources
    k8s: Owner-reference garbage collection removes the `Dataplane` when the Pod goes away.
    mesh: Sweeps offline `Dataplane` resources on Universal, after 72 hours by default.
    you: Tune `KUMA_RUNTIME_UNIVERSAL_DATAPLANE_CLEANUP_AGE` if 72 hours is too slow for how often your instances churn.
{% endtable %}

### Identity and credentials

{% table %}
columns:
  - title: Capability
    key: capability
  - title: On Kubernetes
    key: k8s
  - title: What {{site.mesh_product_name}} does
    key: mesh
  - title: What you do on Universal
    key: you
rows:
  - capability: Proxy authentication
    k8s: The ServiceAccount token is mounted and rotated by the platform, and the control plane verifies it against the Kubernetes API.
    mesh: Picks the authentication method for the environment, then issues and validates tokens.
    you: Generate a data plane proxy token, distribute it to every host, pass `--dataplane-token-file`, and own expiry, rotation, and revocation.
  - capability: Token reload without a restart
    k8s: Enabled automatically.
    mesh: Can reload a token in place, without a proxy restart, in both modes.
    you: Opt in with `KUMA_DP_SERVER_AUTHN_ENABLE_RELOADABLE_TOKENS`, or restart the proxy whenever a token rotates.
  - capability: Identity attributes for policy targeting
    k8s: The workload name and service account are derived from the Pod.
    mesh: Builds the SPIFFE ID from whichever attributes are present.
    you: Set the `kuma.io/workload` label on the `Dataplane` yourself. If a `MeshIdentity` selects the proxy and the label is missing, the proxy is rejected when it connects.
  - capability: Default SPIFFE ID path
    k8s: "`/ns/<namespace>/sa/<service-account>`"
    mesh: Picks the template for the environment.
    you: |
      Nothing to configure, but note that identity keys off the workload label rather than a namespace and service account: `/workload/<workload>`.
  - capability: SPIRE agent socket
    k8s: The injector adds the SPIFFE CSI volume and mount for you.
    mesh: Consumes the socket.
    you: Run the SPIRE agent and supply its socket path. The default is `/tmp/spire-agent/public/api.sock`.
{% endtable %}

### Networking

{% table %}
columns:
  - title: Capability
    key: capability
  - title: On Kubernetes
    key: k8s
  - title: What {{site.mesh_product_name}} does
    key: mesh
  - title: What you do on Universal
    key: you
rows:
  - capability: Transparent proxy rules
    k8s: An init container or the CNI plugin applies the rules inside the Pod network namespace. Transparent proxying can't be turned off.
    mesh: Generates the rules, but only ever applies them from `kumactl` or the CNI plugin — never from `kuma-dp`.
    you: Run `kumactl install transparent-proxy` as root on every host, and re-apply or persist the rules across reboots.
  - capability: Dedicated proxy user
    k8s: The sidecar runs as UID 5678, set by the injector.
    mesh: Defaults to UID `5678` and username `kuma-dp`.
    you: Create the user, then run `kuma-dp` as exactly the user you passed to `kumactl install transparent-proxy`.
  - capability: Redirect loop protection
    k8s: Contained within the Pod network namespace.
    mesh: Writes rules that match on the owning user of each connection.
    you: Keep the proxy user and the transparent proxy user identical. A mismatch sends traffic into a loop.
  - capability: Firewall persistence and resolver files
    k8s: Not applicable — the rules live and die with the Pod.
    mesh: Offers `--store-firewalld`, and backs up `/etc/resolv.conf` so uninstall can restore it.
    you: Decide how rules persist, and manage `--vnet` and `--exclude-inbound-ports` for the ports that must bypass the proxy.
{% endtable %}

### Service discovery and DNS

{% table %}
columns:
  - title: Capability
    key: capability
  - title: On Kubernetes
    key: k8s
  - title: What {{site.mesh_product_name}} does
    key: mesh
  - title: What you do on Universal
    key: you
rows:
  - capability: Service inventory
    k8s: Controllers watch Pods, Services, and EndpointSlices continuously.
    mesh: Turns whatever inventory exists into endpoints for consumers.
    you: |
      The `Dataplane` resources *are* the inventory. You author and maintain every one of them.
  - capability: "`MeshService` and `Workload` resources"
    k8s: Reconciled from Services, EndpointSlices, and workload controllers.
    mesh: Generates them from your `Dataplane` resources every few seconds.
    you: Nothing, unless you disable the generators — then you manage both resources by hand.
  - capability: Virtual IPs
    k8s: The Kubernetes ClusterIP is reused as the `MeshService` virtual IP.
    mesh: Allocates a virtual IP from `241.0.0.0/8` when the service doesn't already have one.
    you: Nothing to configure, but expect allocated virtual IPs rather than ClusterIPs.
  - capability: Hostnames
    k8s: Cluster DNS already resolves `*.svc.cluster.local`, and mesh hostnames are generated on top.
    mesh: Creates a default generator for `*.svc.mesh.local` hostnames on Universal.
    you: Rely on the default generator, or curate your own `HostnameGenerator` resources.
  - capability: DNS inside the proxy
    k8s: The injector enables the built-in DNS server and sets every port for you.
    mesh: Ships a DNS server inside `kuma-dp` and configures Envoy to resolve mesh names through it.
    you: |
      Pass `--dns-enabled` and the DNS port flags to every `kuma-dp`, and redirect DNS through the transparent proxy — or skip DNS entirely and hand-write `networking.outbound` entries with explicit addresses and ports.
{% endtable %}

### Health and readiness

{% table %}
columns:
  - title: Capability
    key: capability
  - title: On Kubernetes
    key: k8s
  - title: What {{site.mesh_product_name}} does
    key: mesh
  - title: What you do on Universal
    key: you
rows:
  - capability: Application readiness drives endpoint health
    k8s: Container and Pod readiness are written straight into the `Dataplane` inbound state.
    mesh: Reads the platform signal wherever one exists.
    you: |
      There's no platform signal to read. An inbound with no health information is treated as healthy and stays in the endpoint list.
  - capability: A terminating workload leaves the mesh
    k8s: A Pod entering termination immediately marks its inbounds as not ready.
    mesh: —
    you: Shut the proxy down gracefully so the control plane withdraws it, or remove the `Dataplane` yourself.
  - capability: The control plane learns application health
    k8s: Not used. Platform readiness already provides the signal.
    mesh: Has Envoy probe the local application and report the result back to the control plane.
    you: |
      Add a `serviceProbe` to every inbound in every `Dataplane`, or run an external health checker that writes readiness back to the resource.
  - capability: Probe rewriting
    k8s: Liveness, readiness, and startup probes — HTTP, TCP, and gRPC — are rewritten through a probe proxy inside the sidecar.
    mesh: Provides the probe proxy.
    you: Not available. Every trigger for it is a Pod annotation set by the admission webhook.
  - capability: The proxy readiness endpoint
    k8s: Binds a wildcard address so the kubelet can reach it on the Pod IP.
    mesh: Serves `/ready` in both modes.
    you: Expect it on loopback by default outside Kubernetes, so a health checker on another host can't reach it without configuration.
  - capability: Consumer-side ejection
    k8s: "`MeshHealthCheck` and `MeshCircuitBreaker`."
    mesh: Identical in both modes.
    you: Treat both as mandatory. They're how consumers eject a bad endpoint that the control plane is still advertising.
{% endtable %}

## What you need to build on Universal

### Deploy and supervise the proxy

You install `kuma-dp` on every host that runs a meshed workload, and you decide which processes get a proxy. There's no label to flip and no webhook to add the sidecar for you.

You also own restarts. If Envoy exits, `kuma-dp` exits with it, and nothing brings it back — so run it under a process manager with a restart policy, as the same user you gave to the transparent proxy installer:

```
[Service]
User=kuma-dp
Restart=always
RestartSec=5
ExecStart=/usr/local/bin/kuma-dp run \
  --cp-address=https://mesh-cp.example.com:5678 \
  --dataplane-file=/etc/kuma/dp.yaml \
  --dataplane-token-file=/etc/kuma/token
```

The `Dataplane` resource is yours to write. You can create it up front and start the proxy with `--name` and `--mesh`, or pass the file to `kuma-dp run` and let the control plane create the resource when the proxy connects. See [{{site.mesh_product_name}} data plane on Universal](/mesh/data-plane-universal/#lifecycle) for both flows and how each one behaves on shutdown.

### Issue and rotate credentials

Every proxy needs a token before it can connect. Generate one, get it onto the host, and reference it:

```sh
kumactl generate dataplane-token --name=backend-1 --mesh=default > /etc/kuma/token
```

Distribution, file permissions, expiry, rotation, and revocation are all yours. By default a rotated token isn't picked up until the proxy restarts; set `KUMA_DP_SERVER_AUTHN_ENABLE_RELOADABLE_TOKENS=true` on the control plane if you'd rather the proxy reload it in place. See [data plane proxy authentication](/mesh/data-plane-proxy-authentication/#data-plane-proxy-token).

If you use `MeshIdentity` with a SPIFFE ID path template that references the workload label, set that label on the `Dataplane` yourself. The proxy is rejected at connect time when the label is missing:

```yaml
type: Dataplane
mesh: default
name: backend-1
labels:
  kuma.io/workload: backend
networking:
  address: 192.168.0.2
  inbound:
    - port: 8000
      servicePort: 80
      tags:
        kuma.io/service: backend
```

### Set up transparent proxying

`kuma-dp` never touches your firewall. Transparent proxying on Universal is a separate, root-privileged step you run once per host — and re-run or persist after a reboot:

```sh
useradd -u 5678 -U kuma-dp
kumactl install transparent-proxy --kuma-dp-user kuma-dp
```

Use `--exclude-inbound-ports` for anything that must bypass the proxy, and `--vnet` to declare virtual networks such as Docker bridges. `--store-firewalld` writes the rules through `firewalld` so they survive a restart. To roll back, `kumactl uninstall transparent-proxy` restores both the firewall rules and `/etc/resolv.conf`.

{:.warning}
> The redirect rules identify proxy traffic by the user that owns the connection. If `kuma-dp` runs as a different user than the one you passed to `kumactl install transparent-proxy`, its own outbound traffic is redirected back into itself and loops. Create the user first, install the rules with `--kuma-dp-user`, and start `kuma-dp` as exactly that user.

If you'd rather not manage host firewall rules, skip transparent proxying and declare `networking.outbound` entries instead. Your application then reaches its dependencies on `127.0.0.1` at the port you assign. See [transparent proxying](/mesh/transparent-proxying/#universal) for the full Universal setup.

### Maintain service discovery and DNS

On Kubernetes the service inventory is a side effect of deploying: controllers watch Pods, Services, and EndpointSlices and keep the mesh's view current. On Universal, your `Dataplane` resources *are* that inventory. Every instance that appears, moves, or scales has to be reflected in one, which in practice means generating them from your provisioning tooling rather than writing them by hand. [Service discovery](/mesh/service-discovery/) explains how the control plane uses them.

`MeshService` and `Workload` resources are generated from those `Dataplane` resources automatically, and hostnames such as `backend.svc.mesh.local` come from a default [`HostnameGenerator`](/mesh/hostnamegenerator/). Virtual IPs are allocated from `241.0.0.0/8` rather than reusing a ClusterIP.

The built-in DNS server isn't on by default outside Kubernetes. Enable it explicitly and make sure DNS traffic reaches it:

```sh
kuma-dp run \
  --dns-enabled \
  --dns-coredns-port=5300 \
  --dns-envoy-port=5301 \
  ...
```

See [DNS](/mesh/dns/#virtual-ips) for how resolution and virtual IPs fit together.

### Report application health

This is the largest gap, and the one that's easiest to miss because nothing fails loudly.

On Kubernetes, readiness is already solved. The kubelet runs your probes, container and Pod readiness are written into the `Dataplane` inbound state, and consumers stop receiving an endpoint the moment it stops being ready. Termination behaves the same way. You configure a probe once, in the PodSpec, and the mesh follows it.

On Universal there's no such signal, and the default is permissive: an inbound with no health information is considered healthy. A proxy whose application is still starting, deadlocked, or shutting down keeps receiving traffic. Marking a proxy offline doesn't withdraw its endpoints either — endpoint membership follows inbound readiness, so until the `Dataplane` is removed, consumers can still be sent to it.

Close the gap on both sides. First, give the control plane something to observe by adding a `serviceProbe` to each inbound, which has Envoy probe the local application and report the result back:

```yaml
type: Dataplane
mesh: default
name: backend-1
networking:
  address: 192.168.0.2
  inbound:
    - port: 8000
      servicePort: 80
      serviceProbe:
        tcp: {}
      tags:
        kuma.io/service: backend
```

Service probes establish a TCP connection to the application port — they don't check an HTTP path — so a process that's listening but not yet serving still looks healthy. If you need a richer check, run an external health checking system and have it write readiness back to the `Dataplane`.

Second, don't rely on the control plane alone. Apply [`MeshHealthCheck`](/mesh/policies/meshhealthcheck/) and [`MeshCircuitBreaker`](/mesh/policies/meshcircuitbreaker/) so consumers detect and eject a failing endpoint themselves. On Kubernetes these are a useful addition; on Universal, treat them as part of the baseline. [Data plane health](/mesh/dataplane-health/) compares the mechanisms.

Note also that `kuma-dp` serves its own `/ready` endpoint on loopback outside Kubernetes. If you want an external load balancer or monitoring system to poll it, plan for that explicitly.

## What doesn't change

The mesh itself is the same product in both modes. These behave identically on Universal and on Kubernetes:

- mTLS, workload identity, and certificate rotation
- Every traffic policy: `MeshTrafficPermission`, `MeshHTTPRoute`, `MeshTCPRoute`, `MeshTimeout`, `MeshRetry`, `MeshCircuitBreaker`, `MeshHealthCheck`, `MeshLoadBalancingStrategy`, `MeshFaultInjection`, and `MeshRateLimit`
- Observability: `MeshMetric`, `MeshTrace`, and `MeshAccessLog`
- Multi-zone routing, zone ingress, and zone egress
- `MeshExternalService` and `MeshPassthrough`

You apply these as YAML through `kumactl` or the API instead of as Kubernetes resources, and the identities they match on follow the SPIFFE ID shape for the mode. What each policy does, and how the proxy enforces it, is the same.

## Choosing between Universal and Kubernetes

{% table %}
columns:
  - title: Choose Kubernetes when
    key: k8s
  - title: Universal is a good fit when
    key: universal
rows:
  - k8s: Your workloads already run on Kubernetes, or can. The platform supplies identity, restarts, readiness, and service inventory, and the mesh consumes them directly.
    universal: You have VM or bare metal workloads that need to join a mesh whose primary platform is Kubernetes, and you want one policy and mTLS domain across both.
  - k8s: You don't have configuration management or process supervision you're prepared to extend to proxy lifecycle, credentials, and firewall rules.
    universal: You already run configuration management, secret distribution, and process supervision, and adding the proxy to them is routine work.
  - k8s: You want application readiness to reach the mesh without extra configuration.
    universal: You're prepared to define service probes on every inbound, or to run an external health checking system.
  - k8s: You want the mesh to track scaling and rescheduling on its own.
    universal: Your instance inventory is already automated, so generating and retiring `Dataplane` resources fits into existing tooling.
{% endtable %}

Both modes can run in the same mesh. Migrating a workload from Universal to Kubernetes later doesn't change your policies — it hands most of this page's work back to the platform.
