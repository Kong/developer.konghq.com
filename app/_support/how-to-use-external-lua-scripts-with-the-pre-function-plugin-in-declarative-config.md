---
title: "How to Use External Lua Scripts with the `pre-function` Plugin in declarative config"
content_type: support
description: While Kong DecK does not support referencing external files directly, you can achieve your goal by using environment variables to include the content of your Lua script.
tldr:
  q: How do I reference an external Lua script file in the `config.access` field of the `pre-function` plugin with declarative config and decK?
  a: |
    decK cannot reference external files directly. Load the script into an environment variable (`export DECK_FUNCTION=$(cat function.lua)`) and inject it in the declarative config with `${{ env "DECK_FUNCTION" | indent 8 }}`.
    Multiline indentation support requires decK v1.22.0 or later.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: using environment variables with Kong Deck
    url: /deck/reference/env-variables/
  - text: multiline environment variables in Kong Deck pull request
    url: https://github.com/Kong/deck/pull/929
---

## Overview

How can I reference an external Lua script file, such as `function.lua`, in the `config.access` field of the `pre-function` plugin when using Kong with declarative configuration files and Deck CLI?

## Steps

While Kong DecK does not support referencing external files directly, you can achieve your goal by using environment variables to include the content of your Lua script. Here's how you can do it:

1. Create your Lua script and save it in a file, for example, `function.lua`.

2. Load the content of the Lua script into an environment variable using the following command:

   ```bash
   export DECK_FUNCTION=$(cat function.lua)
   ```

3. Reference the content of the environment variable in your declarative configuration file. Since Kong Deck v1.22.0, you can use indentation to include multiline variable content. Here's an example of how to do this in your configuration:

   ```yaml
   plugins:
   - config:
       access:
       - |
         ${{ env "DECK_FUNCTION" | indent 8 }}
     enabled: true
     name: pre-function
   ```

This approach allows you to maintain the readability and maintainability of your configurations, especially when dealing with complex Lua scripts.
