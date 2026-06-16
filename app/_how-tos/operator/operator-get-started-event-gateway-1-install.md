---
title: Install {{site.operator_product_name}} for {{ site.event_gateway }}
description: Install {{site.operator_product_name}} and prepare a Kubernetes cluster for {{ site.event_gateway }}.
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
  
min_version:
  operator: '2.2'

works_on:
  - konnect

prereqs:
  skip_product: true

tldr:
  q: How do I prepare a cluster for {{ site.event_gateway }} with {{site.operator_product_name}}?
  a: Create the `kong` and `kafka` namespaces, install {{site.operator_product_name}}, then deploy a Kafka cluster for the {{ site.event_gateway_short }} examples.

tags:
  - install
  - helm
  - kafka

related_resources:
  - text: "{{ site.event_gateway }} architecture"
    url: /event-gateway/architecture/
  - text: "{{ site.event_gateway }} with {{ site.operator_product_name }}"
    url: /operator/konnect/event-gateway/
  - text: Known limitations
    url: /event-gateway/known-limitations/
---

This guide walks through a complete {{ site.event_gateway }} setup using {{site.operator_product_name}} and {{site.konnect_short_name}}.

By the end of the series, you will have:

- a {{site.konnect_short_name}} {{ site.event_gateway_short }} control plane
- an {{ site.event_gateway_short }} data plane in Kubernetes
- a backend Kafka cluster
- a virtual cluster, listener, and listener policies
- consumer and producer policies
- two ways to expose services:
  - `LoadBalancer` and `portMapping`
  - `Gateway`, `TLSRoute`, and SNI

## Create the Kubernetes namespaces

Create the namespaces used throughout this example:

```bash
kubectl create namespace kong
kubectl create namespace kafka
```

## Install {{site.operator_product_name}}

Install {{site.operator_product_name}} with Helm:

{% include prereqs/products/operator.md raw=true v_maj=2 keg_install=true %}

## Install a Kafka cluster

The {{ site.event_gateway_short }} examples in this guide use a three-broker Kafka cluster deployed with the Bitnami chart.

1. Add the Bitnami Helm repository:

   ```bash
   helm repo add bitnami https://charts.bitnami.com/bitnami
   helm repo update
   ```

1. Write the Kafka configuration file:

   ```bash
   cat <<'EOF' >/tmp/kafka-values.yaml
   image:
     registry: docker.io
     repository: bitnamilegacy/kafka
     tag: 4.0.0-debian-12-r6

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

1. Install Kafka:

   ```bash
   helm install kafka-cluster bitnami/kafka \
     -n kafka \
     --version 32.4.3 \
     -f /tmp/kafka-values.yaml
   ```

1. Wait for all Kafka brokers to be ready before continuing:

   ```bash
   kubectl wait pod -n kafka \
     --for=condition=Ready \
     --selector app.kubernetes.io/name=kafka \
     --timeout=5m
   ```
