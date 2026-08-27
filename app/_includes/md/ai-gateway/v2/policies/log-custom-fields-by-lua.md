<!---shared with AI Gateway logging Policies: http-log, file-log, syslog, tcp-log, udp-log, loggly, kafka-log, solace-log --->

The [`config.custom_fields_by_lua`](/ai-gateway/policies/{{include.slug}}/reference/#schema--config-custom-fields-by-lua) configuration lets you dynamically modify log fields using Lua code. The following example configuration removes the `route` field from the logs:

{% entity_example %}
type: policy
data:
  display_name: "{{include.name}} - Remove Field"
  name: {{include.slug}}
  type: {{include.slug}}
  config:
    {{include.base_config}}
    custom_fields_by_lua:
      route: "return nil"
formats:
  - konnect-api
  - kongctl
{% endentity_example %}

New fields can be added the same way:

{% entity_example %}
type: policy
data:
  display_name: "{{include.name}} - Add Field"
  name: {{include.slug}}
  type: {{include.slug}}
  config:
    {{include.base_config}}
    custom_fields_by_lua:
      header: "return kong.request.get_header('h1')"
formats:
  - konnect-api
  - kongctl
{% endentity_example %}

Dot characters (`.`) in the field key create nested fields. Use a backslash `\` to escape a dot if you want to keep it as part of a flat field name instead of nesting it. For example, `[my_entry.log\.field]` produces a `my_entry` object with a single `log.field` key, instead of nesting into `log` and `field`.

### Targeting {{site.ai_gateway}} fields

{{site.ai_gateway}} logs the outcome of an LLM request under a nested `ai` object, for example `ai.$POLICY_NAME.meta`, `ai.$POLICY_NAME.usage`, and, when payload logging is enabled, `ai.$POLICY_NAME.payload.request` and `ai.$POLICY_NAME.payload.response`. Because `custom_fields_by_lua` keys are split into nested table accesses the same way, you can use the same unescaped, dotted-key syntax to remove or override those fields.

For example, to stop logging LLM request and response payloads:

{% entity_example %}
type: policy
data:
  display_name: "{{include.name}} - Disable Payload Logging"
  name: {{include.slug}}
  type: {{include.slug}}
  config:
    {{include.base_config}}
    custom_fields_by_lua:
      "ai.{{include.slug}}.payload.request": "return nil"
formats:
  - konnect-api
  - kongctl
{% endentity_example %}

{:.info}
> **Note:** Escaping the dots (for example, `ai\.{{include.slug}}\.payload\.request`) targets a literal flat key instead of the nested `ai.{{include.slug}}.payload.request` field, so it won't match. Use unescaped dots to target {{site.ai_gateway}} fields.

Because {{include.name}} applies `custom_fields_by_lua` in its own log phase, which runs after {{site.ai_gateway}} sets the `ai.*` fields on the request, it can override or remove any `ai.*` field. The reverse isn't possible, since {{site.ai_gateway}} can't run after a logging Policy's log phase to override a field the Policy already set.

### Policy precedence and managing fields

All logging Policies use the same table for logging. If you set `config.custom_fields_by_lua` in one Policy, all logging Policies that run after it also use that configuration. For example, if you configure fields in the File Log Policy, those same fields appear in the Syslog Policy too, since File Log executes first.

* If you want all logging Policies to use the same configuration, use the [Pre-function](/ai-gateway/policies/pre-function/) Policy to call `kong.log.set_serialize_value` so the function is applied predictably and is easier to manage.
* If you don't want all logging Policies to share the same configuration, disable the relevant field in each Policy explicitly. For example, if you configure a field in the File Log Policy that you don't want appearing in the Syslog Policy, set that field to `return nil` in the File Log Policy's `custom_fields_by_lua` configuration.

### Limitations

Lua code runs in a restricted sandbox environment, whose behavior is governed by the `untrusted_lua` configuration.

As this code runs in the log phase, only [PDK](/gateway/pdk/reference/) methods that can run in that phase can be used.
