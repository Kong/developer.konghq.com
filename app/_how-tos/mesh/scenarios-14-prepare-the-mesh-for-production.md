---
title: Prepare the mesh for production
content_type: how_to
permalink: /mesh/prepare-the-mesh-for-production/
description: Bound the outbound configuration each proxy receives with reachableBackends, and set the {{site.mesh_product_name}} 3.0 defaults that production depends on.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
products:
  - mesh
works_on:
  - on-prem
  - konnect
min_version:
  mesh: '3.0'
series:
  id: mesh-kong-air-scenario
  position: 14
tags:
  - service-mesh
  - data-plane
  - performance
tldr:
  q: How do I prepare my mesh for production traffic?
  a: |
    1. Profile the destinations that each workload calls with the DNS query log of its sidecar.
    2. Declare those destinations in the `kuma.io/reachable-backends` annotation of each workload.
    3. Set `restrictOutbound` to `true` on every zone control plane.
faqs:
  - q: Why does every proxy need `reachableBackends`?
    a: |
      `reachableBackends` lists the destinations that a proxy's workload calls, and the control plane sends the proxy configuration only for those destinations.
      Without it, the configuration grows with the number of services multiplied by the number of proxies.
      That costs control plane CPU and xDS bandwidth, and it slows down how fast a change reaches every proxy.

      With `restrictOutbound` set to `true`, the {{site.mesh_product_name}} 3.0 default, a proxy without `reachableBackends` gets no outbound configuration and reaches no destination in the mesh.
      The setting also closes outbound passthrough on every proxy that no `MeshPassthrough` policy selects.
      Don't run a production mesh with `restrictOutbound` set to `false`.
  - q: How does a `reachableBackends` ref select destinations?
    a: |
      A ref selects backends by `kind` and `labels`.
      `kind` accepts `MeshService`, `MeshMultiZoneService`, and `MeshExternalService`.
      The control plane computes `kuma.io/display-name` from the resource name, and `k8s.kuma.io/namespace` from its namespace.
      `port` is optional and narrows the ref to one port, so set it on a service that exposes more than one port.
      Every ref needs `labels`, and the control plane rejects a ref without them.
      To select every backend of a kind, set `labels: {}`.
      A ref that matches no resource adds no destination.
      For more information, see [reachableBackends](/mesh/concepts/#reachablebackends).
  - q: How do I declare reachable backends on Universal?
    a: |
      On Universal, you declare outbound destinations on the `Dataplane` resource.
      See [Differences from Kubernetes](/mesh/universal/#differences-from-kubernetes).
  - q: What doesn't the DNS query log show?
    a: |
      A resolved name shows that the workload tried to reach a destination, not that a connection happened.
      The query log records no port, so you decide whether a ref needs one.
      It also records nothing for a workload that connects to a literal IP address, because that workload makes no DNS query.
      The profiling window must cover the workload's normal behavior, including destinations that it calls only on a schedule or during a failure.
      Each log line carries `name`, `type`, `rcode`, `source`, `answers`, and `duration`.
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
    - title: Stop the Grafana port-forward
      content: |
        Stop the Grafana port-forward that runs in the background since [Observe mesh traffic in practice](/mesh/observe-mesh-traffic-in-practice/):

        ```sh
        kill $GRAFANA_PORT_FORWARD_PID
        ```
      icon_url: /assets/icons/code.svg
    - title: Remove the Kong Air foundation
      include_content: md/mesh/v3/cleanup/kong-air-foundation
      icon_url: /assets/icons/gateway.svg
    - title: Delete the working directory
      content: |
        Change to the parent directory, and delete the `kong-air-scenarios` directory and the files that the series created in it:

        ```sh
        cd ..
        rm -rf kong-air-scenarios
        ```
      icon_url: /assets/icons/code.svg
related_resources:
  - text: reachableBackends
    url: /mesh/concepts/#reachablebackends
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

Every earlier scenario added a capability to the Kong Air mesh, on a control plane that sets `restrictOutbound` to `false`.
With that setting, every proxy receives the configuration for every destination in the mesh, which costs control plane CPU and xDS bandwidth as the mesh grows.
Declare the destinations of each workload before you restrict outbound traffic, so that traffic keeps flowing during the change.

To learn more about what this guide does, read the following reference pages:

* [reachableBackends](/mesh/concepts/#reachablebackends): how a proxy declares the destinations it calls
* [Production readiness checklist](/mesh/production-readiness-checklist/): the settings to review before production

## Discover what each workload calls

1. Raise the log level of the DNS proxy in the `passenger-portal` sidecar.
   The annotation becomes an environment variable on the sidecar container, so it takes effect when Kubernetes recreates the Pod:

   ```sh
   kubectl patch deployment passenger-portal -n kong-air-production --type merge -p '
   spec:
     template:
       metadata:
         annotations:
           kuma.io/component-log-level: dnsproxy:debug
   '
   ```

1. Wait for the new Pods to roll out:

   ```sh
   kubectl rollout status deployment/passenger-portal -n kong-air-production --timeout=120s
   ```

1. Send a request from `passenger-portal` to `check-in-api`, so the DNS proxy logs a lookup:

   ```sh
   kubectl exec -n kong-air-production deploy/passenger-portal -- wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

   The request fails with `403 Forbidden`, because `MeshTrafficPermission` allows only `flight-control` to call `check-in-api`.
   The DNS proxy logs the lookup before the request reaches `check-in-api`, so the response isn't important.

1. Send a request from `passenger-portal` to `flight-control`:

   ```sh
   kubectl exec -n kong-air-production deploy/passenger-portal -- wget -q -T 5 -O- http://flight-control.kong-air-production.svc.cluster.local:8080/
   ```

   This request also fails with `403 Forbidden`, and the DNS proxy logs the lookup.

1. Read the distinct names that the workload resolved successfully.
   The `"rcode": "noerror"` filter drops the failed lookups that Kubernetes search domains add for each name:

   ```sh
   kubectl logs -n kong-air-production deploy/passenger-portal -c kuma-sidecar \
     | grep '"rcode": "noerror"' | grep -o '"name": "[^"]*"' | cut -d'"' -f4 | sort -u
   ```

   The output is the candidate list for `passenger-portal`:

   ```text
   check-in-api.kong-air-production.svc.cluster.local.
   flight-control.kong-air-production.svc.cluster.local.
   ```
   {:.no-copy-code}

1. Remove the log level annotation:

   ```sh
   kubectl patch deployment passenger-portal -n kong-air-production --type json \
     -p '[{"op": "remove", "path": "/spec/template/metadata/annotations/kuma.io~1component-log-level"}]'
   ```

## Declare reachable backends for Kong Air

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

1. Declare that `passenger-portal` calls `check-in-api` on port 8080, `baggage-api` in `zone2` on port 8080, and the `aeropay-api` external service:

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
             - kind: MeshService
               labels:
                 kuma.io/display-name: baggage-api
                 k8s.kuma.io/namespace: kong-air-production
                 kuma.io/zone: zone2
               port: 8080
             - kind: MeshExternalService
               labels:
                 kuma.io/display-name: aeropay-api
   '
   ```

1. Declare the same destinations for `passenger-portal-v2`:

   ```sh
   kubectl patch deployment passenger-portal-v2 -n kong-air-production --type merge -p '
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
             - kind: MeshService
               labels:
                 kuma.io/display-name: baggage-api
                 k8s.kuma.io/namespace: kong-air-production
                 kuma.io/zone: zone2
               port: 8080
             - kind: MeshExternalService
               labels:
                 kuma.io/display-name: aeropay-api
   '
   ```

1. Wait for the new Pods to roll out.
   The annotation lives on the Pod template, so the control plane reads it when Kubernetes recreates each Pod:

   ```sh
   kubectl rollout status deployment -n kong-air-production --timeout=120s
   ```

## Turn on restricted outbound

1. Set `KUMA_DEFAULTS_RESTRICT_OUTBOUND` to `true` on the `zone1` control plane:

   ```sh
   helm upgrade kong-mesh kong-mesh/kong-mesh \
     --namespace kong-mesh-system --reuse-values \
     --set kuma.controlPlane.envVars.KUMA_DEFAULTS_RESTRICT_OUTBOUND="true"
   ```

   The control plane restarts and regenerates every proxy's configuration.
   The data plane proxies don't restart.

1. Set the same value on the `zone2` control plane:

   ```sh
   helm upgrade kong-mesh kong-mesh/kong-mesh --kube-context "$ZONE2_CONTEXT" \
     --namespace kong-mesh-system --reuse-values \
     --set kuma.controlPlane.envVars.KUMA_DEFAULTS_RESTRICT_OUTBOUND="true"
   ```

1. Wait for the new control plane Pods to replace the old ones:

   ```sh
   kubectl rollout status deployment/kong-mesh-control-plane -n kong-mesh-system --timeout=90s
   kubectl --context "$ZONE2_CONTEXT" rollout status deployment/kong-mesh-control-plane -n kong-mesh-system --timeout=90s
   ```

1. Confirm that the `zone1` control plane runs with outbound traffic restricted.
   A control plane with the setting off logs a warning at startup that names `KUMA_DEFAULTS_RESTRICT_OUTBOUND`:

   ```sh
   kubectl logs -n kong-mesh-system deploy/kong-mesh-control-plane | grep 'KUMA_DEFAULTS_RESTRICT_OUTBOUND is disabled'
   ```

   The command prints nothing.

## Validate

1. Check the destinations that each Kong Air proxy declares:

   ```sh
   kubectl get dataplanes.kuma.io -n kong-air-production \
     -o custom-columns='APP:.metadata.labels.app,VERSION:.metadata.labels.version,REACHABLE BACKENDS:.spec.networking.transparentProxying.reachableBackends.refs[*].labels.kuma\.io/display-name'
   ```

   Each proxy lists the destinations from its annotation, so each annotation parsed:

   ```text
   APP                VERSION   REACHABLE BACKENDS
   check-in-api       v1        passenger-portal
   flight-control     v1        check-in-api,flight-db
   passenger-portal   v1        check-in-api,baggage-api,aeropay-api
   passenger-portal   v2        check-in-api,baggage-api,aeropay-api
   ```
   {:.no-copy-code}

   A proxy that shows `<none>` has no declaration, so it reaches no destination in the mesh.

1. Confirm that `passenger-portal` still reaches `check-in-api`, a destination that it declared:

   ```sh
   kubectl exec -n kong-air-production deploy/passenger-portal -- wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

   The request fails with `403 Forbidden`:

   ```text
   wget: server returned error: HTTP/1.1 403 Forbidden
   ```
   {:.no-copy-code}

   The inbound listener of `check-in-api` returned the `403`, so the request reached it.
   `MeshTrafficPermission` still allows only `flight-control` to call `check-in-api`.

1. Confirm that `passenger-portal` still reaches `baggage-api` in `zone2`, a destination that it declared and that `MeshTrafficPermission` allows:

   ```sh
   kubectl exec -n kong-air-production deploy/passenger-portal -- wget -q -T 5 -O- http://baggage-api.kong-air-production.svc.zone2.mesh.local:8080/
   ```

   The response is the name of the `baggage-api` Pod that served the request.

1. Confirm that `passenger-portal` can't reach `flight-control`, a destination that it didn't declare:

   ```sh
   kubectl exec -n kong-air-production deploy/passenger-portal -- wget -q -T 5 -O- http://flight-control.kong-air-production.svc.cluster.local:8080/
   ```

   The request gets no HTTP response, not even a `403`:

   ```text
   wget: error getting response: Resource temporarily unavailable
   ```
   {:.no-copy-code}

   The `passenger-portal` proxy has no cluster for `flight-control`, so the request fails at the caller.

1. Confirm that `flight-control` still reaches `check-in-api`, a destination that it declared and that `MeshTrafficPermission` allows:

   ```sh
   kubectl exec -n kong-air-production deploy/flight-control -- wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

   The response is the name of the `check-in-api` Pod that served the request.
