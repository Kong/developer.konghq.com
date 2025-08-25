---
title: Migrate your classic Dev Portal (v2) Terraform resource
content_type: reference
layout: reference
products:
    - dev-portal
tags:
  - terraform
works_on:
    - konnect

search_aliases:
  - Dev Portal v2
  - classic Dev Portal
  - Portal

breadcrumbs:
  - /dev-portal/

description: "Learn how to migrate your classic Dev Portal (v2) `konnect_portal` Terraform resource to `konnect_portal_classic`."
related_resources:
  - text: API Products
    url: /api-products/
  - text: Migrate from classic Dev Portal (v2) to the new Dev Portal (v3)
    url: /dev-portal/v2-migration/
---

{:.warning}
> **BREAKING CHANGE**: In the upcoming 3.x {{site.konnect_short_name}} Terraform provider, releasing at the end of August 2025, the provider deploys a v3 Dev Portal using the `konnect_portal` resource. If you are using Dev Portal v2 (classic), you need to migrate to the `konnect_portal_classic` resource in version 2.x of the Terraform provider before upgrading.

You can migrate your `konnect_portal` Terraform resource to the new `konnect_portal_classic` resource using `import` and `removed` blocks in the manifests or using the CLI. We recommend using the `import`/`removed` blocks in manifests.

{% navtabs "Terraform" %}
{% navtab "Manifests" %}
1. Get your Dev Portal ID from the Terraform state: 
   ```sh
   terraform state show konnect_portal.my_portal | grep "id"
   ```
   You can also do this from the {{site.konnect_short_name}} UI by navigating to [**Dev Portal**](https://cloud.konghq.com/portals/) in the sidebar, clicking the **Classic** tab, and clicking on your v2 Dev Portal.

1. Rename `konnect_portal` to `konnect_portal_classic` in your manifest. For example:
   ```hcl
   resource "konnect_portal_classic" "my_portal" {
     name                      = "My New Portal"
     auto_approve_applications = false
     auto_approve_developers   = false
     is_public                 = false
     rbac_enabled              = false
   }

   import {
     to = konnect_portal_classic.my_portal
     id = "854cb4ce-8a3f-4cf7-b878-52347a78d8d6"
   }

   removed {
     from = konnect_portal.my_portal
     lifecycle {
       destroy = false
     }
   }
   ```

   {:.danger}
   > **Warning:** If the `removed` block is missing, the Dev Portal will be destroyed.

1. Apply all of the resource changes using Terraform:
   ```sh
   terraform apply -auto-approve
   ```
1. Remove the `import` and `removed` lines in your manifest.
{% endnavtab %}
{% navtab "CLI" %}
1. Get your Dev Portal ID from the Terraform state: 
   ```sh
   echo konnect_portal.my_portal.id | terraform console
   ```
   You can also do this from the {{site.konnect_short_name}} UI by navigating to [**Dev Portal**](https://cloud.konghq.com/portals/) in the sidebar, clicking the **Classic** tab, and clicking on your v2 Dev Portal.
1. Export your Dev Portal ID:
   ```sh
   export PORTAL_ID='YOUR-PORTAL-ID'
   ```
1. Remove the resource from state:
   ```sh
   terraform state rm konnect_portal.my_portal
   ```
1. Update your manifest to use the `konnect_portal_classic` resource.

1. Ensure the provider in your manifests is `provider = konnect`.

1. Re-import the Dev Portal into the new resource:
   ```sh
   terraform import konnect_portal_classic.my_portal "$PORTAL_ID"
   ```
1. Apply all of the resource changes using Terraform:
   ```sh
   terraform apply -auto-approve
   ```
   Some things will say they need updating. It’s safe to do so as it’s just the state file updating IDs and references.
{% endnavtab %}
{% navtab "Edit state file" %}
It's not recommended, but you can edit your state file directly to migrate. To do this, search `"type":"konnect_portal"` and replace with `"type": "konnect_portal_classic"`.
{% endnavtab %}
{% endnavtabs %}

