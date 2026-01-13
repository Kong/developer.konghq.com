---
title: "{{site.operator_product_name}} architecture"
description: Learn about the {{site.operator_product_name}} architecture with a self-hosted control plane or with {{site.konnect_short_name}}.
content_type: reference
layout: reference

breadcrumbs:
  - /operator/
  - index: operator
    group: Reference

products:
  - operator

works_on:
  - on-prem
  - konnect
---




{% mermaid %}
flowchart LR
    subgraph K8s[Kubernetes Cluster]
        K[Kubernetes API Server]

        K <-->|Watches CRDs events| KO

        subgraph NS1[Namespace A]
            KO["{{site.operator_product_name}}<br/>(Controller Manager)"]
            CP["Control plane<br/>(In-memory KIC)"]
        end

        subgraph NS2[Namespace B]
            DP1[Data plane]
        end
        subgraph NS3[Namespace C]
            DP2[Data plane]
        end

        S[Upstream services]

        KO -->|Reconciles| CP
        KO -->|Deploys| DP1 & DP2

        CP --->|mTLS config sync| DP1 & DP2

        DP1 -->|Proxy traffic| S
        DP2 -->|Proxy traffic| S
    end

    C[Client]
    C ---->|HTTP/HTTPS| DP1 & DP2
{% endmermaid %}

{% mermaid %}
flowchart LR
    subgraph KOKO[{{site.konnect_product_name}}]
        CP[Control plane]
    end
    subgraph K8s[Kubernetes Cluster]
        K[Kubernetes API Server]

        K <-->|Watches CRDs events| KO

        subgraph NS1[Namespace A]
            KO["{{site.operator_product_name}}<br/>(Controller Manager)"]
        end

        subgraph NS2[Namespace B]
            DP1[Data plane]
        end
        subgraph NS3[Namespace C]
            DP2[Data plane]
        end

        S[Upstream services]

        KO -->|Reconciles| CP
        KO -->|Deploys| DP1 & DP2

        

        DP1 -->|Proxy traffic| S
        DP2 -->|Proxy traffic| S
    end



    CP --->|WSS config sync| DP1 & DP2
    
    C[Client]
    C ---->|HTTP/HTTPS| DP1 & DP2
{% endmermaid %}