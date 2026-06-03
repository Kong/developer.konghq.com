---
title: Streaming custom plugins
content_type: reference
layout: reference

breadcrumbs:
  - /custom-plugins/

products:
    - gateway

works_on:
    - konnect
    - on-prem

description: "Define custom plugin logic directly in {{site.base_gateway}} configuration and have it distributed to all data planes automatically."
tags:
  - custom-plugins

min_version:
  gateway: '3.15'

related_resources:
  - text: Custom plugins
    url: /custom-plugins/
  - text: Custom plugins reference
    url: /custom-plugins/reference/
  - text: Installation and distribution
    url: /custom-plugins/installation-and-distribution/
  - text: Deployment options
    url: /custom-plugins/deployment-options/
---

You can define a custom plugin directly in Kong entity configuration.

## How does custom plugin streaming work? 

{{site.base_gateway}} can stream custom plugins from the control plane to the data plane. 
The control plane becomes the single source of truth for plugin versions. You only need to define the plugin once, and {{site.base_gateway}} handles distribution to all data planes in the same control plane.

A streamed custom plugin must meet the following requirements: 
* Unique name per plugin
* One plugin `handler` and one `schema`
* Cannot run in the `init_worker` phase or create timers
* Must be written in Lua

You can also define streaming plugins in traditional or DB-less mode.
In these modes, the plugin is defined in the entity configuration directly, and no separate files are needed.

## Streaming plugin limitations

Keep the following custom plugin limitations in mind for streaming plugins:

* Only `schema.lua` and `handler.lua` are supported. Plugin logic must be self-contained in these two modules.
You can't use DAOs, custom APIs, migrations, or multiple Lua modules.
* Custom modules cannot be required when plugin sandboxing is enabled. External Lua files or shared libraries can't be loaded.
* Custom validation must be implemented in `handler.lua`, not `schema.lua`. In `handler.lua`, it can be logged and handled as part of plugin business logic.
* Plugins can't read/write to the {{site.base_gateway}} filesystem.

## How do I add a streamed plugin?

{% navtabs 'streaming' %}
{% navtab "Admin API" %}

You can add custom plugins using the `/custom-plugins` Admin API endpoint.
If your schema and handler are in separate files, you can use [jq](https://jqlang.org/) to build the request:

```bash
curl -X POST http://localhost:8001/custom-plugins \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
      --arg name "my-example-plugin" \
      --arg handler "$(cat handler.lua)" \
      --arg schema "$(cat schema.lua)" \
      '{"name":$name,"handler":$handler,"schema":$schema}')"
```

Or pass the schema and handler inline:

```bash
curl -X POST http://localhost:8001/custom-plugins \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-example-plugin",
    "schema": "SCHEMA_LUA",
    "handler": "HANDLER_LUA"
  }'
```

{% endnavtab %}
{% navtab "Konnect API" %}

You can use [jq](https://jqlang.org/) with the following request template to add the plugin using the `/custom-plugins` Control Plane Config API endpoint:

```bash
curl -X POST $KONNECT_CONTROL_PLANE_URL/v2/control-planes/$CONTROL_PLANE_ID/core-entities/custom-plugins \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $KONNECT_TOKEN" \
  -d "$(jq -n \
      --arg name "my-example-plugin" \
      --arg handler "$(cat handler.lua)" \
      --arg schema "$(cat schema.lua)" \
      '{"name":$name,"handler":$handler,"schema":$schema}')" \
    | jq
```

{% endnavtab %}
{% navtab "decK" %}
```yaml
_format_version: "3.0"
custom_plugins:
 - name: my-example-plugin
   schema: |
    return {
      name = "my-example-plugin",
      fields = {
        {
          config = {
            type = "record",
            fields = {
              { example_field = { type = "string", required = true } },
              { another_example_field = { type = "string", required = true } },
            },
          },
        },
      },
    }
   handler: |
    local MyPluginHandler = {
      PRIORITY = 1000,
      VERSION = "0.0.1",
    }

    return MyPluginHandler
```
{% endnavtab %}
{% endnavtabs %}

Once added to configuration, you can manage custom plugins using any of the following methods:
* [decK](/deck/)
* [Control Plane Config API](/api/konnect/control-planes-config/v2/)
* [{{site.konnect_short_name}} UI](https://cloud.konghq.com/)

For example:

```yaml
plugins:
  - name: my-example-plugin
    condition: '!http.path.contains("something")'
    config:
      example_field: foo
      another_example_field: bar
```

For a complete end-to-end tutorial, see [Stream {{site.base_gateway}} plugins](/how-to/stream-custom-plugins/).