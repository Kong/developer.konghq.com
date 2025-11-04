---
title: Set up {{site.event_gateway}} with Kong Identity OAuth
content_type: how_to
breadcrumbs:
  - /event-gateway/

products:
    - event-gateway

works_on:
    - konnect

tags:
    - event-gateway
    - kafka

description: ""

tldr: 
  q: ""
  a: | 
    ""

tools:
    - konnect-api
  
prereqs:
  skip_product: true
  inline:
    - title: Terraform
      include_content: prereqs/terraform
      icon_url: /assets/icons/terraform.svg
    - title: "{{site.konnect_product_name}}"
      include_content: prereqs/products/konnect-terraform
      icon_url: /assets/icons/gateway.svg
    - title: Install kafkactl
      content: |
        Install [kafkactl](https://github.com/deviceinsight/kafkactl?tab=readme-ov-file#installation). You'll need it to interact with Kafka clusters. 
    - title: Start a local Kafka cluster
      include_content: knep/docker-compose-start

automated_tests: false
related_resources:
  - text: Event Gateway
    url: /event-gateway/

---

## Create an auth server in Kong Identity

Before you can configure the authentication plugin, you must first create an auth server in Kong Identity. We recommend creating different auth servers for different environments or subsidiaries. The auth server name is unique per each organization and each {{site.konnect_short_name}} region.

Create an auth server using the [`/v1/auth-servers` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServer):

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers
status_code: 200
method: POST
body:
  name: "Kafka Dev"
  audience: "http://kafka.dev"
  description: "Auth server for the Kafka dev environment"
{% endkonnect_api_request %}

Export the auth server ID and issuer URL:
```sh
export AUTH_SERVER_ID='YOUR-AUTH-SERVER-ID'
export ISSUER_URL='YOUR-ISSUER-URL'
```

## Configure the auth server with scopes 

Configure a scope in your auth server using the [`/v1/auth-servers/$AUTH_SERVER_ID/scopes` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServerScope):

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/scopes 
status_code: 200
method: POST
body:
  name: "kafka"
  description: "Scope to test Kong Identity"
  default: false
  include_in_metadata: false
  enabled: true
{% endkonnect_api_request %}
<!--vale on-->

Export your scope ID:
```sh
export SCOPE_ID='YOUR-SCOPE-ID'
```

## Create a client in the auth server

The client is the machine-to-machine credential. In this tutorial, {{site.konnect_short_name}} will autogenerate the client ID and secret, but you can alternatively specify one yourself. 

Configure the client using the [`/v1/auth-servers/$AUTH_SERVER_ID/clients` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServerClient):

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/clients
status_code: 201
method: POST
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
{% endkonnect_api_request %}
<!--vale on-->

Export your client secret and client ID:
```sh
export CLIENT_SECRET='YOUR-CLIENT-SECRET'
export CLIENT_ID='YOUR-CLIENT-ID'
```

## Deploy Event Gateway with Terraform

Now that Kong Identity is set up, you can deploy the Event Gateway using Terraform.

The Terraform configuration creates the following resources:

1. **Event Gateway** (`konnect_event_gateway.event_gateway_terraform`)
   - Main Event Gateway instance

2. **Backend Cluster** (`konnect_event_gateway_backend_cluster.backend_cluster`)
   - Connects to Confluent Cloud
   - SASL_PLAIN authentication with TLS

3. **Virtual Cluster** (`konnect_event_gateway_virtual_cluster.virtual_cluster`)
   - Namespace with `my-` prefix
   - SASL_PLAIN and OAuth Bearer authentication
   - ACL enforcement mode

4. **Listener** (`konnect_event_gateway_listener.listener`)
   - Listens on `0.0.0.0:19092-19192`

5. **Forwarding Policy** (`konnect_event_gateway_listener_policy_forward_to_virtual_cluster.forward_to_vcluster`)
   - Routes traffic to virtual cluster

```hcl
echo '
resource "konnect_event_gateway" "event_gateway_terraform" {
  provider = konnect-beta
  name     = event_gateway_terraform
}
' >> main.tf
```

```hcl
echo '
resource "konnect_event_gateway_backend_cluster" "backend_cluster" {
  provider    = konnect-beta
  name        = "local-backend-cluster"
  description = "local kafka cluster (PLAINTEXT)"
  gateway_id  = konnect_event_gateway.event_gateway_terraform.id

  authentication = {
    type = "anonymous"
  }

  bootstrap_servers = [
    "kafka1:9092",
    "kafka2:9092",
    "kafka3:9092",
  ]

  tls = {
    enabled = false
  }

  insecure_allow_anonymous_virtual_cluster_auth = false

  depends_on = [konnect_event_gateway.event_gateway_terraform]
}
' >> main.tf
```

```hcl
echo '
resource "konnect_event_gateway_virtual_cluster" "virtual_cluster" {
  provider    = konnect-beta
  name        = "virtual-cluster"
  description = "team virtual cluster"
  gateway_id  = konnect_event_gateway.event_gateway_terraform.id

  destination = {
    id = konnect_event_gateway_backend_cluster.backend_cluster.id
  }

  acl_mode  = "enforce_on_gateway"
  dns_label = "vcluster"

  namespace = {
    prefix = "my-"
    mode   = "hide_prefix"
    additional = {
      consumer_groups = [{}]
      topics = [{
        exact_list = {
          conflict  = "warn"
          exact_list = [{
            backend = "extra_topic"
          }]
        }
      }]
    }
  }

  authentication = [{
    oauth_bearer = {
      mediation = "terminate"
      jwks = {
        endpoint = "https://YOUR-ISSUER-HERE.us.identity.konghq.com/auth/.well-known/jwks"
        timeout  = "1s"
      }
    }
  }]

  depends_on = [
    konnect_event_gateway.event_gateway_terraform,
    konnect_event_gateway_backend_cluster.backend_cluster
  ]
}
' >> main.tf
```

```hcl
echo '
resource "konnect_event_gateway_listener" "listener" {
  provider    = konnect-beta
  name        = "localhost-listener"
  description = "localhost listener"
  gateway_id  = konnect_event_gateway.event_gateway_terraform.id

  addresses = ["0.0.0.0"]
  ports     = ["19092-19192"]

  depends_on = [konnect_event_gateway.event_gateway_terraform]
}
' >> main.tf
```

```hcl
echo '
resource "konnect_event_gateway_listener_policy_forward_to_virtual_cluster" "forward_to_vcluster" {
  provider                  = konnect-beta
  name                      = "forward-to-vcluster"
  description               = "forward to vcluster policy"
  gateway_id                = konnect_event_gateway.event_gateway_terraform.id
  event_gateway_listener_id = konnect_event_gateway_listener.listener.id

  config = {
    port_mapping = {
      advertised_host = "localhost"
      destination = {
        virtual_cluster_reference_by_id = {
          id = konnect_event_gateway_virtual_cluster.virtual_cluster.id
        }
      }
    }
  }

  depends_on = [
    konnect_event_gateway.event_gateway_terraform,
    konnect_event_gateway_virtual_cluster.virtual_cluster
  ]
}
' >> main.tf
```

Add ACL policy for user1:
```hcl
echo '
resource "konnect_event_gateway_cluster_policy_acls" "acl_topic_policy_producer" {
  provider           = konnect-beta
  name               = "acl_topic_policy_producer"
  description        = "Producer client: full topic access"
  gateway_id         = konnect_event_gateway.event_gateway_terraform.id
  virtual_cluster_id = konnect_event_gateway_virtual_cluster.virtual_cluster.id

  # Replace with the actual client id that gets the token
  condition = "context.auth.claims.client_id == '${CLIENT_ID}'"

  config = {
    rules = [
      {
        action = "allow"
        operations = [
          { name = "describe" },
          { name = "read" },
          { name = "write" }
        ]
        resource_type = "topic"
        resource_names = [{ match = "*" }]
      }
    ]
  }
}
' >> main.tf
```

Add ACL policy for user2:
```hcl
echo '
resource "konnect_event_gateway_cluster_policy_acls" "acl_topic_policy_reader" {
  provider           = konnect-beta
  name               = "acl_topic_policy_reader"
  description        = "Reader client: describe + read"
  gateway_id         = konnect_event_gateway.event_gateway_terraform.id
  virtual_cluster_id = konnect_event_gateway_virtual_cluster.virtual_cluster.id

  condition = "context.auth.claims.client_id == reader-app"

  config = {
    rules = [
      {
        action         = "allow"
        operations     = [{ name = "describe" }]
        resource_type  = "topic"
        resource_names = [
          { match = "topic" },
          { match = "topic-encrypted" },
          { match = "extra_topic" }
        ]
      },
      {
        action         = "allow"
        operations     = [{ name = "read" }]
        resource_type  = "topic"
        resource_names = [{ match = "topic" }]
      }
    ]
  }
}
' >> main.tf
```

## Initialize and Apply Terraform

```sh
terraform init
terraform plan
terraform apply
```

This will create:
- Event Gateway instance
- Backend cluster connection to Confluent Cloud
- Virtual cluster with namespace configuration
- ACL policies for user1 and user2
- Skip record policy for filtering
- Listener on localhost:19092-19192
- Forwarding policy to virtual cluster

## Generate an Access Token

The Gateway Service requires an access token from the client to access the Service. Generate a token for the client by making a call to the issuer URL:

```sh
curl -X POST "$ISSUER_URL/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET" \
  -d "scope=kafka"
```

Export your access token:

```sh
export ACCESS_TOKEN='YOUR-ACCESS-TOKEN'
```

## Connect with OAuth Bearer Token

```sh
kafka-console-consumer --bootstrap-server localhost:19092 \
  --topic my-test-topic \
  --consumer-property security.protocol=SASL_PLAINTEXT \
  --consumer-property sasl.mechanism=OAUTHBEARER \
  --consumer-property "sasl.jaas.config=org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginModule required oauth.access.token=\"$ACCESS_TOKEN\";" \
  --consumer-property sasl.login.callback.handler.class=org.apache.kafka.common.security.oauthbearer.secured.OAuthBearerLoginCallbackHandler
```


