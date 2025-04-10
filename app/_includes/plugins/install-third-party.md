
{% if include.distributor == 'private' %}

The {{include.name}} plugin is provided as a set of Lua scripts.

1. Obtain the plugin directly from {{include.publisher}} or a distributor.

1. Mount or copy the Lua files, or create a {{site.base_gateway}} container image with Lua files (usually at `/usr/local/share/lua/5.1/kong/plugins/{{include.slug}}`).

{% else %}

You can install the {{include.name}} plugin via LuaRocks.
A Lua plugin is distributed in `.rock` format, which is
a self-contained package that can be installed locally or from a remote server.

1. Install the {{include.name}} plugin:

   ```sh
   luarocks install {{include.rock}}
   ```

   {{ include.explanation }}

{% endif %}

1. Update your loaded plugins list in {{site.base_gateway}}.

   In your [`kong.conf`](/gateway/configuration/), append `{{include.slug}}` to the `plugins` field. Make sure the field isn't commented out.

   ```yaml
   plugins = bundled,{{include.slug}}
   ```

{{ include.extra-steps }}

1. Restart {{site.base_gateway}}:

   ```sh
   kong restart
   ```
