---
content_type: reference
no_version: true
---

## Changelog

### {{site.base_gateway}} 3.6.x
* This plugin can now be scoped to Consumer Groups.

### {{site.base_gateway}} 3.1.x

* The plugin no longer allows setting `config.status_code` to `null`.

### {{site.base_gateway}} 2.6.x
* Added the `config.trigger` and `config.echo` configuration options.

### {{site.base_gateway}} 2.1.x
* There were changes in the plugin handler structure and on the plugins DAO (`load_plugin_schemas`) that make this plugin
backwards-incompatible if another plugin depended on it.
