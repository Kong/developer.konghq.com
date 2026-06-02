---
title: Enrich Kafka SASL PLAIN connections with Kong Identity principal metadata
content_type: how_to
breadcrumbs:
  - /event-gateway/

permalink: /event-gateway/kong-identity-metadata-integration/

products:
    - event-gateway

works_on:
    - konnect

tags:
    - event-gateway
    - kafka

description: "Look up Kong Identity principal metadata from a SASL-authenticated Kafka connection and use it to drive {{site.event_gateway}} policies."

tldr:
  q: How do I use Kong Identity principal metadata in {{site.event_gateway_short}} policies?
  a: |
    1. Create a Kong Identity directory, principal with metadata, and a `custom` identity keyed by the SASL username.
    1. Configure a virtual cluster with `sasl_plain` `passthrough` authentication and `fetch_kong_identity_principal` pointing at the directory.
    1. Create a Modify Headers policy with a condition on `context.auth.principal.metadata`.
    1. Produce and consume a record to see the policy fire.

tools:
    - konnect-api

prereqs:
  skip_product: true
  inline:
    - title: Install kafkactl
      position: before
      include_content: knep/kafkactl
    - title: Kong Identity directory
      include_content: prereqs/kong-identity-directory
      icon_url: /assets/icons/kong-identity.svg

cleanup:
  inline:
    - title: Clean up {{site.event_gateway}} resources
      include_content: cleanup/products/event-gateway
      icon_url: /assets/icons/gateway.svg

related_resources:
  - text: Authenticate {{site.event_gateway}} connections to Kafka using SASL/PLAIN
    url: /event-gateway/configure-sasl-plain-backend-cluster-auth/
  - text: Modify Headers policy
    url: /event-gateway/policies/modify-headers/
  - text: "{{site.event_gateway_short}} expressions language"
    url: /event-gateway/expressions/
  - text: Backend clusters
    url: /event-gateway/entities/backend-cluster/

min_version:
  event-gateway: '1.2.0'

automated_tests: false
---

In this guide, you'll authenticate a Kafka client to a SASL-secured broker through {{site.event_gateway_short}}, look up the connecting principal in a Kong Identity directory by its SASL username, and use the principal's metadata to drive a [Modify Headers policy](/event-gateway/policies/modify-headers/).

{% mermaid %}
flowchart LR
    C[Kafka client]
    subgraph EG [" {{site.event_gateway_short}} "]
        VC[sasl_plain passthrough<br/>virtual cluster]
    end
    KI[(Kong Identity<br/>directory)]
    subgraph K [Kafka cluster]
        L["SASL_PLAINTEXT :9082"]
    end
    C -->|SASL/PLAIN<br/>user=john| VC
    VC -.->|lookup by sasl_username| KI
    KI -.->|principal metadata<br/>team=operators| VC
    VC -->|SASL/PLAIN passthrough| L
    VC -->|record with<br/>x-team header| C
{% endmermaid %}

## Start the secured Kafka cluster

Create the JAAS configuration file that defines the SASL/PLAIN credentials:

```bash
cat <<'EOF' > kafka_server_jaas.conf
KafkaServer {
    org.apache.kafka.common.security.plain.PlainLoginModule required
    username="eventgateway"
    password="eventgateway-secret"
    user_eventgateway="eventgateway-secret"
    user_john="john-secret";
};
EOF
```

The broker accepts two SASL/PLAIN users: `eventgateway` (used by {{site.event_gateway_short}} itself for broker discovery) and `john` (used by the Kafka client and matched against Kong Identity).

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

## Create a principal with team metadata

Create a principal in the directory and attach the `team` metadata. The Modify Headers policy will read this value at request time:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals
status_code: 201
method: POST
body:
  display_name: john
  description: Principal that maps to the john SASL user
  metadata:
    team: operators
extract_body:
  - name: id
    variable: PRINCIPAL_ID
capture:
  - variable: PRINCIPAL_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

## Create a custom identity for the SASL username

Create a `custom` identity that links the principal to the SASL username sent by the Kafka client. {{site.event_gateway_short}} will match the connecting username against the `sasl_username` key:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals/$PRINCIPAL_ID/identities
status_code: 201
method: POST
body:
  type: custom
  key: sasl_username
  value: john
{% endkonnect_api_request %}
<!--vale on-->

## Create the backend cluster

Create a [backend cluster](/event-gateway/entities/backend-cluster/) configured with the `eventgateway` SASL/PLAIN user. {{site.event_gateway_short}} uses these credentials for its own connection to the broker. Client connections pass through this configuration unchanged because of the virtual cluster's `passthrough` mediation, which you'll configure in the next step:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/backend-clusters
status_code: 201
method: POST
body:
  name: backend_cluster
  bootstrap_servers:
    - kafka1:9082
    - kafka2:9082
    - kafka3:9082
  authentication:
    type: sasl_plain
    username: eventgateway
    password: eventgateway-secret
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

## Create a virtual cluster

Create a [virtual cluster](/event-gateway/entities/virtual-cluster/) that accepts SASL/PLAIN connections, forwards them unchanged to the broker, and asks {{site.event_gateway_short}} to fetch the principal from the Kong Identity directory by matching the SASL username against the `sasl_username` key:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters
status_code: 201
method: POST
body:
  name: identity_vc
  destination:
    id: $BACKEND_CLUSTER_ID
  dns_label: identity-vc
  acl_mode: passthrough
  authentication:
    - type: sasl_plain
      mediation: passthrough
      fetch_kong_identity_principal:
        directory: kong-identity-directory
        fetch_by:
          key: sasl_username
        failure_mode: error
extract_body:
  - name: id
    variable: VIRTUAL_CLUSTER_ID
capture:
  - variable: VIRTUAL_CLUSTER_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

The `fetch_kong_identity_principal` block tells {{site.event_gateway_short}} to use the SASL username (in this case, `john`) as the lookup value against identities of key `sasl_username` in the directory. When a match is found, the parent principal's metadata is attached to `context.auth.principal.metadata` for the lifetime of the connection.

## Create a listener

Run the following command to create a new [listener](/event-gateway/entities/listener/):

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/listeners
status_code: 201
method: POST
body:
  name: identity_listener
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

## Create a listener policy

Add a [Forward to Virtual Cluster](/event-gateway/policies/forward-to-virtual-cluster/) policy that routes the listener to the virtual cluster:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/listeners/$LISTENER_ID/policies
status_code: 201
method: POST
body:
  type: forward_to_virtual_cluster
  name: forward_to_identity_vc
  config:
    type: port_mapping
    advertised_host: localhost
    destination:
      id: $VIRTUAL_CLUSTER_ID
{% endkonnect_api_request %}
<!--vale on-->

## Create the Modify Headers policy

Add a [Modify Headers](/event-gateway/policies/modify-headers/) policy that sets the `x-team` header on consumed records only when the principal's `team` metadata equals `operators`:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$VIRTUAL_CLUSTER_ID/consume-policies
status_code: 201
method: POST
body:
  type: modify_headers
  name: tag-operators-team
  condition: context.auth.principal.metadata.team == "operators"
  config:
    actions:
      - op: set
        key: x-team
        value: operators
{% endkonnect_api_request %}
<!--vale on-->

## Configure kafkactl

Create a `kafkactl.yaml` config file with a `direct` context that talks to the broker's PLAINTEXT listener, and a `vc` context that connects to the virtual cluster using SASL/PLAIN:

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
    vc:
      brokers:
        - localhost:19092
      sasl:
        enabled: true
        username: john
        password: john-secret
  EOF
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

## Create a topic

Create the `orders` topic using the `direct` context:

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

## Validate

Produce a record through the virtual cluster:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context vc produce orders --value="test-message"
expected:
  return_code: 0
  message: "message produced (partition=0	offset=0)"
render_output: false
{% endvalidation %}
<!--vale on-->

Consume the record back through the virtual cluster with `--print-headers` so you can see the header added by the Modify Headers policy:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context vc consume orders --print-headers --from-beginning --exit
expected:
  return_code: 0
  message: "x-team:operators#test-message"
render_output: false
{% endvalidation %}
<!--vale on-->

The output should contain the `x-team` header:

```shell
x-team:operators#test-message
```
{:.no-copy-code}

{{site.event_gateway_short}} authenticated the client with the broker by passing the SASL/PLAIN credentials straight through, looked up the `john` SASL username in the Kong Identity directory, attached the principal's metadata to the connection, and applied the Modify Headers policy because `context.auth.principal.metadata.team` was `operators`.

The same principal lookup strategy can be used with all other authentication methods (SASL/SCRAM, SASL/OAUTHBEARER, client certificates). 
