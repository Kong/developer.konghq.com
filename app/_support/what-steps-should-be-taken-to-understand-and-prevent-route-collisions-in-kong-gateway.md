---
title: Understanding and preventing route collisions in {{site.base_gateway}}
content_type: support
description: Route collisions occur when multiple routes match the same request criteria; use `KONG_ROUTE_VALIDATION_STRATEGY`, decK lint rulesets, and Kong Manager permission restrictions to detect and prevent them.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: What steps should be taken to understand and prevent route collisions in {{site.base_gateway}}?
  a: |
    Route collisions happen because Kong only checks for conflicts at route creation or update time, controlled by `KONG_ROUTE_VALIDATION_STRATEGY`, so pre-existing conflicts never get caught retroactively. Prevent them with a decK lint ruleset before deployment and read-only Kong Manager access for non-automation accounts, and catch any that slip through with Event Hooks that monitor route creation.
related_resources: []
---

## Problem

Route collisions occur when multiple routes match the same request criteria (path, method, host, etc.), causing ambiguous routing. Kong only validates for these conflicts at route creation or update time based on `KONG_ROUTE_VALIDATION_STRATEGY` — pre-existing conflicts aren't retroactively checked, so collisions can still reach production through manual changes or misconfigured pipelines.

## Solution

See also:

- How does {{site.base_gateway}} resolve entity conflicts between Workspaces?
- Getting error API route collides with an existing API

## Validation Scope & Timing

- Validation only occurs during route creation or update
- Pre-existing conflicts are not retroactively validated
- Changing strategy later won’t flag previously added conflicting routes

## Solutions

### Proactive: Lint Before Deployment

- Keep `KONG_ROUTE_VALIDATION_STRATEGY` set to `smart` to validate any duplicate routes.
- Use a deck ruleset to prevent misconfigured routes before they reach Kong, more information - deck file lint - deck | Kong Docs

```yaml
rules:
  # Rule 1: Ensure 'paths' field exists on every route
  # Purpose:
  #   Prevent routes missing the 'paths' field entirely,
  #   which can cause ambiguous routing or unexpected behavior.
  # Examples:
  #   Accepted:
  #     paths: ["/api"]
  #     paths: ["/users", "/admin"]
  #   Rejected:
  #     (missing 'paths' field)
  route-paths-exist:
    description: "Routes must have a 'paths' field"
    given: $.services[*].routes[*]
    severity: error
    then:
      function: truthy
      field: paths

  # Rule 2: Validate 'paths' is a non-empty array of non-empty, valid strings
  # Purpose:
  #   Ensure the 'paths' array is present and contains at least one non-empty string.
  #   Reject empty arrays and empty or whitespace-only strings.
  # Pattern explanation:
  #   "^\\S+.*$" means:
  #     - Path must start with a non-whitespace character
  #     - Followed by zero or more characters
  #
  # Examples:
  #   Accepted:
  #     paths: ["/api"]
  #     paths: ["/v1/users", "/v2/admin"]
  #     paths: ["/api/v1 test"]  # spaces allowed after first char
  #   Rejected:
  #     paths: []
  #     paths: [""]
  #     paths: [" "]
  #     paths: ["\t"]
  route-paths-validation:
    description: "Paths must be a non-empty array with non-empty strings starting with a non-whitespace character"
    given: $.services[*].routes[*]
    severity: error
    then:
      function: schema
      field: paths
      functionOptions:
        schema:
          type: array
          minItems: 1
          items:
            type: string
            pattern: "^\\S+.*$"

  # Rule 3: Disallow literal root path "/"
  # Purpose:
  #   Prevent routes that specify the root path "/" alone,
  #   which causes ambiguous or overly broad routing behavior.
  #
  # Pattern "^/[^/].*" explained:
  #   - Path must start with "/"
  #   - Followed by at least one character that is NOT "/"
  #   - So "/" alone is rejected, but "/api", "/v1/status" are allowed
  #
  # Examples:
  #   Accepted:
  #     paths: ["/api"]
  #     paths: ["/v1/status"]
  #   Rejected:
  #     paths: ["/"]
  route-no-root-path:
    description: "Reject routes that use '/' as a path"
    given: $.services[*].routes[*].paths[*]
    severity: error
    then:
      function: pattern
      functionOptions:
        match: "^/[^/].*"
```

- Audit your route configurations with decK dump or Kong’s Admin API.

Integration:

- Extend current deployment pipelines to introduce this deck lint ruleset to prevent misconfigured routes before they reach Kong.

#### Additional Considerations - Prevent Manual Route Creation

Problem:

Even with linting in place, users can manually create / update invalid routes in Kong Manager, bypassing safeguards.

Solution:

- Restrict Kong Manager to read-only access for most users
- Grant write permissions only to automation accounts or the admin reviewer.

### Reactive: Monitor with Event Hooks

Event Hooks can be used to detect route creation in real-time.
