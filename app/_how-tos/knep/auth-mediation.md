---
title: Authenticate messages with {{site.event_gateway}}
short_title: Auth mediation
content_type: how_to
breadcrumbs:
  - /event-gateway/

permalink: /event-gateway/get-started/auth-mediation/

series:
  id: event-gateway-get-started
  position: 5

beta: true

products:
    - event-gateway

works_on:
    - konnect

tags:
    - get-started
    - event-gateway
    - kafka

description: Configure {{site.event_gateway}} with different authentication methods, specifically showing both anonymous and JWT authentication configurations.


tldr: 
  q: How can I set up authentication for {{site.event_gateway}}?
  a: | 
    This example demonstrates how to configure {{site.event_gateway}} with different authentication methods, specifically showing both anonymous and JWT authentication configurations.


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
backend_clusters:
  - name: kafka-localhost
    bootstrap_servers:
      - localhost:9092
      - localhost:9093
      - localhost:9094

virtual_clusters:
  - name: team-a
    backend_cluster_name: kafka-localhost
    route_by:
      type: port
      port:
        min_broker_id: 1
    authentication:
      - type: sasl_oauth_bearer
        sasl_oauth_bearer:
          jwks:
            endpoint: http://localhost:8080/realms/kafka-realm/protocol/openid-connect/certs
            timeout: "1s"
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

listeners:
  port:
    - listen_address: 0.0.0.0
      listen_port_start: 19092
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