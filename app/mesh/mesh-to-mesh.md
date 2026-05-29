---
title: "Cross-mesh communication"
description: "How {{site.mesh_product_name}} enables secure communication between services in different meshes using MeshGateway or {{site.base_gateway}}."
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
  - text: "Enable cross-mesh communication"
    url: /how-to/enable-cross-mesh-communication/
  - text: "Built-in gateways"
    url: /mesh/built-in-gateway/
  - text: "Observability"
    url: /mesh/observability/
---

In {{site.mesh_product_name}}, each `Mesh` resource is an isolated security domain with its own mTLS root of trust. Services in `mesh1` can't verify or communicate with services in `mesh2` without explicit configuration. Cross-mesh communication bridges these isolated security domains.

## How cross-mesh communication works

The core pattern is the same regardless of which gateway you use:

1. A gateway in the target mesh exposes a service as a listener.
2. The calling mesh maps that gateway to a local `MeshExternalService`, making it reachable by a generated DNS name.
3. Workloads in the calling mesh send requests to the local DNS name; the sidecar proxy forwards them to the gateway.

## Architecture example

The following diagram shows two meshes (`mesh1` and `mesh2`) each spanning two clusters. Each mesh exposes a `MeshGateway` that the other mesh treats as an external service.

- **Cluster 1**: hosts `mesh1` and `mesh2`, and contains the `echo` service.
- **Cluster 2**: hosts `mesh1` and `mesh2`, and contains a client calling the `echo` service.

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

## Gateway options

You can use one of two approaches to expose services for cross-mesh traffic.

### {{site.base_gateway}} (recommended)

We recommend using **{{site.base_gateway}} ({{site.operator_product_name}})** for production cross-mesh communication because it provides a unified gateway for both North-South (internet) and East-West (cross-mesh) traffic. With this pattern:

- **Cluster 1 (mesh1)**: exposes the `echo` service via a standard Kubernetes Gateway API managed by {{site.operator_product_name}}.
- **Cluster 2 (mesh2)**: calls the endpoint (for example, `https://echo.example.com`) as it would any external service.

Benefits of this approach:
- Treats the other mesh as an anonymous external client, providing a clean API contract.
- Uses the same Ingress infrastructure as external traffic.
- Gives access to Kong's full plugin library (OIDC, Rate Limiting, AI Proxy, and others).

### Built-in MeshGateway

The built-in `MeshGateway` is the native {{site.mesh_product_name}} option. It requires no additional components beyond {{site.mesh_product_name}} itself and preserves mesh-level context across the boundary. Use this when:

- You haven't deployed {{site.base_gateway}} ({{site.operator_product_name}}) and don't need Kong plugins on the cross-mesh path.
- You want to keep the setup entirely within {{site.mesh_product_name}}.
- You need mesh-level metadata (for example, service identity tags) to be visible at the gateway.

See [Enable cross-mesh communication](/how-to/enable-cross-mesh-communication/) for step-by-step instructions.

## MeshGateway vs ZoneIngress

These two resources are often confused because both involve gateways, but they serve different purposes:

{% table %}
columns:
  - title: Feature
    key: feature
  - title: "`MeshGateway`"
    key: meshgateway
  - title: "`ZoneIngress`"
    key: zoneingress
rows:
  - feature: Primary scope
    meshgateway: Inter-mesh (cross-mesh)
    zoneingress: Intra-mesh (multi-zone)
  - feature: When to use
    meshgateway: Bridges two separate security domains with different mTLS roots.
    zoneingress: Connects different physical locations of the *same* mesh.
  - feature: Configuration
    meshgateway: Requires manual routing and external service mapping.
    zoneingress: Automatic — {{site.mesh_product_name}} handles the tunnel.
  - feature: North-South traffic
    meshgateway: "Yes"
    zoneingress: "No (mesh-internal only)"
{% endtable %}

If you have a single mesh (`mesh1`) spanning `zone1` and `zone2`, you don't need `MeshGateway`. {{site.mesh_product_name}}'s `ZoneIngress` handles multi-zone routing automatically. The `MeshGateway` pattern is only needed when you have isolated meshes that must communicate across a security boundary.

## mTLS and traffic permissions

Each mesh has its own mTLS root of trust. When you enable `mtls` with a `builtin` backend, the mesh generates its own Certificate Authority and issues short-lived certificates to every sidecar. This ensures all inter-service traffic is encrypted and authenticated, with automatic certificate rotation.

When `meshServices` mode is set to `Exclusive`, the mesh uses a zero-trust model: all traffic is denied by default. You must apply explicit `MeshTrafficPermission` policies to allow communication within or across meshes.
