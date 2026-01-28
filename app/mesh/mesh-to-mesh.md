---
title: "Mesh to Mesh Communication"
description: "Learn how to set up {{site.mesh_product_name}} to enable secure communication between services in different meshes."
content_type: reference
layout: reference
breadcrumbs: 
  - /mesh/
products:
  - mesh
tags: 
  - zones
works_on:
  - on-prem
  - konnect
related_resources:
  - text: "Observability"
    url: /mesh/observability/
  - text: "{{site.mesh_product_name}} features"
    url: /mesh/
---

## Mesh to Mesh Communication

This guide demonstrates how to set up {{site.mesh_product_name}} across two Kubernetes clusters, configure multiple meshes (mesh1 and mesh2), and enable secure communication between services in different meshes.

{:.warning}
> **Preferred Pattern: {{site.base_gateway}}**
> For production environments and long-term stability, we recommend using **{{site.base_gateway}} ({{site.base_gateway}} Operator)** for cross-mesh communication. While {{site.mesh_product_name}} provides a built-in `MeshGateway`, **{{site.base_gateway}}** offers:
> *   **Unified Strategy**: Use the same gateway for both North-South (Internet) and East-West (Cross-Mesh) traffic.
> *   **Standardization**: Fully supports Kubernetes Gateway API.
> *   **Feature Rich**: Access to the full suite of Kong plugins (OIDC, Rate Limiting, AI Proxy).

## Architecture Overview

- **Cluster 1**: Hosts `mesh1` and `mesh2`. Contains the `echo` service.
- **Cluster 2**: Hosts `mesh1` and `mesh2`. Contains a client calling the `echo` service.

- **Cross-Mesh Flow**: 
    - **Mesh 2 -> Mesh 1**: Mesh 2 uses a `MeshExternalService` to point to a `MeshGateway` in Mesh 1.
    - **Mesh 1 -> Mesh 2**: Mesh 1 uses a `MeshExternalService` to point to a `MeshGateway` in Mesh 2.

{% mermaid %}
flowchart LR
    subgraph C1["Cluster 1 (Zone 1)"]
        direction TB
        subgraph C1M1["Mesh 1"]
            MGW1{{"MeshGateway:<br/>cross-mesh-gateway"}}
            Echo1[Echo Service]
        end
        subgraph C1M2["Mesh 2"]
            MGW2{{"MeshGateway:<br/>mesh2-gateway"}}
            Echo2[Echo Service]
        end
    end

    subgraph C2["Cluster 2 (Zone 2)"]
        direction TB
        subgraph C2M1["Mesh 1"]
            Client1[Client Workload]
            MES_TO_M2[MeshExternalService:<br/>echo-mesh-2-http]
        end
        subgraph C2M2["Mesh 2"]
            Client2[Client Workload]
            MES_TO_M1[MeshExternalService:<br/>echo-mesh-1-http]
        end
    end

    %% Flow 1: Mesh 2 (Zone 2) -> Mesh 1 (Zone 1)
    Client2 -.-> MES_TO_M1
    MES_TO_M1 == "East-West Hop" ==> MGW1
    MGW1 -.-> Echo1

    %% Flow 2: Mesh 1 (Zone 2) -> Mesh 2 (Zone 1)
    Client1 -.-> MES_TO_M2
    MES_TO_M2 == "East-West Hop" ==> MGW2
    MGW2 -.-> Echo2

    %% Styling
    style C1M1 fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    style C2M1 fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    style C1M2 fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    style C2M2 fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    
    classDef default font-family:Inter,Arial,sans-serif;

{% endmermaid %}

## Prerequisites

- Two Kubernetes clusters (referred to as `c1` and `c2`).
- `kumactl` and `kubectl` installed.
- {{site.mesh_product_name}} installed on both clusters.

## Step 1: Prepare Namespaces

Create and label namespaces on both clusters to enable sidecar injection and associate them with the correct mesh.

### Cluster 1 (Mesh 1 & Mesh 2)
```sh
# Mesh 1
kubectl create ns c1m1
kubectl label ns c1m1 kuma.io/sidecar-injection=enabled kuma.io/mesh=mesh1

# Mesh 2
kubectl create ns c1m2
kubectl label ns c1m2 kuma.io/sidecar-injection=enabled kuma.io/mesh=mesh2
```

### Cluster 2 (Mesh 2 & Mesh 1)
```sh
# Mesh 2
kubectl create ns c2m2
kubectl label ns c2m2 kuma.io/sidecar-injection=enabled kuma.io/mesh=mesh2

# Mesh 1
kubectl create ns c2m1
kubectl label ns c2m1 kuma.io/sidecar-injection=enabled kuma.io/mesh=mesh1
```

## Step 2: Configure Mesh Resources

Apply mTLS and mesh-wide policies using `kumactl`.

### Enable mTLS
Apply these to the global control plane to enable mutual TLS for each mesh.  This is required for secure communication between services in different meshes.

**Mesh 1 mTLS:**
```yaml
name: mesh1
type: Mesh
meshServices:
  mode: Exclusive
skipCreatingInitialPolicies:
- '*'
mtls:
  enabledBackend: ca-1
  backends:
    - name: ca-1
      type: builtin
      dpCert:
        rotation:
          expiration: 1d
      conf:
        caCert:
          RSAbits: 2048
          expiration: 10y
```

**Mesh 2 mTLS:**
```yaml
name: mesh2
type: Mesh
meshServices:
  mode: Exclusive
networking:
  outbound:
    passthrough: false
skipCreatingInitialPolicies:
- '*'
mtls:
  enabledBackend: ca-1
  backends:
    - name: ca-1
      type: builtin
      dpCert:
        rotation:
          expiration: 1d
      conf:
        caCert:
          RSAbits: 2048
          expiration: 10y
```

> **Concepts for Beginners: The Mesh Object & mTLS**

> *   **What is a Mesh?** In {{site.mesh_product_name}}, a `Mesh` resource represents an isolated environment for your services. Think of it as a logical boundary. Services in `mesh1` cannot verify or talk to services in `mesh2` without explicit configuration.
> *   **Why `builtin` CA?** We enabled `mtls` (Mutual TLS) with a `builtin` backend. This means the mesh automatically generates its own Root Certificate Authority (CA). It uses this CA to issue short-lived certificates to every data plane proxy (sidecar).
> *   **Why is this needed?** This ensures every request between services is encrypted and identified. {{site.mesh_product_name}} handles the rotation of these certificates automatically (every day in this config), saving you from manual certificate management.


## Recommended Pattern: {{site.base_gateway}} ({{site.operator_product_name}})

Instead of using the {{site.mesh_product_name}}-specific `MeshGateway`, you can use a standard **{{site.base_gateway}} ({{site.operator_product_name}})** to bridge communication. This is our recommended pattern for production cross-mesh communication.

In this model:
1.  **Cluster 1 (Mesh 1)**: Exposes the `echo` service using a standard Kubernetes Ingress/Gateway API (managed by {{site.operator_product_name}}).
2.  **Cluster 2 (Mesh 2)**: Calls the Ingress endpoint (e.g., `https://echo.example.com`) just like any other external web service.

### Benefits
*   **Decoupled Boundaries**: Treats the other mesh as an anonymous external client, providing a clean API contract.
*   **Operational Simplicity**: Leverages the same Ingress infrastructure you already use for external traffic.
*   **Feature Parity**: Full support for Kong's 100+ plugins.

### Comparison: MeshGateway vs ZoneIngress

| Feature | `MeshGateway` | `ZoneIngress` |
| :--- | :--- | :--- |
| **Primary Scope** | **Inter-Mesh** (Cross-Mesh) | **Intra-Mesh** (Multi-Zone) |
| **Why use it?** | Bridges two separate security domains (different mTLS roots). | Connects different physical locations of the *same* mesh. |
| **Complexity** | High (Requires manual routing & external service mapping). | Low (Automatic; {{site.mesh_product_name}} handles the tunnel). |
| **North-South** | Yes (Exposes services to the internet). | No (Mesh internal only). |

**Do I need a MeshGateway for everything?**
No. If you have a single mesh `mesh1` spanning `zone1` and `zone2`, you **don't** need the `MeshGateway` pattern shown in this guide. {{site.mesh_product_name}}'s `ZoneIngress` handles that automatically. You only need this complex "matrix" setup when you have **Isolated Meshes** that need to communicate.


### Traffic Permissions
By default, `meshServices` mode `Exclusive` requires explicit permissions.
- [mesh1mtp.yaml](file:///Users/justin.davies/Documents/GitHub/MultiMeshComms/mesh1mtp.yaml): Allows all traffic within `mesh1`.
- [mesh2mtp.yaml](file:///Users/justin.davies/Documents/GitHub/MultiMeshComms/mesh2mtp.yaml): Allows all traffic within `mesh2`.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: allow-all
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: mesh1
    kuma.io/origin: zone
spec:
  targetRef:
    kind: Mesh
  from:
  - targetRef:
      kind: Mesh
    default:
      action: Allow
```

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: allow-all
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: mesh2
    kuma.io/origin: zone
spec:
  targetRef:
    kind: Mesh
  from:
  - targetRef:
      kind: Mesh
    default:
      action: Allow
```

```sh
kubectl apply -f mesh1mtp.yaml
kubectl apply -f mesh2mtp.yaml
```

> **Concepts for Beginners: Traffic Permissions**
> *   **Implicit Deny:** When mTLS is enabled, the default behavior of the mesh typically shifts to "deny-all" (referred to as `Exclusive` mode in generic terms, though configured via `meshServices` mode). This is a "Zero Trust" security model.
> *   **Why `mesh2mtp.yaml`?** Just like Mesh 1, Mesh 2 is also secure by default. Even for a client to talk to the `MeshExternalService` (which looks like a local service), it needs permission. This policy grants that permission within Mesh 2.
> *   **Granularity:** In a production environment, you would likely replace this with finer-grained permissions (e.g., "Only `frontend` can talk to `backend`").


## Step 3: Deploy Workloads

Deploy the `echo` service in Cluster 1.

```sh
kubectl apply -f https://developer.konghq.com/manifests/kic/echo-service.yaml -n c1m1
```

## Step 4: Setup Alternative Cross-Mesh Pattern (MeshGateway)

{:.info}
> This pattern uses the built-in {{site.mesh_product_name}} `MeshGateway`. Use this if you want a dedicated East-West bridge that preserves more mesh-internal context.

To allow `mesh2` to talk to `mesh1`, we set up a `MeshGateway` in `mesh1`.

### 1. Gateway Instance

A Gateway Instance is the actual proxy that will handle the traffic, this is needed for deploying the gateway.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshGatewayInstance
metadata:
  name: cross-mesh-gateway
  namespace: c1m1
  labels:
    kuma.io/mesh: mesh1   # required because you're not using the default mesh
spec:
  replicas: 1
  serviceType: LoadBalancer # use LoadBalancer if you need external access
```

### 2. Gateway Listener
Let's apply the `MeshGateway` resource to configure the listener on port 8080.
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshGateway
mesh: mesh1
metadata:
  name: cross-mesh-gateway
  namespace: kong-mesh-system
spec:
  selectors:
    - match:
        kuma.io/service: cross-mesh-gateway_c1m1_svc
  conf:
    listeners:
      - port: 8080
        protocol: HTTP
```

### 3. HTTP Routes
We configure how the gateway routes traffic to backend services.

**Route 1: Default Echo**
Routes `/echo` to the `echo` service (standard routing).
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
  name: gw-to-mesh1-echo
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: mesh1
    kuma.io/origin: zone
spec:
  targetRef:
    kind: MeshGateway
    name: cross-mesh-gateway
  to:
  - targetRef:
      kind: Mesh
    rules:
    - matches:
      - path:
          type: PathPrefix
          value: /echo
      default:
        backendRefs:
        - kind: MeshService
          labels:
            kuma.io/display-name: echo
          port: 1027
          weight: 1
```

**Route 2: Zone-Targeted Echo**
Routes `/zone2echo` specifically to an `echo` service instances in **Zone 2**.
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
  name: gw-to-mesh2-echo-zone2
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: mesh1  # This route belongs to Mesh 1's gateway
    kuma.io/origin: zone
spec:
  targetRef:
    kind: MeshGateway
    name: cross-mesh-gateway
  to:
  - targetRef:
      kind: Mesh
    rules:
    - matches:
      - path:
          type: PathPrefix
          value: /zone2echo
      default:
        backendRefs:
        - kind: MeshService
          labels:
            kuma.io/display-name: echo
            kuma.io/zone: zone2  # <--- Targeting specific zone
          port: 1027
          weight: 1
```

> **Concepts for Beginners: Routing & Zones**
> *   **`mesh1httproute`:** This is a standard route. It sends traffic to *any* available `echo` service in the mesh. Ideally, it prefers local instances (Zone 1) but can failover to Zone 2.
> *   **`mesh2httproute` (Why explicit zone?):** Sometimes you want to guarantee traffic goes to a specific physical location (e.g., for compliance, testing, or because that zone has special data). By adding `kuma.io/zone: zone2`, we force the Gateway in Zone 1 to forward traffic over the bridge to Zone 2, bypassing any local instances.

> **Concepts for Beginners: Gateways**
> *   **Why two different resources?** You'll notice we created a `MeshGatewayInstance` AND a `MeshGateway`.
>     *   **`MeshGatewayInstance` (The Body):** This asks Kubernetes to spin up the actual "physical" Pods and LoadBalancers. It's the infrastructure.
>     *   **`MeshGateway` (The Brain):** This configures the listener logic (e.g., "Listen on port 8080 for HTTP"). It doesn't deploy pods itself; it just configures the running instances.
> *   **Why separate them?** detailed control. You might want to update *how* the gateway listens (change the port) without redeploying the underlying pods, or scale the pods without changing the listener config.


## Step 5: Enable Cross-Mesh Communication (Mesh 2)

In `mesh2`, we define the `mesh1` gateway as an external service.

Let's apply the `MeshExternalService` resource to map `echo-mesh-1-http` to the `mesh1` gateway's internal DNS or LoadBalancer IP.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshExternalService
metadata:
  name: echo-mesh-1-http
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: mesh2
    kuma.io/origin: zone
spec:
  match:
    type: HostnameGenerator
    port: 8080
    protocol: http
  endpoints:
  - address: cross-mesh-gateway.c1m1.svc.cluster.local
    port: 8080
```

> **Concepts for Beginners: External Services & Hostnames**
> *   **The Problem:** Workloads in `mesh2` don't know about services in `mesh1`. They are in a separate "bubble."
> *   **The Solution (`MeshExternalService`):** This resource maps a fake local name (like a nickname) to a real external destination. It tricks `mesh2` apps into thinking the remote service is local.
> *   **`HostnameGenerator`:** This is the magic that assigns the DNS name `echo-mesh-1-http.extsvc.mesh.local`. Without this, your app would have to know the IP address of the gateway, which might change.
> *   **`endpoints`:** This is the bridge. It points specifically to the Fully Qualified Domain Name (FQDN) of the Gateway's LoadBalancer service in Cluster 1, allowing traffic to physically cross the network gap between clusters.

Now, any workload in `mesh2` can call `http://echo-mesh-1-http.extsvc.mesh.local:8080/echo` to reach the service in `mesh1`.

## Step 6: Complete the Matrix (Mesh 1 to Mesh 2)

To complete the matrix, we allow `mesh1` to talk to `mesh2` using the same pattern.

### 1. Mesh 2 Gateway (Cluster 1)
Deploy the gateway and listener for `mesh2`.

**Gateway Instance:**
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshGatewayInstance
metadata:
  name: mesh2-gateway
  namespace: c1m2
  labels:
    kuma.io/mesh: mesh2
spec:
  replicas: 1
  serviceType: LoadBalancer
```

**Gateway Listener:**
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshGateway
mesh: mesh2
metadata:
  name: mesh2-gateway
  namespace: kong-mesh-system
spec:
  selectors:
    - match:
        kuma.io/service: mesh2-gateway_c1m2_svc
  conf:
    listeners:
      - port: 8080
        protocol: HTTP
```

### 2. Mesh 2 Route
Routes traffic from the gateway to the `echo` service.

**HTTP Route:**
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
  name: gw-to-mesh2-echo
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: mesh2
    kuma.io/origin: zone
spec:
  targetRef:
    kind: MeshGateway
    name: mesh2-gateway
  to:
  - targetRef:
      kind: Mesh
    rules:
    - matches:
      - path:
          type: PathPrefix
          value: /echo
      default:
        backendRefs:
        - kind: MeshService
          labels:
            kuma.io/display-name: echo
          port: 1027
          weight: 1
```

### 3. Mesh 1 External Service
Define the entry point in `mesh1`.

**External Service:**
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshExternalService
metadata:
  name: echo-mesh-2-http
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: mesh1
    kuma.io/origin: zone
spec:
  match:
    type: HostnameGenerator
    port: 8080
    protocol: http
  endpoints:
  - address: mesh2-gateway.c1m2.svc.cluster.local
    port: 8080
```

Now, any workload in `mesh1` (including those in Zone 2) can call `http://echo-mesh-2-http.extsvc.mesh.local:8080/echo` to reach the service in `mesh2`.
