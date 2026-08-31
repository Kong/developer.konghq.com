{{site.ai_gateway}} expects Lua code in a string format. For a short script, write it directly in the Policy's `config`:

{% entity_example %}
type: policy
data:
  display_name: "{{include.name}} - Inline Script"
  name: {{include.slug}}
  type: {{include.slug}}
  config:
    access:
    - |
      kong.log.info("hello world")
formats:
  - kongctl
{% endentity_example %}

For a longer script, save it to a file and load it into an environment variable:

```sh
export FUNCTION_LUA=$(cat function.lua)
```

Then reference the environment variable in your {{include.name}} Policy configuration:

{% entity_example %}
type: policy
data:
  display_name: "{{include.name}} - Script From File"
  name: {{include.slug}}
  type: {{include.slug}}
  config:
    access:
    - $FUNCTION_LUA
formats:
  - kongctl
{% endentity_example %}
