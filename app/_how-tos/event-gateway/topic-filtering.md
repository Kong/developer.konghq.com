---
title: Set up topic filtering with {{site.event_gateway}}
short_title: Topic filtering
content_type: how_to
breadcrumbs:
  - /event-gateway/

permalink: /event-gateway/get-started/topic-filtering/

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
    Configure {{site.event_gateway}} to automatically filter topic names using prefixes.
    In this how-to guide, we apply specific prefixes to team-based contexts by configuring a `topic_rewrite` with custom prefixes for each team. 

tools:
    - konnect-api
  
prereqs:
  skip_product: true

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Clean up {{site.event_gateway}} resources
      include_content: cleanup/products/event-gateway
      icon_url: /assets/icons/event.svg    

automated_tests: false
related_resources:
  - text: "{{site.event_gateway_short}} configuration schema"
    url: /api/konnect/event-gateway/
  - text: Event Gateway
    url: /event-gateway/

faqs:
  - q: Why am I not seeing a prefix in front of my Kafka topics?
    a: |
      If you configured a prefix but aren't seeing one, troubleshoot your configuration by checking the following:
      * Verify the proxy configuration is loaded correctly by checking the logs (`docker compose logs knep`), or looking at your data plane errors in {{site.konnect_short_name}}
      * Ensure that you're connecting through the correct proxy port (in this guide, 19092 for team-a, 29092 for team-b)
      * Check that the topic filter rules are correctly configured
  - q: Why can't I access the original topic names through Kafka after configuring a prefix?
    a: |
      After you configure a prefix, you can't directly access the topics using the original names. 
      * When accessing topics directly through Kafka, use prefixed names (for example, `a-first-topic`).
      * When accessing topics through the {{site.event_gateway_short}} proxy, use unprefixed names (for example, `first-topic`).
  - q: Why are certain topics not visible to a team?
    a: |
      Each team can only see topics with their respective prefix. For example:
      * Team-a can only see topics prefixed with `a-`
      * Team-b can only see topics prefixed with `b-`
      
      Topics without the correct prefix (like `fourth-topic`) won't be visible through either proxy.

published: false 
# Needs to be updated for GA

---

Topic filtering lets you automatically prefix and filter topics based on virtual clusters. 
With filter prefixes, you can limit Kafka topics by team, purpose, or any other category.

Topic filtering is useful for:
* Multi-tenant environments
* Topic namespace isolation
* Environment segregation
* Service mesh patterns

In this guide, you'll configure topic filtering by team, where each team can only see topics that match their assigned prefix.
The actual Kafka cluster stores all topics with their prefixed names.

## Configure topic name aliasing

Create a config file to define topic name aliases.

This config uses the `topic_rewrite` parameter with a `prefix` option, in this case adding custom prefixes for `team-a` and `team-b`:

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
* Two virtual clusters with different prefixes: `a-` for `team-a` and `b-` for `team-b`
* Team-a is accessible on port 9192, team-b on port 9193
* All topics accessed through each proxy will be prefixed based on their team assignments
* Original topic names are preserved in the client view
* This provides transparent prefix handling for clients


## Validate topic filtering

Using `kafkactl`, test the topic filtering.

1. Create topics directly in Kafka:

   ```sh
   kafkactl -C kafkactl.yaml --context direct create topic a-first-topic b-second-topic
   ```

1. Access topics through the proxy using the `team-a` context:

   ```sh
   kafkactl -C kafkactl.yaml --context team-a get topics
   ```

   In the output, you should only see `first-topic`, without the `a-` prefix:

   ```sh
   TOPIC            PARTITIONS     REPLICATION FACTOR
   first-topic      1              1
   ```
   {:.no-copy-code}

1. Create and consume message in the topic `first-topic`:

   ```sh
   kafkactl -C kafkactl.yaml --context team-a produce first-topic --value="Hello from Team A"
   kafkactl -C kafkactl.yaml --context team-a consume first-topic -b -e
   ```

1. Now, lets verify the actual topic names in Kafka:

   ```sh
   kafkactl -C kafkactl.yaml --context direct get topics
   ```

   In the output, you should see all topics with their prefixes:

   ```
   TOPIC              PARTITIONS     REPLICATION FACTOR
   Jon                      1              1
   _schemas           1              1
   a-first-topic      1              1
   b-second-topic     1              1
   my-test-topic      1              1
   ```
   {:.no-copy-code}

