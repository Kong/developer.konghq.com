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
  position: 11
tldr:
  q: How do I manage specific external services as part of my mesh?
  a: |
    Create a **MeshExternalService** for each external dependency to:
    1. **Assign a stable hostname**: Workloads call external APIs through internal names (for example, `aeropay-api.extsvc.mesh.local`).
    2. **Get observability**: Collect metrics and logs for outbound calls, as you do for internal services.
    3. **Apply resiliency**: Configure retries and timeouts for external dependencies with `MeshRetry`, `MeshTimeout`, and related mesh policies.
prereqs:
  inline:
    - title: Mesh-scoped zone egress
      content: |
        A mesh-scoped zone egress for `kong-air-mesh`.
        [Install {{site.mesh_product_name}} and deploy Kong Air](/mesh/install-kong-mesh-and-deploy-kong-air/) deploys one through the Helm `meshes:` entry.
        That entry creates the zone proxy `Deployment`, and the `Service` that the control plane reads the listener address and port from.
        A zone proxy deployment without its `Service` registers as an ordinary `Dataplane` and never becomes a zone egress.
        To confirm that the zone egress runs, or to add the same `meshes:` entry to another zone control plane, see [Configure mesh-scoped zone proxies](/mesh/configure-mesh-scoped-zone-proxies/).
    - title: Workload identity
      content: |
        A `MeshIdentity` whose selector covers the zone proxies in `{{site.mesh_namespace}}` and the application workloads.
        See [Manage workload identity and mTLS](/mesh/manage-workload-identity-and-mtls/).
cleanup:
  inline:
    - title: Remove the external service definitions
      include_content: md/mesh/v3/cleanup/external-services
    - title: Remove the Kong Air foundation
      include_content: md/mesh/v3/cleanup/kong-air-foundation
next_steps:
  - text: "How-to: Validate resilience with fault injection"
    url: "/mesh/validate-resilience-with-fault-injection/"
related_resources:
  - text: MeshExternalService
    url: /mesh/meshexternalservice/
  - text: MeshRetry
    url: /mesh/policies/meshretry/
  - text: MeshTrafficPermission
    url: /mesh/policies/meshtrafficpermission/
---

## Why MeshExternalService?

Kong Air's critical dependencies need more than the allowlist from [Secure the perimeter with MeshPassthrough](/mesh/secure-the-perimeter-with-meshpassthrough/).
These dependencies are AeroPay, Kong Air's payment provider, and the managed PostgreSQL database for flight data.
A [`MeshExternalService`](/mesh/meshexternalservice/) turns each dependency into a named mesh destination:
- Consistent naming: Workloads call a mesh-generated hostname instead of a hardcoded IP address or external URL.
- Traffic control: `MeshRetry` retries failed calls to AeroPay without changes to application code.
- Security: The zone egress originates TLS, so the application doesn't manage external certificates. See [Originating TLS](/mesh/meshexternalservice/#originating-tls).

## Set the naming standard

On Kubernetes, {{site.mesh_product_name}} includes a default `HostnameGenerator`.
The `HostnameGenerator` gives each zone-local `MeshExternalService` a generated hostname and a virtual IP.
For the hostname format and the virtual IP range, see [MeshExternalService](/mesh/meshexternalservice/).

A custom naming scheme for Kong Air is an operator task.
The operator customizes the `HostnameGenerator` once, so application teams don't redefine it in each scenario.

## How the traffic leaves the mesh

`MeshExternalService` traffic always goes through the mesh-scoped zone egress in the caller's zone.
The caller's sidecar sends the request to the zone egress over mesh mTLS, and the zone egress connects to the external endpoint.
That path gives Kong Air one enforcement point for every external dependency.
A caller's sidecar gets a cluster for a `MeshExternalService` only when the caller has a workload identity.
Without a workload identity, the caller gets no cluster, and its requests fail with `503`.
For the full path, see [Traffic paths](/mesh/mesh-scoped-zone-proxies/#traffic-paths).

## Define the RDS database

Kong Air uses a managed PostgreSQL instance for flight data.
Define the instance as a `MeshExternalService` named `flight-db`, so that workloads reach it through a mesh-generated hostname instead of the hardcoded AWS endpoint.

{:.info}
> On Kubernetes, you can create a `MeshExternalService` only in the system namespace, `{{site.mesh_namespace}}`.
> The `MeshTrafficPermission` and `MeshRetry` in this guide live in the same namespace.
> See [Resource scoping](/mesh/resource-scoping/).

The following `MeshExternalService` defines `flight-db` and turns on TLS to the database endpoint:

```yaml
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
  tls:
    enabled: true
    verification:
      mode: Secured
      serverName: rds-instance-01.c7x2.us-east-1.rds.amazonaws.com
```

Applications keep a simple configuration, and the zone egress encrypts the traffic to the managed database.

## Restrict database access by workload

Defining `flight-db` doesn't give any workload access to it.
The mesh-scoped zone egress denies all `MeshExternalService` traffic by default, so every call returns `403 Forbidden` until a policy allows the caller.
Kong Air wants one caller, `flight-control`.
Create a `MeshTrafficPermission` on the zone egress that allows `flight-control` to reach `flight-db`:

```yaml
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
              value: spiffe://kong-air-mesh.zone1.mesh.local/ns/kong-air-production/sa/flight-control
            sni:
              type: Exact
              value: sni.extsvc.kong-air-mesh.zone1.{{site.mesh_namespace}}.flight-db.5432
```

Each `allow` entry pairs a caller with a destination.
The caller is the workload's Secure Production Identity Framework for Everyone (SPIFFE) ID, which mTLS proves.
The destination is the external service's Server Name Indication (SNI).
The zone egress allows a connection only when both match, and it denies every other connection.

### Derive the SNI

The SNI for a zone-local `MeshExternalService` uses the following format, where the last segment is the `match.port`:

```
sni.extsvc.<mesh>.<zone>.<namespace>.<name>.<port>
```

For `flight-db` in zone `zone1`, the SNI is:

```
sni.extsvc.kong-air-mesh.zone1.{{site.mesh_namespace}}.flight-db.5432
```

Read the zone name from the zone egress `Dataplane`:

```bash
kubectl get dataplanes.kuma.io -n {{site.mesh_namespace}} \
  -l kuma.io/listener-zoneegress=enabled \
  -o jsonpath='{.items[0].metadata.labels.kuma\.io/zone}{"\n"}'
```

Expected output:

```text
zone1
```
{:.no-copy-code}

{:.info}
> Use the fully qualified name `dataplanes.kuma.io`. If {{site.gateway_operator_product_name}} runs in the same cluster, the short name `dataplane` resolves to `dataplanes.gateway-operator.konghq.com`, and the command returns nothing.

For how to find the SNI on any zone egress, see [Authorize zone proxy traffic](/mesh/policies/meshtrafficpermission/#authorize-zone-proxy-traffic).

### Derive the SPIFFE ID

{{site.mesh_product_name}} issues SPIFFE IDs in the following format:

```
spiffe://<trust-domain>/ns/<namespace>/sa/<service-account>
```

For `flight-control`, which runs in the `kong-air-production` namespace with the `flight-control` service account in zone `zone1`, the SPIFFE ID is:

```
spiffe://kong-air-mesh.zone1.mesh.local/ns/kong-air-production/sa/flight-control
```

Read the trust domain from the status of the `kong-air-identity` `MeshIdentity`:

```bash
kubectl get meshidentity kong-air-identity -n {{site.mesh_namespace}} \
  -o jsonpath='{.status.trustDomain}{"\n"}'
```

Expected output:

```text
kong-air-mesh.zone1.mesh.local
```
{:.no-copy-code}

For the trust domain and path templates, see [SPIFFE ID](/mesh/policies/meshidentity/#spiffe-id).

{:.info}
> To give more workloads access to the same or other external services, add entries under `rules[0].default.allow`.
> To let a workload reach any external service through the zone egress, leave out the `sni` field from its entry.

## Secure AeroPay (HTTPS with TLS origination)

Kong Air's security architect wants all traffic to AeroPay encrypted, without developers managing third-party CA bundles in application code.
The `aeropay-api` `MeshExternalService` turns on TLS origination, so the zone egress opens the TLS connection to `api.aeropay.com`.
See [Originating TLS](/mesh/meshexternalservice/#originating-tls).

{:.info}
> Developers call `aeropay-api` over plain HTTP inside the mesh, so `match.port` is an HTTP port, `80`.
> The upstream endpoint stays on port `443`.
> The `HostnameGenerator` still generates the hostname.

Define `aeropay-api` with TLS origination to `api.aeropay.com`:

```yaml
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
```

## Add resiliency with MeshRetry

`aeropay-api` is now a mesh destination, so developers can apply standard mesh policies to it.
When AeroPay is slow for a moment or returns a 5xx error, the caller's sidecar can retry the call.
Configure retries with the `MeshRetry` policy, because `MeshHTTPRoute` filters don't configure retries.

Create a `MeshRetry` that retries calls from `passenger-portal` to `aeropay-api` up to three times:

```yaml
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
```

{:.info}
> A top-level `spec.targetRef` accepts only `Mesh` or `Dataplane`.
> So `MeshRetry` selects the clients whose retries it configures, and names the destination in the `to[]` list.
> The `to[]` entry selects the destination by its `kuma.io/display-name` label.
> See [Accepted values by field](/mesh/policy-targeting/#accepted-values-by-field).

{:.info}
> Pair `MeshRetry` with `MeshCircuitBreaker`, so the mesh stops sending requests to an external service that's already failing.
> Add `MeshTimeout` to limit the total time spent on retries.

## Validate

1. Confirm that the control plane accepted both `MeshExternalService` resources and gave each one a mesh-generated hostname:

   ```sh
   kubectl get meshexternalservice -n {{site.mesh_namespace}}
   ```

   Expected output, where the `HOSTNAME` column shows the stable internal name of each external dependency:

   ```text
   NAME          HOSTNAME
   aeropay-api   aeropay-api.extsvc.mesh.local
   flight-db     flight-db.extsvc.mesh.local
   ```
   {:.no-copy-code}

1. Confirm that a mesh-scoped zone egress serves `kong-air-mesh`. Every step in this guide depends on the zone egress. When this command returns nothing, the missing zone egress causes any `503` that DNS doesn't explain:

   ```sh
   kubectl get dataplanes.kuma.io -n {{site.mesh_namespace}} \
     -l kuma.io/listener-zoneegress=enabled,kuma.io/mesh=kong-air-mesh
   ```

   Expected output: one `Dataplane`, named after the zone egress pod.
   {:.no-copy-code}

1. Confirm that `flight-control`, the workload that `flight-db-access` allows, resolves the generated hostname to its mesh-assigned virtual IP:

   ```sh
   kubectl exec -n kong-air-production deploy/flight-control -- nslookup flight-db.extsvc.mesh.local
   ```

   Expected output: the hostname resolves to an address in the `MeshExternalService` virtual IP range. `flight-control` addresses `flight-db` by its generated name instead of the raw RDS endpoint.
   {:.no-copy-code}

1. Confirm that the permission controls access. Call the AeroPay hostname from `check-in-api`, which no `allow` entry names:

   ```sh
   kubectl exec -n kong-air-production deploy/check-in-api -- wget -q -T 10 -O- http://aeropay-api.extsvc.mesh.local
   ```

   Expected output: `403 Forbidden`. The connection reached the zone egress, and the zone egress denied it by default. To grant access, add an `allow` entry with the workload's SPIFFE ID and the AeroPay SNI.
   {:.no-copy-code}
