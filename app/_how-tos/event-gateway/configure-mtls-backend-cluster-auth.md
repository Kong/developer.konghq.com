---
title: Authenticate {{site.event_gateway}} connections to Kafka using mTLS
content_type: how_to
breadcrumbs:
  - /event-gateway/

permalink: /event-gateway/configure-mtls-backend-cluster-auth/

products:
    - event-gateway

works_on:
    - konnect

tags:
    - event-gateway
    - kafka

description: "Configure mTLS authentication so that {{site.event_gateway}} can connect to a secured Kafka cluster."

tldr:
  q: How do I authenticate {{site.event_gateway}} connections to a Kafka cluster using mTLS?
  a: |
    Create a backend cluster with `tls.enabled: true` and supply a CA bundle and a client certificate and key in `tls.client_identity`.

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
  - text: Authenticate connections to Kafka using SASL/PLAIN
    url: /event-gateway/configure-sasl-plain-backend-cluster-auth/

min_version:
  event_gateway: '1.1.0'
---

In this guide you'll configure {{site.event_gateway_short}} to connect to a secured Kafka cluster by presenting a mutual TLS client certificate.

{% mermaid %}
flowchart LR
    C[Kafka Client]
    subgraph EG [" {{site.event_gateway_short}} "]
        VC2[mtls virtual cluster]
    end
    subgraph K [Kafka Cluster]
        L2["SSL :9088"]
    end
    C -->|anonymous| VC2
    VC2 -->|mTLS| L2
{% endmermaid %}

## Generate TLS certificates

Generate a CA, per-broker JKS keystores, and a PEM client certificate for {{site.event_gateway_short}}.
This requires OpenSSL and `keytool` (included in any JDK installation).

1. Create the output directory and generate a self-signed CA certificate:

    ```bash
    mkdir -p certs
    openssl req -new -x509 -nodes -keyout certs/ca.key -out certs/ca.crt \
      -days 365 -subj "/CN=Kafka-CA"
    ```

1. Create the credentials file used as the password for all keystores, then import the CA into a shared truststore that all brokers will reference:

    ```bash
    echo "changeit" > certs/keystore-credentials
    keytool -import -trustcacerts -alias CARoot \
      -file certs/ca.crt -keystore certs/truststore.jks \
      -storepass changeit -noprompt
    ```

1. For each broker, generate a key pair, sign it with the CA, and import both the CA certificate and the signed broker certificate into the broker's keystore:

    ```bash
    for broker in kafka1 kafka2 kafka3; do
      keytool -genkeypair -alias "$broker" \
        -keyalg RSA -keysize 2048 -dname "CN=$broker" \
        -keystore "certs/$broker.keystore.jks" \
        -storepass changeit -keypass changeit -validity 365

      keytool -certreq -alias "$broker" \
        -keystore "certs/$broker.keystore.jks" \
        -storepass changeit -file "certs/$broker.csr"
      printf "subjectAltName=DNS:%s" "$broker" > "certs/$broker.ext"
      openssl x509 -req -in "certs/$broker.csr" \
        -CA certs/ca.crt -CAkey certs/ca.key -CAcreateserial \
        -out "certs/$broker.crt" -days 365 -extfile "certs/$broker.ext"

      keytool -import -trustcacerts -alias CARoot \
        -file certs/ca.crt -keystore "certs/$broker.keystore.jks" \
        -storepass changeit -noprompt
      keytool -import -alias "$broker" \
        -file "certs/$broker.crt" -keystore "certs/$broker.keystore.jks" \
        -storepass changeit -noprompt
    done
    ```

1. Generate a PEM client certificate for {{site.event_gateway_short}}:

    ```bash
    openssl genrsa -out certs/client.key 2048
    openssl req -new -key certs/client.key -out certs/client.csr -subj "/CN=event-gateway"
    openssl x509 -req -in certs/client.csr -CA certs/ca.crt -CAkey certs/ca.key \
      -CAcreateserial -out certs/client.crt -days 365
    ```

## Start the secured Kafka cluster

Create the Docker Compose file:

```bash
cat <<'EOF' > docker-compose.yaml
{% include_cached _files/event-gateway/docker-compose-mtls.yaml %}
EOF
```

The broker exposes an `SSL` listener on port `9088` in the Docker network for {{site.event_gateway_short}} mTLS connections (client certificate required), and a `PLAINTEXT` listener on ports `9094`/`9095`/`9096` for direct local access.

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

Create a `kafkactl.yaml` config file with contexts for direct Kafka access and the mTLS virtual cluster:

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

## Create the backend cluster

The `ca_bundle` and `client_identity.certificate` fields accept PEM-encoded strings.
The `client_identity.key` field requires a base64-encoded value.

Build the request body with TLS enabled:

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

Then, create the backend cluster:

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

## Create a virtual cluster

Run the following command to create a [virtual cluster](/event-gateway/entities/virtual-cluster/) with `anonymous` authentication:

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

## Create a listener

Run the following command to create a [listener](/event-gateway/entities/listener/):

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

## Create a listener policy

Add a [Forward to Virtual Cluster](/event-gateway/policies/forward-to-virtual-cluster/) policy,
which will forward requests based on a defined mapping to our virtual cluster:

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

## Validate

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
