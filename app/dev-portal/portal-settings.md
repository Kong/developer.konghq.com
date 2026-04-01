---
title: Global Dev Portal configuration
content_type: reference
layout: reference

products:
    - dev-portal
tags:
  - dev-portal-customization

breadcrumbs:
  - /dev-portal/

api_specs:
  - konnect/portal-management

search_aliases:
  - Portal

works_on:
    - konnect

description: "Learn about the settings you can configure for Dev Portal."

related_resources:
  - text: Pages and content
    url: /dev-portal/pages-and-content/
  - text: Security settings
    url: /dev-portal/security-settings/
  - text: Custom domains
    url: /dev-portal/custom-domains/
  - text: About Dev Portal customizations
    url: /dev-portal/customizations/dev-portal-customizations/
---

The Dev Portal Setting page allows you to make global changes to your Dev Portal.

## Name

This is the name that you will see in your list of Dev Portals in {{site.konnect_short_name}}.

## Display name

This is used for SEO in the Portal and sets what users will see in the browser for the `home` or `/` Page, appended to the front matter title.

The format looks like this
```
<title>{front matter title} | {display_name}</title>
```

For example, assuming the `home` or `/` page has the following front matter:

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

To change the meta description and tags in pages, see the [pages reference](/dev-portal/pages-and-content/).

## Visibility

All menu items have visibility controls, which determine which developers can see different menus. Visibility is `Private` by default, and will only be displayed to logged-in Developers. If `Public` is selected, the menu item will be available to all visitors to your Dev Portal.

## Custom Domains

You can customize the Dev Portal domain name. Learn more about configuring [custom domains](/dev-portal/custom-domains/).

## Audit logs

Dev Portal audit logs are set up and managed separately from org-wide {{site.konnect_short_name}} audit logs. For more information, see the [audit logs documentation](/gateway/audit-logs/).

## SEO customization

To optimize how search engines crawl your Dev Portal, you can provide a `/robots.txt` directly.