---
title: Convert Gateway entity configuration from 3.4 to 3.10
content_type: how_to

description: Use decK to upgrade from {{ site.base_gateway }} 3.4 LTS to 3.10 LTS

permalink: /gateway/upgrade/convert-lts-34-310/

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.10'

tags:
    - upgrade

tldr:
    q: How do I convert Gateway entity configuration from 3.4 to 3.10, as part of my upgrade process?
    a: Run `deck file convert` and review the results.
tools: []

prereqs:
  skip_product: true
  inline:
    - title: "{{site.base_gateway}} {% new_in 3.4 %}"
      content: "You have {{site.base_gateway}} running on version 3.4."
    - title: |
        decK &nbsp; {% new_in 1.51 %}
      content: |
        decK is a CLI tool for managing {{site.base_gateway}} declaratively with state files.
        To complete this tutorial, install [decK](/deck/) **version 1.51** or later.

        This guide uses `deck gateway apply`, which directly applies entity configuration to your Gateway instance.
        We recommend upgrading your decK installation to take advantage of this tool.

        You can check your current decK version with `deck version`.

related_resources:
  - text: deck file convert
    url: /deck/file/convert/
  - text: Convert Gateway entity configuration from 2.8 to 3.4
    url: /deck/reference/3.0-upgrade/
  - text: Gateway LTS 3.4 to 3.10 upgrade guide
    url: /gateway/upgrade/lts-upgrade-28-34/
  - text: Gateway LTS 3.10 to 3.10 upgrade guide
    url: /gateway/upgrade/lts-upgrade-34-310/

faqs:
  - q: I ran `deck file convert` but there are still errors or warnings, what do I do?
    a: Manually validate the file, then make any necessary updates to your state file.
  - q: Can I still apply configuration if there are warnings?
    a: |
      If you have validated the configuration and found no issues but are still getting a warning, the warning may be a false positive. 
      You can still apply the configuration, but do so at your own risk.

      If you run into false positives, [file an issue](https://github.com/Kong/deck/issues) to let us know.

automated_tests: false
---


You can use `deck file convert` to automatically perform many of the changes that occurred between {{site.base_gateway}} 3.4 LTS and 3.10 LTS versions.

See the [deck file convert](/deck/file/convert/) reference for a list of all the conversions that decK will perform.

{:.info}
> **Note:** Update your decK version to 1.51 or later before converting files.

## Export configuration

Use an existing backup file, or export the entity configuration an existing installation, for example 3.10:

```sh
deck gateway dump -o kong-3.4.yaml \
    --konnect-token "$YOUR_KONNECT_PAT" \
    --konnect-control-plane-name $YOUR_CP_NAME
```
{: data-deployment-topology="konnect" }

```sh
deck gateway dump -o kong-3.4.yaml --all-workspaces
```
{: data-deployment-topology="on-prem" }


## Convert configuration

Use `deck file convert` with version flags to convert the entity configuration:

```sh
deck file convert \
    --from 3.4 \
    --to 3.10 \
    --input-file kong-3.4.yaml \
    --output-file kong-3.10.yaml
```

## Review and validate

1. Review the output of the command.
   
    `deck file convert` creates a new file and prints warnings and errors for any changes that can't be made automatically. 
    These changes require some manual work, so adjust your configuration accordingly.

1. Validate the converted file in a test environment.

    Make sure to manually audit the generated file before applying the configuration in production. 
    These changes may not be fully correct or exhaustive, so manual validation is strongly recommended.

## Apply configuration

Upload your new configuration to a {{site.konnect_short_name}} control plane:
{: data-deployment-topology="konnect" }

```sh
deck gateway sync kong-3.10.yaml \
    --konnect-token "$YOUR_KONNECT_PAT" \
    --konnect-control-plane-name $YOUR_CP_NAME
```
{: data-deployment-topology="konnect" }

Upload your new configuration to the new environment:
{: data-deployment-topology="on-prem" }

```sh
deck gateway sync kong-3.10.yaml \
    --workspace default
```
{: data-deployment-topology="on-prem" }
