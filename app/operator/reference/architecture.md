---
title: "{{site.operator_product_name}} architecture"
description: Learn about the {{site.operator_product_name}} architecture with a self-hosted control plane or with {{site.konnect_short_name}}, with a single or multiple tenants.
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

related_resources:
  - text: "Managed Gateways"
    url: /operator/dataplanes/managed-gateways/
  - text: "Gateway API"
    url: /operator/dataplanes/gateway-api/
  - text: "Gateway configuration"
    url: /operator/dataplanes/gateway-configuration/
  - text: "Limiting namespaces watched by ControlPlane"
    url: /operator/reference/control-plane-watch-namespaces/
  - text: "Konnect reconciliation loop"
    url: /operator/konnect/reconciliation-loop/
  - text: "KonnectExtension"
    url: /operator/dataplanes/konnectextension/
---

{{site.operator_product_name}} is a [Kubernetes Operator](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/) that manages the lifecycle of {{site.base_gateway}} deployments on Kubernetes. It supports two primary deployment models: a self-hosted control plane and a {{site.konnect_short_name}}-hosted control plane.

## Self-hosted control plane

In self-hosted mode, {{site.operator_product_name}} manages both the control plane and the data plane within your Kubernetes cluster.

<!--vale off-->
{% mermaid %}
flowchart LR
    subgraph K8s[Kubernetes Cluster]
        K[Kubernetes API Server]

        subgraph kongNS[kong-system]
            KO["{{site.operator_product_name}} Pod<br/>(Controller Manager<br/>+ in-memory {{site.kic_product_name_short}} per Gateway)"]
        end

        subgraph AppNS[Application Namespace]
            GWConfig[GatewayConfiguration]
            GWClass[GatewayClass]
            GW[Gateway]
            Routes["HTTPRoute / GRPCRoute<br/>TCPRoute / UDPRoute"]
            DP["Data plane<br/>({{site.base_gateway}}, DB-less)"]
            S[Upstream services]
        end

        GWConfig -.->|parametersRef| GWClass
        GWClass -.->|gatewayClassName| GW
        K <-->|Watch CRD events| KO
        KO -->|Deploys| DP
        KO -->|mTLS config sync| DP
        DP -->|Proxy traffic| S
    end

    Client([Client]) --> DP
{% endmermaid %}
<!--vale on-->

{{site.operator_product_name}} watches for `GatewayClass` resources with `spec.controllerName: konghq.com/gateway-operator`. For each `Gateway` associated with such a `GatewayClass`, {{site.operator_product_name}}:

1. Starts an in-memory {{site.kic_product_name}} instance to act as the control plane for that `Gateway`. This isn't a separately deployed Pod, it runs embedded inside the {{site.operator_product_name}} process.
2. Deploys a data plane: a {{site.base_gateway}} instance running in DB-less mode.
3. Continuously pushes routing configuration from the in-memory {{site.kic_product_name_short}} to the data plane over mTLS via the Admin API.

Routing rules are defined using Gateway API resources (`HTTPRoute`, `GRPCRoute`, `TCPRoute`, `UDPRoute`). The embedded {{site.kic_product_name_short}} instance translates these into Kong configuration and syncs them to the data plane.

Use a `GatewayConfiguration` resource, referenced via `GatewayClass.spec.parametersRef`, to customize the data plane container image, environment variables, and other deployment settings.

To deploy multiple isolated gateways (for example, a public-facing and a private internal gateway), create a `GatewayConfiguration`, `GatewayClass`, and `Gateway` for each. Each `Gateway` results in one embedded {{site.kic_product_name_short}} instance (within the same {{site.operator_product_name}} Pod) and one separate data plane deployment.

## {{site.konnect_short_name}}-hosted control plane

In {{site.konnect_short_name}} mode, the control plane runs in {{site.konnect_short_name}} rather than in your cluster. 

<!--vale off-->
{% mermaid %}
flowchart LR
    subgraph Konnect["{{site.konnect_product_name}}"]
        KCP[Control plane]
        KAPI[Konnect API]
    end

    subgraph K8s[Kubernetes Cluster]
        K[Kubernetes API Server]

        subgraph kongNS[kong-system]
            KO["{{site.operator_product_name}}<br/>(Controller Manager)"]
        end

        subgraph AppNS[Application Namespace]
            KonnectCRs["KonnectAPIAuthConfiguration<br/>KonnectGatewayControlPlane<br/>Kong entity CRDs"]
            DP["Data plane + KonnectExtension<br/>({{site.base_gateway}}, DB-less)"]
            S[Upstream services]
        end

        K <-->|Watch CRD events| KO
        KonnectCRs -->|Reconciled by| KO
        KO -->|Deploys| DP
        DP -->|Proxy traffic| S
    end

    KO -->|"HTTPS — sync resources"| KAPI
    KCP -->|WSS config sync| DP
    Client([Client]) --> DP
{% endmermaid %}
<!--vale on-->

{{site.operator_product_name}} reconciles Kubernetes CRDs, such as `KonnectAPIAuthConfiguration`, `KonnectGatewayControlPlane`, and Kong entity CRDs, against the {{site.konnect_short_name}} API over HTTPS.

For data plane connectivity, {{site.operator_product_name}} deploys data plane Pods annotated with a `KonnectExtension`. These Pods connect to the {{site.konnect_short_name}}-hosted control plane over a secure WebSocket (WSS) connection to receive their configuration. There is no in-memory {{site.kic_product_name_short}} in this model, {{site.konnect_short_name}} acts as the control plane.