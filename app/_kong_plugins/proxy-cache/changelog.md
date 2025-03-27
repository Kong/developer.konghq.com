---
content_type: reference

---

## Changelog

### {{site.base_gateway}} 3.8.x
* Fixed an issue where the Age header was not being updated correctly when serving cached responses.

### {{site.base_gateway}} 3.6.x
* This plugin can now be scoped to Consumer Groups.

### {{site.base_gateway}} 3.3.x
* Added wildcard and parameter match support for `config.content_type`.
* Added the configuration parameter `config.ignore_uri_case` to allow handling the cache key URI as lowercase.

### {{site.base_gateway}} 3.0.x
* This plugin doesn't store response data in `ngx.ctx.proxy_cache_hit` anymore.
Logging plugins that need the response data must now read it from `kong.ctx.shared.proxy_cache_hit`.