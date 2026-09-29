{% assign custom_fields_by_lua = include.custom_fields_by_lua %}
{% assign custom_fields_by_lua_name = include.custom_fields_by_lua_name %}
{% assign custom_fields_by_lua_slug = include.custom_fields_by_lua_slug %}

Array indices should be enclosed within square brackets. For example:

```sh
curl -i -X POST http://localhost:8001/plugins \
  --header 'Accept: application/json' \
  --header 'Content-Type: application/json' \
  --data '{
  "name": "{{include.slug}}",
  "config": {
    "{{custom_fields_by_lua_name}}": {
      "foo[1].bar[2].woo": "return 456"
    }
  }
}'
```

Array indices only support positive integers.