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
---

## Insomnia teams

You can use teams to manage access for multiple users. You can add users to a team, and the team can then be assigned to organizations. 

Let's say that you have an engineering organization and a product organization. You could create:
* An admin team which has access to all organizations
* A dev team which has access to the engineering organization only
* A product team which has access to the product organization only

This would allow you to automatically add users to the relevant organizations by adding them to a team.

Teams are managed in [**Enterprise Controls** > **Teams**](https://app.insomnia.rest/app/enterprise/team). 
You can create new teams, invite users to teams, and assign organizations to teams.

You can also manage teams using SCIM provisioning. For more information, see [SCIM](/insomnia/scim/).

{:.info}
> **Notes**:
> * Roles are defined on the team level, which means that if the same team is linked to multiple organizations, the team members will have the same role in all linked organizations.
> * Teams can't be renamed or deleted manually in Insomnia, but this feature will be added in a future release. However, teams deleted through SCIM will also be deleted in Insomnia.

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