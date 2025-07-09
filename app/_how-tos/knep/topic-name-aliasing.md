---
title: Set up topic aliasing with {{site.event_gateway}}
short_title: Topic name aliasing
content_type: how_to
breadcrumbs:
  - /event-gateway/

permalink: /event-gateway/get-started/topic-name-aliasing/

series:
  id: event-gateway-get-started
  position: 2

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
    This example demonstrates how to configure {{site.event_gateway}} to perform topic name aliasing using Common Expression Language (CEL) expressions.

tools:
    - konnect-api
  
prereqs:
  skip_product: true

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

automated_tests: false
related_resources:
  - text: "{{site.event_gateway_short}} configuration schema"
    url: /api/event-gateway/knep/
  - text: Event Gateway
    url: /event-gateway/
  - text: Common Expression Language Specification
    url: https://github.com/google/cel-spec

faqs:
  - q: Why are my topic names not transforming?
    a: |
      If your topic names aren't transforming, troubleshoot your setup by doing the following:
      * Verify the proxy configuration is loaded correctly
      * Ensure you're connecting through the proxy port (in this guide, port 9192)
      * Check if the topic name matches exactly. Topic names are case-sensitive.
  - q: Why am I getting unexpected topic names?
    a: |
      If you get topic names that you didn't configure, troubleshoot by doing the following:
      * Verify the CEL expressions in the configuration
      * Check the mapping dictionary for the expected names
      * Ensure that bi-directional mappings are consistent

---

## Benefits of topic aliasing

Topic aliasing is useful for:

* Standardizing topic naming conventions
* Supporting legacy topic names
* Providing friendly names for clients
* Maintaining backward compatibility

## Configure topic name aliasing

Create a config file to define topic name aliases:

```yaml
cat <<EOF > knep-topic-aliases.yaml
virtual_clusters:
  - name: proxy
    backend_cluster_name: kafka-localhost
    route_by:
      type: port
      port:
        listen_start: 19092
        min_broker_id: 1
    authentication:
      - type: anonymous
        mediation:
          type: anonymous
    topic_rewrite:
      type: cel
      cel:
        virtual_to_backend_expression: >
          {
            "Jonathan":"Jon",
            "Katherine":"Kate",
            "William":"Will",
            "Elizabeth":"Liz"
          }.has(topic.name) ? 
          {
            "Jonathan":"Jon",
            "Katherine":"Kate",
            "William":"Will",
            "Elizabeth":"Liz"
          }[topic.name] : topic.name
        backend_to_virtual_expression: >
          {
            "Jon":"Jonathan",
            "Kate":"Katherine",
            "Will":"William",
            "Liz":"Elizabeth"
          }.has(topic.name) ? 
          {
            "Jon":"Jonathan",
            "Kate":"Katherine",
            "Will":"William",
            "Liz":"Elizabeth"
          }[topic.name] : topic.name
backend_clusters:
  - name: kafka-localhost
    bootstrap_servers:
      - localhost:9092
EOF
```
In this configuration file, we use:
* CEL expressions for bidirectional name mapping
* Predefined name aliases
* Fallback to original name if no mapping exists
* Transparent transformation for clients

Update the Control Plane using the `/declarative-config` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: "/v2/control-planes/$KONNECT_CONTROL_PLANE_ID/declarative-config"
status_code: 201
method: PUT
body_cmd: "$(jq -Rs '{config: .}' < knep-topic-aliases.yaml)"
{% endkonnect_api_request %}
<!--vale on-->

## Validate topic name aliasing

Using `kafkactl`, test the topic aliasing.

First, create and use topics with full names:

```sh
kafkactl config use-context virtual
kafkactl create topic Jonathan
kafkactl produce Jonathan --value="Hello World"
kafkactl consume Jonathan
```

Then, verify the actual topic name in Kafka:
```sh
kafkactl config use-context direct
kafkactl list topics
```
If aliasing is working, you should see `Jon` instead of `Jonathan` in the output.