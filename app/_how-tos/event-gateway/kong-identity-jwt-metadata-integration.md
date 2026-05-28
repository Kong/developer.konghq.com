---
title: Enrich Kafka OAuth connections with Kong Identity principal metadata
content_type: how_to
breadcrumbs:
  - /event-gateway/

permalink: /event-gateway/kong-identity-jwt-metadata-integration/

products:
    - event-gateway

works_on:
    - konnect

tags:
    - event-gateway
    - kafka

description: "Look up Kong Identity principal metadata from a JWT-authenticated Kafka connection and use it to drive {{site.event_gateway}} policies."

tldr:
  q: How do I use Kong Identity principal metadata in {{site.event_gateway_short}} policies for JWT-authenticated clients?
  a: |
    1. Create a Kong Identity auth server, scope, and client.
    1. Create a Kong Identity directory, principal with metadata, and an `oidc` identity that matches the JWT's `iss` and `sub`.
    1. Configure a virtual cluster with `oauth_bearer` authentication and `fetch_kong_identity_principal` pointing at the directory.
    1. Create a Modify Headers policy with a condition on `context.auth.principal.metadata`.
    1. Produce and consume a record to see the policy fire.

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

related_resources:
  - text: Set up {{site.event_gateway}} with Kong Identity OAuth
    url: /event-gateway/kong-identity-oauth/
  - text: Enrich Kafka connections with Kong Identity principal metadata
    url: /event-gateway/kong-identity-metadata-integration/
  - text: Modify Headers policy
    url: /event-gateway/policies/modify-headers/
  - text: "{{site.event_gateway_short}} expressions language"
    url: /event-gateway/expressions/

min_version:
  event-gateway: '1.2.0'

automated_tests: false
---

In this guide, you'll authenticate a Kafka client to {{site.event_gateway_short}} with a JWT issued by a Kong Identity auth server, look up the connecting principal in a Kong Identity directory by the token's issuer and subject, and use the principal's metadata to drive a Modify Headers policy.

For `oauth_bearer` authentication, {{site.event_gateway_short}} always looks up the Kong Identity identity by matching the JWT's `iss` and `sub` claims against an `oidc` identity in the directory. No extra lookup-key configuration is needed.

{% mermaid %}
flowchart LR
    C[Kafka client]
    subgraph EG [" {{site.event_gateway_short}} "]
        VC[oauth_bearer<br/>virtual cluster]
    end
    KI[(Kong Identity<br/>directory)]
    subgraph K [Kafka cluster]
        L["PLAINTEXT :9092"]
    end
    C -->|SASL/OAUTHBEARER<br/>JWT| VC
    VC -.->|lookup by iss + sub| KI
    KI -.->|principal metadata<br/>team=operators| VC
    VC -->|forward request| L
    VC -->|record with<br/>x-team header| C
{% endmermaid %}

## Create an auth server in Kong Identity

Create an auth server using the [`/v1/auth-servers` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServer):

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "Event Gateway Auth"
  audience: "http://event-gateway"
  description: "Auth server for Event Gateway"
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

Configure a scope using the [`/v1/auth-servers/$AUTH_SERVER_ID/scopes` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServerScope):

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/scopes
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "kafka"
  description: "Scope for Kafka access"
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

## Create a client in the auth server

The client is the machine-to-machine credential. {{site.konnect_short_name}} autogenerates the client ID and secret. Configure the client using the [`/v1/auth-servers/$AUTH_SERVER_ID/clients` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServerClient):

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/clients
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: kafka-client
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

## Create a Kong Identity directory

A directory groups principals around an organizational boundary. Create one to hold the principals for this guide:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories
status_code: 201
method: POST
body:
  name: event-gateway-directory
  description: Directory for Event Gateway principals
  allow_all_control_planes: true
extract_body:
  - name: id
    variable: DIRECTORY_ID
capture:
  - variable: DIRECTORY_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

## Create a principal with team metadata

Create a principal in the directory and attach the `team` metadata. The Modify Headers policy will read this value at request time:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals
status_code: 201
method: POST
body:
  display_name: john
  description: Principal for the kafka-client OAuth client
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

## Create an OIDC identity for the JWT subject

Create an `oidc` identity that links the principal to the JWT issued by the auth server. {{site.event_gateway_short}} will match the JWT's `iss` against `issuer` and the JWT's `sub` against the configured claim:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals/$PRINCIPAL_ID/identities
status_code: 201
method: POST
body:
  type: oidc
  issuer: $ISSUER_URL
  claim:
    name: sub
    value: $CLIENT_ID
{% endkonnect_api_request %}
<!--vale on-->

For the `client_credentials` grant, Kong Identity sets the JWT `sub` claim to the client ID, so the identity's `claim.value` is the `CLIENT_ID` captured earlier.

## Create the backend cluster

Create a [backend cluster](/event-gateway/entities/backend-cluster/) pointing at the local Kafka brokers:

<!--vale off-->
{% include knep/create-backend-cluster.md insecure=true %}
<!--vale on-->

## Create a virtual cluster

Create a [virtual cluster](/event-gateway/entities/virtual-cluster/) that terminates `oauth_bearer` authentication and fetches the principal from the Kong Identity directory:

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
    - type: oauth_bearer
      mediation: terminate
      jwks:
        endpoint: $ISSUER_URL/.well-known/jwks
      fetch_kong_identity_principal:
        directory: event-gateway-directory
        failure_mode: error
extract_body:
  - name: id
    variable: VIRTUAL_CLUSTER_ID
capture:
  - variable: VIRTUAL_CLUSTER_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

For `oauth_bearer` authentication, the `fetch_kong_identity_principal` block doesn't need a `fetch_by` field: the principal is always looked up by the JWT's `iss` and `sub` claims.

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

{:.warning}
> This step requires a `kafkactl` version >= 5.17.0. To check your version, run `kafkactl version`.
> <br><br>
> Note that this script is for demo purposes only and hard-codes the client ID, client secret, and scope.
> For production, we recommend securing sensitive data.

`kafkactl` generates tokens using a script. Create the script:

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
  -d "scope=kafka" | jq -r '{"token": .access_token}'
  EOF
  chmod u+x get-oauth-token.sh
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

Create the `kafkactl.yaml` configuration:

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

{{site.event_gateway_short}} validated the JWT against the auth server's JWKS, looked up the principal in the `event-gateway-directory` Kong Identity directory by matching the token's `iss` and `sub` against the `oidc` identity, attached the principal's metadata to the connection, and applied the Modify Headers policy because `context.auth.principal.metadata.team` was `operators`.
