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
    controllers: [KEGDATAPLANE]
  inline:
    - title: Kubernetes namespaces
      position: before
      content: |
          Create the namespaces used throughout this tutorial:

          ```bash
          kubectl create namespace kong
          kubectl create namespace kafka
          ```
      icon_url: /assets/icons/kubernetes.svg
    - title: Kafka cluster
      position: before
      content: |
          The schema registry stores its schemas in Kafka, and {{ site.event_gateway }} needs a backend cluster to proxy. Deploy a three-broker Kafka cluster with the Bitnami chart:

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

          1. Wait for all Kafka brokers to be ready:

             ```bash
             kubectl wait pod -n kafka \
               --for=condition=Ready \
               --selector app.kubernetes.io/name=kafka \
               --timeout=5m
             ```
      icon_url: /assets/icons/kubernetes.svg
    - title: Confluent Schema Registry
      position: before
      content: |
          Deploy a Confluent Schema Registry backed by the Kafka cluster. Running it in the cluster means {{ site.event_gateway }} can reach it at `http://schema-registry.kafka.svc.cluster.local:8081`:

          1. Deploy the registry and its Service:

             ```bash
             echo '
             apiVersion: apps/v1
             kind: Deployment
             metadata:
               name: schema-registry
               namespace: kafka
             spec:
               replicas: 1
               selector:
                 matchLabels:
                   app: schema-registry
               template:
                 metadata:
                   labels:
                     app: schema-registry
                 spec:
                   enableServiceLinks: false
                   containers:
                     - name: schema-registry
                       image: confluentinc/cp-schema-registry:8.2.1
                       ports:
                         - containerPort: 8081
                       env:
                         - name: SCHEMA_REGISTRY_HOST_NAME
                           value: schema-registry
                         - name: SCHEMA_REGISTRY_LISTENERS
                           value: http://0.0.0.0:8081
                         - name: SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS
                           value: kafka-cluster.kafka.svc.cluster.local:9092
             ---
             apiVersion: v1
             kind: Service
             metadata:
               name: schema-registry
               namespace: kafka
             spec:
               selector:
                 app: schema-registry
               ports:
                 - name: http
                   port: 8081
                   targetPort: 8081
             ' | kubectl apply -f -
             ```

          1. Wait for the registry to be ready:

             ```bash
             kubectl wait pod -n kafka \
               --for=condition=Ready \
               --selector app=schema-registry \
               --timeout=5m
             ```
      icon_url: /assets/icons/kubernetes.svg
    - title: "{{ site.event_gateway }} control plane, backend cluster, and virtual cluster"
      content: |
          The schema registry and the schema validation policy attach to a {{ site.event_gateway }} control plane and virtual cluster. Create them, along with the backend cluster that points at Kafka:

          1. Create the `KonnectEventGateway` resource:

             ```bash
             echo '
             apiVersion: konnect.konghq.com/v1alpha1
             kind: KonnectEventGateway
             metadata:
               name: cp-event-1
               namespace: kong
             spec:
               apiSpec:
                 name: cp-event-1
                 description: Event Gateway control plane managed by Kubernetes
               konnect:
                 authRef:
                   name: konnect-api-auth
             ' | kubectl apply -f -

             kubectl wait konnecteventgateway/cp-event-1 -n kong \
               --for=condition=Programmed=True \
               --timeout=10m
             ```

          1. Create the `EventGatewayBackendCluster` resource:

             ```bash
             echo '
             apiVersion: configuration.konghq.com/v1alpha1
             kind: EventGatewayBackendCluster
             metadata:
               name: default-backend-cluster
               namespace: kong
             spec:
               gatewayRef:
                 type: namespacedRef
                 namespacedRef:
                   name: cp-event-1
               apiSpec:
                 name: default_backend_cluster
                 bootstrapServers:
                   - kafka-cluster.kafka.svc.cluster.local:9092
                 authentication:
                   type: anonymous
                   anonymous: {}
                 insecureAllowAnonymousVirtualClusterAuth: Enabled
                 tls:
                   enabled: Disabled
             ' | kubectl apply -f -

             kubectl wait eventgatewaybackendcluster/default-backend-cluster -n kong \
               --for=condition=Programmed=True \
               --timeout=10m
             ```

          1. Create the `EventGatewayVirtualCluster` resource:

             ```bash
             echo '
             apiVersion: configuration.konghq.com/v1alpha1
             kind: EventGatewayVirtualCluster
             metadata:
               name: example-virtual-cluster
               namespace: kong
             spec:
               eventGatewayBackendClusterRef:
                 type: namespacedRef
                 namespacedRef:
                   name: default-backend-cluster
               apiSpec:
                 name: example_virtual_cluster
                 dnsLabel: vcluster-1
                 aclMode: passthrough
                 authentication:
                   - type: anonymous
                 namespace:
                   prefix: "vc1_"
                   mode: hide_prefix
             ' | kubectl apply -f -

             kubectl wait eventgatewayvirtualcluster/example-virtual-cluster -n kong \
               --for=condition=Programmed=True \
               --timeout=10m
             ```
      icon_url: /assets/icons/event.svg

faqs:
  - q: How do I validate plain JSON records?
    a: |
      Use `json` instead of `confluentSchemaRegistry` when producers send plain JSON records without a wire-format schema ID. This mode only checks that each record is valid JSON, so it doesn't consult a schema registry. Omit `schemaRegistry` entirely, {{ site.konnect_short_name }} rejects it when `type` is `json`.

      Apply this policy in place of the `confluentSchemaRegistry` one, not alongside it:

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
            description: Validate that consumed records are valid JSON
            config:
              type: json
              json:
                valueValidationAction: skip
      ' | kubectl apply -f -
      ```

  - q: How do I connect to a schema registry that requires authentication?
    a: |
      The registry deployed in the prerequisites accepts unauthenticated requests, so the `authentication` field is omitted in this tutorial. If your own registry requires basic authentication, store the password in a Kubernetes Secret. {{ site.operator_product_name }} only watches Secrets labeled `konghq.com/secret="true"`:

      ```bash
      kubectl create secret generic schema-registry-password \
        --from-literal=password='my-schema-registry-password' \
        -n kong
      kubectl label secret schema-registry-password -n kong konghq.com/secret="true"
      ```

      Then add an `authentication` block to `config` that references the Secret:

      ```yaml
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
      ```

related_resources:
  - text: Deploy {{ site.event_gateway }} with port mapping
    url: /operator/get-started/event-gateway/port-mapping/
  - text: "{{ site.event_gateway }} with {{ site.operator_product_name }}"
    url: /operator/konnect/event-gateway/
  - text: Policies
    url: /event-gateway/entities/policy/
---

`EventGatewaySchemaRegistry` connects {{ site.event_gateway }} to a schema registry so consume and produce policies can validate Kafka record schemas before they reach clients or your backend cluster.

The examples below use the `cp-event-1` control plane, `example-virtual-cluster` virtual cluster, and `schema-registry` registry Service created in the prerequisites.

## Create the EventGatewaySchemaRegistry

1. Create the `EventGatewaySchemaRegistry` resource, pointing at the schema registry endpoint:

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
           endpoint: http://schema-registry.kafka.svc.cluster.local:8081
           schemaType: json
           timeoutSeconds: 10
   ' | kubectl apply -f -
   ```

1. Wait for the resource to be ready:

   ```bash
   kubectl wait eventgatewayschemaregistry/example-schema-registry -n kong \
     --for=condition=Programmed=True \
     --timeout=10m
   ```

## Enforce schema validation on a virtual cluster

Reference the `EventGatewaySchemaRegistry` from an `EventGatewayVirtualClusterConsumePolicy` using `type: schemaValidation`. {{ site.event_gateway }} supports two validation modes, depending on how records are serialized.

This example uses `confluentSchemaRegistry`, for producers that serialize records with the Confluent wire format (a schema ID embedded in the record header). {{ site.event_gateway }} resolves the schema by ID from the registry:

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
          keyValidationAction: mark
          valueValidationAction: mark
' | kubectl apply -f -
```

If your producers send plain JSON records without a wire-format schema ID, use the `json` mode instead. For more information, see the [FAQs](#how-do-i-validate-plain-json-records).

{:.info}
> A virtual cluster should have a single, consistent schema validation policy, so apply only one `EventGatewayVirtualClusterConsumePolicy` with `type: schemaValidation` at a time. The same `type: schemaValidation` config also works on `EventGatewayVirtualClusterProducePolicy` to validate records before they reach the backend cluster.

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

A `Programmed=True` condition confirms {{ site.event_gateway }} accepted the policy and is enforcing schema validation on the `example-virtual-cluster` virtual cluster. Records that fail validation are either marked with a `kong/server` header or skipped so they aren't delivered to the client, depending on whether you set `mark` or `skip` in `keyValidationAction` and `valueValidationAction`.
