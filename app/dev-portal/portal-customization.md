---
title: Dev Portal customization
content_type: reference
layout: reference

products:
    - dev-portal
tags:
  - dev-portal-customization

breadcrumbs:
  - /dev-portal/

search_aliases:
  - Portal

api_specs:
  - konnect/portal-management

works_on:
    - konnect

description: "Change the Dev Portal UI appearance and user experience."
faqs:
  - q: What are the limitations of the Dev Portal Preview feature?
    a: |
      The Preview feature only displays `Visibility: Public` assets like APIs and Menus because it does not simulate a logged-in Developer context.

      **Preview behavior examples:**
      * `Private` Pages **can** be previewed.
      * `Private` APIs **will not** appear when using the `:apis-list` MDC component.
      * `Private` Menus in headers or footers **will not** be shown.
  - q: I just edited or deleted my spec, document, page, or snippet. Why don't I immediately see these changes live in the Dev Portal?
    a: If you recently viewed the related content, your browser might be serving a cached version of the page. To fix this, you can clear your browser cache and refresh the page. 
  - q: How do I add an external link to my Dev Portal main menu or footer?
    a: You can add external links to your main menu or footer by navigating to your Dev Portal in {{site.konnect_short_name}} and clicking **Customization** in the sidebar. From the **Menu** tab, you can select the menu you want to customize and add the external link by clicking **Add menu item**. You can also send a PATCH request to the [`/portals/{portalId}/customization` endpoint](/api/konnect/portal-management/v3/#/operations/update-portal-customization) to add an external link using the {{site.konnect_short_name}} API.

related_resources:
  - text: Pages and content
    url: /dev-portal/pages-and-content/
  - text: Custom domains
    url: /dev-portal/custom-domains/
  - text: About Dev Portal customizations
    url: /dev-portal/customizations/dev-portal-customizations/
---

You can configure Dev Portal UI customization settings by navigating to your Dev Portal in {{site.konnect_short_name}} and clicking **Portal Editor** in the sidebar. The Portal Editor provides you with a variety of tools for creating highly customized content for your Dev Portal.

{:.info}
> *Pages are built using Markdown Components (MDC). Additional documentation on syntax, as well as tools for generating components, are available on a [dedicated MDC site](https://portaldocs.konghq.com/).*

## Preview panel

The preview will automatically show what your page should look like when developers view your Dev Portal. In the event that it fails to refresh after editing the page, there is a refresh button next to the generated URL at the bottom.

There are three icons above **Preview** that allow you to test adaptive designs in some predefined viewports:
* Desktop
* Tablet
* Mobile

## Pages and content

In your Dev Portal, you can create pages that contain content such as text, buttons, tabs, and more. Pages are used to convey information about your API and Dev Portal to users. They are highly customizable using Markdown Components (MDC), allowing you to create nested page structures to organize pages and generate URLs or slugs. You can also stage new pages or restrict access to logged-in developers by using visibility controls and publishing status. To configure pages and content, navigate to your Dev Portal in {{site.konnect_short_name}} and click **Portal Editor** in the sidebar. In the Portal Editor sidebar, click the folder icon. 

For more information, see [Dev Portal pages and content](/dev-portal/pages-and-content/).

## Appearance

Appearance settings are applied globally to all pages in your Dev Portal.
To configure appearance settings, navigate to your Dev Portal in {{site.konnect_short_name}} and click **Portal Editor** in the sidebar. In the Portal Editor sidebar, click the paint bucket icon.

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
    description: Icon displayed in the browser tab and Favorites for Dev Portal visitors.
{% endtable %}

### Custom CSS

For advanced needs, you can also create custom CSS that applies custom styles to your Dev Portal. Custom CSS provides global customization to all pages in Dev Portal.

## Dev Portal navigation

You can configure the main menu, footer, and footer bottom navigation menus in your Dev Portal. To configure navigation settings, navigate to your Dev Portal in {{site.konnect_short_name}} and click **Portal Editor** in the sidebar. In the Portal Editor sidebar, click the menu tree icon.

### Main menu

Main menus are a flat list of links that will be added to the header of every page in your Dev Portal.
These titles and links will be spaced evenly horizontally.

You can customize several options for Dev Portal menus. To customize menus in the {{site.konnect_short_name}} UI, navigate to your Dev Portal in {{site.konnect_short_name}} and click **Customization** in the sidebar. From the **Menu** tab, you can select the menu you want to customize and click **Add menu item**.

You can also add external links to all Dev Portal menu items either using the {{site.konnect_short_name}} UI or the [`/portals/{portalId}/customization` endpoint](/api/konnect/portal-management/v3/#/operations/update-portal-customization).

### Footer menu sections

Footer menus allow you to create a set of columns with links for global navigation. Select **Footer Sections Menu** from the dropdown list to begin creating your menus.

Footer sections create vertical columns across the bottom of every page, with the logo from [Appearance](#appearance) on the left side.
We recommend creating your desired footer sections before creating footer menu items.

Footer menu items are links to any URL you prefer, with a title to be displayed. Items must specify a footer menu section.

### Footer bottom menu

Footer bottom menu is a flat list of links that will be added to the bottom of every page.
Footer bottom menus are placed below footer menu sections.

## API specification settings

The API specification settings allow you to control how developers can interact with your API specs in your Dev Portal. To configure API spec settings, navigate to your Dev Portal in {{site.konnect_short_name}} and click **Portal Editor** in the sidebar. In the Portal Editor sidebar, click the code brackets icon.

The following table describes the API spec settings you can configure:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Description
    key: description
rows:
  - setting: Show Try it
    description: Enable in-browser testing for your APIs. All linked gateways must have the CORS plugin configured. For more information, see [Allow developers to try requests from the Dev Portal spec renderer](/catalog/apis/#allow-developers-to-try-requests-from-the-dev-portal-spec-renderer).
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

## Developer email customization

You can customize both the email domain and content of emails that developers receive for the following events:
* Welcome (developer sign-up approved)
* App registration approved
* App registration rejected
* App registration revoked
* Confirm email address
* Reset password
* Account access rejected
* Account access revoked

To configure email customization settings, go to your Dev Portal, click **Portal Editor**, and then click the **Email** icon in the sidebar.

### Email customization variables

In the customization settings, you can use variables. For example, `{% raw %}{{application_name}}{% endraw %}` will be replaced with the name of the application in the email.

The following table contains the variables you can use when customizing emails:

<!--vale off-->
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
  - variable: "<code>&#123;&#123;dev_portal_reply_to&#125;&#125;</code>"
    description: The Dev Portal reply-to email address.
  - variable: "<code>&#123;&#123;developer_email&#125;&#125;</code>"
    description: The email address of the developer.
  - variable: "<code>&#123;&#123;developer_fullname&#125;&#125;</code>"
    description: The full name of the developer.
  - variable: "<code>&#123;&#123;developer_status&#125;&#125;</code>"
    description: The Dev Portal status of a developer. For example, \"approved\", \"pending\", or \"revoked\".
  - variable: "<code>&#123;&#123;portal_display_name&#125;&#125;</code>"
    description: The display name of the Dev Portal.
  - variable: "<code>&#123;&#123;portal_domain&#125;&#125;</code>"
    description: The URL of the Dev Portal.
{% endtable %}
<!--vale on-->

### Customize the email domain

If you want to change the from and reply-to email domains, you can configure a different domain through Dev Portal settings.
Navigate to your Dev Portal, click **Settings** in the sidebar and click the **Custom domains** tab. Click **New email domain** and configure the settings.

Once you've added your new domain, you must add the CNAME records to your DNS server.

{:.info}
> Certain domain names are restricted. See [Domain name restrictions](/dev-portal/custom-domains/#domain-name-restrictions) for more information.

