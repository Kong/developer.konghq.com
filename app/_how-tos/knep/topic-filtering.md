---
title: Set up topic filtering with {{site.event_gateway}}
short_title: Topic filtering
content_type: how_to
breadcrumbs:
  - /event-gateway/

permalink: /event-gateway/get-started/topic-filtering/

series:
  id: event-gateway-get-started
  position: 3

beta: true

products:
    - event-gateway

works_on:
    - konnect

tags:
    - get-started
    - event-gateway
    - kafka

description: Configure {{site.event_gateway}} to automatically filter topic names using prefixes.


tldr: 
  q: How can I set up topic filtering with {{site.event_gateway}}?
  a: | 
    This example demonstrates how to configure {{site.event_gateway}} to automatically filter topic names using prefixes.

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

faqs:
  - q: Why are topics not appearing with a prefix?
    a: |
      Troubleshoot your configuration by checking the following:
      * Verify the proxy configuration is loaded correctly
      * Ensure that you're connecting through the correct proxy port (19092 for team-a, 29092 for team-b)
      * Check that the topic filter rules are correctly configured
  - q: Why can't I access the original topic names through Kafka after configuring a prefix?
    a: |
      After you configure a prefix, you can't directly access the topics using the original names. 
      * When accessing topics through Kafka, use prefixed names.
      * When accessing topics through the {{site.event_gateway_short}} proxy, use prefixed names.
  - q: Why are certain topics not visible to a team?
    a: |
      Each team can only see topics with their respective prefix. For example:
      * Team-a can only see topics prefixed with `a-`
      * Team-b can only see topics prefixed with `b-`
      
      Topics without the correct prefix (like `fourth-topic`) won't be visible through either proxy.
---

## Benefits of topic filtering

Topic filtering is ideal for:

* Multi-tenant environments
* Topic namespace isolation
* Environment segregation
* Service mesh patterns


## Configure topic name aliasing

Create a config file to define topic name aliases:

```yaml
cat <<EOF > knep-topic-filtering.yaml
virtual_clusters:
  - name: team-a
    backend_cluster_name: kafka-localhost
    route_by:
      type: port
      port:
        min_broker_id: 1
    authentication:
      - type: anonymous
        mediation:
          type: anonymous
    topic_rewrite:
      type: prefix
      prefix:
        value: a-
  - name: team-b
    backend_cluster_name: kafka-localhost
    route_by:
      type: port
      port:
        offset: 10000
        min_broker_id: 1
    authentication:
      - type: anonymous
        mediation:
          type: anonymous
    topic_rewrite:
      type: prefix
      prefix:
        value: b-
EOF
```
In this configuration file, we use:
* Two virtual clusters with different prefixes: `a-` for Team-a and `b-` for Team-b
* Team-a accessible on port 9192, team-b on port 9193
* All topics accessed through each proxy will be prefixed accordingly
* Original topic names preserved in the client view
* Transparent prefix handling for clients

Update the Control Plane using the `/declarative-config` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: "/v2/control-planes/$KONNECT_CONTROL_PLANE_ID/declarative-config"
status_code: 201
method: PUT
body_cmd: "$(jq -Rs '{config: .}' < knep-topic-filtering.yaml)"
{% endkonnect_api_request %}
<!--vale on-->

## Validate topic filtering

Using `kafkactl`, test the topic filtering.

1. Create topics directly in Kafka:

   ```sh
   kafkactl config use-context direct
   kafkactl create topic a-first-topic b-second-topic b-third-topic fourth-topic
   ```

1. Access team-a topics through the proxy:

   ```sh
   kafkactl config use-context team-a
   kafkactl get topics
   ```

   In the output, you should only see `first-topic`, without the `a-` prefix.

1. Create and consume message in the topic `first-topic`:

   ```sh
   kafkactl produce first-topic --value="Hello from Team A"
   kafkactl consume first-topic -b -e
   ```

You can check the same for team-b.

Now, lets verify the actual topic names in Kafka:
```
kafkactl config use-context direct
kafkactl get topics
```

In the output, you should see all topics with their prefixes: `a-first-topic`, `b-second-topic`, and so on.
