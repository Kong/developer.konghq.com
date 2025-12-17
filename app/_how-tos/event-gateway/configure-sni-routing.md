---
title: Configure SNI routing with {{site.event_gateway}}
content_type: how_to
breadcrumbs:
  - /event-gateway/

permalink: /event-gateway/configure-sni-routing/

products:
    - event-gateway

works_on:
    - konnect

tags:
    - event-gateway
    - kafka

description: Set up SNI routing to send traffic to multiple virtual clusters in the same Event Gateway control plane without opening more ports on the data plane.

tldr: 
  q: TODO 
  a: | 
    TODO

tools:
    - konnect-api

related_resources:
  - text: Event Gateway
    url: /event-gateway/

prereqs:
  inline:
    - title: Install kafkactl
      position: before
      include_content: knep/kafkactl
    - title: Start a local Kafka cluster
      position: before
      include_content: knep/docker-compose-start
---

## Create a backend cluster

{% include knep/create-backend-cluster.md %}

## Create an analytics virtual cluster

{% include knep/create-virtual-cluster.md name="analytics" %}

## Create a payments virtual cluster

{% include knep/create-virtual-cluster.md name="payments" %}

## Define the kafkactl context

```sh
cat <<EOF > kafkactl.yaml
contexts:
  backend:
    brokers:
      - localhost:9094
  analytics:
    brokers:
      - bootstrap.analytics.127-0-0-1.sslip.io:19092
    tls:
      enabled: true
      ca: ./rootCA.crt
      insecure: true
  payments:
    brokers:
      - bootstrap.payments.127-0-0-1.sslip.io:19092
    tls:
      enabled: true
      ca: ./rootCA.crt
      insecure: true
EOF
```

## Create Kafka topics

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context backend create topic \
  analytics_pageviews analytics_clicks analytics_orders \
  payments_transactions payments_refunds payments_orders \
  user_actions
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

## Generate root key and certificate

```sh
openssl genrsa -out ./rootCA.key 4096
openssl req -x509 -new -nodes -key ./rootCA.key \
-sha256 -days 3650 \
	-subj "/C=US/ST=Local/L=Local/O=Dev CA/CN=Dev Root CA" \
	-out ./rootCA.crt
```

## Generate the gateway key and certificate signing request

```sh
openssl genrsa -out ./tls.key 2048
openssl req -new -key ./tls.key \
-subj "/C=US/ST=Local/L=Local/O=Dev/CN=*.127-0-0-1.sslip.io" \
	-out ./tls.csr
```

## Create extension file

```sh
cat << EOF > ./tls.ext
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names
authorityKeyIdentifier = keyid,issuer

[alt_names]
DNS.1 = *.analytics.127-0-0-1.sslip.io
DNS.2 = analytics.127-0-0-1.sslip.io
DNS.3 = *.payments.127-0-0-1.sslip.io
DNS.4 = payments.127-0-0-1.sslip.io
EOF
```

## Sign gateway certificate signing request

```sh
openssl x509 -req -in ./tls.csr \
	-CA ./rootCA.crt -CAkey ./rootCA.key -CAcreateserial \
	-out ./tls.crt -days 825 -sha256 \
	-extfile ./tls.ext
```

## Export the key and certificate
```sh
export CERTIFICATE=$(cat tls.crt | base64)
export KEY=$(cat tls.key | base64)
```

## Create a listener

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/listeners
status_code: 201
method: POST
body:
  name: gateway_listener
  addresses:
    - 0.0.0.0
  ports:
    - 19092
extract_body:
  - name: id
    variable: LISTENER_ID
capture: LISTENER_ID
jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

## Create a TLS server listener policy

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/listeners/$LISTENER_ID/policies
status_code: 201
method: POST
body:
  type: tls_server
  name: tls_server
  config:
    certificates:
      - certificate: $CERTIFICATE
        key: $KEY
{% endkonnect_api_request %}
<!--vale on-->

## Create a Forward to Virtual Cluster policy

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/listeners/$LISTENER_ID/policies
status_code: 201
method: POST
body:
  type: forward_to_virtual_cluster
  name: forward_to_virtual_cluster
  config:
    type: sni
    advertised_port: 19092
    sni_suffix: .127-0-0-1.sslip.io
{% endkonnect_api_request %}
<!--vale on-->

## Validate

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context payments list topics
expected:
  return_code: 0
  message: |
    TOPIC            PARTITIONS     REPLICATION FACTOR
    orders           1              1
    refunds          1              1
    transactions     1              1
    user_actions     1              1
render_output: false
{% endvalidation %}

<!--vale on-->