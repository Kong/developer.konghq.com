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
  - text: Team RBAC and domain capture
    url: https://konghq.com/blog/product-releases/insomnia-teams-rbac-and-domain-capture

faq:
  - q: Why is there not a new free seat in my account after removing a user from my organization?
    a: Removing a user from an organization is not enough to free their seat, you need to remove the user from the [Licenses](https://app.insomnia.rest/app/enterprise/licenses) page.
---

## Teams

You can use teams to manage access for multiple users.

Teams are managed in [**Enterprise Controls** > **Teams**](https://app.insomnia.rest/app/enterprise/team). 
You can create new teams, invite users to teams, and assign organizations to teams.

You can also manage teams using SCIM provisioning. For more information, see [SCIM](/insomnia/scim/).

{:.info}
> **Notes**:
> * Roles are defined on the team level, which means that if the same team is linked to multiple organizations, the team members will have the same role in all linked organizations.
> * Teams can't be deleted manually in Insomnia. However, Teams deleted through SCIM will also be deleted in Insomnia.


## Domain capture

{% include insomnia/domain-capture.md %}

## Licenses

The [**Licenses** tab](https://app.insomnia.rest/app/enterprise/licenses) in your Enterprise settings allows you to manage who can access Enterprise resources.

From this tab, you can also remove users from your Enterprise account. These users will still be able to log in, but they will not have access to Enterprise data and their seat will be freed.

### User activity reports

You can generate a CSV report about active and inactive users by clicking the download button next to **Last Active** in the [Licenses](https://app.insomnia.rest/app/enterprise/licenses) page.
This report contains the date at which each user last opened Insomnia. 

This data is maintained for 100 days. After 100 days without any activity, the date no longer appears in the report but the user will always be listed. If a user was last active more than 100 days before the report was generated, the **Last Active** value for that user will be `N/A` in the report. This allows you to quickly find inactive users.