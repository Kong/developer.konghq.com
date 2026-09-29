---
title: Setting up Kong with SMTP server to use for admin invite or forgot password (using Gmail SMTP server)
content_type: support
description: Configure Kong to send admin invite and forgot-password emails using Gmail's SMTP server and an app password.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Gmail SMTP server documentation (Google)
    url: https://knowledge.workspace.google.com/admin/gmail/send-email-from-a-printer-scanner-or-app?hl=en#send-email-with-the-gmail-smtp-server
  - text: Enabling 2-Step Verification (Google)
    url: https://support.google.com/accounts/answer/185839
  - text: Kong SMTP configuration reference
    url: /gateway/configuration/#general-smtp-configuration-section
tldr:
  q: How do I configure Kong to send admin invite and forgot-password emails through Gmail's SMTP server?
  a: |
    Set the SMTP parameters in `kong.conf` (or as environment variables) — `smtp_host=smtp.gmail.com`, `smtp_port=587`, `smtp_starttls=on`, `smtp_auth_type=plain` — using a Gmail app password rather than your real account password, and set `admin_emails_from` to match `smtp_username`. The same configuration also covers Forgot Password emails; if `portal=on`, the Developer Portal's own SMTP parameters must be configured separately.
---

## Steps

This example will use Gmail SMTP server to send Kong email to recipient. For more details about using Gmail SMTP server, see the Gmail SMTP server documentation in Related resources.

1. Set up an `app password` for your Gmail account. This will enable you to use the email service without using your real password.

   You may need to enable 2 Step verification for your account to create an `app password`. For more details on how to enable 2 Step verification, see the 2-Step Verification documentation in Related resources.

   After you create an `app password`, you should see the password for your account like below:

2. Setup kong parameters for SMTP in `kong.conf` or as environment variables. Below are the minimum required parameters to setup the SMTP with Gmail SMTP server. Below will use `kongtestsmtp@gmail.com` as a test account.

   ```bash
   smtp_mock=off
   smtp_host=smtp.gmail.com
   smtp_port=587
   smtp_starttls=on
   smtp_username=kongtestsmtp@gmail.com <-- your gmail account
   smtp_password=kvttlirflsbobuwx <-- your gmail app password
   smtp_auth_type=plain
   admin_emails_from=kongtestsmtp@gmail.com <-- The email FROM for Kong to send out, it must be same with your smtp_username, as you will using the account to send it out.
   ```

   For more details on the parameters, see the Kong SMTP configuration reference in Related resources.

3. Now invite a new admin by going to `Teams` > `Invite Admin` from Kong Manager and specify the admin email. For this example, the admin email will use the same test account, so the `kongtestsmtp@gmail.com` will receive the invitation email from the same `kongtestsmtp@gmail.com`

4. Check your email inbox. You should see the invitation email from email you set for `admin_emails_from`.

## Additional notes

- This method is also applicable to receive email for `Forgot Password`

- If `portal=on`, the Developer portal SMTP parameters are needed to be set up too. Please use `portal=off` when testing the KB.
</content>
