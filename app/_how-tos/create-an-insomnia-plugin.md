---
title: Create and publish an Insomnia plugin

products:
- insomnia

tags:
- plugins

tldr:
  q: How do I create a new Insomnia plugin?
  a: Create a NodeJS module in the Insomnia plugins directory and add it to Insomnia. To publish on the [Plugin Hub](https://insomnia.rest/plugins), publish it as unscoped public package to the npm public registry.
---

## 1. Create the plugin directory

In order for Insomnia to recognize your plugin as an Insomnia plugin, create a folder in the Insomnia plugins directory:
* `~/Library/Application Support/Insomnia/plugins/` on MacOS
* `%APPDATA%\Insomnia\plugins\` on Windows
* `$XDG_CONFIG_HOME/Insomnia/plugins/` or `~/.config/Insomnia/plugins/` on Linux

You can easily do this by going to **Preferences** > **Plugins** and clicking **Generate New Plugin**. This option creates a plugin folder along with two starter files: `package.json` and `main.js`. The new plugin is directly added to Insomnia.

## 2. Configure the plugin

Develop your plugin and make sure the `package.json` file includes the content required to be identified by Insomnia as a plugin. For example:

```json
{
  "name": "insomnia-plugin-base64", // NPM module name, must be prepended with insomnia-plugin-
  "version": "1.0.0",               // Plugin version
  "main": "app.js",                 // Entry point

  // Insomnia-specific metadata. Without this, Insomnia won't recognize the module as a plugin.
  "insomnia": {
    "name": "base64",                                                       // Internal Insomnia plugin name
    "displayName": "base64 Plugin",                                         // Plugin display name
    "description": "The base64 plugin encodes and decodes basic strings.",  // Plugin description

    // Optional plugin metadata

    // Plugin images for Plugin Hub and other interfaces
    "images": {
      // Plugin Icon
      // Suggested filetype: SVG (for scaling)
      // Suggested dimensions: 48x48
      "icon": "icon.svg", // relative path, relative to package root

      // Plugin Cover Image
      // Suggested filetype: SVG (for scaling)
      // Suggested dimensions: 952w x 398h
      "cover": "cover.svg", // relative path, relative to package root
    },

    // Force plugin hub and other entities to show specific author details
    // Useful for teams and organizations who work on the same plugin
    "publisher": {
      "name": "YOUR NAME HERE", // Plugin publisher name, displayed on plugin hub
      "icon": "https://...",    // Plugin publisher avatar or icon, absolute url
    },

    "unlisted": false // Set to true if this plugin should not be available on the Plugin Hub
  },

  // External dependencies are also supported
  "dependencies": [],
  "devDependencies": []
}
```

<!-- Link to plugins reference page -->

## 3. Debug the plugin

Insomnia enables debugging using Chrome DevTools. Click **View** > **Toggle DevTools** to open it. You can find your plugin in the **Sources** tab or filter the **Console** based on the plugin's name.


## 4. Publish the plugin

If you to publish your plugin on the [Insomnia Plugin Hub](https://insomnia.rest/plugins), it must follow these requirements:
* The name of the plugin must start with the prefix `insomnia-plugin-`
* The plugin must include a `package.json` file, correctly structured and containing the `insomnia` attribute. See the [Insomnia plugin reference]() for more information.
* The plugin must be publicly available.

Once these requirements are met, follow the [npm docs](https://docs.npmjs.com/creating-and-publishing-unscoped-public-packages) to publish your plugin as an unscoped public package. After a few days, your plugin should appear on the Insomnia Plugin Hub. If it doesn't, [contact us](https://insomnia.rest/support).