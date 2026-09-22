---
title: Conditional expressions for plugins

description: Reference for the `condition` field, which lets a {{site.base_gateway}} plugin run only when a CEL expression matches the request.
content_type: reference
layout: reference

products:
  - gateway

min_version:
  gateway: '3.15'

breadcrumbs:
  - /gateway/
  - /gateway/entities/
  - /gateway/entities/plugin/

faqs:
  - q: Do conditions work with global plugins?
    a: Yes, conditions can be used on global plugins that are not scoped to a Route, Service, Consumer, or Consumer Group.
  - q: When should I use plugin conditions instead of Routes?
    a: |
      Routes with expression router conditions should be used instead of per-plugin conditions, since Route expressions are more performant than plugin conditions.
      This is because:
       * The `init` phase of plugins on excluded Routes won't execute.
       * The plugin condition won't need to be evaluated.
  - q: Can I match a plugin condition based on request content type (for example, JSON or XML)?
    a: |
      No, the condition expression language doesn't support this explicitly.
      As an alternative, you can use a plugin such as [Datakit](/plugins/datakit/) or [Pre-Function](/plugins/pre-function/) to parse the body, extract the required value, and store it in [`kong.ctx.shared`](/gateway/plugins/expressions/#available-fields).
      The plugin condition can then reference that `kong.ctx.shared` key.
  - q: What happens if my condition expression has a runtime error?
    a: |
      If a condition expression fails at runtime, {{site.base_gateway}} logs the error at the ERROR level and returns a 500 status code to the client.
      To prevent this, wrap your expression in a `default()` call: `default(<expression>, false)`.
      This returns `false` (and skips the plugin) instead of a 500 if the expression errors.

works_on:
  - on-prem
  - konnect

related_resources:
  - text: CEL expressions for plugins
    url: /gateway/plugins/expressions/
  - text: Expressions router
    url: /gateway/routing/expressions/
  - text: Configure conditional plugin execution
    url: /gateway/configure-conditional-plugin-execution/
  - text: Dynamic plugin config with CEL
    url: /gateway/plugins/expressible-fields/
  - text: Plugin entity
    url: /gateway/entities/plugin/
  - text: Plugin contexts
    url: /gateway/entities/plugin/#plugin-contexts
  - text: Plugin scopes
    url: /gateway/entities/plugin/#scoping-plugins
  - text: Plugin priority
    url: /gateway/entities/plugin/#plugin-priority
  - text: Conditional expressions for plugins in 3.14
    url: /gateway/plugins/expressions-314/

---

Plugin conditions let you attach an optional `condition` expression to any plugin.
When a request comes in, {{site.base_gateway}} evaluates the expression immediately before the plugin's `access` phase.
If the expression evaluates to `true`, the plugin runs normally.
If it evaluates to `false`, the plugin is skipped for that request.

Conditions use [Common Expression Language (CEL)](https://cel.dev/), a lightweight expression language.

Here are some common use cases for setting a condition on a plugin:

* Skip a global plugin for specific Routes, hosts, or request paths without removing the plugin or duplicating it across individual Routes.
* Enforce a plugin only for specific HTTP methods, headers, or query parameters.
* Make one plugin's execution depend on context set by a higher-priority plugin.
* Condition plugin behavior on the authenticated Consumer, matched Route, or target Gateway Service.

## How it works

When {{site.base_gateway}} receives a request, it matches the request to a Route and determines which plugins are in scope according to the [plugin scoping rules](/gateway/entities/plugin/#scoping-plugins).
For each in-scope plugin that has a `condition` set, {{site.base_gateway}} evaluates the expression before that plugin's `access` phase runs.

The following [plugin contexts](/gateway/entities/plugin/#plugin-contexts) always execute, regardless of the condition: `init_worker`, `configure`, `certificate`, and `rewrite`.
If the condition evaluates to `false`, the plugin's `access` phase and all later phases are skipped.
Because of this, values set during or after the response phase (for example, `kong.ctx.shared` values written in `header_filter` or `body_filter`) aren't available to condition expressions.

Unlike plugin scopes, which are evaluated once at router time before any plugins run, conditions are evaluated per request, per plugin, immediately before each plugin executes.
This means a higher-priority plugin can set values in `kong.ctx.shared` that a lower-priority plugin's condition can then read.

If no condition is set, the plugin always executes.

## Performance considerations

[Plugin scopes](/gateway/entities/plugin/#scoping-plugins) are evaluated once at router time and are more efficient than conditions, which are evaluated per request for each conditioned plugin.
Where possible, use plugin scopes to control plugin execution rather than conditions.

When conditions are necessary, keep the following in mind:

* A plugin's configuration is always loaded into memory, even if its condition evaluates to `false`.
* Complex compound expressions with many fields are more expensive to evaluate than simple single-field expressions.
* Conditions that reference `kong.ctx.shared` fields require a higher-priority plugin to set those values on every request, which adds its own overhead.

## Limitations

Plugin conditions are only supported in the HTTP subsystem.
They can't be used with stream (TCP, TLS, UDP) Routes.

The following plugins **do not** support conditions:
* Pre-Function
* Post-Function
* WebSocket Size Limit
* WebSocket Validator

All other [{{site.base_gateway}} plugins](/plugins/) support conditions.

Condition expressions have a maximum length of 1024 characters.

## Condition expressions reference

A condition expression is a string value assigned to the `condition` field of a plugin object. It follows the syntax, available fields, and types described in [CEL expressions for plugins](/gateway/plugins/expressions/).

### Handling default values

`default()` makes condition expressions safe at runtime.
If the expression raises an evaluation error (for example, accessing a missing key in a map), `default()` returns the fallback value instead of causing a 500 error.

`default()` must wrap the **entire** expression. It can't appear inline within a larger expression:

```sh
# Valid — wraps the entire expression
default(kong.ctx.shared.my_flag == "enabled", false)

# Not valid — default() can't be used inline
kong.ctx.shared.my_flag == "enabled" && default(principal.id == "abc", false)
```
{:.no-copy-code}

Use `default()` when your expression references fields that might not be set for every request, such as `kong.ctx.shared.*` or `principal.metadata.*`:

```sh
default(principal.metadata["Department"] == "finance", false)
```

## Debugging

When {{site.base_gateway}} is running with debug logging enabled, a log line is emitted for each condition evaluation.

When a condition is **not matched** and the plugin is skipped:

```
plugin condition not matched for plugin 'request-termination' (ID: 66a1adbb-0179-49af-a065-4d0bc6c28cd6): skipped
```
{:.no-copy-code}

When a condition is **matched** and the plugin executes:

```
plugin condition matched for plugin 'request-termination' (ID: 66a1adbb-0179-49af-a065-4d0bc6c28cd6)
```
{:.no-copy-code}

If a condition expression **fails at runtime**, the error is logged at the `ERROR` level and {{site.base_gateway}} returns a 500 to the client:

```
error evaluating plugin condition for plugin 'request-termination' (ID: 66a1adbb-0179-49af-a065-4d0bc6c28cd6): No such key: foo
```
{:.no-copy-code}

To prevent runtime errors, wrap your expression in `default()`:

```json
"condition": "default(kong.ctx.shared.my_flag == \"enabled\", false)"
```

## Migration from 3.14 to 3.15

{% include_cached /gateway/expressions/migrate.md %}