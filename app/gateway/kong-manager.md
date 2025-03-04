---
title: "Kong Manager"
content_type: reference
layout: reference

products:
    - gateway

min_version:
  gateway: '3.4'

description: Kong Manager is the graphical user interface (GUI) for {{site.base_gateway}}.

related_resources:
  - text: Enable Kong Manager
    url: /how-to/enable-kong-manager/
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