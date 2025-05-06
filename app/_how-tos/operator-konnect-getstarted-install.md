---
title: Install Kong Gateway Operator
description: Install the Kong Gateway Operator with Helm and enable Konnect CRD support.
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
  id: kgo-get-started
  position: 1

tldr:
  q: How do I install Kong Gateway Operator with Konnect CRD support?
  a: |
    ```bash
    helm upgrade --install kgo kong/gateway-operator -n kong-system --create-namespace \
      --set image.tag=1.5 \
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

## Install Kong Gateway Operator

The Kong Gateway Operator can deploy and manage Data Planes connected to a {{ site.konnect_short_name }} Control Plane. Configuration for services, routes, and plugins is managed entirely through {{site.konnect_short_name}} and propagated automatically to Data Planes.

## Add the Helm repo

```bash
helm repo add kong https://charts.konghq.com
helm repo update kong
```
## Create the `kong` namespace

```sh
kubectl create namespace kong
```

## Install the Operator

Use Helm to install the Kong Gateway Operator with {{ site.konnect_short_name }}  support enabled:

```sh
helm upgrade --install kgo kong/gateway-operator -n kong-system --create-namespace \
  --set image.tag=1.5 \
  --set kubernetes-configuration-crds.enabled=true \
  --set env.ENABLE_CONTROLLER_KONNECT=true
```

### Wait for readiness

Once installed, wait for the Operator to become available:

```sh
kubectl -n kong-system wait --for=condition=Available=true --timeout=120s deployment/kgo-gateway-operator-controller-manager
```

Once the Operator is ready, you can begin provisioning Gateway Control Planes and Data Planes using {{site.konnect_short_name}} CRDs, the output will look like: 

```sh
deployment.apps/kgo-gateway-operator-controller-manager condition met
```
