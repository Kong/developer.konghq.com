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
  skip_tool: true
  show_works_on: false
  inline:
    - title: Konnect access
      content: |
        You need a {{site.konnect_short_name}} account and a personal or
        system account access token with permission to manage Dev Portals
        and APIs. To get started easily, use a token for an account in the
        **Organization Admin** team. See
        [Konnect teams and roles](/konnect-platform/teams-and-roles/)
        for permissions and
        [kongctl authentication](/kongctl/authentication/) for token setup.
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

This quickstart builds a CI/CD pipeline to deliver a simple API and its
OpenAPI specification to a Dev Portal using GitOps and GitHub Actions.

## Configure GitHub authentication

In your GitHub repository's web interface, go to
**Settings > Secrets and variables > Actions** and add:

| Type | Name | Value |
| --- | --- | --- |
| Secret | `KONNECT_TOKEN` | Your Konnect access token |
| Variable | `KONNECT_REGION` | Your Konnect region, such as `us` or `eu` |

## Create a branch

On your development machine, clone your GitHub repository if necessary
and change into its directory. Create a new branch to build this example:

```sh
git switch -c konnect-apiops
```

## Declare the portal and API

Create the configuration directory if it doesn't already exist:

```sh
mkdir -p konnect
```

On your new branch, create a file `konnect/portal.yaml` with the following
kongctl resource definitions:

```yaml
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

The publication's `!ref` links the API to the portal. Portal authentication
is disabled so the published API documentation is publicly accessible.

The API specification is inline to keep the example simple and
self-contained. See the
[portal example][ex] for a larger configuration with separate
specification files, pages, and customization.

[ex]: https://github.com/Kong/kongctl/tree/main/docs/examples/declarative/portal

## Add the GitHub Actions workflow

Create the workflows directory if it doesn't already exist:

```sh
mkdir -p .github/workflows
```

Create a file `.github/workflows/konnect.yaml` with the following GitHub
Actions workflow definition:

The workflow installs kongctl on the runner. The version below comes from
the docs site's shared release data and is an explicit version when you
copy it. Update `kongctl-version` in your repository when you're ready to
upgrade; existing workflows keep using the version you copied.

{% raw %}
```yaml
name: Konnect APIOps

on:
  pull_request:
    branches: [main]
    paths:
      - konnect/**
      - .github/workflows/konnect.yaml
  push:
    branches: [main]
    paths:
      - konnect/**
      - .github/workflows/konnect.yaml

permissions:
  contents: read
  pull-requests: write

concurrency:
  group: konnect-${{ github.ref }}
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
          kongctl-version: >-
            {% endraw %}{{site.data.kongctl_latest.version}}{% raw %}
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
          {
            echo '## Konnect configuration diff'
            echo '```text'
            cat diff.txt
            echo '```'
          } > comment.md
          cat comment.md >> "$GITHUB_STEP_SUMMARY"
      - name: Post diff comment
        if: github.event_name == 'pull_request'
        uses: marocchino/sticky-pull-request-comment@v2
        with:
          header: konnect-diff
          path: comment.md
      - name: Apply configuration
        if: github.event_name == 'push'
        run: |
          kongctl apply -f konnect/portal.yaml --auto-approve -o text \
            --region "$KONGCTL_DEFAULT_KONNECT_REGION"
```
{% endraw %}

This workflow runs PR checks for branches in the same GitHub repository.
Contributors who can push to these branches can modify workflows that use
your Konnect token, so give that access only to people you trust. The
workflow skips pull requests from forks and `dependabot[bot]`, which don't
receive the repository's Actions secrets.

The workflow has two behaviors:

- **Pull requests targeting `main`:** `kongctl diff` compares the proposed
  configuration with live Konnect state. It shows the changes in the
  workflow summary and a PR comment for review without applying them.
  Each successful diff run updates the same comment. The
  `pull-requests: write` permission lets the workflow post this comment.
- **Pushes to `main`:** `kongctl apply` calculates a fresh plan from live
  Konnect state and executes it without prompting. This plan reflects the
  state at deployment time, which may have changed since the PR diff.
  The concurrency group prevents overlapping deployments to `main`.

## Review and deploy

1. Commit both files, push your branch, and open a PR targeting `main`.
   Review the diff comment posted by the **Konnect APIOps** workflow.
1. Merge the PR. Check that the **Apply configuration** step succeeds, then
   open your Dev Portal in Konnect and verify the published API and spec.

Every matching push to `main` deploys, including direct pushes. Use branch
rules if all changes must go through PR review. `apply` creates and updates
resources; use [sync](/kongctl/sync/) when you want removed declarations to
delete resources.

## Update the API

1. On your development machine, switch to `main`, pull the merged changes,
   and create a new branch:

   ```sh
   git switch main
   git pull --ff-only
   git switch -c update-example-api
   ```

1. In `konnect/portal.yaml`, change the API's `description` to
   `An example API deployed with GitOps`.
1. Commit the change, push your branch, and open a PR targeting `main`.
   Check that the **Konnect APIOps** diff comment shows an update to the
   API description.
1. Merge the PR and check that the **Apply configuration** step succeeds.
   Open your Dev Portal and verify that the API description has changed.
1. In your GitHub repository's **Actions** tab, open the **Konnect APIOps**
   run triggered by the merge's push to `main`. Select **Re-run all jobs**
   and confirm the re-run. The **Apply configuration** step should report
   no further changes if the configuration and live state are unchanged.
   This repeats the existing push run; it doesn't require a
   `workflow_dispatch` trigger.
