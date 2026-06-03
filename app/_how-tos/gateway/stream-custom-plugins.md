---
title: Stream {{site.base_gateway}} plugins
permalink: /how-to/stream-custom-plugins/
content_type: how_to
related_resources:
  - text: Plugin streaming reference
    url: /custom-plugins/streaming-plugins/

description: "Define custom plugins directly in {{site.base_gateway}} entity configuration and distribute them to all data planes automatically."

products:
    - gateway

works_on:
    - on-prem
    - konnect

tools:
    - deck

prereqs:
  gateway:
    - name: "KONG_CUSTOM_PLUGINS_ENABLED=true"
  konnect:
    - name: "KONG_CUSTOM_PLUGINS_ENABLED=true"
  entities:
    services:
        - example-service
    routes:
        - example-route

min_version:
  gateway: '3.15'

entities:
  - plugin

tldr:
  q: How can I define a custom plugin without having to upload any files?
  a: |
    Use the `custom_plugins` key in your decK configuration to embed the plugin schema and handler directly in {{site.base_gateway}} entity configuration. 
    If you're running in hybrid mode, the control plane streams the plugin to all connected data planes automatically.

faqs:
  - q: Can I define any custom plugin as a streaming plugin?
    a: |
      No, there are some limitations. The plugin must have only one `handler` and one `schema`, cannot run in the `init_worker` phase or create timers, and must be written in Lua. See the [custom plugin streaming reference](/custom-plugins/streaming-plugins/) for more detail.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

Normally, deploying a custom plugin requires uploading Lua files to every data plane and restarting {{site.base_gateway}}. 
With streaming plugins, you define the plugin schema and handler directly in your {{site.base_gateway}} entity configuration. 
The control plane becomes the single source of truth and distributes the plugin to all connected data planes automatically, with no file management or restarts needed.

In this guide, you'll define two plugins inline to demonstrate how streaming works:

* `replaceme`: Substitutes a target word in the request body with a replacement word before forwarding to the upstream.
* `reflector`: Returns the request body directly to the caller, bypassing the upstream. This lets you inspect the modified body without needing an external service.

You'll apply `replaceme` globally with a condition so it only runs when the request path does not contain the word `skip`, then validate both cases.

## Create the first plugin

The `replaceme` plugin reads the raw request body, performs a global text substitution, and writes the modified body back before the request is proxied upstream.

```bash
cat <<'EOF' | deck gateway apply -
_format_version: "3.0"
_transform: true

custom_plugins:
  - name: replaceme
    schema: |
      return {
        name = "replaceme",
        fields = {
          {
            config = {
              type = "record",
              fields = {
                { target_word = { type = "string", required = true } },
                { replacement_word = { type = "string", required = true } },
              },
            },
          },
        },
      }
    handler: |
      local WordReplacerHandler = {
        PRIORITY = 800,
        VERSION = "1.0.0",
      }
      function WordReplacerHandler:access(config)
        local raw_body, err = kong.request.get_raw_body()
        if err then
          kong.log.err("Failed to read request body: ", err)
          return
        end
        if raw_body and raw_body ~= "" then
          local escaped_target = config.target_word:gsub("([^%w])", "%%%1")
          local modified_body, count = string.gsub(raw_body, escaped_target, config.replacement_word)
          if count > 0 then
            kong.service.request.set_raw_body(modified_body)
          end
        end
      end
      return WordReplacerHandler
EOF
```

Where:
* `custom_plugins.name`: A unique name for the plugin.
* `custom_plugins.schema`: The Lua schema definition, which declares the plugin's configuration fields.
* `custom_plugins.handler`: The Lua handler that contains the plugin logic.

## Create the second plugin

The `reflector` plugin returns the request body directly to the caller with a `200` response, bypassing the upstream entirely. 
This makes it useful for testing what the request body looks like after earlier plugins have modified it.

The `reflector` plugin has an empty schema because it takes no configuration.
Its `PRIORITY` is set to `-10` so it runs after `replaceme` (priority `800`), ensuring `replaceme` modifies the body first.

```bash
cat <<'EOF' | deck gateway apply -
_format_version: "3.0"
_transform: true

custom_plugins:
  - name: reflector
    schema: 'return { name = "reflector", fields = { { config = { type = "record", fields = {} } } } }'
    handler: |
      local ReflectorHandler = {
        PRIORITY = -10,
        VERSION = "1.0.0",
      }
      function ReflectorHandler:access(config)
        local body = kong.request.get_raw_body()
        local headers = kong.request.get_headers()
        local content_type = headers["content-type"] or "text/plain"
        return kong.response.exit(200, body, {
          ["Content-Type"] = content_type
        })
      end
      return ReflectorHandler
EOF
```

## Configure the plugins

Now that both plugins are defined, apply them globally.
Apply `replaceme` with a [condition](/gateway/plugins/expressions/) so it only runs when the request path doesn't contain `skip`:

{% entity_examples %}
entities:
  plugins:
    - name: replaceme
      condition: '!http.path.contains("skip")'
      config:
        target_word: sea
        replacement_word: pelican
    - name: reflector
{% endentity_examples %}

## Validate

Send a request with the word `sea` in the body.
The `replaceme` plugin substitutes every occurrence of `sea` with `pelican`, and `reflector` returns the modified body directly:

```bash
curl http://localhost:8000/anything -d 'She sells sea shells by the sea shore.'
```

You should see the following response:

```text
She sells pelican shells by the pelican shore.
```
{:.no-copy-code}

Now send the same request, but include `skip` somewhere in the path.
The condition `!http.path.contains("skip")` prevents `replaceme` from running, so the body passes through unchanged:

```bash
curl http://localhost:8000/anything/skip -d 'She sells sea shells by the sea shore.'
```

You should see the following response:

```text
She sells sea shells by the sea shore.
```
{:.no-copy-code}
