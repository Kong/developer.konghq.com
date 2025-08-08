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
    - title: An existing custom dashboard
      content: |
        This guide requires an existing dashboard in {{site.konnect_short_name}}. You can create one using the [Create a custom dashboard](/how-to/create-custom-dashboards/) guide.
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

1. Export the dashboard ID into an environment variable to be used later: 

  ```
  export DASHBOARD_ID='fe1b6b51-2e7e-44d6-bfa5-CC93489b3eed'
  ```
## Authenticate with {{site.konnect_short_name}}

To authenticate with {{site.konnect_short_name}} you have to create an `auth.tf` file in the directory you intend to manage Terraform in: 

```hcl
echo '
provider "konnect-beta" {
  personal_access_token = "$KONNECT_TOKEN"
  server_url            = "https://us.api.konghq.com"
}
' >> auth.tf
```
## Import the dashboard

Now configure Terraform to import a dashboard from {{site.konnect_short_name}}.

```hcl
echo '
import {
  provider = "konnect-beta"
  to = konnect_dashboard.service_dashboard_template
  id = "$DASHBOARD_ID"
}
' >> import.tf
```

## Generate the Terraform configuration

Generate the Terraform configuration from the dashboard:

1. Initialize Terraform:
    ```sh
    terraform init
    ```
1. Gernate the Terraform configuration for the dashboard: 
    ```sh
    terraform plan -generate-config-out=create_dashboard.tf
    ```


This creates a new file named `create_dashboard.tf` that contains the Terraform resource definition for the imported dashboard.


## Configure the dashboard

The new `create_dashboard.tf` file contains information about your dashboard. You can use this file to make changes to the dashboard in {{site.konnect_short_name}} with Terraform: 

```sh

          }
          layout = {
            position = {
              col = 4
              row = 6
            }
            size = {
              cols = 2
              rows = 2
            }
          }
          type = "chart"
        }
      },
    ]
  }
  labels = null
  name   = "Quick summary dashboard"
}
```

You can add a label to the dashboard by configuring the file: 

```
  }
  labels = {
  test = "test"
}
```

## Validate

To validate that your changes are working, make an update in the generated Terraform file (for example, change a chart title).

1. Run the following command to apply the update:
   ```sh
   terraform apply
   ```
1. After the change is applied, return to the [{{site.konnect_short_name}} dashboard manager](https://cloud.konghq.com/us/analytics/dashboards) to confirm the "test" label has been added to the dashboard.
