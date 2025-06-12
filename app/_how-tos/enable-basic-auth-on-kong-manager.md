---
title: Enable Basic Auth for Kong Manager
content_type: how_to
related_resources:
  - text: Authentication
    url: /gateway/authentication/
  - text: About Kong Manager
    url: /gateway/kong-manager/
  - text: Kong Manager configuration reference
    url: /gateway/kong-manager/configuration/
description: Learn how to enable basic authentication and RBAC for Kong Manager.

products:
    - gateway

plugins:
  - basic-auth

works_on:
    - on-prem

min_version:
  gateway: '3.4'

tags:
    - authentication
    - kong-manager

tldr:
    q: How do I enable basic authentication for Kong Manager?
    a: Set `enforce-rbac = on`, `admin_gui_auth = basic-auth`, and `admin_gui_session_conf = { "secret":"kong" }` in your Kong configuration file or as environment variables. Then, log in to Kong Manager with `kong_admin` as your username and `kong` as your password.

tools: []

entities: []

prereqs:
  skip_product: true

cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

faqs:
  - q: If I created a super admin via the Kong Manager Teams tab, how do they log in using basic auth?
    a: They should log in with the credentials they created after accepting the email invitation.
---

## Set environment variables

Set the {{site.base_gateway}} license as a variable:
```sh
export KONG_LICENSE_DATA='LICENSE-CONTENTS-GO-HERE'
```

## Start {{site.base_gateway}}

Create the {{site.base_gateway}} container and enable RBAC and basic auth. In this example, we can use the quickstart:
```bash
curl -Ls get.konghq.com/quickstart | bash -s -- -e "KONG_LICENSE_DATA" \
    -e "KONG_ENFORCE_RBAC=on" \
    -e "KONG_ADMIN_GUI_AUTH=basic-auth" \
    -e "KONG_PASSWORD=kong" \
    -e 'KONG_ADMIN_GUI_SESSION_CONF={"secret":"kong"}'
```

This enables RBAC, sets `basic-auth` as the authentication method, and creates a session secret.

Kong Manager uses the [Session](/plugins/session/) plugin in the background.
This plugin (configured with `admin_gui_session_conf`) requires a secret and is configured securely by default. Under all circumstances, the `secret` must be manually set to a string.

For more information about the values, see the [RBAC](/gateway/entities/rbac/) reference.

## Validate

To validate that basic authentication was configured correctly for Kong Manager, navigate to the Kong Manager GUI at [http://localhost:8002](http://localhost:8002) and use the username (`kong_admin`) and the password (`kong`) you set when you created the {{site.base_gateway}} container.

{:.warning}
> To log in to Kong Manage with basic auth, you must have [super admin permissions](/how-to/create-a-super-admin/) or a user that has `/admins` and `/rbac` read and write access.

