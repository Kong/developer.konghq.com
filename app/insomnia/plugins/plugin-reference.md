---
title: Plugin reference

description: "Learn about Insomnia's plugin context that allow plugins to interact with requests, responses, the app UI, and stored data."

content_type: reference
layout: reference

products:
- insomnia

breadcrumbs:
- /insomnia/
- /insomnia/plugins/

tags:
- plugins
- template-tags

search_aliases:
  - Insomnia plugins
  - Insomnia custom plugins
related_resources:
  - text: Plugins
    url: /insomnia/plugins/
  - text: Context object reference
    url: /insomnia/plugins/context-object-reference/
  - text: Hooks and actions
    url: /insomnia/plugins/hooks-and-actions/
  - text: Insomnia Plugin Hub
    url: https://insomnia.rest/plugins
  - text: Template tags
    url: /insomnia/template-tags/
faqs:
  - q: I'm having issues with a third-party plugin. What should I do?
    a: |
      Insomnia cannot guarantee support for third-party plugins. 
      If the plugin is officially maintained by the Insomnia team, reach out to [our community](https://insomnia.rest/support).
---


Insomnia's plugin context provides various helpers that allow plugins to interact with requests, responses, the app UI, and stored data. This enables advanced customization and extension of the Insomnia application.

## Request and response helpers

The `context.request` object allows plugins to read and modify request data, such as URLs, headers, body, and authentication. This is commonly used for tasks like injecting headers or altering request payloads before sending.

The `context.response` object provides access to response metadata, headers, and body content. Plugins can log responses, alter the response body, or save it to a file using Node.js streams and buffers.

## App, store, and utility helpers

Insomnia uses the following app, store, and utility helpers:
- `context.app`: Exposes UI features like alerts, dialogues, prompts, clipboard access, and app metadata
- `context.store`: Provides persistent plugin-specific storage, useful for caching or configuration
- `context.data`: Supports import and export of Insomnia data in various formats (e.g., raw, HAR, Insomnia JSON/YAML)
- `context.network`: Enables sending arbitrary network requests, useful for chaining calls or external integrations

## Template tags overview

[Template tags](/insomnia/template-tags/) in Insomnia act as operations rather than static values. They are often used to transform strings, generate UUIDs or random values, and insert timestamps. Template tags can be inserted anywhere environment variables are supported by pressing `Ctrl+Space`.

## Built-in and custom tags

Built-in tags include support for dynamic data from responses, requests, and generated values. You can also create custom template tags as plugins using the Insomnia plugin system, enabling behavior like parsing headers or injecting tokens.

## Request and response chaining

You can use the following tags to chain requests and responses:
- **Response tags** allow referencing values from previous responses, useful for request chaining (e.g., grabbing a newly created ID).
- **Request tags** enable referencing values within the current request, like extracting a CSRF token from a cookie to reuse in a header or form field.

For custom behavior, you can define tags using the `TemplateTag` interface, providing configuration options, validation, and logic for generating values.

## Custom themes

You can create a custom Insomnia theme by building a plugin that defines color values for UI components. Themes can be used to adjust background, text, and highlight colors across the application.

To get started, see the [Insomnia themes](https://github.com/Kong/insomnia/tree/develop/packages/insomnia/src/plugins/themes) module for live examples.

### Creating a theme plugin

Custom themes are written as plugins. Start your plugin project with a name like `insomnia-plugin-my-theme`, and export your theme using the `module.exports.themes` array.

#### Example: dark theme plugin structure

```ts
module.exports.themes = [{
  name: 'dark-colorblind',
  displayName: 'Dark Colorblind',
  theme: {
    background: {
      default: '#21262D',
      success: '#1F6FEB',
      danger: '#FF4242',
      surprise: '#FFC20A',
    },
    foreground: {
      default: '#ffffff',
      surprise: '#000000',
    },
    highlight: {
      default: '#D3D3D3',
    },
    styles: {
      editor: {
        foreground: {
          default: '#000000',
        }
      },
      dialog: {
        background: {
          default: '#2E4052',
        },
        foreground: {
          default: '#ffffff',
        }
      }
    }
  }
}];
```

### Available style targets

You can customize the following UI areas using `styles` with `background`, `foreground`, and `highlight` values:

* `appHeader`
* `dialog`, `dialogHeader`, `dialogFooter`
* `dropdown`, `editor`, `link`, `overlay`
* `pane`, `paneHeader`
* `sidebar`, `sidebarHeader`, `sidebarList`
* `tooltip`, `transparentOverlay`

### Adding raw CSS (optional)

You can extend your theme with custom CSS using the `rawCss` property, though using predefined theme keys is preferred for future compatibility.

#### Example: add transparency to tool tips and dropdowns

```ts
module.exports.themes = [{
  name: 'my-dark-theme',
  displayName: 'My Dark Theme',
  theme: {
    rawCss: `
      .tooltip, .dropdown__menu {
        opacity: 0.95;
      }
    `,
  },
}];
```

