---
content_type: reference

---

## Changelog

### {{site.base_gateway}} 3.8.x
* Fixed an issue where the Data Plane would report that deprecated config fields were used when configuration was pushed from the Control Plane.

### {{site.base_gateway}} 3.7.x
* Fixed migration of Redis configuration.

### {{site.base_gateway}} 3.6.x

* Standardized Redis configuration across plugins.
 The Redis configuration now follows a common schema that is shared across other plugins.

### {{site.base_gateway}} 3.5.x

* Added support for secret rotation with Redis connections. 

### {{site.base_gateway}}  3.1.x

* Added the `config.redis_ssl`, `config.redis_ssl_verify`, and `config.redis_server_name` configuration parameters.

### {{site.base_gateway}} 2.8.x

* Added the `config.redis_username` configuration parameter.
