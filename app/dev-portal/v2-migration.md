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
    - upgrade
    - migration

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
  - text: Migrate your classic Dev Portal (v2) Terraform resource
    url: /dev-portal/migrate-classic-dev-portal-resource-with-terraform/
---

With the GA release of the new Dev Portal (v3) in June 2025, you can migrate from classic Dev Portals (v2) to the new Dev Portal. 

Dev Portal v3 provides additional features such as a streamlined [API creation and publishing process](/catalog/apis/) and enhanced [Dev Portal customization](/dev-portal/customizations/dev-portal-customizations/) with Markdown components and snippets.

## Migrate manually

To migrate from Dev Portal classic (v2) to the new Dev Portal (v3), do the following:

1. For Kong-hosted classic Dev Portals, do the following:
   1. [Create a new v3 Dev Portal in {{site.konnect_short_name}}](https://cloud.konghq.com/portals/create). 
      
      {:.warning}
      > If you're using Terraform to manage your v2 Dev Portal, make sure you've migrated your `konnect_portal` Terraform resource to `konnect_portal_classic` by following the [Migrate your classic Dev Portal (v2) Terraform resource](/dev-portal/migrate-classic-dev-portal-resource-with-terraform/) guide. 
   1. [Republish your API catalog](/how-to/automate-api-catalog/) either via the UI or the v3 API.
   
1. If you are using an [IdP for developer credentials](/dev-portal/team-mapping/), update your IdP with the new Dev Portal domain for the redirect URIs. This will maintain developer logins.
1. If you are using {{site.konnect_short_name}} developer logins, like basic auth, developers will need to register at the new v3 Dev Portal and regenerate their API credentials.
1. If you're using a custom domain for your Dev Portal, do the following:
   1. Decrease your domain TTL in advance to reduce the transition time. Some minimal downtime will be required to move custom domains.
   1. Delete your custom domain from v2 Dev Portal.
   1. Add the custom domain to the v3 Dev Portal.
1. If you've enabled developer RBAC, manually assign developers to teams and roles by navigating to your v3 Dev Portal in {{site.konnect_short_name}}, clicking **Access and approvals** in the sidebar, and click the **Teams** tab.
   {:.warning}
   > For self-hosted Dev Portals, contact Kong Support by navigating to the **?** icon on the top right menu and clicking **Create support case** or from the [Kong Support portal](https://support.konghq.com).