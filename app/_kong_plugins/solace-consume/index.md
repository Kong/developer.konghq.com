---
title: 'Solace Consume'
name: 'Solace Consume'

content_type: plugin
tier: enterprise
publisher: kong-inc
description: 'Consume messages from Solace topics and make them available through HTTP endpoints'
premium_partner: true

products:
    - gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.12'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

icon: solace-consume.png

categories:
   - traffic-control

tags:
  - traffic-control
  - events
  - solace

search_aliases:
  - solace-consume
  - traffic-control
  - events
  - event gateway

related_resources:
  - text: Solace Log plugin
    url: /plugins/solace-log/
  - text: Solace Upstream plugin
    url: /plugins/solace-upstream/
  - text: Kafka Log plugin
    url: /plugins/kafka-log/
  - text: Kafka Upstream plugin
    url: /plugins/kafka-upstream/
  - text: Confluent plugin
    url: /plugins/confluent/
  - text: Confluent Consume plugin
    url: /plugins/confluent-consume/

faqs:
  - q: I'm running into SSL connection issues with my Solace broker, what can I do?
    a: |
      If you encounter SSL connection issues, try the following:

      * Check if the Solace broker is properly configured for SSL connections
      * Verify that the broker's SSL certificate is valid
      * Verify that the plugin has [`config.session.ssl_validate_certificate`](./reference/#schema--config-session-ssl-validate-certificate) set to `true`
      * Ensure that the correct port is being used for SSL connections (usually port 55443)
      * Ensure that all necessary SSL parameters are configured in `config.session.properties`; see [Consume messages over SSL](/plugins/solace-consume/examples/ssl/) for an example.
      
      Note that the plugin doesn't implement any retry logic, so if the connection fails, the client has to retry sending the message.
  - q: Connections to Solace are failing.
    a: |
      If connections to Solace fail, check the following:

      * Network connectivity between {{site.base_gateway}} and the Solace broker
      * Authentication credentials
      * VPN name and permissions
      * Review Solace broker logs for more detailed error information
      * Increase the connection timeout on the Solace side (`solace_session_connect_timeout_ms`), or on the Kong side (see the [timeout setting](./reference/) for your mode)

  - q: I'm experiencing performance issues when using the Solace Consume plugin.
    a: |
      If you experience performance issues with high concurrency, adjust the following settings in your Solace broker:

      * Adjust the session pool size (`solace_session_pool`)
      * Increase the `ack` timeout (`ack_max_wait_time_ms`)
      * Consider using direct messaging instead of guaranteed messaging for higher throughput
      
      Since {{site.base_gateway}} workers are single-threaded, this plugin uses one Solace context per {{site.base_gateway}} worker with up to 4 sessions per plugin. 
      All sessions on a plugin share the same event loop. The plugin executes non-blocking event handling to avoid delaying {{site.base_gateway}} requests.

      {:.info}
      > **Note:** Make sure that your ulimits are high enough to handle the number of concurrent connections, and ensure that clients are using keepalive connections to avoid reaching the maximum number of file descriptors.

---

This plugin allows {{site.base_gateway}} to consume messages from a [Solace PubSub+ Event Broker](https://solace.com/products/event-broker/) and makes them available through HTTP endpoints.
For more information, see [Understanding Solace topics](https://docs.solace.com/Get-Started/what-are-topics.htm).

The Solace Consume plugin includes the following features:
* Supports Basic and OAuth2 Authentication for secure communication with Solace
* Allows dynamic configuration of Solace session properties
* Supports custom content payloads or direct payload forwarding
* Provides configurable acknowledgment wait time to handle guaranteed message delivery
* SSL/TLS support for secure connections to Solace brokers

Kong also provides Solace plugins for logging and publishing messages:
* [Solace Log](/plugins/solace-log/)
* [Solace Upstream](/plugins/solace-upstream/)

## Use cases and examples

See the following table for Solace Consume use cases:

{% table %}
columns:
  - title: Example
    key: example
  - title: Description
    key: desc
rows:
  - example: "[Auto mode](./examples/auto/)"
    desc: "Run the Solace Consume plugin in `auto` mode, letting the plugin automatically determine the mode from the client request."
  - example: "[Polling mode](./examples/polling/)"
    desc: "Run the Solace Consume plugin in its default polling mode."
  - example: "[Server-sent events mode](./examples/server-sent-events)"
    desc: "Stream messages using [server-sent events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events)."
  - example: "[WebSocket mode](./examples/websocket/)"
    desc: "Stream messages over a [WebSocket](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API) connection."
  - example: "[SSL connections](./examples/ssl/)"
    desc: "Enable SSL validation."
  - example: "[URI capture](./examples/uri-capture/)"
    desc: "Capture the URI of the request and use it as the message destination name."
{% endtable %}

## Implementation details

The plugin supports the following modes of operation:
* `polling`: Checks for messages at set intervals instead of waiting for a push notification (default)
* `auto`: Determines the mode automatically from the client request
* `server-sent-events`: Streams messages using [server-sent events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events)
* `websocket`: Streams messages over a [WebSocket](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API) connection

### WebSocket mode

{% include /plugins/confluent-kafka-consume/websocket.md slug=page.slug broker='Solace' name=page.name %}

### Message delivery guarantees

{% include /plugins/confluent-kafka-consume/message-delivery.md %}
