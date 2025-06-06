---
#
#  WARNING: this file was auto-generated by a script.
#  DO NOT edit this file directly. Instead, send a pull request to change
#  https://github.com/Kong/kong/tree/master/autodoc/pdk/ldoc/ldoc.ltp
#  or its associated files
#
title: kong.telemetry.log
source_url: https://github.com/Kong/kong/tree/master/kong/pdk
---

The telemetry module provides capabilities for telemetry operations.



## kong.telemetry.log(plugin_name, plugin_config, message_type, message, attributes)

Records a structured log entry, to be reported via the OpenTelemetry plugin.

 This function has a dependency on the OpenTelemetry plugin, which must be
 configured to report OpenTelemetry logs.


**Phases**

* `rewrite`, `access`, `balancer`, `timer`, `header_filter`,
         `response`, `body_filter`, `log`

**Parameters**

* **plugin_name** (`string`):  the name of the plugin
* **plugin_config** (`table`):  the plugin configuration
* **message_type** (`string`):  the type of the log message, useful to categorize
         the log entry
* **message** (`string`):  the log message
* **attributes** (`table`):  structured information to be included in the
         `attributes` field of the log entry

**Usage**

``` lua
local attributes = {
  http_method = kong.request.get_method()
  ["node.id"] = kong.node.get_id(),
  hostname = kong.node.get_hostname(),
}

local ok, err = kong.telemetry.log("my_plugin", conf, "result", "successful operation", attributes)
```


