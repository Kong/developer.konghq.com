---
title: Access and approvals
content_type: reference
layout: reference
description: |
  Approve and manage developer registrations and applications for the {{site.konnect_short_name}} Dev Portal.
content_type: reference
products:
  - dev-portal
tags:
  - access-control
  - developer-management
works_on:
  - konnect
related_resources:
  - text: "Application registration"
    url: /dev-portal/application-registration/
  - text: "Developer sign up"
    url: /dev-portal/developer-signup/
---

When Dev Portal [security settings](/dev-portal/security-settings/) require manual approval, Portal admins are notified to approve new Developer and Application registrations.

## Developer approvals

Registered developers appear in the default list. Each entry includes their email address and current approval status.

{% table %}
columns:
  - title: Filter
    key: filter
  - title: Description
    key: description
rows:
  - filter: "**Approved**"
    description: Developers who have been approved
  - filter: "**Pending Approval**"
    description: Developers awaiting admin approval
{% endtable %}

To approve a developer, open the menu next to their name and select **Approve**.

You can also add a developer to a team from the {{site.konnect_short_name}}

1. Open the menu next to an approved developer.
2. Select **Add to Team**.
3. Search and select the team, then click **Save**.

Developers can belong to multiple teams.

[Learn more about developer registration &rarr;](/dev-portal/developer-signup/)

## Application approvals

When a developer creates an application from the **My Apps** section, the app is added to the list of all applications and may require approval based on your Portal settings.

{% table %}
columns:
  - title: Filter
    key: filter
  - title: Description
    key: description
rows:
  - filter: "**Approved**"
    description: Applications that have already been approved
  - filter: "**Pending Approval**"
    description: Applications awaiting admin approval
{% endtable %}

To approve an application, open the menu next to the entry and select **Approve**. 
Once approved, the application can generate credentials and use the APIs.