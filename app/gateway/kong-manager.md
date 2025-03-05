---
title: "Kong Manager"
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
      
      For example, with a [Docker install](/gateway/{{page.release}}/install/docker/?install=oss):

      ```
      -p 127.0.0.1:8002:8002
      ```

related_resources:
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
---

@todo

Pull content from https://docs.konghq.com/gateway/latest/kong-manager/

If you're running {{site.base_gateway}} with a database (either in traditional
or hybrid mode), you can enable {{site.base_gateway}}'s graphical user interface
(GUI), Kong Manager.

## Enable Kong Manager

To enable Kong Manager, set the [`KONG_ADMIN_GUI_PATH`](/gateway/configuration/#admin_gui_path) and [`KONG_ADMIN_GUI_URL`](/gateway/configuration/#admin_gui_url) properties in the ([`kong.conf`](/gateway/configuration/)) configuration file to the DNS or IP address of your system, then reload {{site.base_gateway}} with `kong reload` for the setting to take effect.

If you're running {{site.base_gateway}} in Docker, you'd use the following:

```bash
docker exec -i $KONG_CONTAINER_ID /bin/sh -c "export KONG_ADMIN_GUI_PATH='/'; export KONG_ADMIN_GUI_URL='http://localhost:8002/manager'; kong reload; exit"
```
This example uses the default Kong Manager path and URL.

If you're enabling Kong Manager in production, you may need to change the following:
* `$KONG_CONTAINER_ID`: The Docker container for {{site.base_gateway}}. The {{site.base_gateway}} quickstart script we used in the prerequisites uses this container by default.
* `KONG_ADMIN_GUI_PATH`: The path to the GUI.
* `KONG_ADMIN_GUI_URL`: The URL of Kong Manager.

{:.info}
> **Note:** If you run the [{{site.base_gateway}} quickstart script](https://get.konghq.com/quickstart), Kong Manager is automatically enabled.

To verify that Kong Manager is running, access it on port `8002` at the default URL: [http://localhost:8002/workspaces](http://localhost:8002/workspaces)

{% if_version gte:3.9.x %}
## Multiple domains 
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

If your setup involves multiple domains or subdomains, it’s generally recommended to remove the `cookie_domain` setting in the [`admin_gui_session_conf`](/gateway/configuration/#admin_gui_session_conf) or [`admin_gui_auth_conf`](/gateway/configuration/#admin_gui_auth_conf).
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
{% endif_version %}