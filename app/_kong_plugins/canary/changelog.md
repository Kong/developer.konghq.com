---
content_type: reference

---

## Changelog

### {{site.base_gateway}} 3.5.x
* Removed the custom validator for `config.start` to allow setting it to a past time.

### {{site.base_gateway}} 3.2.x
* The `config.start` field now defaults to the current timestamp.

### {{site.base_gateway}} 3.0.x
* The priority of the Canary plugin changed from 13 to 20.

### {{site.base_gateway}} 2.8.x
* Added the `config.canary_by_header_name` configuration parameter.

### {{site.base_gateway}} 2.1.x
* Use `allow` and `deny` instead of `whitelist` and `blacklist` in the `config.groups` parameter.
* Added the `config.hash_header` configuration parameter.
