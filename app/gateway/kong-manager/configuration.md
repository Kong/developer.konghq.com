---
title: "Kong Manager configuration"
content_type: reference
layout: reference

products:
    - gateway

breadcrumbs:
  - /gateway/
  - /gateway/kong-manager/

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
  - q: How do I configure the session cookies with Kong Manager?
    a: |
      The [Session](/plugins/session/#kong-manager) plugin can be configured through `kong.conf` to manage session cookies.

related_resources:
  - text: Kong Manager
    url: /gateway/kong-manager/
  - text: Enable Basic Auth for Kong Manager
    url: /how-to/enable-basic-auth-on-kong-manager/
  - text: Enable OIDC for Kong Manager
    url: /gateway/kong-manager/openid-connect/
  - text: Set up authenticated group mapping in Kong Manager with OIDC
    url: /gateway/kong-manager/openid-connect/#oidc-authenticated-group-mapping
  # - text: Configure LDAP with Kong Manager
  #   url: /how-to/configure-ldap-with-kong-manager/
tags:
  - kong-manager

works_on:
  - on-prem
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

To verify that Kong Manager is running, access it on port `8002` at the default URL: [http://localhost:8002/workspaces](http://localhost:8002/workspaces).

## Kong Manager networking

By default, Kong Manager starts up without authentication (see
[`admin_gui_auth`](/gateway/configuration/#admin-gui-auth)), and it assumes that the Admin API is available
on [port 8001](/gateway/network/#admin-api-ports) of the same host that serves Kong Manager.

Here are some common configuration scenarios for Kong Manager:

{% table %}
columns:
  - title: Use case
    key: use-case
  - title: Configuration
    key: configuration
rows:
  - use-case: Serving Kong Manager from a dedicated {{site.base_gateway}} node
    configuration: |
      When Kong Manager is on a dedicated {{site.base_gateway}} node, it must make
      external calls to the Admin API. Set [`admin-gui-api-url`](/gateway/configuration/#admin-gui-api-url) to the
      location of your Admin API.
  - use-case: Securing Kong Manager through an authentication plugin
    configuration: |
      When Kong Manager is secured through an authentication plugin
      and is _not_ on a dedicated node, it makes calls to the Admin API on
      the same host. By default, the Admin API listens on ports 8001 and
      8444 on localhost. Change [`admin_listen`](/gateway/configuration/#admin-listen) if necessary, or set
      [`admin-gui-api-url`](/gateway/configuration/#admin-gui-api-url).
      > **Important**: If you need to expose the `admin_listen` port to the internet in a production environment, 
      [secure it with authentication](/gateway/secure-the-admin-api/).
  - use-case: Securing Kong Manager and serving it from a dedicated node
    configuration: |
      When Kong Manager is **secured and served from a dedicated node**,
      set [`admin-gui-api-url`](/gateway/configuration/#admin-gui-api-url) to the location of the Admin API.
{% endtable %}                                             

## Enable authentication

To enable authentication for Kong Manager, configure the following properties (`admin_gui_auth_conf` is optional and `enforce_rbac` must be set to `on`):

<!--vale off-->
{% kong_config_table %}
config:
  - name: admin_gui_auth
  - name: admin_gui_auth_conf
  - name: admin_gui_session_conf
  - name: enforce_rbac
{% endkong_config_table %}
<!--vale on-->

{:.warning}
> **Important:** When Kong Manager authentication is enabled, [RBAC](/gateway/entities/rbac/) must be enabled to enforce authorization rules. Otherwise, anyone who can log in
to Kong Manager can perform any operation available on the Admin API.

### TLS certificates

By default, if Kong Manager’s URL is accessed over HTTPS _without_ a certificate issued by a CA, it will
receive a self-signed certificate that modern web browsers will not trust. This prevents the application
from accessing the Admin API.

To serve Kong Manager over HTTPS, use a trusted certificate authority to issue TLS certificates
and have the resulting `.crt` and `.key` files ready for the next step.

1. Move `.crt` and `.key` files into the desired directory of the {{site.base_gateway}} node.

1. Point [`admin_gui_ssl_cert`](/gateway/configuration/#admin-gui-ssl-cert) and [`admin_gui_ssl_cert_key`](/gateway/configuration/#admin-gui-ssl-cert-key) at the absolute paths of the certificate and key.
   ```
   admin_gui_ssl_cert = ./test.crt
   admin_gui_ssl_cert_key = ./test.key
   ```
1. Ensure that `admin_gui_url` is prefixed with `https` to use TLS. For example:
   ```
   admin_gui_url = https://YOUR-DOMAIN.com:8445
   ```

### Using https://localhost

If you're serving Kong Manager on `localhost`, you might want to use HTTP as the protocol. If you're also using RBAC,
set `cookie_secure=false` in [`admin_gui_session_conf`](/gateway/configuration/#admin-gui-session-conf). Creating TLS certificates for `localhost` requires more effort and configuration, so you should only use TLS when:

* Data is in transit between hosts
* You're testing an application with [mixed content](https://developer.mozilla.org/en-US/docs/Web/Security/Mixed_content) (which Kong Manager doesn't use)

External CAs cannot provide a certificate since no one uniquely owns `localhost`, nor is it rooted in a top-level
domain (for example, `.com`, `.org`). Likewise, self-signed certificates won't be trusted in modern browsers. Instead, you must use a private CA that allows you to issue your own certificates. Also, ensure that the SSL state
is cleared from the browser after testing to prevent stale certificates from interfering with future access to
`localhost`.

## Multiple domains {% new_in 3.9 %}
To configure Kong Manager to be accessible from multiple domains, you can list the domains as comma-separated values in the [`admin_gui_url`](/gateway/configuration/#admin-gui-url) parameter in your Kong configuration. For example:
```
admin_gui_url = http://localhost:8002, http://127.0.0.1:8002
```

If the [`admin_gui_path`](/gateway/configuration/#admin-gui-path) is also set, update the Kong configuration:
```
admin_gui_url = http://localhost:8002/manager, http://127.0.0.1:8002/manager
admin_gui_path = /manager
```
Make sure that each domain has proper DNS records and that the {{site.base_gateway}} instance is accessible from all specified domains.

If your setup involves multiple domains or subdomains, we recommend removing the `cookie_domain` setting in the [`admin_gui_session_conf`](/gateway/configuration/#admin-gui-session-conf) or [`admin_gui_auth_conf`](/gateway/configuration/#admin-gui-auth-conf).
When `cookie_domain` is not specified, cookies are set for the domain initiated in the request if [`admin_gui_api_url`](/gateway/configuration/#admin-gui-api-url) is not specified. This allows the browser to manage cookies correctly for each domain independently, avoiding conflicts or scope issues. 

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

## Session management

The Session configuration is secure by default, which may require alteration if using HTTP or different domains for the Admin API and Kong Manager. The encrypted session data may be stored either in {{site.base_gateway}} or the cookie itself. For more information on the Session plugin, review the [plugin documentation](/plugins/session/).

## Configure Kong Manager to send email

The following workflows in Kong Manager use email to communicate with the user:
* A super admin inviting other [admins](/gateway/entities/admin/) to register in Kong Manager
* An admin or user resetting their password using the "Forgot Password" link on the Kong Manager login page

To configure emails for Kong Manager, set up SMTP using the [general SMTP configuration settings](/gateway/configuration/#general-smtp-configuration-section).
You can then adjust the following parameters in `kong.conf` to customize your emails:

<!--vale off-->
{% kong_config_table %}
config:
  - name: admin_emails_from
  - name: admin_emails_reply_to
  - name: admin_invitation_expiry
{% endkong_config_table %}
<!--vale on-->

If running {{site.base_gateway}} in hybrid mode, the admin SMTP settings must be applied on the Control Plane.

{:.warning}
> {{site.base_gateway}} doesn't check the validity of email addresses set in the configuration. 
If the SMTP settings are configured incorrectly (for example, pointing to a non-existent email address), Kong Manager will _not_ display an error message.

