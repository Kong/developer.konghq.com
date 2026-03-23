---
title: Authenticate {{site.event_gateway}} connections to Kafka using SASL/PLAIN
content_type: how_to
breadcrumbs:
  - /event-gateway/

permalink: /event-gateway/configure-sasl-plain-backend-cluster-auth/

products:
    - event-gateway

works_on:
    - konnect

tags:
    - event-gateway
    - kafka

description: "Configure SASL/PLAIN authentication so that {{site.event_gateway}} can connect to a secured Kafka cluster."

tldr:
  q: How do I authenticate {{site.event_gateway}} connections to a Kafka cluster using SASL/PLAIN?
  a: |
    Create a backend cluster with `authentication.type: sasl_plain` and supply a `username` and `password`.

tools:
    - konnect-api

prereqs:
  skip_product: true
  inline:
    - title: Install kafkactl
      position: before
      include_content: knep/kafkactl

cleanup:
  inline:
    - title: Clean up {{site.event_gateway}} resources
      include_content: cleanup/products/event-gateway
      icon_url: /assets/icons/gateway.svg

related_resources:
  - text: Backend clusters
    url: /event-gateway/entities/backend-cluster/
  - text: Get started with {{site.event_gateway}}
    url: /event-gateway/get-started/
  - text: Authenticate connections to Kafka using mTLS
    url: /event-gateway/configure-mtls-backend-cluster-auth/
---

In this guide you'll configure {{site.event_gateway_short}} to connect to a secured Kafka cluster using SASL/PLAIN credentials.

{% mermaid %}
flowchart LR
    C[Kafka Client]
    subgraph EG [" {{site.event_gateway_short}} "]
        VC1[sasl virtual cluster]
    end
    subgraph K [Kafka Cluster]
        L1["SASL_PLAINTEXT :9082"]
    end
    C -->|anonymous| VC1
    VC1 -->|SASL/PLAIN| L1
{% endmermaid %}

## Start the secured Kafka cluster

Create the JAAS configuration file that defines the SASL/PLAIN credentials:

```bash
cat <<'EOF' > kafka_server_jaas.conf
KafkaServer {
    org.apache.kafka.common.security.plain.PlainLoginModule required
    username="gateway"
    password="gateway-secret"
    user_gateway="gateway-secret";
};
EOF
```

Create the Docker Compose file:

```bash
cat <<'EOF' > docker-compose.yaml
{% include_cached _files/event-gateway/docker-compose-sasl.yaml %}
EOF
```

The broker exposes a `SASL_PLAINTEXT` listener on port `9082` in the Docker network for {{site.event_gateway_short}} connections, and a `PLAINTEXT` listener on ports `9094`/`9095`/`9096` for direct local access.

Start the cluster:

```bash
docker compose up -d
```

## Create an {{site.event_gateway_short}} control plane and data plane

Run the [quickstart script](https://get.konghq.com/event-gateway) to provision a local data plane and configure your environment:

```bash
curl -Ls https://get.konghq.com/event-gateway | bash -s -- -k $KONNECT_TOKEN -N kafka_event_gateway
```

Copy the exported variable into your terminal:

```bash
export EVENT_GATEWAY_ID=your-gateway-id
```

{% include_cached /knep/quickstart-note.md %}

## Configure kafkactl

Create a `kafkactl.yaml` config file with contexts for direct Kafka access and the SASL virtual cluster:

<!--vale off-->
{% validation custom-command %}
command: |
  cat <<EOF > kafkactl.yaml
  contexts:
    direct:
      brokers:
        - localhost:9094
        - localhost:9095
        - localhost:9096
    sasl-vc:
      brokers:
        - localhost:19092
  EOF
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

Create a test topic using the `direct` context:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context direct create topic orders
expected:
  return_code: 0
  message: "topic created: orders"
render_output: false
{% endvalidation %}
<!--vale on-->

## Create the backend cluster

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/backend-clusters
status_code: 201
method: POST
body:
  name: sasl_backend_cluster
  bootstrap_servers:
    - kafka1:9082
    - kafka2:9082
    - kafka3:9082
  authentication:
    type: sasl_plain
    username: gateway
    password: gateway-secret
  insecure_allow_anonymous_virtual_cluster_auth: true
  tls:
    enabled: false
extract_body:
  - name: id
    variable: SASL_BACKEND_CLUSTER_ID
capture: SASL_BACKEND_CLUSTER_ID
jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

## Create a virtual cluster

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters
status_code: 201
method: POST
body:
  name: sasl_vc
  destination:
    id: $SASL_BACKEND_CLUSTER_ID
  dns_label: sasl-vc
  authentication:
    - type: anonymous
  acl_mode: passthrough
extract_body:
  - name: id
    variable: SASL_VC_ID
capture: SASL_VC_ID
jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

## Create a listener and policy

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/listeners
status_code: 201
method: POST
body:
  name: sasl_listener
  addresses:
    - 0.0.0.0
  ports:
    - 19092-19095
extract_body:
  - name: id
    variable: SASL_LISTENER_ID
capture: SASL_LISTENER_ID
jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/listeners/$SASL_LISTENER_ID/policies
status_code: 201
method: POST
body:
  type: forward_to_virtual_cluster
  name: forward_to_sasl_vc
  config:
    type: port_mapping
    advertised_host: localhost
    destination:
      id: $SASL_VC_ID
{% endkonnect_api_request %}
<!--vale on-->

## Validate

List the topics through the `sasl-vc` virtual cluster:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context sasl-vc list topics
expected:
  return_code: 0
  message: |
    TOPIC     PARTITIONS     REPLICATION FACTOR
    orders    1              1
render_output: false
{% endvalidation %}
<!--vale on-->

```shell
TOPIC     PARTITIONS     REPLICATION FACTOR
orders    1              1
```
{:.no-copy-code}

{{site.event_gateway_short}} authenticated to Kafka using the `gateway` SASL/PLAIN credentials and forwarded the metadata request successfully.
