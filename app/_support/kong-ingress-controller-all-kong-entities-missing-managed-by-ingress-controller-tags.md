---
title: "Kong Ingress Controller: All Kong entities missing managed-by-ingress-controller tags"
content_type: support
description: The simplest way to remedy the missing tags is to make use of our Deck tool.
products:
  - kic
works_on:
  - on-prem
  - konnect
tldr:
  q: Why are all Kong entities missing the `managed-by-ingress-controller` tag, causing HTTP 409 conflicts in KIC?
  a: |
    If Kong entities lose their `managed-by-ingress-controller` tag, KIC can no longer reconcile them and logs HTTP 409 unique-violation errors. Use decK's `add-tags` command to dump the current config, blanket-apply the tag, and sync it back so KIC recognizes the entities again.
related_resources:
  - text: add-tags
    url: /deck/reference/deck_file_add-tags/
---

## Problem

We have had a functioning KIC + Proxy Gateway (Database backed) installation and recently we are seeing 409 duplicate conflict errors in our KIC logging. When we take a look at some of the entities it is complaining about we see them present in our Kong Manager / Admin API but they are missing the required 'managed-by-ingress-controller' tag.

Error message from the KIC:

```

time="xxx" level=error msg="could not update kong admin" error="x errors occurred:\n\twhile processing event: {Create} xxxxxxx failed: HTTP status 409 (message: \"UNIQUE violation detected on '{name=\\\"xxxxxxxx\\\"}'\")
```

Upon further inspection we see that all of our Kong entities no longer have this tag. How can we update all of our Kong entities so that they have the required tag again?

## Solution

The simplest way to remedy the missing tags is to make use of our Deck tool. In version 1.24+ there is a function called `add-tags`:

By default, this function will add tags to every single Kong entity in a given Deck dump .yaml file.

To fix the above problem, we can perform the following steps:

1. Create a deck dump of our `broken` Kong Gateway:

   ```bash
   deck dump --kong-addr https://gateway_admin_api_endpoint  -o Tagsfixdump.yaml
   ```

   If your Admin API is protected by RBAC, you will need to add a token header (--headers "kong-admin-token: <admin token value>")

2. Blanket add tags to all objects in the dump file (The tag we want is set at the end of the command and should be whatever you have set for `kong_admin_filter_tag` in your KIC environment variables. The default is `managed-by-ingress-controller`)

   ```bash
   deck file add-tags -s Tagsfixdump.yaml -o Tagsfixdump2.yaml managed-by-ingress-controller
   ```

3. Sync all newly tagged objects back to the Gateway:

   ```bash
   deck sync --kong-addr https://gateway_admin_api_endpoint  -s Tagsfixdump2.yaml
   ```

4. Now that the KIC sees all of the objects have the proper ownership tag, it will delete/recreate the objects as necessary and syncing should begin working again.
