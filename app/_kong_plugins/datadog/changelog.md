---
content_type: reference

---

## Changelog

### {{site.base_gateway}} 3.6.x
* Fixed a bug where the plugin wasn't triggered for serviceless routes. 
  The Datadog plugin is now always triggered, and the value of tag `name`(`service_name`) is set as an empty value.
 [#12068](https://github.com/Kong/kong/issues/12068)

### {{site.base_gateway}} 3.3.x
* The `host` configuration value is now referenceable.

### {{site.base_gateway}} 3.1.x
* Added support for managing queues and connection retries when sending messages to the upstream with 
the `queue_size`,`flush_timeout`, and `retry_count` configuration parameters. 

### {{site.base_gateway}} 2.7.x
* Added support for the `distribution` metric type.
* Allow service, consumer, and status tags to be customized through the configuration parameters `service_name_tag`, `consumer_tag`, and `status_tag`.

### {{site.base_gateway}} 2.6.x
* The `host` and `port` configuration options can now be configured through the environment variables `KONG_DATADOG_AGENT_HOST` and `KONG_DATADOG_AGENT_PORT`.
This lets you set different destinations for each Kong node, which makes multi-DC setups easier, and in Kubernetes, lets you run a Datadog agent as a DaemonSet.
