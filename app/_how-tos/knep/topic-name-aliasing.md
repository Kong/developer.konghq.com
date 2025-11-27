---
title: Set up topic aliasing with {{site.event_gateway}}
short_title: Topic name aliasing
content_type: how_to
breadcrumbs:
  - /event-gateway/

permalink: /event-gateway/get-started/topic-name-aliasing/

beta: true

products:
    - event-gateway

works_on:
    - konnect

tags:
    - get-started
    - event-gateway
    - kafka

description: Configure {{site.event_gateway}} to perform topic name aliasing using Common Expression Language (CEL) expressions.

tldr: 
  q: How can I set up topic name aliasing with {{site.event_gateway}}?
  a: | 
    Configure {{site.event_gateway}} to perform topic name aliasing using Common Expression Language (CEL) expressions. 
    To set up aliases, you'll need to configure a `topic_rewrite` directive with bidirectional name rewrites: `virtual_to_backend_expression` and `backend_to_virtual_expression`.

tools:
    - konnect-api
  
prereqs:
  skip_product: true

automated_tests: false
related_resources:
  - text: "{{site.event_gateway_short}} configuration schema"
    url: /api/konnect/event-gateway/
  - text: Event Gateway
    url: /event-gateway/
  - text: Common Expression Language Specification
    url: https://github.com/google/cel-spec

faqs:
  - q: Why are my topic names not transforming?
    a: |
      If your topic names aren't transforming, troubleshoot your setup by doing the following:
      * Verify the proxy configuration is loaded correctly by checking the logs (`docker compose logs knep`), or looking at your data plane errors in {{site.konnect_short_name}}
      * Ensure you're connecting through the proxy port (in this guide, port 19092)
      * Check if the topic name matches exactly. Topic names are case-sensitive.
  - q: Why am I getting unexpected topic names?
    a: |
      If you get topic names that you didn't configure, troubleshoot by doing the following:
      * Verify the CEL expressions in the configuration
      * Check the mapping dictionary for the expected names
      * Ensure that bi-directional mappings are consistent

published: false 
# Needs to be updated for GA

---

Topic name aliasing lets you to create bidirectional name mappings between virtual topic names 
(what clients see) and backend topic names (what actually exists in Kafka).

Topic name aliasing is useful for:
* Standardizing topic naming conventions
* Supporting legacy topic names
* Providing friendly names for clients
* Maintaining backward compatibility

In this guide, you'll configure a client-facing alias for a topic and a fallback topic name.

## Configure topic name aliasing

Create a config file to define topic name aliases. 

This config uses the `topic_rewrite` parameter with the following options:
* `virtual_to_backend_expression`: Transforms client-facing names to Kafka topic names (`Jonathan` to `Jon`)
* `backend_to_virtual_expression`: Transforms Kafka topic names into to client-facing names (`Jon` to `Jonathan`)

```yaml
cat <<EOF > knep-config.yaml
backend_clusters:
  - bootstrap_servers:
      - kafka:9092
    name: kafka-localhost
listeners:
  port:
    - advertised_host: localhost
      listen_address: 0.0.0.0
      listen_port_start: 19092
virtual_clusters:
  - authentication:
      - mediation:
          type: anonymous
        type: anonymous
    backend_cluster_name: kafka-localhost
    name: team-a
    route_by:
      port:
        min_broker_id: 1
      type: port
    topic_rewrite:
      type: cel
      cel:
        virtual_to_backend_expression: 'topic.name == "Jonathan" ? "Jon" : topic.name'
        backend_to_virtual_expression: 'topic.name == "Jon" ? "Jonathan" : topic.name'
EOF
```
In this configuration file, we use:
* CEL expressions for bidirectional name mapping
* Predefined name aliases
* Fallback to original name if no mapping exists
* Transparent transformation for clients


## Validate topic name aliasing

Using `kafkactl`, test the topic aliasing.

First, create a topic through the proxy using the full name `Jonathan`:

```sh
kafkactl -C kafkactl.yaml --context knep create topic Jonathan
```

Check the topic in `knep`:

```sh
kafkactl -C kafkactl.yaml --context knep list topics
```

Then, verify the actual topic name in Kafka:
```sh
kafkactl -C kafkactl.yaml --context direct list topics
```
If aliasing is working, you should see `Jon` instead of `Jonathan` in the output.