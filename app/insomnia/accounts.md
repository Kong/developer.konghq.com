---
title: Accounts

description: Learn how to manage your Insomnia account.

content_type: reference
layout: reference
breadcrumbs: 
  - /insomnia/
products:
    - insomnia
search_aliases:
  - insomnia account
  - e2ee
related_resources:
  - text: Manage Insomnia
    url: /insomnia/manage-insomnia/
  - text: End-to-End Encryption
    url: /insomnia/end-to-end-encryption/
  - text: Insomnia Enterprise
    url: /insomnia/enterprise/
  - text: Enterprise user management
    url: /insomnia/enterprise-user-management/
  - text: Enterprise account management
    url: /insomnia/enterprise-account-management/
  - text: Get started with Insomnia Enterprise
    url: /insomnia/enterprise-onboarding/

faqs:
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
      The free trial supports up to five team members. After the trial, you will be billed based on the number of member seats in your subscription. 
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

      {:.info}
      > **Note**: Invoice details only appear on downloaded invoices, not the emailed versions.

  - q: Why do I see multiple charges for my Insomnia plan?
    a: |
      Some banks may show multiple charge attempts due to currency differences. 
      However, our payment provider (Stripe) only processes a single charge per billing cycle. 
      If you have concerns, please contact us through the [support page](https://insomnia.rest/support).
      Do not include sensitive data in any requests, responses, or logs you share with support unless you send it through a secure channel.


  - q: Why am I not getting my Insomnia login code email?
    a: |
      If sender verification callout is enabled on your mail server, it may be blocking Insomnia emails. To avoid this issue, we recommend disabling sender verification for your mail server.

  - q: If I update my credit card information, are my payments automatically processed?
    a: |
      Yes. After you update your credit card information, that new card is now the default payment method associated with your account. On your next scheduled billing day for your subscription, we process your payment automatically. To update your payment information, contact [Sales](https://insomnia.rest/pricing/contact).

  - q: I have an unpaid invoice, how can I pay it?
    a: |
      Contact [Sales](https://insomnia.rest/pricing/contact) to update your credit card information. Once updated, the outstanding balance is immediately charged to your updated payment method and your billing schedule is restarted, with access to your account restored.
---

## Create an Insomnia account

To create a new account, go to [app.insomnia.rest](https://app.insomnia.rest/app/authorize) and select a sign up option. You'll be prompted to create a [passphrase](#passphrase) to enable [End-to-End Encryption](/insomnia/end-to-end-encryption/).

{:.danger}
> **Warning**: If you reset your passphrase, you will lose the data encrypted with the previous passphrase. To avoid this, make sure to securely back up your passphrase in a password manager, for example.

If needed, you can click **Upgrade** from the Insomnia dashboard to upgrade to a Pro plan or activate an Enterprise plan.

## Invite users

Owners and admins can invite users to collaborate on projects by adding them to organizations.

1. Go to [your organizations](https://app.insomnia.rest/app/dashboard/organizations), select the organization in which you want to invite users, and go to **Collaborators** tab to invite them.
1. In the Insomnia app, select the relevant organization and click the **Invite** button in the header.

Invited users will receive an email. They will need to log in to Insomnia and accept the invite.

## End-to-End Encryption

Hobby accounts created from June 4th 2024 onwards have E2EE disabled by default. While your data remains encrypted at rest and in transit, E2EE offers an additional layer of security by encrypting data so that only the parties involved in the communication can decrypt it.

You can enable or disable E2EE from the **Encryption** tab in your account settings.

For more details about how E2EE works, see [End-to-End Encryption](/insomnia/end-to-end-encryption/).

### Passphrase

Insomnia uses the [Secure Remote Password (SRP) protocol](https://datatracker.ietf.org/doc/html/rfc2945) to handle data encryption, which means:
* Insomnia Cloud doesn't store a user's passphrase in any form
* All user data is encrypted in a manner that requires the user's passphrase to decrypt

If you lose your passphrase, you can reset it using the **Forgot your Passphrase?** link on the login screen, however:
* You will lose access to the organizations you have been invited to. An owner or admin will need to invite you again.
* You will lose access to encrypted data that isn't backed up.

To avoid issues, back up your passphrase in a secure location.