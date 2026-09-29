---
title: How legacy dynamic plugin ordering works

description: A plain-language guide to the `legacy` dynamic plugin ordering algorithm in {{site.base_gateway}} — the principle behind it, worked examples, and its pros, cons, and corner cases.
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
  - text: How priority_preserving dynamic plugin ordering works
    url: /gateway/plugins/plugin-ordering-priority-preserving/
---

Every {{site.base_gateway}} plugin has a static [priority](/gateway/entities/plugin/#plugin-priority)
that decides the order plugins run in. [Dynamic plugin ordering](/gateway/entities/plugin/#dynamic-plugin-ordering)
lets you override that order for the [`access` phase](/gateway/entities/plugin/#plugin-contexts)
by giving a plugin an `ordering` rule that runs it `before` or `after` another plugin.

This page covers `legacy`, the algorithm `plugin_ordering_algorithm` selects by default. It
explains how `legacy` actually decides an order, with worked examples, and its pros, cons, and
corner cases. For the newer, opt-in algorithm, see [How priority_preserving dynamic plugin
ordering works](/gateway/plugins/plugin-ordering-priority-preserving/).

{:.warning}
> Dynamic ordering only affects the **`access` phase**. Every other phase (`header_filter`,
> `body_filter`, `response`, `log`) always runs in static [plugin priority](/gateway/entities/plugin/#plugin-priority)
> order, regardless of any `ordering` you set.

## How `legacy` decides the order

`legacy` builds a dependency graph from your `ordering` rules, then visits every plugin exactly
once, from highest priority to lowest. The first time the walk reaches a plugin, it doesn't place
that plugin yet. It first visits every plugin the current one depends on — recursively — and
places each of those first. Only once that recursion finishes does the current plugin get placed.

> **A plugin's entire dependency chain is placed immediately before that plugin is — however far
> down the priority list that chain reaches.**

`before` and `after` build the *same* dependency edge, regardless of which plugin carries the rule:

* `A before: [B]` records "`B` depends on `A`."
* `B after: [A]` also records "`B` depends on `A`."

Writing the same relationship either way therefore produces the same graph, and the same output.

A useful analogy: think of each plugin as a person in a line, but nobody can take their seat until
everyone they're waiting on has already sat down — including people *those* people are waiting on.
When your turn comes up in priority order, you first go fetch everyone you're waiting on, seat all
of them, and only then sit down yourself.

## Worked example

Take the customer scenario that motivated this feature:

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

By static priority alone the order would be `pre-function → request-callout → opentelemetry`. The
rule "`pre-function` after: `[opentelemetry]`" means `pre-function` depends on `opentelemetry`.
Here's how `legacy` builds the result:

1. The walk reaches `pre-function` first — it's the highest priority. It depends on
   `opentelemetry`, so visit that first.
2. `opentelemetry` depends on nothing. Place it. → placed so far: `opentelemetry`.
3. Back to `pre-function` — its one dependency is now placed, so place `pre-function` too. →
   placed so far: `opentelemetry, pre-function`.
4. The walk continues in priority order and reaches `request-callout`. It depends on nothing, so
   place it. → placed so far: `opentelemetry, pre-function, request-callout`.

**Result:** `opentelemetry → pre-function → request-callout`.

Notice what happened to `request-callout`: it carries no rule, and no rule names it either — but it
still moved, from 2nd place to last, purely because `pre-function`'s dependency chain was placed
ahead of it.

## `before` and `after` are the same rule under `legacy`

Take five plugins in natural priority order — `key-auth (1250)`, `ldap-auth (1200)`,
`header-cert-auth (1009)`, `response-transformer (800)`, `ai-proxy (770)` — and express one
relationship two ways:

```
natural order:                              key-auth, ldap-auth, header-cert-auth, response-transformer, ai-proxy

response-transformer before: [ldap-auth]:   key-auth, response-transformer, ldap-auth, header-cert-auth, ai-proxy
ldap-auth after: [response-transformer]:    key-auth, response-transformer, ldap-auth, header-cert-auth, ai-proxy
```

Both forms record the same dependency — "`ldap-auth` depends on `response-transformer`" — so both
produce the identical result: `response-transformer` rises two slots to the front of the pair, and
`ldap-auth` and `header-cert-auth` each drop one slot to make room, even though only one
relationship was ever configured. Under `priority_preserving`, the same two forms move *different*
plugins and can produce different orders — see [How priority_preserving dynamic plugin ordering
works](/gateway/plugins/plugin-ordering-priority-preserving/) if you want to compare them
directly.

## Pros

* **One mental model.** Once you see it as "place what I depend on before I'm placed, recursively,"
  every result follows from that one rule.
* **The original, most-tested behavior.** `legacy` is still the default `plugin_ordering_algorithm`,
  and upgrading {{site.base_gateway}} never changes it on its own.
* **Agrees with `priority_preserving` when a rule chain has no gaps.** If every link in a chain is
  configured — nothing left to priority alone — both algorithms give the same answer. Verified
  example: `header-cert-auth before: [response-transformer]`, `response-transformer before:
  [ai-proxy]`, and `ai-proxy before: [key-auth]`, with `ldap-auth` configuring nothing:

  ```
  legacy:              header-cert-auth, response-transformer, ai-proxy, key-auth, ldap-auth
  priority_preserving: header-cert-auth, response-transformer, ai-proxy, key-auth, ldap-auth
  ```

  The two algorithms only disagree when a plugin that carries no rule of its own sits *between* a
  mover and its anchor. A fully linked chain leaves nothing in between to disagree about.

## Cons and corner cases

* **Cascading displacement.** As the worked example above shows, a single rule can move plugins
  that never appear in any rule — not just the plugin the rule sits on.
* **`before`/`after` collapse removes a choice.** Because both forms build the same edge, you can't
  pick which of the two named plugins is the one that moves. `priority_preserving` always moves the
  plugin carrying the rule; `legacy` moves whichever the dependency direction happens to place.
* **Cycle errors don't name the cycle.** A contradictory pair of rules (for example
  `response-transformer before: [ai-proxy]` *and* `ai-proxy before: [response-transformer]`)
  produces exactly this message, with no path:

  > There is a circular dependency in the graph. It is not possible to derive a topological sort.

  `priority_preserving` reports the same kind of error with the offending plugins named in order,
  which makes a large configuration easier to fix.

## Plugins that share a priority

A cloned plugin that declares no `priority` override inherits its source plugin's priority, so
sharing a priority is routine rather than exotic. `key-auth-enc` and `key-auth`, for example, both
run at priority `1250`.

{{site.base_gateway}} breaks a tie deterministically: by plugin name, descending. It never depends
on load order or timing. An `ordering` rule between two plugins that share a priority is honored
exactly like any other rule — for example, `acl` (priority `950`) with `before: [key-auth]` lands
directly above `key-auth`, and `key-auth-enc` (also `1250`, alphabetically after `key-auth`) is
unaffected:

```
natural order:                   key-auth-enc, key-auth, acl
acl with before: [key-auth]:     key-auth-enc, acl, key-auth
```

## Scoping and the request path

Dynamic ordering runs per request. A plugin scoped to a specific Route, Service, or Consumer only
takes part in ordering for requests that match its scope. A scoped plugin that doesn't match the
current request still counts as a dependency target (so another plugin's `before`/`after` that
points at it is preserved), but it contributes no rules of its own and does not execute. This is
why the resulting order can differ from one request path to another.

## Known limitations

If you use dynamic ordering, test your configurations and handle the feature with care:

* **Cascading deletes**: {{site.base_gateway}} does not detect an `ordering` rule that points at a
  deleted plugin.
* **Performance**: sorting plugins during a request adds a small amount of latency. Reordering any
  plugin in a Workspace or control plane affects all plugins in that environment.
* **Validation**: {{site.base_gateway}} catches basic mistakes (such as circular rules) but cannot
  validate that an order makes sense for your business logic.

If the corner cases above matter for your setup, `priority_preserving` addresses the first two —
see [How priority_preserving dynamic plugin ordering
works](/gateway/plugins/plugin-ordering-priority-preserving/) for what changes and how to enable
it.
