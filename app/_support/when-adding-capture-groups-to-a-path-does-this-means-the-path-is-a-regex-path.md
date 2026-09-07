---
title: Adding capture groups to a path doesn't make it a regex path without a `~` prefix
content_type: support
description: On Kong Gateway 3.14.0.0, a path is only ever treated as a regex path if it is explicitly prefixed with a tilde (`~`) — adding capture groups alone does not make a path a regex path.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: the current documentation on routing
    url: /gateway/entities/route/
tldr:
  q: When adding capture groups to a path, does this mean the path is a regex path?
  a: |
    A path is only treated as a regex path when it's explicitly prefixed with `~` — adding capture groups alone doesn't do it. Once both example paths are correctly prefixed with `~`, the more specific Route wins; to force a specific Route to win regardless of the router's own specificity resolution, set its `regex_priority` explicitly.
---

## Problem

When Routes are defined, it's unclear whether adding a capture group automatically means the path is considered a Regular Expression. For example, take two Routes with paths defined as below:

```

~/(?<who>customer/invoices(?<rest>/service))$
```

```

~/(?<who>customer/invoices(?<rest>/service/[^/]+))$
```

If a request is sent to `/customer/invoices/service/1234`, it matches both Route paths, and it's unclear which Route actually resolves the request — the less specific one, or the more specific one.

## Solution

On Kong Gateway 3.14.0.0, a path is only ever treated as a regex path if it is explicitly prefixed with a tilde (`~`) — Kong no longer auto-detects regex-ness based on which characters a path contains, so everything else is treated as a literal/plain path, no matter what characters it contains.

Creating a Route with a path containing capture-group/regex syntax but **no** `~` prefix (for example `\/(?<who>customer\/invoices(?<rest>\/service))`) is rejected outright by the Admin API's schema validation:

```json

{"name":"schema violation","message":"schema violation (paths.1: should start with: / (fixed path) or ~/ (regex path))","code":2,"fields":{"paths":["should start with: / (fixed path) or ~/ (regex path)"]}}
```

So adding capture groups to a path does **not**, by itself, make the path a regex path — you must also prefix it with `~`. This is a change from older Kong versions, which used to infer regex-ness automatically by testing the path against the character class `[^[a-zA-Z0-9\.\-_~/%]*$` — any path containing characters outside that set (such as `(`, `)`, `?`, `<`, `>`) was implicitly treated as a regex, with no `~` prefix required. That heuristic only survives today as a one-time upgrade migration (`kong/db/migrations/migrate_path_280_300.lua`), which auto-prefixes any route path carried over from those older versions that used to be implicitly detected as a regex with `~` so that it keeps working after the upgrade. It plays no role in how paths you create today are evaluated.

Once both paths are correctly prefixed with `~`, both Routes are created successfully, and a request to `/customer/invoices/service/1234` matches both, resolved by the **more specific** Route (the one requiring at least one additional path segment after `/service`), not the less specific one.

If you need to guarantee a specific Route wins regardless of the router's own specificity resolution — or you observe the less-specific Route winning instead — set the `regex_priority` property explicitly on the Route you want to take precedence; a higher `regex_priority` value always wins when multiple regex Routes match the same request. See the current documentation on routing.
