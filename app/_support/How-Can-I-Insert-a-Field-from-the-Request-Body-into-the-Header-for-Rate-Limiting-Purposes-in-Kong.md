---
title: Insert a Field from the Request Body into the Header for Rate Limiting in Kong
content_type: support
description: Use the pre-function plugin with the Kong PDK to extract a field from the request body and insert it into a request header so you can rate limit on that field.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How Can I Insert a Field from the Request Body into the Header for Rate Limiting Purposes in Kong?
related_resources: []
---

## Overview

How Can I Insert a Field from the Request Body into the Header for Rate Limiting Purposes in Kong?

## Steps

To achieve the goal of inserting a field from the request body directly into the header, which is necessary for enabling rate limiting on a specific field in Kong, you can utilize the pre-function plugin in conjunction with the Kong Plugin Development Kit (PDK). This approach allows you to manipulate the request before it reaches the upstream service, enabling you to extract the desired field from the request body and insert it into the request header.

Here is a practical example of how you can accomplish this task:

1. First, ensure that the pre-function plugin is enabled on your Kong instance. You can check the official Kong documentation for guidance on how to enable plugins if you're not familiar with this process.

2. Next, use the following Lua script as a template for your pre-function plugin configuration. This script extracts the "number" field from a JSON object in the request body and adds it as a custom header (`x-contact-number`) to the request.

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

3. Add this Lua script to the `config.access` parameter of the pre-function plugin configuration. This step is crucial as it tells Kong to execute your custom logic during the access phase of the request processing.

4. Once the pre-function plugin is correctly configured with this script, Kong will automatically insert the "number" field from the request body into the request header as `x-contact-number`. You can then set up rate limiting based on this header as per your requirements.

Please note, the provided code snippet is a basic example meant to illustrate the concept. Depending on your specific use case, you might need to extend this script to handle various edge cases, such as requests with multiple contacts or missing fields. Implementing proper error handling and validation logic will ensure that your configuration is robust and can handle unexpected inputs gracefully.

This method provides a flexible way to manipulate request headers based on the content of the request body, enabling more granular control over rate limiting and other policies in Kong.
