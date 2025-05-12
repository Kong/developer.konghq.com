---
title: Dev Portal snippets
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
  - Portal

breadcrumbs:
  - /dev-portal/

description: "Snippets allow you to reuse content and MDC components across Pages."
faqs:
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

  - q: Is there a size limit for snippets?
    a: |
      Yes. Snippets are limited to a maximum of 1,000,000 characters.

related_resources:
  - text: Portal customization reference
    url: /dev-portal/portal-customization/
  - text: Custom pages
    url: /dev-portal/custom-pages/
---

Snippets allow you to reuse content and MDC components across [pages](/dev-portal/custom-pages). You can enable or disable snippets with visibility controls and publishing status. You can also restrict access to logged in developers.

To get started creating snippets, navigate to your Dev Portal and click [**Portal editor**](/dev-portal/portal-customization/#portal-editor/), then click **Snippets**.

Snippets are built using Markdown Components (MDC). See the [dedicated MDC site](https://portaldocs.konghq.com/components/snippet) for more information about Snippet syntax and usage.

## Create a new snippet

1. At the top of the left sidebar, click **Snippets** then **New Snippet**.
1. Give the snippet a name. 
You will need this name to refer to your snippet from pages, and must be a unique lowercase, `kebab-case` string.
1. The snippet will be created with the `title` in front matter set to the specified name. 
   
   Snippet front matter can be useful to keep track of what you're working on alongside other Portal Editors, as well as providing additional data to the snippet.

1. Edit the content of your snippet in the middle panel using any Markdown or MDC, and you'll see a live preview in the right panel.

## Reference a snippet in a page

You can reuse the snippet component within a page by specifying the name of the snippet. These properties are auto-completed from the list of your previously created snippets.

For example:

```
::snippet
---
name: "get-api-keys"
---
::
```

For more advanced usage, including passing data into Snippets, see our [dedicated MDC site](https://portaldocs.konghq.com/components/snippet).

## Unpublishing snippets

Newly created pages are published by default. If you want to unpublish a snippet, select the snippet in the sidebar, click the menu in the top right corner, and select **Unpublish**. 

This can be useful for providing messaging across pages that is only displayed for a period of time, for example, system outages or special events.

## Change snippet visibility

If you want to change the visibility of a snippet, select the snippet in the sidebar, click the menu in the top right corner, and toggle **Private** or **Public** as needed.
