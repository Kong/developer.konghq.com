---
title: Kong SMTP Not Sending Emails with Office 365
content_type: support
description: Kong SMTP fails to send emails through Office 365 unless the `admin_emails_from` and `admin_emails_reply_to` properties are configured.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does Kong SMTP fail to send emails through Office 365?
  a: |
    Office 365 requires two additional Kong SMTP properties — `admin_emails_from` and `admin_emails_reply_to` — that aren't needed for other domains like Gmail. Configure both to resolve SMTP send failures with Office 365.
---

## Problem

When configuring Kong SMTP, there are several domains you can utilize (Gmail, Office 365, etc..). For Office 365, there are two additional properties that need to be added in order for Kong to send emails properly. If these are not set, you may run into the below errors:

```
[info] 41#0: *408 [lua] smtp_client.lua:114: send(): [smtp-client]Error sending email: <email>: /usr/local/share/lua/5.1/resty/mail/smtp.lua:183: SMTP response was not successful: 501 5.1.7 Invalid address, client: <IP>, server: kong_admin, request: "POST /default/admins HTTP/1.1", host: "<Host>", referrer: "<Host>"
```

```
[error] 41#0: *408 [lua] admins_helpers.lua:286: create(): [admins] error inviting user: <User>, client: <IP>, server: kong_admin, request: "POST /default/admins HTTP/1.1", host: "<Host>", referrer: "<Host>"
```

What additional properties need to be added for Office 365?

## Solution

1. `admin_emails_from`

2. `admin_emails_reply_to`

Once those two properties are configured, Kong SMTP should be sending out emails properly to the Office 365 domain.

Gmail doesn't look for these properties to be set, so they are not necessary for Gmail domains.
