---
title: Install {{site.operator_product_name}} for {{ site.event_gateway }}
description: Install {{site.operator_product_name}} and prepare a Kubernetes cluster for {{ site.event_gateway }}, with either a {{site.konnect_short_name}} or an on-prem control plane.
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
  - on-prem

prereqs:
  show_works_on: true
  skip_product: true
  operator:
    on_prem_controllers: [GWADMIN, ONPREMEVENTGATEWAY]
    skip_license: true
  inline:
    - title: "On-prem: Kubernetes cluster and {{ site.event_gateway_short }} license"
      topology: on-prem
      include_content: /md/operator/event-gateway/prereqs/on-prem-cluster
      icon_url: /assets/icons/kubernetes.svg

tldr:
  q: How do I prepare a cluster for {{ site.event_gateway }} with {{site.operator_product_name}}?
  a: |
    Create the `kong` and `kafka` namespaces, install {{site.operator_product_name}}, then deploy a Kafka cluster for the {{ site.event_gateway_short }} examples.
    For on-prem (Tech Preview), also enable the `GWAdmin` and `OnPremEventGateway` controllers, store your {{ site.event_gateway_short }} license in a Secret, and create a `GWAdmin`.

tags:
  - install
  - helm
  - kafka

related_resources:
  - text: "{{ site.event_gateway }} architecture"
    url: /event-gateway/architecture/
  - text: "{{ site.event_gateway }} with {{ site.operator_product_name }}"
    url: /operator/event-gateway/
  - text: Known limitations
    url: /event-gateway/known-limitations/
---

This guide walks through a complete {{ site.event_gateway }} setup using {{site.operator_product_name}}.

By the end of the series, you will have:

{% konnect %}
content: |
  - a {{site.konnect_short_name}} {{ site.event_gateway_short }} control plane
{% endkonnect %}
{% on_prem %}
content: |
  - an on-prem {{ site.event_gateway_short }} control plane, run in your cluster by {{site.operator_product_name}}
{% endon_prem %}

- an {{ site.event_gateway_short }} data plane in Kubernetes
- a backend Kafka cluster
- a virtual cluster, listener, and listener policies
- consumer and producer policies
- two ways to expose services:
  - `LoadBalancer` and `portMapping`
  - `Gateway`, `TLSRoute`, and SNI

{% on_prem %}
content: |
  {% include operator/event-gateway-on-prem-tech-preview.md %}
{% endon_prem %}

## Create the Kubernetes namespaces

Create the namespaces used throughout this example:

```bash
kubectl create namespace kong
kubectl create namespace kafka
```

## Install {{site.operator_product_name}}

Install {{site.operator_product_name}} with Helm:

{% include prereqs/products/operator.md raw=true v_maj=2 keg_install=true %}

{% on_prem %}
title: Create the `GWAdmin`
step: true
content: |
  With an on-prem control plane, {{ site.event_gateway }} data planes pull their configuration from gw-admin, a control plane that runs in your cluster. The `GWAdmin` resource deploys gw-admin. {{site.operator_product_name}} pushes your {{ site.event_gateway_short }} configuration to gw-admin, and provisions the certificates that gw-admin and the data planes use to authenticate each other.

  1. Store your {{ site.event_gateway_short }} license in a Secret. {{site.operator_product_name}} only reads Secrets that carry the `konghq.com/secret=true` label:

     ```bash
     kubectl create secret generic gw-admin-license -n kong \
       --from-file=license=./event-gateway-license.jws
     kubectl label secret gw-admin-license -n kong konghq.com/secret=true
     ```
     {: data-test-step="block" }

  1. Create the `GWAdmin` resource:

     ```bash
     echo '
     apiVersion: gateway-operator.konghq.com/v1alpha1
     kind: GWAdmin
     metadata:
       name: gw-admin
       namespace: kong
     spec:
       license:
         secretRef:
           name: gw-admin-license
           key: license
     ' | kubectl apply -f -
     ```
     {: data-test-step="block" }

  1. Wait for the `GWAdmin` and its Pod to be ready:

     ```bash
     kubectl wait gwadmin/gw-admin -n kong \
       --for=condition=Ready=True \
       --timeout=5m

     kubectl wait deployment/gw-admin -n kong \
       --for=condition=Available=True \
       --timeout=5m
     ```
     {: data-test-step="block" }

     The `GWAdmin` reports `LicenseProvisioned=True` once the license Secret is mounted. gw-admin validates the license itself, and doesn't start without a valid one. If the Deployment doesn't become available, check the gw-admin logs:

     ```bash
     kubectl logs -n kong deployment/gw-admin
     ```
{% endon_prem %}

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
