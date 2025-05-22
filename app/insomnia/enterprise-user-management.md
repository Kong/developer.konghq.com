---
title: Enterprise user management

description: Learn how to manage your Insomnia enterprise users and licenses.

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

## Licenses and seats

The [**Licenses** tab](https://app.insomnia.rest/app/enterprise/licenses) in your enterprise settings allows you to manage who can access enterprise resources.

From this tab, you can remove users from your enterprise account. These users will still be able to log in, but they will not have access to enterprise data and their seat will be freed.

