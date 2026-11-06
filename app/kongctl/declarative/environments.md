---
title: "Managing multiple environments with kongctl"
description: "Reuse a manifest across independently managed dev and prod environments."
content_type: reference
layout: reference
works_on:
  - konnect
tools:
  - kongctl
breadcrumbs:
  - /kongctl/
  - /kongctl/declarative/
related_resources:
  - text: Declarative configuration overview
    url: /kongctl/declarative/
  - text: Supported resources
    url: /kongctl/supported-resources/
---

Use this workflow to reuse a manifest across independently synchronized
environments. Install kongctl and authenticate each profile before starting.
Review [sync scope](/kongctl/declarative/sync/) before choosing sync mode.

## Environment Management

Use distinct namespaces for environments that are synchronized independently,
optionally scoped by both team and environment, such as `payments-dev` and
`payments-prod`. Namespaces define kongctl ownership and reconciliation
boundaries. A profile selects credentials and configuration; it does not by
itself isolate ownership or sync deletion scope.

Reuse one manifest to target separate control planes and {{site.ai_gateway}}s:

```yaml
# environments.yaml
_defaults:
  kongctl:
    namespace: !env ENV_NS
control_planes:
  - ref: gateway
    name: !env CONTROL_PLANE_NAME
ai_gateways:
  - ref: ai-gateway
    name: !env AI_GATEWAY_NAME
    display_name: !env AI_GATEWAY_NAME
```

```shell
export ENV_NS=payments-dev
export CONTROL_PLANE_NAME=payments-dev
export AI_GATEWAY_NAME=payments-ai-dev
kongctl plan -f environments.yaml --profile dev --mode sync \
  --require-namespace=payments-dev --output-file dev-plan.json
kongctl diff --plan dev-plan.json
kongctl sync --plan dev-plan.json --profile dev

export ENV_NS=payments-prod
export CONTROL_PLANE_NAME=payments-prod
export AI_GATEWAY_NAME=payments-ai-prod
kongctl plan -f environments.yaml --profile prod --mode sync \
  --require-namespace=payments-prod --output-file prod-plan.json
kongctl diff --plan prod-plan.json
kongctl sync --plan prod-plan.json --profile prod
```

`--require-namespace` checks the resolved namespace against the expected value.
Use an independently configured expected value in CI to catch an incorrect
`ENV_NS`. `--require-any-namespace` requires an explicit resource namespace or
file default. Defaults-only files also select sync namespaces; external-only
file defaults satisfy guardrails without adding deletion scope.

Use `--mode apply` to create and update without pruning when the supplied
resources are only part of the environment's desired state. Use `--mode sync`
when the input represents the complete desired set for the selected collections
and namespaces. Do not share a team namespace across independent environment
sync runs: omitted sibling resources can become deletion candidates. A namespace
does not provide API authorization or protect against a parent gateway's cascade
deletion.

## Review and verify each environment

After applying each reviewed plan, verify its resources with the matching
profile:

```shell
kongctl get gateway control-planes --profile prod
kongctl get ai-gateways --profile prod
```

Keep ordinary deferred resource-name variables consistent between planning and
execution. Namespace values resolve during loading and remain fixed in the plan,
including with `store: false`; ordinary deferred values are read again at
execution. Use `store: true` for supported non-sensitive fields when the
approved value must remain fixed. See [environment
values](/kongctl/declarative/environment-values/).

For shared {{site.ai_gateway}}s, use the [ownership
rules](/kongctl/declarative/ownership/) and
[federation support matrix][federation-support-matrix] to determine which
children own independent namespaces.

[federation-support-matrix]:
https://github.com/Kong/kongctl/blob/main/docs/ai-gateway-federation.md
