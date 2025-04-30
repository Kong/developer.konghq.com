---
title: Dev Portal custom pages
content_type: reference
layout: reference

products:
    - dev-portal
beta: true
tags:
  - beta
works_on:
    - konnect
api_specs:
  - konnect/portal-management

search_aliases:
  - MDC
  - Markdown Components
  - Portal

breadcrumbs:
  - /dev-portal/

description: "Customize Dev Portal Pages using Markdown Components (MDC)."
faqs:
  - q: What visibility setting is applied when creating a new page?
    a: |
      Pages are created using the Default Visibility setting configured in your [Portal Settings](/dev-portal/portal-settings/).

  - q: Where can I find the URL for a page in Preview?
    a: |
      When previewing a page, the generated URL is shown at the bottom of the preview window.

  - q: What is the special behavior of the `home` page?
    a: |
      The `home` page represents the `/` root path of your Dev Portal. 
      If it is deleted, you’ll need to recreate it using the [Pages API](/api/konnect/portal-management/v3/#/operations/create-portal-page).

  - q: Is there a size limit for custom pages?
    a: |
      Yes. Custom pages are limited to a maximum of 1,000,000 characters.

related_resources:
  - text: Portal customization reference
    url: /dev-portal/portal-customization/
  - text: Portal snippets
    url: /dev-portal/snippets/
  - text: Custom domains
    url: /dev-portal/custom-domains/
---

Pages are highly customizable using Markdown Components (MDC), allowing you to create nested page structures to organize pages and generate URLs/slugs. Visibility controls and Publishing status allow you to stage new pages, and/or restrict access to logged-in developers.

To get started creating pages, navigate to your Dev Portal and select [**Portal Editor**](/dev-portal/portal-customization/#portal-editor) from the left sidebar.

{:.info}
> *Pages are built using Markdown Components (MDC). Additional documentation on syntax, as well as tools for generating components, are available on a [dedicated MDC site](https://portaldocs.konghq.com/).*

## Page structure

On the left panel inside Portal Editor, you'll see a list of pages in your Dev Portal. The name for each page is a `slug`, and will be used to build the URL for that page. If pages are nested, the slugs will be combined to build the URL.
This allows you to organize pages, and convey that organization in the URLs of your pages.

Example: `about` has a child page, `contact`. The URL for the `contact` page would be `/about/contact`

## Create and manage a page

1. In the Dev Portal editor, click **New page** in the sidebar.
1. Give the page a **slug**. This will be used in constructing the path. Hit Enter.
1. The page will be created and display in preview.
1. Edit the content of your page in the middle panel, and you'll see a live preview in the right panel.

{:.info}
> *To rename a page's slug, click the 'three dots' menu, and click Rename*.

### Publishing a page

Newly created pages are in `Draft` status by default. With the page selected on the left sidebar, click **Publish** in the top right corner, and your page will be published to the Dev Portal.

### Changing page visibility

In the top right corner, click the menu with three dots. You can toggle from `Private` to `Public`, and vice versa.

### Creating a child page

To create pages in a nested structure (generating URLs in a folder-style), you can create **Child Pages**. 
Click the three dots menu next to any page, and select **Create Child Page**. 
As with creating any page, provide a name and slug, and your page will be created.

## Reserved paths

The Portal requires a number of reserved paths from the root of the URL to properly function.
You can't override these paths with custom pages or other functionality.

The following table lists the reserved paths:

<!-- vale off -->
{% table %}
columns:
  - title: Path
    key: path
  - title: Description
    key: description
  - title: RegExp
    key: regexp
rows:
  - path: "`/login/*`"
    description: Login
    regexp: "`^/login(?:\\/.*)?`"
  - path: "`/register`"
    description: Registration
    regexp: "`^/register`"
  - path: "`/forgot-password`"
    description: Forgot password
    regexp: "`^/forgot-password`"
  - path: "`/reset-password`"
    description: Reset password
    regexp: "`^/reset-password`"
  - path: "`/logout`"
    description: Log out
    regexp: "`^/logout`"
  - path: "`/apps/*`"
    description: Developer applications
    regexp: "`^/apps`"
  - path: "`/api/v*/`"
    description: Portal API
    regexp: "`^/api\\/v\\d+\\/.*`"
  - path: "`/_proxy/*`"
    description: Proxied APIs
    regexp: "`^/_proxy/.*`"
  - path: "`/api/*`"
    description: Nuxt server endpoints
    regexp: "`^/api\\/(?!v\\d+\\/).*`"
  - path: "`/_api/*`"
    description: Nuxt server endpoints
    regexp: "`^/_api\\/.*`"
  - path: "`/npm/*`"
    description: CDN proxy
    regexp: "`^/npm\\/.*`"
  - path: "`/_preview-mode/*`"
    description: {{site.konnect_short_name}} previews
    regexp: "`^/_preview-mode\\/.*`"
{% endtable %}

<!--vale on -->


## Meta tags

To affect page metadata/descriptions (meta tags like  `description` `og:description`), use the `description` field in page front matter.

For example, using the following front matter, the Portal will render HTML tags for pages: 

```yaml
---
title: Home
description: Start building and innovating with our APIs
---
```

Will render this: 

```html
<title>Home | Developer Portal</title>
<meta name="description" content="Start building and innovating with our APIs">
<meta property="og:title" content="Home | Developer Portal">
<meta property="og:description" content="Start building and innovating with our APIs">
```

## OpenGraph

The Dev Portal will automatically generates an Open Graph image for each page on the site which uses a default design, and incorporates your brand color and light or dark color mode, along with the page's title and description. This image may be used in search results and when sharing links that render page previews (for example, on X or other social sites).

If you would like to provide a custom Open Graph image, you may do so in the page's front matter by providing the `image` property as a string:

```yaml
---
title: Home
description: Start building and innovating with our APIs
image: https://example.com/images/my-image.png
---
```

If you would like more control over the image, the front matter property also accepts an object interface:

```yaml
---
title: Home
description: Start building and innovating with our APIs
image:
  url: https://example.com/images/my-image.png
  alt: A description of the image
  width: 300px
  height: 200px
---
```