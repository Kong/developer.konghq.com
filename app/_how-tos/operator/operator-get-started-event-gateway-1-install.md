---
title: Install {{site.operator_product_name}} for Kong Event Gateway
description: Install {{site.operator_product_name}} and prepare a Kubernetes cluster for Kong Event Gateway.
content_type: how_to
permalink: /operator/get-started/event-gateway/install/

series:
  id: operator-get-started-event-gateway
  position: 1

breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: Get Started

products:
  - operator

works_on:
  - konnect

prereqs:
  skip_product: true

tldr:
  q: How do I prepare a cluster for Kong Event Gateway with {{site.operator_product_name}}?
  a: Create the `kong` and `kafka` namespaces, install {{site.operator_product_name}}, then deploy a Kafka cluster for the Event Gateway examples.

tags:
  - install
  - helm
  - kafka
---

This guide walks through a complete Kong Event Gateway setup using {{site.operator_product_name}} and {{site.konnect_short_name}}.

By the end of the series, you will have:

- a `KonnectEventGateway`
- an Event Gateway data plane in Kubernetes
- a backend Kafka cluster
- a virtual cluster, listener, and listener policies
- consume and produce policies
- two exposure patterns:
  - `LoadBalancer` plus `portMapping`
  - `Gateway` plus `TLSRoute` plus SNI

## Create the Kubernetes namespaces

Create the namespaces used throughout this guide:

```bash
kubectl create namespace kong
kubectl create namespace kafka
```

If the namespaces already exist, Kubernetes will return an `AlreadyExists` message, which is safe to ignore.

## Install {{site.operator_product_name}}

Install {{site.operator_product_name}} with Helm:

{% include prereqs/products/operator.md raw=true v_maj=2 %}

## Wait for the operator to be ready

Wait for the controller deployment to become available:

{% include prereqs/products/operator-validate-deployment.md %}

## Install a Kafka cluster

The Event Gateway examples in this guide use a three-broker Kafka cluster deployed with the Bitnami chart.

Add the Bitnami Helm repository:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

Install Kafka:

```bash
cat <<'EOF' >/tmp/kafka-values.yaml
listeners:
  client:
    protocol: PLAINTEXT
externalAccess:
  enabled: false
kraft:
  enabled: true
controller:
  replicaCount: 3
broker:
  replicaCount: 0
EOF
```

```bash
helm install kafka-cluster bitnami/kafka \
  -n kafka \
  --version 32.4.3 \
  -f /tmp/kafka-values.yaml
```

Wait for Kafka to be ready:

```bash
kubectl wait --for=condition=Ready pod \
  -l app.kubernetes.io/name=kafka \
  -n kafka \
  --timeout=10m
```

## Validation

Verify that the operator and Kafka are ready:

```bash
kubectl get pods -n kong
kubectl get pods -n kafka
```

Once both the operator and Kafka are ready, continue to [Create API Authentication](/operator/get-started/event-gateway/authentication/).
