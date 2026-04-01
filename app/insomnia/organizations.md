---
title: Organizations

description: Learn how to manage your Insomnia organizations.

content_type: reference
layout: reference
breadcrumbs: 
  - /insomnia/
  - /insomnia/enterprise/
products:
    - insomnia
search_aliases:
  - insomnia organization
  - insomnia workspace
  - personal workspace
related_resources:
  - text: Accounts
    url: /insomnia/accounts/
tier: pro
---

Insomnia organizations allows users to share collections and environments safely and securely with their colleagues.

Members of an organization can make commits and set up branches for their collections. They can also view commits and branches from other members.

To view a complete list of your organizations, go to [**Enterprise Controls** > **Organizations**](https://app.insomnia.rest/app/dashboard/organizations).

## Create an organization

1. Go to your [Insomnia dashboard](https://app.insomnia.rest/app/dashboard).
1. Click **New organization**.
1. Enter a name and click **Create organization**.

{:.info}
> New organizations can only be created by the account owner or co-owners.

## Invite users to your organization

Organization owners and admins can invite new users to an organization:
1. Go to [your organization](https://app.insomnia.rest/app/dashboard/organizations).
1. Enter the email addresses of the users to invite and click **Invite**.
1. Enter your passphrase and click **Invite**.

By default, new users are added with the **Member** role.

{:.warning} 
> Invitation links expire after 30 days. If an invite expires before the user accepts it, the pre-authorised license seat is released and becomes available for reuse.

## Transfer an organization

The organization owner can transfer ownership to another member to ensure continued administrative control within the organization.

The following conditions must be met to transfer an organization:

* The new owner is already a member
* Their subscription level is equal or higher with available seats
* All pending invitations have been revoked
* SSO is disabled during the transfer

To transfer an organization:
1. Go to [your organization](https://app.insomnia.rest/app/dashboard/organizations) and open the  **Advanced** tab.
1. Click **Transfer organization**, enter the new owner's email and confirm the transfer.

To complete the transfer, the new owner will need to log in to their account and accept the request to transfer.

## Manage organization storage

{% include insomnia/enterprise-storage.md %}

## Organization best practices

Navigating between organizations can be difficult when you have a large number of organizations, since they can look identical in the Insomnia sidebar. This will be improved in a future release, but in the meantime we recommend you:
* Use the drop-down list instead of the sidebar. It contains the same content but the drop-down list is easier to read.
* Add different icons to your organizations to differentiate them in the sidebar. To do that, go to the **Profile** tab in [your organization](https://app.insomnia.rest/app/dashboard/organizations).