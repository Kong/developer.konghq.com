---
title: "Kong Gateway: Error seen with custom plugin in 3.x: \"module 'resty.rsa' not found:No LuaRocks module found for resty.rsa\""
content_type: support
description: "The error \"module 'resty.rsa' not found: No LuaRocks module found for resty.rsa\" occurs after upgrading Kong Gateway from 2.x to 3.0 or newer, because `resty.rsa` was removed in favor of `resty.openssl`."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: "How do I resolve the \"module 'resty.rsa' not found: No LuaRocks module found for resty.rsa\" error after upgrading Kong Gateway from 2.x to 3.x?"
  a: |
    Kong Gateway 3.0 removed the `resty.rsa` module in favor of `resty.openssl`, so custom plugins that still reference `resty.rsa` fail to load after upgrading. Update the affected custom plugin code to remove `resty.rsa` references, integrating with `resty.openssl` instead where needed, and retest the plugin. Fixing custom plugin code is outside the scope of Kong Support.
---

## Problem

I am trying to upgrade from Kong Gateway 2.x to 3.x, and am receiving an error in the Kong Gateway logs for my custom plugin. The error seen looks like this:

```

Error: /usr/local/share/lua/5.1/kong/tools/utils.lua:793: error loading module 'kong.plugins.{customPluginName}.handler':
...{customPluginName}/utils/security.lua:3: module 'resty.rsa' not found:No LuaRocks module found for resty.rsa
```

## Solution

The error "module 'resty.rsa' not found:No LuaRocks module found for resty.rsa" will occur after upgrading Kong from version 2.x to 3.0 or newer due to the removal of the `resty.rsa` module in favor of the `resty.openssl` module. To resolve this issue, you will need to first identify all the custom plugins referencing `resty.rsa`, and then update the code to remove all references to `resty.rsa`. Depending on the requirements of your custom plugin design, you may need to write code to integrate with the included `resty.openssl` module. Be sure to test your custom plugin afterwards and ensure it's working as intended. Please note that writing/fixing custom plugin code falls outside the scope of Kong Support, however if the custom plugin was written by our Kong Professional Services team then this can be fixed by that team. If the plugin was not written by Kong Professional Services and if you require the issue be resolved with outside help, then your Kong Account Executive will get you in touch with Kong Professional Services.
