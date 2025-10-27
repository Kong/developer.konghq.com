---
title: Get started with {{site.event_gateway}}
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
    Get started with {{site.event_gateway}} by setting up a {{site.konnect_short_name}} control plane and data plane, then configuring a backend cluster, virtual cluster, listener, and policies with the {{site.event_gateway}} API.

    {:.info}
    > **Note:**
    > This quickstart runs a pre-configured demo Docker container to explore {{ site.base_gateway }}'s capabilities. 
    If you want to run {{ site.base_gateway }} as a part of a production-ready platform, set up your control plane and data planes through the [{{site.konnect_short_name}} UI](/event-gateway/?tab=konnect-ui#install-event-gateway), or using [Terraform](/terraform/).

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
      * Verify all services are running with `docker ps`.
      * Check if ports are available (in this how-to guide, we use 19092 for the proxy, 9092-9095 for Kafka). For example, on a Unix-based system, you could use `lsof -i -P | grep 909`.
      * Ensure that all environment variables are set correctly.
  - q: When I run `list topics`, topics aren't visible.
    a: |
      Troubleshoot your setup by doing the following:
      * Verify that your Kafka broker is healthy.
      * Check if you're using the correct `kafkactl` context.
      * Ensure that the proxy is properly connected to the backend cluster.
      * Ensure that `acl_mode` is set to `passthrough` in the virtual cluster. If set to `enforce_on_gateway`, you won't see any topics listed without an ACL policy.
---

{{site.event_gateway}} lets you configure virtual clusters, which act as a proxy interface between the Kafka client and the Kafka cluster.
With virtual clusters, you can:
* Apply transformations, filtering, and custom policies
* Route messages based on specific rules to different Kafka clusters
* Apply auth mediation and message encryption
and much more.

Now, let's configure a proxy and test your first virtual cluster setup.

## Create an {{site.event_gateway_short}} in {{site.konnect_short_name}}

Run the [quickstart script](https://get.konghq.com/event-gateway) to automatically provision a demo {{site.base_gateway}} control plane and data plane, and configure your environment:

```bash
curl -Ls https://get.konghq.com/event-gateway | bash -s -- -k $KONNECT_TOKEN
```

This sets up an {{site.base_gateway}} control plane named `event-gateway-quickstart`, provisions a local data plane, and prints out the following environment variable export:

```bash
export EVENT_GATEWAY_ID=your-gateway-id
```

Copy and paste this into your terminal to configure your session.

{:.info}
> This quickstart script is meant for demo purposes only, therefore it runs locally with default parameters and a small number of exposed ports.
If you want to run {{ site.base_gateway }} as a part of a production-ready platform, set up your control plane and data planes through the [{{site.konnect_short_name}} UI](/event-gateway/?tab=konnect-ui#install-event-gateway), or using [Terraform](/terraform/).

## Add a backend cluster

[Backend clusters](/event-gateway/entities/backend-cluster/) are abstractions of your real Kafka clusters, and they store connection and configuration details required for {{site.event_gateway}} to proxy traffic to Kafka.
You need at least one backend cluster.

Run the following command to create a new backend cluster linked to the local Kafka server we created in the [prerequisites](#start-a-local-kafka-cluster):
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
{% endkonnect_api_request %}
<!--vale on-->

In this example configuration:
* `bootstrap_servers`: Points the backend cluster to the three bootstrap servers that we launched in the prerequisites. 
* `authentication` and `insecure_allow_anonymous_virtual_cluster_auth`: For demo purposes, we're allowing insecure `anonymous` connections, which means no authentication required. 
* `tls`: TLS is disabled so that we can easily test the connection.

Export the backend cluster ID to your environment:
```sh
export BACKEND_CLUSTER_ID="YOUR-BACKEND-CLUSTER-ID"
```

## Add a virtual cluster

[Virtual clusters](/event-gateway/entities/virtual-cluster/) are the connection point for Kafka clients. 
Instead of connecting clients directly to your Kafka cluster, you can set up virtual clusters to customize how clients connect, and what requirements they need to have.
From the client's point of view, they're just connecting to a regular Kafka cluster.

Virtual clusters provide environment isolation and let you enforce policies, manage authentication, and more.
Each virtual cluster can connect to one backend cluster, though a backend cluster can have many virtual clusters connected to it.

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
{% endkonnect_api_request %}
<!--vale on-->

In this example:
* `authentication`: Allows anonymous authentication.
* `acl_mode`: The setting `passthrough` means that all clients are allowed and don't have to match a defined ACL. 
In a production environment, you would set this to `enforce_on_gateway` and define an ACL policy.
* `name` is an internal name for the configuration object, while the `dns_label` is necessary for SNI routing.

Export the virtual cluster ID to your environment:
```sh
export VIRTUAL_CLUSTER_ID="YOUR-VIRTUAL-CLUSTER-ID"
```

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
{% endkonnect_api_request %}
<!--vale on-->

Export the listener ID to your environment:
```sh
export LISTENER_ID="YOUR-LISTENER-ID"
```

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

## Add a virtual cluster policy

Now, let's add a policy the virtual cluster so we can test our proxy. 
For this example, let's add a [Modify Headers](/event-gateway/policies/modify-headers/) policy, which lets you set or remove headers on requests:

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

This policy configuration sets the custom header `My-New-Header: header_value` on all requests proxied by this virtual cluster.

## Configure the Kafka cluster

Now that we've configured the proxy, let's make sure the Kafka cluster is ready.

In your local environment, set up the `kafkactl.yaml` config file for your Kafka cluster:

```shell
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
```
This file defines two configuration profiles:
* `direct`: Connection addresses to all of the bootstrap servers you launched in the prerequisites, and configured in the backend cluster. 
Accessing the `direct` context will bypass the {{site.event_gateway}} proxy and connect directly to your Kafka cluster.
* `vc`: Connection to the virtual cluster. Accessing the `vc` context will pass requests through the virtual cluster.

We're going to switch between these profiles as we test different features.

## Validate the cluster

Let's check that the cluster works using `kafkactl`.
First, create a topic using the `direct` context, which is a direct connection to our Kafka cluster:

```shell
kafkactl -C kafkactl.yaml --context direct create topic my-test-topic
```

Produce a message to make sure it worked:
```shell
kafkactl -C kafkactl.yaml --context direct produce my-test-topic --value="Hello World"
```

You should see the following response:
```shell
topic created: my-test-topic
message produced (partition=0	offset=0)
```
{:.no-copy-code}

Now let's test that our Modify Headers policy is applying the header `My-New-Header`.
By passing the `vc` context, `kafkactl` will connect to Kafka through the proxy port `19092`.

First, produce a message:

```shell
kafkactl -C kafkactl.yaml --context vc produce my-test-topic --value="test message"
```

Consume the `my-test-topic` from the beginning while passing the `--print-headers` flag:

```shell
kafkactl -C kafkactl.yaml --context vc consume my-test-topic --print-headers --from-beginning
```

The output should contain your new header:
```shell
My-New-Header: header_value
```
{:.no-copy-code}

You now have a Kafka cluster running with an {{site.event_gateway_short}} proxy in front, and the proxy is applying your custom policies. 