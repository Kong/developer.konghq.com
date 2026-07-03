---
title: "How can I insert a field from the request body into the header for rate limiting?"
content_type: support
description: Use the Pre-Function plugin with the {{site.base_gateway}} PDK to extract a field from the request body and insert it into a request header so you can rate limit on that field.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How can I insert a field from the request body into the header for rate limiting purposes?
  a: |
    Use the Pre-Function plugin to extract a field from the request body with `kong.request.get_body()` and insert it as a header with `kong.service.request.add_header()`.
    You can then configure rate limiting based on that header.
related_resources:
  - text: Pre-Function plugin
    url: /plugins/pre-function/
  - text: Plugin developement kit (PDK)
    url: /gateway/pdk/reference/
---

To insert a field from the request body directly into the header so you can rate limit on a specific field in {{site.base_gateway}}, use the [Pre-Function](/plugins/pre-function/) plugin together with the [Kong Plugin Development Kit (PDK)](/gateway/pdk/reference/). 
This approach lets you manipulate the request before it reaches the upstream service, so you can extract the desired field from the request body and insert it into the request header.

Here is a practical example of how you can accomplish this task:

1. Use the following Lua script as a template for your Pre-Function plugin configuration. This script extracts the `number` field from a JSON object in the request body and adds it as a custom header (`x-contact-number`) to the request:

   ```lua
   -- Example request body
   -- {"contacts": [{"phoneNumber": {"number": "123456789"}}]}

   local rl_header_name = kong.request.get_body()
   if (rl_header_name.contacts and #rl_header_name.contacts == 1) then
     if (rl_header_name.contacts[1].phoneNumber and 
       rl_header_name.contacts[1].phoneNumber.number) then
       kong.service.request.add_header("x-contact-number", 
       rl_header_name.contacts[1].phoneNumber.number)
     end
   end
   ```

1. Add this Lua script to the `config.access` parameter of the Pre-Function plugin configuration. This step is crucial, as it tells {{site.base_gateway}} to execute your custom logic during the access phase of the request processing.

1. Apply the plugin configuration to your required scope. See the [Pre-Function plugin config examples](/plugins/pre-function/examples/) for guidance.

1. Once the Pre-Function plugin is correctly configured with this script, {{site.base_gateway }} will automatically insert the `number` field from the request body into the request header as `x-contact-number`. You can then set up rate limiting based on this header as per your requirements.

This method provides a flexible way to manipulate request headers based on the content of the request body, enabling more granular control over rate limiting and other policies in {{site.base_gateway}}.
