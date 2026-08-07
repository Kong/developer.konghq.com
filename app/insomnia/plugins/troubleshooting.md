---
title: Plugin troubleshooting

description: "Diagnose Insomnia plugin problems — plugins that fail to load now show a disabled row with a reason instead of disappearing — plus current sandbox known limitations."

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
  - plugin disappeared
  - plugin failed to load
  - plugin not showing

related_resources:
  - text: Plugins
    url: /insomnia/plugins/
  - text: Plugin sandbox and trust model
    url: /insomnia/plugins/sandbox-and-trust/
  - text: Plugin permissions
    url: /insomnia/plugins/permissions/
---

## A plugin disappeared from the list

A plugin that fails to load **no longer silently disappears**. Instead it appears in **Preferences > Plugins** as a disabled row with a reason:

* Open **Preferences > Plugins** and look for a row marked **Failed to load plugin** (a warning icon, and no enable checkbox). Expand it to see the exact error.

Common reasons and fixes:

| Reason shown | Cause | Fix |
|--------------|-------|-----|
| `Cannot find module '…'` | A `require()` failed (a missing dependency, or a module that isn't in the sandbox registry) | Add the dependency as a registry module in `insomnia.permissions.modules`, or fix the missing dependency. See [Plugin permissions](/insomnia/plugins/permissions/). |
| `Multiple plugin folders declare the name "…"` | Two folders under your plugin paths declare the same plugin `name` | Remove or rename the duplicate folder. While a name is claimed by more than one folder, *none* of them load — this is deliberate, to avoid an ambiguous trust grant. |
| Other load-time error | The plugin's top-level code threw | Read the message. If the plugin needs host access the sandbox doesn't grant, consider **Full host access** — see [Plugin sandbox and trust model](/insomnia/plugins/sandbox-and-trust/). |

### A plugin stayed broken even after I fixed the error

Older versions cached the plugin and render engine for the whole session, so a plugin that failed once stayed broken until you restarted the app. This is fixed. Use **Preferences > Plugins > Reload plugins** (or the plugin-reload keyboard shortcut): reloading now rebuilds the render engine and re-scans the registry, so a plugin recovers once its underlying error is fixed. You no longer need to reinstall it into a fresh folder.

## Known limitations

### Passing DOM or non-serializable values across the plugin boundary

APIs that pass rich objects (for example `context.app.dialog()` with DOM nodes) don't round-trip through the sandbox bridge, which marshals plain JSON. Prefer serializable data.

<!-- TODO(triage): Folder actions (requestGroupActions) are reported broken in Kong/insomnia#10292.
     Confirm whether this is a sandbox/marshalling limitation to document here, or an action-routing
     regression to fix. If it's a regression it belongs in a fix, not this list. Do not finalize
     this section until #10292 is triaged. -->

## Still stuck?

[Open an issue](https://github.com/Kong/insomnia/issues) with the exact text from the plugin's disabled-row reason and your `package.json` `insomnia` block.
