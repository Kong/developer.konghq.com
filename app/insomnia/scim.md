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

faqs:
  - q: What happens if Insomnia cannot refresh the SCIM token automatically?
    a: |
      If Insomnia cannot refresh the SCIM token automatically, SCIM provisioning enters a degraded or stopped state. SCIM remains enabled, but syncing pauses until the issue is resolved. A **Refresh Token** action is available in **Enterprise Controls > [SCIM](https://app.insomnia.rest/app/enterprise/scim)**.
  - q: How will I know that the SCIM token is expiring or has expired?
    a: |
      There's two ways for Insomnia to alert you to an expiring token:
      
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

{:.info}
> SCIM applies only to users and groups that are provisioned through your IdP. Users who were added manually before SCIM was enabled remain unchanged and continue to consume licenses until you update or remove them manually.

## User and team provisioning
SCIM provisioning in Insomnia follows predictable, non-destructive rules:
- Users and teams that you assigned to the Insomnia application in your IdP are provisioned by Insomnia.
- Existing Insomnia users are matched to IdP users by email address.
- If a user exists in Insomnia but not in the IdP, Insomnia does not remove or disable that user automatically.

{:.info}
> Users who were added manually before SCIM was enabled you enabled SCIM remain separate from users that were provisioned through your IdP. Insomnia does not automatically change or reconcile manually added users when you enable SCIM. This behavior is expected and prevents unintended changes to existing accounts.

## License usage
- Users provisioned through SCIM consume Enterprise licenses.
- Manually added users continue to consume licenses until you remove them or transition them to IdP-managed provisioning.

For more information about license management, go to [Enterprise user management](/insomnia/enterprise-user-management/).

## SCIM connector token lifecycle
SCIM provisioning uses a connector URL and token generated in Insomnia. The token authorizes your identity provider to provision users and teams.

### Automatic token refresh

Insomnia automatically refreshes SCIM connector tokens before they expire. This helps prevent provisioning interruptions that are caused by routine token expiration and reduces the need for manual maintenance.

### View token status
Administrators can view the current SCIM token status in Insomnia:
1. From the Insomnia Enterprise control dashboard, in the sidebar, select [**SCIM**](https://app.insomnia.rest/app/enterprise/scim).
1. Review the SCIM configuration page too see:
  - If SCIM is enabled.
  - If the token is valid, expiring soon, or expired.

When a token is close to expiration, Insomnia displays a warning message indicating that the token expires soon.

## Supported identity providers

Insomnia supports SCIM provisioning with the following identity providers:
- Okta
- Azure

## Requirements

Before enabling SCIM, you must meet all of the following requirements in Insomnia:
- Your organization is on the Enterprise plan.
- You are an Owner in the Insomnia organization.
- You have verified at least one [domain in Insomnia](https://app.insomnia.rest/app/enterprise/domains/list).
- You configured [SSO](https://app.insomnia.rest/app/enterprise/sso/list) for your identity provider.

From your IdP, you must:
- Have an administrator account in your identity provider.
- Have permission to configure SCIM provisioning for the Insomnia application.
- Configure SSO between your IdP and Insomnia.

## Next steps

Now that you understand how SCIM works in Insomnia and have confirmed the requirements, configure SCIM with your identity provider.

Follow one of the provider-specific guides:
- [Configure SCIM for Insomnia with Okta](/how-to/configure-scim-for-insomnia-with-okta/)
- [Configure SCIM for Insomnia with Azure](/how-to/configure-scim-for-insomnia-with-azure/)
