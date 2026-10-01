---
title: Authenticate {{site.event_gateway}} connections to Kafka using AWS IAM
content_type: how_to
breadcrumbs:
  - /event-gateway/

permalink: /event-gateway/configure-aws-iam-backend-cluster-auth/

products:
    - event-gateway

works_on:
    - konnect

tags:
    - event-gateway
    - kafka
    - aws

description: "Configure AWS IAM authentication so that {{site.event_gateway}} can connect to Amazon MSK using IAM credentials."

tldr:
  q: How do I authenticate {{site.event_gateway}} connections to Amazon MSK using AWS IAM?
  a: |
    Create a backend cluster with `authentication.type: sasl_aws_iam` and `sasl_aws_iam.type: default_provider_chain` to authenticate with the AWS SDK's default credentials provider chain, or `assume_role` to authenticate by assuming an IAM role.

tools:
    - konnect-api

prereqs:
  skip_product: true
  inline:
    - title: Install kafkactl
      position: before
      include_content: knep/kafkactl

    - title: Amazon MSK cluster
      content: |
        You need an [Amazon MSK cluster with IAM access control enabled](https://docs.aws.amazon.com/msk/latest/developerguide/create-cluster.html), reachable from your {{site.event_gateway_short}} data plane, and the bootstrap broker addresses for its IAM listener (port `9098` by default).
      icon_url: /assets/icons/aws.svg

    - title: AWS credentials
      content: |
        {{site.event_gateway_short}} authenticates to Amazon MSK using the [AWS SDK's default credentials provider chain](https://docs.aws.amazon.com/sdkref/latest/guide/standardized-credentials.html), so the {{site.event_gateway_short}} data plane host needs AWS credentials available through one of the standard mechanisms, for example environment variables, a shared credentials file, or an EC2/ECS/EKS instance role.

        The credentials (or a role they can assume) need the [MSK IAM actions](https://docs.aws.amazon.com/msk/latest/developerguide/iam-access-control.html) required to connect and describe the cluster, such as `kafka-cluster:Connect` and `kafka-cluster:DescribeCluster`. They also need the relevant `kafka-cluster:*Topic*` permissions for the topic resources.
      icon_url: /assets/icons/aws.svg

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
  - text: Authenticate connections to Kafka using mTLS
    url: /event-gateway/configure-mtls-backend-cluster-auth/
  - text: IAM access control for Amazon MSK
    url: https://docs.aws.amazon.com/msk/latest/developerguide/iam-access-control.html

min_version:
  event-gateway: '1.3.0'

automated_tests: false
---

In this guide you'll configure {{site.event_gateway_short}} to connect to an [Amazon MSK](https://aws.amazon.com/msk/) cluster using AWS Identity and Access Management (IAM) credentials.

{% mermaid %}
flowchart LR
    C[Kafka Client]
    subgraph EG [" {{site.event_gateway_short}} "]
        VC[aws-iam virtual cluster]
    end
    subgraph K [Amazon MSK]
        L["IAM :9098"]
    end
    C -->|anonymous| VC
<!-- vale off -->
    VC -->|AWS IAM| L
<!-- vale on -->
{% endmermaid %}

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

{:.info}
> Unlike the local Docker Compose examples for mTLS and SASL/PLAIN, this guide connects to a real Amazon MSK cluster.
> Make sure the host running the {{site.event_gateway_short}} data plane can reach your MSK cluster's bootstrap brokers, for example through VPC peering, a VPN, or by running the data plane inside the same VPC.

## Configure kafkactl

Create a `kafkactl.yaml` config file with a context for the AWS IAM virtual cluster:

<!--vale off-->
{% validation custom-command %}
command: |
  cat <<EOF > kafkactl.yaml
  contexts:
    aws-iam-vc:
      brokers:
        - localhost:19092
  EOF
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

Clients only ever authenticate anonymously to this virtual cluster. AWS IAM is used solely by {{site.event_gateway_short}} itself, when it connects to the backend cluster on the client's behalf.

## Create the backend cluster

Export the bootstrap broker addresses for your MSK cluster's IAM listener:

```bash
export MSK_BOOTSTRAP_SERVERS="b-1.example.abc123.c2.kafka.us-east-1.amazonaws.com:9098,b-2.example.abc123.c2.kafka.us-east-1.amazonaws.com:9098,b-3.example.abc123.c2.kafka.us-east-1.amazonaws.com:9098"
```

Build the request body for a [backend cluster](/event-gateway/entities/backend-cluster/) using `sasl_aws_iam` authentication with the default AWS credentials provider chain:

<!--vale off-->
{% validation custom-command %}
command: |
  jq -n --arg brokers "$MSK_BOOTSTRAP_SERVERS" \
    '{
      "name": "msk_backend_cluster",
      "bootstrap_servers": ($brokers | split(",")),
      "authentication": {
        "type": "sasl_aws_iam",
        "sasl_aws_iam": {"type": "default_provider_chain"}
      },
      "insecure_allow_anonymous_virtual_cluster_auth": true,
      "tls": {"enabled": true}
    }' > msk_backend_cluster.json
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
body_cmd: $(cat msk_backend_cluster.json)
extract_body:
  - name: id
    variable: MSK_BACKEND_CLUSTER_ID
capture:
    - variable: MSK_BACKEND_CLUSTER_ID
      jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

`default_provider_chain` tells {{site.event_gateway_short}} to resolve AWS credentials the same way the AWS CLI and SDKs do.

### Assume an IAM role instead

If you need {{site.event_gateway_short}} to assume a role before connecting, for example to access an MSK cluster in another AWS account, use `assume_role` instead:

```json
{
  "authentication": {
    "type": "sasl_aws_iam",
    "sasl_aws_iam": {
      "type": "assume_role",
      "assume_role": {
        "arn": "arn:aws:iam::123456789012:role/example-role",
        "session_name": "event-gateway-session"
      }
    }
  }
}
```

{{site.event_gateway_short}} first resolves base credentials from the default provider chain, then uses them to assume the role at `arn`. The role's trust policy must allow the base credentials to assume it. `session_name` is optional and becomes part of the assumed role session's ARN.

## Create a virtual cluster

Create a [virtual cluster](/event-gateway/entities/virtual-cluster/) with `anonymous` authentication:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters
status_code: 201
method: POST
body:
  name: aws_iam_vc
  destination:
    id: $MSK_BACKEND_CLUSTER_ID
  dns_label: aws-iam-vc
  authentication:
    - type: anonymous
  acl_mode: passthrough
extract_body:
  - name: id
    variable: MSK_VC_ID
capture:
    - variable: MSK_VC_ID
      jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

## Create a listener

Run the following command to create a new [listener](/event-gateway/entities/listener/):

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/listeners
status_code: 201
method: POST
body:
  name: aws_iam_listener
  addresses:
    - 0.0.0.0
  ports:
    - 19092-19105
extract_body:
  - name: id
    variable: MSK_LISTENER_ID
capture:
    - variable: MSK_LISTENER_ID
      jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

## Create a listener policy

Add a [Forward to Virtual Cluster](/event-gateway/policies/forward-to-virtual-cluster/) policy,
which will forward requests based on a defined mapping to our virtual cluster:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/listeners/$MSK_LISTENER_ID/policies
status_code: 201
method: POST
body:
  type: forward_to_virtual_cluster
  name: forward_to_aws_iam_vc
  config:
    type: port_mapping
    advertised_host: localhost
    destination:
      id: $MSK_VC_ID
{% endkonnect_api_request %}
<!--vale on-->

## Validate

Ensure there's at least one topic on your MSK cluster.
Then list the topics through the `aws-iam-vc` virtual cluster:

<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context aws-iam-vc list topics
expected:
  return_code: 0
  message: |
    TOPIC                    PARTITIONS     REPLICATION FACTOR
    test-topic               1              1
render_output: false
{% endvalidation %}
<!--vale on-->

```shell
TOPIC                    PARTITIONS     REPLICATION FACTOR
test-topic               1              1
```
{:.no-copy-code}

{{site.event_gateway_short}} authenticated to Amazon MSK using AWS IAM and forwarded the metadata request successfully.
