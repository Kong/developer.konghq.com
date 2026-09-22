{% assign custom_fields_by_lua = include.custom_fields_by_lua %}
{% assign custom_fields_by_lua_name = include.custom_fields_by_lua_name %}
{% assign custom_fields_by_lua_slug = include.custom_fields_by_lua_slug %}

All logging plugins use the same table for logging.
If you set `{{custom_fields_by_lua_name}}` in one plugin, all logging plugins that execute after that plugin will also use the same configuration.
For example, if you configure fields via `{{custom_fields_by_lua_name}}` in File Log, those same fields will appear in [Syslog](/plugins/syslog/), since {{page.name}} executes first.

* If you want all logging plugins to use the same configuration, we recommend using the [Pre-function](/plugins/pre-function/) plugin to call [kong.log.set_serialize_value](/gateway/pdk/reference/kong.log/#kong-log-set-serialize-value-key-value-options) so that the function is applied predictably and is easier to manage.

* If you **don't** want all logging plugins to use the same configuration, you need to manually disable the relevant fields in each plugin.

   For example, if you configure a field in File Log that you don't want appearing in Syslog, set that field to `return nil` in the File Log plugin:

   ```sh
   curl -i -X POST http://localhost:8001/plugins/ \
   ...
     --data config.name={{include.slug}} \
    --data {{custom_fields_by_lua}}.my_file_log_field="return nil"
   ```

See the [plugin execution order reference](/gateway/entities/plugin/#plugin-contexts) for more details on plugin ordering.