---
title: schema.lua
content_type: reference
layout: reference

breadcrumbs:
  - /custom-plugins/
  - /custom-plugins/reference/

products:
    - gateway

works_on:
    - konnect
    - on-prem

description: Learn how to enable plugin configuration options using schema.lua.

tags:
  - custom-plugins

min_version:
  gateway: '3.4'

related_resources:
  - text: Custom plugins
    url: /custom-plugins/
  - text: Custom plugins reference
    url: /custom-plugins/reference/
  - text: handler.lua reference
    url: /custom-plugins/handler.lua/
---

Most of the time, it makes sense for your plugin to be configurable to answer
all of your users' needs. Your plugin's configuration is stored in the
data store for {{site.base_gateway}} to retrieve it and pass it to your
[handler.lua](/custom-plugins/handler.lua/) methods when the plugin is
being executed.

The configuration consists of a Lua table, in what we call a schema. It
contains key/value properties that the user will set when enabling the plugin.
{{site.base_gateway}} provides you with a way of validating the user's
configuration for your plugin.

Your plugin's configuration is verified against your schema when a user
enables or updates a plugin.

For example, when a user performs the following request:
```bash
curl -X POST http://localhost:8001/services/{service-name-or-id}/plugins \
  -d "name=my-custom-plugin" \
  -d "config.foo=bar"
```

If all properties of the `config` object are valid according to your schema,
then the API would return `201 Created` and the plugin would be stored in the
database along with its configuration:
```lua
{
  foo = "bar"
}
 ```

If the configuration is not valid, the Admin API would return `400 Bad Request`
and the appropriate error messages.

## schema.lua specification

This module is to return a Lua table with properties that will define how your
plugins can later be configured by users. Available properties are:

{% table %}
columns:
  - title: Name
    key: name
  - title: Lua type
    key: type
  - title: Description
    key: description
rows:
  - name: "`name`"
    type: "`string`"
    description: |
      Name of the plugin, for example: `key-auth`.
  - name: "`fields`"
    type: "`table`"
    description: Array of field definitions.
  - name: "`entity_checks`"
    type: "`function`"
    description: Array of conditional entity level validation checks.
{% endtable %}


All the plugins inherit some default fields which are:

{% table %}
columns:
  - title: Name
    key: name
  - title: Lua type
    key: type
  - title: Description
    key: description
rows:
  - name: "`id`"
    type: "`string`"
    description: Auto-generated plugin ID.
  - name: "`name`"
    type: "`string`"
    description: Name of the plugin.
  - name: "`created_at`"
    type: "`number`"
    description: Creation time of the plugin configuration (seconds from epoch).
  - name: "`route`"
    type: "`table`"
    description: Route to which plugin is bound, if any.
  - name: "`service`"
    type: "`table`"
    description: Service to which plugin is bound, if any.
  - name: "`consumer`"
    type: "`table`"
    description: Consumer to which plugin is bound when possible, if any.
  - name: "`protocols`"
    type: "`table`"
    description: Protocols on which the plugin will run.
  - name: "`enabled`"
    type: "`boolean`"
    description: Whether or not the plugin is enabled.
  - name: "`tags`"
    type: "`table`"
    description: Tags for the plugin.
{% endtable %}

In most of the cases you can ignore most of those and use the defaults or let the user
specify value when enabling a plugin.

Here is an example of a potential `schema.lua` file (with some overrides applied):

```lua
local typedefs = require "kong.db.schema.typedefs"


return {
  name = "<plugin-name>",
  fields = {
    {
      -- this plugin will only be applied to Services or Routes
      consumer = typedefs.no_consumer
    },
    {
      -- this plugin will only run within Nginx HTTP module
      protocols = typedefs.protocols_http
    },
    {
      config = {
        type = "record",
        fields = {
          -- Describe your plugin's configuration's schema here.
        },
      },
    },
  },
  entity_checks = {
    -- Describe your plugin's entity validation rules
  },
}
```

## Describe your configuration schema

The `config.fields` property of your `schema.lua` file describes the schema of your
plugin's configuration. It's a flexible array of field definitions where each field
is a valid configuration property for your plugin, describing the rules for that
property. For example:

```lua
{
  name = "<plugin-name>",
  fields = {
    config = {
      type = "record",
      fields = {
        {
          some_string = {
            type = "string",
            required = false,
          },
        },
        {
          some_boolean = {
            type = "boolean",
            default = false,
          },
        },
        {
          some_array = {
            type = "array",
            elements = {
              type = "string",
              one_of = {
                "GET",
                "POST",
                "PUT",
                "DELETE",
              },
            },
          },
        },
      },
    },
  },
}
```

Here is a list of commonly used rules for a property:
{% table %}
columns:
  - title: Rule
    key: rule
  - title: Description
    key: description
rows:
  - rule: "`type`"
    description: The type of a property.
  - rule: "`required`"
    description: Whether or not the property is required.
  - rule: "`default`"
    description: The default value for the property when not specified.
  - rule: "`elements`"
    description: The field definition of `array` or `set` elements.
  - rule: "`keys`"
    description: The field definition of `map` keys.
  - rule: "`values`"
    description: The field definition of `map` values.
  - rule: "`fields`"
    description: The field definition(s) of `record` fields.
{% endtable %}

You can also add field validators, for example:
{% table %}
columns:
  - title: Rule
    key: rule
  - title: Description
    key: description
rows:
  - rule: "`between`"
    description: Checks that the input number is between allowed values.
  - rule: "`eq`"
    description: Checks the equality of the input to allowed value.
  - rule: "`ne`"
    description: Checks the inequality of the input to allowed value.
  - rule: "`gt`"
    description: Checks that the number is greater than given value.
  - rule: "`len_eq`"
    description: Checks that the input string length is equal to the given value.
  - rule: "`len_min`"
    description: Checks that the input string length is at least the given value.
  - rule: "`len_max`"
    description: Checks that the input string length is at most the given value.
  - rule: "`match`"
    description: Checks that the input string matches the given Lua pattern.
  - rule: "`not_match`"
    description: Checks that the input string doesn't match the given Lua pattern.
  - rule: "`match_all`"
    description: Checks that the input string matches all the given Lua patterns.
  - rule: "`match_none`"
    description: Checks that the input string doesn't match any of the given Lua patterns.
  - rule: "`match_any`"
    description: Checks that the input string matches any of the given Lua patterns.
  - rule: "`starts_with`"
    description: Checks that the input string starts with a given value.
  - rule: "`one_of`"
    description: Checks that the input string is one of the accepted values.
  - rule: "`contains`"
    description: Checks that the input array contains the given value.
  - rule: "`is_regex`"
    description: Checks that the input string is a valid regex pattern.
  - rule: "`custom_validator`"
    description: A custom validation function written in Lua.
{% endtable %}

## Making a field expressible {% new_in 3.16 %}

A `string`, `number`, `integer`, or `boolean` field, or an `array`/`map` whose elements or values are one of those scalar types, can be marked `expressible = true`:

```lua
{
  limit = {
    type = "number",
    gt = 0,
    expressible = true,
  },
},
```

This lets an operator pair the field with a [CEL expression](/gateway/plugins/expressible-fields/), evaluated per request, alongside the field's ordinary static `config` value. 
{{site.base_gateway}} derives the paired `expressions.FIELD` entry from this attribute automatically. 
You don't define it yourself, and you don't need any additional code in `handler.lua` to support it.

`record` fields can't be marked expressible, and neither can an `array` or `map` of them. Kong rejects this when your plugin's schema loads.

For the full mechanism, including how the static value acts as a fallback and how array fields work, see [Dynamic plugin config with CEL](/gateway/plugins/expressible-fields/).

### Security guidance for expressible fields

Marking a field expressible has security implications the framework doesn't check for you. Before adding `expressible = true` to a field, review the following considerations.

#### Is the field's static value already safe as a fallback?

{{site.base_gateway}} falls back to a field's static `config` value automatically whenever its expression fails to evaluate on a CEL error, a `null` result, or a type or constraint mismatch. 
This fallback is unconditional. A plugin can't opt out of it.

A client can trigger this fallback deliberately by sending a request shaped to make the expression error or produce the wrong type. 
That means a field's static value is also its worst-case runtime value once the field is expressible.
If a permissive static value would be unsafe, marking the field expressible makes that value reachable from ordinary request traffic, not just from an Admin API misconfiguration.

Here are examples of a safe vs an unsafe approach:
* **Safe approach**: [Rate Limiting Advanced](/plugins/rate-limiting-advanced/)'s `limit` field requires `gt = 0`, so a forced fallback always lands on the operator's own configured limit, never zero, negative, or unbounded.
* **Unsafe approach**: A boolean gating field, for example `bypass_check` or `skip_verification`, where `false` is the safe default and `true` disables an enforcement step. If a forced fallback could land on `true`, a client could force that fallback and skip the check the field is meant to gate. Before marking a field like this expressible, make sure every failure path lands on the restrictive value, or don't mark it expressible at all.

Before shipping, ask: if every expression on this field failed on every request, would you be comfortable with the resulting behavior as the field's permanent default? If not, fix the field's static semantics first.

#### Are the exposed CEL variables safe to drive this field?

An expressible field's expression can reference any of the available CEL variables, including request data such as `http.headers.*` and `http.queries.*`. 
That data is controlled by the client by definition. A client can set it to anything, including a value chosen specifically to collide with, spoof, or evade another client's.

This matters most for a field that keys, identifies, or scopes something for a specific client, such as a counter key, a quota bucket, or an identity binding. 
If your field falls into that category, document which CEL variables are safe to reference and which aren't:

* **Safe example**: Authenticated, identity-derived values, such as `principal.id` or `principal.metadata.*`. A client can't forge them without first compromising the authentication step itself.
* **Unsafe example**: Raw request data, such as `http.headers.*` or `http.queries.*`, used as the sole input to anything identity-related. Any client can set it to any value, including another client's.

This isn't a risk expressible fields introduce on their own. 
Making a field expressible just lets an operator express an unsafe choice as a formula instead of a fixed value. Document the risk the same way you would for a static field, rather than assume the operator will guess right.

## Examples

This `schema.lua` file is for the [key-auth](/plugins/key-auth/) plugin:

```lua
-- schema.lua
local typedefs = require "kong.db.schema.typedefs"


return {
  name = "key-auth",
  fields = {
    {
      consumer = typedefs.no_consumer
    },
    {
      protocols = typedefs.protocols_http
    },
    {
      config = {
        type = "record",
        fields = {
          {
            key_names = {
              type = "array",
              required = true,
              elements = typedefs.header_name,
              default = {
                "apikey",
              },
            },
          },
          {
            hide_credentials = {
              type = "boolean",
              default = false,
            },
          },
          {
            anonymous = {
              type = "string",
              uuid = true,
            },
          },
          {
            key_in_body = {
              type = "boolean",
              default = false,
            },
          },
          {
            run_on_preflight = {
              type = "boolean",
              default = true,
            },
          },
        },
      },
    },
  },
}
```

When implementing the `access()` function of your plugin in
[handler.lua](/custom-plugins/handler.lua/) and given that the user
enabled the plugin with the default values, you'd have access to:

```lua
-- handler.lua

local CustomHandler = {
  VERSION  = "1.0.0",
  PRIORITY = 10,
}

local kong = kong

function CustomHandler:access(config)

  kong.log.inspect(config.key_names)        -- { "apikey" }
  kong.log.inspect(config.hide_credentials) -- false
end


return CustomHandler
```

The above example uses the [kong.log.inspect](/gateway/pdk/reference/kong.log/#kong-log-inspect)
function of the [Plugin Development Kit](/gateway/pdk/reference/) to print out those values to the {{site.base_gateway}}
logs.

A more complex example, which could be used for an eventual logging plugin:

```lua
-- schema.lua
local typedefs = require "kong.db.schema.typedefs"


return {
  name = "my-custom-plugin",
  fields = {
    {
      config = {
        type = "record",
        fields = {
          {
            environment = {
              type = "string",
              required = true,
              one_of = {
                "production",
                "development",
              },
            },
          },
          {
            server = {
              type = "record",
              fields = {
                {
                  host = typedefs.host {
                    default = "example.com",
                  },
                },
                {
                  port = {
                    type = "number",
                    default = 80,
                    between = {
                      0,
                      65534
                    },
                  },
                },
              },
            },
          },
        },
      },
    },
  },
}
```

Such a configuration will allow a user to post the configuration to your plugin
as follows:

```bash
curl -X POST http://localhost:8001/services/<service-name-or-id>/plugins \
  -d "name=my-custom-plugin" \
  -d "config.environment=development" \
  -d "config.server.host=http://localhost"
```

And the following will be available in [handler.lua](/custom-plugins/handler.lua/):

```lua
-- handler.lua

local CustomHandler = {
  VERSION  = "1.0.0",
  PRIORITY = 10,
}

local kong = kong

function CustomHandler:access(config)

  kong.log.inspect(config.environment) -- "development"
  kong.log.inspect(config.server.host) -- "http://localhost"
  kong.log.inspect(config.server.port) -- 80
end


return CustomHandler
```

You can also see a real-world example of schema in [the Key-Auth plugin source code](https://github.com/Kong/kong/blob/master/kong/plugins/key-auth/schema.lua).