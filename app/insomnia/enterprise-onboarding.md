---
title: Get started with Insomnia Enterprise

description: Learn how to set up your Insomnia Enterprise instance.

content_type: reference
layout: reference
breadcrumbs: 
  - /insomnia/
  - /insomnia/enterprise/
products:
    - insomnia
tier: enterprise
related_resources:
  - text: Enterprise
    url: /insomnia/enterprise/
  - text: Enterprise account management
    url: /insomnia/enterprise-account-management/
  - text: Enterprise user management
    url: /insomnia/enterprise-user-management/

next_steps:
  - text: Documents
    url: /insomnia/documents/
  - text: Collections
    url: /insomnia/collections/
  - text: Environments
    url: /insomnia/environments/
  - text: Mock servers
    url: /insomnia/mock-servers/
  - text: Scripts
    url: /insomnia/scripts/

---

If you're new to Insomnia Enterprise, this document will guide you through the full setup of your instance in [**Insomnia Admin**](https://app.insomnia.rest/).

## 1. Activate your Enterprise membership

Once you've signed up for the Insomnia Enterprise plan through the [sales team](https://insomnia.rest/pricing/contact), you'll get an activation code.
The first thing you'll need to do is:

1. Go to [Change subscription plan](https://app.insomnia.rest/app/subscription/update).
1. Select the Enterprise plan, and enter your activation code.

Once this is done, you'll be the owner of the Enterprise instance and have access to all the Enterprise features.

## 2. Create organizations

By default, your account is created with an organization named **Personal Workspace**. 
You can invite users to that organization, but you can also create other organizations to manage access to projects.
For example, you could have a _Product_ organization and an _Engineering_ organization, with different projects accessible to different users.

1. Go to [**Your organizations**](https://app.insomnia.rest/app/dashboard/organizations).
1. Click **New organization**.
1. In the **Organization name** field, enter a name for your organization.
1. Click **Create organization**.

## 3. Create teams

You can add individual users to organizations, but you can also create teams and link them to organizations.
Using the _Product_ and _Engineering_ organizations example above, you could create:

* An _Admin_ team which has access to both organizations
* A _Dev_ team which only has access to the engineering organization
* A _Product_ team which only has access to the product organization

{:.info}
> You can either create teams manually, or through your [SCIM](#7-enable-scim) provider. Manually created teams can be synchronized with SCIM teams.

To create teams manually:

1. Navigate to [**Enterprise Controls** > **Teams**](https://app.insomnia.rest/app/enterprise/team).
1. Click **Create Team**. 
1. In the **Team name** field, enter a team name.
1. In the **Description** field, enter a team description.
1. Click **Create team**.
1. Click the team you just created.
1. Click the **+** button for the Org links to link one or more organizations to the team.

Each time a new member is added to the team, they will automatically have access to the linked organizations.

## 4. Invite users

New users can be invited to your Enterprise instance in three different ways:
* Manually through an organization
* Manually through a team
* Automatically with [SCIM](#set-up-scim)

{:.info}
> **Notes**:
> * Each pending invitation uses a seat in your instance.
> * An invitation expires after 30 days. Once an invitation expires, the corresponding seat is open.
> * When you remove a user from an org or team, you must also remove them from the [Licenses](https://app.insomnia.rest/app/enterprise/licenses) page to free the seat, even if the user was removed from all organizations and teams in the instance.

### Invite a user to an organization

1. Go to [**Your organizations**](https://app.insomnia.rest/app/dashboard/organizations).
1. Click the org that you want to invite users to.
1. In the **Invite** field, enter the users' email addresses.
1. Click **Invite**.

By default, users are added with the **Member** role, but you can change their role to **Admin** if needed.
Once the users accept the invitation, they will have access to the content in the selected organization.

### Invite a user to a team

1. Navigate to [**Enterprise Controls** > **Teams**](https://app.insomnia.rest/app/enterprise/team).
1. Click the team you want to invite users to.
1. In the **Invite new members** field, enter the users' email addresses.
1. Select a role from the dropdown menu.
1. Click **Invite**.

Once the users accept the invitation, they will have access to the organizations linked to their team.

## 5. Add a domain

Adding a domain allows you to automatically manage users with email addresses in that domain. It's also a prerequisite for SSO and SCIM.

To add a new domain:
1. Go to [**Domains**](https://app.insomnia.rest/app/enterprise/domains/list) and click **New Domain**.
1. From the **Verify using** settings, select how you want to verify your domain:
  * **Unique verification record**: This is the option to use for most domains.
  * **Root domain verification record**: You can this option to reuse the existing verification record of a root domain to verify a subdomain. For example, if you have already verified the `example.com` domain, you can use this option to verify `app.example.com` without having to add a new record to your DNS.
1. In the **Domain** field, enter your domain.
1. Click **Create Domain**. If you selected **Root domain verification record**, the domain will be verified automatically.
1. If you selected **Unique verification record**, Insomnia provides a TXT record that you'll need to add to your DNS tool to verify the domain.
Once you've added the record to your DNS tool, click the checkbox to confirm that it's done, and click **Verify Domain**.

Once your domain is created, you can click it to access its settings. For more details, see [Add domains](/insomnia/enterprise-account-management/#add-domains).

## 6. Enable SSO

Once your domain is verified, you can set up SSO with SAML 2.0 or OIDC with your preferred provider.

See our how-to guides to learn how to configure SSO for Insomnia with:
* [Okta SAML](/how-to/okta-saml-sso-insomnia/)
* [Okta OpenID Connect](/how-to/okta-oidc-sso-insomnia/)
* [Azure SAML](/how-to/azure-saml-sso-insomnia/)

## 7. Enable SCIM

Once you've configured SSO, you can use the same provider to set up SCIM.

See our how-to guides to learn how to configure SCIM for Insomnia with:
* [Okta SAML](/how-to/configure-scim-for-insomnia-with-okta/)
* [Azure SAML](/how-to/configure-scim-for-insomnia-with-azure/)

## 8. Configure storage control

Insomnia allows you to have control over the [storage options](/insomnia/storage/) used in your instance. You can define whether users can use [Cloud Sync](/insomnia/storage/#cloud-sync), [Local Vault](/insomnia/storage/#local-vault), or [Git Sync](/insomnia/storage/#git-sync) storage, or a combination of these.

1. Navigate to [**Enterprise Controls** > **Storage**](https://app.insomnia.rest/app/enterprise/storage).
1. Click the **Edit** icon for your personal workspaces and organizations.
1. Select the storage options you want to allow.
1. Click **Save**.

## 9. Import content

Now that your Insomnia Enterprise instance is configured, you and your collaborators can start using the Insomnia app to design and test your APIs. If you are migrating from another tool, such as Postman, you can import your content:

* [Import and export reference for Insomnia](/insomnia/import-export/)
* [Migrate collections and environments from Postman to Insomnia](/how-to/migrate-collections-and-envrionments-from-postman-to-insomnia/)
* {% new_in 11.6 %} [Import content from Postman to multiple Insomnia projects](/how-to/import-content-from-postman-to-multiple-insomnia-projects/)
* [Import an API specification as a design document in Insomnia](/how-to/import-an-api-spec-as-a-document/)