---
title: Bring external traffic into the mesh
description: Connect an API gateway to Mesh 3, route external requests to mesh services, and apply identity and policies on the gateway-to-backend connection.
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/
tags:
  - service-mesh
  - routing
  - security
related_resources:
  - text: Kong Operator Gateway API support
    url: /operator/dataplanes/gateway-api/
  - text: Mesh-scoped zone proxies
    url: /mesh/mesh-scoped-zone-proxies/
  - text: MeshTrafficPermission policy
    url: /mesh/policies/meshtrafficpermission/
  - text: How policies select traffic
    url: /mesh/policy-targeting/
  - text: MeshIdentity policy
    url: /mesh/policies/meshidentity/
---

Use an API gateway to accept requests from clients outside the mesh and forward them to mesh
services. The gateway handles its public listeners, TLS certificates, routes and client
authentication. A {{site.mesh_product_name}} sidecar handles the connections the gateway
makes to mesh backends.

V2 called this a **delegated gateway**. In v3, the gateway is an ordinary `Dataplane`:
you exclude the ports that the gateway handles directly from inbound interception. There is
no special gateway label or proxy type. Other ports can remain part of the mesh.

Port exclusions do not deploy an API gateway, expose a public address or create routes.
Configure those through your gateway's own deployment and routing tools.

## Choose application ingress or zone ingress

Application ingress and [zone ingress](/mesh/mesh-scoped-zone-proxies/) solve different
problems. A zone ingress is not a public API gateway.

| You need to | Use | Why |
| --- | --- | --- |
| Accept external HTTP clients, authenticate users and route public requests | An API gateway with a mesh sidecar | The API gateway owns the public API; its sidecar connects it to mesh services. |
| Carry mesh workload traffic from another zone | Mesh-scoped zone ingress | It forwards workload mTLS to a destination proxy without terminating that connection. |
| Send mesh traffic to a registered external service | Mesh-scoped zone egress | It handles the mesh-to-external-service path, not public application ingress. |

For a local backend, a typical HTTP request follows this path:

```text
External client → API gateway → gateway sidecar → backend sidecar → application
                  public TLS     └──── mesh mTLS ────┘
                  and user auth
```

Incoming traffic on excluded ports reaches the API gateway directly, bypassing its mesh
sidecar's inbound processing. Outgoing traffic from the gateway is intercepted by the sidecar and sent through
the mesh. If the chosen backend is in another zone, the mesh connection also passes through
that zone's ingress.

This page describes a gateway that processes the incoming request and opens a connection to
the backend. If the gateway instead passes application TLS through unchanged, the mesh
sidecar cannot inspect the encrypted HTTP request; HTTP routing, tracing and request-level
policies require visible HTTP traffic.

## Connect the gateway to a mesh

Before changing the gateway deployment, prepare:

- A mesh and a working zone control plane.
- A gateway deployment with its own public Service or load balancer and routes.
- A registered backend destination with the correct port and protocol.
- A `MeshIdentity` that selects the gateway proxy and the backend proxies, with the trust
  needed for their mTLS connection.
- A backend permission that allows the gateway's workload identity.

Inject the gateway's traffic-serving Pods, not just the controller that configures
them. For example, injecting an ingress controller without injecting the gateway data plane
does not put user requests through the mesh.

### Kubernetes

Enable sidecar injection and mesh membership for the gateway namespace. For a new namespace:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: edge
  labels:
    kuma.io/mesh: default
    kuma.io/sidecar-injection: enabled
```

For an existing namespace, merge these labels with its current configuration. Namespace
injection can affect other newly created Pods there, so use a namespace appropriate for the
gateway deployment.

Exclude the gateway's public listening ports on its Pod template. For a gateway managed by
{{site.operator_product_name}}, configure the generated Pod template through the Operator's
[gateway configuration](/operator/dataplanes/gateway-configuration/), rather than editing an
Operator-owned Deployment that reconciliation can overwrite. The required Pod-template
settings for a process listening on `8000` and `8443` are:

```yaml
spec:
  template:
    metadata:
      labels:
        app: edge-gateway
      annotations:
        traffic.kuma.io/exclude-inbound-ports: "8000,8443"
```

Use the ports the process listens on inside the Pod, not the Service's public ports. For
example, a Service exposing `443` with `targetPort: 8443` needs `8443` in the exclusion list.
The annotation takes a comma-separated list; there is no all-ports value. Include every
listener that must accept traffic directly, and review admin, status and probe ports as well
as public listeners. If a controller is also injected, review its own listening ports separately.

{:.warning}
> Excluding a port bypasses mesh inbound mTLS and permissions on that port; it does not grant
> access through them. Protect public listeners with the gateway's TLS and authentication.
> Keep admin and status listeners private through their bind addresses and network controls.
> Do not exclude backend ports that should remain protected by the mesh.

### Keep public gateway Services out of mesh discovery

Port exclusion and Service discovery are separate settings. Excluding a port removes its
generated Dataplane inbound, but does not by itself prevent the Service from producing a
`MeshService`. Mesh clients can then discover a destination with no endpoints for that port.

Add this annotation to each gateway Service that should remain outside mesh discovery.
Merge it into the existing Service metadata, preserving its ports, selector and type:

```yaml
metadata:
  annotations:
    kuma.io/ignore: "true"
```

The **Pod annotation** controls traffic interception. The **Service annotation** suppresses
mesh inbounds derived from that Service and its generated MeshService; it does not disable
the Kubernetes Service or expose it publicly. Do not put `kuma.io/ignore` on the backend
Services the gateway must reach through the mesh.

Ignoring a Service applies to the whole Service, not just one port. If the same Pod has ports
that should remain mesh destinations, expose those through a separate, non-ignored Service
and leave them out of the exclusion list. Direct access to an ignored Service from a mesh
client still depends on that client's passthrough and network configuration.

Roll out new Pods through the gateway's normal deployment process so the injector writes the
updated transparent proxy configuration. Retain the gateway image, service account and
routes. Inspect the new Dataplane: excluded ports must be absent from its inbounds, while
ports intentionally left in the mesh should remain. A Pod injected by an older control plane
does not gain the updated excluded-inbound behavior just from editing the Deployment template.

### Universal

Use an ordinary Dataplane and direct the gateway process's outbound traffic through its
sidecar. No gateway label is required:

```yaml
type: Dataplane
mesh: default
name: edge-gateway-01
labels:
  app: edge-gateway
networking:
  address: 10.0.0.10
```

Replace the address with the proxy's address. Configure data plane authentication, DNS and
outbound interception as described in [Universal data plane proxies](/mesh/universal-data-plane/).
Pass `--exclude-inbound-ports=8000,8443` to `kuma-dp`, or set
`redirect.inbound.excludePorts` in its transparent proxy configuration, using the gateway's
actual listening ports. Do not declare those excluded ports as Dataplane inbounds. Unlike
Kubernetes, you maintain that resource yourself. Retain any other inbounds that the mesh
should serve, and verify the interception rules before exposing the gateway.

## Route to a mesh destination, not individual Pods

Configure the gateway's upstream to use an address recognized by mesh service discovery.
On Kubernetes, send traffic to the backend Service address rather than resolving and
load-balancing directly across its Pod IPs. This lets the sidecar select endpoints and apply
the policies associated with the service.

{{site.operator_product_name}} can configure the gateway to choose individual backend Pod
addresses. For a mesh backend, enable service-upstream so the gateway uses the Kubernetes
Service's DNS name instead. For a regular ClusterIP Service, that name resolves to its
ClusterIP. The gateway's mesh sidecar intercepts that connection, recognizes the
service, and chooses the backend according to mesh routing and load-balancing policies.

To configure this for one backend, add the following annotation to that backend's Kubernetes
Service. For example, merge this metadata into the existing `payments` Service in `shop`;
keep its selector and ports unchanged:

```yaml
metadata:
  name: payments
  namespace: shop
  annotations:
    ingress.kubernetes.io/service-upstream: "true"
```

Put this on the **backend Service**, not on the gateway's public Service or Pod. It changes
how the gateway connects to the backend; it does not grant access or enable mesh mTLS.
The annotation name remains `ingress.kubernetes.io/service-upstream`; it is supported by
{{site.operator_product_name}}. The per-Service setting keeps the change scoped to one backend.

This ClusterIP configuration is for Services backed by Pods. An ExternalName Service has no
ClusterIP; use the mesh hostname alias described below for a MeshMultiZoneService.

For cross-zone backends, configure the gateway to use the hostname published for the intended
[MeshMultiZoneService](/mesh/meshmultizoneservice/) or remote
[MeshService](/mesh/meshservice/). The gateway's mesh sidecar handles the cross-zone path.
Do not set the gateway's application upstream to the zone ingress's raw address: that address
is part of mesh transport, not a replacement for the service destination.

The gateway's public route and a [MeshHTTPRoute](/mesh/policies/meshhttproute/) have different
jobs. The public route chooses where an external request goes. A MeshHTTPRoute on the gateway
sidecar can then change the mesh backend used for that outbound request. It does not configure
the gateway's public hostname, certificate or listener.

### Use a MeshMultiZoneService as a Gateway API backend

A Gateway API `HTTPRoute` normally references a Kubernetes `Service`, not a
`MeshMultiZoneService`. With {{site.operator_product_name}}, you can bridge the two with an
`ExternalName` Service pointing to the aggregate's generated mesh hostname. Other Gateway
API implementations may differ in their support for ExternalName backends; check your
controller before using this pattern. See
[{{site.operator_product_name}} Gateway API support](/operator/dataplanes/gateway-api/) for
how the Operator manages the Gateway and its routes.

First, inspect the `MeshMultiZoneService` as seen by the gateway's zone. Read a generated
hostname from `status.addresses[].hostname` and its listening port from `spec.ports[].port`.
Also check `status.meshServices` to confirm that the aggregate selects the intended services
and zones. Do not construct a `.mesh` name from the resource name: hostname generation is
configurable.

For example, if the published hostname is `payments.mesh` and the aggregate exposes HTTP on
port `80`, create this alias in the gateway's namespace. Replace the hostname and port with
the values you inspected:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: payments-multizone
  namespace: edge
spec:
  type: ExternalName
  externalName: payments.mesh
  ports:
    - name: http
      port: 80
      protocol: TCP
```

ExternalName is a DNS alias: it does not create a proxy, a ClusterIP or a new mesh identity.
It also does not make the destination a `MeshExternalService`; this is still an internal
multi-zone mesh destination. Unlike the ignored public gateway Service described earlier,
this Service exists to give the route a backend reference, not to expose the gateway's Pods.

Assuming a Gateway API `Gateway` named `edge` already exists in namespace `edge` and accepts
this route, reference the alias from an `HTTPRoute`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: payments
  namespace: edge
spec:
  parentRefs:
    - name: edge
  hostnames:
    - payments.example.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: payments-multizone
          port: 80
```

Here, `payments.example.com` is the public request hostname, `payments-multizone` is the
Kubernetes alias, and `payments.mesh` is the mesh destination hostname. They serve different
purposes. ExternalName does not rewrite the HTTP Host header or configure application TLS;
configure those separately in the gateway if the backend requires them.

The gateway's DNS resolution must reach mesh DNS and resolve the generated hostname to the
aggregate's VIP in that zone. Test resolution from the traffic-serving gateway Pod, using the
resolver the gateway process actually uses. An unrelated Pod or a gateway configured to use
a custom external resolver may not resolve the same name. Keep the connection to the VIP
inside outbound interception; do not exclude the backend port from outbound proxying.

### Keep multi-zone routing and authorization separate

Using ExternalName does not bypass MeshIdentity. Once the gateway sidecar recognizes the
aggregate's VIP and port, it uses the normal MeshMultiZoneService connection configuration:

- The gateway sidecar presents its workload certificate. It needs a matching MeshIdentity
  and the trust required to validate the destination.
- The sidecar builds destination identity checks from the SPIFFE identities advertised in
  `spec.identities` of the MeshServices selected by the aggregate. The alias's DNS name is
  not a workload identity and does not need to appear in a mesh certificate.
- For a remote backend, zone ingress forwards the workload mTLS connection. The destination
  proxy authenticates the gateway and evaluates its MeshTrafficPermission rules.

Allow the gateway's actual SPIFFE ID on the backend proxies in every zone that can receive
traffic, using the permission pattern below. Do not attach the permission to the ExternalName
Service or try to match the gateway by the alias name. If gateway identities include a zone
in their trust domain or path, allow each intended gateway identity rather than assuming they
are identical across zones.

For outbound policies, select the gateway with `spec.targetRef`, then use
`spec.to[].targetRef.kind: MeshMultiZoneService` and labels from the aggregate itself. Do not
use the Kubernetes alias name as a MeshService selector. Keep the aggregate's service
selector narrow and verify its advertised identities and trust before granting access; DNS
resolution alone is not evidence of authorization.

Validate both layers: check the HTTPRoute's `Accepted` and `ResolvedRefs` conditions, resolve
the mesh hostname from the gateway, and verify a request reaches an intended backend. Then
exercise another eligible zone and a disallowed caller. A route can be accepted while DNS,
cross-zone reachability, trust or permissions still prevent traffic.

## Allow the gateway to call the backend

The backend authenticates the gateway sidecar's SPIFFE identity. It does not receive the
external user's identity as the mesh TLS peer. Authenticate users and enforce public API
authorization in the gateway or application; do not treat a forwarded header as a
MeshTrafficPermission identity.

This example allows the gateway identity to call proxies labeled `app: payments`. Replace the
SPIFFE URI with the URI in your gateway proxy's workload certificate and ensure the backend
Dataplanes carry the selected label:

{% policy_yaml %}
```yaml
type: MeshTrafficPermission
mesh: default
name: allow-edge-to-payments
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: payments
  rules:
    - default:
        allow:
          - spiffeID:
              type: Exact
              value: spiffe://default.zone-a.mesh.local/ns/edge/sa/edge-gateway
```
{% endpolicy_yaml %}

The top-level selector identifies the **backend proxies enforcing access**, not the gateway.
The allow entry identifies the **gateway calling them**. A certificate with a different
trust domain or workload path does not match this example's URI.

Without a matching allow, the backend denies mesh traffic. Review all applicable permissions:
an existing broad allow can admit other callers, and any matching deny takes precedence over
this allow. See [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/) for evaluation
and identity verification.

## Apply policies to gateway-to-backend traffic

For outbound behavior, select the gateway Dataplane at the top level and the destination under
`to`. This policy gives the gateway sidecar two seconds to connect to `payments` and five
seconds for an HTTP request:

{% policy_yaml %}
```yaml
type: MeshTimeout
mesh: default
name: edge-to-payments-timeout
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: edge-gateway
  to:
    - targetRef:
        kind: MeshService
        labels:
          kuma.io/display-name: payments
          k8s.kuma.io/namespace: shop
      default:
        connectionTimeout: 2s
        http:
          requestTimeout: 5s
```
{% endpolicy_yaml %}

Replace the destination labels with those on your MeshService. These limits start on the
gateway-to-backend hop; they do not bound time already spent authenticating or processing a
request in the API gateway. Coordinate them with the gateway's own timeout budget.

| Concern | Configure it here |
| --- | --- |
| Public TLS, user authentication, public routes and per-consumer limits | In the API gateway. Public traffic bypasses the mesh sidecar's inbounds. |
| Mesh backend routing, retries, timeouts, load balancing and circuit breaking | With outbound policies selecting the gateway Dataplane and destination. |
| Which gateway workloads may call a backend | With MeshTrafficPermission selecting the backend proxy and matching the gateway's identity. |
| Mesh-side access logs, metrics and traces | With observability policies selecting the gateway proxy. These supplement the gateway's public request logs. |

Use labels you manage, such as `app: edge-gateway`, to select the gateway proxies; add a zone
label when needed. A proxy-wide `targetRef` can select a Dataplane with no inbounds, so a
gateway does not need a special marker to receive outbound policies.

Do not use `sectionName` to name an excluded public listener: that port is not a mesh inbound.
For a proxy with no inbounds, use `kind: Mesh` or a matching `kind: Dataplane` selector without
`sectionName` to configure proxy-wide behavior.

Mesh-wide policies can already include gateway proxies. A narrower policy does not universally
replace them; consult each policy's merge behavior. Avoid uncoordinated retries at both the API
gateway and sidecar, which can multiply backend attempts. Mesh permissions identify gateway
workloads, so user-specific rate limits and authorization still belong at the public API layer.

## Update an existing v2 gateway

Keep the API gateway and sidecar architecture, but replace its special gateway configuration.
It is not replaced by zone ingress.

1. Inventory every listening port and Service on the gateway and any injected controller.
   Decide which ports accept traffic directly and which remain mesh-protected.
1. Before or together with the v3 upgrade, replace the `kuma.io/gateway` Pod annotation with
   `traffic.kuma.io/exclude-inbound-ports`. Add `kuma.io/ignore: "true"` to gateway Services
   that should not become mesh destinations. Roll out new Pods with the updated injector.
1. On Universal, remove the `kuma.io/gateway` label and old `networking.gateway` block, set the
   inbound port exclusions, and remove those ports from the Dataplane's declared inbounds.
1. Replace policy selectors and locality keys that depend on `kuma.io/gateway` with labels
   you manage. Move any required custom tags from `networking.gateway.tags` to labels too.
1. Update dashboards and inspection automation. These proxies now report as ordinary
   Dataplanes: `MeshMetric` reports `sidecar` rather than `gateway` for `kuma.proxy_role`,
   gateway insight counters are removed, and gateway-specific inspection filters are gone.
1. Verify public traffic, readiness probes, backend permissions and outbound policies before
   completing the rollout. Rehearse with the exact versions you plan to deploy.

{:.warning}
> The removed `kuma.io/gateway` annotation is ignored, not rejected. A Pod can start successfully
> while public traffic is redirected through Envoy instead of reaching the gateway directly.
> Also, stored gateway labels are removed on the next Dataplane write, so selectors that still
> depend on them can stop matching later. Replace both the interception settings and selectors.

For a former built-in gateway, this is not a complete deployment migration. V3 no longer
reconciles `MeshGatewayInstance` deployments. Replace that architecture with an independently
managed gateway and sidecar, including its public routes and certificates, before upgrading.

## Verify the gateway and mesh separately

1. Inspect the traffic-serving Pod and its Dataplane. Confirm the sidecar, mesh membership,
   port exclusions and labels used by policies. Excluded ports must not appear as inbounds.
1. Check that ignored gateway Services have no generated MeshService. Confirm that intended
   backend Services still have mesh destinations and endpoints.
1. Confirm that the gateway has the expected public listener, certificate and route using its
   own configuration and logs.
1. Inspect the gateway sidecar's active configuration. Confirm that the backend destination and
   outbound policy settings exist and were accepted by Envoy.
1. Send a request through the public gateway and verify the backend response. Observe both the
   gateway's public request log and mesh-side telemetry to confirm the full path.
1. Test a rejected external user at the API gateway and a disallowed workload at the backend.
   These test different security boundaries; success at one does not prove the other.

| Symptom | Check |
| --- | --- |
| Gateway has no mesh policies | The traffic-serving Pod was injected, policy labels match, and a proxy with no inbounds is selected without `sectionName`. Remove selectors using the old gateway label. |
| External client is rejected before reaching the gateway | The actual Pod listening port is excluded, and the Pod was recreated with the updated injection configuration. |
| Mesh clients see a gateway destination with no endpoints | The gateway Service needs `kuma.io/ignore: "true"` if it should stay outside mesh discovery. Check passthrough policy separately. |
| Gateway or controller fails readiness checks after migration | Probe traffic is no longer specially exempted for gateways. Review probe configuration and port exclusions on each injected deployment. |
| Public requests fail before reaching the mesh | Gateway listener, certificate, authentication, public route and load balancer. |
| Gateway reaches the backend but mesh routing has no effect | The upstream uses the service address, traffic is intercepted, and the sidecar recognizes the destination and protocol. |
| Backend rejects the gateway connection | Gateway certificate, backend trust and permissions matching the gateway's actual SPIFFE URI. |
| HTTP policy has no effect | The gateway is not passing opaque application TLS to the sidecar, and the destination is configured with an HTTP protocol. |
| Backend sees the same mesh identity for different users | Expected: mesh mTLS identifies the gateway workload. Enforce and propagate end-user identity through a separately secured application mechanism. |
| Request fails earlier than the mesh timeout | The API gateway or client may have a shorter timeout. Check all budgets along the path. |
