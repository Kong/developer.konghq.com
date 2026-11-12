---
title: How to make the Developer Portal tag search case insensitive
content_type: support
description: Add a custom SwaggerUI filter plugin to the Developer Portal to make tag search match regardless of case.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I make the Developer Portal tag search case insensitive?
  a: |
    The Developer Portal's tag search comes from SwaggerUI's `filter` component, which matches search terms with exact case by default. To make it case insensitive, edit `/themes/base/layouts/system/spec-renderer.html` to define a custom SwaggerUI plugin that overrides `opsFilter` with a case-insensitive comparison, then add that plugin to the SwaggerUI `plugins` option.
---

## Overview

When using the tag search in the Developer Portal, the searches are case sensitive. For example, searching for ' auth ' in the HTTPBin spec returns no results;

whereas searching for ' Auth ' shows the desired results;

How can the tag search be made case insensitive?

## Steps

The tag search is provided from the filter component in SwaggerUI. To change the behavior of the search, it is required to load a plugin to SwaggerUI that provides the custom search implementation.

The SwaggerUI can be customized by editing the `/themes/base/layouts/system/spec-renderer.html` file and adding the custom search function and then adding this function to the SwaggerUI options.

1) Define the plugin function that is used for the case insensitive search;

```js

var CaseInsensitiveFilterPlugin = function (system) {
    return {
        fn: {
            opsFilter: (taggedOps, phrase) => {
                return taggedOps.filter((tagObj, tag) => tag.toLowerCase().indexOf(phrase.toLowerCase()) !== -1);
            }
        }
    }
};
```

2) Add this plugin to the SwaggerUI options;

```js

var swaggerUIOptions = {
  dom_id: '#ui-wrapper', // Determine what element to load swagger ui
  docExpansion: 'list',
  deepLinking: true, // Enables dynamic deep linking for tags and operations
  filter: true,
  oauth2RedirectUrl: '{* portal.url *}/oauth2-redirect',
  presets: [
    SwaggerUIBundle.presets.apis,
    SwaggerUIBundle.SwaggerUIStandalonePreset
  ],
  plugins: [
    SwaggerUIKongTheme.SwaggerUIKongTheme,
    SwaggerUIBundle.plugins.DownloadUrl,
    CaseInsensitiveFilterPlugin
  ],
  layout: 'KongLayout',
  theme: {
    hasSidebar: true,
    swaggerAbsoluteTop: "90px"
  }
}
```

After making these changes, you will have a case insensitive search for tags
