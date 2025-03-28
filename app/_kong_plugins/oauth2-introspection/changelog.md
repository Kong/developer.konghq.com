---
content_type: reference

---

## Changelog

### {{site.base_gateway}} 3.8.x
* Fixed an issue where the Consumer's cache couldn't be invalidated when the OAuth2 Introspection plugin used `client_id` as `config.consumer_by`.

### {{site.base_gateway}} 3.6.x
* Added support for Consumer Group scoping by using the PDK `kong.client.authenticate` function.
* The `config.authorization_value` configuration parameter can now be encrypted.

### {{site.base_gateway}} 3.4.x
* Fixed an issue where the plugin failed when processing a request with JSON that is not a table.

### {{site.base_gateway}} 3.0.x
* The deprecated `X-Credential-Username` header has been removed.