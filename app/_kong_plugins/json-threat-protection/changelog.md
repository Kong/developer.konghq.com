---
content_type: reference

---

## Changelog

### {{site.base_gateway}} 3.10.x
* Added the schema field `allow_duplicate_object_entry_name` to allow or disallow duplicate object keys in JSON payloads. 
When set to `false`, the plugin will reject JSON payloads with duplicate object keys. 
The default value is `true`, which is same as the previous behavior.
* This plugin now accurately supports proxying for non-`POST/PUT/PATCH` requests.

### {{site.base_gateway}} 3.9.x
* Fixed an issue where the length counting of escape sequences, non-ASCII characters, and object entry names in JSON strings was incorrect. The plugin now uses UTF-8 character count instead of bytes.
* Fixed an issue where certain default parameter values were incorrectly interpreted as 0 in some environments (for example, ARM64-based):
    * `max_container_depth`
    * `max_object_entry_count`
    * `max_object_entry_name_length`
    * `max_array_element_count`
    * `max_string_value_length`

### {{site.base_gateway}} 3.8.x

* Introduced the new **JSON Threat Protection** plugin.

**Known issues**:
*  In the [JSON Threat Protection plugin](/plugins/json-threat-protection/reference/), the default value of `-1`
for any of the `max_*` parameters indicates unlimited.
In some environments (such as ARM64-based environments), the default value is interpreted incorrectly.
The plugin can erroneously block valid requests if any of the parameters continue with the default values.
To mitigate this issue, configure the JSON Threat Protection plugin with limits for all of the `max_*` parameters.