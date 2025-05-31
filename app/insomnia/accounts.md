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
  - text: Enterprise
    url: /insomnia/enterprise/
---

## Create an Insomnia account

To create a new account, go to [app.insomnia.rest](https://app.insomnia.rest/app/authorize) and select a sign up option. You'll be prompted to create a [passphrase](#passphrase).

{:.warning}
> If you reset your passphrase, you will lose the data encrypted with the previous passphrase. To avoid this, make sure to securely back up your passphrase.

Your account is created with a Hobby plan. You can click **Upgrade** from the Insomnia dashboard to upgrade to a Pro plan or activate an Enterprise plan.

## Invite users

You can invite users to collaborate on your projects by adding them to your organizations.

To do that, you can
* Go to [your organizations](https://app.insomnia.rest/app/dashboard/organizations), select to organization in which you want to invite users, and go to **Collaborators** tab to invite them.
* {% new_in 10.1 %} In the Insomnia app, select the relevant organization and click the **Invite** button in the header.

Invited users will receive an email, they will need to log in to Insomnia and accept the invite.

## End-to-End Encryption

Accounts created from June 4th 2024 onwards with a free subscription have E2EE disabled by default. While your data remains encrypted at rest and in transit, E2EE offers an additional layer of security by encrypting data such that only the parties involved in the communication can decrypt it.

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