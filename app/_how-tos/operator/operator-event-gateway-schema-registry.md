---
title: Validate Kafka message schemas with EventGatewaySchemaRegistry
description: "Learn how to connect {{ site.event_gateway }} to a schema registry and enforce schema validation on produced and consumed records."
content_type: how_to

permalink: /operator/dataplanes/how-to/event-gateway-schema-registry/
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
  - konnect

min_version:
  operator: '2.3'

tldr:
  q: How do I validate Kafka message schemas with {{ site.operator_product_name }}?
  a: Create an `EventGatewaySchemaRegistry` resource pointing at your schema registry, then reference it from an `EventGatewayVirtualClusterConsumePolicy` or `EventGatewayVirtualClusterProducePolicy` with a `schemaValidation` config.

prereqs:
  operator:
    konnect:
      auth: true
      control_plane: true

related_resources:
  - text: Deploy {{ site.event_gateway }} with port mapping
    url: /operator/get-started/event-gateway/port-mapping/
  - text: "{{ site.event_gateway }} with {{ site.operator_product_name }}"
    url: /operator/konnect/event-gateway/
  - text: Policies
    url: /event-gateway/entities/policy/
---

`EventGatewaySchemaRegistry` connects {{ site.event_gateway }} to a schema registry so consume and produce policies can validate Kafka record schemas before they reach clients or your backend cluster.

This guide assumes you already have a `KonnectEventGateway` and an `EventGatewayVirtualCluster` running, such as the ones created in [Deploy {{ site.event_gateway }} with port mapping](/operator/get-started/event-gateway/port-mapping/). The examples below reuse the `cp-event-1` control plane and `example-virtual-cluster` virtual cluster from that guide.

## Store the schema registry credentials

Store the schema registry password in a Kubernetes Secret. {{ site.operator_product_name }} only watches Secrets labeled `konghq.com/secret="true"`:

```bash
kubectl create secret generic schema-registry-password \
  --from-literal=password="${SCHEMA_REGISTRY_PASSWORD}" \
  -n kong
kubectl label secret schema-registry-password -n kong konghq.com/secret="true"
```

## Create the EventGatewaySchemaRegistry

Create the `EventGatewaySchemaRegistry` resource, pointing at your Confluent-compatible schema registry endpoint:

```bash
echo '
apiVersion: configuration.konghq.com/v1alpha1
kind: EventGatewaySchemaRegistry
metadata:
  name: example-schema-registry
  namespace: kong
spec:
  gatewayRef:
    type: namespacedRef
    namespacedRef:
      name: cp-event-1
  apiSpec:
    type: confluent
    confluent:
      name: example_schema_registry
      description: Schema registry for example_virtual_cluster
      config:
        endpoint: https://schema-registry.example.com
        schemaType: json
        timeoutSeconds: 10
        authentication:
          type: basic
          basic:
            username: schema-registry-user
            password:
              type: secretRef
              secretRef:
                name: schema-registry-password
                key: password
' | kubectl apply -f -
```

Wait for the resource to be ready:

```bash
kubectl wait eventgatewayschemaregistry/example-schema-registry -n kong \
  --for=condition=Programmed=True \
  --timeout=10m
```

## Enforce schema validation on a virtual cluster

Reference the `EventGatewaySchemaRegistry` from an `EventGatewayVirtualClusterConsumePolicy` using `type: schemaValidation`. {{ site.event_gateway }} supports two validation modes, depending on how records are serialized.

### Validate Confluent wire-format records

Use `confluentSchemaRegistry` when producers serialize records with the Confluent wire format (a schema ID embedded in the record header). {{ site.event_gateway }} resolves the schema by ID from the registry:

```bash
echo '
apiVersion: configuration.konghq.com/v1alpha1
kind: EventGatewayVirtualClusterConsumePolicy
metadata:
  name: example-schema-validation-confluent
  namespace: kong
spec:
  eventGatewayVirtualClusterRef:
    type: namespacedRef
    namespacedRef:
      name: example-virtual-cluster
  apiSpec:
    type: schemaValidation
    schemaValidation:
      name: example_schema_validation_confluent
      description: Validate Confluent wire-format records against the registry
      config:
        type: confluentSchemaRegistry
        confluentSchemaRegistry:
          schemaRegistry:
            kind: EventGatewaySchemaRegistry
            name: example-schema-registry
' | kubectl apply -f -
```

### Validate plain JSON records

Use `json` when producers send plain JSON records without a wire-format schema ID. {{ site.event_gateway }} validates the record body against a JSON Schema stored in the registry:

```bash
echo '
apiVersion: configuration.konghq.com/v1alpha1
kind: EventGatewayVirtualClusterConsumePolicy
metadata:
  name: example-schema-validation-json
  namespace: kong
spec:
  eventGatewayVirtualClusterRef:
    type: namespacedRef
    namespacedRef:
      name: example-virtual-cluster
  apiSpec:
    type: schemaValidation
    schemaValidation:
      name: example_schema_validation_json
      description: Validate plain JSON records against the registry
      config:
        type: json
        json:
          schemaRegistry:
            kind: EventGatewaySchemaRegistry
            name: example-schema-registry
' | kubectl apply -f -
```

{:.info}
> Apply only one of these `EventGatewayVirtualClusterConsumePolicy` resources per virtual cluster at a time — they use different names here so you can see both shapes, but a virtual cluster should have a single, consistent schema validation policy. The same `type: schemaValidation` config also works on `EventGatewayVirtualClusterProducePolicy` to validate records before they reach the backend cluster.

Wait for the resource to be ready:

```bash
kubectl wait eventgatewayvirtualclusterconsumepolicy/example-schema-validation-confluent -n kong \
  --for=condition=Programmed=True \
  --timeout=10m
```

## Validate

Check that the policy reconciled without errors:

```bash
kubectl describe eventgatewayvirtualclusterconsumepolicy/example-schema-validation-confluent -n kong
```

A `Programmed=True` condition confirms {{ site.event_gateway }} accepted the policy and is enforcing schema validation on the `example-virtual-cluster` virtual cluster. Records that fail validation are rejected or marked, depending on the `keyValidationAction` and `valueValidationAction` you configure on the policy.
