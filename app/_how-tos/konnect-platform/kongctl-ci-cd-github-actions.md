---
title: Set up CI/CD with kongctl and GitHub Actions
description: >-
  Review {{site.ai_gateway}} configuration diffs in pull requests and apply
  changes from main with kongctl and GitHub Actions.
content_type: how_to
permalink: /kongctl/ci-cd/github-actions/
breadcrumbs:
  - /kongctl/
products:
  - konnect
  - ai-gateway
works_on:
  - konnect
tools:
  - kongctl
min_version:
  kongctl: '1.15.1'
tags:
  - declarative-config
  - ai
automated_tests: false
tldr:
  q: How do I use kongctl in GitHub Actions?
  a: |
    Store declarative configuration in Git. Run `kongctl diff --mode apply`
    in pull requests, then `kongctl apply --auto-approve` on pushes to main.
prereqs:
  skip_product: false
  show_works_on: false
  inline:
    - title: Konnect access
      content: |
        You need a {{site.konnect_short_name}} account with access to
        {{site.ai_gateway}} and a personal or system account access token
        with permission to read and manage {{site.ai_gateway}} resources. See
        [kongctl authentication](/kongctl/authentication/).
      icon_url: /assets/icons/gateway.svg
    - title: GitHub repository and OpenAI key
      content: |
        Use a GitHub repository with Actions enabled and a `main` branch.
        You need permission to add repository secrets and variables, and an
        [OpenAI API key](https://platform.openai.com/api-keys).
      icon_url: /assets/icons/ai.svg
related_resources:
  - text: Declarative configuration with kongctl
    url: /kongctl/declarative/
  - text: "{{site.ai_gateway}} resource reference"
    url: /kongctl/supported-resources/#ai-gateway
  - text: Use kongctl with AI agent skills
    url: /kongctl/skills/
next_steps:
  - text: Learn about kongctl sync
    url: /kongctl/sync/
  - text: Manage write-only secrets
    url: /kongctl/declarative/#write-only-secret-fields
---

This quickstart manages one {{site.ai_gateway}}, an OpenAI Model Provider,
and a Model in {{site.konnect_short_name}}. The repository contains three
files:

```text
konnect/ai-gateway.yaml
.github/workflows/kongctl-diff.yaml
.github/workflows/kongctl-apply.yaml
```

Pull requests display a diff without changing Konnect. Merging into `main`
runs `apply`, which calculates changes against current Konnect state and
executes them. There are no plan artifacts to transfer between workflows.

## Configure repository secrets and variables

In your GitHub repository, open **Settings > Secrets and variables > Actions**.
Add these repository secrets:

| Secret | Value |
| --- | --- |
| `KONNECT_TOKEN` | Your Konnect personal or system account access token |
| `OPENAI_API_KEY` | Your OpenAI API key, without the `Bearer ` prefix |

On the **Variables** tab, add `KONNECT_REGION` with your Konnect region, such
as `us` or `eu`. Both workflows must use the same region and account.

The workflows map `KONNECT_TOKEN` to `KONGCTL_DEFAULT_KONNECT_PAT`, so no
interactive `kongctl login` is needed. Only the apply step receives
`OPENAI_API_KEY`.

Use this example with trusted contributors opening branches in the same
repository. Fork and dependency-bot PRs are skipped because their workflow runs
do not receive repository secrets. See
[Using secrets in GitHub Actions][github-secrets].

[github-secrets]: https://docs.github.com/actions/security-guides/encrypted-secrets

## Declare the gateway, provider, and model

Create a branch in your repository and add `konnect/ai-gateway.yaml`:

```yaml
_defaults:
  kongctl:
    namespace: ai-gateway-cicd

ai_gateways:
  - ref: cicd-ai-gateway
    name: cicd-ai-gateway
    display_name: CI/CD AI Gateway
    description: AI Gateway managed with GitHub Actions
    model_providers:
      - ref: openai
        name: openai
        display_name: OpenAI
        type: openai
        config:
          auth:
            type: basic
            headers:
              - name: Authorization
                value: !secret
                  parts:
                    - "Bearer "
                    - !env OPENAI_API_KEY
    models:
      - ref: example-model
        name: example-model
        display_name: Example Model
        type: model
        formats:
          - type: openai
        config:
          route:
            paths:
              - /v1
            model:
              body_param: model
              values:
                - example-model
        targets:
          - name: gpt-4o
            provider: openai
            config:
              type: openai
        capabilities:
          - generate
```

Choose a namespace and gateway name unique to this repository before the
first deployment. Keep `name` and `ref` stable in later changes.

`!secret` defers reading the OpenAI key until execution. PR diffs do not need
that key and do not display its value. The model targets `gpt-4o` in OpenAI.

## Show diffs on pull requests

Create `.github/workflows/kongctl-diff.yaml`:

{% raw %}
```yaml
name: kongctl diff

on:
  pull_request:
    branches: [main]
    paths:
      - konnect/**
      - .github/workflows/kongctl-*.yaml

permissions:
  contents: read

jobs:
  diff:
    if: >-
      github.event.pull_request.head.repo.full_name == github.repository &&
      github.actor != 'dependabot[bot]'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: kong/setup-kongctl@v1
        with:
          kongctl-version: '1.15.1'
      - name: Show configuration diff
        shell: bash
        env:
          KONGCTL_DEFAULT_KONNECT_PAT: ${{ secrets.KONNECT_TOKEN }}
          KONGCTL_DEFAULT_KONNECT_REGION: ${{ vars.KONNECT_REGION }}
          NO_COLOR: '1'
        run: |
          : "${KONGCTL_DEFAULT_KONNECT_PAT:?Set the KONNECT_TOKEN secret}"
          : "${KONGCTL_DEFAULT_KONNECT_REGION:?Set KONNECT_REGION}"
          kongctl diff --mode apply -f konnect/ai-gateway.yaml -o text \
            --region "$KONGCTL_DEFAULT_KONNECT_REGION" | tee diff.txt
          echo '## Konnect configuration diff' >> "$GITHUB_STEP_SUMMARY"
          echo '```text' >> "$GITHUB_STEP_SUMMARY"
          cat diff.txt >> "$GITHUB_STEP_SUMMARY"
          echo '```' >> "$GITHUB_STEP_SUMMARY"
```
{% endraw %}

`diff` queries live Konnect state, so it requires the Konnect token even
though it does not change any resources. Its output appears in the workflow
logs and summary. A successful run with proposed changes is expected.

The workflow uses Bash with pipeline failure handling, so a failed `diff`
command fails the check even though its output is piped through `tee`.

## Apply changes on main

Create `.github/workflows/kongctl-apply.yaml`:

{% raw %}
```yaml
name: kongctl apply

on:
  push:
    branches: [main]
    paths:
      - konnect/**
      - .github/workflows/kongctl-*.yaml

permissions:
  contents: read

concurrency:
  group: kongctl-apply-main
  cancel-in-progress: false

jobs:
  apply:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: kong/setup-kongctl@v1
        with:
          kongctl-version: '1.15.1'
      - name: Apply configuration
        shell: bash
        env:
          KONGCTL_DEFAULT_KONNECT_PAT: ${{ secrets.KONNECT_TOKEN }}
          KONGCTL_DEFAULT_KONNECT_REGION: ${{ vars.KONNECT_REGION }}
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
        run: |
          : "${KONGCTL_DEFAULT_KONNECT_PAT:?Set the KONNECT_TOKEN secret}"
          : "${KONGCTL_DEFAULT_KONNECT_REGION:?Set KONNECT_REGION}"
          : "${OPENAI_API_KEY:?Set the OPENAI_API_KEY secret}"
          kongctl apply -f konnect/ai-gateway.yaml --auto-approve -o text \
            --region "$KONGCTL_DEFAULT_KONNECT_REGION"
```
{% endraw %}

Both workflows pin kongctl to the same version. When upgrading, update both
pins together. The deployment concurrency group prevents overlapping apply
runs and allows an active apply to finish.

`--auto-approve` runs without an interactive confirmation. `apply` generates
its own plan from the merged configuration and current Konnect state; the
result can differ from the earlier PR diff if state has changed.

## Open a PR and deploy

1. Commit the manifest and both workflow files, then open a PR targeting
   `main`.
1. Open the **kongctl diff** check. Follow its **Details** link to the workflow
   run and review the diff in the summary. For a new namespace, expect the
   gateway, provider, and model to be created, with no plaintext OpenAI key.
1. Merge the PR. Open **Actions > kongctl apply** and check that the run
   succeeds. Verify the gateway, provider, and model in your Konnect region.
1. In another branch, change only the gateway's `description`. Open a PR and
   confirm the diff shows an update rather than a new gateway. Merge it and
   verify the updated description in Konnect.
1. Re-run the successful apply job without changing the configuration.
   Expect no further configuration changes.

Every matching push to `main` deploys, including direct pushes. Use your
repository's branch rules if all changes must go through PR review.

## Understand the update behavior

`apply` creates and updates resources. Removing an entry from the manifest
does not delete it from Konnect. See [kongctl sync](/kongctl/sync/) when you
need deletion-based reconciliation.

The provider key is written when the provider is created. Changing the
GitHub secret does not trigger a workflow and an ordinary apply does not
rotate an existing write-only credential. Use explicit secret-write
selection when rotating credentials; see
[Write-only secret fields](/kongctl/declarative/#write-only-secret-fields).

If a check fails, verify the repository secret names, region variable, token
permissions, and {{site.ai_gateway}} access. For an existing gateway managed
outside this repository, follow
[adoption guidance](/kongctl/adopt/ai-gateway/) before using it in this
configuration.
