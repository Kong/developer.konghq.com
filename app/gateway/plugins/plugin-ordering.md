---
title: How dynamic plugin ordering works

description: A plain-language guide to dynamic plugin ordering in {{site.base_gateway}} — the principle behind it, how the priority_preserving and legacy algorithms differ, and how to predict the exact execution order your ordering rules produce.
content_type: reference
layout: reference

products:
  - gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.16'

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

Two consequences fall out of that rule, and they are the whole behavior:

* **Only the plugin you name moves.** When you write `before` or `after` on a plugin, that plugin
  (the *mover*) is the one repositioned — next to the plugin it points at (the *anchor*). Think of
  the mover as being given a temporary position right beside its anchor (just above it for
  `before`, just below it for `after`). Every plugin you did **not** configure keeps its order
  relative to every other plugin you didn't configure — though its absolute position can shift by
  a slot or two when a mover passes through it on the way to its anchor. (See `before` ≠ `after`,
  below, for what that looks like.)
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

Notice what did **not** happen: `request-callout`, which you never configured, was not itself
repositioned by any rule — it rose one slot only because `pre-function` dropped past it on the way
to its anchor. You moved `pre-function`, and only `pre-function` carried an `ordering` rule.

## Plugins that share a priority

A cloned plugin that declares no `priority` override inherits its source plugin's priority, so
sharing a priority is routine rather than exotic. `key-auth-enc` and `key-auth`, for example, both
run at priority `1250`.

{{site.base_gateway}} breaks a tie deterministically: by plugin name, descending. It never depends
on load order or timing, and this holds for both ordering algorithms. An `ordering` rule between
two plugins that share a priority is honored exactly like any other rule — for example, `acl`
(priority `950`) with `before: [key-auth]` lands directly above `key-auth`, and `key-auth-enc`
(also `1250`, alphabetically after `key-auth`) is unaffected either way:

```
natural order:                   key-auth-enc, key-auth, acl
acl with before: [key-auth]:     key-auth-enc, acl, key-auth
```

## `priority_preserving` vs. `legacy` ordering

{{site.base_gateway}} includes two ordering algorithms, selected by the
[`plugin_ordering_algorithm`](/gateway/configuration/)
configuration parameter:

* **`priority_preserving`** — the algorithm described above. Only the configured plugin moves;
  every other plugin's order relative to the other plugins you didn't configure is unchanged;
  `before` and `after` can differ.
* **`legacy`** — the original algorithm, kept so upgrades don't change behavior unexpectedly. It
  treats `before` and `after` as the same relationship, and repositioning one plugin can pull
  unrelated plugins out of their priority slots.

The scenario above shows the difference plainly:

{% table %}
columns:
  - title: ""
    key: item
  - title: "`priority_preserving`"
    key: priority_preserving
  - title: "`legacy`"
    key: legacy
rows:
  - item: Result
    priority_preserving: "`request-callout, opentelemetry, pre-function`"
    legacy: "`opentelemetry, pre-function, request-callout`"
  - item: What moved
    priority_preserving: "only `pre-function` (as configured)"
    legacy: "`opentelemetry` jumped to the front and `request-callout` was pushed to the end — **neither was configured**"
{% endtable %}

Under `legacy`, moving `pre-function` displaced `opentelemetry` and `request-callout` even though
you never mentioned them. That surprise — an unrelated plugin changing position — is exactly what
`priority_preserving` removes.

### `before` ≠ `after` under `priority_preserving`

Take five plugins in natural priority order — `key-auth (1250)`, `ldap-auth (1200)`,
`header-cert-auth (1009)`, `response-transformer (800)`, `ai-proxy (770)` — and express the same
relationship two ways:

{% table %}
columns:
  - title: Configuration
    key: config
  - title: "`priority_preserving` result"
    key: priority_preserving
  - title: "`legacy` result"
    key: legacy
rows:
  - config: "`response-transformer` with `before: [ldap-auth]`"
    priority_preserving: "`key-auth, response-transformer, ldap-auth, header-cert-auth, ai-proxy`"
    legacy: "`key-auth, response-transformer, ldap-auth, header-cert-auth, ai-proxy`"
  - config: "`ldap-auth` with `after: [response-transformer]`"
    priority_preserving: "`key-auth, header-cert-auth, response-transformer, ldap-auth, ai-proxy`"
    legacy: "`key-auth, response-transformer, ldap-auth, header-cert-auth, ai-proxy`"
{% endtable %}

Under `priority_preserving`, `response-transformer before: [ldap-auth]` moves only
`response-transformer` — up past `header-cert-auth` — to land just above `ldap-auth`;
`header-cert-auth` drops one slot as a side effect. `ldap-auth after: [response-transformer]`
moves only `ldap-auth` — down past `header-cert-auth` *and* `response-transformer` — to land just
below `response-transformer`; this time `header-cert-auth` and `response-transformer` each rise
one slot. Neither bystander is untouched, but its order relative to `key-auth` and `ai-proxy` is
the same in both cases. Under `legacy`, `before` and `after` are identical, so **both forms produce
the same order regardless of which plugin you write the rule on** — `response-transformer` rises
two slots to the front of the pair, and `ldap-auth` and `header-cert-auth` both drop one slot to
make room, even though only one relationship was ever configured.

## Why `priority_preserving` is easier to work with

* **Predictable.** Only the plugin you configure moves. You never have to reason about side effects
  on plugins you didn't touch.
* **Deterministic.** The same configuration always produces the same order — on every node, every
  time. Whatever you see in testing is what you get in production.
* **Expressive.** Because `before` and `after` move different plugins, you can say precisely which
  plugin should relocate.

### What {{site.base_gateway}} guarantees (both algorithms)

* **Your rules are always honored, or the config is rejected.** Every `before`/`after` you set is
  satisfied. If your rules contradict each other (for example `response-transformer before:
  [ai-proxy]` *and* `ai-proxy before: [response-transformer]`), {{site.base_gateway}} reports a
  **circular dependency** error instead of guessing.
* **The result is deterministic.** It never depends on load order or timing.

### What it does not promise

* **Exact adjacency when rules interact.** If a plugin is both a mover and an anchor, or sits on a
  chain of rules, it lands as close to its anchor as *all* your rules allow — which may not be
  immediately adjacent. The order is still correct; it just reflects the whole set of rules, not one
  rule in isolation.
* **A priority-looking result when you constrain many plugins.** If you order most of your plugins
  explicitly, the output is dictated by those rules and can look nothing like priority order. That's
  expected — you asked for it.
* **The tightest possible order when rules interact.** `priority_preserving` places each rule next
  to its anchor rather than searching every valid order for the one with the least overall
  disruption. In roughly one configuration in twenty that uses `ordering`, this pushes an
  unconfigured plugin one or two places further than a hand-picked order would need. For example:

  ```
  natural priority order: key-auth, ldap-auth, response-transformer, ai-proxy

  rules: response-transformer before: [ai-proxy]
         ai-proxy before: [key-auth]

  result: response-transformer, ai-proxy, key-auth, ldap-auth
  ```

  `ldap-auth` carries no `ordering` rule of its own, yet it drops from 2nd to last — a valid order
  exists that satisfies the same two rules without moving `ldap-auth` at all (`ldap-auth,
  response-transformer, ai-proxy, key-auth`), but `priority_preserving` doesn't search for it.

  **If this matters for your setup, pin the affected plugin with its own rule.** Adding
  `ldap-auth before: [response-transformer]` here recovers the tighter order — your rules are
  always honored, so naming the plugin you want protected is the direct fix, rather than reasoning
  about priority values.

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
access-phase order**. When you're ready to adopt the clearer `priority_preserving` behavior:

1. Set `plugin_ordering_algorithm = priority_preserving` in `kong.conf` (or the
   `KONG_PLUGIN_ORDERING_ALGORITHM` environment variable) on your data planes.
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
* **Non-optimal placement**: in an uncommon case, `priority_preserving` can displace an
  unconfigured plugin more than necessary when multiple `ordering` rules interact. See [What it
  does not promise](#what-it-does-not-promise) above for a worked example and the fix.
