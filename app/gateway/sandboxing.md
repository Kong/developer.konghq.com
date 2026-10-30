---
title: "Lua sandboxing"

description: |
  Reference for Lua sandboxing in {{site.base_gateway}}, including available environments and modules for each sandbox mode.
content_type: reference
layout: reference

breadcrumbs:
  - /gateway/
products:
  - gateway
works_on:
  - on-prem
  - konnect

related_resources:
  - text: "Pre-function plugin"
    url: /plugins/pre-function/
  - text: "Post-function plugin"
    url: /plugins/post-function/
  - text: "Exit Transformer plugin"
    url: /plugins/exit-transformer/
  - text: "{{site.base_gateway}} configuration reference"
    url: /gateway/configuration/
---

Sandboxing imposes several limitations on how custom Lua code can be executed,
for heightened security. The Lua (or LuaJIT) language itself is not limited — only the available
environment and the set of usable modules are restricted.

The limitations can be adjusted with the `untrusted_lua` configuration option.

## Disallow custom code execution

If no custom code is needed, disable all custom code execution by setting `untrusted_lua=off`.
This ensures that the {{site.base_gateway}} node will not attempt to load or execute custom code, such as
serverless functions used by the `pre-function` and `post-function` plugins. The downside is
that Lua-based extensibility will not be available.

## Strict mode (the default)

Strict mode is an allowlist-based execution environment, selected by setting
`untrusted_lua=strict`. This is also the default value in current {{site.base_gateway}} releases. In this mode
you can load and execute custom Lua code with some limitations. Most notably,
all file I/O and network I/O functionality is disallowed.

### Environment in strict mode

In `strict` mode you are allowed to use:

{% include_cached /sandbox/allowlist-table.md kind="environment" mode="strict" %}

### Available modules in strict mode

You are also allowed to use the standard `require` function to load modules.
In strict mode, the following modules are available:

{% include_cached /sandbox/allowlist-table.md kind="require" mode="strict" %}

## Lax mode

The lax mode extends the strict mode with network I/O, and some other functionality.

### Environment in lax mode

Lax mode includes everything in strict mode, plus the following:

{% include_cached /sandbox/allowlist-table.md kind="environment" mode="lax" %}

### Available modules in lax mode

Lax mode includes everything in strict mode, plus the following:

{% include_cached /sandbox/allowlist-table.md kind="require" mode="lax" %}

## Sandbox mode (deprecated)

Sandbox mode is deprecated and may be removed in a future release. Sandbox mode allows (almost)
full access to {{site.base_gateway}} PDK (`kong.*`) and Nginx functions (`ngx.*`). It has somewhat limited access
to standard Lua environment (see the strict mode Lua related environment). This is useful when
upgrading from older {{site.base_gateway}} versions that used the sandbox mode, and thus is backward compatible.

In sandbox mode you are not allowed to use the `require` function to load modules, unless you are
also using `untrusted_lua_sandbox_requires` and listing the allowed modules there.

## Unrestricted mode

It is also possible to run {{site.base_gateway}} in unrestricted mode by setting the `untrusted_lua`
configuration option to `on`. In this mode the access to environment or available modules
is completely unrestricted, and no protections are applied.

## Notes

{{site.base_gateway}} keeps rights to modify the above mentioned allow-lists of environment and modules. Most commonly,
{{site.base_gateway}} will do additions to the allow-lists, but in case a security vulnerability is found, {{site.base_gateway}} may
remove some. In such case, {{site.base_gateway}} will notify the user about the change.
