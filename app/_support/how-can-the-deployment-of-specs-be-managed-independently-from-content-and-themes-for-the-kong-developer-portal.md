---
title: Managing spec deployment independently from content and themes in the Kong Developer Portal
content_type: support
description: "How to manage spec file deployments independently from Developer Portal content and theme updates by retrieving, deleting, or updating existing spec files to avoid unique constraint violations."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How can the deployment of specs be managed independently from content and themes for the Kong Developer Portal?
  a: |
    Use the Admin API `/files` endpoints to manage spec files (paths under `specs/`) separately from content and theme files. Since Kong doesn't support bulk deletion, either retrieve and delete existing specs before uploading new ones at the same path, or use `PATCH` to update an existing spec file in place, to avoid unique constraint violations.
related_resources: []
---

## Overview

How can the deployment of specs be managed independently from the content and themes? In particular, how can the specs be updated without altering the content and theme files?

## Steps

When managing the deployment of content/themes and swagger specs to the Kong Developer Portal separately, it's important to handle spec files carefully to avoid unique constraint violations when a file with the same name already exists. The core issue revolves around updating or deleting existing spec files before uploading new or updated ones.

Note: on the Kong Gateway (Enterprise) 3.11.0.0+ line, the on-prem/Gateway-native Developer Portal (and the `/files`/`/specs` Admin API routes this workflow depends on) is deprecated and returns a flat `404` on a standard Enterprise license, regardless of `KONG_PORTAL`/workspace `config.portal` settings — it requires a separate, non-standard license entitlement. If your `/files`/`/specs` calls return `404`, this is the likely cause; contact Kong support to confirm your license's Developer Portal entitlement. The workflow below remains correct for any environment where the Developer Portal is actually enabled and licensed.

To address this challenge, follow the steps below:

1. Retrieving and Deleting Existing Specs

   Since there's no single API call to delete all spec files in bulk, you'll need to first retrieve all the spec files and then delete them individually if needed. This can be achieved using a combination of `curl`, `jq`, and `xargs` commands. Here's how you can do it:

   a. Retrieve the paths of all spec files:

      ```bash
      curl -vk --http1.1 'https://api.kong.lan:8444/default/files' \
      | jq -r -M '.data[] | select(.path|test("^spec")) | .path'
      ```

   b. Delete the retrieved spec files:

      ```bash
      curl -sk --http1.1 'https://api.kong.lan:8444/default/files' \
      | jq -r -M '.data[] | select(.path|test("^spec")) | .path' \
      | xargs -I{} curl -vk --http1.1 -X DELETE 'https://api.kong.lan:8444/default/files/{}'
      ```

2. Uploading New Spec Files

   After ensuring that there are no conflicts with existing files, you can proceed to upload new or updated spec files. To upload a new spec file:

   ```bash
   curl --http1.1 -X POST 'https://api.kong.lan:8444/default/files' \
   -F 'path="specs/first-spec.yaml"' \
   -F 'contents=@"/tmp/first-spec.yaml"'
   ```

3. Updating Existing Spec Files

   If you prefer to update existing spec files rather than deleting and re-uploading, you can use the `PATCH` method to update the content of an existing spec file:

   ```bash
   curl --http1.1 -X PATCH 'https://api.kong.lan:8444/default/files/specs/first-spec.yaml' \
   -F 'path="specs/first-spec.yaml"' \
   -F 'contents=@"/tmp/first-spec.yaml"'
   ```

By following these steps, you can effectively manage the deployment of your specs and content/themes separately in the Kong Developer Portal, ensuring that your spec updates do not result in unique constraint violations.
