---
content_type: reference
---

## Changelog

### {{site.base_gateway}} 3.3.x

* `kong.cache` now points to a cache instance that is dedicated to the Serverless Functions plugins. 
It does not provide access to the global {{site.base_gateway}} cache. 
Access to certain fields in `kong.conf` has also been restricted.

### {{site.base_gateway}} 3.0.x

* The deprecated `config.functions` parameter has been removed from the plugin.
Use `config.access` instead.

### {{site.base_gateway}} 2.3.x

* Introduced sandboxing, which is enabled by default.
Only the Kong PDK, OpenResty `ngx` APIs, and Lua standard libraries are allowed.
To change the default setting, see the [`untrusted_lua`](/gateway/configuration/#untrusted_lua) parameter in `kong.conf`.

  This change was also introduced into previous releases through patch versions: 1.5.0.9, 2.1.4.3, and 2.2.1.0.