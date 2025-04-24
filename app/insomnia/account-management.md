---
title: Account Management

description: Learn how to manage your Insomnia account and organization

content_type: reference
layout: reference

products:
    - insomnia

related_resources:
  - text: Incident response
    url: /insomnia/incident-response/
faqs:
  - q: What happens if I forget my Insomnia passphrase?
    a: |
      If you forget your passphrase, your synced data cannot be decrypted. 
      Insomnia uses the SRP protocol, which means the Insomnia Cloud never stores your passphrase. 
      Your encryption keys are derived from your passphrase, so without it, you can't access your encrypted data (Requests, Collections, Environments, etc.).

  - q: Can I reset my Insomnia passphrase?
    a: |
      Yes, you can reset your passphrase via the "Forgot your Passphrase?" link in the login screen or when inviting someone to an organization. 
      After clicking the link, you’ll be asked to enter a new passphrase and confirm:
      * You have backed up the new passphrase.
      * You understand this action will cause the loss of encrypted data with no backup.
      * You will lose access to organizations you were previously invited to.

  - q: Will I lose any data if I reset my Insomnia passphrase?
    a: |
      Yes. Resetting your passphrase will permanently delete all data encrypted with the previous passphrase. 
      You will also lose access to any organizations you've been invited to, unless you are re-invited after the reset.

  - q: Is it possible to recover any data after resetting my passphrase?
    a: |
      In some cases, yes:
      * If you were invited to collaborate on an organization, you can be re-invited and regain access to that data.
      * If others shared organizations or projects with you, users with admin permissions can re-invite you after your reset.
  - q: What platforms does Insomnia run on?
    a: |
      Insomnia is available as a desktop application for 64-bit versions of macOS, Windows, and Linux.

  - q: Does Insomnia provide 32-bit binaries?
    a: |
      No. Insomnia currently supports only 64-bit systems.

  - q: What software license does Insomnia use?
    a: |
      The Insomnia desktop app and related software packages are open source under the [Apache License 2.0](https://opensource.org/license/apache-2-0/). 
      The source code is available on [GitHub](https://github.com/Kong/insomnia). 
      Note that the server-side software that powers the paid sync service is closed source.

  - q: Can I use Insomnia for commercial use?
    a: |
      Yes! Insomnia can be used commercially. Visit our [pricing page](https://insomnia.rest/pricing) for available plans.

  - q: How can I support Insomnia?
    a: |
      Thanks for your support! You can:
      * Spread the word about Insomnia
      * Submit bug reports or feature requests
      * Contribute to our [open source repo](https://github.com/Kong/insomnia)
      * Share how you use Insomnia
      * Sign up for a [paid plan](https://insomnia.rest/pricing)

  - q: Does Insomnia have a EULA?
    a: |
      Currently, Insomnia does not have a dedicated End User License Agreement (EULA). 
      It is governed by the [Apache License 2.0](https://opensource.org/license/apache-2-0/), along with our [Terms of Service](https://insomnia.rest/terms) and [Privacy Policy](https://insomnia.rest/privacy). 
      A formal EULA may be introduced in the future.

  - q: What is the team size limit for a free trial?
    a: |
      The free trial supports up to 5 team members. After the trial, you will be billed based on the number of member seats in your subscription. 
      See our [pricing page](https://insomnia.rest/pricing) for more details.

  - q: How do I increase the number of seats on my team?
    a: |
      The team owner can update the subscription to include more seats by:
      1. Visiting [https://app.insomnia.rest](https://app.insomnia.rest)
      2. Navigating to **Account → Change Subscription**
      3. Increasing the team size as needed

      The updated seat count will be reflected in your next billing cycle.

  - q: How can I customize receipt data?
    a: |
      You can add custom details (company name, address, VAT number, etc.) when [creating or updating your subscription](https://app.insomnia.rest/app/subscribe/). 
      These details will appear on invoices available through the [Invoice History](https://app.insomnia.rest/app/invoices/) page.

      **Note**: Invoice details only appear on downloaded invoices, not the emailed versions.

  - q: Why do I see multiple charges for my Insomnia plan?
    a: |
      Some banks may show multiple charge attempts due to currency differences. 
      However, our payment provider (Stripe) only processes a single charge per billing cycle. 
      If you have concerns, please contact us through the [support page](https://insomnia.rest/support).
---

## Creating an Insomnia account

You can create an Insomnia account using your email, Google, GitHub, or Enterprise SSO. After signing up, you’ll receive a verification code (valid for 30 minutes) to complete registration.

All accounts require setting up an encryption passphrase for end-to-end encryption (E2EE), which protects your data. If the passphrase is lost, encrypted data cannot be recovered.

## Signing in to Insomnia

To sign in, you'll be redirected to a browser to authenticate. Once logged in, you'll return to the app and be prompted to enter your encryption passphrase to access your data.

If the app doesn’t reopen automatically after signing in, you can manually copy and paste your session token into the Insomnia app to complete login.


## Organization management

Users on a Team or Enterprise plan can create new organizations and manage membership from the [Organization dashboard](https://app.insomnia.rest/app/dashboard/organizations). Organization Owners and Administrators have the ability to:

* Invite new users by email
* Assign and change member roles
* Remove members as needed

Adding new members requires the user's encryption passphrase.

## Ownership and transfer

The current Organization Owner can transfer ownership to another member if the following conditions are met:

* The new owner is already a member
* Their subscription level is equal or higher with available seats
* All invitations have been revoked
* SSO is disabled during the transfer

Ownership transfer ensures continued administrative control within the organization.

### Transferring enterprise ownership and license

Enterprise owners can transfer their organization and license to another user by navigating to the Enterprise Controls in the Insomnia app. Navigate to the **Advanced** tab and select the option to transfer license and ownership.

To complete the transfer, the current owner must provide the new owner's email address (entered twice for confirmation) along with their own email to verify identity.

### Ownership confirmation and access

After submitting the transfer request, a confirmation email is sent to both the current and new owners. The new owner must accept the transfer to gain access to enterprise controls and assume ownership of the organization and license.


## Multiple owners in Enterprise accounts

Enterprise accounts support multiple owners. You can grant co-owner access to other members, allowing them full or restricted control over organizations, billing, projects, and members.

To assign co-ownership, the user must first be a member of your enterprise. You can also grant "Billing Only" permissions for users who need limited administrative access.

## Invite control for enterprise accounts

Enterprise owners can manage who is allowed to be invited to their organizations and projects using the Invite Control feature. This capability restricts invites based on email domains, helping prevent unauthorized or mistaken invitations.

Admins can choose from the following invite domain options:

- **All domains**: No restrictions on email domains.
- **Only verified domains**: Only previously verified domains are allowed.
- **Custom domains**: Specific domains defined per organization.

Invite Control can also disable the ability to invite users entirely. If any current members or pending invites do not comply with the configured domain rules, they can be identified and removed.

This feature supports enterprise-grade governance by ensuring only authorized individuals can access your organizations, alongside tools like [Storage Control](/insomnia/storage-control).
