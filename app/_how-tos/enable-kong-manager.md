---
title: Enable Kong Manager
content_type: how_to
related_resources:
  - text: Kong Manager
    url: /gateway/kong-manager/
  - text: Enable Basic Auth for Kong Manager
    url: /how-to/enable-basic-auth-on-kong-manager/
  - text: Enable OIDC for Kong Manager
    url: /how-to/enable-oidc-for-kong-manager/
  - text: Set up authenticated group mapping in Kong Manager with OIDC
    url: /how-to/oidc-authenticated-group-mapping/
  - text: Configure LDAP with Kong Manager
    url: /how-to/configure-ldap-with-kong-manager/
  - text: Configuring Kong Manager to Send Email
    url: /how-to/configure-kong-manager-email/

products:
    - gateway

works_on:
    - on-prem

min_version:
  gateway: '3.4'

tags:
    - UI

tldr:
    q: How do I enable Kong Manager for {{site.base_gateway}}?
    a: Set the [`KONG_ADMIN_GUI_PATH`](/gateway/configuration/#admin_gui_path) and [`KONG_ADMIN_GUI_URL`](/gateway/configuration/#admin_gui_url) properties in the [`kong.conf`](/gateway/manage-kong-conf/) configuration file to the DNS or IP address of your system, then [restart {{site.base_gateway}}]().

faqs:
    - q: I can't access Kong Manager. How do I fix a Kong Manager URL that doesn’t resolve?
      a: |
        Most likely, the port wasn't exposed during installation. Install a new instance and map port `8002` during installation.
        
        For example, with a [Docker install](/gateway/{{page.release}}/install/docker/?install=oss):

        ```
        -p 127.0.0.1:8002:8002
        ```


cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## 1. Enable Kong Manager

If you're running {{site.base_gateway}} with a database (either in traditional
or hybrid mode), you can enable {{site.base_gateway}}'s graphical user interface
(GUI), Kong Manager.

To enable Kong Manager, set the [`KONG_ADMIN_GUI_PATH`](/gateway/configuration/#admin_gui_path) and [`KONG_ADMIN_GUI_URL`](/gateway/configuration/#admin_gui_url) properties in the ([`kong.conf`](/gateway/configuration/)) configuration file to the DNS or IP address of your system, then restart {{site.base_gateway}} for the setting to take effect:

```bash
docker exec -i kong-quickstart-gateway /bin/sh -c "export KONG_ADMIN_GUI_PATH='/'; export KONG_ADMIN_GUI_URL='http://localhost:8002/manager'; kong reload; exit"
```

If you're enabling Kong Manager in production, you may need to change the following:
* `kong-quickstart-gateway`: The Docker container for {{site.base_gateway}}. The {{site.base_gateway}} quickstart script we used in the prerequisites uses this container by default.
* `KONG_ADMIN_GUI_PATH`: The path to the GUI.
* `KONG_ADMIN_GUI_URL`: The URL of Kong Manager.

## 2. Validate

To verify that Kong Manager is running, access it on port `8002` at the default URL: [`http://localhost:8002/workspaces`](http://localhost:8002/workspaces).

