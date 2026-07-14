---
title: How dynamic plugin ordering works

description: A plain-language guide to dynamic plugin ordering in {{site.base_gateway}} — the principle behind it, how the new and legacy algorithms differ, and how to predict the exact execution order your ordering rules produce.
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

related_resources:
  - text: Plugin entity reference
    url: /gateway/entities/plugin/
  - text: Plugin priority
    url: /gateway/entities/plugin/#plugin-priority
---

Every {{site.base_gateway}} plugin has a static [priority](/gateway/entities/plugin/#plugin-priority)
that decides the order plugins run in. [Dynamic plugin ordering](/gateway/entities/plugin/#dynamic-plugin-ordering)
lets you override that order for the [`access` phase](/gateway/entities/plugin/#plugin-contexts)
by giving a plugin an `ordering` rule that runs it `before` or `after` another plugin.

This page explains **how that reordering is decided**, so you can predict the exact result of any
`ordering` configuration — the part that has historically been hard to reason about.

{:.warning}
> Dynamic ordering only affects the **`access` phase**. Every other phase (`header_filter`,
> `body_filter`, `response`, `log`) always runs in static [plugin priority](/gateway/entities/plugin/#plugin-priority)
> order, regardless of any `ordering` you set.

## The one rule that decides everything

{{site.base_gateway}} builds the access-phase order by repeating a single step until every plugin
has run:

> **At each step, run the highest-priority plugin whose `after` requirements are already met.**

`before` and `after` only decide *which* plugins are allowed to run yet. Among the plugins that are
allowed, the higher priority always goes first.

A useful analogy is boarding a plane: first class boards before economy, but a first-class
passenger who hasn't reached the gate yet has to wait while a checked-in economy passenger boards.
Priority decides who goes first; "not ready yet" always wins.

Two consequences fall out of that rule, and they are the whole behavior:

* **Only the plugin you name moves.** When you write `before` or `after` on a plugin, that plugin
  (the *mover*) is the one repositioned — next to the plugin it points at (the *anchor*). Think of
  the mover as being given a temporary position right beside its anchor (just above it for
  `before`, just below it for `after`). Every plugin you did **not** configure keeps its natural
  priority slot.
* **`before` and `after` are not the same statement.** `A before B` moves `A`; `B after A` moves
  `B`. They describe the same relationship but relocate different plugins, so they can produce
  different orders. Choose the form that names the plugin you actually want to move.

## Predict the order, step by step

Because the order is built by that one repeated step, you can always work it out by hand. Take the
customer scenario that motivated this feature:

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
    ordering: "*(none)*"
  - plugin: "`opentelemetry`"
    priority: 14
    ordering: "*(none)*"
{% endtable %}

By static priority alone the order would be `pre-function → request-callout → opentelemetry`. You've
asked for one change: run `pre-function` **after** `opentelemetry`. Here's how {{site.base_gateway}}
builds the result:

1. **Ready:** `request-callout` (812), `opentelemetry` (14). `pre-function` is *not* ready — it must
   wait for `opentelemetry`. → Run the highest-priority ready plugin: **`request-callout`**.
2. **Ready:** `opentelemetry` (14). → Run **`opentelemetry`**. This satisfies `pre-function`'s
   requirement.
3. **Ready:** `pre-function`. → Run **`pre-function`**.

**Result:** `request-callout → opentelemetry → pre-function`.

Notice what did **not** happen: `request-callout`, which you never configured, kept its place. You
moved `pre-function`, and only `pre-function` moved.

## New vs. legacy ordering

{{site.base_gateway}} includes two ordering algorithms, selected by the
[`plugin_ordering_algorithm`](/gateway/configuration/)
configuration parameter:

* **`new`** — the algorithm described above. Only the configured plugin moves; unconfigured plugins
  keep their priority slots; `before` and `after` can differ.
* **`legacy`** — the original algorithm, kept so upgrades don't change behavior unexpectedly. It
  treats `before` and `after` as the same relationship, and repositioning one plugin can pull
  unrelated plugins out of their priority slots.

The scenario above shows the difference plainly:

{% table %}
columns:
  - title: ""
    key: item
  - title: "`new`"
    key: new
  - title: "`legacy`"
    key: legacy
rows:
  - item: Result
    new: "`request-callout, opentelemetry, pre-function`"
    legacy: "`opentelemetry, pre-function, request-callout`"
  - item: What moved
    new: "only `pre-function` (as configured)"
    legacy: "`opentelemetry` jumped to the front and `request-callout` was pushed to the end — **neither was configured**"
{% endtable %}

Under `legacy`, moving `pre-function` displaced `opentelemetry` and `request-callout` even though
you never mentioned them. That surprise — an unrelated plugin changing position — is exactly what
`new` removes.

### `before` ≠ `after` under `new`

Take five plugins in natural priority order `e(500), d(400), c(300), b(200), a(100)` and express
the same relationship two ways:

{% table %}
columns:
  - title: Configuration
    key: config
  - title: "`new` result"
    key: new
  - title: "`legacy` result"
    key: legacy
rows:
  - config: "`b` with `before: [d]`"
    new: "`e, b, d, c, a`"
    legacy: "`e, b, d, c, a`"
  - config: "`d` with `after: [b]`"
    new: "`e, c, b, d, a`"
    legacy: "`e, b, d, c, a`"
{% endtable %}

Under `new`, `d after b` moves only `d` (down to just after `b`), so `c` and `e` stay put. Under
`legacy`, `before` and `after` are identical, so both forms produce the same order — and to get
there `legacy` lifts `b`, the plugin you only *referenced*.

## Why `new` is easier to work with

* **Predictable.** Only the plugin you configure moves. You never have to reason about side effects
  on plugins you didn't touch.
* **Deterministic.** The same configuration always produces the same order — on every node, every
  time. Whatever you see in testing is what you get in production.
* **Expressive.** Because `before` and `after` move different plugins, you can say precisely which
  plugin should relocate.

### What {{site.base_gateway}} guarantees (both algorithms)

* **Your rules are always honored, or the config is rejected.** Every `before`/`after` you set is
  satisfied. If your rules contradict each other (for example `A before B` *and* `B before A`),
  {{site.base_gateway}} reports a **circular dependency** error instead of guessing.
* **The result is deterministic.** It never depends on load order or timing.

### What it does not promise

* **Exact adjacency when rules interact.** If a plugin is both a mover and an anchor, or sits on a
  chain of rules, it lands as close to its anchor as *all* your rules allow — which may not be
  immediately adjacent. The order is still correct; it just reflects the whole set of rules, not one
  rule in isolation.
* **A priority-looking result when you constrain many plugins.** If you order most of your plugins
  explicitly, the output is dictated by those rules and can look nothing like priority order. That's
  expected — you asked for it.

## Scoping and the request path

Dynamic ordering runs per request. A plugin scoped to a specific Route, Service, or Consumer only
takes part in ordering for requests that match its scope. A scoped plugin that doesn't match the
current request still counts as an **anchor** (so another plugin's `before`/`after` that points at
it is preserved), but it contributes no rules of its own and does not execute. This is why the
resulting order can differ from one request path to another.

<!-- TODO(productionize): embed the interactive plugin ordering simulator include here
     (app/_includes/components/plugin_ordering_simulator.html). A validated standalone
     prototype of this tool exists; the Vue component wiring is a follow-up. -->

## Choosing an algorithm on upgrade

`plugin_ordering_algorithm` defaults to `legacy`, so **upgrading does not change your current
access-phase order**. When you're ready to adopt the clearer `new` behavior:

1. Set `plugin_ordering_algorithm = new` in `kong.conf` (or the `KONG_PLUGIN_ORDERING_ALGORITHM`
   environment variable) on your data planes.
2. Re-test any Workspace that uses `ordering` — the access-phase order of those Workspaces may
   change (that's the fix taking effect). Workspaces with no `ordering` are unaffected either way.

The setting is read per node, so you can roll it out one data plane at a time.

## Known limitations

If you use dynamic ordering, test your configurations and handle the feature with care:

* **Cascading deletes**: {{site.base_gateway}} does not detect an `ordering` rule that points at a
  deleted plugin.
* **Performance**: sorting plugins during a request adds a small amount of latency. Reordering any
  plugin in a Workspace or control plane affects all plugins in that environment.
* **Validation**: {{site.base_gateway}} catches basic mistakes (such as circular rules) but cannot
  validate that an order makes sense for your business logic.
