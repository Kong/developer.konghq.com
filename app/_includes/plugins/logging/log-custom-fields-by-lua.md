The `custom_fields_by_lua` configuration allows for the dynamic modification of
log fields using Lua code. Below is a snippet of an example configuration that 
removes the `route` field from the logs:

```sh
curl -i -X POST http://localhost:8001/plugins \
... 
  --data config.custom_fields_by_lua.route="return nil"
```

Similarly, new fields can be added:

```sh
curl -i -X POST http://localhost:8001/plugins \
... 
  --data config.custom_fields_by_lua.header="return kong.request.get_header('h1')"
```

### Special characters {% new_in 3.10 %}

Dot characters (`.`) in the field key create nested fields. You can use a backslash `\` to escape a dot if you want to keep it in the field name.

For example, if you configure a field in the File Log plugin with both a regular dot and an escaped dot:

```sh
curl -i -X POST http://localhost:8001/plugins/ \
...
  --data config.name=file-log \
  --data config.custom_fields_by_lua[my_file.log\.field]="return foo"
```
The field will look like this in the log:
```sh
"my_file": {
  "log.field": "foo"
}
```

### Plugin precedence and managing fields

All logging plugins use the same table for logging. 
If you set `custom_fields_by_lua` in one plugin, all logging plugins that execute after that plugin will also use the same configuration. 
For example, if you configure fields via `custom_fields_by_lua` in [File Log](/plugins/file-log/), those same fields will appear in [Kafka Log](/plugins/kafka-log/), since File Log executes first.

If you want all logging plugins to use the same configuration, we recommend using the [Pre-function](/plugins/pre-function/) plugin to call [kong.log.set_serialize_value](/gateway/pdk/reference/kong.log/#kong-log-set-serialize-value-key-value-options) so that the function is applied predictably and is easier to manage.

If you **don't** want all logging plugins to use the same configuration, you need to manually disable the relevant fields in each plugin. 

For example, if you configure a field in File Log that you don't want appearing in Kafka Log, set that field to `return nil` in the Kafka Log plugin:

```sh
curl -i -X POST http://localhost:8001/plugins/ \
...
  --data config.name=kafka-log \
  --data config.custom_fields_by_lua.my_file_log_field="return nil"
```

See the [plugin execution order reference](/gateway/entities/plugin/#plugin-contexts) for more details on plugin ordering.

### Limitations

Lua code runs in a restricted sandbox environment, whose behavior is governed
by the `untrusted_lua` [configuration properties](/gateway/configuration/).

{% include /plugins/sandbox.md %}

Further, as code runs in the context of the log phase, only [PDK](/gateway/pdk/reference/) methods
that can run in said phase can be used.
