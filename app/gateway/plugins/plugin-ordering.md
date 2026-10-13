---
title: Plugin ordering algorithms

description: "Learn how {{site.base_gateway}} resolves dynamic plugin ordering rules and compare the available algorithms."
content_type: reference
layout: reference

products:
  - gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.0'

breadcrumbs:
  - /gateway/
  - /gateway/entities/
  - /gateway/entities/plugin/

related_resources:
  - text: Plugin entity reference
    url: /gateway/entities/plugin/
  - text: Plugin priority
    url: /gateway/entities/plugin/#plugin-priority
  - text: Dynamic plugin ordering
    url: /gateway/entities/plugin/#dynamic-plugin-ordering
---

Every {{site.base_gateway}} plugin has a static [priority](/gateway/entities/plugin/#plugin-priority) that decides the order that plugins run in.
[Dynamic plugin ordering](/gateway/entities/plugin/#dynamic-plugin-ordering) lets you override that order by adding an `ordering` rule to a plugin, so that it runs `before` or `after` another plugin.

The [`plugin_ordering_algorithm` setting](/gateway/configuration/#plugin-ordering-algorithm) in `kong.conf` tells {{site.base_gateway}} how to resolve the plugin ordering rules.
Use this reference to help you predict the order and decide which algorithm to use.

{:.warning}
> Dynamic ordering only affects the `access` phase.
> All other phases (`header_filter`, `body_filter`, `response`, and `log`) always run in static priority order.

## Algorithm comparison

The available algorithms are `legacy` and `priority_preserving`, with `legacy` as default.

{% table %}
columns:
  - title: ""
    key: item
  - title: "`legacy`"
    key: legacy
  - title: |
      `priority_preserving` {% new_in 3.16 %}
    key: priority_preserving
rows:
  - item: "[How is the order determined?](#ordering-behavior)"
    legacy: |
      Places plugins from highest to lowest priority. 
      Before placing a plugin, it places everything that plugin depends on, however low that chain sits in the priority list.
    priority_preserving: |
      Places each configured plugin next to the plugin it references, then keeps the remaining plugins in priority order.
  - item: "[Should I use `before` or `after`?](#choosing-between-before-and-after)"
    legacy: |
      Both `before` and `after` build the same dependency. 
      Writing the rule on either plugin gives the same order.
    priority_preserving: |
      The algorithm will move different plugins depending on where you put the setting. 
      `A before B` moves `A`, and `B after A` moves `B`.
  - item: "[Which plugins move?](#plugins-with-the-same-priority)"
    legacy: |
      The plugin you configure moves, plus any plugin that sits between it and its dependencies in priority order.
    priority_preserving: |
      The plugin you configure moves. 
      Unconfigured plugins keep their orders relative to each other.
{% endtable %}

Upgrading {{site.base_gateway}} doesn't change the algorithm, so your current `access` phase order stays the same until you [migrate to `priority_preserving`](#migrate-from-legacy-to-priority-preserving).

### Rule resolution example

Consider the following plugins, which have static priorities and one ordering rule:

{% table %}
columns:
  - title: Plugin
    key: plugin
  - title: Priority
    key: priority
  - title: Ordering rule
    key: ordering
rows:
  - plugin: "`pre-function`"
    priority: 1000000
    ordering: "`after: [opentelemetry]`"
  - plugin: "`request-callout`"
    priority: 812
    ordering: None
  - plugin: "`opentelemetry`"
    priority: 14
    ordering: None
{% endtable %}

By priority alone, the order is `pre-function`, `request-callout`, `opentelemetry`.

Under `priority_preserving`, `pre-function` has the highest priority but must wait for `opentelemetry`:

1. `request-callout` (812) and `opentelemetry` (14) are ready. `request-callout` runs first.
1. `opentelemetry` is the only plugin that's ready, so it runs next.
1. `pre-function` is now ready and runs last.

Under `legacy`, the walk reaches `pre-function` first and places its dependency, `opentelemetry`, before it. `request-callout` is placed last.

The following table shows the result for each algorithm:

{% table %}
columns:
  - title: Algorithm
    key: algorithm
  - title: Order
    key: order
rows:
  - algorithm: "`legacy`"
    order: "`opentelemetry`, `pre-function`, `request-callout`"
  - algorithm: "`priority_preserving`"
    order: "`request-callout`, `opentelemetry`, `pre-function`"
{% endtable %}

In both results, `pre-function` runs after `opentelemetry`.
The difference is in the other plugins:
* Under `legacy`, `request-callout` moves from second to last, even though it has no rule.
* Under `priority_preserving`, `request-callout` only moves up one position to make room for `pre-function`.

## Ordering behavior

The following sections describe how the algorithms handle specific rule configurations and request conditions.

### Choosing between before and after

With `legacy`, `A before: [B]` and `B after: [A]` record the same dependency, so they always give the same order.

With `priority_preserving`, the plugin carrying the rule is the one that moves, so the same relationship can produce different orders depending on where you write it.

For example, let's take four plugins in priority order: Key Auth (1250), LDAP Auth (1200), Header Cert Auth (1009), and Response Transformer (800).
Here's how the order changes depending on the algorithm you use:

{% table %}
columns:
  - title: Configuration
    key: config
  - title: "`priority_preserving` order"
    key: priority_preserving
  - title: "`legacy` order"
    key: legacy
rows:
  - config: "Response Transformer with `before: [ldap-auth]`"
    priority_preserving: |
      1. Key Auth
      1. Response Transformer
      1. LDAP Auth
      1. Header Cert Auth
    legacy: |
      1. Key Auth
      1. Response Transformer
      1. LDAP Auth
      1. Header Cert Auth
  - config: "LDAP Auth with `after: [response-transformer]`"
    priority_preserving: |
      1. Key Auth
      1. Header Cert Auth
      1. Response Transformer
      1. LDAP Auth
    legacy: |
      1. Key Auth
      1. Response Transformer
      1. LDAP Auth
      1. Header Cert Auth
{% endtable %}

### Unexpected placement when rules interact

When several rules interact, `priority_preserving` places each plugin next to its anchor without searching for the order that disturbs the fewest unconfigured plugins.

For example, let's look at Key Auth, LDAP Auth, Header Cert Auth, and Response Transformer in priority order. 
If you set Header Cert Auth `before` Response Transformer and Response Transformer `before` Key Auth, the resulting order looks like this:
  1. Header Cert Auth
  1. Response Transformer
  1. Key Auth
  1. LDAP Auth

LDAP Auth has no rule but drops from second to last.
The two rules only fix the relative order of Header Cert Auth, Response Transformer, and Key Auth, so LDAP Auth can run in any position and still satisfy them.
For example, running LDAP Auth first is also valid.
`priority_preserving` doesn't search for such an order, so it can move an unconfigured plugin further than necessary.

To keep a plugin in place, add a rule to that plugin.
In this case, LDAP Auth with `before: [header-cert-auth]` makes it run before the other three plugins.

### Plugins with the same priority

When plugins share a priority, {{site.base_gateway}} orders them by plugin name in descending order.
This applies to both algorithms and doesn't depend on load order.
A cloned plugin without a `priority` override inherits the priority of its source plugin.
See [cloned plugins](/gateway/entities/plugin/#cloning-plugins) for details.

### Scoped plugins

Dynamic ordering runs for each request.
A plugin scoped to a Route, Service, or Consumer only takes part in ordering for requests that match its scope.
A scoped plugin that doesn't match the request can still be the target of another plugin's `before` or `after` rule, but it doesn't contribute rules and doesn't run.
This means the order can differ between request paths.

### Circular rules

If your rules contradict each other, for example Response Transformer with `before: [key-auth]` and Key Auth with `before: [response-transformer]`, {{site.base_gateway}} reports a circular dependency error instead of picking an order.

With `legacy`, the message is:

```
There is a circular dependency in the graph. It is not possible to derive a topological sort.
```
{:.no-copy-code}

With `priority_preserving`, the error message also lists the plugins that form the circular dependency.

## Migrate from legacy to priority_preserving

The `plugin_ordering_algorithm` defaults to `legacy`, so upgrading {{site.base_gateway}} doesn't change your current `access` phase order.

To migrate to `priority_preserving`, follow these steps:

1. Set `plugin_ordering_algorithm = priority_preserving` in `kong.conf`, or set the `KONG_PLUGIN_ORDERING_ALGORITHM` environment variable, on every data plane.
  
   Use the same algorithm on every data plane.
   Data planes with different algorithms run the same configuration in a different order.

1. Restart the data planes.
1. Retest every Workspace that uses `ordering`. Its `access` phase order might change.

{:.info}
> **Note:** `plugin_ordering_algorithm` is a node-level setting.
> It has no effect on Workspaces that don't use `ordering`.

## Limitations

The two algorithms have different behaviors, but dynamic plugin ordering also has limitations that apply no matter which algorithm you use, such as cascading deletes, performance, and validation.
See [Known limitations of dynamic plugin ordering](/gateway/entities/plugin/#known-limitations-of-dynamic-plugin-ordering) before you use it in production.
