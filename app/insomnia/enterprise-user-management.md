---
title: Enterprise user management

description: Learn how to manage your Insomnia Enterprise users and licenses.

content_type: reference
layout: reference
breadcrumbs: 
  - /insomnia/
  - /insomnia/enterprise/
products:
    - insomnia
search_aliases:
  - insomnia licenses
  - insomnia users

tier: enterprise
related_resources:
  - text: Enterprise
    url: /insomnia/enterprise/
  - text: Get started with Insomnia Enterprise
    url: /insomnia/enterprise-onboarding/
  - text: Team RBAC and domain capture
    url: https://konghq.com/blog/product-releases/insomnia-teams-rbac-and-domain-capture
  - text: Organizations
    url: /insomnia/organizations/

faqs:
  - q: Why is there not a new free seat in my account after removing a user from my organization?
    a: Removing a user from an organization is not enough to free their seat, you need to remove the user from the [Licenses](https://app.insomnia.rest/app/enterprise/licenses) page.
  - q: Can my organization’s IT department centrally manage Insomnia software updates?
    a: |
      Yes. In Enterprise deployments, an organization’s IT department can centrally manage Insomnia software updates instead of allowing users to install them individually.  
      
      To deactivate automatic updates across managed devices, set the following environment variable:
      ```bash
      INSOMNIA_DISABLE_AUTOMATIC_UPDATES=true
      ```

      Configure this variable through your organization’s device management system. When active, this setting prevents Insomnia from performing automatic updates and allows your IT department to control rollout and version management through its standard deployment process.
  
---

## Insomnia teams

Use teams to manage access for multiple users. From here, add users to a team, and then assign the team to one or more organizations. 

For example, if you have an engineering organization and a product organization, you could create:
* An admin team with access to all organizations
* A development team with access only to the engineering organization
* A product team with access only to the product organization

This approach allows you to manage organization access by adding or removing users from teams.

If you have access to multiple team instances, you can switch between them by doing the following:
1. Navigate to your [Insomnia dashboard](https://app.insomnia.rest/app/dashboard).
1. From the sidebar, click the name of the team that you're currently viewing.
1. From the dropdown menu, select the name of the team that you want to switch to.

Manage teams in [**Enterprise Controls** > **Teams**](https://app.insomnia.rest/app/enterprise/team), to create new teams, invite users to teams, and assign organizations to teams.

You can also manage teams using SCIM provisioning. For more information, see [SCIM](/insomnia/scim/).

{:.info}
> Roles are defined on the team level, which means that if the same team is linked to multiple organizations, the team members will have the same role in all linked organizations.

## Domain capture

{% include insomnia/domain-capture.md %}

## Insomnia licenses

The [**Licenses** tab](https://app.insomnia.rest/app/enterprise/licenses) in your Enterprise settings allows you to manage who can access Enterprise resources.

From this tab, you can also remove users from your Enterprise account. These users will still be able to log in, but they will not have access to Enterprise data and their seat will be freed.

## User activity reports

You can generate a CSV report about active and inactive users by clicking the download button next to **Last Active** in the [Licenses](https://app.insomnia.rest/app/enterprise/licenses) page.
This report contains the date at which each user last opened Insomnia. 

This data is maintained for 90 days. After 90 days without any activity, the date no longer appears in the report but the user will always be listed. If a user was last active more than 100 days before the report was generated, the **Last Active** value for that user will be `N/A` in the report. This allows you to quickly find inactive users.

{:.info}
> For any user who last logged in before May 20, 2025, the date will show their last login date.

## User types

In your Enterprise Plan, there are two types of users:
- **Managed Users**: A user that operates Insomnia from one of your verified domains and is associated with your Enterprise account. These users consume a license.
- **Unmanaged Users**: A user that operates Insomnia from one of your verified domains, but is not associated with your Enterprise account. These users don't consume a license and not impacted by organization policies, for example, restrictions on allowed project storage types.

You can review unmanaged users on a domain to identify accounts that you may want to add to your Enterprise organization. At this time, you must review unmanaged users on a per-domain basis. To view all of the unmanaged users associated with a domain:
1. From Insomnia [**Enterprise Controls**](https://app.insomnia.rest/app/enterprise/), click **Domains** in the sidebar.
1. Select your domain.
1. From the **Unclaimed Accounts** section, click **Manage**.

To associate unmanaged users with your Enterprise account, enable [Domain Capture](#domain-capture):
1. From the Insomnia [**Enterprise Controls**](https://app.insomnia.rest/app/enterprise/), click **Domains** in the sidebar.
1. Select your domain.
1. Enable the **Enable** toggle.

{:.info}
> The number of unmanaged users is cumulative across all your domains. Unclaimed accounts are specific to one domain and only reflect the unmanaged users associated with that specific domain. As a result, if you have more than one domain, the number of unmanaged users won't match the number of unclaimed accounts.
