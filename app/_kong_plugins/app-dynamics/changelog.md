---
content_type: reference
---

## Changelog

### {{site.base_gateway}} 3.9.x

* Fixed an issue where the `snapshot` of the fields `upstream`, `service`, `route`, and `consumer` was missing in the AppDynamics plugin.

### {{site.base_gateway}} 3.8.x

* Added a new `KONG_APPD_ANALYTICS_ENABLE` flag. This plugin now also collects more snapshot user data in runtime.

### {{site.base_gateway}} 3.6.x
* This plugin now supports using self-signed certificates via the `KONG_APPD_CONTROLLER_CERTIFICATE_FILE`
and `KONG_APPD_CONTROLLER_CERTIFICATE_DIR` environment configuration options.

### {{site.base_gateway}} 3.1.x
* Introduced the new **AppDynamics** plugin.