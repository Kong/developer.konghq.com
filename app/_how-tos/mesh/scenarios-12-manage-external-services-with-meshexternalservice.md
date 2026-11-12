---
title: Manage external services with MeshExternalService
content_type: how_to
permalink: /mesh/manage-external-services-with-meshexternalservice/
description: Model external dependencies like APIs and databases as MeshExternalService resources, so the mesh gives them stable hostnames, access control, TLS origination, and retries.
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
  position: 12
tldr:
  q: How do I manage specific external services as part of my mesh?
  a: |
    1. Create a `MeshExternalService` for each external dependency, so workloads call it through a generated hostname such as `aeropay-api.extsvc.mesh.local`.
    2. Allow each caller at the zone egress with a `MeshTrafficPermission` that matches the caller's SPIFFE ID and the service's SNI.
    3. Apply mesh policies, such as `MeshRetry`, to the external service.
faqs:
  - q: How does a `MeshExternalService` get its hostname?
    a: |
      A zone control plane creates a default `HostnameGenerator` named `local-mesh-external-service`.
      It gives each `MeshExternalService` created in the zone a hostname in the format `<name>.extsvc.mesh.local`.
      The control plane also assigns each `MeshExternalService` a virtual IP from `242.0.0.0/8`, and the hostname resolves to that virtual IP.
      For the `status` fields that record both, see [MeshExternalService](/mesh/meshexternalservice/#status).
  - q: How do I find the SNI of a `MeshExternalService`?
    a: |
      For a `MeshExternalService` created on a Kubernetes zone, the SNI uses the format `sni.extsvc.<mesh>.<zone>.<namespace>.<name>.<port>`, where the last segment is the `match.port`.
      Read the zone name from the zone egress `Dataplane`:

      ```bash
      kubectl get dataplanes.kuma.io -n {{site.mesh_namespace}} \
        -l kuma.io/listener-zoneegress=enabled \
        -o jsonpath='{.items[0].metadata.labels.kuma\.io/zone}{"\n"}'
      ```

      Use the fully qualified name `dataplanes.kuma.io`.
      If {{site.gateway_operator_product_name}} runs in the same cluster, the short name `dataplane` resolves to `dataplanes.gateway-operator.konghq.com`, and the command returns nothing.
      For more information, see [Authorize zone proxy traffic](/mesh/policies/meshtrafficpermission/#authorize-zone-proxy-traffic).
  - q: How do I find the SPIFFE ID of a workload?
    a: |
      {{site.mesh_product_name}} issues SPIFFE IDs in the format `spiffe://<trust-domain>/ns/<namespace>/sa/<service-account>`.
      The trust domain comes from the `MeshIdentity` that issues the workload's certificate.
      Find that `MeshIdentity` in the `issuedBackend` of the workload's `DataplaneInsight`, then read its trust domain:

      ```bash
      kubectl get meshidentity kong-air-certmanager-identity -n {{site.mesh_namespace}} \
        -o jsonpath='{.status.trustDomain}{"\n"}'
      ```

      For the trust domain and path templates, see [SPIFFE ID](/mesh/policies/meshidentity/#spiffe-id).
  - q: How do I give more workloads access to an external service?
    a: |
      Add entries under `rules[0].default.allow` of the `MeshTrafficPermission` on the zone egress.
      Each entry pairs a caller's SPIFFE ID with the SNI of a destination.
      To let a workload reach any external service through the zone egress, leave out the `sni` field from its entry.
  - q: Why doesn't `flight-db` use TLS origination?
    a: |
      A PostgreSQL client starts TLS inside the PostgreSQL protocol: it sends an `SSLRequest` message first, and only then starts the TLS handshake.
      The zone egress can't take part in that exchange, so it forwards the TCP connection, and the database client negotiates TLS with RDS end to end.
      Configure the client with `sslmode=verify-full`, so it checks the RDS certificate.
      Use TLS origination for protocols that start TLS immediately, such as HTTPS.
  - q: Why do requests to a `MeshExternalService` fail with `503`?
    a: |
      `MeshExternalService` traffic always goes through the mesh-scoped zone egress in the caller's zone, so check the following:
      * A zone egress serves the mesh. The Helm `meshes:` entry creates the zone proxy `Deployment` and its `Service`. A zone proxy without its `Service` registers as an ordinary `Dataplane` and never becomes a zone egress.
      * The caller has a workload identity. Without one, the caller's sidecar gets no cluster for the `MeshExternalService`.

      For the full path, see [Traffic paths](/mesh/mesh-scoped-zone-proxies/#traffic-paths).
  - q: How do I combine `MeshRetry` with other resilience policies?
    a: |
      Pair `MeshRetry` with `MeshCircuitBreaker`, so the mesh stops sending requests to an external service that's already failing.
      Add `MeshTimeout` to limit the total time spent on retries.
related_resources:
  - text: MeshExternalService
    url: /mesh/meshexternalservice/
  - text: Mesh-scoped zone proxies
    url: /mesh/mesh-scoped-zone-proxies/
  - text: Authorize zone proxy traffic
    url: /mesh/policies/meshtrafficpermission/#authorize-zone-proxy-traffic
  - text: MeshRetry
    url: /mesh/policies/meshretry/
  - text: MeshTrafficPermission
    url: /mesh/policies/meshtrafficpermission/
---

Kong Air's critical dependencies are AeroPay, its payment provider, and a managed PostgreSQL database for flight data.
Both run outside the mesh, so the mesh can't name them, control who calls them, or apply policies to the calls.

To learn more about what this guide does, read the following reference pages:

* [MeshExternalService](/mesh/meshexternalservice/): how the mesh describes a destination outside it
* [Mesh-scoped zone proxies](/mesh/mesh-scoped-zone-proxies/): how traffic leaves the zone through the zone egress
* [Authorize zone proxy traffic](/mesh/policies/meshtrafficpermission/#authorize-zone-proxy-traffic): how the zone egress allows each caller

## Define the flight database

1. Create a `MeshExternalService` named `flight-db` for the managed PostgreSQL instance, as a TCP destination on port 5432:

   ```sh
   kubectl apply -f - <<'EOF'
   apiVersion: kuma.io/v1alpha1
   kind: MeshExternalService
   metadata:
     name: flight-db
     namespace: {{site.mesh_namespace}}
     labels:
       kuma.io/mesh: kong-air-mesh
   spec:
     match:
       type: HostnameGenerator
       port: 5432
       protocol: tcp
     endpoints:
       - address: rds-instance-01.c7x2.us-east-1.rds.amazonaws.com
         port: 5432
   EOF
   ```

1. Allow `flight-control` to reach `flight-db` through the zone egress:

   ```sh
   kubectl apply -f - <<'EOF'
   apiVersion: kuma.io/v1alpha1
   kind: MeshTrafficPermission
   metadata:
     name: flight-db-access
     namespace: {{site.mesh_namespace}}
     labels:
       kuma.io/mesh: kong-air-mesh
   spec:
     targetRef:
       kind: Dataplane
       labels:
         kuma.io/listener-zoneegress: enabled
     rules:
       - default:
           allow:
             - spiffeID:
                 type: Exact
                 value: spiffe://internal.kongair.com/ns/kong-air-production/sa/flight-control
               sni:
                 type: Exact
                 value: sni.extsvc.kong-air-mesh.zone1.{{site.mesh_namespace}}.flight-db.5432
   EOF
   ```

## Define AeroPay with TLS origination

1. Create a `MeshExternalService` named `aeropay-api` with TLS origination to `api.aeropay.com`.
   Developers call `aeropay-api` over plain HTTP on port `80`, and the zone egress opens the TLS connection to the endpoint on port `443`, so the applications don't manage third-party CA bundles:

   ```sh
   kubectl apply -f - <<'EOF'
   apiVersion: kuma.io/v1alpha1
   kind: MeshExternalService
   metadata:
     name: aeropay-api
     namespace: {{site.mesh_namespace}}
     labels:
       kuma.io/mesh: kong-air-mesh
   spec:
     match:
       type: HostnameGenerator
       port: 80
       protocol: http
     endpoints:
       - address: api.aeropay.com
         port: 443
     tls:
       enabled: true
       verification:
         mode: Secured
         serverName: api.aeropay.com
   EOF
   ```

1. Allow `passenger-portal` to reach `aeropay-api` through the zone egress.
   The SNI ends with `80`, the `match.port` of `aeropay-api`:

   ```sh
   kubectl apply -f - <<'EOF'
   apiVersion: kuma.io/v1alpha1
   kind: MeshTrafficPermission
   metadata:
     name: aeropay-access
     namespace: {{site.mesh_namespace}}
     labels:
       kuma.io/mesh: kong-air-mesh
   spec:
     targetRef:
       kind: Dataplane
       labels:
         kuma.io/listener-zoneegress: enabled
     rules:
       - default:
           allow:
             - spiffeID:
                 type: Exact
                 value: spiffe://kong-air-mesh.zone1.mesh.local/ns/kong-air-production/sa/passenger-portal
               sni:
                 type: Exact
                 value: sni.extsvc.kong-air-mesh.zone1.{{site.mesh_namespace}}.aeropay-api.80
   EOF
   ```

## Retry failed calls to AeroPay

Create a `MeshRetry` that makes the `passenger-portal` sidecar retry failed calls to `aeropay-api` up to three times:

```sh
kubectl apply -f - <<'EOF'
apiVersion: kuma.io/v1alpha1
kind: MeshRetry
metadata:
  name: aeropay-retry-policy
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: passenger-portal
  to:
    - targetRef:
        kind: MeshExternalService
        labels:
          kuma.io/display-name: aeropay-api
      default:
        http:
          numRetries: 3
          retryOn:
            - 5xx
            - ConnectFailure
            - GatewayError
EOF
```

## Validate

1. Confirm that the control plane accepted both `MeshExternalService` resources and gave each one a mesh-generated hostname:

   ```sh
   kubectl get meshexternalservice -n {{site.mesh_namespace}}
   ```

   The `HOSTNAME` column shows the internal name of each external dependency:

   ```text
   NAME          HOSTNAME
   aeropay-api   aeropay-api.extsvc.mesh.local
   flight-db     flight-db.extsvc.mesh.local
   ```
   {:.no-copy-code}

1. Confirm that a mesh-scoped zone egress serves `kong-air-mesh`:

   ```sh
   kubectl get dataplanes.kuma.io -n {{site.mesh_namespace}} \
     -l kuma.io/listener-zoneegress=enabled,kuma.io/mesh=kong-air-mesh
   ```

   The output lists one `Dataplane`, named after the zone egress Pod.

1. Confirm that `flight-control` resolves the generated hostname of `flight-db`:

   ```sh
   kubectl exec -n kong-air-production deploy/flight-control -- nslookup flight-db.extsvc.mesh.local
   ```

   The hostname resolves to an address in the `MeshExternalService` virtual IP range, `242.0.0.0/8`.

1. Confirm that the permission controls access.
   Call the AeroPay hostname from `check-in-api`:

   ```sh
   kubectl exec -n kong-air-production deploy/check-in-api -- wget -q -T 10 -O- http://aeropay-api.extsvc.mesh.local
   ```

   The command fails with `403 Forbidden`.
   The connection reached the zone egress, and the zone egress denied it, because `aeropay-access` allows only `passenger-portal`.
