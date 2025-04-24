---
title: Dev Portal snippets
content_type: reference
layout: reference

products:
    - dev-portal

works_on:
    - konnect

description: "Snippets allow you to reuse content and MDC components across Pages."
faqs:
  - q: Why aren’t parameterized values appearing in the Page Preview?
    a: |
      Preview may not be able to display parameterized values. When the Page is rendered in the Portal, parameters will be resolved. 
      Depending on the syntax used, Preview may not accurately reflect those values in Page or Snippet views.

  - q: Are Snippets visible in the Portal by default?
    a: |
      Snippets are published by default, but they won’t appear in the Portal unless they are reused in a Page.

  - q: What visibility setting is applied when creating a new Snippet?
    a: |
      Snippets are created with the default page visibility setting configured in your [Portal Settings](/dev-portal/portal-settings/).

  - q: Is there a size limit for Snippets?
    a: |
      Yes. Snippets are limited to a maximum of 1,000,000 characters.


related_resources:
  - text: Portal customization reference
    url: /dev-portal/portal-customization/
  - text: Custom pages
    url: /dev-portal/custom-pages/
---



Snippets allow you to reuse content and MDC components across [pages](/dev-portal/custom-pages). You can enable or disable snippets with visibility controls and publishing status. You can also restrict access to logged in developers.

To get started creating Snippets, navigate to your Dev Portal and click [**Portal editor**](/dev-portal/portal-customization/#portal-editor/), then click **Snippets**.


Snippets are built using Markdown Components (MDC). See the [dedicated MDC site](https://portaldocs.konghq.com/components/snippet) for more information about Snippet syntax and usage.


## Create a new Snippet
* Click to create a new Snippet at the top of the left sidebar.
* Give the Snippet a "name". This will be used to refer to your Snippet from Pages, and must be a unique lowercase, `kebab-case` string.
* The Snippet will be created with the `title` in front matter set to the specified name. Snippet front matter can be useful to keep track of what you're working on alongside other Editors as well as providing additional data to the Snippet.
* Edit the content of your Snippet in the middle panel using any Markdown or MDC, and you'll see a Live Preview in the right panel.


## Reference a Snippet in a Page

You can reuse the Snippet component within a Page by specifying the name of the Snippet. These properties are auto-completed from the list of your previously created Snippets.

For example:

```mdc
::snippet
---
name: "get-api-keys"
---
::
```

For more advanced usage, including passing data into Snippets, see our [dedicated MDC site](https://portaldocs.konghq.com/components/snippet).


## Unpublishing Snippets

Newly created Pages are published by default. If you want to unpublish a Snippet, select the Snippet in the sidebar and click the menu in the top right corner and select **Unpublish**. 

This can be useful for providing messaging across Pages that is only displayed for a period of time, for example, system outages or special events.

## Change Snippet visibility
If you want to change the visibility of a Snippet, select the Snippet in the sidebar and click the menu in the top right corner and toggle **Private** and **Public** as needed.
