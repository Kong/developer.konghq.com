---
title: How to update Kong configuration that is hard coded in `/usr/local/share/lua/5.1/kong/templates/nginx_kong.lua` when using Helm charts
content_type: support
description: Use the Helm chart's `userDefinedVolumes` and `userDefinedVolumeMounts` to mount a custom `nginx_kong.lua` template, overriding hard-coded Nginx configuration options that Kong's default template doesn't expose.
products:
  - kic
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I override Nginx configuration hard-coded in `/usr/local/share/lua/5.1/kong/templates/nginx_kong.lua` when using the Kong Helm chart?
  a: |
    Mount a custom `nginx_kong.lua` file using the Helm chart's `userDefinedVolumes` and
    `userDefinedVolumeMounts` settings under `deployment` in `values.yaml`, backed by a `configMap`
    created from your edited template. Re-check the template against Kong's default after any
    upgrade, since it can change between versions.
---

## Overview

There is one or more nginx configuration options which are hard coded in the `/usr/local/share/lua/5.1/kong/templates/nginx_kong.lua` file that propagate to `nginx-kong.conf` in the kong `<prefix>` directory, and determine the nginx configuration, and we need to override those values. Using a custom nginx template would be a way to address this, but with the Kong Helm charts this does not seem to be straight forward. What is a good way to override the `/usr/local/share/lua/5.1/kong/templates/nginx_kong.lua` file when using Kong Helm charts?

## Steps

As documented with the Kong Helm charts you can add configMap to a custom volume with a custom mount point using the `userDefinedVolumes`, and `userDefinedVolumeMounts` elements under the deployment property of your `values.yaml` file.

To replace `/usr/local/share/lua/5.1/kong/templates/nginx_kong.lua` you would need to:

1. Create a configMap using something like the following command:

   ```bash
   kubectl -n <yournamespace> create configmap nginx-kong-lua --from-file=nginx_kong.lua
   ```

2. Change the `values.yaml` to use that configMap as in this configuration:

   ```yaml
   deployment:
     kong:
       enabled: true
       daemonset: false
     userDefinedVolumes:
     - name: "nginx-kong-lua"
       configMap:
         name: nginx-kong-lua
     userDefinedVolumeMounts:
     - name: "nginx-kong-lua"
       mountPath: "/usr/local/share/lua/5.1/kong/templates/nginx_kong.lua"
       subPath: "nginx_kong.lua"

   image:
     repository: kong/kong-gateway
   ...
   ```

WARNING: Before upgrading Kong (even to a new minor version), you MUST make sure that the `/usr/local/share/lua/5.1/kong/templates/nginx_kong.lua` has not changed or if it has, use the new version with the required changes on your side.
