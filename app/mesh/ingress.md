---
title: 'Ingress traffic with {{site.mesh_product_name}}'
description: 'Overview of how ingress (north/south) traffic flows through delegated and built-in gateways in {{site.mesh_product_name}}, with visuals and key differences.'
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

min_version:
  mesh: '2.6'

related_resources:
  - text: Built-in gateways
    url: '/mesh/built-in-gateway/'
  - text: Delegated gateways
    url: '/mesh/delegated-gateways/'
  - text: Data plane proxy
    url: '/mesh/data-plane-proxy/'
  - text: Multi-zone deployment
    url: '/mesh/mesh-multizone-service-deployment/'

---

{{site.mesh_product_name}} provides two features to manage ingress traffic, also known as north/south traffic.
Both use a gateway proxy that sits between external clients and your services in the mesh.

* [Delegated gateway](/mesh/delegated-gateways/): Uses any existing gateway proxy, like [{{site.base_gateway}}](/gateway/).
* [Built-in gateway](/mesh/built-in-gateway/): Runs Envoy instances as a gateway proxy.

{:.warning}
> Gateways exist within a mesh.
> If you have multiple meshes, each mesh requires its own gateway. You can connect your meshes together using [cross-mesh gateways](/mesh/meshgateway/#cross-mesh).

The following diagrams show the difference between built-in and delegated gateway deployments. Solid lines represent traffic not managed by {{site.mesh_product_name}}; dashed lines represent mesh-managed traffic between data plane proxies.

## Built-in gateway

{{site.base_gateway}} at the edge routes to built-in gateways running as Envoy proxies inside each service mesh.

{% mermaid %}
flowchart TB
    CLIENT([Client])
    KGW[{{site.base_gateway}}]
    CLIENT --> KGW

    subgraph M1[Team 1 service mesh]
        BG1[Built-in gateway]
        subgraph sg1a[ ]
            direction LR
            S1[Service] --- D1[KUMA-DP]
            D1 <-.-> D2[KUMA-DP]
            D2 --- S2[Service]
        end
        subgraph sg1b[ ]
            direction LR
            S3[Service] --- D3[KUMA-DP]
            D3 <-.-> D4[KUMA-DP]
            D4 --- S4[Service]
        end
        BG1 -.-> D1 & D3
    end

    subgraph M2[Team 2 service mesh]
        BG2[Built-in gateway]
        subgraph sg2a[ ]
            direction LR
            S5[Service] --- D5[KUMA-DP]
            D5 <-.-> D6[KUMA-DP]
            D6 --- S6[Service]
        end
        subgraph sg2b[ ]
            direction LR
            S7[Service] --- D7[KUMA-DP]
            D7 <-.-> D8[KUMA-DP]
            D8 --- S8[Service]
        end
        BG2 -.-> D5 & D7
    end

    KGW --> BG1 & BG2

    classDef kongBlue fill:#1456cb,color:#fff,stroke:#1456cb
    classDef builtinPurple fill:#9c7fc1,color:#fff,stroke:#7c5fa1
    class KGW kongBlue
    class BG1,BG2 builtinPurple
    linkStyle 0,17,18 stroke:#1456cb,stroke-width:2px
    linkStyle 2,5,7,8,10,13,15,16 stroke:#e44b8a
{% endmermaid %}

## Delegated gateway

{{site.base_gateway}} routes directly to delegated gateways that operate as data plane proxies inside each service mesh.

{% mermaid %}
flowchart TB
    CLIENT([Client])
    KGW[{{site.base_gateway}}]
    CLIENT --> KGW

    subgraph M1[Team 1 service mesh]
        DG1[Delegated gateway]
        subgraph sg1a[ ]
            direction LR
            S1[Service] --- D1[KUMA-DP]
            D1 <-.-> D2[KUMA-DP]
            D2 --- S2[Service]
        end
        subgraph sg1b[ ]
            direction LR
            S3[Service] --- D3[KUMA-DP]
            D3 <-.-> D4[KUMA-DP]
            D4 --- S4[Service]
        end
        DG1 -.-> D1 & D3
    end

    subgraph M2[Team 2 service mesh]
        DG2[Delegated gateway]
        subgraph sg2a[ ]
            direction LR
            S5[Service] --- D5[KUMA-DP]
            D5 <-.-> D6[KUMA-DP]
            D6 --- S6[Service]
        end
        subgraph sg2b[ ]
            direction LR
            S7[Service] --- D7[KUMA-DP]
            D7 <-.-> D8[KUMA-DP]
            D8 --- S8[Service]
        end
        DG2 -.-> D5 & D7
    end

    KGW --> DG1 & DG2

    classDef kongBlue fill:#1456cb,color:#fff,stroke:#1456cb
    class KGW,DG1,DG2 kongBlue
    linkStyle 0,17,18 stroke:#1456cb,stroke-width:2px
    linkStyle 2,5,7,8,10,13,15,16 stroke:#e44b8a
{% endmermaid %}
