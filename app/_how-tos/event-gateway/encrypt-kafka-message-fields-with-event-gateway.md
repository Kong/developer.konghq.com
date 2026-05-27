---
title: Encrypt and decrypt Kafka fields in message values with {{site.event_gateway}}
permalink: /event-gateway/encrypt-kafka-message-fields-with-event-gateway/
content_type: how_to
breadcrumbs:
  - /event-gateway/

products:
    - event-gateway

works_on:
    - konnect

tags:
    - kafka

description: Use this tutorial to encrypt and decrypt Kafka fields in Kafka message values with {{site.event_gateway}} using a static key.

tldr:
  q: How can I encrypt and decrypt Kafka specific fields of message values with {{site.event_gateway}}?
  a: |
    Generate a key and create a [static key](/event-gateway/entities/static-key/) entity, then create [field encryption](/event-gateway/policies/encrypt-fields/) and [field decryption](/event-gateway/policies/decrypt-fields/) policies to enable message encryption and decryption.

tools:
    - konnect-api

prereqs:
  inline:
    - title: Install kafkactl
      position: before
      content: |
        Install [kafkactl](https://github.com/deviceinsight/kafkactl?tab=readme-ov-file#installation). You'll need it to interact with Kafka clusters.

    - title: Start a local Kafka cluster
      position: before
      include_content: knep/docker-compose-start

cleanup:
  inline:
    - title: Clean up {{site.event_gateway}} resources
      include_content: cleanup/products/event-gateway
      icon_url: /assets/icons/gateway.svg

related_resources:
  - text: "{{site.event_gateway_short}} Control Plane API"
    url: /api/konnect/event-gateway/
  - text: Event Gateway
    url: /event-gateway/
  - text: Static keys
    url: /event-gateway/entities/static-key/
  - text: Encrypt fields policy
    url: /event-gateway/policies/encrypt-fields/
  - text: Decrypt fields policy
    url: /event-gateway/policies/decrypt-fields/
---


## Configure a Kafka cluster

Now that we've configured the proxy, let's make sure the Kafka cluster is ready.

In your local environment, set up the `kafkactl.yaml` config file for your Kafka cluster:

{% validation custom-command %}
command: |
  cat <<EOF > kafkactl.yaml
  contexts:
    direct:
      brokers:
        - localhost:9095
        - localhost:9096
        - localhost:9094
    vc:
      brokers:
        - localhost:19092
  EOF
expected:
  return_code: 0
render_output: false
{% endvalidation %}

## Add a backend cluster

Run the following command to create a new backend cluster:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/backend-clusters
status_code: 201
method: POST
body:
  name: default_backend_cluster
  bootstrap_servers:
    - kafka1:9092
    - kafka2:9092
    - kafka3:9092
  authentication:
    type: anonymous
  insecure_allow_anonymous_virtual_cluster_auth: true
  tls:
    enabled: false
extract_body:
  - name: id
    variable: BACKEND_CLUSTER_ID
capture:
  - variable: BACKEND_CLUSTER_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

## Add a virtual cluster

Run the following command to create a new virtual cluster associated with our backend cluster:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters
status_code: 201
method: POST
body:
  name: example_virtual_cluster
  destination:
    id: $BACKEND_CLUSTER_ID
  dns_label: vcluster-1
  authentication:
    - type: anonymous
  acl_mode: passthrough
extract_body:
  - name: id
    variable: VIRTUAL_CLUSTER_ID
capture:
  - variable: VIRTUAL_CLUSTER_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->


## Add a listener

A [listener](/event-gateway/entities/listener/) represents hostname-port or IP-port combinations that connect to TCP sockets.
In this example, we're going to use port mapping, so we need to expose a range of ports.

Run the following command to create a new listener:
<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/listeners
status_code: 201
method: POST
body:
  name: example_listener
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

## Add a listener policy

The listener needs a policy to tell it how to process requests and what to do with them.
In this example, we're going to use the [Forward to Virtual Cluster](/event-gateway/policies/forward-to-virtual-cluster/) policy,
which will forward requests based on a defined mapping to our virtual cluster.

Run the following command to add the listener policy:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/listeners/$LISTENER_ID/policies
status_code: 201
method: POST
body:
  type: forward_to_virtual_cluster
  name: forward
  config:
    type: port_mapping
    advertised_host: localhost
    destination:
      id: $VIRTUAL_CLUSTER_ID
{% endkonnect_api_request %}
<!--vale on-->

For demo purposes, we're using port mapping, which assigns each Kafka broker to a dedicated port on the {{site.event_gateway_short}}.
In production, we recommend using [SNI routing](/event-gateway/architecture/#hostname-mapping) instead.

## Generate a key

Use OpenSSL to generate the key that will be used to encrypt and decrypt messages:

<!--vale off-->
{% env_variables %}
MY_KEY: $(openssl rand -base64 32)
{% endenv_variables %}
<!--vale on-->

## Add a static key

Run the following command to create a new [static key](/event-gateway/entities/static-key/) named `my-key` with the key we generated:
<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/static-keys
status_code: 201
method: POST
body:
    name: my-key
    value: $MY_KEY
{% endkonnect_api_request %}
<!--vale on-->

## Create a Schema Validation produce policy

Create a [Schema Validation policy](/event-gateway/policies/schema-validation-produce/) that validates that all produced values are JSON encoded.

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$VIRTUAL_CLUSTER_ID/produce-policies
status_code: 201
method: POST
body:
  type: schema_validation
  name: produce_validate_json
  config:
    type: json
    value_validation_action: reject
extract_body:
  - name: id
    variable: PRODUCE_SCHEMA_VALIDATION_ID
capture:
  - variable: PRODUCE_SCHEMA_VALIDATION_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

The `value_validation_action: reject` setting ensures that the entire batch containing an invalid message is rejected, and the producer receives an error. Alternatively, you can use `mark`, which passes the message to the broker but adds a `kong/sverr-value` header to flag it as invalid.

## Add a field encryption policy

Use the following command to create a [field encryption policy](/event-gateway/policies/encrypt-fields/) to enable encryption of one field in the JSON value:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$VIRTUAL_CLUSTER_ID/produce-policies
status_code: 201
method: POST
body:
  name: encrypt-fields-static-key
  parent_policy_id: $PRODUCE_SCHEMA_VALIDATION_ID
  type: encrypt_fields
  config:
    failure_mode: reject
    encrypt_fields:
      - paths:
        - match: "personal.ssn"
        encryption_key:
          type: static
          key:
            name: my-key
{% endkonnect_api_request %}
<!--vale on-->

## Create a Schema Validation consume policy

Create a [Schema Validation policy](/event-gateway/policies/schema-validation-consume/) that validates that all consumed values are JSON encoded.

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$VIRTUAL_CLUSTER_ID/consume-policies
status_code: 201
method: POST
body:
  type: schema_validation
  name: consume_validate_json
  config:
    type: json
    value_validation_action: mark
extract_body:
  - name: id
    variable: CONSUME_SCHEMA_VALIDATION_ID
capture:
  - variable: CONSUME_SCHEMA_VALIDATION_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

The `value_validation_action: mark` passes the message to the broker but adds a `kong/sverr-value` header to flag it as invalid.

## Add a field decryption policy

Use the following command to create a [field decryption policy](/event-gateway/policies/decrypt-fields/) to enable decryption of one field in the JSON value:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$VIRTUAL_CLUSTER_ID/consume-policies
status_code: 201
method: POST
body:
  name: decrypt-fields-static-key
  parent_policy_id: $CONSUME_SCHEMA_VALIDATION_ID
  type: decrypt_fields
  config:
    failure_mode: error
    key_sources:
      - type: static
    decrypt_fields:
      paths:
        - match: "personal.ssn"
{% endkonnect_api_request %}
<!--vale on-->

## Validate

Let's check that the encryption/decryption works.
First, create a topic using the `direct` context, which is a direct connection to our Kafka cluster:

{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context direct create topic my-test-topic
expected:
  message: "topic created: my-test-topic"
  return_code: 0
render_output: false
{% endvalidation %}

Produce a message using the `vc` context which should encrypt the message:
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context vc produce my-test-topic --value='{"personal": {"ssn": "100-00-00001"}}'
expected:
  message: "message produced (partition=0	offset=0)"
  return_code: 0
render_output: false
{% endvalidation %}


You should see the following response:
```shell
message produced (partition=0	offset=0)
```
{:.no-copy-code}

Now let's verify that the message was encrypted, by consuming the message directly.

{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context direct consume my-test-topic --exit --output json --from-beginning --print-headers
expected:
  message: '"kong/enc": "\u0000\u0004\u0000-static://'
  return_code: 0
render_output: false
{% endvalidation %}

You should see the following response:
```shell
{
	"Partition": 0,
	"Offset": 0,
	"Headers": {
		"kong/enc": "\u0000\u0004\u0000-static://<static-key-id>"
	},
	"Value": "{\"personal\":{\"ssn\":\"AHry69Jl4oJzafOlu/xOjVa37hpfYTAVXoAolj94NoBQSKz7dkEF/gg=\"}}"
}
```
{:.no-copy-code}

The field encryption policy appends a `kong/enc` header to each message. This header identifies the encryption key by its ID.

Now let's verify that the field decryption policy works by consuming the message through the virtual cluster.

{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context vc consume my-test-topic --from-beginning  --exit
expected:
  message: '{"personal": {"ssn": "100-00-00001"}}'
  return_code: 0
render_output: false
{% endvalidation %}

The output should look like:

```shell
{"personal": {"ssn": "100-00-00001"}}
```
{:.no-copy-code}

