---
title: Mesh-scoped zone proxies
description: Understand zone ingress and zone egress in Mesh 3, deploy them for a mesh, and apply policies at the correct point in the traffic path.
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
  - text: Bring external traffic into the mesh
    url: /mesh/application-ingress/
  - text: Migrate zone proxies to Mesh 3
    url: /mesh/migrate-zone-proxies-to-3/
  - text: Deploy mesh-scoped zone proxies
    url: /mesh/zone-proxies/
  - text: How policies select traffic
    url: /mesh/policy-targeting/
  - text: MeshTrafficPermission policy
    url: /mesh/policies/meshtrafficpermission/
  - text: MeshIdentity policy
    url: /mesh/policies/meshidentity/
  - text: MeshMultiZoneService
    url: /mesh/meshmultizoneservice/
---

Zone proxies carry traffic between zones or from a mesh to external services. In
{{site.mesh_product_name}} 3, each zone proxy belongs to one mesh and is represented by a
`Dataplane`. Its `networking.listeners` entries give it an ingress or egress role.

This lets you select zone proxies with policies just as you select workload proxies. The
important difference is the traffic they handle: an ingress forwards an encrypted connection,
while an egress can inspect traffic after terminating mesh mTLS. Selecting a zone proxy does
not make every policy meaningful on both roles.

Use this reference to choose where to deploy a proxy, where to enforce a policy, and how to
verify the result. The [deployment walkthrough](/mesh/zone-proxies/) provides a complete
Kubernetes environment to try these concepts.

## Why the model changed in Mesh 3

The legacy `ZoneIngress` and `ZoneEgress` resources were shared across meshes in a zone.
That made them different from workload proxies: they did not belong to the mesh whose
identity, permissions and observability policies operators wanted to apply.

Mesh-scoped proxies bring those concerns together:

- **Identity belongs to the mesh.** Egress can receive a workload identity through
  `MeshIdentity` and authenticate callers before forwarding external traffic.
- **Policies target the proxy directly.** You select the Dataplane that enforces a permission,
  records a log or applies a limit, instead of relying on separate zone-proxy configuration.
- **Operations are scoped to a mesh.** Each mesh can have its own proxy capacity, telemetry
  and rollout, using the same Dataplane inspection and authentication model as workloads.

The tradeoff is more infrastructure: separate meshes need separate proxy capacity and can
need separate ingress load balancers. This provides a clearer configuration and operational
boundary, not automatic network isolation or permission to access another mesh.

Mesh-scoped proxies were introduced in 2.14; Mesh 3 removes support for the legacy standalone
proxy types. Existing customers should [migrate zone proxies before upgrading their zone
control planes](/mesh/migrate-zone-proxies-to-3/). This is a deployment and traffic migration,
not just a resource rename.

## Where traffic passes

For public application requests, use an [API gateway with a mesh sidecar](/mesh/application-ingress/).
Zone ingress carries connections from other mesh proxies; it does not replace a public API gateway.

| Role | Destination | What the proxy does | Where caller permissions are checked |
| --- | --- | --- | --- |
| Zone ingress | A service in the ingress's zone | Reads the destination name from TLS SNI and forwards the encrypted connection to a local workload proxy. It does not terminate workload mTLS. | On the destination workload proxy, which authenticates the original caller. |
| Zone egress | A registered `MeshExternalService` | Terminates mesh mTLS from the caller's proxy, then connects to the external endpoint. | On the egress, which authenticates the caller before forwarding traffic. |

For a request to a workload in another zone, the path is:

```text
Client proxy in zone A → zone ingress in zone B → destination proxy in zone B
```

Workload mTLS runs between the client and destination proxies, through ingress.

For a registered external destination reached through egress, the path is:

```text
Client proxy → zone egress → external endpoint
             mesh mTLS     separate connection, with TLS configured by MeshExternalService
```

Zone egress is not an additional hop in the cross-zone workload path shown above. Nor is it
an automatic gateway for every address an application can dial. Unknown destinations and
traffic outside interception are separate concerns; see
[MeshPassthrough](/mesh/policies/meshpassthrough/). Use network controls as well when you
must prevent applications from bypassing an approved exit path.

Deploying an ingress does not choose which remote service a client calls.
[MeshService](/mesh/meshservice/) and [MeshMultiZoneService](/mesh/meshmultizoneservice/)
describe the destinations; routing and load-balancing policies on the client determine where
its traffic goes. The ingress forwards the connection to the chosen service in its own zone.

## Deploy proxies for a mesh

Create the mesh separately and connect each proxy to its zone control plane. A proxy cannot
register successfully until its mesh exists. Create identities and permissions before sending
traffic: a running Pod alone does not mean the proxy can serve requests.

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
The entry does not create the `Mesh` resource or grant traffic permissions.

Each enabled role gets its own Deployment and Service. The ingress Service defaults to
`LoadBalancer` on port `10001`; egress defaults to `ClusterIP` on port `10002`. Both roles
are disabled by default. Enable only ingress if the zone needs to receive cross-zone workload
traffic but does not need this external-service egress path.

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
but the Kubernetes chart above deploys them separately.

Use a dataplane token for control plane authentication, not a legacy zone-proxy token or
`--proxy-type=ingress`. Registration credentials are separate from the workload certificate
used for mesh mTLS. See [Universal data plane proxies](/mesh/universal-data-plane/) for
startup and token configuration.

## Make ingress reachable from other zones

The ingress listener address is where the proxy listens. The address clients in another zone
can reach may instead belong to a load balancer or a Kubernetes node.

`MeshZoneAddress` publishes that reachable ingress address in `spec.address` and its port
in `spec.port`. It is shared through the global control plane so other zones can discover the
ingress. It does not open a firewall, configure DNS, or make a private address reachable.

On Kubernetes, the control plane maintains this resource from the ingress Service and its
ready endpoints. It can use a load balancer address, a NodePort address, or an explicit Service
external IP. A plain ClusterIP without an external address is not sufficient for publication.
Inspect the generated value and check that it is reachable from the other zones.

On Universal, publish a `MeshZoneAddress` on the zone control plane for the mesh. For example,
if a load balancer forwards `ingress.zone-b.example.com:10001` to the listener above:

```yaml
type: MeshZoneAddress
mesh: default
name: zone-b-ingress
spec:
  address: ingress.zone-b.example.com
  port: 10001
```

Keep this address aligned with the load balancer and the available ingress instances. Do not
manually overwrite a Kubernetes controller-owned `MeshZoneAddress`; change the Service
configuration it is derived from.

## Establish identity before allowing traffic

[MeshIdentity](/mesh/policies/meshidentity/) selects the proxies that receive workload
identities. Include the egress proxies and the clients that connect to them in those selectors.
The egress listener requires a workload identity; without one, the control plane skips
generating that listener.

[MeshTrust](/mesh/policies/meshtrust/) supplies the trust needed to validate peer
certificates. Trust establishes who the caller is; it does not grant access.
[MeshTrafficPermission](/mesh/policies/meshtrafficpermission/) grants that access.
Egress connections are denied when no applicable allow rule matches.

Ingress does not terminate the workload TLS connection, so it cannot authenticate the caller's
SPIFFE ID from that connection. Apply workload permissions to the destination proxy, not to
ingress as a substitute. The destination sees the original caller's identity, not the ingress's
identity. An identity assigned to the ingress does not change this forwarding behavior.

## Select the proxy, then select its traffic

The top-level `spec.targetRef` answers **which proxy enforces this policy**. Use
`kind: Dataplane` with these computed resource labels:

| Label | Selects |
| --- | --- |
| `kuma.io/listener-zoneingress: enabled` | Dataplanes containing an ingress listener. |
| `kuma.io/listener-zoneegress: enabled` | Dataplanes containing an egress listener. |
| `kuma.io/zone: zone-a` | Dataplanes in `zone-a`; combine this with a role label. |

These are `Dataplane` labels, not labels to copy onto the caller's application. A Dataplane
with both listener types has both role labels. Selecting its egress label selects the proxy,
not just the egress listener: use `targetRef.sectionName` to narrow listener-scoped policies.

On Kubernetes, inspect the resource on the zone control plane:

```sh
kubectl get dataplanes -A -l kuma.io/listener-zoneegress=enabled -o yaml
```

Read `.spec.networking.listeners[].name` and use that value for `sectionName`. If the name
is absent, use the listener's port as a quoted string, such as `"10002"`. Do not assume that
every installation uses the same listener name.

After selecting the proxy, the policy's own shape determines how you select traffic:

| Policy | Configuration on the selected zone proxy | Important boundary |
| --- | --- | --- |
| [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/) | `rules[].default.allow`, `deny`, or `allowWithShadowDeny`; match caller `spiffeID` and destination `sni`. | Enforces access on egress, where mesh mTLS terminates, not on TLS-passthrough ingress. |
| [MeshAccessLog](/mesh/policies/meshaccesslog/) | `rules`, optionally with `matches` for destination SNI or authenticated caller identity. | Ingress can log connection information, not encrypted HTTP requests or authenticated caller identities. |
| [MeshTimeout](/mesh/policies/meshtimeout/) | `rules` for received traffic and the supported timeout settings. | HTTP settings require an HTTP connection manager. Connection-level settings cannot vary by authenticated caller. |
| [MeshRateLimit](/mesh/policies/meshratelimit/), [MeshFaultInjection](/mesh/policies/meshfaultinjection/) | `rules`, with traffic matches where supported. | HTTP request limits and faults require decoded HTTP traffic on egress, not encrypted HTTP passing through ingress. |
| [MeshCircuitBreaker](/mesh/policies/meshcircuitbreaker/), [MeshHealthCheck](/mesh/policies/meshhealthcheck/) | `to[].targetRef` selects the destination cluster, such as a `MeshExternalService` reached by egress. | These configure the proxy's connections to the destination, not the client's connection to the proxy. |
| [MeshMetric](/mesh/policies/meshmetric/) | `default` configures collection and export for the selected proxy. | Metrics configuration does not depend on decoding HTTP traffic. |
| [MeshTrace](/mesh/policies/meshtrace/) | `default` configures tracing; `sectionName` can narrow the listener. | Trace spans require HTTP processing; ingress TLS passthrough does not produce HTTP spans. |
| [MeshProxyPatch](/mesh/policies/meshproxypatch/) | `default.appendModifications` changes generated proxy configuration. | Prefer a dedicated policy when one supports the change. A patch can invalidate a listener. |

This is not a promise that every workload policy applies to zone listeners. For example, use
client-side [MeshRetry](/mesh/policies/meshretry/) to retry requests, and do not use
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
the enforcing proxy; they do not identify the caller or external destination.

The destination SNI is the internal name the client proxy sends to egress. It is not necessarily
the external server's DNS name or its upstream TLS server name. Inspect the egress's active
Envoy configuration and copy the appropriate
`filter_chains[].filter_chain_match.server_names[]` value into `sni.value`. Identify the chain
for your `MeshExternalService`, rather than copying the first server name in the output.

For the caller, `MeshTrust.spec.trustDomain` tells you the trust-domain part of the identity,
but the certificate URI also includes the workload path. Matching the full URI avoids guessing
either component. See [matching identities](/mesh/policies/meshtrafficpermission/) for examples.

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

This records traffic; it does not allow traffic that permissions deny. To log selected callers
or destinations, add the `rules[].matches` described in
[MeshAccessLog](/mesh/policies/meshaccesslog/). Choose a format that includes the peer identity
and requested server name when you need an authorization audit trail.

## Account for policies that already apply

A mesh-wide policy can include zone proxies. A narrower policy does not automatically erase
the broader configuration: each policy type has its own merge rules.

For permissions, any matching deny wins over allows. Do not add a blanket deny-all and expect
the example above to reopen access. Conversely, an existing broad allow can continue granting
traffic beyond this example's caller and destination. Review all applicable permissions before
using a narrow allow as evidence that access is restricted.

Rate limits are local to each proxy, not a shared allowance across replicas. Adding egress
replicas can increase aggregate allowed traffic. Access-log configurations can overlap and
emit multiple records. Check the policy-specific behavior before applying a broad baseline
and a role-specific exception.

## Verify the traffic path and policy effect

Check configuration and traffic separately:

1. Inspect the zone proxy `Dataplane`. Confirm its mesh, role labels, zone and listener names.
1. For ingress, inspect `MeshZoneAddress.spec.address` and `spec.port` and test reachability
   from another zone. A published address is not proof that firewalls or load balancers allow it.
1. Inspect the proxy's active Envoy configuration. Confirm that the expected listener and
   destination chain exist and that Envoy accepted the configuration. A declared listener may
   not be generated when it has no destinations; egress also needs an identity and endpoints.
1. Send a request through the intended path. For cross-zone traffic, confirm that the responding
   workload is in the remote zone. For egress, confirm that its logs or counters change.
1. Test the restriction as well as the allowance: use a different caller and a different external
   destination. Both should fail unless another permission explicitly allows them.

Use these checks to narrow failures:

| Symptom | Check |
| --- | --- |
| Proxy cannot register | The mesh exists, the zone control plane is reachable, and the proxy has valid registration credentials. |
| No ingress address is published | The ingress Service has a usable external address and ready endpoints. On Universal, check the zone's `MeshZoneAddress`. |
| Egress Pod runs but its listener is absent | A `MeshIdentity` selects the proxy, and there are external destinations with endpoints to serve. |
| TLS handshake fails | Caller and egress have certificates and compatible trust. For ingress traffic, check the caller and destination workload instead. |
| Egress denies a request | The actual caller URI and destination SNI match an allow, and no applicable deny matches. |
| HTTP policy has no effect on ingress | Ingress forwards encrypted bytes. Put request-level behavior on a proxy that processes the HTTP request. |
| Policy affects both roles on a combined Dataplane | Role labels select a Dataplane. Narrow the relevant listener-scoped policy with `sectionName`. |
| Resource is accepted but traffic is unchanged | The policy selects the intended proxy, the relevant listener exists, and the selected protocol supports the requested behavior. |
