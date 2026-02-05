---
title: Create and publish an Insomnia plugin
permalink: /how-to/create-an-insomnia-plugin/
content_type: how_to

products:
- insomnia
description: Create a NodeJS module in the Insomnia plugins directory and add it to Insomnia.
breadcrumbs: 
  - /insomnia/plugins/
tags:
- insomnia-plugins

tldr:
  q: How do I create a new Insomnia plugin?
  a: Create a NodeJS module in the Insomnia plugins directory and add it to Insomnia. To publish on the [Plugin Hub](https://insomnia.rest/plugins), publish it as an unscoped public package to the npm public registry.
---

## Create the plugin directory

In order for Insomnia to recognize your plugin as an Insomnia plugin, create a folder in the Insomnia plugins directory:
* `~/Library/Application Support/Insomnia/plugins/` on macOS
* `%APPDATA%\Insomnia\plugins\` on Windows
* `$XDG_CONFIG_HOME/Insomnia/plugins/` or `~/.config/Insomnia/plugins/` on Linux

You can easily do this by going to **Preferences** > **Plugins** and clicking **Generate New Plugin**. This option creates a plugin folder along with two starter files: `package.json` and `main.js`. The new plugin is directly added to Insomnia.

## Configure the plugin

Develop your plugin and make sure the `package.json` file includes the content required to be identified by Insomnia as a plugin. For example:

```json
{
  "name": "insomnia-plugin-base64",
  "version": "1.0.0",
  "main": "app.js",
  "insomnia": {
    "name": "base64",
    "displayName": "base64 Plugin",
    "description": "The base64 plugin encodes and decodes basic strings.",
    "images": {
      "icon": "icon.svg",
      "cover": "cover.svg",
    },
    "publisher": {
      "name": "YOUR NAME HERE",
      "icon": "https://...",
    },

    "unlisted": false
  },
  "dependencies": [],
  "devDependencies": []
}
```

<!-- Link to plugins reference page -->

## Debug the plugin

Insomnia enables debugging using Chrome DevTools. Click **View** > **Toggle DevTools** to open it. You can find your plugin in the **Sources** tab or filter the **Console** based on the plugin's name.


## Publish the plugin

If you to publish your plugin on the [Insomnia Plugin Hub](https://insomnia.rest/plugins), it must follow these requirements:
* The name of the plugin must start with the prefix `insomnia-plugin-`
* The plugin must include a `package.json` file, correctly structured and containing the `insomnia` attribute. See the [Insomnia plugin reference]() for more information.
* The plugin must be publicly available.

Once these requirements are met, follow the [npm docs](https://docs.npmjs.com/creating-and-publishing-unscoped-public-packages) to publish your plugin as an unscoped public package. After a few days, your plugin should appear on the Insomnia Plugin Hub. If it doesn't, [contact us](https://insomnia.rest/support).