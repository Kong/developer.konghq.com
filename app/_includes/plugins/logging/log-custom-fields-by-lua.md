{% assign custom_fields_by_lua = include.custom_fields_by_lua %}
{% assign custom_fields_by_lua_name = include.custom_fields_by_lua_name %}
{% assign custom_fields_by_lua_slug = include.custom_fields_by_lua_slug %}

The [`{{custom_fields_by_lua_name}}`](./reference/#schema--{{custom_fields_by_lua_slug}}) configuration allows for the dynamic modification of
log fields using Lua code. For example, here is a snippet of an example configuration that
removes the `route` field from the logs:

```sh
curl -i -X POST http://localhost:8001/plugins \
  --data config.name={{include.slug}} \
  --data {{custom_fields_by_lua}}.route="return nil"
```

Similarly, new fields can be added:

```sh
curl -i -X POST http://localhost:8001/plugins \
  --data config.name={{include.slug}} \
  --data {{custom_fields_by_lua}}.header="return kong.request.get_header('h1')"
```
