---
title: Configure Azure Communication Services for SMTP emails in {{site.base_gateway}}
permalink: /how-to/configure-azure-smtp-for-kong-gateway/
content_type: how_to
related_resources:
  - text: Kong Manager configuration
    url: /gateway/kong-manager/configuration/
  - text: Configure Kong Manager to send email
    url: /gateway/kong-manager/configuration/#configure-kong-manager-to-send-email
  - text: Enable Basic Auth for Kong Manager
    url: /how-to/enable-basic-auth-on-kong-manager/

description: Learn how to configure Azure Communication Services as the SMTP provider for {{site.base_gateway}} to send emails from Kong Manager.

products:
  - gateway

works_on:
  - on-prem

min_version:
  gateway: '3.14'

entities: []

tags:
  - kong-manager
  - azure

tldr:
  q: How do I configure {{site.base_gateway}} to send SMTP emails using Azure Communication Services?
  a: |
    Create an Azure Communication Services resource with an email resource connected, register a Microsoft Entra application with the **Communication and Email Service Owner** role, and create an SMTP username. Then, configure the SMTP host, port, username, password, and `admin_emails_from` in your `kong.conf` file.

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
    - title: Azure Communication Services resource
      content: |
        You need an [Azure Communication Services resource](https://learn.microsoft.com/en-us/azure/communication-services/quickstarts/create-communication-resource) with an [Email Communication resource](https://learn.microsoft.com/en-us/azure/communication-services/quickstarts/email/create-email-communication-resource) connected and a verified domain.

        Follow the [Azure SMTP authentication guide](https://learn.microsoft.com/en-us/azure/communication-services/quickstarts/email/send-email-smtp/smtp-authentication) to create your SMTP credentials. You'll need to note the **SMTP username** and the **Microsoft Entra application client secret** for the next step.
      icon_url: /assets/icons/cloud.svg
faqs:
  - q: Can I store the SMTP password in a Vault instead of kong.conf?
    a: |
      Yes. If you have a [Vault backend configured](/gateway/entities/vault/), you can reference the SMTP password as a Vault secret using the `{vault://...}` syntax in `kong.conf`.
automated_tests: false
---

## Configure {{site.base_gateway}} with Azure SMTP settings

Add the following SMTP configuration to your [`kong.conf` file](/gateway/manage-kong-conf/). 
Replace the placeholder values with the SMTP endpoint, username, and password from the [prerequisites](#azure-communication-services-resource):

```bash
smtp_mock = off
smtp_host = smtp.azurecomm.net
smtp_port = 587
smtp_starttls = on
smtp_username = YOUR_SMTP_USERNAME
smtp_password = YOUR_ENTRA_CLIENT_SECRET
smtp_auth_type = login

admin_emails_from = YOUR_NAME <verified-sender@example.com>
admin_emails_reply_to = YOUR_NAME <verified-sender@example.com>
```

Replace the following values:
* `smtp_username`: The SMTP username you created in the Azure portal.
* `smtp_password`: The Microsoft Entra application client secret.
* `admin_emails_from`: A connected email address from your Azure Communication Services domain.
* `admin_emails_reply_to`: The reply-to email address for outgoing emails.

## Restart {{site.base_gateway}}

After updating `kong.conf`, restart {{site.base_gateway}} to apply the changes:

```bash
kong restart
```

## Validate

To verify that the SMTP configuration is working correctly, do the following:

1. Navigate to Kong Manager in your browser (for example, [http://localhost:8002](http://localhost:8002)).
1. Do one of the following:
   * If you have basic authentication enabled, click **Forgot Password** on the login page and enter a valid admin email address. 
     If the configuration is correct, a password reset email is sent to that address via Azure Communication Services. 
   * If you're logged in as a super admin, invite a new admin by navigating to **Teams** > **Admins** and clicking **Invite Admin**. 
     Enter an email address and submit. If the SMTP settings are configured correctly, the invitation email is sent through Azure Communication Services.
