---
content_type: reference

---

## Changelog

### {{site.base_gateway}} 3.2.1.0

* This plugin can now handle custom messages from the OPA server.

### {{site.base_gateway}} 3.1.0.0

* Added the `include_uri_captures_in_opa_input` field. When this field is set to `true`, the regex capture groups captured on the {{site.base_gateway}} route’s path field in the current request (if any) are included as input to OPA.
* Removed redundant deprecated code from the plugin.

### {{site.base_gateway}} 3.0.0.0

* New configuration parameter `include_body_in_opa_input`: When enabled, include the raw body as a string in the OPA input at `input.request.http.body` and the body size at `input.request.http.body_size`.
* New configuration parameter `include_parsed_json_body_in_opa_input`: When enabled and content-type is `application/json`, the parsed JSON will be added to the OPA input at `input.request.http.parsed_body`.