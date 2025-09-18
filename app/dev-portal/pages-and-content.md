---
title: Dev Portal pages and content
content_type: reference
layout: reference

products:
    - dev-portal
tags:
  - dev-portal-documentation
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
      If it is deleted, you’ll need to recreate it using the [Pages API](/api/konnect/portal-management/#/operations/create-portal-page).

  - q: Is there a character limit for custom pages?
    a: |
      Yes. Custom pages are limited to a maximum of 1,000,000 characters.
  - q: Why aren’t parameterized values appearing in the page Preview?
    a: |
      The preview may not be able to display parameterized values. When the page is rendered in the Portal, parameters will be resolved.
      Depending on the syntax used, the preview may not accurately reflect those values in Page or Snippet views.

  - q: Are snippets visible in the Portal by default?
    a: |
      Snippets are published by default, but they won’t appear in the Portal unless they are reused in a page.

  - q: What visibility setting is applied when creating a new snippet?
    a: |
      Snippets are created with the default page visibility setting configured in your [Portal settings](/dev-portal/portal-settings/).

  - q: Is there a character limit for snippets?
    a: |
      Yes. Snippets are limited to a maximum of 1,000,000 characters.

  - q: I just edited or deleted my spec, document, page, or snippet. Why don't I immediately see these changes live in the Dev Portal?
    a: If you recently viewed the related content, your browser might be serving a cached version of the page. To fix this, you can clear your browser cache and refresh the page.

  - q: How do I add an external link to my Dev Portal main menu or footer?
    a: You can add external links to your main menu or footer by navigating to your Dev Portal in {{site.konnect_short_name}} and clicking **Customization** in the sidebar. From the **Menu** tab, you can select the menu you want to customize and add the external link by clicking **Add menu item** and configuring the link to **Open in a new tab**. You can also send a PATCH request to the [`/portals/{portalId}/customization` endpoint](/api/konnect/portal-management/v3/#/operations/update-portal-customization) to add an external link using the {{site.konnect_short_name}} API by setting the `external` property to `true`.

  - q: How do I add a child page to a parent page using the {{site.konnect_short_name}} Portal Management API?
    a: |
      You can create a child page by specifying the `parent_page_id` in the request body of the []`/portals/{portalId}/pages` endpoint](/api/konnect/portal-management/v3/#/operations/create-portal-page):
      ```json
      {
        "slug": "/contact",
        "title": "Contact us",
        "content": "Contact our company",
        "visibility": "public",
        "status": "published",
        "parent_page_id": "5bc355be-3e92-4b54-88f9-d7c21b0bdba9"
      }
      ```

      The full path of the child page is the slug of the parent page with the slug of the child page. For example, if the parent slug is `/about` and the child slug is `/contact`, the full path to the child page is `/about/contact`.

related_resources:
  - text: Dev Portal Markdown components reference
    url: https://portaldocs.konghq.com/
  - text: Portal customization reference
    url: /dev-portal/portal-customization/
  - text: Custom domains
    url: /dev-portal/custom-domains/
  - text: About Dev Portal customizations
    url: /dev-portal/customizations/dev-portal-customizations/
---

In your Dev Portal, you can create pages that contain content such as text, buttons, tabs, and more. Pages are used to convey information about your API and Dev Portal to users. They are highly customizable using Markdown Components (MDC), allowing you to create nested page structures to organize pages and generate URLs or slugs. You can also stage new pages or restrict access to logged-in developers by using visibility controls and publishing status.

![Dev Portal Editor](/assets/images/dev-portal/dev-portal-editor.png)
> _**Figure 1:** The Portal Editor UI in Dev Portal._

## Pages

You can create multiple pages in the Dev Portal, similar to how a website is structured. Pages can contain text and other objects, like containers and buttons. To get started creating pages, navigate to your Dev Portal and click **Portal Editor** in the sidebar. Pages are built using Markdown Components (MDC). Additional documentation on syntax, as well as tools for generating components, are available on a [dedicated MDC site](https://portaldocs.konghq.com/).

### Page structure

On the left panel inside the Portal Editor, you'll see a list of pages in your Dev Portal. The name for each page is a `slug`, and will be used to build the URL for that page. You can nest child pages under other pages. If pages are nested, the slugs will be combined to build the URL.

For example, if `about` has a child page called `contact`, its URL will be `/about/contact`.

```
about         ← URL: "/about"
└ contact    ← URL: "/about/contact"
```
{:.no-copy-code}

### Page visibility and publishing

You can choose to make a page public or private and publish or unpublish it. To control page visibility and publishing, click a page in the Portal Editor and click the menu at the top right.

### Reserved paths

Dev Portal reserves certain paths from the root of the URL to properly function.
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
  - path: "`/_core/*`"
    description: Core Portal APIs
    regexp: "`^/_core/.*`"
  - path: "`/api/*`"
    description: Nuxt server endpoints
    regexp: "`^/api\\/(?!v\\d+\\/).*`"
  - path: "`/_api/*`"
    description: Nuxt server endpoints
    regexp: "`^/_api\\/.*`"
  - path: "`/api/oauth/*`"
    description: OAuth endpoints
    regexp: "`^/api//oauth\\/.*`"
  - path: "`/npm/*`"
    description: CDN proxy
    regexp: "`^/npm\\/.*`"
  - path: "`/_preview-mode/*`"
    description: {{site.konnect_short_name}} previews
    regexp: "`^/_preview-mode\\/.*`"
  - path: |
      `/.well-known/*`
    description: Site-wide metadata and configurations
    regexp: |
      `^/\.well-known\\/.*`
{% endtable %}

<!--vale on -->


### Metadata

Dev Portal will use the front matter you set in a page, like the title and description, and render HTML tags.

For example:

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

### OpenGraph

The Dev Portal automatically generates an Open Graph image for each page on the site that uses a default design, and incorporates your brand color, light or dark mode, and the page's title and description. This image may be used in search results and when sharing links that render page previews.

If you would like to provide a custom Open Graph image, you can specify it in the page's front matter with the `image` property as a string:

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

## Reuse content with snippets

You can reuse content on multiple pages by using snippets. Snippets allow you to store and write content in one location and use that content in multiple pages. You can also use snippets to publish content temporarily, like system outages or special events.

Snippets are built using Markdown Components (MDC). See the [dedicated MDC site](https://portaldocs.konghq.com/components/snippet) for more information about Snippet syntax and usage.

To get started creating snippets, navigate to your Dev Portal and click **Portal editor**, then click **Snippets**.

