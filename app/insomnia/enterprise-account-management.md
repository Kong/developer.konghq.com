---
title: Enterprise account management

description: Learn how to manage your Insomnia Enterprise account.

content_type: reference
layout: reference
breadcrumbs: 
  - /insomnia/
  - /insomnia/enterprise/
products:
    - insomnia
search_aliases:
  - insomnia enterprise

tier: enterprise
related_resources:
  - text: Enterprise
    url: /insomnia/enterprise/
  - text: Enterprise user management
    url: /insomnia/enterprise-user-management/
---

## Enable Enterprise membership

To upgrade your account to the Enterprise plan:
1. Contact the [sales team](https://insomnia.rest/pricing/contact) to get an activation code.
1. Go to [Change subscription plan](https://app.insomnia.rest/app/subscription/update), select the Enterprise plan, and enter your activation code.

## Add domains

You can use domains in your Insomnia Enterprise account to manage users.

To create a domain:
{% include insomnia/new-domain.md %}

Once the domain is verified, you can configure its settings to control users with email addresses in that domain.

### Domain capture

{% include insomnia/domain-capture.md %}

### Domain lock

Domain lock allows you to disable access to your Enterprise account for:
* Existing Hobby users in the domain
* Uninvited users in the domain

To enable domain lock, go to your domain settings and click the toggle under **Lock**.

### Invite control

Invite control allows you to specify domains that are allowed to be invited into your Enterprise organizations.

To configure invite control, go to [**Enterprise Controls** > **Invites**](https://app.insomnia.rest/app/enterprise/invite) and define the rules to apply to your organizations.

You can allow invites to all domains, to verified domains only, or to specific domains only.

## Manage storage

{% include insomnia/enterprise-storage.md %}

## Add co-owners

The owner of an Insomnia Enterprise account can invite other users to be co-owners of the account.

To add a co-owner:
1. [Invite](/insomnia/organizations/#invite-users-to-your-organization) the user to your an organization in your Enterprise account.
1. Once they have accepted the invitation, go to [**Enterprise Controls** > **Co-owners**](https://app.insomnia.rest/app/enterprise/co-owners), search for the user's email address and select a role, then click **Invite**.