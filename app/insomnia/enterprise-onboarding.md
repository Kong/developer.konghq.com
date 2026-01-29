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
  - text: Migrate from scratch pad to Enterprise
    url: /insomnia/migrate-from-scratch-pad-to-enterprise/

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

faqs:
  - q: What happens when my trial ends?
    a: |
      The trial expires automatically after 14 days and reverts to your previous plan. 
      You do not need to cancel manually.
  - q: Who can access organization data after downgrade?
    a: |
      Only the **Organization Owner** can access exported data from inactive organizations. 
      Co-owners and members lose access.
  - q: Can I upgrade from a trial to a paid plan before it ends?
    a: |
      No. Trials cannot be converted mid-cycle. 
      When the trial ends, you can upgrade to a paid plan from your organization settings.
  - q: How many seats are available during the trial?
    a: Each Enterprise trial includes **50 seats**.
  - q: How can I restore Git Sync if I reach the Essentials plan limit?
    a: |
      Reduce the number of active users to three or fewer, 
      or disable Git Sync to continue adding users.
  - q: What data access do I have after I downgrade?
    a: |
      When an Enterprise or Trial subscription ends:
      1. The organization is marked as **inactive**.
      2. Only the **Organization Owner** can access exported data from inactive organizations.  
        Co-owners and other members lose access to that data.
      3. All advanced operations for inactive organizations are disabled.

      Organization data is retained according to Kong’s data retention policies 
      but cannot be modified until reactivated under a supported plan.
  - q: What happens if I downgrade?
    a: |
      Insomnia supports both **manual** and **automatic** downgrades, depending on subscription and renewal status.
      When a paid plan expires without renewal:
      - **Enterprise** downgrades to **Essentials**  
      - **Pro** downgrades to **Essentials**  
      - **Trial** downgrades to the **previous plan**
  - q: Do I need an activation code to start using Insomnia Enterprise?  
    a: |
      Subscriptions that are paid for by credit card are called **Self-serve Enterprise** subscriptions and don't require an activation code.  
      Access is granted automatically once payment is completed.  
    
      If you purchased Enterprise through the **sales team**, you will receive an activation code as part of the onboarding process.
  - q: How do I know that I have successfully upgraded to Insomnia Enterprise?
    a: |
      Look for the **Enterprise** badge in the top-right corner of the app.

      If you don’t see the badge, you're either not part of an Enterprise workspace, or you don't have an **Owner** or **Co-owner** role. If you require support, reach out to **Insomnia Support** at support@insomnia.rest or [https://support.konghq.com/support/s/](https://support.konghq.com/support/s/).
    
---

If you're new to Insomnia Enterprise, this document will guide you through the full setup of your instance in [**Insomnia Admin**](https://app.insomnia.rest/).

{:.decorative}
> **Start a 14-day trial of Insomnia Enterprise:** Any Owner or Co-owner can start a 14-day trial to evaluate Enterprise features in Insomnia. To activate your trial, from the Insomnia application, click **Start 14 day trial** and then confirm. To learn more about Enterprise features, go to the [Insomnia pricing page](https://insomnia.rest/pricing/).

## 1. Activate your Enterprise membership

Once you've signed up for the Insomnia Enterprise plan through the [sales team](https://insomnia.rest/pricing/contact), you'll get an activation code. If you're already an **Owner** or **Co-owner** of an upgraded Enterprise workspace, skip this step.

To activate the code you'll need to follow these steps:

1. In the Insomnia Admin app, click **Upgrade**.
1. On the [Change subscription plan](https://app.insomnia.rest/app/subscription/update) page, select the Enterprise plan.
1. Enter your activation code.
1. Click **Verify activation code**.
   
   Once this is done, you'll be the owner of the Enterprise instance and have access to all the Enterprise features.
1. Click your email address in the header and make sure that your Enterprise instance is selected.
1. Click **Enterprise Controls** to access your Enterprise configuration options.

## 2. Create organizations

By default, your account is created with an organization named **Personal Workspace**. 
You can invite users to that organization, but you can also create other organizations to manage access to projects.
Let's take the example of [KongAir](https://github.com/Kong/KongAir/tree/main?tab=readme-ov-file#kongair): the airline might have a _Cargo_ organization and a _Passengers_ organization, with different projects accessible to different users and teams.

1. In the Insomnia Admin app, navigate to your Insomnia account dropdown menu and click [**Your organizations**](https://app.insomnia.rest/app/dashboard/organizations).
1. Click **New organization**.
1. In the **Organization name** field, enter a name for your organization.
1. Click **Create organization**.

## 3. Create teams

You can add individual users to organizations, but you can also create teams and link them to organizations.
This allows you to manage users more efficiently instead of having to invite each user to each organization manually.

Using the [KongAir](https://github.com/Kong/KongAir/tree/main?tab=readme-ov-file#kongair) example, you could create:
* A _Flight_ team which has access to both organizations
* A _Sales_ team which only has access to the _Passengers_ organization

{:.info}
> You can either create teams manually, or through your [SCIM](#7-enable-scim) provider. Manually created teams can be synchronized with SCIM teams.

To create teams manually:
1. In your Insomnia account dropdown menu, click **Enterprise Controls**.
1. In the sidebar, click [**Teams**](https://app.insomnia.rest/app/enterprise/team).
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

1. In your Insomnia account dropdown menu, click [**Your organizations**](https://app.insomnia.rest/app/dashboard/organizations).
1. Click the org that you want to invite users to.
1. In the **Invite** field, enter the users' email addresses.
1. Click **Invite**.

By default, users are added with the **Member** role, but you can change their role to **Admin** if needed.
Once the users accept the invitation, they will have access to the content in the selected organization.

### Invite a user to a team

1. In your Insomnia account dropdown menu, click **Enterprise Controls**.
1. In the sidebar, click [**Teams**](https://app.insomnia.rest/app/enterprise/team).
1. Click the team you want to invite users to.
1. In the **Invite new members** field, enter the users' email addresses.
1. Select a role from the dropdown menu.
1. Click **Invite**.

Once the users accept the invitation, they will have access to the organizations linked to their team.

## 5. Add a domain

Adding a domain allows you to automatically manage users with email addresses in that domain. It's also a prerequisite for SSO and SCIM.

1. In your Insomnia account dropdown menu, click **Enterprise Controls**.
1. In the sidebar, click [**Domains**](https://app.insomnia.rest/app/enterprise/domains/list).
1. Click **New Domain**.
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

This allows you to completely control where your proprietary code and data are, and what servers they touch.

1. In your Insomnia account dropdown menu, click **Enterprise Controls**.
1. In the sidebar, click [**Storage**](https://app.insomnia.rest/app/enterprise/storage).
1. Click the **Edit** icon for your personal workspaces and organizations.
1. Select the storage options you want to allow.
1. Click **Save**.

## 9. Import content

Now that your Insomnia Enterprise instance is configured, you and your collaborators can start using the Insomnia app to design and test your APIs. If you are migrating from another tool, such as Postman, you can import your content:

* [Import and export reference for Insomnia](/insomnia/import-export/)
* [Migrate collections and environments from Postman to Insomnia](/how-to/migrate-collections-and-envrionments-from-postman-to-insomnia/)
* [Import content from Postman to multiple Insomnia projects](/how-to/import-content-from-postman-to-multiple-insomnia-projects/)
* [Import an API specification as a design document in Insomnia](/how-to/import-an-api-spec-as-a-document/)
