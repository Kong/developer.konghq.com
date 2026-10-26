---
title: Mesh-scoped zone proxies
description: Understand zone ingress and zone egress in {{site.mesh_product_name}} 3.x, deploy them for a mesh, and apply policies at the correct point in the traffic path.
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/
tags:
  - service-mesh
  - multi-zone
related_resources:
  - text: Application ingress
    url: /mesh/application-ingress/
  - text: Migrate zone proxies to {{site.mesh_product_name}} 3.x
    url: /mesh/migrate-zone-proxies-to-3/
  - text: Deploy mesh-scoped zone proxies
    url: /mesh/zone-proxies/
  - text: Policy targeting
    url: /mesh/policy-targeting/
  - text: MeshTrafficPermission policy
    url: /mesh/policies/meshtrafficpermission/
  - text: MeshIdentity policy
    url: /mesh/policies/meshidentity/
  - text: MeshMultiZoneService
    url: /mesh/meshmultizoneservice/
  - text: "Concepts: Zone ingress and zone egress"
    url: /mesh/concepts/#zone-ingress-and-zone-egress
min_version:
  mesh: '3.0'
---

Zone proxies carry traffic between zones or from a mesh to external services. In
{{site.mesh_product_name}} 3.x, each zone proxy belongs to one mesh, and a
`Dataplane` resource represents it. Its `networking.listeners` entries give it an ingress or egress role.

Representing zone proxies as `Dataplane` resources lets you select them with policies the same way you select workload proxies. The
important difference is the traffic they handle: an ingress forwards an encrypted connection,
while an egress can inspect traffic after terminating mesh mTLS. Selecting a zone proxy does
not make every policy meaningful on both roles.

Use this reference to choose where to deploy a proxy, where to enforce a policy, and how to
verify the result. The [deployment walkthrough](/mesh/zone-proxies/) provides a complete
Kubernetes environment to try these concepts.

## Traffic paths

For public application requests, use an [API gateway with a mesh sidecar](/mesh/application-ingress/).
Zone ingress carries connections from other mesh proxies; it doesn't replace a public API gateway.

{% table %}
columns:
  - title: Role
    key: role
  - title: Destination
    key: destination
  - title: Proxy behavior
    key: what
  - title: Caller permission enforcement
    key: where
rows:
  - role: "Zone ingress"
    destination: "A service in the ingress's zone"
    what: "Reads the destination name from TLS Server Name Indication (SNI) and forwards the encrypted connection to a local workload proxy. It doesn't terminate workload mTLS."
    where: "On the destination workload proxy, which authenticates the original caller."
  - role: "Zone egress"
    destination: "A registered `MeshExternalService`"
    what: "Terminates mesh mTLS from the caller's proxy, then connects to the external endpoint."
    where: "On the egress, which authenticates the caller before forwarding traffic."
{% endtable %}

For a request to a workload in another zone, the path is:

{% mermaid %}
flowchart LR
    subgraph A[Zone A]
        C[Client proxy]
    end
    subgraph B[Zone B]
        I[Zone ingress]
        D[Destination proxy]
    end
    C --> I -->|"Forwarded without decrypting"| D
    C -.->|"Workload mTLS, end to end"| D
{% endmermaid %}

For a registered external destination reached through egress, the path is:

{% mermaid %}
flowchart LR
    C[Client proxy] -->|"Mesh mTLS"| E[Zone egress]
    E -->|"Separate connection, TLS configured by MeshExternalService"| X[External endpoint]
{% endmermaid %}

Zone egress isn't an additional hop in the cross-zone workload path between a client proxy and a destination proxy through zone ingress, nor is it
an automatic gateway for every address an application can dial. Unknown destinations and
traffic outside interception are separate concerns. For more information, see
[MeshPassthrough](/mesh/policies/meshpassthrough/). Use network controls as well when you
must prevent applications from bypassing an approved exit path.

Deploying an ingress doesn't choose which remote service a client calls.
[MeshService](/mesh/meshservice/) and [MeshMultiZoneService](/mesh/meshmultizoneservice/)
describe the destinations; routing and load-balancing policies on the client determine where
its traffic goes. The ingress forwards the connection to the chosen service in its own zone.

## Deploy proxies for a mesh

Create the mesh separately and connect each proxy to its zone control plane. A proxy can't
register successfully until its mesh exists. Create identities and permissions before sending
traffic: a running Pod alone doesn't mean the proxy can serve requests.

### Kubernetes

Add a mesh entry to the values for the zone control plane installation. This example enables
separate ingress and egress Deployments for the `default` mesh:

```yaml
kuma:
  controlPlane:
    mode: zone
  meshes:
    - name: default
      ingress:
        enabled: true
      egress:
        enabled: true
```

Merge these settings into your existing zone values, including its global control plane
connection settings. The `kuma` prefix is for the {{site.mesh_product_name}} Helm chart.
The entry doesn't create the `Mesh` resource or grant traffic permissions.

Each enabled role gets its own Deployment and Service. The ingress Service defaults to
`LoadBalancer` on port `10001`; egress defaults to `ClusterIP` on port `10002`. Both roles
are disabled by default. Enable only ingress if the zone needs to receive cross-zone workload
traffic but doesn't need this external-service egress path.

The chart uses sidecar injection to run the proxy. The control plane generates its
`Dataplane` listeners from the zone-proxy deployment configuration. Inspect those generated
resources rather than creating a second `Dataplane` manually for the same Pod.

The roles have separate replica and autoscaling settings, so you can scale them independently.
The chart defaults to one replica per enabled role. Plan availability and capacity for each mesh
and zone; enabling a second mesh creates another set of proxies rather than sharing the first.

### Universal

Run `kuma-dp` as an ordinary data plane proxy and supply a `Dataplane` with zone listeners.
This example declares an ingress listening on `10.0.0.20:10001`:

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

Replace the address with the proxy's listening address. Use `type: ZoneEgress` for an egress
listener. The listener `name` is the value policies use as `sectionName`; if omitted, the port
number becomes its name as a string. The API can represent both roles on one `Dataplane`,
though a Kubernetes deployment using the {{site.mesh_product_name}} Helm chart runs them as separate Deployments.

Use a dataplane token for control plane authentication, not a legacy zone-proxy token or
`--proxy-type=ingress`. Registration credentials are separate from the workload certificate
used for mesh mTLS. See [Universal data plane](/mesh/universal-data-plane/) for
startup and token configuration.

## Make ingress reachable from other zones

The ingress listener address is where the proxy listens. The address clients in another zone
can reach might instead belong to a load balancer or a Kubernetes node.

`MeshZoneAddress` publishes that reachable ingress address in `spec.address` and its port
in `spec.port`. The global control plane shares it so other zones can discover the
ingress. It doesn't open a firewall, configure DNS, or make a private address reachable.

On Kubernetes, the control plane maintains this resource from the ingress Service and its
ready endpoints. It can use a load balancer address, a NodePort address, or an explicit Service
external IP. A plain ClusterIP without an external address isn't sufficient for publication.
Inspect the generated value and check that it's reachable from the other zones.

Clients in other zones get endpoints for this zone's `MeshService` destinations only when this
zone has a `MeshZoneAddress` for the mesh and the mesh has at least one `MeshIdentity`. Without
either, cross-zone requests to the zone fail; a missing address makes the control plane log
`no MeshZoneAddress found for zone`.

On Universal, publish a `MeshZoneAddress` on the zone control plane for the mesh. For example,
if a load balancer forwards `ingress.zone-b.example.com:10001` to the `zone-ingress-01` `Dataplane`'s `ingress` listener:

```yaml
type: MeshZoneAddress
mesh: default
name: zone-b-ingress
spec:
  address: ingress.zone-b.example.com
  port: 10001
```

Keep this address aligned with the load balancer and the available ingress instances. Don't
manually overwrite a Kubernetes controller-owned `MeshZoneAddress`; change the Service
configuration that the controller derives it from.

## Establish identity before allowing traffic

[MeshIdentity](/mesh/policies/meshidentity/) selects the proxies that receive workload
identities. Include the egress proxies and the clients that connect to them in those selectors.
The egress listener requires a workload identity; without one, the control plane skips
generating that listener.

An egress listener also requires something to serve. Until a `MeshExternalService` exists in
the mesh, the control plane generates the proxy without an egress listener, even when an identity covers it. The
two causes produce the same symptom, so check both. First, list the identities:

```sh
kubectl get meshidentities -A
```

Then list the external services:

```sh
kubectl get meshexternalservices -A
```

A `ZoneEgress` listener on a running egress Pod's `Dataplane` doesn't prove that the listener exists:
the `Dataplane` shows the requested configuration, not the generated one. Confirm the proxy
received `self_zoneegress_dp_<listener name>` in its Envoy configuration. With the chart
defaults on Kubernetes, that is `self_zoneegress_dp_10002`.

[MeshTrust](/mesh/policies/meshtrust/) supplies the trust needed to validate peer
certificates. Trust establishes who the caller is; it doesn't grant access.
[MeshTrafficPermission](/mesh/policies/meshtrafficpermission/) grants that access.
Egress denies connections when no applicable allow rule matches.

Ingress doesn't terminate the workload TLS connection, so it can't authenticate the caller's
SPIFFE ID from that connection. Apply workload permissions to the destination proxy, not to
ingress as a substitute. The destination sees the original caller's identity, not the ingress's
identity. An identity assigned to the ingress doesn't change this forwarding behavior.

## Proxy and traffic selection

The top-level `spec.targetRef` selects the proxy that enforces the policy. Use
`kind: Dataplane` with the following computed resource labels:

{% table %}
columns:
  - title: Label
    key: label
  - title: Selects
    key: selects
rows:
  - label: "`kuma.io/listener-zoneingress: enabled`"
    selects: "`Dataplane` resources containing an ingress listener."
  - label: "`kuma.io/listener-zoneegress: enabled`"
    selects: "`Dataplane` resources containing an egress listener."
  - label: "`kuma.io/zone: zone-a`"
    selects: "`Dataplane` resources in `zone-a`; combine this with a role label."
{% endtable %}

These are `Dataplane` labels, not labels to copy onto the caller's application. A `Dataplane`
with both listener types has both role labels. Selecting its egress label selects the proxy,
not only the egress listener: use `targetRef.sectionName` to narrow listener-scoped policies.

On Kubernetes, inspect the resource on the zone control plane:

```sh
kubectl get dataplanes -A -l kuma.io/listener-zoneegress=enabled -o yaml
```

Read `.spec.networking.listeners[].name` and use that value for `sectionName`. If the name
is absent, use the listener's port as a quoted string, such as `"10002"`. Don't assume that
every installation uses the same listener name.

After selecting the proxy, the policy's own shape determines how you select traffic:

{% table %}
columns:
  - title: Policy
    key: policy
  - title: Configuration on the selected zone proxy
    key: configuration
  - title: Important boundary
    key: important
rows:
  - policy: "[MeshTrafficPermission](/mesh/policies/meshtrafficpermission/)"
    configuration: "`rules[].default.allow`, `deny`, or `allowWithShadowDeny`; match caller `spiffeID` and destination `sni`."
    important: "Enforces access on egress, where mesh mTLS terminates, not on TLS-passthrough ingress."
  - policy: "[MeshAccessLog](/mesh/policies/meshaccesslog/)"
    configuration: "`rules`, optionally with `matches` for destination SNI or authenticated caller identity."
    important: "Ingress can log connection information, not encrypted HTTP requests or authenticated caller identities."
  - policy: "[MeshTimeout](/mesh/policies/meshtimeout/)"
    configuration: "`rules` for received traffic and the supported timeout settings."
    important: "HTTP settings require an HTTP connection manager. Connection-level settings can't vary by authenticated caller."
  - policy: "[MeshRateLimit](/mesh/policies/meshratelimit/), [MeshFaultInjection](/mesh/policies/meshfaultinjection/)"
    configuration: "`rules`, with traffic matches where supported."
    important: "HTTP request limits and faults require decoded HTTP traffic on egress, not encrypted HTTP passing through ingress."
  - policy: "[MeshCircuitBreaker](/mesh/policies/meshcircuitbreaker/), [MeshHealthCheck](/mesh/policies/meshhealthcheck/)"
    configuration: "`to[].targetRef` selects the destination cluster, such as a `MeshExternalService` reached by egress."
    important: "These configure the proxy's connections to the destination, not the client's connection to the proxy."
  - policy: "[MeshMetric](/mesh/policies/meshmetric/)"
    configuration: "`default` configures collection and export for the selected proxy."
    important: "Metrics configuration doesn't depend on decoding HTTP traffic."
  - policy: "[MeshTrace](/mesh/policies/meshtrace/)"
    configuration: "`default` configures tracing; `sectionName` can narrow the listener."
    important: "Trace spans require HTTP processing; ingress TLS passthrough doesn't produce HTTP spans."
  - policy: "[MeshProxyPatch](/mesh/policies/meshproxypatch/)"
    configuration: "`default.appendModifications` changes generated proxy configuration."
    important: "Prefer a dedicated policy when one supports the change. A patch can invalidate a listener."
{% endtable %}

Not every workload policy applies to zone listeners. For example, use
client-side [MeshRetry](/mesh/policies/meshretry/) to retry requests, and don't use
[MeshOPA](/mesh/policies/meshopa/) as an authorization layer on zone egress. Check the linked
policy reference for supported protocols, fields and merge behavior.

### Allow one caller to one external destination

This policy selects egress proxies in `zone-a` and allows one caller to one destination.
Replace `CLIENT_SPIFFE_ID` with the URI from the caller's workload certificate. Replace
`DESTINATION_SNI` with the destination's server name from the egress listener configuration.

{% policy_yaml %}
```yaml
type: MeshTrafficPermission
mesh: default
name: allow-client-to-external-service
spec:
  targetRef:
    kind: Dataplane
    labels:
      kuma.io/listener-zoneegress: enabled
      kuma.io/zone: zone-a
  rules:
    - default:
        allow:
          - spiffeID:
              type: Exact
              value: CLIENT_SPIFFE_ID
            sni:
              type: Exact
              value: DESTINATION_SNI
```
{% endpolicy_yaml %}

The `spiffeID` and `sni` in this single entry must both match. The role and zone labels select
the enforcing proxy; they don't identify the caller or external destination.

The destination SNI is the internal name the client proxy sends to egress. It isn't necessarily
the external server's DNS name or its upstream TLS server name. Inspect the egress's active
Envoy configuration and copy the appropriate
`filter_chains[].filter_chain_match.server_names[]` value for your `MeshExternalService` into `sni.value`.

For the caller, `MeshTrust.spec.trustDomain` tells you the trust-domain part of the identity,
but the certificate URI also includes the workload path. Matching the full URI avoids guessing
either component. See [matching identities](/mesh/policies/meshtrafficpermission/#match-caller-identities) for
examples.

### Record traffic on egress

This policy writes access logs from the selected egress proxies to their standard output:

{% policy_yaml %}
```yaml
type: MeshAccessLog
mesh: default
name: log-zone-egress
spec:
  targetRef:
    kind: Dataplane
    labels:
      kuma.io/listener-zoneegress: enabled
  rules:
    - default:
        backends:
          - type: File
            file:
              path: /dev/stdout
```
{% endpolicy_yaml %}

To log selected callers
or destinations, add the `rules[].matches` described in
[MeshAccessLog](/mesh/policies/meshaccesslog/). Choose a format that includes the peer identity
and requested server name when you need an authorization audit trail.

## Account for policies that already apply

A mesh-wide policy can include zone proxies. A narrower policy doesn't automatically erase
the broader configuration: each policy type has its own merge rules.

For permissions, any matching deny wins over allows. Don't add a blanket deny-all and expect
the [allow example](#allow-one-caller-to-one-external-destination) to reopen access. Conversely, an existing broad allow can continue granting
traffic beyond this example's caller and destination. Review all applicable permissions before
using a narrow allow as evidence that you restricted access.

Rate limits are local to each proxy, not a shared allowance across replicas. Adding egress
replicas can increase aggregate allowed traffic. Access-log configurations can overlap and
emit multiple records. Check the policy-specific behavior before applying a broad baseline
and a role-specific exception.

## Verify the traffic path and policy effect

Check configuration and traffic separately:

1. Inspect the zone proxy `Dataplane`. Confirm its mesh, role labels, zone and listener names.
1. For ingress, inspect `MeshZoneAddress.spec.address` and `spec.port` and test reachability
   from another zone. A published address isn't proof that firewalls or load balancers allow it.
1. Inspect the proxy's active Envoy configuration. Confirm that the expected listener and
   destination chain exist and that Envoy accepted the configuration. The control plane might not
   generate a declared listener when it has no destinations; egress also needs an identity and endpoints.
1. Send a request through the intended path. For cross-zone traffic, confirm that the responding
   workload is in the remote zone. For egress, confirm that its logs or counters change.
1. Test the restriction as well as the allowance: use a different caller and a different external
   destination. Both should fail unless another permission explicitly allows them.

Use these checks to narrow failures:

{% table %}
columns:
  - title: Symptom
    key: symptom
  - title: Check
    key: check
rows:
  - symptom: "Proxy can't register"
    check: "The mesh exists, the zone control plane is reachable, and the proxy has valid registration credentials."
  - symptom: "No published ingress address"
    check: "The ingress Service has a usable external address and ready endpoints. On Universal, also check the zone's `MeshZoneAddress`."
  - symptom: "Egress Pod runs but its listener is absent"
    check: "A `MeshIdentity` selects the proxy, and there are external destinations with endpoints to serve."
  - symptom: "TLS handshake fails"
    check: "Caller and egress have certificates and compatible trust. For ingress traffic, check the caller and destination workload instead."
  - symptom: "Egress denies a request"
    check: "The actual caller URI and destination SNI match an allow, and no applicable deny matches."
  - symptom: "HTTP policy has no effect on ingress"
    check: "Ingress forwards encrypted bytes. Put request-level behavior on a proxy that processes the HTTP request."
  - symptom: "Policy affects both roles on a combined `Dataplane`"
    check: "Role labels select a `Dataplane`. Narrow the relevant listener-scoped policy with `sectionName`."
  - symptom: "Control plane accepts the resource but traffic doesn't change"
    check: "The policy selects the intended proxy, the relevant listener exists, and the selected protocol supports the requested behavior."
{% endtable %}
