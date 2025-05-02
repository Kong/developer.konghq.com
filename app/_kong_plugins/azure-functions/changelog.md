---
content_type: reference

---

## Changelog

### {{site.base_gateway}} 3.6.x

* The Azure Functions plugin now eliminates the upstream/request URI and only uses the [`routeprefix`](/plugins/azure-functions/reference/#schema--config-routeprefix) 
configuration field to construct the request path when requesting the Azure API.

### {{site.base_gateway}} 3.1.x
* Fixed an issue where calls made by this plugin would fail in the following situations:
    * The plugin was associated with a route that had no service.
    * The route's associated service had a `path` value.

### {{site.base_gateway}} 2.7.x

* Starting with {{site.base_gateway}} 2.7.0.0, if keyring encryption is enabled,
 the `config.apikey` and `config.clientid` parameter values will be encrypted.
