---
content_type: reference
no_version: true
---

## Changelog

### {{site.base_gateway}} 3.9.x
* Fixed an issue where the plugin could fail to authenticate to Redis correctly with Vault-referenced Redis configuration.

### {{site.base_gateway}} 3.8.x
* Added the Redis `config.redis.cluster_max_redirections` configuration option.

### {{site.base_gateway}} 3.5.x
* Fixed an issue where any plugins using the `rate-limiting` library, when used together, 
would interfere with each other and fail to synchronize counter data to the central data store.

### {{site.base_gateway}} 3.4.x
* The `config.host` field of this plugin now accepts {{site.base_gateway}} Upstream targets.
* The schema validation has been updated so that Redis cluster mode is now supported.

### {{site.base_gateway}} 3.3.x
* The Redis strategy now catches strategy connection failures.

### {{site.base_gateway}} 3.2.x
* In hybrid and DB-less modes, this plugin now supports `sync_rate = -1` with any strategy, including the default `cluster` strategy.

### {{site.base_gateway}} 2.8.x
* Added Redis ACL support (Redis v6.0.0+ and Redis Sentinel v6.2.0+).
* Added the `config.redis.username` and `config.redis.sentinel_username` configuration parameters.
* The `config.redis.username`, `config.redis.password`, `config.redis.sentinel_username`, and `config.redis.sentinel_password`
configuration fields are now marked as referenceable, which means they can be securely stored as [secrets in a Vault](/gateway/entities/vault/). 
References must follow a specific format.
* Fixed plugin versions in the documentation. Previously, the plugin versions
were labelled as `1.3-x` and `2.3.x`. They are now updated to align with the
plugin's actual versions, `0.1.x` and `0.2.x`.
* The plugin now returns a `500` error when using the `cluster` strategy in hybrid or DB-less modes instead of crashing.
* Fixed `deserialize_parse_tree` logic when building GraphQL AST with non-nullable or list types.

### {{site.base_gateway}} 2.5.x

* Added the `config.redis.keepalive_pool`, `config.redis.keepalive_pool_size`, and `config.redis.keepalive_backlog` configuration parameters.
 These options relate to [Openresty’s Lua INGINX module’s](https://github.com/openresty/lua-nginx-module/#tcpsockconnect) `tcp:connect` options.

### {{site.base_gateway}} 2.2.x

* Added Redis TLS support with the `config.redis.ssl`, `config.redis.ssl_verify`, and `config.redis.server_name` configuration parameters.
