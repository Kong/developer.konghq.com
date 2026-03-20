---
title: Set up {{site.event_gateway}} with Kong Identity OAuth
content_type: how_to
permalink: /event-gateway/kong-identity-oauth/
breadcrumbs:
  - /event-gateway/

products:
    - event-gateway

works_on:
    - konnect

tags:
    - event-gateway
    - kafka

description: "Learn how to secure Kafka traffic in {{site.event_gateway_short}} with Kong Identity."

tldr:
  q: "How do I secure Kafka traffic in {{site.event_gateway_short}} with Kong Identity?"
  a: |
    1. Create a Kong Identity auth server, scope, claim, and client.
    1. Create a {{site.event_gateway}} with a virtual cluster that can verify OAuth tokens from clients.
    1. Create an ACL policy to restrict access to a specific client.

tools:
    - konnect-api

prereqs:
  inline:
    - title: Install kafkactl
      position: before
      content: |
        Install [kafkactl](https://github.com/deviceinsight/kafkactl?tab=readme-ov-file#installation). You'll need it to interact with Kafka clusters.
        Version >= 5.17.0 is needed to support script driven OAuth token generation.

    - title: Start a local Kafka cluster
      position: before
      include_content: knep/docker-compose-start

cleanup:
  inline:
    - title: Clean up {{site.event_gateway}} resources
      include_content: cleanup/products/event-gateway
      icon_url: /assets/icons/gateway.svg

automated_tests: false
related_resources:
  - text: Event Gateway
    url: /event-gateway/
  - text: "Kong Identity"
    url: /kong-identity/
  - text: Dynamic claim templating
    url: /kong-identity/#dynamic-claim-templates
  - text: Event Gateway ACL policy
    url: /event-gateway/policies/acl/

min_version:
  event_gateway: '1.1.0'
---

## Create an auth server in Kong Identity

Before you can configure the authentication plugin, you must first create an auth server in Kong Identity. We recommend creating different auth servers for different environments or subsidiaries. The auth server name is unique per each organization and each {{site.konnect_short_name}} region.

Create an auth server using the [`/v1/auth-servers` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServer):

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "Appointments Dev"
  audience: "http://myhttpbin.dev"
  description: "Auth server for the Appointment dev environment"
extract_body:
  - name: 'id'
    variable: AUTH_SERVER_ID
  - name: 'issuer'
    variable: ISSUER_URL
capture:
    - variable: AUTH_SERVER_ID
      jq: '.id'
    - variable: ISSUER_URL
      jq: '.issuer'
{% endkonnect_api_request %}
<!--vale on-->

## Configure the auth server with scopes

Configure a scope in your auth server using the [`/v1/auth-servers/$AUTH_SERVER_ID/scopes` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServerScope):

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/scopes
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "my-scope"
  description: "Scope to test Kong Identity"
  default: false
  include_in_metadata: false
  enabled: true
extract_body:
  - name: 'id'
    variable: SCOPE_ID
capture:
    - variable: SCOPE_ID
      jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

## Configure the auth server with custom claims

Configure a custom claim to hold a topic prefix, `products`, using the [`/v1/auth-servers/$AUTH_SERVER_ID/claims` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServerClaim):

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/claims
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "topic_prefix"
  value: "products"
  include_in_token: true
  include_in_all_scopes: false
  include_in_scopes:
  - $SCOPE_ID
  enabled: true
{% endkonnect_api_request %}
<!--vale on-->

You can also configure dynamic custom claims with [dynamic claim templating](/kong-identity/#dynamic-claim-templates) to generate claims during runtime.

## Create a client in the auth server

The client is the machine-to-machine credential. In this tutorial, {{site.konnect_short_name}} will autogenerate the client ID and secret, but you can alternatively specify one yourself.

Configure the client using the [`/v1/auth-servers/$AUTH_SERVER_ID/clients` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServerClient):

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/clients
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: Client
  grant_types:
    - client_credentials
  allow_all_scopes: false
  allow_scopes:
    - $SCOPE_ID
  access_token_duration: 3600
  id_token_duration: 3600
  response_types:
    - id_token
    - token
extract_body:
  - name: 'client_secret'
    variable: CLIENT_SECRET
  - name: 'id'
    variable: CLIENT_ID
capture:
  - variable: CLIENT_SECRET
    jq: '.client_secret'
  - variable: CLIENT_ID
    jq: '.id'
{% endkonnect_api_request %}
<!--vale on-->

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
  insecure_allow_anonymous_virtual_cluster_auth: true
  authentication:
    type: anonymous
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
    acl_mode: enforce_on_gateway
    authentication:
    - type: anonymous
    - type: oauth_bearer
      mediation: terminate
      jwks:
        endpoint: $ISSUER_URL/.well-known/jwks

extract_body:
  - name: id
    variable: VIRTUAL_CLUSTER_ID
capture:
  - variable: VIRTUAL_CLUSTER_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

Notice that the cluster will accept both anonymous and OAuth authentication method. We'll later restrict access using ACLs.

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

## Create an ACL policy for the client using the token claims

Add an ACL policy for the client with an allow list for matched operations:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$VIRTUAL_CLUSTER_ID/cluster-policies
status_code: 201
method: POST
body:
  type: acls
  name: acl_policy
  config:
    rules:
    - resource_type: topic
      action: allow
      operations:
        - name: describe
        - name: describe_configs
        - name: read
        - name: write
      resource_names: '[context.auth.token.claims.topic_prefix + "*"]'
{% endkonnect_api_request %}
<!--vale on-->

This ACL policy grants full access to all topics with the prefix in the `topic_prefix` claim.

## Setup `kafkactl` to use OAuth

{:.warning}
> This step requires a `kafkactl` version >= 5.17.0. To check your version, run `kafkactl version`.
> <br><br>
> Note that this script is for demo purposes only and hard-codes client ID, client secret, and scope.
> For production, we recommend securing sensitive data.

`kafkactl` will generate tokens using a script. Let's create the script:

<!--vale off-->
{% validation custom-command %}
command: |
  cat <<EOF > get-oauth-token.sh
  #!/bin/bash
  curl -s --fail -X POST "$ISSUER_URL/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET" \
  -d "scope=my-scope" | jq -r '{"token": .access_token}'
  EOF
  chmod u+x get-oauth-token.sh
expected:
    return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

Next, create a `kafkactl` configuration with both non-authenticated and authenticated access:

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
    vc:
      brokers:
      - localhost:19092
    vc-oauth:
      sasl:
        enabled: true
        mechanism: oauth
        tokenprovider:
          plugin: generic
          options:
            script: ./get-oauth-token.sh
            args: []
      brokers:
      - localhost:19092
  EOF
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

## Validate

Run through the following commands to validate your configuration.

### Access topics with auth

Create a topic bypassing the gateway:

{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context direct create topic products-topic
expected:
  return_code: 0
  message: "topic created: products-topic"
render_output: false
{% endvalidation %}

List topics using an authenticated client:

{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context vc-oauth list topics
expected:
  return_code: 0
  message: |
    TOPIC              PARTITIONS     REPLICATION FACTOR
    products-topic     1              1
render_output: false
{% endvalidation %}

The output should look like this:

```shell
TOPIC           PARTITIONS     REPLICATION FACTOR
products-topic  1              1
```
{:.no-copy-code}

### Access topics without auth

Now try listing topics without auth:

{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context vc list topics
expected:
  return_code: 0
  message: |
    TOPIC     PARTITIONS     REPLICATION FACTOR
render_output: false
{% endvalidation %}

The output should be an empty list:

```shell
TOPIC     PARTITIONS     REPLICATION FACTOR
```
{:.no-copy-code}

As you can see, when using OAuth we can retrieve the topic. 
However, when using anonymous access, the topic isn't visible as this user doesn't have the appropriate ACLs.
