---
title: Set up {{site.event_gateway}} with Kong Identity OAuth
content_type: how_to
breadcrumbs:
  - /event-gateway/
beta: true
products:
    - event-gateway

works_on:
    - konnect

tags:
    - event-gateway
    - kafka

description: "Learn how to secure Kafka traffic in Event Gateway with Kong Identity."

tldr: 
  q: "How do I secure Kafka traffic in Event Gateway with Kong Identity?"
  a: | 
    "Create an auth server (`konnect_auth_server`), scope (`konnect_auth_server_scopes`), and clients (`konnect_auth_server_clients`) resources with Terraform. Then, create a Event Gateway with ACL (`konnect_event_gateway_virtual_cluster`) and record filtering policies. Each Kafka client authenticates with an access token from Kong Identity, and the Event Gateway enforces topic-level access based on the token’s `client_id` claim."

tools:
    - terraform
  
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

```hcl
echo '
resource "konnect_auth_server" "kafka_auth_server" {
  provider    = konnect-beta
  name        = "Kafka Dev"
  audience    = "http://kafka.dev"
  description = "Auth server for the Kafka dev environment"
}
' >> main.tf
```

## Configure the auth server with scopes 

Configure a scope in your auth server:

```hcl
echo '
resource "konnect_auth_server_scopes" "kafka_scope" {
  provider            = konnect-beta
  auth_server_id      = konnect_auth_server.kafka_auth_server.id
  name                = "kafka"
  description         = "Scope to test Kong Identity"
  default             = false
  include_in_metadata = false
  enabled             = true

  depends_on = [konnect_auth_server.kafka_auth_server]
}
' >> main.tf
```

## Create clients in the auth server

The client is the machine-to-machine credential. In this tutorial, {{site.konnect_short_name}} will autogenerate the client ID and secret, but you can alternatively specify one yourself. 

Configure Client 1:

```hcl
echo '
resource "konnect_auth_server_clients" "kafka_client_1" {
  provider              = konnect-beta
  auth_server_id        = konnect_auth_server.kafka_auth_server.id
  name                  = "Client1"
  grant_types           = ["client_credentials"]
  allow_all_scopes      = false
  allow_scopes          = [konnect_auth_server_scopes.kafka_scope.id]
  access_token_duration = 3600
  id_token_duration     = 3600
  response_types        = ["id_token", "token"]

  depends_on = [konnect_auth_server.kafka_auth_server]
}
' >> main.tf
```

Configure Client 2:

```hcl
echo '
resource "konnect_auth_server_clients" "kafka_client_2" {
  provider              = konnect-beta
  auth_server_id        = konnect_auth_server.kafka_auth_server.id
  name                  = "Client2"
  grant_types           = ["client_credentials"]
  allow_all_scopes      = false
  allow_scopes          = [konnect_auth_server_scopes.kafka_scope.id]
  access_token_duration = 3600
  id_token_duration     = 3600
  response_types        = ["id_token", "token"]

  depends_on = [konnect_auth_server.kafka_auth_server]
}
' >> main.tf
```

## Deploy Event Gateway with Terraform

Now that Kong Identity is set up, you can deploy the Event Gateway using Terraform:

```hcl
echo '
resource "konnect_event_gateway" "event_gateway_terraform" {
  provider = konnect-beta
  name     = "event_gateway_terraform"

  depends_on = [
    konnect_auth_server.kafka_auth_server,
    konnect_auth_server_scopes.kafka_scope
  ]
}
' >> main.tf
```

## Create the backend cluster

Create the backend cluster that connects to Kafka:

```hcl
echo '
resource "konnect_event_gateway_backend_cluster" "backend_cluster" {
  provider    = konnect-beta
  name        = "local-backend-cluster"
  description = "local kafka cluster (PLAINTEXT)"
  gateway_id  = konnect_event_gateway.event_gateway_terraform.id

  authentication = {
    anonymous = {}
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

## Create the virtual cluster

Configure the virtual cluster that enforces ACL and has a namespace with `my-` prefix:

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

  acl_mode = "enforce_on_gateway"
  dns_label = "vcluster"

  namespace = {
    prefix = "my-"
    mode   = "hide_prefix"
    additional = {
      consumer_groups = [{}]
      topics = [{
        exact_list = {
          conflict = "warn"
          exact_list = [{
            backend = "extra_topic"
          }]
        }
      }]
    }
  }

  authentication = [
    {
      oauth_bearer = {
        mediation = "terminate"
        jwks = {
          endpoint = "${konnect_auth_server.kafka_auth_server.issuer}/.well-known/jwks"
          timeout  = "1s"
        }
      }
    }
  ]

  depends_on = [konnect_event_gateway.event_gateway_terraform, konnect_event_gateway_backend_cluster.backend_cluster]
}
' >> main.tf
```

## Create a listener

Configure a listener that listens on `0.0.0.0:19092-19192`:

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

## Create the forwarding policy

Configure the forwarding policy to route traffic to the virtual cluster:

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

  depends_on = [konnect_event_gateway.event_gateway_terraform, konnect_event_gateway_virtual_cluster.virtual_cluster]
}
' >> main.tf
```

## Create ACL policies for clients

Add the ACL policy for Client 1:

```hcl
cat >> main.tf <<'HCL'
resource "konnect_event_gateway_cluster_policy_acls" "acl_topic_policy_u1" {
  provider           = konnect-beta
  name               = "acl_topic_policy1"
  description        = "ACL policy for ensuring access to topics based on principals"
  gateway_id         = konnect_event_gateway.event_gateway_terraform.id
  virtual_cluster_id = konnect_event_gateway_virtual_cluster.virtual_cluster.id

  condition = "context.auth.principal.name == '${konnect_auth_server_clients.kafka_client_1.id}'"
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
        resource_names = [{
          match = "*"
        }]
      }
    ]
  }
}
HCL
```

Add the ACL policy for Client 2:

```hcl
cat >> main.tf <<'HCL'
resource "konnect_event_gateway_cluster_policy_acls" "acl_topic_policy_u2" {
  provider           = konnect-beta
  name               = "acl_topic_policy2"
  description        = "ACL policy for ensuring access to topics based on principals"
  gateway_id         = konnect_event_gateway.event_gateway_terraform.id
  virtual_cluster_id = konnect_event_gateway_virtual_cluster.virtual_cluster.id

  condition = "context.auth.principal.name == '${konnect_auth_server_clients.kafka_client_2.id}'"
  config = {
    rules = [
      {
        action = "allow"
        operations = [
          { name = "describe" }
        ]
        resource_type = "topic"
        resource_names = [{
          match = "topic"
          }, {
          match = "topic-encrypted"
          }, {
          match = "extra_topic"
        }]
        }, {
        action = "allow"
        operations = [
          { name = "read" }
        ]
        resource_type = "topic"
        resource_names = [{
          match = "topic"
        }]
      }
    ]
  }
}
HCL
```

Add skip record policy on orders topic based on header and principal:

```hcl
cat >> main.tf <<'HCL'
resource "konnect_event_gateway_consume_policy_skip_record" "skip_record" {
  provider           = konnect-beta
  name               = "skip_records"
  description        = "skip records"
  gateway_id         = konnect_event_gateway.event_gateway_terraform.id
  virtual_cluster_id = konnect_event_gateway_virtual_cluster.virtual_cluster.id

  condition = "record.headers['internal'] == 'true' && context.auth.principal.name != '${konnect_auth_server_clients.kafka_client_1.id}'"
}
HCL
```

## Create outputs 

Create an `outputs.tf` file with your token endpoint, client IDs, and client secrets:

```hcl
echo '
output "token_endpoint" {
  value = "${konnect_auth_server.kafka_auth_server.issuer}/oauth/token"
}

output "client_id_1" {
  value = konnect_auth_server_clients.kafka_client_1.id
}

output "client_secret_1" {
  value     = konnect_auth_server_clients.kafka_client_1.client_secret
  sensitive = true
}

output "client_id_2" {
  value = konnect_auth_server_clients.kafka_client_2.id
}

output "client_secret_2" {
  value     = konnect_auth_server_clients.kafka_client_2.client_secret
  sensitive = true
}
' >> outputs.tf
```

## Create the resources

Create all of the defined resources using Terraform:

```bash
terraform apply -auto-approve
```

You will see five resources created:

```text
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.
```
{:.no-copy-code}

## Generate Access Tokens

After Terraform deployment, generate OAuth tokens for each client.

Get the token endpoint from your Terraform output:

```sh
export TOKEN_ENDPOINT=$(terraform output -raw token_endpoint)
```

Generate the access token for Client 1 (full access):

```sh
export CLIENT_ID_1=$(terraform output -raw client_id_1)
export CLIENT_SECRET_1=$(terraform output -raw client_secret_1)

curl -X POST "$TOKEN_ENDPOINT" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=$CLIENT_ID_1" \
  -d "client_secret=$CLIENT_SECRET_1" \
  -d "scope=kafka"
```

Export the Client 1's access token:

```sh
export ACCESS_TOKEN_CLIENT1='YOUR-ACCESS-TOKEN-FROM-RESPONSE'
```

Generate the access token for Client 2 (limited access):

```sh
export CLIENT_ID_2=$(terraform output -raw client_id_2)
export CLIENT_SECRET_2=$(terraform output -raw client_secret_2)

curl -X POST "$TOKEN_ENDPOINT" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=$CLIENT_ID_2" \
  -d "client_secret=$CLIENT_SECRET_2" \
  -d "scope=kafka"
```

Export the Client 2's access token:

```sh
export ACCESS_TOKEN_CLIENT2='YOUR-ACCESS-TOKEN-FROM-RESPONSE'
```

## Validate

Run the following to validate your configuration.

### Connect with OAuth Bearer Token (Client 1 - Full Access)

Produce messages to any topic:

```sh
kafka-console-producer --bootstrap-server localhost:19092 \
  --topic test-topic \
  --producer-property security.protocol=SASL_PLAINTEXT \
  --producer-property sasl.mechanism=OAUTHBEARER \
  --producer-property sasl.jaas.config='org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginModule required oauth.access.token="'$ACCESS_TOKEN_CLIENT1'";' \
  --producer-property sasl.login.callback.handler.class=org.apache.kafka.common.security.oauthbearer.secured.OAuthBearerLoginCallbackHandler
```

Consume messages from any topic:

```sh
kafka-console-consumer --bootstrap-server localhost:19092 \
  --topic test-topic \
  --consumer-property security.protocol=SASL_PLAINTEXT \
  --consumer-property sasl.mechanism=OAUTHBEARER \
  --consumer-property sasl.jaas.config='org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginModule required oauth.access.token="'$ACCESS_TOKEN_CLIENT1'";' \
  --consumer-property sasl.login.callback.handler.class=org.apache.kafka.common.security.oauthbearer.secured.OAuthBearerLoginCallbackHandler
```

### Connect with OAuth Bearer Token (Client 2 - Limited Access)

Client2 can only read from the `topic` topic:

```sh
kafka-console-consumer --bootstrap-server localhost:19092 \
  --topic topic \
  --consumer-property security.protocol=SASL_PLAINTEXT \
  --consumer-property sasl.mechanism=OAUTHBEARER \
  --consumer-property sasl.jaas.config='org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginModule required oauth.access.token="'$ACCESS_TOKEN_CLIENT2'";' \
  --consumer-property sasl.login.callback.handler.class=org.apache.kafka.common.security.oauthbearer.secured.OAuthBearerLoginCallbackHandler
```
{:.info}
> **Note**: Client 2 cannot produce messages or read from other topics due to ACL restrictions.

### Test Record Filtering

Client 1 can see all records, including those with `internal=true` header:

```sh
# Produce a record with internal header (as Client1)
echo "internal-data" | kafka-console-producer --bootstrap-server localhost:19092 \
  --topic test-topic \
  --property "parse.key=false" \
  --property "key.separator=:" \
  --property "header.separator=|" \
  --property "headers=internal:true" \
  --producer-property security.protocol=SASL_PLAINTEXT \
  --producer-property sasl.mechanism=OAUTHBEARER \
  --producer-property sasl.jaas.config='org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginModule required oauth.access.token="'$ACCESS_TOKEN_CLIENT1'";' \
  --producer-property sasl.login.callback.handler.class=org.apache.kafka.common.security.oauthbearer.secured.OAuthBearerLoginCallbackHandler
```

Client 2 will NOT see records with `internal=true` header due to the skip record policy.


