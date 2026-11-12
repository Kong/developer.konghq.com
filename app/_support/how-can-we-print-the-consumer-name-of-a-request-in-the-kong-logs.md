---
title: Printing the consumer name of a request in Kong logs
content_type: support
description: How Kong's logging plugins include consumer information by default, and how to filter a `file-log` plugin's output to a limited set of fields.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How can we print the consumer name of a request in the Kong logs?
  a: |
    Kong's logging plugins (for example `file-log`) include consumer information in their output by default, so simply enabling one is usually enough. To limit what else gets logged, use the plugin's `custom_fields_by_lua` config to return `nil` for fields you don't want, such as headers, service, or route.
related_resources: []
---

## Overview

We would like to output the Kong consumer name of a request in the Kong logs. What is the best way of doing this?

## Steps

The Kong log plugins will output the consumer information by default so the easiest way to output the consumer name is to use one of the Kong log plugins. In a Docker or Kubernetes environment, using the `file-log` plugin lets you output the information to `/dev/stdout`, which makes this information available together with other Kong log information that is typically sent there such as access log information.

It is possible to filter out information that is usually logged by default by the Kong log plugins if only a limited set of data is desired to be logged.

For example if you create a `file-log` plugin with the below configuration, headers, service, or route information will not be logged.

```json
{
   "name":"file-log",
   "config":{
      "custom_fields_by_lua":{
         "request.headers":"return nil",
         "response.headers":"return nil",
         "service":"return nil",
         "route":"return nil"
      },
      "path":"/dev/stdout"
   }
}
```
