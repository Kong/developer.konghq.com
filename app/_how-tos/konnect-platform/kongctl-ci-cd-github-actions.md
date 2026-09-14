---
title: APIOps for Konnect with kongctl and GitHub Actions
description: >-
  Store Konnect declarative configuration in GitHub, show diffs on pull
  requests, and apply changes on pushes to main.
content_type: how_to
permalink: /kongctl/ci-cd/github-actions/
breadcrumbs:
  - /kongctl/
products:
  - konnect
  - dev-portal
works_on:
  - konnect
tools:
  - kongctl
min_version:
  kongctl: '1.15.1'
tags:
  - declarative-config
automated_tests: false
tldr:
  q: How do I set up APIOps for Konnect with kongctl?
  a: |
    Store Konnect declarative configuration in GitHub and deploy a simple
    GitHub Actions workflow that shows diffs on pull requests and applies
    changes on pushes to main.
prereqs:
  skip_product: false
  show_works_on: false
  inline:
    - title: Konnect access
      content: |
        You need a {{site.konnect_short_name}} account and a personal or
        system account access token with permission to manage Dev Portals
        and APIs. See [kongctl authentication](/kongctl/authentication/).
      icon_url: /assets/icons/gateway.svg
    - title: GitHub repository
      content: |
        Use a GitHub repository with Actions enabled and a `main` branch.
        You need permission to add repository secrets and variables.
      icon_url: /assets/icons/code.svg
related_resources:
  - text: Declarative configuration with kongctl
    url: /kongctl/declarative/
  - text: Use kongctl with AI agent skills
    url: /kongctl/skills/
next_steps:
  - text: Learn about kongctl sync
    url: /kongctl/sync/
  - text: Explore Dev Portal
    url: /dev-portal/
---

This quickstart publishes a simple API and its OpenAPI specification to a
Dev Portal. It uses two files:

```text
konnect/portal.yaml
.github/workflows/kongctl.yaml
```

## Configure GitHub authentication

In **Settings > Secrets and variables > Actions**, add:

| Type | Name | Value |
| --- | --- | --- |
| Secret | `KONNECT_TOKEN` | Your Konnect access token |
| Variable | `KONNECT_REGION` | Your Konnect region, such as `us` or `eu` |

The workflow maps the token to `KONGCTL_DEFAULT_KONNECT_PAT`, so no
interactive login or additional credentials are needed.

## Declare the portal and API

Create a branch and add `konnect/portal.yaml`:

```yaml
_defaults:
  kongctl:
    namespace: portal-cicd

portals:
  - ref: example-portal
    name: Example Portal
    display_name: Example Portal
    authentication_enabled: false
    default_api_visibility: public
    default_page_visibility: public

apis:
  - ref: example-api
    name: Example API
    description: A simple API managed with GitHub Actions
    versions:
      - ref: example-api-v1
        version: "1.0.0"
        spec: |
          openapi: 3.0.3
          info:
            title: Example API
            version: 1.0.0
          paths:
            /hello:
              get:
                operationId: getHello
                responses:
                  '200':
                    description: A greeting
    publications:
      - ref: example-api-publication
        portal_id: !ref example-portal#id
        visibility: public
```

Choose names and a namespace unique to this repository before deploying.
The publication's `!ref` links the API to the portal. Portal authentication
is disabled so the published API documentation is publicly accessible.

The specification is inline to keep the example self-contained. See the
[portal example][ex] for a larger configuration with separate
specification files, pages, and customization.

[ex]: https://github.com/Kong/kongctl/tree/main/docs/examples/declarative/portal

## Add the GitHub Actions workflow

Create `.github/workflows/kongctl.yaml`:

{% raw %}
```yaml
name: Konnect APIOps

on:
  pull_request:
    branches: [main]
    paths:
      - konnect/**
      - .github/workflows/kongctl.yaml
  push:
    branches: [main]
    paths:
      - konnect/**
      - .github/workflows/kongctl.yaml

permissions:
  contents: read

concurrency:
  group: kongctl-${{ github.ref }}
  cancel-in-progress: false

jobs:
  configure:
    if: >-
      github.event_name == 'push' ||
      (github.event.pull_request.head.repo.full_name == github.repository &&
       github.actor != 'dependabot[bot]')
    runs-on: ubuntu-latest
    env:
      KONGCTL_DEFAULT_KONNECT_PAT: ${{ secrets.KONNECT_TOKEN }}
      KONGCTL_DEFAULT_KONNECT_REGION: ${{ vars.KONNECT_REGION }}
      NO_COLOR: '1'
    steps:
      - uses: actions/checkout@v7
      - uses: kong/setup-kongctl@v1
        with:
          kongctl-version: '1.15.1'
      - name: Check configuration
        run: |
          : "${KONGCTL_DEFAULT_KONNECT_PAT:?Set the KONNECT_TOKEN secret}"
          : "${KONGCTL_DEFAULT_KONNECT_REGION:?Set KONNECT_REGION}"
      - name: Show diff
        if: github.event_name == 'pull_request'
        shell: bash
        run: |
          kongctl diff --mode apply -f konnect/portal.yaml -o text \
            --region "$KONGCTL_DEFAULT_KONNECT_REGION" | tee diff.txt
          echo '## Konnect configuration diff' >> "$GITHUB_STEP_SUMMARY"
          echo '```text' >> "$GITHUB_STEP_SUMMARY"
          cat diff.txt >> "$GITHUB_STEP_SUMMARY"
          echo '```' >> "$GITHUB_STEP_SUMMARY"
      - name: Apply configuration
        if: github.event_name == 'push'
        run: |
          kongctl apply -f konnect/portal.yaml --auto-approve -o text \
            --region "$KONGCTL_DEFAULT_KONNECT_REGION"
```
{% endraw %}

Use trusted branches in the same repository. The workflow skips fork and
dependency-bot PRs because they lack repository secrets. The concurrency
group prevents overlapping deployments to `main`.

`diff` reads live Konnect state and displays proposed changes without
applying them. On a push to `main`, `apply` calculates a fresh plan and
executes it without prompting.

## Review and deploy

1. Commit both files and open a PR targeting `main`. Open the **Konnect
   APIOps** workflow run and review the diff in its summary.
1. Merge the PR. Check that the **Apply configuration** step succeeds, then
   open your Dev Portal in Konnect and verify the published API and spec.
1. In a new PR, change the API's `description`. Review the update in the
   diff, merge, and verify the change. Re-running the apply job without
   changing configuration should produce no further changes.

Every matching push to `main` deploys, including direct pushes. Use branch
rules if all changes must go through PR review. `apply` creates and updates
resources; use [sync](/kongctl/sync/) when you want removed declarations to
delete resources.
