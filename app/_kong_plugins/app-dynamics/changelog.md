---
content_type: reference
no_version: true
---

## Changelog

### {{site.base_gateway}} 3.9.x

* Fixed an issue where the `snapshot` of the fields `upstream`, `service`, `route`, and `consumer` was missing in the AppDynamics plugin.

### {{site.base_gateway}} 3.8.x

* Added a new `ANALYTICS_ENABLE` flag. This plugin now also collects more snapshot user data in runtime.

### {{site.base_gateway}} 3.6.x
* This plugin now supports using self-signed certificates via the `CONTROLLER_CERTIFICATE_FILE`
and `CONTROLLER_CERTIFICATE_DIR` environment configuration options.

### {{site.base_gateway}} 3.1.x
* Introduced the new **AppDynamics** plugin.