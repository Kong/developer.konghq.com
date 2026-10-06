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
    Declare `reachableBackends` on every data plane proxy. It bounds the configuration the control plane generates and ships to each proxy, and in {{site.mesh_product_name}} 3.0 a proxy without it reaches nothing at all, because restricted outbound is on by default.

    Then work through the rest of the 3.0 defaults that are now closed rather than open, such as outbound passthrough, retries, inbound ports, and the certificate authority behind your workload identity. See the [production readiness checklist](/mesh/production-readiness-checklist/).
faqs:
  - q: How do I spot destinations a workload starts calling after the profiling window?
    a: |
      The same DNS proxy exports metrics, which is the ongoing signal once the profiling window is over. `kuma_dp_dns_queries_total` counts queries by type and source, `kuma_dp_dns_response_codes_total` counts responses by code, and `kuma_dp_dns_entries_total` reports the size of the proxy's map. Each carries `mesh`, `kuma_io_zone`, `kuma_workload`, and `k8s_kuma_io_namespace` labels, so you can see which workload the queries came from.

      The metrics are not labeled by hostname, deliberately, since that would make their cardinality grow with every name a workload resolves. They tell you that a workload is resolving more than you expected, and the query log tells you which name. Scrape them through [MeshMetric](/mesh/policies/meshmetric/), as set up in [Deploy an OpenTelemetry collector](/mesh/deploy-an-opentelemetry-collector/).
  - q: What does the `source` field in the DNS query log mean?
    a: |
      The `source` field reports whether the proxy answered from its own DNS map or forwarded the query to the cluster resolver, which is not the same as whether the destination is in the mesh. On Kubernetes, a `MeshService` is addressed through the Kubernetes `Service` ClusterIP, so the proxy's map is typically empty and every lookup reads `source: upstream`. Do not read `upstream` as "outside the mesh".
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

Every scenario so far has added a capability to the Kong Air mesh. This one takes the mesh that results and makes it fit to run.

This guide bounds what the control plane has to compute and ship to each proxy, which is what decides whether the mesh still behaves when Kong Air has three hundred services instead of three. For the {{site.mesh_product_name}} 3.0 defaults that are closed rather than open, and the other controls that shape configuration at scale, see the [production readiness checklist](/mesh/production-readiness-checklist/).

## Why every proxy needs reachableBackends

By default the control plane assumes any workload might call any destination in its mesh. Each proxy therefore receives a cluster and an endpoint set for every destination, and the total configuration the control plane generates grows with the number of services multiplied by the number of proxies. The control plane regenerates that configuration on a timer and ships it over xDS, so the cost lands on control plane CPU, on xDS bandwidth, and on how long a change takes to reach the fleet.

`reachableBackends` replaces that assumption with a declaration. A proxy that states which destinations its workload actually calls receives configuration for those destinations and nothing else, which keeps the per-proxy configuration flat as the service count grows.

In {{site.mesh_product_name}} 3.0 the control plane setting `defaults.restrictOutbound` defaults to `true`, and a data plane proxy that declares no `reachableBackends` receives no outbound clusters at all. It cannot reach any service through the proxy.

The Kong Air control plane in this collection was installed with that setting turned off, so that every scenario up to this point could teach one idea without also requiring an outbound declaration for it. This guide reverses that. You declare what each workload calls, then turn the setting on, which is the order a running mesh has to follow if it is not to drop traffic in between.

{:.warning}
> `defaults.restrictOutbound` set to `false` is the pre-3.0 behavior, where every proxy can reach every destination and receives configuration for all of them. Treat it as a position to migrate off, not a setting to leave alone.

## Discover what each workload calls

The Kong Air call graph is written out in this guide. Your own is not, and a `reachableBackends` list built from an out-of-date architecture diagram is how a workload loses a destination it quietly depended on.

The sidecar resolves DNS through an embedded proxy in `kuma-dp`, and that proxy can log every name a workload looks up along with the answer it returned. Raise the log level for that one component and the sidecar log becomes a record of what the workload tried to reach.

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

   The annotation raises one component rather than the whole sidecar, so you get the query log without the rest of `kuma-dp` at debug. It becomes an environment variable on the sidecar container, so it takes effect when the pod is recreated.

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

   The query log records the DNS lookup, so the response doesn't matter here. On your own workloads, let the workload serve its normal traffic instead. A profiling window has to cover the workload's real behavior, including the destinations it only reaches on a schedule or during a failure path.

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

   That is the candidate list. Each full log line carries `name`, `type`, `rcode`, `source`, `answers`, and `duration`, so dropping the filter shows what each lookup resolved to.

1. Turn the log level back off once you have the list. Debug logging on a busy workload is expensive, and the query log is a profiling tool rather than something to leave running:

   ```sh
   kubectl patch deployment passenger-portal -n kong-air-production --type json \
     -p '[{"op": "remove", "path": "/spec/template/metadata/annotations/kuma.io~1component-log-level"}]'
   ```

{:.warning}
> Filter on `"rcode": "noerror"`. Kubernetes resolves names with `ndots:5`, so a single lookup for `check-in-api.kong-air-production.svc.cluster.local` first tries that name with each search domain appended and logs several `nxdomain` lines before the one that resolves. Reading the log unfiltered makes one destination look like four.

A resolved name is evidence that the workload tried to reach something, not proof of a connection, and the log has two blind spots worth knowing before you treat its output as a finished list. It records no port, so you still have to decide whether a ref needs one. It also records nothing for a workload that connects to a literal IP address, because that path makes no DNS query at all. Treat the list as the starting point and confirm it with the reachability checks in [Validate](#validate).

## Declare reachable backends for Kong Air

The Kong Air call graph is small enough to write out in full. `passenger-portal` calls `check-in-api`, `check-in-api` calls `flight-control`, and `flight-control` calls nothing. Three declarations cover the whole mesh.

1. Declare what `passenger-portal` reaches:

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
   '
   ```

   A ref selects backends by `kind` and `labels`. `kuma.io/display-name` is the service name and `k8s.kuma.io/namespace` is its namespace, both computed by the control plane. `port` is optional and narrows the ref to a single port, which is worth setting on a service that exposes more than one.

1. Declare what `check-in-api` reaches:

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
                 kuma.io/display-name: flight-control
                 k8s.kuma.io/namespace: kong-air-production
               port: 8080
   '
   ```

1. Declare that `flight-control` reaches nothing:

   ```sh
   kubectl patch deployment flight-control -n kong-air-production --type merge -p '
   spec:
     template:
       metadata:
         annotations:
           kuma.io/reachable-backends: |
             refs: []
   '
   ```

   An empty `refs` list is a real declaration, not a missing one. `flight-control` is a leaf service: it answers requests and originates none. Writing that down means a future change that gives it an outbound dependency has to be declared too, rather than working by accident.

1. Wait for the new pods to roll out. The annotation lives on the pod template, so the control plane sees it when the pod is recreated:

   ```sh
   kubectl rollout status deployment -n kong-air-production --timeout=120s
   ```

A ref can also select `MeshMultiZoneService` and `MeshExternalService` backends. See [reachableBackends](/mesh/concepts/#reachablebackends) for what a ref can select.

## Turn on restricted outbound

The three declarations are in place, so the mesh can now be closed without taking anything with it. Declaring first and closing second is the order to follow on a real mesh: closing first would drop every call that has not yet been declared.

1. Set `KUMA_DEFAULTS_RESTRICT_OUTBOUND` to `true` on the zone control plane:

   ```sh
   helm upgrade kong-mesh kong-mesh/kong-mesh \
     --namespace kong-mesh-system --reuse-values \
     --set kuma.controlPlane.envVars.KUMA_DEFAULTS_RESTRICT_OUTBOUND="true"
   ```

   The control plane restarts and regenerates every proxy's configuration. The data plane proxies themselves do not restart, and they pick up the new configuration on their next xDS refresh. See [The xDS refresh interval](/mesh/production-readiness-checklist/#the-xds-refresh-interval).

1. Wait for the control plane to be ready:

   ```sh
   kubectl wait -n kong-mesh-system --for=condition=ready pod \
     --selector=app=kong-mesh-control-plane --timeout=90s
   ```

1. Confirm the control plane is running with outbound restricted:

   ```sh
   kubectl get pods -n kong-mesh-system -l app=kong-mesh-control-plane
   ```

   A control plane running with the setting off logs a warning at startup naming `KUMA_DEFAULTS_RESTRICT_OUTBOUND`. Once it is on, that warning is absent.

## Validate

1. Read the generated `Dataplane` resources back from the control plane:

   ```sh
   kongctl get mesh dataplanes --control-plane-name "$MESH_CP" --mesh kong-air-mesh -o yaml
   ```

   Each of the three Kong Air proxies carries its declaration under `networking.transparentProxying.reachableBackends`, and `flight-control` carries an empty object rather than no field at all. This reports what the control plane computed rather than what you wrote, so it is the authoritative answer to whether the annotation parsed.

1. Confirm that a declared destination is still reachable. `passenger-portal` declared `check-in-api`:

   ```sh
   kubectl exec -n kong-air-production deploy/passenger-portal -- wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

   Expected output:

   ```text
   wget: server returned error: HTTP/1.1 403 Forbidden
   ```
   {:.no-copy-code}

   A `403` is the right result here. It comes from `check-in-api`'s own inbound listener, which can only refuse a connection that arrived, so the outbound cluster exists and the request was delivered. [Create a security policy](/mesh/create-a-security-policy/) authorized `flight-control` and nothing else, so `MeshTrafficPermission` still denies `passenger-portal`. Reachability and authorization are separate gates, and this request cleared the first one.

1. Confirm that an undeclared destination is not reachable. `passenger-portal` never declared `flight-control`:

   ```sh
   kubectl exec -n kong-air-production deploy/passenger-portal -- wget -q -T 5 -O- http://flight-control.kong-air-production.svc.cluster.local:8080/
   ```

   Expected output:

   ```text
   wget: error getting response: Resource temporarily unavailable
   ```
   {:.no-copy-code}

   No `403`, and no HTTP response at all. The caller's proxy has no cluster for that destination, so the request fails at the caller and never reaches `flight-control`. Without the declaration the same request returns `403`, so the two failures tell you which gate stopped the traffic.

1. Confirm that `refs: []` means what it says. `flight-control` reached `check-in-api` successfully at the end of [Create a security policy](/mesh/create-a-security-policy/), and `MeshTrafficPermission` still authorizes it:

   ```sh
   kubectl exec -n kong-air-production deploy/flight-control -- wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

   Expected output:

   ```text
   wget: error getting response: Resource temporarily unavailable
   ```
   {:.no-copy-code}

   An authorized path that the caller has not declared is not a path. Treat this as the check on your own service map: if a workload turns out to need a destination, give it a ref rather than leaving the permission to carry the traffic on its own.
