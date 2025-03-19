---
content_type: reference

---
## Changelog

### {{site.base_gateway}} 3.9.x
* Added the new configuration field `config.lock_dictionary_name` to support specifying an independent shared memory for storing locks.
* Added support for authentication from {{site.base_gateway}} to Envoy Proxy.
* Added support for combining multiple identifier items with the new configuration field `config.compound_identifier`.
* Fixed an issue where counters of the overriding consumer groups weren't fetched when the `config.window_size` was different and the workspace was non-default.
* Fixed an issue where a warn log was printed when `config.event_hooks` was disabled.
* Fixed an issue where, if multiple plugin instances sharing the same namespace enforced consumer groups and different `config.window_size`s were used in the consumer group overriding configs, then the rate limiting of some consumer groups would fall back to the `local` strategy. Now, every plugin instance sharing the same namespace can set a different `config.window_size`.
* Fixed an issue where the plugin could fail to authenticate to Redis correctly with vault-referenced Redis configuration.
* Fixed an issue where plugin-stored items with a long expiration time caused `no memory` errors.

### {{site.base_gateway}} 3.8.x
* Added the Redis `config.redis.cluster_max_redirections` configuration option.
* Timer spikes no longer occur when there is network instability with the central data store.
* Fixed an issue where, if the `config.window_size` in the consumer group overriding config was different 
  from the `config.window_size` in the default config, the rate limiting of that consumer group would fall back to local strategy.
* Fixed an issue where the sync timer could stop working due to a race condition.
* Fixed an issue where a warn log was printed when `event_hooks` was disabled.

### {{site.base_gateway}} 3.7.x
* Refactored `kong/tools/public/rate-limiting`, adding the new interface `new_instance` to provide isolation between different plugins. 
  The original interfaces remain unchanged for backward compatibility. 

  If you are using custom Rate Limiting plugins based on this library, update the initialization code to the new format. For example: 
  `'local ratelimiting = require("kong.tools.public.rate-limiting").new_instance("custom-plugin-name")'`.
  The old interface will be removed in the upcoming major release.

* Fixed an issue where any plugins using the `rate-limiting` library, when used together, 
  would interfere with each other and fail to synchronize counter data to the central data store.
* Fixed an issue with `config.sync_rate` setting being used with the `redis` strategy. 
  If the Redis connection is interrupted while `sync_rate = 0`, the plugin now accurately falls back to the `local` strategy.
* Fixed an issue where, if `config.sync_rate` was changed from a value greater than `0` to `0`, the namespace was cleared unexpectedly.
* Fixed some timer-related issues where the counter syncing timer couldn't be created or destroyed properly.
* The plugin now creates counter syncing timers during plugin execution instead of plugin creation to reduce some meaningless error logs.
* Fixed an issue where {{site.base_gateway}} produced a log of error log entries when multiple Rate Limiting Advanced plugins shared the same namespace.

### {{site.base_gateway}} 3.6.x
* Enhanced the resolution of the RLA sliding window weight.
* The plugin now checks for query errors in the Redis pipeline.
* The plugin now checks if `config.sync_rate` is `nil` or `null` when calling the `configure()` phase. 
If it is `nil` or `null`, the plugin skips the sync with the database or with Redis.

### {{site.base_gateway}} 3.4.x
* The `redis` strategy now catches strategy connection failures.
* The `/consumer_groups/:id/overrides` endpoint has been deprecated. While this endpoint will still function, we strongly recommend transitioning 
to managing consumer groups using the [Consumer Group entity](/gateway/entities/consumer-group/).
* Fixed an issue that impacted the accuracy with the `redis` policy.

### {{site.base_gateway}} 3.2.1
* The shared Redis connector now supports username + password authentication for cluster connections, improving on the existing single-node connection support. This automatically applies to all plugins using the shared Redis configuration.

### {{site.base_gateway}} 3.1.x
* Added the ability to customize the error code and message with
the configuration parameters `error_code` and `error_message`.

### {{site.base_gateway}} 3.0.x

* {{site.base_gateway}} now disallows enabling the plugin if the `cluster`
strategy is set with DB-less or hybrid mode.
* The default policy is now `local` for all deployment modes.
* Fixed error handling when calling `get_window` and added more buffer on the window reserve.
* Fixed error handling for plugin strategy configuration when in hybrid or DB-less mode and strategy is set to `cluster`.
* Fixed an issue where the sync timer could stop working due to a race condition.

### {{site.base_gateway}} 2.8.x
* Added the `redis.username` and `redis.sentinel_username` configuration parameters.
* The `redis.username`, `redis.password`, `redis.sentinel_username`, and `redis.sentinel_password`
configuration fields are now marked as referenceable, 
which means they can be securely stored as [secrets in a Vault](/gateway/entities/vault/). 
References must follow a specific format.
* Fixed an issue where any plugins using the `rate-limiting` library, when used together, 
would interfere with each other and fail to synchronize counter data to the central data store.
* Fixed an issue where, if `sync_rate` was set to `0` and the `redis` strategy was in use, 
the plugin did not properly revert to the `local` strategy if the Redis connection was interrupted.

### {{site.base_gateway}} 2.7.x
* Added the `enforce_consumer_groups` and `consumer_groups` configuration parameters.

### {{site.base_gateway}} 2.5.x
* Deprecated the `config.timeout` field and replaced it with three precise options: `config.connect_timeout`, `config.read_timeout`, and `config.send_timeout`.
* Added `config.redis.keepalive_pool`, `config.redis.keepalive_pool_size`, and `config.redis.keepalive_backlog` configuration options.
* `config.ssl_verify` and `config.server_name` configuration options now support Redis Sentinel-based connections.

### {{site.base_gateway}} 2.2.x
* Added the `config.redis.ssl`, `config.redis.ssl_verify`, and `config.redis.server_name` parameters for configuring TLS connections.
