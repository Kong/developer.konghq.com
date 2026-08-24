---
title: Resetting the Admin API RBAC token programmatically
content_type: support
description: Reset the Admin API RBAC token programmatically by authenticating to get a Kong Manager session cookie and using it to call the `/admins/self/token` endpoint.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How can the Admin API RBAC token be reset programmatically?
  a: |
    Authenticate against `/auth` with the Kong Manager admin credentials to obtain a session cookie, then use that cookie to call `PATCH /admins/self/token`, which generates and returns a new RBAC token.
    The token value is always auto-generated and cannot be set to a specific value.
related_resources: []
---

## Overview

Kong Manager can be used to reset the RBAC token, but how can this be done programmatically via a curl to the Admin API?

## Steps

The RBAC tokens are not documented as part of the Admin API as it requires a Kong Manager session cookie as authentication to reset it. It is possible to authenticate and obtain the session cookie and authenticate the token reset using the below example.

Be advised that this will store the session cookie locally and is provided simply to demonstrate how this is possible.

```bash
curl 'https://admin-api.konghq.com:<port>/auth' \
-H 'Kong-Admin-User: kong_admin' \
-H 'Authorization: Basic a29uZ19hZG1pbjprb25n' -ik -c session.txt

curl -X PATCH 'https://admin-api.konghq.com:<port>/admins/self/token' \
-H 'Kong-Admin-User: kong_admin' \
-b session.txt -ik
```

The new RBAC token is automatically generated and cannot be set to a specific value. Below is an example request and response when generating a new token;

```bash
curl -k -X PATCH 'https://admin-api.konghq.com:<port>/admins/self/token' \
-H 'Kong-Admin-User: kong_admin' -b session.txt
{"message":"Token reset successfully","token":"SY8YYcwKhkve7FJRrhchjbS0yVP16spc"}
```

You could store the new token in an env variable for use with a subsequent command like this;

```bash
export RBAC_TOKEN=$(curl -sk -X PATCH 'https://admin-api.konghq.com:<port>/admins/self/token' -H 'Kong-Admin-User: kong_admin' -b session.txt | jq -r '.token')

echo $RBAC_TOKEN
TLqCCXDPlWEre6MPm4vC1WuE4LccMewL
```
