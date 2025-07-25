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

Dev Portal v3 provides additional features such as:
* Streamlined [API creation and publishing process](/dev-portal/apis/)
* Enhanced [Dev Portal customization](/dev-portal/customizations/dev-portal-customizations/) with Markdown components and snippets

## Migrate to Dev Portal v3

To migrate from Dev Portal classic (v2) to the new Dev Portal (v3), do the following:

1. For Kong-hosted classic Dev Portals, do the following:
   1. Adjust any CI/CD automation
   1. [Create a new Dev Portal in {{site.konnect_short_name}}](https://cloud.konghq.com/portals/create)
   1. [Republish your API catalog](/how-to/automate-api-catalog/) either via the UI or the v3 API
   {:.warning}
   > For self-hosted Dev Portals, [contact Kong support](https://support.konghq.com) for help.
1. If you are using an [IdP for developer credentials](/dev-portal/team-mapping/), update your IdP with the new Dev Portal domain for the redirect URIs. This will maintain developer logins.
1. If you are using {{site.konnect_short_name}} developer logins, like basic auth, developers will need to register at the new v3 Dev Portal and regenerate their API credentials.
1. If you're using a custom domain for your Dev Portal, see the [Dev Portal breaking changes](/dev-portal/breaking-changes/) for migration information.
1. If you've enabled developer RBAC, manually assign developers to teams and roles by navigating to your v3 Dev Portal in {{site.konnect_short_name}}, clicking **Access and approvals** in the sidebar, and click the **Teams** tab.

