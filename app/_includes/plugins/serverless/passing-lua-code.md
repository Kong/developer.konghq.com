
Since {{site.base_gateway}} expects the Lua code in a string format, we recommend either 
uploading a file through the Admin API using the `@file.lua` syntax, or minifying your Lua code 
using a [minifier](https://mothereff.in/lua-minifier).

The syntax for passing a file to the {{include.name}} plugin depends on the tool you're using.

{% navtabs "file-syntax" %}
{% navtab "Using decK" %}
decK doesn't support the file syntax directly. If you want to pass Lua files to decK, you'll need to use environment variables to include the content of your Lua script:

1. Create your Lua script and save it in a file, for example, `function.lua`.
2. Load the contents of the Lua script into an environment variable:

   ```sh
   export DECK_FUNCTION=$(cat function.lua)
   ```
3. Reference the variable in a decK file:

   ```yaml
   plugins:
   - name: {{include.slug}}
     config:
       access:
       - |
          {% raw %}${{ env "DECK_FUNCTION" }}{% endraw %}
    ```
{% endnavtab %}
{% navtab "Using an API" %}

If you're using the [Admin API](/api/gateway/admin-ee/) or [{{site.konnect_short_name}} Control Plane Config API](/api/konnect/control-planes-config/v2/), 
you can pass each chunk of Lua code as a form parameter and a filename.

For example:
```sh
--form "config.access=@/tmp/access-serverless.lua"
```

Alternatively, you can pass the contents of the file into an environment variable:

```sh
export FUNCTION=$(cat function.lua)
```

Then pass the environment variable to the API:
```sh
--data "config.access=$FUNCTION"
```

{% endnavtab %}
{% endnavtabs %}