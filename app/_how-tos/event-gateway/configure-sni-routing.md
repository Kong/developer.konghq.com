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
  q: How can I route traffic to multiple virtual clusters via a single port? 
  a: | 
    To send traffic to multiple virtual clusters with a single port and certificate:
    1. Generate a certificate and use a wildcard for the virtual cluster prefix in the subject.
    1. Create an OpenSSL extension file to set the subject alternative names for the certificate.
    1. Create a listener that listens on a single port.
    1. Create a TLS server listener policy using your certificate and key.
    1. Create a Forward to virtual cluster policy with the port ans SNI suffix.


tools:
    - konnect-api

related_resources:
  - text: Event Gateway
    url: /event-gateway/
  - text: Productize Kafka topics with {{site.event_gateway}}
    url: /event-gateway/productize-kafka-topics/

prereqs:
  inline:
    - title: Install kafkactl
      position: before
      include_content: knep/kafkactl
    - title: Start a local Kafka cluster
      position: before
      include_content: knep/docker-compose-start
---

In this guide we'll set up SNI routing to send traffic to more two virtual clusters in the same Event Gateway without opening more ports on the data plane. For more details, see [Hostname mapping](/event-gateway/architecture/#hostname-mapping).

For testing purposes, this guide generates self-signed certificates and points to hostnames that resolve to `127.0.0.1`. In production, you should use real hostnames, manage the DNS entries, and sign your certificates with a real, trusted CA.

## Create a backend cluster

{% include knep/create-backend-cluster.md insecure=true %}

## Create an analytics virtual cluster

{% include knep/create-virtual-cluster.md name="analytics" auth=false %}

## Create a payments virtual cluster

{% include knep/create-virtual-cluster.md name="payments" auth=false %}

## Define the kafkactl context

Configure kafkactl to use TLS but ignore certificate verification:

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
{: data-test-step="block" }

## Create Kafka topics

Create sample topics in the Kafka cluster that we created in the [prerequisites](#start-a-local-kakfa-cluster):

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

## Generate certificates

Generate the certificates we'll need to enable TLS:

1. Generate the root key and certificate:

   ```sh
   openssl genrsa -out ./rootCA.key 4096
   openssl req -x509 -new -nodes -key ./rootCA.key \
     -sha256 -days 3650 \
     -subj "/C=US/ST=Local/L=Local/O=Dev CA/CN=Dev Root CA" \
     -out ./rootCA.crt
   ```
   {: data-test-step="block" }

1. Generate the gateway key and certificate signing request:

   ```sh
   openssl genrsa -out ./tls.key 2048
   openssl req -new -key ./tls.key \
     -subj "/C=US/ST=Local/L=Local/O=Dev/CN=*.127-0-0-1.sslip.io" \
     -out ./tls.csr
   ```
   {: data-test-step="block" }

   We're setting the subject in the certificate signing request to `*.127-0-0-1.sslip.io`:
   * `*` is used for the virtual cluster prefixes, which are the `analytics` and `payments` DNS labels we configured when creating the virtual clusters.
   * `.127-0-0-1.sslip.io` is the SNI suffix, which we'll use in the TLS listener policy configuration. In this example, we're using [sslip.io](https://sslip.io/) to resolve `127-0-0-1.sslip.io` to `127.0.0.1`.

1. To explicitly set the subject alternative names for the certificate, create an OpenSSL extension file:

   ```sh
   cat << EOF > ./tls.ext
   basicConstraints = CA:FALSE
   keyUsage = digitalSignature, keyEncipherment
   extendedKeyUsage = serverAuth, clientAuth
   subjectAltName = @alt_names
   authorityKeyIdentifier = keyid,issuer
   
   [alt_names]
   DNS.1 = *.analytics.127-0-0-1.sslip.io
   DNS.2 = *.payments.127-0-0-1.sslip.io
   EOF
   ```
   {: data-test-step="block" }
  
1. To generate the certificate we'll need for the TLS listener policy, sign the gateway certificate signing request:

   ```sh
   openssl x509 -req -in ./tls.csr \
      -CA ./rootCA.crt -CAkey ./rootCA.key -CAcreateserial \
      -out ./tls.crt -days 825 -sha256 \
      -extfile ./tls.ext
   ```
   {: data-test-step="block" }

1. Export the key and certificate to your environment:
   {% env_variables %}
   CERTIFICATE: $(awk '{printf "%s\\n", $0}' tls.crt)
   KEY: $(cat tls.key | base64)
   {% endenv_variables %}



## Create a listener

Create a listener that listens on port `19092`:

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

Create a TLS server policy:

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

## Create a Forward to virtual cluster policy

Create a Forward to virtual cluster policy that configures SNI and defines a suffix to expose on the listener:

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

This policy enables routing to each virtual cluster and mapping brokers:

* Bootstrap server to `bootstrap.analytics.127-0-0-1.sslip.io:19092` or `bootstrap.payments.127-0-0-1.sslip.io:19092`
* Broker 1 to `broker-0.analytics.127-0-0-1.sslip.io:19092` or `broker-0.payments.127-0-0-1.sslip.io:19092`
* Broker 2 to `broker-1.analytics.127-0-0-1.sslip.io:19092` or `broker-1.payments.127-0-0-1.sslip.io:19092`
* Broker 3 to `broker-2.analytics.127-0-0-1.sslip.io:19092` or `broker-2.payments.127-0-0-1.sslip.io:19092`

## Validate

Get a list of topics from the `analytics` virtual cluster:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context analytics list topics
expected:
  return_code: 0
  message: |
    TOPIC            PARTITIONS     REPLICATION FACTOR
    clicks           1              1
    orders           1              1
    pageviews        1              1
    user_actions     1              1
render_output: false
{% endvalidation %}

You should see the following result:
```sh
TOPIC            PARTITIONS     REPLICATION FACTOR
clicks           1              1
orders           1              1
pageviews        1              1
user_actions     1              1
```
{:.no-copy-code}
<!--vale on-->

Get a list of topics from the `payments` virtual cluster:
<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context  payments list topics
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

You should see the following result:
```sh
TOPIC            PARTITIONS     REPLICATION FACTOR
orders           1              1
refunds          1              1
transactions     1              1
user_actions     1              1
```
{:.no-copy-code}

<!--vale on-->

You can reach both virtual clusters with a single certificate and through a single port.