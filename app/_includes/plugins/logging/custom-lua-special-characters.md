{% assign custom_fields_by_lua = include.custom_fields_by_lua %}
{% assign custom_fields_by_lua_name = include.custom_fields_by_lua_name %}
{% assign custom_fields_by_lua_slug = include.custom_fields_by_lua_slug %}

Dot characters (`.`) in the field key create nested fields. You can use a backslash `\` to escape a dot if you want to keep it in the field name.

For example, if you configure a field with both a regular dot and an escaped dot:

```sh
curl -i -X POST http://localhost:8001/plugins/ \
...
  --data config.name={{include.slug}} \
  --data {{custom_fields_by_lua}}.[my_entry.log\.field]="return foo"
```
The field will look like this in the log:
```sh
"my_entry": {
  "log.field": "foo"
}
```