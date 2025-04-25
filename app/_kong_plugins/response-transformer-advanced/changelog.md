---
content_type: reference

---

## Changelog

### {{site.base_gateway}} 3.3.1.1
* The plugin no longer loads the response body when `if_status` doesn’t match the provided status.

### {{site.base_gateway}} 2.8.1.3
* Fixed an issue with nested array parsing.

### {{site.base_gateway}} 2.8.0.0
* The plugin now uses response buffering from the PDK.
* In the `body_filter` phase, the plugin now sets the body to an empty string instead of `nil`.