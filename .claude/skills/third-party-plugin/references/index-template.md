# index.md template

Annotated template for `app/_kong_plugins/<plugin-slug>/index.md`.

**Choose one variant** based on the complexity assessment in Step 2 of the skill:
- [Simple plugin template](#simple-plugin-template): flat config, no multi-phase lifecycle
- [Complex plugin template](#complex-plugin-template): multi-phase lifecycle, nested config, non-trivial installation

Replace all placeholder values with real content. Remove annotation comments before finalizing.

For style rules, Liquid variables, navtab patterns, and the `{% table %}` syntax, see `patterns.md`.

---

## Simple plugin template

Use this for plugins with flat config (1-5 fields), no request/response body rewriting, and straightforward installation (one or two commands). Examples: DataDome, Moesif, TrendAI.

---
title: 'Plugin Display Name'
name: 'Plugin Display Name'

content_type: plugin

publisher: publisher-slug

description: "One-line description of what this plugin does."

products:
  - gateway
  # - ai-gateway

works_on:
  - on-prem
  - konnect

third_party: true

support_url: https://docs.vendor.com/support

icon: plugin-slug.svg

# min_version:           # Omit if unknown. Never use gateway: ''
#   gateway: '3.4'

# tags:
#   - security

# search_aliases:
#   - vendor name

related_resources:
  - text: Plugin documentation
    url: https://docs.vendor.com/plugin
---

Use the Plugin Display Name plugin (`plugin-slug`) to [what it does and why].

[Optional second paragraph: broader context — the problem without the plugin and how it solves it.]

Benefits of using the Plugin Display Name plugin:

- [Benefit one]: [explanation].
- [Benefit two]: [explanation].
- [Benefit three]: [explanation].

## How it works

When you enable this plugin on a Route or Service, [describe what it does in one or two sentences].

## Install the Plugin Display Name plugin

### Prerequisites

- [Prerequisite one — for example: a vendor account and API key]
- [Prerequisite two]

### Installation steps

{% navtabs 'install' %}
{% navtab "Self-managed" %}

1. Install the plugin using LuaRocks:

   ```bash
   luarocks make ./path/to/plugin-name-X.Y.Z-N.rockspec
   ```

1. Enable the plugin on the node:

   ```bash
   export KONG_PLUGINS=bundled,plugin-slug
   ```

{% endnavtab %}
{% endnavtabs %}

## Enable the plugin

After installing the plugin, enable it on a Route or Service.
See the [Plugin Display Name example](/plugins/plugin-slug/examples/enable-plugin-slug/).

---

## Complex plugin template

Use this for plugins that intercept and rewrite request/response bodies, call external services, act in multiple Kong lifecycle phases, or have non-trivial Konnect installation steps. Examples: Noma, Skyflow, VeriKnox, Impart, CrowdStrike.

---
title: 'Plugin Display Name'
name: 'Plugin Display Name'

content_type: plugin

publisher: publisher-slug

description: "One-line description of what this plugin does."

products:
  - gateway
  # - ai-gateway

works_on:
  - on-prem
  - konnect

third_party: true

support_url: https://docs.vendor.com/support

icon: plugin-slug.svg

# min_version:           # Omit if unknown. Never use gateway: ''
#   gateway: '3.4'

# tags:
#   - security

# search_aliases:
#   - vendor name

related_resources:
  - text: Plugin documentation
    url: https://docs.vendor.com/plugin
---

Use the Plugin Display Name plugin (`plugin-slug`) to [what it does and why].

[Second paragraph: the broader context — what problem exists without this plugin and how it solves it.]

Benefits of using the Plugin Display Name plugin:

- [Benefit one]: [explanation].
- [Benefit two]: [explanation].
- [Benefit three]: [explanation].

## How it works

[One paragraph orienting the reader: what the plugin does at a high level, what external service it talks to, and what lifecycle phases it uses.]

When you enable this plugin on a Route, it acts in the Kong request-lifecycle `access` phase:

- `access`: [what happens before the request is proxied upstream].

[Include `response` phase bullet only if the plugin acts on the response:]

- `response`: [what happens after the upstream response is buffered, before it reaches the client].

<!-- Sequence diagram: use when the plugin calls an external service. Adjust participants. -->
{% mermaid %}
sequenceDiagram
    autonumber
    participant C as Client
    participant K as Kong Gateway<br/>plugin-slug
    participant E as External Service
    participant U as Upstream

    C->>K: Request
    Note over K: access phase
    K->>E: Call to external service
    E-->>K: Response from external service
    K->>U: Modified request
    U-->>K: Upstream response
    Note over K: response phase
    K->>E: Second call (if applicable)
    E-->>K: Response
    K-->>C: Final response
{% endmermaid %}

<!-- Flowchart: add ONLY if the routing topology is non-trivial (e.g. nested-proxy pattern).
     Otherwise omit this block entirely. -->
<!--
{% mermaid %}
flowchart TB
    C["Client"]
    F["Front route - plugin-slug only"]
    I["Internal route - other-plugin only"]
    U["Upstream"]

    C -- "original request" --> F
    F -- "modified<br/>loopback 127.0.0.1:8000" --> I
    I --> U
    U -- "response" --> I
    I -- "response" --> F
    F -- "restored response" --> C
{% endmermaid %}
-->

[Add subsections here for notable behavioral details — for example plugin priority, caller identity handling, or composability constraints. Use ### headings.]

## Install the Plugin Display Name plugin

LuaRock name: `plugin-slug` (current version `X.Y.Z-N`).
<!-- Remove the line above if the plugin does not distribute a LuaRock. -->

### Prerequisites

Before installing the plugin, you need:

- [Prerequisite one — for example: a vendor account and site enrollment token]
- [Prerequisite two]

### Installation steps

{% navtabs 'install' %}
{% navtab "Self-managed" %}

1. Install the plugin using LuaRocks.
   The rockspec lives at [relative path from repo root]:

   ```bash
   luarocks make ./path/to/plugin-slug-X.Y.Z-N.rockspec
   ```

1. Enable the plugin on the node:

   ```bash
   export KONG_PLUGINS=bundled,plugin-slug
   ```

Dependencies: [list any non-bundled dependencies].
[Library X] and [Library Y] are provided by the {{site.base_gateway}}/OpenResty runtime.

{% endnavtab %}
{% navtab "{{site.konnect_short_name}}" %}

<!-- Use this block when the plugin supports Konnect streamed upload. -->
Do not use the LuaRock for {{site.konnect_short_name}}.
Instead, upload `schema.lua` and `handler.lua` to the control plane as a custom plugin.

1. In the {{site.konnect_short_name}} sidebar, navigate to **API Gateway > Control planes**.
1. Click your control plane.
1. Click the **Plugins** tab.
1. Click **New plugin**.   
1. Click **Custom plugin**.
1. Upload `schema.lua` and `handler.lua`.
1. Select **Streamed** as the installation type.
   Streamed plugins require no image rebuild or data plane restart.

The two files depend only on libraries that {{site.base_gateway}} already ships ([list them]).

Set the following environment variables on each data plane node:

```bash
KONG_CUSTOM_PLUGIN_STREAMING_ENABLED=on
KONG_UNTRUSTED_LUA=lax
KONG_PLUGINS=bundled
```

{:.warning}
> **Note**: Do not add `plugin-slug` to `KONG_PLUGINS` on data plane nodes.
> The gateway will demand local code at boot before streaming arrives, causing the node to fail.
> List only `bundled` and let the control plane stream the plugin code.

<!-- Include only if the plugin uses vault references: -->
If your plugin configuration references `{vault://env/...}` values, also set:

```bash
KONG_VAULTS=bundled
```

{% endnavtab %}
{% endnavtabs %}

## Enable the plugin

After installing the plugin, enable it on a Route or Service.
See the following examples:

- [Example one title](/plugins/plugin-slug/examples/example-one/): [one-line description].
- [Example two title](/plugins/plugin-slug/examples/example-two/): [one-line description].

<!-- Optional: info callout for behavioral notes that apply across all configurations. -->
{:.info}
> **Note**: [Anything the user should know regardless of which example they use.]

<!-- Optional: troubleshooting section. Repeat the block below for each known issue. -->
## Troubleshooting

### [Symptom in a few words]

**Symptoms:** [What the user sees.]

**Possible solutions:**
- [Solution one.]
- [Solution two.]
