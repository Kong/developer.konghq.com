---
title: "Migrate from classic Dev Portal (v2) to the new Dev Portal (v3)"
content_type: reference
layout: reference
breadcrumbs:
  - /dev-portal/
products:
    - dev-portal

works_on:
    - konnect

tags:
    - upgrades
    - migrating

search_aliases:
    - Dev Portal v2
    - classic Dev Portal

description: "Learn how to migrate from the classic Dev Portal (v2) to the new Dev Portal (v3)."

related_resources:
  - text: Dev Portal
    url: /dev-portal/
  - text: Dev Portal breaking changes
    url: /dev-portal/breaking-changes/
  - text: "{{site.konnect_short_name}} release notes"
    url: https://releases.konghq.com/en
---

With the GA release of the new Dev Portal (v3) in June 2025, you can migrate from classic Dev Portals (v2) to the new Dev Portal. 

Dev Portal v3 provides additional features such as a streamlined [API creation and publishing process](/dev-portal/apis/) and enhanced [Dev Portal customization](/dev-portal/customizations/dev-portal-customizations/) with Markdown components and snippets.

## Migrate manually

To migrate from Dev Portal classic (v2) to the new Dev Portal (v3), do the following:

1. For Kong-hosted classic Dev Portals, do the following:
   1. [Create a new v3 Dev Portal in {{site.konnect_short_name}}](https://cloud.konghq.com/portals/create)
   1. [Republish your API catalog](/how-to/automate-api-catalog/) either via the UI or the v3 API
   
1. If you are using an [IdP for developer credentials](/dev-portal/team-mapping/), update your IdP with the new Dev Portal domain for the redirect URIs. This will maintain developer logins.
1. If you are using {{site.konnect_short_name}} developer logins, like basic auth, developers will need to register at the new v3 Dev Portal and regenerate their API credentials.
1. If you're using a custom domain for your Dev Portal, do the following:
   1. Decrease your domain TTL in advance to reduce the transition time. Some minimal downtime will be required to move custom domains.
   1. Delete your custom domain from v2 Dev Portal.
   1. Add the custom domain to the v3 Dev Portal.
1. If you've enabled developer RBAC, manually assign developers to teams and roles by navigating to your v3 Dev Portal in {{site.konnect_short_name}}, clicking **Access and approvals** in the sidebar, and click the **Teams** tab.
   {:.warning}
   > For self-hosted Dev Portals, [contact Kong support](https://support.konghq.com) for help.

## Migrate with Terraform

Users can migrate to the new konnect_portal_classic resource using `import` and `removed` blocks in the manifests or using the CLI. We recommend using the `import`/`removed` blocks in manifests.

{:.warning}
> While not recommended, you can edit your state file directly to migrate. To do this, search `"type":"konnect_portal"` and replace with `"type": "konnect_portal_classic"`.

{% navtabs "Terraform" %}
{% navtab "Manifests" %}
1. Get your Dev Portal ID from the Terraform state: 
   ```sh
   terraform state show konnect_portal_classic.my_portal | grep "id"
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

1. Remove the resource from state:
   ```sh
   terraform state rm konnect_portal.my_portal
   ```
1. Update your manifest to use the `konnect_portal_classic` resource.

1. Update the provider in your manifests to `provider = konnect`.

1. Re-import the Dev Portal into the new resource:
   ```sh
   terraform import konnect_portal_classic.my_portal "fc32ee8a-84cc-4a05-b0d2-98d7e4b0fb59"
   ```
1. Apply all of the resource changes using Terraform:
   ```sh
   terraform apply -auto-approve
   ```
   Some things will say they need updating. It’s safe to do as it’s just the state file updating IDs + references.
{% endnavtab %}
{% endnavtabs %}

