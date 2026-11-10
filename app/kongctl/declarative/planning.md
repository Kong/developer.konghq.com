---
title: "Planning, reviewing, and executing changes with kongctl"
description: "Choose commands, review saved plans, and understand execution and recovery."
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

Read this page when selecting a command, reviewing saved plans, or separating
planning from execution.

## Plan artifacts

A plan records the operations needed to move resources from their current state
to the declared desired state. Every declarative execution uses a plan. Saving
the plan as JSON is optional; it enables a separate review and execution step.

### How planning works

The declarative configuration commands (`apply`, `sync`, `delete`, `diff`) use
the planning engine internally:

**Implicit Planning** (direct execution):

```shell
# Internally generates plan and executes it
kongctl apply -f config.yaml
```

**Explicit Planning** (two-phase execution):

```shell
# Phase 1: Generate plan artifact
kongctl plan --mode apply -f config.yaml --output-file plan.json

# Phase 2: Execute plan artifact (can be done later)
kongctl apply --plan plan.json
```

Saved plans have strict execution ownership. `apply --plan`, `sync --plan`, and
`delete --plan` accept only plans generated in `apply`, `sync`, and `delete`
mode, respectively. `diff --plan` can inspect a plan generated in any mode.

### Why use plan artifacts?

Plan artifacts enable more advanced workflows:

- Keep reviewed plans as controlled build artifacts, which document exactly what was planned
- Share plans with team members for review before execution
- Generate plans in CI and apply them after approval
- Inspect earlier changes when preparing a fresh plan

## Plan artifact workflows

### Basic plan review workflow

Developer creates plan:

```shell
kongctl plan --mode apply -f config.yaml \
  --output-file proposed-changes.json
```

Review changes visually:

```shell
kongctl diff --plan proposed-changes.json
```

Share the plan as a controlled CI artifact or review attachment. Literal and
stored values can remain in executable plans. See [environment
values](/kongctl/declarative/environment-values/) for the difference between
executable plans and redacted review output.

After approval, apply the plan:

```shell
kongctl apply --plan proposed-changes.json
```

### Production deployment with approval

```shell
# CI/CD Pipeline Stage 1: Plan Generation
kongctl plan --mode sync -f production-config.yaml \
  --output-file production-plan.json

# Stage 2: Manual approval gate
# - Plan artifact is stored as build artifact
# - Team reviews plan details
# - Approval triggers next stage

# Stage 3: Plan Execution
kongctl sync --plan production-plan.json --auto-approve
```

## Returning to a previous configuration

A saved plan records changes calculated against a particular remote state. It is
not a snapshot of the complete desired state, and replaying an old plan is not a
rollback procedure.

Restore the desired manifest revision from version control, generate a fresh
plan against current {{site.konnect_short_name}} state, and review it before execution. Review
deletions and write-only values separately: restoring a manifest cannot recover
deleted data or secret material that {{site.konnect_short_name}} does not return.

## Choose a command

| Goal | Command |
| --- | --- |
| Preview creates and updates | `kongctl diff --mode apply -f config.yaml` |
| Preview sync deletes | `kongctl diff --mode sync -f config.yaml` |
| Create or update resources | `kongctl apply -f config.yaml` |
| Reconcile explicitly scoped collections | `kongctl sync -f config.yaml` |
| Delete resources selected by a manifest | `kongctl delete -f config.yaml` |
| Inspect a saved plan of any mode | `kongctl diff --plan plan.json` |
| Establish ownership of existing resources | `kongctl adopt --help` |
| Export current state | `kongctl dump declarative --help` |

Use `kongctl <command> --help` for flags and supported resource types.
`kongctl plan` writes executable JSON; redacted diff output is for review. For
updates, text diff shows changed fields. JSON and YAML diff expose those changes
in `changed_fields`, while `fields` remains the execution payload.

## Values and portability

Plan mode and resolved namespace ownership stay fixed in a saved plan. Ordinary
deferred environment values are read again at execution; stored environment
values remain fixed. See [environment
values](/kongctl/declarative/environment-values/) and [write-only
secrets](/kongctl/declarative/secrets/) before moving a plan between
environments. Secret files and decK state files also have plan-relative path
rules.

For CI, choose whether to execute an approved artifact or calculate a fresh plan
from the merged configuration. These are distinct review boundaries. See the
[GitHub Actions quickstart][cicd-quickstart] for an inline apply workflow.

[cicd-quickstart]: https://developer.konghq.com/kongctl/ci-cd/github-actions/
