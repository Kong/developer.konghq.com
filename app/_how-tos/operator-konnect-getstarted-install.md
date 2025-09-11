---
title: Install {{site.operator_product_name}}
description: Install the {{site.operator_product_name}}with Helm and enable Konnect CRD support.
content_type: how_to
permalink: /operator/konnect/get-started/install/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: Get Started

series:
  id: operator-konnectcrds-get-started
  position: 1

tldr:
  q: How do I install {{site.operator_product_name}}with Konnect CRD support?
  a: |
    ```bash
    helm upgrade --install kgo kong/gateway-operator -n kong-system --create-namespace \
      --set image.tag={{ site.data.operator_latest.release }} \
      --set kubernetes-configuration-crds.enabled=true \
      --set env.ENABLE_CONTROLLER_KONNECT=true
    ```

products:
  - operator

works_on:
  - konnect

entities: []

prereqs:
  skip_product: true

---

## Install {{site.operator_product_name}}

The {{site.operator_product_name}} can deploy and manage Data Planes connected to a {{ site.konnect_short_name }} Control Plane. Configuration for services, routes, and plugins is managed entirely through {{site.konnect_short_name}} and propagated automatically to Data Planes.

## Add the Helm repo

Add the Helm chart repository to your local Helm client and update the repo to fetch the latest charts:

```bash
helm repo add kong https://charts.konghq.com
helm repo update kong
```
## Create the `kong` namespace

Create the `kong` namespace in your Kubernetes cluster, which is where the Getting Started guide will run:

```sh
kubectl create namespace kong
```

## Install the Operator

Use Helm to install the {{site.operator_product_name}} with {{ site.konnect_short_name }}  support enabled:

```sh
helm upgrade --install kgo kong/gateway-operator -n kong-system --create-namespace \
  --set image.tag={{ site.data.operator_latest.release }} \
  --set kubernetes-configuration-crds.enabled=true \
  --set env.ENABLE_CONTROLLER_KONNECT=true
```

### Wait for readiness

Wait for the {{site.operator_product_name}}'s controller deployment to become available before proceeding, ensuring it’s ready to manage resources:

```sh
kubectl -n kong-system wait --for=condition=Available=true --timeout=120s deployment/kgo-gateway-operator-controller-manager
```

Once the {{site.operator_product_name}} is ready, you can begin provisioning Gateway Control Planes and Data Planes using {{site.konnect_short_name}} CRDs, the output will look like:

```sh
deployment.apps/kgo-gateway-operator-controller-manager condition met
```
