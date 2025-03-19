---
content_type: reference

---

## Changelog

### {{site.base_gateway}} 3.9.x
* Fixed an issue where the returned values from `get_redis_connection()` were incorrect.
* Fixed an issue that caused an HTTP 500 error when `config.hide_client_headers` was set to `true` and the request exceeded the rate limit.

### {{site.base_gateway}} 3.8.x
* Fixed an issue where the DP would report that deprecated config fields were used when configuration was pushed from the CP.
* Fixed an issue that caused an HTTP 500 error when `hide_client_headers` was set to `true` and the request exceeded the rate limit.

### {{site.base_gateway}} 3.7.x
* Fixed migration of Redis configuration.

### {{site.base_gateway}} 3.6.x
* This plugin can now be scoped to consumer groups.
* Standardized Redis configuration across plugins. The Redis configuration now follows a common schema that is shared across other plugins.
* The plugin now provides better accuracy in counters when `config.sync_rate` is used with the Redis policy.
* Fixed an issue where all counters were synced to the same database at the same rate.

### {{site.base_gateway}} 3.1.x
* Added the ability to customize the error code and message with the configuration parameters `config.error_code` and `config.error_message`.

### {{site.base_gateway}} 3.0.x
* The default policy is now `local` for all deployment modes.
* Fixed a PostgreSQL deadlock issue that occurred when the `cluster` policy was used with two or more metrics (for example, `second` and `day`.)

### {{site.base_gateway}} 2.8.x
* Added the `config.redis_username` configuration parameter.
* Fixed an issue where any plugins using the `rate-limiting` library, when used together, 
  would interfere with each other and fail to synchronize counter data to the central data store.
* Dismissed confusing log entry from Redis regarding rate limiting.
* Fixed a 500 error associated with performing arithmetic functions on a nil
  value by adding a nil value check after performing `ngx.shared.dict` operations.

### {{site.base_gateway}}  2.7.x
* Added the `config.redis_ssl`, `config.redis_ssl_verify`, and `config.redis_server_name` configuration parameters.
