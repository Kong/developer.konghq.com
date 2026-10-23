---
title: Prepare the mesh for production
content_type: how_to
permalink: /mesh/prepare-the-mesh-for-production/
description: Bound the outbound configuration each proxy receives with reachableBackends, and set the {{site.mesh_product_name}} 3.0 defaults that production depends on.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
tools:
  - kongctl
products:
  - mesh
works_on:
  - on-prem
  - konnect
min_version:
  mesh: '3.0'
series:
  id: mesh-kong-air-scenario
  position: 13
tags:
  - service-mesh
  - data-plane
  - performance
tldr:
  q: What do I have to get right before this mesh carries production traffic?
  a: |
    Declare `reachableBackends` on every data plane proxy.
    `reachableBackends` limits the configuration that the control plane generates and sends to each proxy.
    {{site.mesh_product_name}} 3.0 defaults `restrictOutbound` to `true`, so a proxy without `reachableBackends` reaches no destination in the mesh.

    Then review the other 3.0 defaults that are closed, such as outbound passthrough, retries, inbound ports, and the certificate authority behind your workload identity. See the [production readiness checklist](/mesh/production-readiness-checklist/).
faqs:
  - q: How do I spot destinations a workload starts calling after the profiling window?
    a: |
      The DNS proxy in `kuma-dp` exports metrics that keep tracking lookups after the profiling window ends.
      `kuma_dp_dns_queries_total` counts queries by type and source.
      `kuma_dp_dns_response_codes_total` counts responses by code.
      `kuma_dp_dns_entries_total` reports the size of the proxy's DNS map.
      Each metric carries `mesh`, `kuma_io_zone`, `kuma_workload`, and `k8s_kuma_io_namespace` labels, so you can see which workload sent the queries.

      The DNS proxy metrics don't carry a hostname label, because a hostname label makes their cardinality grow with every name a workload resolves.
      The metrics show that a workload resolves more names than you expected, and the query log shows which names.
      Scrape the metrics through [MeshMetric](/mesh/policies/meshmetric/), as in [Deploy an OpenTelemetry collector](/mesh/deploy-an-opentelemetry-collector/).
  - q: What does the `source` field in the DNS query log mean?
    a: |
      The `source` field in the DNS query log reports whether the proxy answered from its own DNS map or forwarded the query to the cluster resolver.
      The field doesn't show whether the destination is in the mesh.
      On Kubernetes, a workload addresses a `MeshService` through the Kubernetes `Service` ClusterIP.
      So the proxy's map holds few names, and a lookup of a Kubernetes `Service` name reads `source: upstream`.
      A lookup with `source: upstream` can still point to a destination inside the mesh.
cleanup:
  inline:
    - title: Remove the reachable backend declarations
      include_content: md/mesh/v3/cleanup/reachable-backends
    - title: Remove the Kong Air foundation
      include_content: md/mesh/v3/cleanup/kong-air-foundation
next_steps:
  - text: "Reference: Production readiness checklist"
    url: "/mesh/production-readiness-checklist/"
related_resources:
  - text: Production readiness checklist
    url: /mesh/production-readiness-checklist/
  - text: Secure the perimeter with MeshPassthrough
    url: /mesh/secure-the-perimeter-with-meshpassthrough/
  - text: Manage external services with MeshExternalService
    url: /mesh/manage-external-services-with-meshexternalservice/
  - text: Integrate an external CA
    url: /mesh/integrate-an-external-ca/
  - text: Concepts
    url: /mesh/concepts/
---

Every earlier scenario added a capability to the Kong Air mesh.
This guide prepares the resulting mesh for production.

You limit what the control plane computes and sends to each proxy.
That limit decides whether the mesh still performs well when Kong Air runs three hundred services instead of three.
For the other {{site.mesh_product_name}} 3.0 defaults, and the controls that shape configuration at scale, see the [production readiness checklist](/mesh/production-readiness-checklist/).

## Why every proxy needs reachableBackends

`reachableBackends` lists the destinations that a data plane proxy's workload calls.
The Kong Air control plane runs with `restrictOutbound` set to `false`, so it sends every proxy the configuration for every destination in the mesh.
That configuration grows with the number of services multiplied by the number of proxies.
It costs control plane CPU and xDS bandwidth, and it slows down how fast a change reaches every proxy.
When a proxy declares `reachableBackends`, the control plane sends it configuration only for the declared destinations.
For how a proxy reaches a `MeshService`, see [MeshService](/mesh/meshservice/).

{{site.mesh_product_name}} 3.0 defaults `restrictOutbound` to `true`.
With the default, a proxy that declares no `reachableBackends` gets no outbound configuration and reaches no destination in the mesh.
The Kong Air control plane turns the setting off, so each earlier scenario could focus on one idea without an outbound declaration.
In this guide, you declare what each workload calls, then turn the setting on.
That order keeps traffic flowing during the change.
On Universal, you declare outbound destinations on the `Dataplane` resource. See [Differences from Kubernetes](/mesh/universal/#differences-from-kubernetes).

{:.warning}
> `defaults.restrictOutbound: false` is not the {{site.mesh_product_name}} 3.0 default.
> The Kong Air control plane uses it so that the demo mesh starts open.
> With this setting, every proxy without `reachableBackends` can reach every destination in the mesh and receives configuration for all of them.
> Every proxy that no `MeshPassthrough` policy selects can also reach any address outside the mesh.
> Do not run a production mesh with this setting.

## Discover what each workload calls

This guide writes out the Kong Air call graph, but you usually need to discover your own.
A `reachableBackends` list built from an old architecture diagram can drop a destination that a workload depends on.

The sidecar resolves DNS through a DNS proxy embedded in `kuma-dp`.
That DNS proxy can log every name a workload looks up, with the answer it returned.
When you raise the log level for that one component, the sidecar log records what the workload tried to reach.

1. Raise the log level for the DNS proxy on the workload you want to profile:

   ```sh
   kubectl patch deployment passenger-portal -n kong-air-production --type merge -p '
   spec:
     template:
       metadata:
         annotations:
           kuma.io/component-log-level: dnsproxy:debug
   '
   ```

   The `kuma.io/component-log-level` annotation raises the log level of one component, so the rest of `kuma-dp` stays at its normal level. The annotation becomes an environment variable on the sidecar container, so it takes effect when Kubernetes recreates the pod.

1. Wait for the new pods to roll out:

   ```sh
   kubectl rollout status deployment/passenger-portal -n kong-air-production --timeout=120s
   ```

1. Generate the lookups to profile. The Kong Air demo apps don't call each other on their own, so send a request from `passenger-portal` to `check-in-api`:

   ```sh
   kubectl exec -n kong-air-production deploy/passenger-portal -- wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

1. Send a request from `passenger-portal` to `flight-control`:

   ```sh
   kubectl exec -n kong-air-production deploy/passenger-portal -- wget -q -T 5 -O- http://flight-control.kong-air-production.svc.cluster.local:8080/
   ```

   The query log records the DNS lookup, so the response doesn't matter here. On your own workloads, let the workload serve its normal traffic instead. The profiling window must cover the workload's normal behavior, including destinations it calls only on a schedule or during a failure.

1. Read back the distinct names the workload resolved successfully:

   ```sh
   kubectl logs -n kong-air-production deploy/passenger-portal -c kuma-sidecar \
     | grep '"rcode": "noerror"' | grep -o '"name": "[^"]*"' | cut -d'"' -f4 | sort -u
   ```

   Expected output:

   ```text
   check-in-api.kong-air-production.svc.cluster.local.
   flight-control.kong-air-production.svc.cluster.local.
   ```
   {:.no-copy-code}

   That output is the candidate list. Each full log line carries `name`, `type`, `rcode`, `source`, `answers`, and `duration`, so when you drop the filter, you see what each lookup resolved to.

1. Remove the log level annotation once you have the list. Debug logging on a busy workload is expensive, so turn off the query log after you profile:

   ```sh
   kubectl patch deployment passenger-portal -n kong-air-production --type json \
     -p '[{"op": "remove", "path": "/spec/template/metadata/annotations/kuma.io~1component-log-level"}]'
   ```

{:.warning}
> Filter on `"rcode": "noerror"`. Kubernetes resolves names with `ndots:5`.
> For one lookup of `check-in-api.kong-air-production.svc.cluster.local`, the resolver first tries that name with each search domain appended.
> The log shows several `nxdomain` lines before the line that resolves, so without the filter, one destination looks like four.

A resolved name shows that the workload tried to reach a destination.
It doesn't prove that a connection happened.
The query log also has the following gaps:
* It records no port, so you decide whether a ref needs one.
* It records nothing for a workload that connects to a literal IP address, because that workload makes no DNS query.

Treat the list as a starting point, and confirm it with the reachability checks in [Validate](#validate).

## Declare reachable backends for Kong Air

The Kong Air call graph is small enough to write out in full.
The earlier scenarios set up the following calls:

* `flight-control` calls `check-in-api`, which [Create a security policy](/mesh/create-a-security-policy/) allows, and the `flight-db` database.
* `check-in-api` calls `passenger-portal`, which [Split traffic with MeshService resources](/mesh/split-traffic-with-meshservice-resources/) allows.
* `passenger-portal` calls `check-in-api` and the `aeropay-api` payment service.

The external services `flight-db` and `aeropay-api` come from [Manage external services with MeshExternalService](/mesh/manage-external-services-with-meshexternalservice/).
A ref that matches no resource adds no destination, so the declarations work whether or not you kept those resources.
Three declarations cover the whole mesh.
The profile in [Discover what each workload calls](#discover-what-each-workload-calls) also recorded a lookup of `flight-control` from `passenger-portal`.
That lookup came from a test request, not from a call that `passenger-portal` needs, so the declaration leaves it out.

1. Declare that `flight-control` calls `check-in-api` on port 8080 and the `flight-db` external service:

   ```sh
   kubectl patch deployment flight-control -n kong-air-production --type merge -p '
   spec:
     template:
       metadata:
         annotations:
           kuma.io/reachable-backends: |
             refs:
             - kind: MeshService
               labels:
                 kuma.io/display-name: check-in-api
                 k8s.kuma.io/namespace: kong-air-production
               port: 8080
             - kind: MeshExternalService
               labels:
                 kuma.io/display-name: flight-db
   '
   ```

   A ref selects backends by `kind` and `labels`. The control plane computes both labels: `kuma.io/display-name` is the resource name, and `k8s.kuma.io/namespace` is its namespace. `port` is optional and narrows the ref to one port. Set it on a service that exposes more than one port. Every ref needs `labels`, and the control plane rejects a ref without them. To select every backend of a kind, set `labels: {}`.

1. Declare that `check-in-api` calls `passenger-portal` on port 8080:

   ```sh
   kubectl patch deployment check-in-api -n kong-air-production --type merge -p '
   spec:
     template:
       metadata:
         annotations:
           kuma.io/reachable-backends: |
             refs:
             - kind: MeshService
               labels:
                 kuma.io/display-name: passenger-portal
                 k8s.kuma.io/namespace: kong-air-production
               port: 8080
   '
   ```

1. Declare that `passenger-portal` calls `check-in-api` on port 8080 and the `aeropay-api` external service:

   ```sh
   kubectl patch deployment passenger-portal -n kong-air-production --type merge -p '
   spec:
     template:
       metadata:
         annotations:
           kuma.io/reachable-backends: |
             refs:
             - kind: MeshService
               labels:
                 kuma.io/display-name: check-in-api
                 k8s.kuma.io/namespace: kong-air-production
               port: 8080
             - kind: MeshExternalService
               labels:
                 kuma.io/display-name: aeropay-api
   '
   ```

1. Wait for the new pods to roll out. The annotation lives on the pod template, so the control plane reads it when Kubernetes recreates each pod:

   ```sh
   kubectl rollout status deployment -n kong-air-production --timeout=120s
   ```

A ref can also select `MeshMultiZoneService` backends. See [reachableBackends](/mesh/concepts/#reachablebackends) for what a ref can select.

## Turn on restricted outbound

Each Kong Air workload now declares its destinations, so you can restrict outbound traffic without breaking a call path.
On a running mesh, always declare first and restrict second.
If you restrict first, the proxies drop every call that you haven't declared yet.
The setting also closes outbound passthrough on every proxy that no `MeshPassthrough` policy selects.
See [Secure the perimeter with MeshPassthrough](/mesh/secure-the-perimeter-with-meshpassthrough/).

1. Set `KUMA_DEFAULTS_RESTRICT_OUTBOUND` to `true` on the zone control plane:

   ```sh
   helm upgrade kong-mesh kong-mesh/kong-mesh \
     --namespace kong-mesh-system --reuse-values \
     --set kuma.controlPlane.envVars.KUMA_DEFAULTS_RESTRICT_OUTBOUND="true"
   ```

   The control plane restarts and regenerates every proxy's configuration. The data plane proxies don't restart. They receive the new configuration on their next xDS refresh. See [The xDS refresh interval](/mesh/production-readiness-checklist/#xds-refresh-interval).

1. Wait for the new control plane pod to replace the old one:

   ```sh
   kubectl rollout status deployment/kong-mesh-control-plane -n kong-mesh-system --timeout=90s
   ```

1. Confirm that the control plane runs with outbound traffic restricted. A control plane that runs with the setting off logs a warning at startup that names `KUMA_DEFAULTS_RESTRICT_OUTBOUND`. Search the control plane log for that warning:

   ```sh
   kubectl logs -n kong-mesh-system deploy/kong-mesh-control-plane | grep 'KUMA_DEFAULTS_RESTRICT_OUTBOUND is disabled'
   ```

   Expected result: the command prints nothing. Once the setting is on, the control plane doesn't log that warning.

## Validate

1. Read the generated `Dataplane` resources back from the control plane:

   ```sh
   kongctl get mesh dataplanes --control-plane-name "$MESH_CP" --mesh kong-air-mesh -o yaml
   ```

   Each of the three Kong Air proxies carries its declaration under `networking.transparentProxying.reachableBackends`. The output shows what the control plane computed from your annotations, so it confirms that each annotation parsed.

1. Confirm that `passenger-portal` still reaches `check-in-api`, the destination it declared:

   ```sh
   kubectl exec -n kong-air-production deploy/passenger-portal -- wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

   Expected output:

   ```text
   wget: server returned error: HTTP/1.1 403 Forbidden
   ```
   {:.no-copy-code}

   A `403` is the expected result. The inbound listener of `check-in-api` returned it, and a listener can only refuse a connection that arrived. So the outbound cluster exists, and the proxy delivered the request. [Create a security policy](/mesh/create-a-security-policy/) allowed only `flight-control`, so `MeshTrafficPermission` still denies `passenger-portal`. Reachability and authorization are separate checks, and this request passed the first one.

1. Confirm that `passenger-portal` can't reach `flight-control`, a destination it didn't declare:

   ```sh
   kubectl exec -n kong-air-production deploy/passenger-portal -- wget -q -T 5 -O- http://flight-control.kong-air-production.svc.cluster.local:8080/
   ```

   Expected output:

   ```text
   wget: error getting response: Resource temporarily unavailable
   ```
   {:.no-copy-code}

   This request gets no HTTP response at all, not even a `403`. The caller's proxy has no cluster for `flight-control`, so the request fails at the caller and never reaches `flight-control`. Before `passenger-portal` declared `reachableBackends`, the same request reached `flight-control` and returned `403`. The two failures tell you which check stopped the traffic.

1. Confirm that `flight-control` still reaches `check-in-api`, a destination that it declared and that `MeshTrafficPermission` allows:

   ```sh
   kubectl exec -n kong-air-production deploy/flight-control -- wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

   The response is the name of the `check-in-api` Pod that served the request:

   ```text
   check-in-api-6b4584fff-d58rx
   ```
   {:.no-copy-code}

   The call works because `flight-control` declared `check-in-api` and the permission allows it. A call needs both: a ref for reachability and a permission for authorization. Use these checks on your own service map. If a workload needs a destination, give it a ref, and don't rely on the permission alone.
