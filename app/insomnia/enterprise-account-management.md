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

Use domain lock to remove access to your Insomnia Enterprise account for existing hobby users and uninvited new users.

To enable domain lock:
- Navigate to your domain settings and click the toggle under **Lock**.

When you enable domain lock on a specific domain, all users from that domain will no longer be able to access your organization's Insomnia Enterprise account. For example:
- **Existing users without an Enterprise invite:** Ariel is an existing hobby user and wasn’t invited to the Enterprise account. Now, when `Ariel@oldkong.com` attempts to sign in to Insomnia with that address, she won't have access to the Enterprise account.
- **Users without an account, but with a matching email domain:** George doesn't have an Insomnia account, but has an email address `george@DomainLockExample.com`. When George creates an Insomnia account, the domain lock blocks his sign-in, which means that he can't access the Insomnia Enterprise account or its features.

{:.info}
> If you enable both domain capture and domain lock on the same verified domain in Insomnia, then domain capture takes priority for new sign-ups and overrides domain lock.

### Invite control
Use invite control to specify which domains can receive invitations to your Enterprise organizations.

To configure invite control, navigate to [**Enterprise Controls** > **Invites**](https://app.insomnia.rest/app/enterprise/invite) and define the rules to apply to your organizations.

You can set your preference for allowing invitations from the following domain types:
- **All domains**: Invites to any email domain are accepted which includes personal addresses.
- **Only verified domains**: Invites are restricted to domains already added and verified in the Domains section of Enterprise controls.
- **Custom domains**: Invites are limited to manually specified domains or sub‑domains for a specific organization, even if those domains are not globally verified.

## Manage storage

{% include insomnia/enterprise-storage.md %}

## Add co-owners

The owner of an Insomnia Enterprise account can invite other users to be co-owners of the account.

To add a co-owner:
1. [Invite](/insomnia/organizations/#invite-users-to-your-organization) the user to your an organization in your Enterprise account.
1. Once they have accepted the invitation, go to [**Enterprise Controls** > **Co-owners**](https://app.insomnia.rest/app/enterprise/co-owners), search for the user's email address and select a role, then click **Invite**.