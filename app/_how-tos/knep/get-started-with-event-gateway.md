---
title: Get started with {{site.event_gateway}}
short_title: Install {{site.event_gateway_short}}
content_type: how_to
breadcrumbs:
  - /event-gateway/

permalink: /event-gateway/get-started/

products:
    - event-gateway

works_on:
    - konnect

tags:
    - get-started
    - event-gateway
    - kafka

description: Use this tutorial to get started with {{site.event_gateway}}.

tldr: 
  q: How can I get started with {{site.event_gateway}}?
  a: | 
    Get started with {{site.event_gateway}} by setting up a {{site.konnect_short_name}} control plane and data plane, then configuring a backend cluster, virtual cluster, listener, and policy with the {{site.event_gateway}} API.

tools:
    - konnect-api
  
prereqs:
  inline:
    - title: Install kafkactl
      content: |
        Install [kafkactl](https://github.com/deviceinsight/kafkactl?tab=readme-ov-file#installation). You'll need it to interact with Kafka clusters. 
    
    - title: Start a local Kafka cluster
      include_content: knep/docker-compose-start

automated_tests: false
related_resources:
  - text: "{{site.event_gateway_short}} configuration schema"
    url: /api/event-gateway/knep/
  - text: Event Gateway
    url: /event-gateway/

faqs:
  - q: | 
      I'm getting the error `Connection refused` when trying to access my Kafka cluster through {{site.event_gateway_short}}.
    a: |
      Check the following:
      * Verify all services are running with `docker ps`
      * Check if ports are available (in this how-to guide, we use 9192 for the proxy, 9092 for Kafka)
      * Ensure that all `KONNECT` environment variables are set correctly
  - q: When I run `list topics`, topics aren't visible.
    a: |
      Troubleshoot your setup by doing the following:
      * Verify that your Kafka broker is healthy
      * Check if you're using the correct `kafkactl` context
      * Ensure that the proxy is properly connected to the backend cluster
---

{{site.event_gateway}} lets you configure virtual clusters, which act as a proxy interface between the client and the Kafka cluster.
With virtual clusters, you can:
* Apply transformations, filtering, and custom policies
* Route messages based on specific rules to different Kafka clusters
* Apply auth mediation and message encryption
and much more.

Now, let's configure a proxy and test your first virtual cluster setup.

## Create an Event Gateway in {{site.konnect_short_name}}

{% include knep/konnect-create-cp.md name='KNEP getting started' %}

## Create a data plane node

1. In {{site.konnect_short_name}}, navigate to [**Event Gateway**](https://cloud.konghq.com/event-gateway/) in the sidebar.
1. Click your event gateway.
1. Navigate to **Data Plane Nodes** in the sidebar.
1. Click **Configure data plane**.
1. In the **Platform** dropdown, select your platform.
1. Click **Generate Certificate**.
1. Click the **Copy** button to copy the command.
1. Run the command in your terminal.

## Add a backend cluster

Run the following command to create a new backend cluster linked to the local Kafka server we created in the [prerequisites](#start-a-local-kafka-server):
<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/backend-clusters
status_code: 201
method: POST
body:
  name: kafka-localhostkafka:9092
  bootstrap_servers:
    - kafka:9092
  authentication:
    type: anonymous
  insecure_allow_anonymous_virtual_cluster_auth: true
  tls:
    insecure_skip_verify: false
{% endkonnect_api_request %}
<!--vale on-->

Export the backend cluster ID to your environment:
```sh
export BACKEND_CLUSTER_ID="YOUR-BACKEND-CLUSTER-ID"
```

## Add a virtual cluster

Run the following command to create a new virtual cluster associated with our backend cluster:
<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters
status_code: 201
method: POST
body:
  name: example.mycompany.com
  destination:
    id: $BACKEND_CLUSTER_ID
  dns_label: vc1
  authentication:
    - type: anonymous
  acl_mode: passthrough
{% endkonnect_api_request %}
<!--vale on-->

Export the virtual cluster ID to your environment:
```sh
export VIRTUAL_CLUSTER_ID="YOUR-VIRTUAL-CLUSTER-ID"
```

## Add a listener

Run the following command to create a new listener:
<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/listeners
status_code: 201
method: POST
body:
  name: listener-localhost
  addresses:
    - 0.0.0.0
  ports:
    - '19092'
{% endkonnect_api_request %}
<!--vale on-->

Export the listener ID to your environment:
```sh
export LISTENER_ID="YOUR-LISTENER-ID"
```

## Add a listener policy

Run the following command to add a listener policy that forwards messages to our virtual cluster:

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
    advertised_host: 0.0.0.0
    destination: 
      name: example.mycompany.com
{% endkonnect_api_request %}
<!--vale on-->


## Add a virtual cluster policy

Run the following command to add a consume policy that adds a new header on the virtual cluster:
<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/virtual-clusters/$VIRTUAL_CLUSTER_ID/consume-policies
status_code: 201
method: POST
body:
  type: modify_headers
  name: new-header
  config:
    actions:
      - op: set
        key: My-New-Header
        value: header_value
{% endkonnect_api_request %}
<!--vale on-->

## Configure the cluster

Set up the `kafkactl` config file:
```shell
cat <<EOF > kafkactl.yaml
contexts:
  direct:
    brokers:
      - localhost:9092
  backend:
    brokers:
      - localhost:9092
  knep:
    brokers:
      - localhost:19092
  secured:
    brokers:
      - localhost:29092
  team-a:
    brokers:
      - localhost:19092
  team-b:
    brokers:
      - localhost:29092
current-context: direct
EOF
```
This file defines several configuration profiles. We're going to switch between these profiles as we test different features.

## Validate the cluster

Let's check that the cluster works. We can use the Kafka UI to do this by going to [http://localhost:8082](http://localhost:8082) and checking the cluster list. 
You should see the `direct-kafka-cluster` and `knep-proxy-cluster` cluster listed there.

You can also use the `kafkactl` command to check the cluster. 
Let's check the Kafka cluster directly:

```shell
kafkactl -C kafkactl.yaml --context direct create topic my-test-topic
kafkactl -C kafkactl.yaml --context direct produce my-test-topic --value="Hello World"
```
It'll use the `direct` context, which is this case is a direct connection to our Kafka cluster.

You should see the following response:
```shell
topic created: my-test-topic
message produced (partition=0	offset=0)
```
{:.no-copy-code}

Now let's check the Kafka cluster through the {{site.event_gateway_short}} proxy.
By passing the `knep` context, `kafkactl` will connect to Kafka through the proxy port `19092`:

```shell
kafkactl -C kafkactl.yaml --context knep list topics
```

You should see a list of the topics you just created:
```shell
TOPIC              PARTITIONS     REPLICATION FACTOR
_schemas           1              1
my-test-topic      1              1
```
{:.no-copy-code}

You now have a Kafka cluster running with an {{site.event_gateway_short}} proxy in front. 