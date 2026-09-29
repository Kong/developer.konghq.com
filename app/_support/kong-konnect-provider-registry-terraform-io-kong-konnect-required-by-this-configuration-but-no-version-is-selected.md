---
title: '{{site.konnect_product_name}} Terraform provider "no version is selected" error when the provider is not yet initialized'
content_type: support
description: This will occur when you have not yet initialized the Konnect provider.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does Terraform show "no version is selected" for the {{site.konnect_product_name}} provider?
  a: |
    This happens when the Konnect Terraform provider hasn't been initialized yet. Add the provider block to your configuration file and run `terraform init` to download the required plugin version.
related_resources: []
---

## Problem

When attempting to use the {{site.konnect_product_name}} Terraform provider I receive the below error when running plan/apply commands. How can this be resolved?

```

│ The following dependency selections recorded in the lock file are inconsistent with the current configuration:
│   - provider registry.terraform.io/hashicorp/konnect: required by this configuration but no version is selected
```

## Solution

This will occur when you have not yet initialized the Konnect provider. Initializing the provider is necessary to download the required plugins and configure the environment.

Be sure you have the provider added to your configuration file, for example

```hcl
terraform {
  required_providers {
    konnect = {
      source  = "kong/konnect"
      version = "0.2.3"
    }
  }
}
```

and initialize using the following command:

```bash
terraform init
```
