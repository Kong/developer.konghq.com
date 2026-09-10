---
title: How to deploy multiple custom plugins in Kong in Docker
content_type: support
description: Deploy multiple custom plugins in a Dockerized Kong by mounting them outside the standard plugins directory and configuring `lua_package_path` and `KONG_PLUGINS`.
tldr:
  q: How do I deploy multiple custom plugins in Kong running in Docker?
  a: |
    Mount your custom plugins to a path outside the standard Kong plugins directory, then point `KONG_LUA_PACKAGE_PATH` at it (e.g. `/usr/local/custom_plugins/?.lua;;`) and list the plugins in `KONG_PLUGINS` alongside `bundled`.
    Restart the container to pick up code changes.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
---

## Overview

How can multiple custom plugins be configured for Kong when using Docker?

## Steps

Implementing and updating custom plugins in Kong, particularly within a Docker environment, requires careful consideration of volume mounts and the `lua_package_path` configuration to avoid overwriting existing plugins and to enable seamless updates. Here's a step-by-step guide based on a successful resolution:

1. Mount custom plugin code to a Docker volume.

   To avoid overwriting the standard Kong plugins directory and ensure that your custom plugins are correctly recognized, you should mount your custom plugins directory outside the standard Kong plugins directory.

   First, organize your custom plugins on your host machine with the correct directory structure. For example, if you have custom plugins named `log-filter` and `custom-handler`, your directory structure should look like this:

   ```
   custom_plugins/
   ├─ kong/
   └─── plugins/
   ├───── log-filter/
   └───── custom-handler/
   ```

   Then, mount this directory to the container using a Docker volume that points outside the standard Kong plugins directory:

   ```bash
   -v /path/to/custom_plugins:/usr/local/custom_plugins
   ```

2. Configure `lua_package_path`.

   Adjust the `lua_package_path` to include your custom plugins directory. This tells Kong where to find your custom plugins without interfering with the default plugin directory.

   ```bash
   -e "KONG_LUA_PACKAGE_PATH=/usr/local/custom_plugins/?.lua;;"
   ```

   The `?` in the `lua_package_path` is expanded to `kong/plugins/<plugin-name>`. So for our example plugins, the path will be expanded to:

   ```
   /usr/local/custom_plugins/kong/plugins/<plugin-name>
   ```

   where `<plugin-name>` will be either `log-filter` or `custom-handler`.

3. Load custom plugins.

   Specify your custom plugins in the `KONG_PLUGINS` environment variable, along with the bundled plugins, to ensure they are loaded by Kong.

   ```bash
   -e "KONG_PLUGINS=bundled, log-filter, custom-handler"
   ```

4. Update custom plugins or add new ones.

   Updating the plugin code on the host requires restarting the Kong container to reflect the changes. For adding new plugins, simply follow the steps above to include them in your custom plugins directory and update the `KONG_PLUGINS` environment variable accordingly.
