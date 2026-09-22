---
title: APIOps for {{site.konnect_short_name}} with kongctl and GitHub Actions
description: >-
  Store Konnect declarative configuration in GitHub, show diffs on pull
  requests, and apply changes on pushes to main.
content_type: reference
layout: reference
permalink: /kongctl/ci-cd/github-actions/
breadcrumbs:
  - /kongctl/
works_on:
  - konnect
tools:
  - kongctl
tags:
  - declarative-config
related_resources:
  - text: Declarative configuration with kongctl
    url: /kongctl/declarative/
  - text: Use kongctl with AI agent skills
    url: /kongctl/skills/
  - text: kongctl and decK
    url: /kongctl/kongctl-and-deck/
  - text: kongctl authentication
    url: /kongctl/authentication/
  - text: kongctl troubleshooting
    url: /kongctl/troubleshooting/
next_steps:
  - text: Learn about kongctl sync
    url: /kongctl/sync/
  - text: Explore {{site.dev_portal}}
    url: /dev-portal/
---

This quickstart builds a CI/CD pipeline to deliver an API and its
OpenAPI specification to a {{site.dev_portal}} using GitOps and GitHub Actions.
Store {{site.konnect_short_name}} declarative configuration in GitHub and
deploy a GitHub Actions workflow that shows diffs on pull requests
and applies changes on pushes to main.

Use a test {{site.konnect_short_name}} organization: this example creates a {{site.dev_portal}} and API
with publicly accessible API documentation.

## Prerequisites

- **{{site.konnect_short_name}} access**: You need a {{site.konnect_short_name}} account and a [personal or system account access token](/konnect-api/#konnect-api-authentication) with permission to manage {{site.dev_portal}}s
  and APIs. For this quickstart in a test organization, you can use an account
  in the **Organization Admin** team to get started.
  For production, follow least privilege: assign only the
  [API roles](/konnect-platform/teams-and-roles/#apis) and
  [{{site.dev_portal}} roles](/konnect-platform/teams-and-roles/#portals)
  your workflow needs. See
  [kongctl authentication](/kongctl/authentication/) for token setup.
- **GitHub repository**: Use a GitHub repository with Actions enabled and `main` as its
  default branch. You need permission to add repository secrets and variables,
  create branches and pull requests, and merge them into `main`.

## Configure GitHub authentication

In your GitHub repository's web interface, go to
**Settings > Secrets and variables > Actions** and add:

| Type | Name | Value |
| --- | --- | --- |
| Secret | `KONNECT_TOKEN` | Your {{site.konnect_short_name}} access token |
| Variable | `KONNECT_REGION` | Your {{site.konnect_short_name}} region, such as `us` or `eu` |

## Create a branch

On your development machine, clone your GitHub repository if necessary
and change into its directory. Create a new branch to build this example:

```sh
git switch -c konnect-apiops
```

## Declare the {{site.dev_portal}} and API

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

This configuration defines a {{site.dev_portal}}, an API with an inline OpenAPI
specification, and a publication that makes the API available in the
{{site.dev_portal}}. The publication's `!ref` links it to the {{site.dev_portal}}. Authentication is
disabled so anyone can read the API documentation. See the
[{{site.dev_portal}} example](https://github.com/Kong/kongctl/tree/main/docs/examples/declarative/portal) for separate specification files and customization.


## Add the GitHub Actions workflow

Create the workflows directory if it doesn't already exist:

```sh
mkdir -p .github/workflows
```

Create a file `.github/workflows/konnect.yaml` with the following GitHub
Actions workflow definition:

{% raw %}
```yaml
name: Konnect APIOps

on:
  workflow_dispatch:
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
      ((github.event_name == 'push' ||
        github.event_name == 'workflow_dispatch') &&
       github.ref == 'refs/heads/main') ||
      (github.event_name == 'pull_request' &&
       github.event.pull_request.head.repo.full_name == github.repository &&
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
        if: >-
          github.ref == 'refs/heads/main' &&
          (github.event_name == 'push' ||
           github.event_name == 'workflow_dispatch')
        run: |
          kongctl apply -f konnect/portal.yaml --auto-approve -o text \
            --region "$KONGCTL_DEFAULT_KONNECT_REGION"
```
{% endraw %}

The workflow installs the pinned kongctl version and does the following:

- **On pull requests targeting `main`:** Compares configuration with live
  {{site.konnect_short_name}} state and posts a diff in the summary and an updating PR comment.
  It doesn't apply changes. `pull-requests: write` allows the comment.
- **On pushes or manual runs on `main`:** Calculates a fresh plan and
  applies it without prompting. Concurrency prevents overlapping applies.
  Manual runs on other branches are skipped.

Only give trusted contributors branch access; they can edit workflows
that use your {{site.konnect_short_name}} token. Fork and dependency-bot pull requests are
skipped because they don't receive repository secrets.

The version comes from the [Kong Developer](/) site's shared release data when the page
is built. Your copied workflow stays pinned; update `kongctl-version`
when you're ready to upgrade.

## Review and deploy

1. Commit both files, push your branch, and open a PR targeting `main`.
   Wait for the **{{site.konnect_short_name}} APIOps** workflow to finish, then review its diff
   comment.
1. Merge the PR. In **Actions**, open the **{{site.konnect_short_name}} APIOps** run for the
   push to `main`, then open **configure > Apply configuration**. Expect
   four creates in the `default` namespace: `portal`, `api`, `api_version`,
   and `api_publication`, followed by successful creation messages. Open
   your {{site.dev_portal}} in {{site.konnect_short_name}} and verify the published API and spec.

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
   Wait for the **{{site.konnect_short_name}} APIOps** workflow to finish, then check that its
   diff comment shows an update to the API description.
1. Merge the PR and check that the **Apply configuration** step succeeds.
   Open your {{site.dev_portal}} and verify that the API description has changed.
1. In your GitHub repository's **Actions** tab, select **{{site.konnect_short_name}} APIOps**,
   click **Run workflow**, select the `main` branch, and confirm with
   **Run workflow**. When the run completes, open
   **configure > Apply configuration**. It should report no further
   changes if the configuration and live state are unchanged.
