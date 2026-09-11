---
title: Plugin sandbox and trust model

description: "Understand how Insomnia runs plugin code — in-process versus the QuickJS sandbox — the pluginSandboxEnabled setting, per-plugin elevated access, and how to migrate an existing plugin."

content_type: reference
layout: reference

products:
- insomnia

breadcrumbs:
- /insomnia/
- /insomnia/plugins/

tags:
- insomnia-plugins

search_aliases:
  - Insomnia plugin sandbox
  - pluginSandboxEnabled
  - elevated plugin
  - full host access

related_resources:
  - text: Plugins
    url: /insomnia/plugins/
  - text: Plugin permissions
    url: /insomnia/plugins/permissions/
  - text: Plugin troubleshooting
    url: /insomnia/plugins/troubleshooting/
  - text: Plugin reference
    url: /insomnia/plugins/plugin-reference/
---

## How plugin code runs

Insomnia can run an installed (user) plugin's code in one of two places:

* **In-process** — directly in the app process, with full Node.js access (`fs`, `child_process`, arbitrary `require`, and so on). This is the original behavior.
* **In the QuickJS sandbox** — an isolated JavaScript runtime with no direct Node.js access. The plugin reaches the app only through a capability-gated bridge, and `require()` resolves only from a curated module registry. See [Plugin permissions](/insomnia/plugins/permissions/).

Which one is used depends on a global setting and a per-plugin opt-in.

## The `pluginSandboxEnabled` setting

In **Preferences > Scripting**, enable **Sandbox all plugin code**. When it's on, every untrusted (user) plugin surface — template tags, request and response hooks, actions, and load-time code — runs in the sandbox.

## Execution modes

For a given plugin, the resolved mode is one of:

| Mode | When | Runs | Host access |
|------|------|------|-------------|
| **Sandboxed** | User plugin, sandbox on, not elevated | QuickJS sandbox | Only declared capabilities |
| **Elevated** | User plugin, sandbox on, "Full host access" turned on | In-process | Full |
| **In-process** | User plugin, sandbox off | In-process | Full (legacy) |

**Preferences > Plugins** shows each plugin's mode as a badge next to its name.

## Full host access (elevated)

Some community plugins genuinely need native modules or host access the sandbox doesn't grant. For those, **Preferences > Plugins** provides a per-plugin **Full host access** toggle. It is:

* **Off by default** — a plugin is sandboxed unless you deliberately elevate it.
* **Per-plugin** — never global.
* **A trust decision** — an elevated plugin runs in-process with full Node.js access, exactly like the pre-sandbox behavior. Only elevate plugins you trust.

## Migrate an existing plugin

If your plugin worked before the sandbox and breaks when it's on:

1. **Does it `require()` `fs`, `child_process`, or an arbitrary npm package?** Those aren't reachable in the sandbox. Move to a registry module and declare it (see [Plugin permissions](/insomnia/plugins/permissions/)), or ask the user to enable **Full host access** for your plugin.
2. **Does it call `context.network`, read files, use storage, or read credentials?** Declare the matching capability in `insomnia.permissions.capabilities`. An undeclared call fails with an error naming the missing capability.
3. **Is it a multi-file plugin?** Your own `node_modules` is *not* consulted at runtime — third-party dependencies must be registry modules declared in `insomnia.permissions.modules`.

## Caveats

* **The Inso CLI has no sandbox.** Under the pure-Node CLI, user-plugin hooks run in-process regardless of the setting — CLI users are trusting their own plugins.
