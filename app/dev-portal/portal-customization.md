---
title: Dev Portal Customization Reference
content_type: reference
layout: reference

products:
    - dev-portal

works_on:
    - konnect

description: "The {{site.konnect_short_name}} Dev Portal is a customizable application a for developers to locate, access, and consume API services."
faqs:
  - q: What are the limitations of the Dev Portal Preview feature?
    a: |
      The Preview feature only displays `Visibility: Public` assets like APIs and Menus because it does not simulate a logged-in Developer context.

      **Preview behavior examples:**
      * `Private` Pages **can** be previewed.
      * `Private` APIs **will not** appear when using the `:apis-list` MDC component.
      * `Private` Menus in headers or footers **will not** be shown.

related_resources:
  - text: Custom pages
    url: /dev-portal/custom-pages/
  - text: Portal snippets
    url: /dev-portal/snippets/
  - text: Custom pages
    url: /dev-portal/custom-pages/
---

Customization can be found on the left sidebar when a Dev Portal is selected.

## Menus 

### Visibility

All menu items have visibility controls. Visibility is `Private` by default, and will only be displayed to logged-in Developers. If `Public` is selected, the menu item will be available to all visitors to your Dev Portal.

### Main Menu

Main Menus are a flat list of links that will be added to the header of every page in your Dev Portal. These titles/links will be spaced evenly horizontally.

### Footer Menu Sections

Footer Menus allow you to create a set of columns with links for global navigation. Select **Footer Sections Menu** from the dropdown list to begin creating your menus.

Footer Sections create vertical columns across the bottom of every Page, with the Logo from [Appearance](#appearance) on the left side. It's best to create your desired Footer Sections before creating Footer Menu Items.

Footer Menu Items are links to any URL you prefer, with a title to be displayed. Items must specify a Footer Menu Section.

### Footer Bottom Menu

Footer Bottom Menu is a flat list of links that will be added to the bottom of every page. Footer Bottom Menus are placed below Footer Menu Sections.


## SEO

To optimize how search engines crawl your Dev Portal, you have the ability to specify `/robots.txt` directly. 


## Appearance

Appearance settings are applied globally to all pages in your Dev Portal. Appearance can be found in Portal Editor on the left sidebar.

### Basic Appearance

Basic appearance settings quickly create basic styles for your default portal template.

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Description
    key: description
rows:
  - setting: Theme
    description: Light and dark options are provided. This changes the background and text in your default template. Dark/light is not selectable by Developers.
  - setting: Brand color
    description: This color will be used to set the primary color in the default template.
  - setting: Portal logo
    description: Automatically used in the header and footer menu sections to ensure consistent branding across pages.
  - setting: Favicon
    description: Icon displayed in the browser tab and Favorites for Dev Portal visitors.
{% endtable %}

### Custom CSS

For advanced needs, you can also create Custom CSS that applies custom styles to your Dev Portal. Custom CSS provides global customization to all pages in Dev Portal.

## Portal editor

Portal Editor provides you with a variety of tools for creating highly customized content for your Dev Portal. Navigate to a specific Dev Portal, and select **Portal Editor** from the left sidebar.

{:.info}
> *Pages are built using Markdown Components (MDC). Additional documentation on syntax, as well as tools for generating components, are available on a [dedicated MDC site](https://portaldocs.konghq.com/).*


### Preview panel

Preview will automatically show what your Page should look like when Developers view your Dev Portal. In the event that it fails to refresh after editing the Page, there is a refresh button next to the generated URL at the bottom. 

### Generated URL

Custom pages allow you to define a page structure/tree that organizes your pages and generates the page URL based on page `slug`s. The generated URL is shown at the bottom of the preview pane.

### Viewports

There are three icons above Preview that will allow you to test adaptive designs in some pre-defined viewports.

* Desktop
* Tablet
* Mobile

## Appearance

Basic appearance settings like brand colors, logo, and favicon can be customized to easily convey your branding. For advanced needs, you can also create Custom CSS that applies custom styles to your Dev Portal.

You'll find the Appearance icon in the left sidebar of Portal Editor.

[Customize Appearance](/dev-portal/portal-customization/)

## Additional Customization

Some items like top navigation and SEO optimization/`robots.txt` are available in {{site.konnect_short_name}}, outside of the Portal Editor.


