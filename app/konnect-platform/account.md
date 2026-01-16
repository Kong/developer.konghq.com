---
title: "{{site.konnect_short_name}} account, pricing, and organization deactivation"

description: Learn how to cancel and deactivate an account in {{site.konnect_short_name}}
breadcrumbs:
  - /konnect/
content_type: policy
layout: reference

products:
    - konnect
works_on:
    - konnect

tags:
  - organization
  - account-management

search_aliases:
  - billing
  - pricing
  - deactivate
  - org switcher

related_resources:
  - text: "{{site.base_gateway}} version support policy"
    url: /gateway/version-support-policy/
  - text: Common Vulnerability Scoring System
    url: https://www.first.org/cvss/
faqs:
  - q: How do I close my Plus or Enterprise account?
    a: |
      To close a Plus or Enterprise account, you can:
      * Go to [**My Account**](https://cloud.konghq.com/global/account) > **Delete Account**.
      * Go to Organization > Settings > General > **Deactivate Organization**
      * Request deactivation from Kong Support by navigating to the **?** icon on the top right menu and clicking **Create support case** or from the [Kong Support portal](https://support.konghq.com).
  - q: When is my free account deactivated?
    a: |
      A free {{site.konnect_short_name}} organization is automatically deactivated after 30
      days of inactivity.

      Your organization is considered inactive when:
      * There is no user login into the organization within the last 30 days.
      * There are no API requests in either the current or the previous billing cycle
      (30 day increments).
  - q: What happens if an organization is deactivated?
    a: |
      If your organization account is deactivated, and can no longer log into the
      organization, either through the {{site.konnect_short_name}} UI or the API, then the following happens:
      * All billing stops immediately, and all {{site.konnect_short_name}} subscriptions
      are removed.
      * The control plane (both the {{site.base_gateway}} and {{site.product_mesh_name}} global control planes) associated with the organization are decommissioned.
      * {{site.product_mesh_name}} local zone control planes and data plane nodes (workloads) continue to run, but will not receive new configuration updates.
      * Any users that were part of the organization are removed from any teams
      associated with the organization, and lose roles associated with the deactivated organization.
      Their accounts are otherwise unaffected.
      * The email associated with the organization is locked and can't be used to
      create another {{site.konnect_short_name}} account.

      If you have registered data plane nodes, they won't be
      stopped by {{site.konnect_short_name}}. They will no longer proxy data, but the
      nodes will keep running until manually stop them.
  - q: How do I deactivate or reactivate an org?
    a: |
      Contact Kong Support by navigating to the **?** icon on the top right menu and clicking **Create support case** or from the [Kong Support portal](https://support.konghq.com) to do any of the following:
      * Deactivate an organization that you registered
      * Reactivate an organization that has been deactivated
      * Unlock an email for use with another organization
  - q: How do I manage and view billing and usage?
    a: |
      You can view service, Dev Portal, and API call usage from the [Billing and Usage](https://cloud.konghq.com/global/plan-and-usage/).

  - q: What is the difference between an Organization Owner and an Organization Admin?
    a: |
      The Organization Owner is the single user tied to the organization itself, while Organization Admins are roles that multiple users can hold.
      - An Organization Owner is a property of the organization that identifies a single user as the Owner. The Owner is automatically assigned when the organization is created and always has the Organization Admin role. Each organization can have only one Owner.
      - An Organization Admin is a role that can be assigned to multiple users. Admins can manage users, teams, and roles, but they can't delete the organization. Only the Owner can delete an organization.

  - q: How do I change the Owner of my organization?
    a: |
      The Owner of an organization in {{site.konnect_short_name}} can transfer ownership in {{site.konnect_short_name}}.
      
      To change the Owner, ensure that the new Owner is already a member of the [Organization Admin pre-defined team](/konnect-platform/teams-and-roles/#predefined-teams) and follow these steps:
      1. Go to [**Organization**](https://cloud.konghq.com/global/organization/settings/) > **General**.
      1. Select a new Organization Owner
      1. Click **Save**
      
      If an Org Owner has left the organization without transfering ownership reach out to [Kong support](https://support.konghq.com/).
  - q: How can I create a support case in {{site.konnect_short_name}}?
    a: |
      If you're an org admin with an Enterprise account and a [Kong Support portal](https://support.konghq.com/support/s/) account, you can create a support case in {{site.konnect_short_name}} by navigating to the **?** icon on the top right menu and clicking **Create support case**. 

      This opens a pop-up dialog where you can enter your case type, description, and the related {{site.konnect_short_name}} entity.

      You can see your support cases in the [Kong Support portal](https://support.konghq.com). 
      
      If you don't have a Kong Support portal account, request access from your org admin or reach out to a Kong representative for an invite.
  - q: Can a {{site.konnect_short_name}} Organization Admin or Owner reset a {{site.konnect_short_name}} user's password?
    a: |
      No, {{site.konnect_short_name}} Organization Admins or Owners can't reset a user's password directly. Each user can only reset their own password.
      
      To reset their password, the user should go through the password reset flow from the {{site.konnect_short_name}} [login page](https://signin.cloud.konghq.com). The user should enter their email, then click on **Forgot your password?** to start the reset flow.
---

{{site.konnect_short_name}} offers [two plans](https://konghq.com/pricing).

* **{{site.konnect_short_name}} Plus**: {{site.konnect_short_name}} Plus is the simplest way to get started with {{site.konnect_short_name}}, allowing you to only pay for the services you consume. New accounts are automatically given a month of free credits as part of 30-day trial. You can claim your Konnect Plus credits by [signing up](https://konghq.com/products/kong-konnect/register).
* **{{site.konnect_short_name}} Enterprise**: {{site.konnect_short_name}} Enterprise is our contract-based option that includes 24x7x365 support and professional services access to help you build and maintain your own custom environment. Learn more about enterprise on our [pricing page](https://konghq.com/pricing).


## License management

When you create a {{site.konnect_short_name}} account, {{site.ee_product_name}}, {{site.kic_product_name}} (KIC), and {{site.mesh_product_name}}
licenses are automatically provisioned to the organization. You do not need to manage these
licenses manually.

Any data plane nodes or {{site.kic_product_name}} associations configured in {{site.konnect_short_name}}
also implicitly receive the same license from the {{site.konnect_short_name}}
control plane. You should never have to deal with a license directly.

For any license questions, contact your sales representative.

## Geographic region management

When you create a {{site.konnect_short_name}} account, you select a [geographic region](/konnect-platform/geos/) for your instance. Geos are distinct deployments of {{site.konnect_short_name}} with objects, such as services and consumers, that are geo-specific. Only authentication is shared between {{site.konnect_short_name}} geos.

## Org switcher

The org switcher allows a user with multiple {{site.konnect_short_name}} accounts to switch between their organizations. 
You can navigate to the org switcher by clicking on **Your Org Name** > **View Organizations** in the {{site.konnect_short_name}} side menu.

### Email matching

The org switcher uses the email of the logged in user to locate all organizations where this email is attached to a {{site.konnect_short_name}} account. 

To gain access to more organizations, you can:
* Create a new organization: Newly created organizations will automatically show up in the org switcher.
* Be invited to an organization: Organizations that the user is invited to will automatically show up in the org switcher.

{:.warning}
> **Note**: If you don't choose to "Link Accounts" when logging into {{site.konnect_short_name}} for the very first time on different social credentials, it's possible to end up with more than one org switcher identity. To avoid issues, we recommend linking accounts when using multiple social identities.
> <br><br>
> Organizations will only be associated with one primary account. It's **not** currently possible to re-link accounts.

### Switch organizations

Users can switch organizations while logged in by clicking on the **Org Name** > **View Organizations**, then selecting an org from the list.

If the organization is configured to be single-sign-on (SSO) only, then the user will be directed to the configured identity provider to re-authenticate into {{site.konnect_short_name}}.

{:.info}
> **Note**: You can't be logged in to more than one {{site.konnect_short_name}} organization at the same time. 
You must return to the org switcher to switch to another organization.

### Delete organizations from org switcher

To remove organizations from the org switcher, you can log in to that organization and navigate to 
[**My Account**](https://cloud.konghq.com/global/account) > **Delete Account**. 
This will delete the {{site.konnect_short_name}} account in that organization and remove the org from org switcher.