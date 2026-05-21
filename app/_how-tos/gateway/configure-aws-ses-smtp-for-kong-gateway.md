---
title: Configure AWS SES for SMTP emails in {{site.base_gateway}}
permalink: /how-to/configure-aws-ses-smtp-for-kong-gateway/
content_type: how_to
related_resources:
  - text: Kong Manager configuration
    url: /gateway/kong-manager/configuration/
  - text: Configure Kong Manager to send email
    url: /gateway/kong-manager/configuration/#configure-kong-manager-to-send-email
  - text: Enable Basic Auth for Kong Manager
    url: /how-to/enable-basic-auth-on-kong-manager/

description: Learn how to configure Amazon Simple Email Service (SES) as the SMTP provider for {{site.base_gateway}} to send emails from Kong Manager.

products:
  - gateway

works_on:
  - on-prem

min_version:
  gateway: '3.14'

entities: []

tags:
  - kong-manager
  - aws

tldr:
  q: How do I configure {{site.base_gateway}} to send SMTP emails using AWS SES?
  a: |
    Create an SES service in the AWS console, generate SMTP credentials by creating a dedicated IAM user, then configure the SMTP host, port, username, password, and `admin_emails_from` in your `kong.conf` file.

tools: []

prereqs:
  skip_product: true
  inline:
    - title: "{{site.base_gateway}} with RBAC enabled"
      content: |
        You need a running {{site.base_gateway}} instance with [RBAC and authentication enabled](/how-to/enable-basic-auth-on-kong-manager/).

        SMTP emails are used in Kong Manager for workflows like admin invitations and password resets, which require authentication and RBAC to be turned on.

        Make sure you've copied and renamed the {{site.base_gateway}} `kong.conf`:
        ```sh
        cp /etc/kong/kong.conf.default /etc/kong/kong.conf
        ```
      icon_url: /assets/icons/gateway.svg
    - title: "Create SMTP credentials in AWS SES"
      content: |
        To setup an [Amazon Simple Email Service (SES)](https://console.aws.amazon.com/ses/) SMTP for Kong Manager, you'll need to copy the following credentials from your configured SES:
        * **SMTP endpoint** (for example, `email-smtp.us-east-1.amazonaws.com`)
        * **SMTP username** and **SMTP password** for the [SMTP IAM user](https://docs.aws.amazon.com/ses/latest/dg/smtp-credentials.html#smtp-credentials-console)
          
          {:.warning}
          > **Important:** Copy both the SMTP username and SMTP password immediately. The SMTP password is only shown once and cannot be retrieved later. If you lose it, you must create new credentials.

        Alternatively, if you already have an existing IAM user with SES permissions, you can convert its AWS secret access key into an SMTP password using the [AWS-provided Python script](https://docs.aws.amazon.com/ses/latest/dg/smtp-credentials.html#smtp-credentials-convert) instead of creating a new IAM user. In this case, the SMTP username is the IAM user's AWS access key ID.
      icon_url:  /assets/icons/aws.svg

faqs:
  - q: Can I use an IAM role instead of static SMTP credentials?
    a: |
      No. {{site.base_gateway}} currently requires a static SMTP username and password for authentication. IAM role-based authentication for SES SMTP is not supported at this time.
  - q: Can I store the SMTP password in a Vault instead of kong.conf?
    a: |
      Yes. If you have a [Vault backend configured](/gateway/entities/vault/), you can reference the SMTP password as a Vault secret using the `{vault://...}` syntax in `kong.conf`.

automated_tests: false
---

## Configure {{site.base_gateway}} with SES SMTP settings

Add the following SMTP configuration to your [`kong.conf` file](/gateway/manage-kong-conf/). Replace the placeholder values with the SMTP endpoint, username, and password from the previous step:

```bash
smtp_mock = off
smtp_host = email-smtp.us-east-1.amazonaws.com
smtp_port = 587
smtp_starttls = on
smtp_username = YOUR_SES_SMTP_USERNAME
smtp_password = YOUR_SES_SMTP_PASSWORD
smtp_auth_type = plain

admin_emails_from = YOUR_NAME <verified-sender@example.com>
admin_emails_reply_to = YOUR_NAME <verified-sender@example.com>
```

Replace the following values:
* `smtp_host`: Use the SMTP endpoint from your AWS SES console. The endpoint varies by AWS region (for example, `email-smtp.eu-west-1.amazonaws.com` for the EU Ireland region).
* `smtp_username`: The SMTP username generated in the [prerequisites](#create-smtp-credentials-in-aws-ses).
* `smtp_password`: The SMTP password generated in the [prerequisites](#create-smtp-credentials-in-aws-ses).
* `admin_emails_from`: A verified email address or an address at a verified domain in your SES account.
* `admin_emails_reply_to`: The reply-to email address for outgoing emails.

{:.info}
> By default, `smtp_mock` is set to `on`, which means {{site.base_gateway}} won't actually send emails. Make sure to set `smtp_mock = off` to enable real email delivery.

## Restart {{site.base_gateway}}

After updating `kong.conf`, restart {{site.base_gateway}} to apply the changes:

```bash
kong restart
```

## Validate

To verify that the SMTP configuration is working correctly:

1. Navigate to Kong Manager in your browser (for example, [http://localhost:8002](http://localhost:8002)).

1. Do one of the following:
   * If you have basic authentication enabled, click **Forgot Password** on the login page and enter a valid admin email address. 
   If the configuration is correct, a password reset email is sent to that address via AWS SES.
   * If you're logged in as a super admin, invite a new admin by navigating to **Teams** > **Admins** in the sidebar and clicking **Invite Admin**. 
     Enter an email address and submit. If the SMTP settings are configured correctly, the invitation email is sent through AWS SES.
