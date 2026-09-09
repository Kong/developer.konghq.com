---
title: Dynamic plugin config with CEL

description: Reference for dynamically setting plugin config fields with CEL expressions in {{site.base_gateway}}.
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
  - text: CEL reference
    url: /gateway/plugins/expressions/
  - text: Plugin entity
    url: /gateway/entities/plugin/
  - text: ACL plugin
    url: /plugins/acl/
  - text: Rate Limiting plugin
    url: /plugins/rate-limiting/
  - text: Rate Limiting Advanced plugin
    url: /plugins/rate-limiting-advanced/
---

A plugin's config can be computed per request from a [CEL expression](/gateway/plugins/expressions/), for example, reading an attribute of the authenticated Consumer or Principal, instead of always using a fixed value.

{{site.base_gateway}} supports this through the following mechanisms:

* **[Expressible config fields](#expressible-config-fields)**: A config field has a paired CEL expression field. If the expression evaluates successfully, {{site.base_gateway}} uses its result; otherwise, it falls back to the field's static value.
* **[Direct CEL fields](#direct-cel-fields)**: A config field's value is a CEL expression. There's no separate static value to fall back to.

Both are different from a plugin's [`condition`](/gateway/plugins/conditions/) field, which decides whether the whole plugin runs for a request. Expressible config fields and direct CEL fields don't skip the plugin; they only change the value of one specific field.

The following plugins support expressions in fields:

<!--vale off-->
{% table %}
columns:
  - title: Plugin
    key: plugin
  - title: Mechanism
    key: mechanism
  - title: Fields
    key: fields
rows:
  - plugin: "[ACL](/plugins/acl/)"
    mechanism: Direct CEL fields
    fields: "`allow_when`, `deny_when`"
  - plugin: "[Rate Limiting](/plugins/rate-limiting/)"
    mechanism: Expressible config fields
    fields: "`custom_key`, `second`, `minute`, `hour`, `day`, `month`, `year`"
  - plugin: "[Rate Limiting Advanced](/plugins/rate-limiting-advanced/)"
    mechanism: Expressible config fields
    fields: "`limit`, `custom_key`"
{% endtable %}
<!--vale on-->

See each plugin's own documentation for how its fields are used.

## Expressible config fields

A plugin schema field marked as expressible has a matching field of the same name under a top-level `expressions` block, alongside `config`:

```yaml
plugins:
  - name: rate-limiting-advanced
    config:
      limit:
        - 10          # static fallback
      window_size:
        - 60
    expressions:
      limit:
        - consumer.tags.exists(t, t == "vip") ? 1000 : 10
```

For each request, {{site.base_gateway}} evaluates the field's expression:

* If the expression evaluates successfully and produces a value of the correct type for that field, {{site.base_gateway}} uses that value for the request.
* If the expression is unset, invalid, or fails to evaluate (for example, because a referenced field is missing), {{site.base_gateway}} falls back to the field's static value in `config`.

This fallback means an expressible field can never cause a request to fail. 
If you want to use an expression for a field, make sure its sibling static `config.FIELD` value is also set.
For example, to use `expressions.limit`, also set `config.limit`.

Expressible fields use the same CEL field vocabulary, types, and null-handling rules as plugin conditions. 
See the CEL expressions reference:
* [Available fields](/gateway/plugins/expressions/#available-fields)
* [Types](/gateway/plugins/expressions/#types)
* [Null handling](/gateway/plugins/expressions/#null-handling)

### Array fields

If the underlying config field is an array, its expression is also an array, with one expression per element, in the same order. For example, the Rate Limiting Advanced plugin's `limit` field holds one value per configured window:

```yaml
config:
  limit: [10, 100]
  window_size: [60, 3600]
expressions:
  limit:
    - consumer.tags.exists(t, t == "vip") ? 1000 : 10
    - consumer.tags.exists(t, t == "vip") ? 10000 : 100
```

Leave an element as an empty string (`""`) to keep that position's static `config` value with no expression override:

```yaml
expressions:
  limit:
    - consumer.tags.exists(t, t == "vip") ? 1000 : 10
    - ""
```

### Handling default values

Unlike `condition`, an expressible field's expression can't be wrapped in `default()`. 
The sibling `config` value is already the automatic fallback, so `default()` would be redundant. Accessing a missing key in a map field like `principal.metadata` also doesn't need a `has()` guard: if the key is absent, the expression fails to evaluate, and {{site.base_gateway}} falls back to the static `config` value, the same as for any other evaluation failure.

```yaml
expressions:
  custom_key: principal.metadata.partner_id
```

Use `has()` only if you want the expression itself to compute a different fallback than the static `config` value when a key is missing:

```yaml
expressions:
  custom_key: "has(principal.metadata.partner_id) ? principal.metadata.partner_id : \"unknown\""
```

## Direct CEL fields

Some plugin config fields don't have a static equivalent to fall back to. 
Instead, the field itself holds one or more CEL expressions, and there is no parallel static value.

The [ACL](/plugins/acl/) plugin's `allow_when` and `deny_when` fields work this way: each field is an array of CEL boolean expressions, evaluated against the same request context as plugin conditions. 
`allow_when` and `deny_when` are mutually exclusive with `allow` and `deny`. 
Exactly one of `allow`, `deny`, `allow_when`, or `deny_when` must be set on a given ACL plugin instance.

```yaml
plugins:
  - name: acl
    config:
      allow_when:
        - "has(principal.metadata.tier) && principal.metadata.tier == \"partner\""
```

Because there's no static value to fall back to, a direct CEL field that fails to evaluate at runtime behaves according to that plugin's own documented error handling, rather than falling back to a static config value. 

For example, in ACL, `allow_when` and `deny_when` are treated differently:
* If an `allow_when` expression fails, the request is denied with a `403`, the same safe default as when no expression matches at all. 
* If a `deny_when` expression fails, the plugin fails closed with a `500`, because silently treating that error as "no match" could let through a request that should have been denied. 

See [Dynamic allow and deny rules](/plugins/acl/#dynamic-allow-and-deny-rules) in the ACL plugin documentation for details.

## Limitations

* Expressible fields and direct CEL fields are only supported in the HTTP subsystem. They can't be used with stream (TCP, TLS, UDP) Routes.
* In [hybrid mode](/gateway/hybrid-mode/), if the control plane is running a version that supports expressible fields and a data plane is running an earlier version, {{site.base_gateway}} strips the plugin's `expressions` for that data plane, and the plugin behaves as if no expression were configured, falling back to its static `config` value.
* Direct CEL fields don't have a static `config` value to fall back to, so this hybrid-mode compatibility works differently: {{site.base_gateway}} doesn't sync the plugin's config to a data plane that doesn't support the direct CEL field being used. For example, an older data plane won't receive an ACL plugin instance configured with `allow_when` or `deny_when` until it's upgraded.
* Only fields the plugin's schema marks as expressible can have an `expressions` entry. The plugin's schema lists these fields under its `expressions` key. Setting `expressions` for any other field is rejected at configuration time.
* An expressible field's expression must resolve to a type compatible with that field's own Kong type (for example, a `number` field requires a CEL `double`, `int`, `uint`, or `dyn` result).
