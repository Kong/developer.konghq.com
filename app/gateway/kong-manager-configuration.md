---
title: "Kong Manager Configuration"
content_type: reference
layout: reference

products:
    - gateway

min_version:
  gateway: '3.4'

description: Kong Manager is the graphical user interface (GUI) for {{site.base_gateway}}.

faqs:
  - q: I can't access Kong Manager. How do I fix a Kong Manager URL that doesn’t resolve?
    a: |
      Most likely, the port wasn't exposed during installation. Install a new instance and map port `8002` during installation.
      
      For example, with a Docker install:

      ```
      -p 127.0.0.1:8002:8002
      ```

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
tags:
  - kong-manager
---


If you're running {{site.base_gateway}} on-prem with a database (either in traditional
or hybrid mode), you can enable {{site.base_gateway}}'s graphical user interface
(GUI), Kong Manager.

## Enable Kong Manager

To enable Kong Manager, set the following [Kong Manager parameters in `kong.conf`](/gateway/configuration/#kong-manager-section), then restart {{site.base_gateway}}:
<!--vale off-->
{% kong_config_table %}
config:
  - name: admin_gui_path
  - name: admin_gui_url
{% endkong_config_table %}
<!--vale on-->

If you're running {{site.base_gateway}} in Docker, you can use the following example, making sure to replace the `KONG_CONTAINER_ID` with your own container:

```bash
docker exec -i $KONG_CONTAINER_ID /bin/sh -c \
"export KONG_ADMIN_GUI_PATH='/'; \
export KONG_ADMIN_GUI_URL='http://localhost:8002/manager'; \
kong reload; \
exit"
```
This example uses the default Kong Manager path and URL.


{:.info}
> **Note:** If you run the [{{site.base_gateway}} quickstart script](https://get.konghq.com/quickstart), Kong Manager is automatically enabled.

To verify that Kong Manager is running, access it on port `8002` at the default URL: [http://localhost:8002/workspaces](http://localhost:8002/workspaces)


## Multiple domains {% new_in 3.9 %}
To configure Kong Manager to be accessible from multiple domains, you can list the domains as comma-separated values in the [`admin_gui_url`](/gateway/configuration/#admin_gui_url) parameter in your Kong configuration. For example:
```
admin_gui_url = http://localhost:8002, http://127.0.0.1:8002
```

If the [`admin_gui_path`](/gateway/configuration/#admin_gui_path) is also set, update the Kong configuration:
```
admin_gui_url = http://localhost:8002/manager, http://127.0.0.1:8002/manager
admin_gui_path = /manager
```
Make sure that each domain has proper DNS records and that the {{site.base_gateway}} instance is accessible from all specified domains.

If your setup involves multiple domains or subdomains, we recommend removing the `cookie_domain` setting in the [`admin_gui_session_conf`](/gateway/configuration/#admin_gui_session_conf) or [`admin_gui_auth_conf`](/gateway/configuration/#admin_gui_auth_conf).
When `cookie_domain` is not specified, cookies are set for the domain initiated in the request if [`admin_gui_api_url`](/gateway/configuration/#admin_gui_api_url) is not specified. This allows the browser to manage cookies correctly for each domain independently, avoiding conflicts or scope issues. 

For example, a request to `gui.konghq.com` and `other-gui.example.com` will produce cookies for `gui.konghq.com` and `other-gui.example.com` respectively, instead of the root-level `konghq.com` domain when `cookie_domain` isn't specified:

```
admin_gui_url = http://gui.konghq.com, http://other-gui.example.com
admin_gui_session_conf = {"secret":"Y29vbGJlYW5z","storage":"kong","cookie_secure":false} # omitted `cookie_domain`
```
{:.no-copy-code}

Or, both requests to `gui.konghq.com` and `other-gui.konghq.com` will receive cookies for `konghq.com`, which makes the cookie shared across all subdomains besides `konghq.com` itself. This increases the cookie's scope, which may lead to unintended side effects or security risks: 
```
admin_gui_url = http://gui.konghq.com, http://other-gui.konghq.com
admin_gui_session_conf = {"secret":"Y29vbGJlYW5z","storage":"kong","cookie_secure":false,"cookie_domain":"konghq.com"}
```
{:.no-copy-code}

## Customize Kong Manager

You can customize various visual aspects of Kong Manager, like header and footer text and colors. Use the following [`kong.conf` parameters to customize Kong Manager](/gateway/configuration/#kong-manager-section):

<!--vale off-->
{% kong_config_table %}
config:
  - name: admin_gui_header_txt
  - name: admin_gui_header_bg_color
  - name: admin_gui_header_txt_color
  - name: admin_gui_footer_txt
  - name: admin_gui_footer_bg_color
  - name: admin_gui_footer_txt_color
  - name: admin_gui_login_banner_title
  - name: admin_gui_login_banner_body
{% endkong_config_table %}
<!--vale on-->