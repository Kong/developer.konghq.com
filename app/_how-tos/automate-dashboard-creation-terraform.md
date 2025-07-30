---
title: Manage analytics dashboards with Terraform
description: Learn how to manage a dashboard in {{site.konnect_short_name}} Analytics with Terraform
content_type: how_to
automated_tests: false
products:
    - konnect-platform
    - advanced-analytics
works_on:
    - konnect
tools:
    - konnect-api
    - terraform
tags:
    - custom-dashboards

series:
  id: custom-dashboards
  position: 2
tldr:
  q: How do I automate dashboard creation using Terraform?
  a: |
    Use the `konnect_dashboard` resource from the [terraform](/terraform/) provider to define and manage dashboards.
    You can import existing dashboards or create new ones with configurable chart layouts, titles, and filters.

prereqs:
  skip_product: true
  inline:
    - title: Terraform
      include_content: prereqs/terraform
      icon_url: /assets/icons/terraform.svg
    - title: "{{site.konnect_product_name}}"
      include_content: prereqs/products/konnect-terraform
      icon_url: /assets/icons/gateway.svg
    - title: Roles and permissions
      content: |
        This guide requires belonging to the [Analytics admin](/konnect-platform/teams-and-roles/) team.
related_resources:
  - text: Custom Dashboards
    url: /advanced-analytics/custom-dashboards/
---

## Get the dashboard ID

Managing dashboards with Terraform requires the dashboard ID of the target dashboard:

1. Get an existing dashboard ID from the {{site.konnect_short_name}} URL of your dashboard. It appears at the end of the URL when viewing the dashboard:
   ```
   https://cloud.konghq.com/us/analytics/dashboards/$DASHBOARD_ID
   ```

## Import the dashboard

Import the dashboard into Terraform by creating an `import.tf` file:

```sh
echo 'import {
  provider = konnect-beta
  to       = konnect_dashboard.service_dashboard_template
  id       = 0810eb60-1290-4428-8b3a-d74ca6182c3d
}
' > import.tf
```

## Generate the Terraform configuration

Generate the Terraform configuration from the imported resource:

```sh
terraform plan -generate-config-out=create_dashboard.tf
```

This creates a new file named `create_dashboard.tf` that contains the Terraform resource definition for the imported dashboard.

## Validate

To validate that your changes are working, make an update in the generated Terraform file (for example, change a chart title).

1. Run the following command to apply the update:
   ```sh
   terraform apply
   ```
1. After the change is applied, return to the [{{site.konnect_short_name}} dashboard manager](https://cloud.konghq.com/us/analytics/dashboards) to confirm the update is reflected in the dashboard UI.

Now, you can commit the Terraform files to your GitHub repo and include them in your CI/CD pipeline to manage future changes as code.