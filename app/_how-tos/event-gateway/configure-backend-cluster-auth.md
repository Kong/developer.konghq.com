---
title: Authenticate {{site.event_gateway}} connections to Kafka
content_type: how_to
breadcrumbs:
  - /event-gateway/

permalink: /event-gateway/configure-backend-cluster-auth/

products:
    - event-gateway

works_on:
    - konnect

tags:
    - event-gateway
    - kafka

description: "Configure SASL/PLAIN and mTLS authentication so that {{site.event_gateway}} can connect to a secured Kafka cluster."

tldr:
  q: How do I authenticate {{site.event_gateway}} connections to a secured Kafka cluster?
  a: |
    1. **SASL/PLAIN**: Create a backend cluster with `authentication.type: sasl_plain` and supply a `username` and `password`.
    1. **mTLS**: Create a backend cluster with `tls.enabled: true` and supply a CA bundle and a client certificate and key in `tls.client_identity`.

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
---

In this guide you'll configure {{site.event_gateway_short}} to connect to the same Kafka cluster in two different ways: using SASL/PLAIN credentials and using a mutual TLS client certificate. Both are common requirements when Kafka enforces authentication on its listeners.

{% mermaid %}
flowchart LR
    C[Kafka Client]
    subgraph EG [" {{site.event_gateway_short}} "]
        VC1[sasl virtual cluster]
        VC2[mtls virtual cluster]
    end
    subgraph K [Kafka Cluster]
        L1["SASL_PLAINTEXT :9082"]
        L2["SSL :9088"]
    end
    C -->|anonymous| VC1
    C -->|anonymous| VC2
    VC1 -->|SASL/PLAIN| L1
    VC2 -->|mTLS| L2
{% endmermaid %}

## Generate TLS certificates

Generate a CA, per-broker JKS keystores, and a PEM client certificate for {{site.event_gateway_short}}.
This requires OpenSSL and `keytool` (included in any JDK installation).

```bash
mkdir -p certs

# CA
openssl req -new -x509 -nodes -keyout certs/ca.key -out certs/ca.crt \
  -days 365 -subj "/CN=Kafka-CA"

# Credentials file (password used for all keystores)
echo "changeit" > certs/keystore-credentials

# Shared truststore (imported by all brokers)
keytool -import -trustcacerts -alias CARoot \
  -file certs/ca.crt -keystore certs/truststore.jks \
  -storepass changeit -noprompt

# Per-broker keystores
for broker in kafka1 kafka2 kafka3; do
  # Generate key pair
  keytool -genkeypair -alias "$broker" \
    -keyalg RSA -keysize 2048 -dname "CN=$broker" \
    -keystore "certs/$broker.keystore.jks" \
    -storepass changeit -keypass changeit -validity 365

  # Export CSR and sign it with the CA
  keytool -certreq -alias "$broker" \
    -keystore "certs/$broker.keystore.jks" \
    -storepass changeit -file "certs/$broker.csr"
  printf "subjectAltName=DNS:%s" "$broker" > "certs/$broker.ext"
  openssl x509 -req -in "certs/$broker.csr" \
    -CA certs/ca.crt -CAkey certs/ca.key -CAcreateserial \
    -out "certs/$broker.crt" -days 365 -extfile "certs/$broker.ext"

  # Import CA then signed cert back into the keystore
  keytool -import -trustcacerts -alias CARoot \
    -file certs/ca.crt -keystore "certs/$broker.keystore.jks" \
    -storepass changeit -noprompt
  keytool -import -alias "$broker" \
    -file "certs/$broker.crt" -keystore "certs/$broker.keystore.jks" \
    -storepass changeit -noprompt
done

# Client certificate for {{site.event_gateway_short}} (PEM format, used by the API)
openssl genrsa -out certs/client.key 2048
openssl req -new -key certs/client.key -out certs/client.csr -subj "/CN=event-gateway"
openssl x509 -req -in certs/client.csr -CA certs/ca.crt -CAkey certs/ca.key \
  -CAcreateserial -out certs/client.crt -days 365
```

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
{% include_cached _files/event-gateway/docker-compose-secured.yaml %}
EOF
```

Each broker exposes three listeners:
- `SASL_PLAINTEXT` on port `9082` in the Docker network: Used for {{site.event_gateway_short}} SASL/PLAIN connections.
- `SSL` on port `9088` in the Docker network: Used for {{site.event_gateway_short}} mTLS connections (client certificate required).
- `PLAINTEXT` on port `9094`/`9095`/`9096` port-forwarded: Used for direct local access.

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

Create a `kafkactl.yaml` config file with contexts for direct Kafka access and each virtual cluster:

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
    mtls-vc:
      brokers:
        - localhost:19096
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

## Part 1: SASL/PLAIN backend cluster auth

Configure {{site.event_gateway_short}} to authenticate to Kafka using a username and password on the `SASL_PLAINTEXT` listener.

### Create the backend cluster

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

### Create a virtual cluster

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

### Create a listener and policy

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

### Validate

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

## Part 2: mTLS backend cluster auth

Configure {{site.event_gateway_short}} to authenticate to Kafka by presenting a client certificate on the `SSL` listener.

### Create the backend cluster

The `ca_bundle` and `client_identity.certificate` fields accept PEM-encoded strings.
The `client_identity.key` field requires a base64-encoded value.

Build the request body:

<!--vale off-->
{% validation custom-command %}
command: |
  jq -n \
    --rawfile ca_bundle certs/ca.crt \
    --rawfile certificate certs/client.crt \
    --arg key "$(cat certs/client.key | base64)" \
    '{
      "name": "mtls_backend_cluster",
      "bootstrap_servers": ["kafka1:9088", "kafka2:9088", "kafka3:9088"],
      "authentication": {"type": "anonymous"},
      "insecure_allow_anonymous_virtual_cluster_auth": true,
      "tls": {
        "enabled": true,
        "ca_bundle": $ca_bundle,
        "client_identity": {"certificate": $certificate, "key": $key}
      }
    }' > mtls_backend_cluster.json
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/backend-clusters
status_code: 201
method: POST
body_cmd: $(cat mtls_backend_cluster.json)
extract_body:
  - name: id
    variable: MTLS_BACKEND_CLUSTER_ID
capture: MTLS_BACKEND_CLUSTER_ID
jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

The `ca_bundle` lets {{site.event_gateway_short}} verify the broker's certificate.
The `client_identity` holds the certificate and key that {{site.event_gateway_short}} presents to Kafka during the TLS handshake.

### Create a virtual cluster

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters
status_code: 201
method: POST
body:
  name: mtls_vc
  destination:
    id: $MTLS_BACKEND_CLUSTER_ID
  dns_label: mtls-vc
  authentication:
    - type: anonymous
  acl_mode: passthrough
extract_body:
  - name: id
    variable: MTLS_VC_ID
capture: MTLS_VC_ID
jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

### Create a listener and policy

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/listeners
status_code: 201
method: POST
body:
  name: mtls_listener
  addresses:
    - 0.0.0.0
  ports:
    - 19096-19099
extract_body:
  - name: id
    variable: MTLS_LISTENER_ID
capture: MTLS_LISTENER_ID
jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/listeners/$MTLS_LISTENER_ID/policies
status_code: 201
method: POST
body:
  type: forward_to_virtual_cluster
  name: forward_to_mtls_vc
  config:
    type: port_mapping
    advertised_host: localhost
    destination:
      id: $MTLS_VC_ID
{% endkonnect_api_request %}
<!--vale on-->

### Validate

List the topics through the `mtls-vc` virtual cluster:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context mtls-vc list topics
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

{{site.event_gateway_short}} completed the mTLS handshake with Kafka using the client certificate and forwarded the metadata request successfully.
