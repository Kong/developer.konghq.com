---
title: Configure mTLS client authentication with {{site.event_gateway}}
content_type: how_to
breadcrumbs:
  - /event-gateway/

permalink: /event-gateway/configure-mtls-client-authentication/

products:
    - event-gateway

works_on:
    - konnect

tags:
    - event-gateway
    - kafka

description: "Require Kafka clients to present a trusted certificate when connecting to {{site.event_gateway}} using mutual TLS (mTLS), and use principals derived from the client certificate to enforce access control."

tldr:
  q: How can I require client certificates for Kafka connections to {{site.event_gateway}} and enforce access control?
  a: |
    1. Generate a CA certificate, a server certificate, and client certificates for each principal.
    1. Create a TLS trust bundle and a TLS server listener policy with `client_authentication` set to `required`.
    1. Create a virtual cluster with `client_certificate` authentication and ACL policies that restrict access based on the certificate principal name.

tools:
    - konnect-api

prereqs:
  inline:
    - title: Install kafkactl
      position: before
      include_content: knep/kafkactl
    - title: Start a local Kafka cluster
      position: before
      include_content: knep/docker-compose-start

cleanup:
  inline:
    - title: Clean up {{site.event_gateway}} resources
      include_content: cleanup/products/event-gateway
      icon_url: /assets/icons/gateway.svg

related_resources:
  - text: TLS trust bundles
    url: /event-gateway/entities/tls-trust-bundle/
  - text: TLS Server policy
    url: /event-gateway/policies/tls-server/
  - text: ACLs policy
    url: /event-gateway/policies/acl/
  - text: "{{site.event_gateway_short}} Control Plane API"
    url: /api/konnect/event-gateway/

min_version:
  event-gateway: '1.1.0'
---

## Overview

Mutual TLS (mTLS) secures client-to-gateway communication by requiring clients to present a certificate during the TLS handshake.
{{site.event_gateway_short}} verifies the client certificate against a [TLS trust bundle](/event-gateway/entities/tls-trust-bundle/) that contains one or more trusted CA certificates.

When combined with `client_certificate` authentication on a [virtual cluster](/event-gateway/entities/virtual-cluster/), the certificate's Common Name (CN) becomes the client's principal name. This allows you to enforce fine-grained access control using [ACL policies](/event-gateway/policies/acl/).

{% mermaid %}
flowchart LR
    C[Kafka Client] -->|1. TLS handshake +<br/>client certificate| L

    subgraph gw [Event Gateway]
        L[Listener] -->|2. Verify against<br/>trust bundle| TB[TLS Trust<br/>Bundle]
        L -->|3. Route| VC[Virtual<br/>Cluster]
        VC -->|4. Extract principal<br/>from certificate CN| ACL[ACL<br/>Policy]
    end

    ACL -->|5. Proxy| K[Kafka<br/>Broker]
{% endmermaid %}

The `client_authentication` configuration on the [TLS server policy](/event-gateway/policies/tls-server/) supports two modes:

<!--vale off-->
{% table %}
columns:
  - title: Mode
    key: mode
  - title: Behavior
    key: behavior
rows:
  - mode: "`required`"
    behavior: "The client must present a valid certificate. Connections without a certificate are rejected."
  - mode: "`requested`"
    behavior: "The gateway requests a certificate but allows connections without one. If a certificate is presented but cannot be verified, the connection is closed."
{% endtable %}
<!--vale on-->

This guide uses `required` mode to enforce mTLS for all connections, and sets up ACL policies to give different permissions to two clients based on their certificate identity.

## Generate certificates

For this guide, we generate self-signed certificates for testing. In production, use certificates issued by your organization's CA.

1. Generate a CA key and certificate:

   ```sh
   openssl genrsa -out ca.key 2048
   openssl req -new -x509 -key ca.key -out ca.crt -days 365 \
     -subj "/CN=Demo mTLS CA/O=Kong Demo/C=EU" \
     -addext "basicConstraints=critical,CA:TRUE" \
     -addext "keyUsage=critical,keyCertSign,cRLSign"
   ```
   {: data-test-step="block" }

1. Generate a client certificate for the **producer** client:

   ```sh
   openssl genrsa -out producer.key 2048
   openssl req -new -key producer.key -out producer.csr \
     -subj "/CN=producer-client/O=Kong Demo/C=EU"
   openssl x509 -req -in producer.csr -CA ca.crt -CAkey ca.key \
     -CAcreateserial -out producer.crt -days 90 \
     -extfile <(printf "basicConstraints=CA:FALSE\nkeyUsage=digitalSignature,keyEncipherment\nextendedKeyUsage=clientAuth")
   ```
   {: data-test-step="block" }

1. Generate a client certificate for the **consumer** client:

   ```sh
   openssl genrsa -out consumer.key 2048
   openssl req -new -key consumer.key -out consumer.csr \
     -subj "/CN=consumer-client/O=Kong Demo/C=EU"
   openssl x509 -req -in consumer.csr -CA ca.crt -CAkey ca.key \
     -CAcreateserial -out consumer.crt -days 90 \
     -extfile <(printf "basicConstraints=CA:FALSE\nkeyUsage=digitalSignature,keyEncipherment\nextendedKeyUsage=clientAuth")
   ```
   {: data-test-step="block" }

1. Generate a server certificate for the gateway listener:

   ```sh
   openssl genrsa -out server.key 2048
   openssl req -new -x509 -key server.key -out server.crt -days 365 \
     -subj "/CN=localhost/O=Kong Demo/C=EU" \
     -addext "subjectAltName=DNS:localhost"
   ```
   {: data-test-step="block" }

1. Export the certificates and key to environment variables:

   {% env_variables %}
   CA_CERT: $(awk '{printf "%s\\n", $0}' ca.crt)
   SERVER_CERT: $(awk '{printf "%s\\n", $0}' server.crt)
   SERVER_KEY: $(cat server.key | base64)
   {% endenv_variables %}

## Create a backend cluster

{% include knep/create-backend-cluster.md %}

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
    - 19092-19095
extract_body:
  - name: id
    variable: LISTENER_ID
capture:
    - variable: LISTENER_ID
      jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

## Create a TLS trust bundle

A [TLS trust bundle](/event-gateway/entities/tls-trust-bundle/) stores CA certificates used to verify client certificates during the mTLS handshake. Create the bundle:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/tls-trust-bundles
status_code: 201
method: POST
body:
  name: demo-ca-bundle
  description: CA certificate for client verification
  config:
    trusted_ca: $CA_CERT
extract_body:
  - name: id
    variable: BUNDLE_ID
capture:
    - variable: BUNDLE_ID
      jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

## Create a TLS server listener policy

Create a [TLS server policy](/event-gateway/policies/tls-server/) with `client_authentication` enabled.
The gateway presents the server certificate to clients and verifies client certificates against the trust bundle.

The `principal_mapping` field is an expression that extracts a principal name from the client certificate after a successful TLS handshake. The expression has access to a `context.certificate` variable with the following fields:

<!--vale off-->
{% table %}
columns:
  - title: Field
    key: field
  - title: Type
    key: type
  - title: Description
    key: description
rows:
  - field: "`context.certificate.subject`"
    type: "map"
    description: "Subject distinguished name as a map. Access individual attributes like `context.certificate.subject['CN']` (Common Name) or `context.certificate.subject['O']` (Organization)."
  - field: "`context.certificate.issuer`"
    type: "map"
    description: "Issuer distinguished name as a map, same format as `subject`."
  - field: "`context.certificate.serialNumber`"
    type: "string"
    description: "Serial number of the certificate."
  - field: "`context.certificate.sans.dns`"
    type: "array"
    description: "DNS Subject Alternative Names."
  - field: "`context.certificate.sans.uri`"
    type: "array"
    description: "URI Subject Alternative Names."
{% endtable %}
<!--vale on-->

If `principal_mapping` is omitted, the principal defaults to the full subject distinguished name (for example, `CN=producer-client, O=Kong Demo, C=EU`).

This guide uses `context.certificate.subject['CN']` to extract only the Common Name, so the principal becomes `producer-client`.

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/listeners/$LISTENER_ID/policies
status_code: 201
method: POST
body:
  type: tls_server
  name: mtls_policy
  config:
    certificates:
      - certificate: $SERVER_CERT
        key: $SERVER_KEY
    client_authentication:
      mode: required
      principal_mapping: context.certificate.subject["CN"]
      tls_trust_bundles:
        - id: $BUNDLE_ID
{% endkonnect_api_request %}
<!--vale on-->

## Create a virtual cluster

Create a virtual cluster with `client_certificate` authentication.
The certificate's Common Name (CN) is extracted via `principal_mapping` and used as the principal name for ACL evaluation.

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters
status_code: 201
method: POST
body:
  name: mtls_virtual_cluster
  destination:
    id: $BACKEND_CLUSTER_ID
  dns_label: mtls-vc
  authentication:
    - type: client_certificate
  acl_mode: enforce_on_gateway
extract_body:
  - name: id
    variable: VIRTUAL_CLUSTER_ID
capture:
    - variable: VIRTUAL_CLUSTER_ID
      jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

## Create a forward-to-virtual-cluster listener policy

Add a [Forward to Virtual Cluster](/event-gateway/policies/forward-to-virtual-cluster/) policy,
which will forward requests based on a defined mapping to our virtual cluster:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/listeners/$LISTENER_ID/policies
status_code: 201
method: POST
body:
  type: forward_to_virtual_cluster
  name: forward_to_mtls_vc
  config:
    type: port_mapping
    advertised_host: localhost
    destination:
      id: $VIRTUAL_CLUSTER_ID
{% endkonnect_api_request %}
<!--vale on-->

## Create ACL policies

Create ACL policies that restrict access based on the certificate principal name. The producer client gets write access and the consumer client gets read access.

### Producer ACL

Allow the `producer-client` principal to produce messages and describe topics:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$VIRTUAL_CLUSTER_ID/cluster-policies
status_code: 201
method: POST
body:
  type: acls
  name: producer_acl
  condition: context.auth.principal.name == "producer-client"
  config:
    rules:
    - resource_type: topic
      action: allow
      operations:
        - name: write
        - name: describe
        - name: describe_configs
      resource_names:
      - match: '*'
{% endkonnect_api_request %}
<!--vale on-->

### Consumer ACL

Allow the `consumer-client` principal to consume messages and manage consumer groups:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$VIRTUAL_CLUSTER_ID/cluster-policies
status_code: 201
method: POST
body:
  type: acls
  name: consumer_acl
  condition: context.auth.principal.name == "consumer-client"
  config:
    rules:
    - resource_type: topic
      action: allow
      operations:
        - name: read
        - name: describe
        - name: describe_configs
      resource_names:
      - match: '*'
    - resource_type: group
      action: allow
      operations:
        - name: read
        - name: describe
      resource_names:
      - match: '*'
{% endkonnect_api_request %}
<!--vale on-->

## Configure kafkactl

Set up kafkactl with four contexts:
- `direct`: connects to the backend Kafka cluster directly, bypassing the gateway
- `producer`: uses the producer client certificate through the mTLS-protected listener
- `consumer`: uses the consumer client certificate through the mTLS-protected listener
- `no_cert`: connects to the gateway with TLS but without a client certificate, for testing mTLS rejection

<!--vale off-->
{% validation custom-command %}
command: |
  cat <<EOF > kafkactl.yaml
  contexts:
    direct:
      brokers:
        - localhost:9095
        - localhost:9096
        - localhost:9094
    producer:
      brokers:
        - localhost:19092
      tls:
        enabled: true
        ca: ./server.crt
        cert: ./producer.crt
        certKey: ./producer.key
        insecure: false
    consumer:
      brokers:
        - localhost:19092
      tls:
        enabled: true
        ca: ./server.crt
        cert: ./consumer.crt
        certKey: ./consumer.key
        insecure: false
    no_cert:
      brokers:
        - localhost:19092
      tls:
        enabled: true
        ca: ./server.crt
        insecure: false
  EOF
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

## Create a Kafka topic

Create a test topic using the `direct` context, which connects directly to the backend Kafka cluster:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context direct create topic my-test-topic
expected:
  message: "topic created: my-test-topic"
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

## Validate

### Produce with the producer client

Produce a message through the mTLS-protected listener using the `producer` context:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context producer produce my-test-topic --value="Hello from mTLS producer"
expected:
  message: "message produced"
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

### Consume with the consumer client

Consume the message using the `consumer` context:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context consumer consume my-test-topic --from-beginning --exit
expected:
  message: "Hello from mTLS producer"
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

You should see:
```sh
Hello from mTLS producer
```
{:.no-copy-code}

### Verify ACL enforcement

Verify that the consumer client cannot produce messages:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context consumer produce my-test-topic --value="This should fail"
expected:
  return_code: 1
render_output: false
{% endvalidation %}
<!--vale on-->

The operation fails because the `consumer-client` principal only has read access.

### Connect without a client certificate

Verify that the gateway rejects connections without a client certificate using the `no_cert` context, which has TLS enabled but does not present a client certificate:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context no_cert get topics
expected:
  return_code: 1
render_output: false
{% endvalidation %}
<!--vale on-->

The connection fails because `client_authentication.mode` is set to `required` and no client certificate was presented.
