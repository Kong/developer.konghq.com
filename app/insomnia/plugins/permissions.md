---
title: Plugin permissions

description: "Declare the modules and host capabilities a sandboxed Insomnia plugin needs with the insomnia.permissions manifest, and learn the default-deny baseline and capability reference."

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
  - insomnia.permissions
  - plugin capabilities
  - plugin modules
  - sandbox permissions

related_resources:
  - text: Plugins
    url: /insomnia/plugins/
  - text: Plugin sandbox and trust model
    url: /insomnia/plugins/sandbox-and-trust/
  - text: Context object reference
    url: /insomnia/plugins/context-object-reference/
  - text: Plugin troubleshooting
    url: /insomnia/plugins/troubleshooting/
---

When a plugin runs sandboxed, it is **default-deny** on two axes: which modules it can `require()`, and which host capabilities it can call. Declare what your plugin needs in its `package.json` under the `insomnia.permissions` key.

```json
{
  "name": "insomnia-plugin-example",
  "insomnia": {
    "permissions": {
      "modules": ["crypto", "ajv"],
      "capabilities": ["network", "storage"]
    }
  }
}
```

A plugin with no `permissions` block gets the baseline only (see below). Requesting anything beyond the baseline requires declaring it, or the call fails with an actionable error such as:

```
capability 'network' not granted — add it to insomnia.permissions.capabilities
```

## Baseline (no manifest)

A plugin that declares no permissions still gets a minimal, read-only baseline:

| Axis | Baseline grant |
|------|----------------|
| Modules | `path`, `crypto` |
| Capabilities | `render`, `models.read`, `util`, `crypto` |

Anything network, filesystem, credential, storage, or app/UI related must be declared explicitly.

## Capabilities reference

Values you can declare in `insomnia.permissions.capabilities`:

| Capability | Grants |
|------------|--------|
| `render` | Nested template rendering (`context.util.render`) |
| `models.read` | Read requests, workspaces, cookie jars, responses, settings, and OAuth 2.0 tokens |
| `util` | Encode/decode and host OS info helpers |
| `crypto` | The host-backed `crypto` module (hash, HMAC, random) |
| `network` | Outbound HTTP via `context.network.sendRequest` |
| `storage` | Plugin-scoped key/value store (`context.store`) |
| `fs-read` | Allow-listed file reads |
| `credentials` | Read and update stored cloud credentials |
| `app` | Dialogs, prompts, clipboard, and open-in-browser |

{:.warning}
> `models.read` includes reading **OAuth 2.0 tokens**, which are live bearer credentials, and it's part of the baseline. Treat it as a credential-disclosure surface when reasoning about what a manifest-less plugin can access.

## Modules reference

Inside the sandbox, `require(name)` resolves **only** from Insomnia's curated registry — never your plugin's `node_modules`, and never raw Node.js built-ins. Declaring a module in `insomnia.permissions.modules` unlocks it; the registry is what provides a safe implementation.

Categories:

* **Baseline:** `path`, `crypto`
* **Polyfilled built-ins:** for example `events`
* **Vetted libraries:** for example `ajv`, `uuid`

<!-- TODO(before publish): replace the examples above with the canonical, generated module list
     (ALL_SANDBOX_MODULES in the Insomnia source) so this reference can't drift. -->

Two distinct error messages tell you which problem you have:

* `Module 'X' not permitted by manifest` — the module exists in the registry, but you didn't declare it.
* `Module 'X' not available in sandbox` — you declared it, but it isn't in the registry.
