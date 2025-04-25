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

The Dev Portal Setting page allows you to make global changes to your Dev Portal.

## Name

This is the name that you will see in your list of Dev Portals in {{site.konnect_short_name}}.

## Display name

This is used for SEO in the Portal and sets what users will see in the browser for the `home` / `/` Page, appended to the front matter title.

The format looks like this
```
<title>{front matter title} | {display_name}</title>
```

For example, assuming the `home` / `/` page has the following front matter:

```yaml
---
title: Welcome to KongAir
description: Start building and innovating with our APIs
---
```

If Dev Portal settings have the display name set to "Developer Portal", the browser would display:

```
Welcome to KongAir | Developer Portal
```

## Description

This description is only displayed in {{site.konnect_short_name}}, and will not be delivered to users browsing the portal.

To change the meta description and tags in pages, see the [pages reference](/dev-portal/custom-pages/).

## Custom Domains

Learn more about configuring [custom domains](/dev-portal/custom-domains/).

## Audit logs

Dev Portal audit logs are set up and managed separately from org-wide {{site.konnect_short_name}} audit logs. For more information, see the [audit logs documentation](/gateway/audit-logs/).