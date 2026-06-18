---
title: Install {{ site.operator_product_name }} for multi-tenancy
description: "Create tenant namespaces, install {{ site.operator_product_name }} scoped to those namespaces, and apply a KongLicense."
content_type: how_to

permalink: /operator/dataplanes/how-to/multi-tenancy/setup/
series:
  id: operator-multi-tenancy
  position: 1

breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: "How-To"

products:
  - operator

works_on:
  - on-prem

min_version:
  operator: '2.0'

related_resources:
  - text: "Multi-tenancy reference"
    url: /operator/reference/multi-tenancy/
  - text: "Limiting namespaces watched by ControlPlane"
    url: /operator/reference/control-plane-watch-namespaces/

tldr:
  q: How do I set up {{ site.operator_product_name }} for multi-tenancy?
  a: |
    Install {{ site.operator_product_name }} with `env.watch_namespace` scoped to your
    tenant namespaces, then apply a single `KongLicense` in `kong-system`.

prereqs:
  skip_product: true
  inline:
    - title: "{{site.ee_product_name}} license"
      icon_url: /assets/icons/key.svg
      content: |
        Save your {{site.ee_product_name}} license as `license.json` in your current working directory. If you don't have a license, contact your Kong representative.
---

This series deploys two independent {{ site.base_gateway }} instances — one public-facing, one private — on the same cluster using a single {{ site.operator_product_name }} installation. Each gateway is scoped to its own namespace so that its in-memory {{ site.kic_product_name_short }} only processes routes from that namespace.

The following diagram shows the end state you'll build across this series:

<!--vale off-->
{% mermaid %}
flowchart TB
  subgraph cluster["Kubernetes Cluster"]
    subgraph sys["kong-system"]
      KO["{{ site.operator_product_name }}\n(KongLicense)"]
    end

    subgraph pub["kong-gw-public"]
      ConfigPub["GatewayConfiguration\nwatchNamespaces: own"]
      GWPub["Gateway: gw-public"]
      DPPub["Data plane Pod"]
      SvcPub["echo service\nHTTPRoute /echo"]
    end

    subgraph priv["kong-gw-private"]
      ConfigPriv["GatewayConfiguration\nwatchNamespaces: own"]
      GWPriv["Gateway: gw-private"]
      DPPriv["Data plane Pod"]
      SvcPriv["echo service\nHTTPRoute /echo"]
    end

    KO -->|manages| GWPub
    KO -->|manages| GWPriv
    ConfigPub -.->|configures| GWPub
    ConfigPriv -.->|configures| GWPriv
    GWPub -->|provisions| DPPub
    GWPriv -->|provisions| DPPriv
    DPPub -->|routes traffic to| SvcPub
    DPPriv -->|routes traffic to| SvcPriv
  end
{% endmermaid %}
<!--vale on-->

## Create namespaces

Create the system namespace and the two tenant namespaces:

```bash
kubectl create namespace kong-system
kubectl create namespace kong-gw-public
kubectl create namespace kong-gw-private
```

## Install {{ site.operator_product_name }}

1. Add the Kong Helm chart repository:

   ```bash
   helm repo add kong https://charts.konghq.com
   helm repo update
   ```

1. Install {{ site.operator_product_name }} scoped to the two tenant namespaces. The `watch_namespace` value prevents the operator from reconciling resources in any other namespace.

   ```bash
   helm upgrade --install kong-operator kong/kong-operator \
     -n kong-system \
     --create-namespace \
     --set image.tag={{ site.data.operator_latest.release }} \
     --values - <<EOF
   env:
     watch_namespace: kong-gw-public,kong-gw-private
   EOF
   ```

1. Wait for {{ site.operator_product_name }} to be ready:

{% capture validate %}
{% include prereqs/products/operator-validate-deployment.md %}
{% endcapture %}

{{validate | indent}}

## Apply a KongLicense

Apply the license once in `kong-system`. It's shared by all gateways managed by this operator installation.

1. Apply the `KongLicense`:

   ```bash
   echo "
   apiVersion: configuration.konghq.com/v1alpha1
   kind: KongLicense
   metadata:
     name: kong-license
   rawLicenseString: '$(cat ./license.json)'
   " | kubectl -n kong-system apply -f -
   ```

1. Wait for {{ site.operator_product_name }} to pick up the license:

   ```bash
   kubectl wait --for=condition=Programmed=True konglicense/kong-license --timeout=60s
   ```
