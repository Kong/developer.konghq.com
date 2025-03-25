---
content_type: reference

---

## Changelog

### {{site.base_gateway}} 3.8.x
* Added the Redis `config.redis.cluster_max_redirections` configuration option.
* Fixed an issue where the Age header was not being updated correctly when serving cached requests.
* The following parameters have been deprecated:
  * `config.redis.cluster_addresses` has been deprecated and replaced by `config.redis.cluster_nodes`.
  * `config.redis.sentinel_addresses` has been deprecated and replaced by `config.redis.sentinel_nodes`.
  * The `config.timeout` config field in Redis configuration has been deprecated and 
  replaced with `config.connect_timeout`, `config.send_timeout`, and `config.read_timeout`. 
  The deprecated `config.timeout` field will be removed in an upcoming major version.

### {{site.base_gateway}} 3.6.x
* This plugin can now be scoped to Consumer Groups.
* Removed the undesired `proxy-cache-advanced/migrations/001_035_to_050.lua` file, which blocked migration from OSS to Enterprise. 
This is a breaking change only if you are upgrading from a {{site.base_gateway}} version between `0.3.5` and `0.5.0`.

### {{site.base_gateway}} 3.3.x
* Added the `config.ignore_uri_case` configuration parameter.
* Added wildcard and parameter match support for `config.content_type`.

### {{site.base_gateway}} 3.1.x
* Added support for integrating with Redis clusters using the `config.redis.cluster_addresses` configuration parameter.
* The plugin now catches the error when {{site.base_gateway}} connects to Redis SSL port `6379` with `config.ssl=false`.

### {{site.base_gateway}} 2.8.x

* Added Redis ACL support (Redis v6.0.0+ and Redis Sentinel v6.2.0+).
* Added the `config.redis.sentinel_username` and `config.redis.sentinel_password` configuration
parameters.
* The `config.redis.password`, `config.redis.sentinel_username`, and `config.redis.sentinel_password`
configuration fields are now marked as referenceable, 
hich means they can be securely stored as [secrets in a Vault](/gateway/entities/vault/). 
References must follow a specific format.
* Fixed the error `function cannot be called in access phase (only in: log)`, 
which was preventing the plugin from working consistently.
* Fixed a `X-Cache-Status:Miss` error that occurred when caching large files.
* Fixed plugin versions in the documentation. Previously, the plugin versions
were labelled as `1.3-x` and `2.2.x`. They are now updated to align with the
plugin's actual versions, `0.4.x` and `0.5.x`.