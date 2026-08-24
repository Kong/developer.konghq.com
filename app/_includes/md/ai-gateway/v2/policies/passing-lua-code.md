{{site.ai_gateway}} expects Lua code in a string format. For a short script, write it directly in the Policy's `config`:

{% entity_example %}
type: policy
data:
  name: {{include.slug}}
  type: {{include.slug}}
  config:
    access:
    - |
      kong.log.info("hello world")
formats:
  - konnect-api
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
  name: {{include.slug}}
  type: {{include.slug}}
  config:
    access:
    - $FUNCTION_LUA
formats:
  - konnect-api
  - kongctl
{% endentity_example %}
