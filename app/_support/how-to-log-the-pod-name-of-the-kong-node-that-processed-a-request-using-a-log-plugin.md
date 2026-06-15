---
title: How to log the pod name of the Kong node that processed a request when using a Kong log plugin
content_type: support
description: Add the data plane pod name to Kong log plugin output by exposing the container HOSTNAME variable through the config.custom_fields_by_lua property.
products:
  - kic
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I add the data plane pod name to the log produced by a Kong log plugin to identify which Kong pod processed the request?
  a: |
    In a Kubernetes environment, the container exposes a `HOSTNAME` variable set to the pod the
    container runs on. Using the Environment Variables Vault Secret Management Backend, add this
    variable to the log plugin output by adding a new field to the plugin's
    `config.custom_fields_by_lua` property, for example
    `x-pod-name: return kong.vault.get("{vault://env/hostname}")`. This can be set via Kong
    Manager, an Admin API call, or declarative config.
related_resources: []
---

## Overview

This article describes how to add the data plane pod name to the log produced by a Kong log plugin to make it easier to identify a specific Kong pod that processed the request.

## Steps

In a kubernetes environment a container should have a `HOSTNAME` variable which is set to the pod the container is deployed on.

With the Environment Variables Vault Secret Management Backend it is easy to add this `HOSTNAME` variable to the log plugin output by adding a new field to the `config.custom_fields_by_lua` property of your log plugin as in these examples:

A). via Kong Manager:

B). Via an admin API call using the file-log plugin as an example:

```bash
curl -H "kong-admin-token: <adminapitoken>" -X POST <adminapiendpoint>/<workspace>/plugins \
-H 'content-type: application/json' \
-d @payload.json
```

where `payload.json` has the following content:

```json
{
   "name":"file-log",
   "config":{
      "custom_fields_by_lua":{
         "x-pod-name":"return kong.vault.get(\"{vault://env/hostname}\")"
      },
      "path":"/tmp/file.log"
   }
}
```

C). Via declarative config:

```yaml
plugins:
- config:
    custom_fields_by_lua:
      x-pod-name: return kong.vault.get("{vault://env/hostname}")
    path: /tmp/file.log
    reopen: false
  enabled: true
  name: file-log
```
