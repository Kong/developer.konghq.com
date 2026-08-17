# Third-party plugin documentation patterns

Reference for front matter, body sections, installation navtabs, style rules, and schema.json structure.

---

## Front matter schema

### Required fields (every plugin)

```yaml
title: 'Plugin Display Name'
name: 'Plugin Display Name'          # same as title
content_type: plugin
publisher: publisher-slug             # kebab-case company identifier
description: "One-line summary."
products:
  - gateway
  # - ai-gateway                      # add if the plugin targets AI Gateway specifically
works_on:
  - on-prem
  - konnect
third_party: true
support_url: https://...
icon: plugin-slug.svg                 # see Icon section below
```

### Optional fields

```yaml
source_code_url: https://github.com/...    # include if the repo is public
min_version:
  gateway: '3.4'                           # ONLY include if a real minimum version is known
                                           # NEVER use gateway: '' — it breaks the build
tags:
  - security
  - ai
search_aliases:
  - alternative name
  - company name
  - plugin slug
related_resources:
  - text: Plugin documentation
    url: https://docs.vendor.com/...       # link to the partner's own plugin docs
  - text: Vendor product overview
    url: https://...                       # other relevant vendor docs
faqs:
  - q: Question text?
    a: Answer text.
```

**`related_resources` guidance**: always include at least a link to the partner's own plugin documentation or getting-started guide. This gives users a path to vendor-maintained reference material that may be more detailed or up-to-date than what we maintain.

### `min_version` rule

Only include `min_version` when you have a concrete version number from the vendor or the schema. Omit the field entirely if unknown. Using `gateway: ''` causes a build error (`Illformed requirement [">= "]`).

---

## Plugin publishers file

The `publisher` slug must exist in `app/_data/plugin_publishers.yml`. If it does not, add:

```yaml
publisher-slug:
  name: Publisher Display Name
```

The file uses a flat structure: one entry per publisher, with `name` as the only property.

---

## Icon

The `icon` field expects a filename only (for example `skyflow.svg`).
Icons live at `app/assets/icons/plugins/`.
The naming convention is `publisher-slug.svg` or `plugin-slug.svg`.
Sourcing the file is the vendor's responsibility; adding it to the repo is part of the plugin onboarding process.
Always check that the file exists at `app/assets/icons/plugins/<filename>` before finalizing the front matter.

---

## Body sections (order)

1. **Intro paragraph**: what the plugin does and the problem it solves. One or two paragraphs max.
2. **Benefit list**: bullets. Do not bold the benefit labels — plain prose only. Start each bullet with a noun phrase.
3. `## How it works`: architecture and flow. Add a Mermaid sequence diagram for complex plugins. Add a flowchart if the topology is non-trivial (for example nested-proxy pattern).
4. `## Install the [Plugin Name] plugin`: installation heading with prerequisites and navtabs.
5. `## Enable the plugin`: links to the example pages. One or two sentences plus a list of example links.
6. `## Troubleshooting` (optional): symptom/solution pairs. Use bold symptom headers and bulleted solutions.

---

## Installation navtab patterns

### Self-managed tab (always present)

```markdown
{% navtab "Self-managed" %}

1. Install the plugin using LuaRocks:

   ```bash
   luarocks make ./path/to/plugin-name-X.Y.Z-N.rockspec
   ```

1. Enable the plugin on the node:

   ```bash
   export KONG_PLUGINS=bundled,plugin-slug
   ```

Dependencies: list runtime dependencies here. Note which are already provided by the Kong/OpenResty runtime (for example `resty.http`, `cjson`).

{% endnavtab %}
```

### Konnect streamed plugin tab

Use this tab when the plugin supports Konnect's streamed custom plugin upload. Do NOT use the LuaRock for Konnect installs.

```markdown
{% navtab "{{site.konnect_short_name}}" %}

Do not use the LuaRock for {{site.konnect_short_name}}.
Instead, upload `schema.lua` and `handler.lua` to the control plane as a custom plugin.

1. In the {{site.konnect_short_name}} menu, navigate to **Plugins**.
1. Click **Custom Plugins**.
1. Upload `schema.lua` and `handler.lua`.
1. Select **Streamed** as the installation type.
   Streamed plugins require no image rebuild or data plane restart.

Set the following environment variables on each data plane node:

```bash
KONG_CUSTOM_PLUGIN_STREAMING_ENABLED=on
KONG_UNTRUSTED_LUA=lax
KONG_PLUGINS=bundled
```

{:.warning}
> **Note**: Do not add the plugin slug to `KONG_PLUGINS` on data plane nodes.
> The gateway will demand local code at boot before streaming arrives, causing the node to fail.
> List only `bundled` and let the control plane stream the plugin code.

If your plugin configuration references `{vault://env/...}` values, also set:

```bash
KONG_VAULTS=bundled
```

{% endnavtab %}
```

### Additional tabs (as needed)

- **Docker**: show a Dockerfile with `COPY`, `ENV KONG_PLUGINS=bundled,plugin-slug`, `USER kong`, `ENTRYPOINT`.
- **Kubernetes**: show a ConfigMap or volume mount pattern.
- **kong.conf**: show `luarocks install`, then append `plugin-slug` to the `plugins` field in `kong.conf`, then `kong restart`.

---

## Style rules

These rules apply to everything written using this skill.

**Liquid variables**
- `{{site.base_gateway}}` for "Kong Gateway" and "Kong"
- `{{site.konnect_short_name}}` for "Konnect"
- `{{site.ai_gateway_name}}` for "Kong AI Gateway"

**Prose**
- One sentence per line. This produces readable diffs on GitHub.
- Active voice, present tense.
- No em dashes (`—`) anywhere, ever. Restructure the sentence instead.
- No `--` as an em dash substitute.
- No excessive bold. Bold only UI labels (button names, menu items, field names). Do not bold prose for emphasis.
- Plain language: "run" not "execute", "use" not "utilize", "for example" not "e.g.", "that is" not "i.e."
- No positional language: not "below", not "above". "The following" is fine.
- Use contractions in body text. They're preferred: "don't" over "do not", "it's" over "it is". The exception is warning callouts, where "Do not" is required for emphasis.

**Headings**
- Sentence case only. Capitalize the first word and proper nouns only.
- Correct: `## How it works`
- Correct: `## Install the Skyflow De-identify plugin`
- Wrong: `## How It Works`

**Gateway entity names to capitalize**: Consumer, Route, Service, Plugin, Certificate, Upstream, Vault, Target.
**Do not capitalize**: control plane, data plane, hybrid mode.

**Tables**
- Never use Markdown tables (`| col | col |`). Always use `{% table %}` / `{% endtable %}` Liquid tags.
- Syntax:

  ```liquid
  {% table %}
  columns:
    - title: Column One
      key: col1
    - title: Column Two
      key: col2
  rows:
    - col1: "Value A"
      col2: "Value B"
    - col1: "`code value`"
      col2: "Plain text"
  {% endtable %}
  ```

- Wrap cell values containing special characters or backticks in double quotes.

**Code blocks**
- One command per block. No `$` prompt marker.
- Always set a language identifier (`bash`, `yaml`, `docker`, etc.).
- Use `{:.no-copy-code}` under output blocks.

**Callouts**
- `{:.warning}` yellow, `{:.info}` blue, `{:.success}` green, `{:.danger}` red, `{:.neutral}` grey.
- Always include a bold label inside: `> **Note**:` or `> **Warning**:`.

---

## Mermaid diagrams

Use `{% mermaid %}...{% endmermaid %}` blocks.

**When to use a sequence diagram**: the plugin intercepts requests and responses (access + response phases), calling an external service in between. Shows the flow: Client → Gateway → External API → Upstream → External API → Gateway → Client.

**When to use a flowchart**: a non-obvious topology is involved (for example a nested-proxy pattern where two routes are required). Shows the routing graph rather than the time-ordered sequence.

Do not use Mermaid for simple plugins where the flow is obvious from the prose.

---

## schema.json structure

The full schema.json has this shape. The scope fields (consumer, consumer_group, route, service, protocols) are identical for every plugin — copy them verbatim. The `config` properties are plugin-specific.

```json
{
  "properties": {
    "consumer": {
      "additionalProperties": false,
      "description": "If set, the plugin will activate only for requests where the specified consumer has been authenticated.",
      "properties": {
        "id": {
          "type": "string"
        }
      },
      "type": "object"
    },
    "consumer_group": {
      "additionalProperties": false,
      "description": "If set, the plugin will activate only for requests where the specified consumer group has been authenticated.",
      "properties": {
        "id": {
          "type": "string"
        }
      },
      "type": "object"
    },
    "route": {
      "additionalProperties": false,
      "description": "If set, the plugin will only activate when receiving requests via the specified route.",
      "properties": {
        "id": {
          "type": "string"
        }
      },
      "type": "object"
    },
    "service": {
      "additionalProperties": false,
      "description": "If set, the plugin will only activate when receiving requests via one of the routes belonging to the specified Service.",
      "properties": {
        "id": {
          "type": "string"
        }
      },
      "type": "object"
    },
    "protocols": {
      "description": "A list of the request protocols that will trigger this plugin.",
      "items": {
        "enum": ["grpc", "grpcs", "http", "https", "tcp", "tls", "tls_passthrough", "udp", "ws", "wss"],
        "type": "string"
      },
      "type": "array"
    },
    "config": {
      "additionalProperties": false,
      "properties": {

        "FIELD_NAME": {
          "type": "string",
          "description": "Description of what this field does.",
          "default": "default-value"
        },

        "BOOLEAN_FIELD": {
          "type": "boolean",
          "description": "When true, does X.",
          "default": false
        },

        "INTEGER_FIELD": {
          "type": "integer",
          "description": "Maximum number of X. Must be greater than 0.",
          "exclusiveMinimum": 0,
          "default": 100
        },

        "ENUM_FIELD": {
          "type": "string",
          "description": "Controls behavior Y. One of: option_a, option_b, option_c.",
          "enum": ["option_a", "option_b", "option_c"],
          "default": "option_a"
        },

        "NESTED_OBJECT": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "child_field": {
              "type": "string",
              "description": "Description of child field."
            }
          }
        },

        "ARRAY_FIELD": {
          "type": "array",
          "description": "List of X values.",
          "items": {
            "type": "string"
          }
        }

      },
      "required": [],
      "type": "object"
    }
  },
  "required": []
}
```

### Converting from schema.lua

When reading a `schema.lua` file:
- Each field in the `config` table's `fields` array becomes a property in `config.properties`.
- Lua `string` → JSON `"type": "string"`
- Lua `boolean` → JSON `"type": "boolean"`
- Lua `number` → JSON `"type": "number"`
- Lua `integer` → JSON `"type": "integer"`
- Lua `table` with nested `fields` → JSON `"type": "object"` with `"properties"`
- Lua `array` → JSON `"type": "array"` with `"items"`
- Lua `one_of` → JSON `"enum"`
- Lua `default` → JSON `"default"`
- Lua `required` → add the field name to `"required"` at the appropriate level
- Strip Lua-specific validation functions (custom validators, `check_with`) — they have no JSON Schema equivalent
- Preserve descriptions from Lua comments or string fields
