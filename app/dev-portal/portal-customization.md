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

description: "Change the Dev Portal UI appearance."
faqs:
  - q: What are the limitations of the Dev Portal Preview feature?
    a: |
      The Preview feature only displays `Visibility: Public` assets like APIs and Menus because it does not simulate a logged-in Developer context.

      **Preview behavior examples:**
      * `Private` Pages **can** be previewed.
      * `Private` APIs **will not** appear when using the `:apis-list` MDC component.
      * `Private` Menus in headers or footers **will not** be shown.

related_resources:
  - text: Pages and content
    url: /dev-portal/pages-and-content/
  - text: Custom domains
    url: /dev-portal/custom-domains/
---

Dev Portal UI customization settings can be found on the left sidebar when you select a Dev Portal.

## Menu customization

You can customize several options for Dev Portal menus.

### Visibility

All menu items have visibility controls, which determine which developers can see different menus. Visibility is `Private` by default, and will only be displayed to logged-in Developers. If `Public` is selected, the menu item will be available to all visitors to your Dev Portal.

### Main menu

Main menus are a flat list of links that will be added to the header of every page in your Dev Portal. 
These titles and links will be spaced evenly horizontally.

### Footer menu sections

Footer menus allow you to create a set of columns with links for global navigation. Select **Footer Sections Menu** from the dropdown list to begin creating your menus.

Footer sections create vertical columns across the bottom of every page, with the logo from [Appearance](#appearance) on the left side. 
We recommend creating your desired footer sections before creating footer menu items.

Footer menu items are links to any URL you prefer, with a title to be displayed. Items must specify a footer menu section.

### Footer bottom menu

Footer bottom menu is a flat list of links that will be added to the bottom of every page. 
Footer bottom menus are placed below footer menu sections.

## SEO customization

To optimize how search engines crawl your Dev Portal, you can provide a `/robots.txt` directly. 

## Portal editor

The Portal Editor provides you with a variety of tools for creating highly customized content for your Dev Portal. Navigate to a specific Dev Portal, and select **Portal Editor** from the left sidebar.

{:.info}
> *Pages are built using Markdown Components (MDC). Additional documentation on syntax, as well as tools for generating components, are available on a [dedicated MDC site](https://portaldocs.konghq.com/).*

### Appearance

Appearance settings are applied globally to all pages in your Dev Portal. 
You'll find the Appearance icon in the left sidebar of the Portal Editor.

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

### Preview panel

The preview will automatically show what your page should look like when developers view your Dev Portal. In the event that it fails to refresh after editing the page, there is a refresh button next to the generated URL at the bottom. 

There are three icons above **Preview** that allow you to test adaptive designs in some predefined viewports:
* Desktop
* Tablet
* Mobile

### Generated URL

Custom pages allow you to define a page structure/tree that organizes your pages and generates the page URL based on page slugs. The generated URL is shown at the bottom of the preview pane.

