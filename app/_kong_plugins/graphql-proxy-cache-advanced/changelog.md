---
content_type: reference

---

## Changelog

### {{site.base_gateway}} 3.8.x
* Added the Redis `config.redis.cluster_max_redirections` configuration option.
* The following parameters have been deprecated:
  * `config.redis.cluster_address` has been deprecated and replaced by `config.redis.cluster_nodes`.
  * `config.redis.sentinel_cluster` has been deprecated and replaced by `config.redis.sentinel_nodes`.
  * `config.redis.timeout` has been deprecated and replaced with `config.redis.connect_timeout`, `config.redis.send_timeout`, and `config.redis.read_timeout`. 

### {{site.base_gateway}} 3.7.x
* Added Redis strategy support.
* Added the ability to resolve unhandled errors with bypass, with the request going upstream. 
Enable it using the `config.bypass_on_err` configuration option.

### {{site.base_gateway}} 2.8.x
* Fixed the error `function cannot be called in access phase (only in: log)`, which was preventing the plugin from working consistently.