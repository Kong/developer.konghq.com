---
title: Creating a consumer credential with the Admin API
content_type: support
description: How to create basic-auth and key-auth consumer credentials directly through the Kong Admin API instead of Kong Manager.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How can a consumer credential be created with the Admin API?
  a: |
    Call the Admin API endpoint for the credential type you need instead of using Kong Manager — for example, `POST /consumers/{consumer}/basic-auth` for Basic Auth credentials or `POST /consumers/{consumer}/key-auth` for key-auth credentials.
---

## Overview

From within Kong Manager, it is possible to create consumer credentials. Is it possible for consumer credentials to be created directly via an Admin API call?

## Steps

To create credentials, you need to call the appropriate endpoint for the required credential type. Some examples are shown below;

1. To create basic-auth Consumer credentials via an Admin API call, use a request similar to below;

   ```bash

   curl -s -X POST 'https://api.kong.lan:8444/{{workspace}}/consumers/{{consumer-name}}/basic-auth' \
   -H 'Content-Type: application/json;charset=UTF-8' \
   --data-raw '{"username":"my-username",
   "password":"my-password"}'
   ```

2. To create key-auth Consumer credentials via an Admin API call, use a request similar to below;

   ```bash

   curl -s -X POST 'https://api.kong.lan:8444/{{workspace}}/consumers/{{consumer-name}}/key-auth' \
   -H 'Content-Type: application/json;charset=UTF-8' \
   --data-raw '{"key":"new-key"}'
   ```
