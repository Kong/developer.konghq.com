---
title: Setting an expiration for key-auth credentials
content_type: support
description: Use the undocumented `ttl` parameter to set an expiration (in seconds) for key-auth credentials created with the Key Authentication plugin.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How can an expiration be set for key-auth credentials?
  a: |
    The Key Authentication plugin supports an undocumented `ttl` parameter (in seconds, up to 100,000,000, approximately 3.16 years) to expire key-auth credentials. Set it when creating or updating the credential through the Admin API, for example `--data-urlencode 'ttl=3600'` for a one-hour key.
---

## Overview

How can an expiration date be set for an API Key created with the Key Authentication plugin?

## Steps

By default, the API Keys created with the Authentication plugin do not expire. However, there is an undocumented parameter, `ttl`, to configure the expiration for the key. The parameter is the number of seconds until expiration.

When creating or updating an existing credential, specify the `ttl` parameter with a value up to 100,000,000 seconds (approximately 3.16 years).

```bash

curl -X POST 'http://<kong-host>:<admin-port>/consumers/<consumer-name>/key-auth' \
--header 'Kong-Admin-Token: <admin-token>' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'key=<api-key>' \
--data-urlencode 'ttl=3600'
```

For example, given the following parameters your request would be as follows:

Host: konghq.com

Admin Port: 8001

Consumer Name: johndoe

Admin Token: kong

API Key: 295c6695-e270-47c2-bb98-684fca793178

TTL: 1 hour / 3600 seconds

```bash

curl -X POST 'http://konghq.com:8001/consumers/johndoe/key-auth' \
--header 'Kong-Admin-Token: kong' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'key=295c6695-e270-47c2-bb98-684fca793178' \
--data-urlencode 'ttl=3600'
```
