---
title: "{{site.dev_portal}} customizations"
content_type: reference
layout: reference
permalink: /dev-portal/customizations/dev-portal-customizations/

breadcrumbs:
  - /dev-portal/

products:
  - dev-portal

works_on:
  - konnect

description: "Customize the look, structure, and access of your {{site.dev_portal}} with flexible page controls and branding options"

related_resources:
  - text: Pages and content
    url: /dev-portal/pages-and-content/
  - text: "{{site.dev_portal}} MDC docs"
    url: https://portaldocs.konghq.com/
  - text: "{{site.dev_portal}} global settings"
    url: /dev-portal/portal-settings/
  - text: VS Code extension
    url: https://marketplace.visualstudio.com/items?itemName=konghq.vscode-konnect-dev-portal-toolkit
  - text: "{{site.konnect_short_name}} MCP Server"
    url: /konnect-platform/konnect-mcp/
  - text: Custom domains
    url: /dev-portal/custom-domains/

faqs:
  - q: How do I customize the reply-to and from for {{site.dev_portal}} emails?
    a: |
      {% include faqs/portal-email.md %}
---

You can customize your {{site.dev_portal}}s with the following features:
- Configure layout, navigation, branding, and domain settings.
- Build content-rich pages with Markdown Components, nest information, and reuse snippets.
- Manage page visibility, publishing workflow, and SEO metadata.
- Customize global appearance, apply custom CSS, and set up menus and navigation structures.
- Set up and manage custom domains, SSL certificates, and URL paths.

The preview will automatically show what your page should look like when developers view your {{site.dev_portal}}. In the event that it fails to refresh after editing the page, there is a refresh button next to the generated URL at the bottom.

There are three icons above **Preview** that allow you to test adaptive designs in some predefined viewports:
* Desktop
* Tablet
* Mobile

## Pages and content

In your {{site.dev_portal}}, you can [create pages](/dev-portal/pages-and-content/) that contain content such as text, buttons, tabs, and more.
Pages are used to convey information about your API and {{site.dev_portal}} to users.
They are highly customizable using [Markdown Components (MDC)](https://portaldocs.konghq.com/), allowing you to create nested page structures to organize pages and generate URLs or slugs.
You can also stage new pages or restrict access to logged-in developers by using visibility controls and publishing status.

To configure pages and content, navigate to your {{site.dev_portal}} in {{site.konnect_short_name}} and click **Portal Editor** in the sidebar.
In the Portal Editor sidebar, click the folder icon.
You can also manage pages and content using the [{{site.konnect_product_name}} MCP Server](/konnect-platform/konnect-mcp/).

## Appearance

Appearance settings are applied globally to all pages in your {{site.dev_portal}}. For advanced needs, you can also create custom CSS that applies custom styles to your {{site.dev_portal}}. Custom CSS provides global customization to all pages in {{site.dev_portal}}.
To configure appearance settings, navigate to your {{site.dev_portal}} in {{site.konnect_short_name}} and click **Portal Editor** in the sidebar. In the Portal Editor sidebar, click the paint bucket icon.

Basic appearance settings quickly create basic styles for your default Portal template:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Description
    key: description
rows:
  - setting: Theme
    description: You can choose from default light and dark options. This changes the background and text in your default template. Dark or light theme is not selectable by developers.
  - setting: Brand color
    description: This color is used to set the primary color in the default template.
  - setting: Portal logo
    description: Automatically used in the header and footer menu sections to ensure consistent branding across pages.
  - setting: Favicon
    description: Icon displayed in the browser tab and Favorites for {{site.dev_portal}} visitors.
{% endtable %}

## {{site.dev_portal}} navigation

You can configure the main menu, footer, footer bottom, and sidebar navigation menus in your {{site.dev_portal}}.
To configure navigation settings, navigate to your {{site.dev_portal}} in {{site.konnect_short_name}} and click **Portal Editor** in the sidebar.
In the Portal Editor sidebar, click the menu tree icon.

{% table %}
columns:
  - title: Menu
    key: menu
  - title: Description
    key: description
rows:
  - menu: Main menu
    description: Main menus are a flat list of links that will be added to the header of every page in your {{site.dev_portal}}. These titles and links will be spaced evenly horizontally. You can also add external links to all {{site.dev_portal}} menu items either using the {{site.konnect_short_name}} UI or the [`/portals/{portalId}/customization` endpoint](/api/konnect/portal-management/v3/#/operations/update-portal-customization).
  - menu: Footer menu sections
    description: Footer menus allow you to create a set of columns with links for global navigation. Select **Footer Sections Menu** from the dropdown list to begin creating your menus. Footer sections create vertical columns across the bottom of every page, with the logo from [Appearance](#appearance) on the left side. We recommend creating your desired footer sections before creating footer menu items. Footer menu items are links to any URL you prefer, with a title to be displayed. Items must specify a footer menu section.
  - menu: Footer bottom menu
    description: Footer bottom menu is a flat list of links that will be added to the bottom of every page. Footer bottom menus are placed below footer menu sections.
  - menu: Sidebar navigation
    description: |
      The sidebar navigation menu is a grouped, vertical list of links that displays on the left side of the page. You can configure this in the **Sidebar Navigation** section of the Portal Editor or using the [`/portals/{portalId}/customization/navigations` endpoint](/api/konnect/portal-management/). You **must** select a [page layout](/dev-portal/pages-and-content/#page-layouts) that supports a sidebar menu, otherwise it won't render. You can choose to have one sidebar menu for all pages by only adding a single `/` navigation entry with links in the group, or split your sidebar menu into different sections (for example, `/getting-started` and `/guides`). You can also omit a sidebar menu for a section, which is useful for content like release notes. Individual links can be restricted to signed-in developers, and you can also add external links.
{% endtable %}

## API specification settings

The API specification settings allow you to control how developers can interact with your API specs in your {{site.dev_portal}}. To configure API spec settings, navigate to your {{site.dev_portal}} in {{site.konnect_short_name}} and click **Portal Editor** in the sidebar. In the Portal Editor sidebar, click the code brackets icon.

The following table describes the API spec settings you can configure:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Description
    key: description
rows:
  - setting: Show Try it
    description: Enable in-browser testing for your APIs. All linked gateways must have the CORS plugin configured. For more information, see [Allow developers to try requests from the {{site.dev_portal}} spec renderer](/catalog/apis/#allow-developers-to-try-requests-from-the-dev-portal-spec-renderer).
  - setting: Show Try it in Insomnia
    description: Enables users to open the API spec in [Insomnia](/insomnia/) to explore and send requests with the native client.
  - setting: Continuous scroll
    description: Display the full spec on a single, scrollable page. If disabled, documentation, endpoints, and schemas appear on separate pages.
  - setting: Show schemas
    description: Control whether schemas are visible in your API specs. When enabled, schemas appear in the side navigation below the endpoints.
  - setting: Hide deprecated endpoints
    description: Manage visibility of deprecated endpoints and models.
  - setting: Hide internal endpoints
    description: Manage visibility of internal endpoints and models.
  - setting: Allow custom server URL
    description: Let users define a custom server URL for endpoints. This will be used to generate code snippets and to test the API. The URL is client_side only and is not saved.
{% endtable %}

## Custom forms

{% include_cached sections/custom-form-tutorials.md %}

Custom forms let you add configurable fields to the developer registration form or to a per-API application registration form, so you can capture the information you need to make approval decisions.

There are two types of custom forms:
* **Developer registration form**: One per {{site.dev_portal}}. Once published, it replaces the default developer sign-up form. If you create the form via the API, you must include the required `full_name` and `email` fields yourself, along with any other additional fields you want.
* **API registration forms**: You can create multiple forms and assign one to each API publication. APIs without an assigned form use the default registration flow, with no extra fields.

Use cases for custom forms include:
{% include_cached sections/custom-form-use-cases.md %}

{% include_cached sections/custom-form-constraints.md %}

The table shows which field types are available when building a form.

{% include_cached sections/custom-form-field-types.md %}

## Developer email customization

You can customize both the email domain and content of emails that developers receive for the following events:
* Welcome (developer sign-up approved)
* App registration approved
* App registration rejected
* App registration revoked
* [API key expired](/dev-portal/auth-strategies/#configure-the-key-auth-strategy)
* [API key expiring soon](/dev-portal/auth-strategies/#configure-the-key-auth-strategy)
* Confirm email address
* Reset password
* Account access rejected
* Account access revoked

To configure email customization settings, go to your {{site.dev_portal}}, click **Portal Editor**, and then click the **Email** icon in the sidebar.

In the customization settings, you can use variables. For example, `{% raw %}{{application_name}}{% endraw %}` will be replaced with the name of the application in the email.

The following table contains the variables you can use when customizing emails:

{% table %}
columns:
  - title: Variable
    key: variable
  - title: Description
    key: description
rows:
  - variable: "<code>&#123;&#123;api_documentation_url&#125;&#125;</code>"
    description: The documentation URL for the API.
  - variable: "<code>&#123;&#123;api_name&#125;&#125;</code>"
    description: The name of the API.
  - variable: "<code>&#123;&#123;api_version&#125;&#125;</code>"
    description: The version of the API.
  - variable: "<code>&#123;&#123;application_name&#125;&#125;</code>"
    description: The name of the developer's application.
  - variable: "<code>&#123;&#123;credential_name&#125;&#125;</code>"
    description: The name of the key auth credential.
  - variable: "<code>&#123;&#123;credential_expires_at&#125;&#125;</code>"
    description: "The date when the [key auth credential expires](/dev-portal/auth-strategies/#configure-the-key-auth-strategy)."
  - variable: "<code>&#123;&#123;dev_portal_reply_to&#125;&#125;</code>"
    description: The {{site.dev_portal}} reply-to email address.
  - variable: "<code>&#123;&#123;developer_email&#125;&#125;</code>"
    description: The email address of the developer.
  - variable: "<code>&#123;&#123;developer_fullname&#125;&#125;</code>"
    description: The full name of the developer.
  - variable: "<code>&#123;&#123;developer_status&#125;&#125;</code>"
    description: The {{site.dev_portal}} status of a developer. For example, \"approved\", \"pending\", or \"revoked\".
  - variable: "<code>&#123;&#123;portal_display_name&#125;&#125;</code>"
    description: The display name of the {{site.dev_portal}}.
  - variable: "<code>&#123;&#123;portal_domain&#125;&#125;</code>"
    description: The URL of the {{site.dev_portal}}.
{% endtable %}

### Customize the email domain

If you want to change the from and reply-to email domains, you can configure a different domain through {{site.dev_portal}} settings.
Navigate to your {{site.dev_portal}}, click **Settings** in the sidebar and click the **Custom domains** tab. Click **New email domain** and configure the settings.

Once you've added your new domain, you must add the CNAME records to your DNS server.

{:.info}
> Certain domain names are restricted. See [Domain name restrictions](/dev-portal/custom-domains/#domain-name-restrictions) for more information.
