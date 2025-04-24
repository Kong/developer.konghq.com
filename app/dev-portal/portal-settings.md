---
title: Dev Portal settings
content_type: reference
layout: reference

products:
    - dev-portal

works_on:
    - konnect

description: "Settings allows you to make global changes to your Dev Portal."

related_resources:
  - text: Portal customization reference
    url: /dev-portal/portal-customization/
  - text: Custom pages
    url: /dev-portal/custom-pages/
  - text: Security settings
    url: /dev-portal/security-settings/
---



## Name
This is the name that you will see in your list of Dev Portals in Konnect.

## Display Name

This is utilized for SEO in the Portal and sets what users will see in the browser for the `home` / `/` Page, appended to the front matter title.

### Home Page title format

```
<title>{front matter title} | {display_name}</title>
```


### Home Page title example

Assuming the `home` / `/` page has the following front matter

```
---
title: Welcome to KongAir
description: Start building and innovating with our APIs
---
```

Assuming Dev Portal Settings has the Display Name set to "Developer Portal", the browser would display:

```
Welcome to KongAir | Developer Portal
```


## Description

This description is only displayed in the Konnect, and will not be delivered to users browsing the portal.

To affect meta description/tags in Pages, refer to [Pages docs](/dev-portal/custom-pages/)

## Custom Domains

Learn more about configuring [Custom Domains](/dev-portal/custom-domains)


## Audit logs


Dev Portal audit logs are set up and managed separately from org-wide {{site.konnect_short_name}} audit logs. For more information see the [audit logs documentation](/audit-logs/).