---
title: Architecture Overview
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
description: A detailed overview of the {{site.mesh_product_name}} architecture, explaining the relationship between Global/Zone control planes and the Envoy-based data plane.
products:
  - mesh
next_steps:
  - text: "Resource Scoping: Where to Apply Policies"
    url: "/mesh/scenarios/resource-scoping/"
---
{{site.mesh_product_name}} separates the **Control Plane** (the brain) from the **Data Plane** (the muscle) and introduces a multi-zone model for distributed environments. For an organization like **Kong Air**, this architecture enables a unified management layer that spans from legacy booking systems to modern cloud-native APIs.

## Core architecture pillars

{% table %}
columns:
  - title: Pillar
    key: pillar
  - title: Role
    key: role
  - title: Key components
    key: components
rows:
  - pillar: Control Plane
    role: "Manages mesh state and policy distribution."
    components: |
      * **Global CP**: Central authority for policies and resource registry.
      * **Zone CP**: Discovers local services and distributes xDS config to Envoy.
  - pillar: Data Plane
    role: "Enforces policies and intercepts traffic."
    components: |
      * **Envoy Proxy**: Sidecar proxy running alongside application instances. Enforces mTLS, retries, and rate limits.
  - pillar: Networking
    role: "Enables secure cross-zone communication."
    components: |
      * **ZoneIngress**: Entry point for cross-zone traffic.
      * **ZoneEgress**: Exit point for outgoing mesh traffic.
  - pillar: Service Model
    role: "Standardized service discovery."
    components: |
      * **MeshService**: Defines services within a single zone.
      * **MeshMultiZoneService**: Aggregates services across zones for failover.
      * **MeshExternalService**: Manages traffic to services outside the mesh.
{% endtable %}

## Why this architecture is simpler

Traditional service meshes often require you to manage multiple disparate resources and API versions just to achieve basic connectivity. {{site.mesh_product_name}} simplifies this by introducing a **Unified Control Plane** model:

{% table %}
columns:
  - title: Feature
    key: feature
  - title: Other meshes
    key: traditional
  - title: {{site.mesh_product_name}}
    key: mesh
rows:
  - feature: Management
    traditional: "Disparate controllers for ingress, egress, and policy."
    mesh: "Single, unified binary for all mesh operations."
  - feature: Infrastructure
    traditional: "Heavy Kubernetes focus; VMs are often second-class citizens."
    mesh: "First-class support for K8s, VMs, and Bare Metal with the same API."
  - feature: Configuration
    traditional: "Fragmented resources (VirtualService, DestinationRule, Gateway)."
    mesh: "Streamlined `targetRef` policies that consolidate intent."
{% endtable %}

---

## Kong Mesh Architecture

{% mermaid %}
flowchart TD
    subgraph Global["Central Management"]
        GCP[Global Control Plane]
        GUI[Konnect / `kumactl`]
    end

    subgraph Zone1["Zone: Kubernetes (Cloud)"]
        Z1CP[Zone Control Plane]
        KGO[Kong Gateway Operator]
        KG[Kong Gateway / Gateway API]
        
        subgraph SvcA["Check-in Service (K8s)"]
            P1[Envoy Proxy]
            App1[Check-in App]
        end
    end

    subgraph Zone2["Zone: Legacy Data Center (VM)"]
        Z2CP[Zone Control Plane]
        Z2Ingress[ZoneIngress]
        
        subgraph SvcB["Flight Control (VM)"]
            P2[Envoy Proxy]
            App2[Booking API]
        end
    end

    %% Control Plane Communication
    GUI --- GCP
    GCP ==>|Sync Policies| Z1CP
    GCP ==>|Sync Policies| Z2CP

    %% Data Plane Communication
    KGO --> KG
    Z1CP -.->|xDS| P1
    Z2CP -.->|xDS| P2

    %% Traffic Flow
    KG --> App1
    App1 --> P1
    P1 == Tunnel ==> Z2Ingress
    Z2Ingress --> P2
    P2 --> App2
{% endmermaid %}

## Scalability and Fault Tolerance
{{site.mesh_product_name}}'s separation of Global and Zone control planes ensures that your mesh can scale across thousands of services and multiple geographical regions without creating a single point of failure. Even if a zone becomes isolated from the global CP, it remains fully operational for existing and new workloads within that zone.
