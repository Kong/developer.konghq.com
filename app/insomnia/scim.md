---
title: System for Cross-domain Identity Management (SCIM) for Insomnia

description: Learn how to configure SCIM provisioning for your Enterprise account.

content_type: reference
layout: reference
breadcrumbs: 
  - /insomnia/
products:
    - insomnia
tier: enterprise
related_resources:
  - text: SSO for Insomnia
    url: /insomnia/sso/
  - text: Insomnia Enterprise
    url: /insomnia/enterprise/
  - text: Enterprise user management
    url: /insomnia/enterprise-user-management/
  - text: Enterprise account management
    url: /insomnia/enterprise-account-management/
  - text: Configure SCIM for Insomnia with Okta
    url: /how-to/configure-scim-for-insomnia-with-okta/
  - text: Configure SCIM for Insomnia with Azure
    url: /how-to/configure-scim-for-insomnia-with-azure/    

faqs:
  - q: Do SCIM tokens expire?
    a: |
      Yes. SCIM tokens can expire. However, Insomnia automatically attempts to refresh the token every 90 days. If the automatic refresh fails, Insomnia warns the account owner and co-owners by email and on the SCIM view starting 20 days before the token expires. If it fails, on the [SCIM](https://app.insomnia.rest/app/enterprise/scim) view, manually refresh the token.

      To fix an automatic token refresh failure, go to [SCIM](https://app.insomnia.rest/app/enterprise/scim), and click **Refresh Token**. Then, in the **Passphrase** field, enter your passphrase, and click **Refresh Token** again. This manually refreshes your SCIM connector token.
  - q: What happens if Insomnia cannot refresh the SCIM token automatically?
    a: |
      SCIM effectively breaks. Account owners **must** manually refresh the token to continue SCIM provisioning. You can manually refresh the token by doing the following:
      1. In the Insomnia web app, navigate to **Enterprise Controls > [SCIM](https://app.insomnia.rest/app/enterprise/scim)**.
      2. Select **Refresh Token**.
      3. Enter your passphrase to generate a new token.
      4. In your identity provider, update the token.
  - q: How will I know that the SCIM token is expiring or has expired?
    a: |
      There are two ways that Insomnia will alert you that a token is going to expire:
      
      - **Admin UI**: A warning or error message that indicates that the token is expiring soon or has already expired.
      - **Email**: Insomnia sends an email to organization administrators when a token is expiring and could not be refreshed automatically, or when syncing has stopped because the token has expired.
  - q: What is the impact when a SCIM token refresh fails?
    a: |
      When SCIM token refresh fails:
      - New users are not provisioned from the identity provider.
      - Users deactivated in the identity provider are not removed from Insomnia.
  - q: How do I restore SCIM provisioning after automatic token refresh fails?
    a: |
      To restore SCIM provisioning:
      
      1. Go to **Enterprise Controls > [SCIM](https://app.insomnia.rest/app/enterprise/scim)**.
      2. Select **Refresh Token**.
      3. Enter your passphrase to generate a new token.
      4. In your identity provider, update the token.
  - q: Does the SCIM connector URL change when I refresh the token?
    a: |
      No. The connector URL remains the same. Only the token value changes when you refresh it.
  - q: Does Insomnia store the SCIM token value?
    a: |
      No. Insomnia does not store the SCIM token value. Store the token securely after it is generated.
---

Use SCIM (System for Cross-domain Identity Management) to manage users and teams in Insomnia through your identity provider (IdP) instead of managing them manually.

SCIM is available on the Enterprise plan and is designed to work alongside [Single Sign-On (SSO)](/insomnia/sso/). When you enable SCIM, Insomnia uses your IdP as the source of truth for provisioning. This means that you can:
- Provision Enterprise users and teams from your IdP.
- Manage user access, team membership, and license consumption through your IdP after configuring SSO.
- Keep existing manually managed users unchanged unless you explicitly modify them.

Insomnia supports SCIM provisioning with the following identity providers:
- Okta
- Azure


## Insomnia SCIM requirements

Before enabling SCIM, you must meet all of the following requirements in Insomnia:
- Your organization is on the Enterprise plan.
- You are an Owner or Co-Owner in the Insomnia organization.
- You have verified at least one [domain in Insomnia](https://app.insomnia.rest/app/enterprise/domains/list).
- You configured [SSO](https://app.insomnia.rest/app/enterprise/sso/list) for your identity provider.

In your IdP, you must:
- Have an administrator account
- Have permission to configure SCIM provisioning for the Insomnia application
- Configure [SSO](/insomnia/sso/) between your IdP and Insomnia.

## User and team provisioning
SCIM provisioning in Insomnia follows predictable, non-destructive rules:
- Users and teams that you assigned to the Insomnia application in your IdP are provisioned by Insomnia.
- Existing Insomnia users are matched to IdP users by email address.
- If a user exists in Insomnia but not in the IdP, Insomnia doesn't remove or disable that user automatically.

SCIM provisioning lets you manage access to Insomnia through your IdP, in the same way that you manage access to other enterprise applications.

{:.info}
> SCIM applies only to users and groups provisioned through your identity provider. Users who were added manually before SCIM was enabled remain unchanged and continue to consume licenses until you update or remove them manually. Insomnia does not automatically reconcile or modify manually added users when you enable SCIM. This behavior prevents unintended changes to existing accounts.

When SCIM is enabled, Insomnia licenses are consumed like the following:
- Users provisioned through SCIM consume Enterprise licenses.
- Manually added users continue to consume licenses until you remove them or transition them to IdP-managed provisioning.

For more information about license management, see [Enterprise user management](/insomnia/enterprise-user-management/).

## SCIM connector token lifecycle
SCIM provisioning uses a connector URL and token generated in Insomnia. The token authorizes your identity provider to provision users and teams.

Administrators can view the current SCIM token status in Insomnia:
1. From the Insomnia Enterprise control dashboard sidebar, click [**SCIM**](https://app.insomnia.rest/app/enterprise/scim).
1. Review the SCIM configuration page to see:
  - If SCIM is enabled.
  - If the token is valid, expiring soon, or expired.

When a token is close to expiration and cannot be refreshed automatically, Insomnia displays a warning message on the SCIM page and sends email notifications starting 20 days before the token expires.

### SCIM token expiration and renewal

SCIM tokens expire based on the configuration in your identity provider. When a token approaches expiration or becomes invalid, Insomnia warns account owners and co-owners.

If the token expires and is not renewed:

- New users aren't provisioned from the identity provider.
- Users that you deactivate in the identity provider aren't removed from Insomnia.
- SCIM provisioning stops until the token is refreshed.

You must manually refresh the token from the [SCIM](https://app.insomnia.rest/app/enterprise/scim) settings:
1. In the Insomnia web app, navigate to **Enterprise Controls > [SCIM](https://app.insomnia.rest/app/enterprise/scim)**.
2. Select **Refresh Token**.
3. Enter your passphrase to generate a new token.
4. In your identity provider, update the token.

After you update the token in your identity provider, SCIM provisioning resumes.

## Next steps

Now that you understand how SCIM works in Insomnia and have confirmed the requirements, configure SCIM with your identity provider.

Follow one of the provider-specific guides:
- [Configure SCIM for Insomnia with Okta](/how-to/configure-scim-for-insomnia-with-okta/)
- [Configure SCIM for Insomnia with Azure](/how-to/configure-scim-for-insomnia-with-azure/)
