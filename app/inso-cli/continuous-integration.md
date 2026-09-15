---
title: Continuous Integration with Inso CLI

description: Inso CLI is designed to run in a Continuous Integration (CI) environment.

content_type: reference
layout: reference

products:
  - insomnia

tools:
  - inso-cli

tags:
  - ci/cd

breadcrumbs:
  - /inso-cli/

related_resources:
  - text: Inso CLI
    url: /inso-cli/
  - text: Inso CLI reference
    url: /inso-cli/reference/
---

Inso CLI is designed to run in a Continuous Integration (CI) environment. It disables prompts and provides exit codes to pass or fail the CI workflow.

You can use the [Setup Inso](https://github.com/marketplace/actions/setup-inso) GitHub Action to perform Inso CLI tasks in your repository's GitHub Actions.

## GitHub Action example

The following sample GitHub Actions performs the following tasks:

1. Checks out branch
2. Downloads [Setup Inso](https://github.com/marketplace/actions/setup-inso)
3. Runs linting
4. Runs legacy unit tests

Here's the example Inso CLI GitHub Action:

{:.warning}
> {% new_in 13.3 %} `inso run test` runs legacy unit tests, which are hidden in the app by default and are planned for deprecation in a future release. To create or edit these tests in {{ site.insomnia }}, go to **Preferences** > **General** > **Application** and enable **Show legacy unit tests**. For new work, use [pre-request and after-response scripts](/insomnia/scripts/) and run them with `inso run collection`.

```yaml
name: Test

jobs:
  Linux:
    name: Validate API spec
    runs-on: ubuntu-latest
    steps:
      - name: Checkout branch
        uses: actions/checkout@v1
      - uses: kong/setup-inso@v2
        with:
          inso-version: 11.3.0
      - name: Lint
        run: inso lint spec "Designer Demo" --ci
      - name: Run test suites
        run: inso run test "Designer Demo" --env UnitTest --ci
```