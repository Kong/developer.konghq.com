# index.md template

Annotated template for `app/_kong_plugins/<plugin-slug>/index.md`.
Replace all `<!-- PLACEHOLDER: ... -->` markers with real content.
Remove annotation comments before finalizing the file.

For style rules, liquid variables, and navtab patterns, see `patterns.md`.

---

```markdown
---
<!-- REQUIRED: Display name shown to users. Use title case. -->
title: 'Plugin Display Name'
name: 'Plugin Display Name'

content_type: plugin

<!-- REQUIRED: kebab-case company identifier. Must exist in app/_data/plugin_publishers.yml. -->
publisher: publisher-slug

<!-- REQUIRED: One-line summary of what the plugin does. -->
description: "One-line description of what this plugin does."

<!-- REQUIRED: List the products this plugin works with. -->
products:
  - gateway
  # - ai-gateway

<!-- REQUIRED: Deployment targets. -->
works_on:
  - on-prem
  - konnect

third_party: true

<!-- REQUIRED: Link to the vendor's support page or docs. -->
support_url: https://docs.vendor.com/support

<!-- OPTIONAL: Include if the source code is publicly available. -->
# source_code_url: https://github.com/vendor/plugin-repo

<!-- REQUIRED: Icon filename only (e.g. skyflow.svg). Vendor provides the file. -->
icon: plugin-slug.svg

<!-- OPTIONAL: Omit entirely if unknown. Never use gateway: '' — it breaks the build. -->
# min_version:
#   gateway: '3.4'

<!-- OPTIONAL: Tags for filtering in the plugin catalog. -->
# tags:
#   - security

<!-- OPTIONAL: Alternative names users might search for. -->
# search_aliases:
#   - vendor name
#   - plugin slug

<!-- RECOMMENDED: At least one link to the partner's own plugin docs. -->
related_resources:
  - text: Plugin documentation
    url: https://docs.vendor.com/plugin
---

<!-- INTRO: One to two paragraphs. What the plugin does and the problem it solves.
     Use {{site.base_gateway}} for "Kong Gateway". One sentence per line. -->
Use the Plugin Display Name plugin (`plugin-slug`) to [what it does and why].

[Second paragraph: the broader context — what problem exists without this plugin,
and how the plugin solves it. Keep it concise.]

<!-- BENEFITS: Bullet list. Do not bold the labels. Start each bullet with a noun phrase.
     Aim for 3-5 bullets. -->
Benefits of using the Plugin Display Name plugin:

- [Benefit one]: [explanation].
- [Benefit two]: [explanation].
- [Benefit three]: [explanation].


<!-- ============================================================
     SIMPLE PLUGIN VARIANT
     Use this section layout for plugins with flat config, no
     multi-phase lifecycle, and straightforward installation.
     ============================================================ -->

## How it works

<!-- SIMPLE: One paragraph explaining what happens when the plugin is enabled.
     No diagram needed unless the flow is non-obvious. -->
When you enable this plugin on a Route or Service, [describe what it does in plain terms].

## Install the Plugin Display Name plugin

<!-- SIMPLE: If the plugin is distributed as a LuaRock only, one navtab suffices.
     Use the standard installation include if available. Otherwise, write the steps. -->

### Prerequisites

<!-- List what the user must have before they can install. -->
- [Prerequisite one, for example: a vendor account and API key]
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


<!-- ============================================================
     COMPLEX PLUGIN VARIANT
     Use this layout for plugins that intercept and rewrite
     request/response bodies, call external services, use
     multiple Kong lifecycle phases, or have multi-step Konnect
     installation requirements.
     ============================================================ -->

## How it works

<!-- COMPLEX: Explain what happens in each lifecycle phase the plugin uses.
     One sentence per line. -->
When you enable this plugin on a Route, it acts in [N] {{site.base_gateway}} request-lifecycle phases:

- `access`: [what happens before the request is proxied upstream].
- `response`: [what happens after the upstream response is buffered, before it reaches the client].

<!-- COMPLEX: Sequence diagram. Use autonumber. Adjust participants to match your plugin.
     Do not use em dashes in labels — use a hyphen or restructure the label. -->
{% mermaid %}
sequenceDiagram
    autonumber
    participant C as Client
    participant K as Kong Gateway<br/>plugin-slug
    participant E as External Service
    participant U as Upstream

    C->>K: Request
    Note over K: access phase
    K->>E: Call external service
    E-->>K: Response from external service
    K->>U: Modified request
    U-->>K: Upstream response
    Note over K: response phase
    K->>E: Second call (if applicable)
    E-->>K: Response
    K-->>C: Final response
{% endmermaid %}

<!-- COMPLEX TOPOLOGY: Add a flowchart only if the routing topology is non-trivial
     (for example a nested-proxy pattern). Otherwise omit. -->
<!-- {% mermaid %}
flowchart TB
    C["Client"]
    F["Front route<br/>plugin-slug only"]
    I["Internal route<br/>other-plugin only"]
    U["Upstream"]

    C -- "original request" --> F
    F -- "modified request<br/>loopback 127.0.0.1:8000" --> I
    I --> U
    U -- "response" --> I
    I -- "response" --> F
    F -- "restored response" --> C
{% endmermaid %}
-->

## Install the Plugin Display Name plugin

<!-- State the LuaRock name and version on its own line so it's easy to scan. -->
LuaRock name: `plugin-slug` (current version `X.Y.Z-N`).

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

<!-- List runtime dependencies. Omit ones already in the Kong/OpenResty runtime. -->
Dependencies: [list].
[Dependency X] and [Dependency Y] are provided by the {{site.base_gateway}}/OpenResty runtime.

{% endnavtab %}
{% navtab "{{site.konnect_short_name}}" %}

<!-- KONNECT STREAMED: Use this block when the plugin supports streamed upload.
     Adjust env vars to match what the vendor specifies. -->
Do not use the LuaRock for {{site.konnect_short_name}}.
Instead, upload `schema.lua` and `handler.lua` to the control plane as a custom plugin.

1. In the {{site.konnect_short_name}} menu, navigate to **Plugins**.
1. Click **Custom Plugins**.
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

<!-- Include the vault block only if the plugin uses vault references. -->
If your plugin configuration references `{vault://env/...}` values, also set:

```bash
KONG_VAULTS=bundled
```

{% endnavtab %}
{% endnavtabs %}

## Enable the plugin

After installing the plugin, enable it on a Route or Service.
See the following examples:

<!-- Link to each example YAML. The URL pattern is /plugins/<slug>/examples/<example-name>/. -->
- [Example one title](/plugins/plugin-slug/examples/example-one/): [one-line description of what this example does and when to use it].
- [Example two title](/plugins/plugin-slug/examples/example-two/): [one-line description].

<!-- OPTIONAL: Add an info callout for important behavioral notes that apply regardless of example. -->
{:.info}
> **Note**: [Anything the user should know that applies across all configurations, for example auto-detection behavior or validation rules enforced at save time.]

<!-- OPTIONAL: List configuration constraints enforced at save time, if any. -->
<!-- Configuration constraints enforced when you save:

- [Constraint one: field A requires field B because...]
- [Constraint two]
-->


<!-- ============================================================
     OPTIONAL: TROUBLESHOOTING
     Include when the plugin has known failure modes with
     actionable solutions. Use this structure for each issue.
     ============================================================ -->

## Troubleshooting

<!-- Repeat this block for each known issue. -->
### [Symptom in a few words]

**Symptoms:** [What the user sees — error message, unexpected behavior, missing output.]

**Possible solutions:**
- [Solution one.]
- [Solution two.]
```
