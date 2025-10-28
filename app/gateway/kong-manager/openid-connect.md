---
title: Kong Manager with OpenID Connect

description: Bind authentication for Kong Manager admins to an organization’s OpenID Connect identity provider, and set up authenticated group mapping.
content_type: reference
layout: reference
products:
   - gateway
   
min_version:
  gateway: '3.6'

breadcrumbs:
  - /gateway/
  - /gateway/kong-manager/

works_on:
  - on-prem

tags:
  - kong-manager
  - security
  - openid-connect

search_aliases:
  - group mapping
  - oidc

related_resources:
  - text: Kong Manager
    url: /gateway/kong-manager/
  - text: OpenID Connect plugin reference
    url: /plugins/openid-connect/reference/
---

{{site.base_gateway}} provides the ability to bind authentication for Kong Manager admins to an organization’s OpenID Connect identity provider.
Set up your identity provider, then configure {{site.base_gateway}} using the Kong configuration file or as environment variables.

OpenID Connect authentication for Kong Manager is enabled and configured entirely through `kong.conf`, and uses the [OpenID Connect plugin](/plugins/openid-connect/) in the background.
You **do not** need to manually enable the OpenID Connect plugin.

## Supported configuration options

{{site.base_gateway}} uses the config parameter [`admin_gui_auth_conf`](/gateway/configuration/#admin-gui-auth-conf) to configure the OIDC plugin.
To customize examples in this guide, refer to the [OpenID Connect plugin documentation](/plugins/openid-connect/reference/) and modify the configuration according to your requirements.

The following parameters can't be customized. They are controlled internally, and any values provided for them will be ignored:

- `auth_methods`
- `login_action`
- `login_methods`
- `login_tokens`
- `logout_methods`
- `logout_query_arg`
- `logout_revoke_access_token`
- `logout_revoke_refresh_token`
- `logout_revoke`
- `refresh_tokens`
- `upstream_access_token_header`
- `upstream_id_token_header`
- `upstream_user_info_header` (while `search_user_info` is `true`)

{:.warning}
> Important: In v3.6.x, many of the parameters under `admin_gui_auth_conf` changed their behavior. 
If you had a previous group mapping configuration and upgraded to 3.6 or later, [review the changes](#migrate-oidc-configuration-from-older-versions) and adjust your configuration accordingly.

## Enable OpenID Connect for Kong Manager

The following examples show you how to enable OIDC auth for Kong Manager.

While authenticating Kong Manager with OpenID Connect, make sure that your IdP supports the
`authorization_code` grant type and is enabled for the associated client.

Review [supported configuration options](#supported-configuration-options) to customize the configuration stored in `admin_gui_auth_conf`.

{% navtabs "enable-oidc" %}
{% navtab "Docker quickstart" %}

Set the {{site.base_gateway}} license as a variable:
```sh
export KONG_LICENSE_DATA='LICENSE-CONTENTS-GO-HERE'
```

Create the {{site.base_gateway}} container and enable RBAC with OpenID Connect auth. In this example, we can use the quickstart.
Replace any values with your own as needed. At minimum, replace the `issuer`, `client_id`, and `client_secret` with the literal values from your IdP:

```bash
curl -Ls get.konghq.com/quickstart | bash -s -- \
  -e "KONG_LICENSE_DATA" \
  -e "KONG_ENFORCE_RBAC=on" \
  -e "KONG_PASSWORD=kong" \
  -e "KONG_ADMIN_GUI_AUTH=openid-connect" \
  -e 'KONG_ADMIN_GUI_AUTH_CONF={ "issuer": "ISSUER_URL", "client_id": ["YOUR_CLIENT_ID"], "client_secret": ["YOUR_CLIENT_SECRET"],"authenticated_groups_claim": ["groups"], "redirect_uri": ["http://localhost:8001/auth"], "login_redirect_uri": ["http://localhost:8002"], "logout_redirect_uri": ["http://localhost:8002"], "scopes": ["openid","profile","email","offline_access"], "authorization_endpoint": "http://localhost:8080" }'
```

This enables RBAC, sets `openid-connect` as the authentication method, and configures your identity provider.
For more information about the values, see the [RBAC](/gateway/entities/rbac/) reference.

{% endnavtab %}
{% navtab "Kong configuration file" %}

Enable RBAC and OpenID Connect for Kong Manager by updating your `kong.conf` file with the following configuration.
Replace any values with your own as needed. At minimum, replace the `issuer`, `client_id`, and `client_secret` with the literal values from your IdP:

```
enforce_rbac = on
admin_gui_auth=openid-connect
admin_gui_auth_conf={
  "issuer": "YOUR_ISSUER_URL",
  "client_id": ["YOUR_CLIENT_ID"],
  "client_secret": ["YOUR_CLIENT_SECRET"],
  "redirect_uri": ["http://localhost:8001/auth"],
  "scopes": ["openid","email","offline_access"], 
  "login_redirect_uri": ["http://localhost:8002"],
  "logout_redirect_uri": ["http://localhost:8002"],
  "admin_claim": "email",
  "authenticated_groups_claim": ["groups"]
}
```

This enables RBAC, sets `openid-connect` as the authentication method, and configures your identity provider.
For more information about the values, see the [RBAC](/gateway/entities/rbac/) reference.

Once this is done, restart the {{site.base_gateway}} container to apply the change:
```sh
docker restart kong-quickstart-gateway
```
Or if not running in Docker:
```
kong restart
```

{% endnavtab %}
{% endnavtabs %}

Next, to start using OIDC auth, either [invite admins manually](/gateway/entities/admin/) or set up [authenticated group mapping](#oidc-authenticated-group-mapping).

When authenticating Kong Manager with OpenID Connect, the session mechanism inside
the plugin is used to persist the authorization state. 
Refer to the documentation for parameters prefixed by [`config.session_*](/plugins/openid-connect/reference/#schema--config-session-absolute-timeout)` to learn more.

### Recommendations to enhance session security

For enhanced security, we recommend setting a few session parameters:
* `session_secret`: A randomly generated secret will be used if unspecified.
* `session_cookie_secure`: Defaults to `false`. We recommend setting this value to `true` when using HTTPS.
* `session_cookie_same_site`: Consider upgrading this value to `Strict` when using the same domain for the Admin API and Kong Manager.

<!-- 
Learn more about these concepts in [Session Security in Kong Manager](/gateway/{{page.release}}/kong-manager/auth/sessions/#session-security). -->

## OIDC authenticated group mapping

Using Kong’s [OpenID Connect plugin](/plugins/openid-connect/) (OIDC), you can map identity provider (IdP) groups to Kong roles. 

With IdP group mapping, admin accounts are created automatically. Adding a user to Kong in this way gives them access to Kong Manager based on their group in the IdP.
The mapping removes the task of manually managing access in {{site.base_gateway}}, because it makes the IdP the system of record.

Roles assigned to admins are also managed by the IdP. 
If an admin’s group changes in the IdP, their Kong admin account’s associated role also changes in {{site.base_gateway}} the next time they log in to Kong Manager. 
Don't assign or unassign admin roles in {{site.base_gateway}} manually, as any changes will be overwritten by the IdP during the next login.

{:.warning}
> Important: In v3.6.x, many of the parameters under `admin_gui_auth_conf` changed their behavior. 
If you had a previous group mapping configuration and upgraded to 3.6 or later, [review the changes](#migrate-oidc-configuration-from-older-versions) and adjust your configuration accordingly.

### Review important values

In the following examples, you specify the `admin_claim` and `authenticated_groups_claim` parameters
to identify which admin value and role name to map from the IdP to {{site.base_gateway}}, as well as
the `admin_auto_create_rbac_token_disabled` to specify whether an RBAC token is created for admins in Kong.

{% table %}
columns:
  - title: Parameter
    key: param
  - title: Description
    key: description
rows:
  - param: "`admin_claim`"
    description: |
      This value specifies which IdP username value should map to Kong Manager. 
      The username and password are required for the user to log into the IdP.
  - param: "`authenticated_groups_claim`"
    description: |
      This value specifies which IdP claim should be used to assign {{site.base_gateway}} roles to the
      specified {{site.base_gateway}} admin. The value depends on your IdP: for example, Okta configures claims for `groups`, and another IdP might configure them as `roles`.
      <br><br>
      In the IdP, the group claim value must follow the format `WORKSPACE_NAME:ROLE_NAME`.
      <br><br>
      For example, if `"authenticated_groups_claim": ["groups"]` is specified, and in the IdP `groups:["default:super-admin"]` is specified, the administrators specified in `admin_claim` are assigned to the `super-admin` role in the default {{site.base_gateway}} workspace.
      <br><br>
      If the mapping doesn't work as expected, decode the JWT that's created by your IdP, and make sure that the admin ID token includes the key:value pair 
      `groups:["default:super-admin"]` for the case of this example, or the appropriate claim name and claim value as set in your IdP.

  - param: "`admin_auto_create_rbac_token_disabled`"
    description: |
      This is a boolean value that enables or disables RBAC token creation when automatically creating admins with OpenID Connect. 
      The default is `false`.
      <br><br>
      * Set to `true` to disable automatic token creation for admins
      * Set to `false` to enable automatic token creation for admins

  - param: "`admin_auto_create`"
    description: |
      This is a value boolean value that enables or disables admin auto-creation with OpenID Connect. The default is `true`.
      <br><br>
      * Set to `true` to enable automatic admin creation
      * Set to `false` to disable automatic admin creation
{% endtable %}

### Set up authenticated group mapping

The following examples show you how to set up OpenID Connect authenticated group mapping for Kong Manager.

Review [supported configuration options](#supported-configuration-options) to customize the configuration stored in `admin_gui_auth_conf`.

{% navtabs "enable-oidc-mapping" %}
{% navtab "Kubernetes with Helm" %}
1. Create a configuration file for the OIDC plugin and save it as
`admin_gui_auth_conf`. Adjust your own values as needed:

    ```json
    {                                      
        "issuer": "ISSUER_URL",        
        "admin_claim": "email",
        "client_id": ["CLIENT_ID"],                 
        "client_secret": ["CLIENT_SECRET"],
        "authenticated_groups_claim": ["CLAIM_NAME"],
        "ssl_verify": false,
        "leeway": 60,
        "redirect_uri": ["YOUR_REDIRECT_URI"],
        "login_redirect_uri": ["YOUR_LOGIN_REDIRECT_URI"],
        "logout_redirect_uri": ["YOUR_LOGOUT_REDIRECT_URI"],
        "scopes": ["openid","profile","email","offline_access"],
        "admin_auto_create_rbac_token_disabled": false,
        "admin_auto_create": true
    }
    ```
    Review the [supported configuration options](#supported-configuration-options) to customize any configuration.

2. Create a secret from the file you just created:

    ```sh
    kubectl create secret generic kong-idp-conf --from-file=admin_gui_auth_conf -n kong
    ```

3. Update the RBAC section of the deployment `values.yml` file with the
following parameters:

    ```yaml
    rbac:
      enabled: true
      admin_gui_auth: openid-connect
      admin_gui_auth_conf_secret: kong-idp-conf
    ```

4. Using Helm, upgrade the deployment with your YAML filename:

    ```sh
    helm upgrade --install kong-ee kong/kong -f ./myvalues.yaml -n kong
    ```
{% endnavtab %}
{% navtab "Docker" %}

Run the following command to set the needed
environment variables and reload the {{site.base_gateway}} configuration.

Replace any values with your own as needed. At minimum, replace the `issuer`, `client_id`, and `client_secret` with the literal values from your IdP:

```sh
echo "
  KONG_ENFORCE_RBAC=on \
  KONG_ADMIN_GUI_AUTH=openid-connect \
  KONG_ADMIN_GUI_AUTH_CONF='{
      \"issuer\": \"ISSUER_URL\",
      \"admin_claim\": \"email\",
      \"client_id\": [\"CLIENT_ID\"],
      \"client_secret\": [\"CLIENT_SECRET\"],
      \"authenticated_groups_claim\": [\"CLAIM_NAME\"],
      \"ssl_verify\": false,
      \"leeway\": 60,
      \"redirect_uri\": [\"YOUR_REDIRECT_URI\"],
      \"login_redirect_uri\": [\"YOUR_LOGIN_REDIRECT_URI\"],
      \"logout_redirect_uri\": [\"YOUR_LOGOUT_REDIRECT_URI\"],
      \"scopes\": [\"openid\",\"profile\",\"email\",\"offline_access\"],
      \"admin_auto_create_rbac_token_disabled\": false,
      \"admin_auto_create\": true
    }' kong reload exit" | docker exec -i KONG_CONTAINER_ID /bin/sh
```
Review the [supported configuration options](#supported-configuration-options) to customize any configuration.

Restart Kong:

```sh
docker restart kong-quickstart-gateway
```

{% endnavtab %}
{% navtab "Kong configuration file" %}

1. Navigate to your `kong.conf` file.

2. With RBAC enabled, add the `admin_gui_auth` and `admin_gui_auth_conf`
properties to the file.

    Replace any values with your own as needed. 
    At minimum, replace the `issuer`, `client_id`, and `client_secret` with the literal values from your IdP:

    ```
    enforce_rbac = on
    admin_gui_auth = openid-connect
    admin_gui_auth_conf = {                                      
        "issuer": "ISSUER_URL",        
        "admin_claim": "email",
        "client_id": ["CLIENT_ID"],                 
        "client_secret": ["CLIENT_SECRET"],
        "authenticated_groups_claim": ["CLAIM_NAME"],
        "ssl_verify": false,
        "leeway": 60,
        "redirect_uri": ["YOUR_REDIRECT_URI"],
        "login_redirect_uri": ["YOUR_LOGIN_REDIRECT_URI"],
        "logout_redirect_uri": ["YOUR_LOGOUT_REDIRECT_URI"],
        "scopes": ["openid","profile","email","offline_access"],
        "admin_auto_create_rbac_token_disabled": false,
        "admin_auto_create": true
    }
    ```
   Review the [supported configuration options](#supported-configuration-options) to customize any configuration.

3. Restart {{site.base_gateway}} to apply the file.

    ```sh
    kong restart -c /path/to/kong.conf
    ```

{% endnavtab %}
{% endnavtabs %}

## Migrate OIDC configuration from older versions {% new_in 3.6 %}

As of Gateway v3.6, Kong Manager uses the session management mechanism in the OpenID Connect plugin.
`admin_gui_session_conf` is no longer required when authenticating with OIDC. Instead, session-related
configuration parameters are set in `admin_gui_auth_conf` (like `session_secret`).

We recommend reviewing your configuration, as some session-related parameters in `admin_gui_auth_conf`
have different default values compared to the ones in `admin_gui_session_conf`.

<!-- vale off -->
### admin_gui_auth_conf
<!-- vale on -->

See the following summary of changes to attributes of `admin_gui_auth_conf`, and follow the individual links for further information:

<!--vale off-->
{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Old behavior
    key: old
  - title: New behavior
    key: new
rows:
  - parameter: "[`scopes`](#scopes)"
    old: 'Old default: `["openid", "profile", "email"]`'
    new: 'New default: `["openid", "email", "offline_access"]`'
  - parameter: "[`admin_claim`](#admin-claim)"
    old: "Required"
    new: 'Optional (Default: `"email"`)'
  - parameter: "[`authenticated_groups_claim`](#authenticated-groups-claim)"
    old: "Required"
    new: 'Optional (Default: `["groups"]`)'
  - parameter: "[`redirect_uri`](#redirect-uri)"
    old: "Takes an array of URLs pointing to Kong Manager"
    new: "Takes an array of URLs pointing to the Admin API's `/auth` endpoint"
  - parameter: "[`login_redirect_uri`](#login-redirect-uri)"
    old: "Optional"
    new: "Required"
  - parameter: "[`logout_redirect_uri`](#logout-redirect-uri)"
    old: "Optional"
    new: "Required"
{% endtable %}
<!--vale on-->

<!-- vale off -->
#### scopes
<!-- vale on -->

While using the OpenID Connect plugin with Kong Manager, `scopes` now have a default value of
`["openid", "email", "offline_access"]` if not specified.

* `openid`: Essential for OpenID Connect.
* `email`: Retrieves the user's email address and includes it in the ID token.
* `offline_access`: Essential refresh tokens to refresh the access tokens and sessions.

This parameter can be modified according to your needs. However, `"openid"` and `"offline_access"` should
always be included to ensure the OpenID Connect plugin works normally. Also, make sure that `scopes`
contains sufficient scopes for the claim specified by this parameter (for example, `"email"` in the default scopes).

<!-- vale off -->
#### admin_claim
<!-- vale on -->

`admin_claim` is now an optional parameter. If not set, it defaults to `"email"`.

This parameter is used while looking up the admin's username from the ID token. When configuring this setting,
make sure that `scopes` contains sufficient scopes for the claim specified by this parameter.

<!-- vale off -->
#### authenticated_groups_claim
<!-- vale on -->

`authenticated_groups_claim` is now an optional parameter. If not set, it defaults to `["groups"]`.

This parameter is used while looking up the admin's associated groups from the ID token.

<!-- vale off -->
#### redirect_uri
<!-- vale on -->

`redirect_uri` now should be configured as an array of URLs that points to Admin API's authentication
endpoint `<ADMIN_API>/auth` (for example,`["http://localhost:8001/auth"]`). 
Previously, `redirect_uri` was a list of URLs
pointing to Kong Manager (for example,`["http://localhost:8002"]`).

Users are recommended to update the client/application settings in their IdP to ensure that `<ADMIN_API>/auth`
(for example,`http://localhost:8001/auth`) is in the allow list for redirect URIs.

<!-- vale off -->
#### login_redirect_uri
<!-- vale on -->

`login_redirect_uri` is now a **required** parameter to configure the destination after authenticating
with the IdP. It should be always be an array of URLs that points to the Kong Manager
(for example, `["http://localhost:8002"]`).

<!-- vale off -->
#### logout_redirect_uri
<!-- vale on -->

`logout_redirect_uri` is now a **required** parameter to configure the destination after logging
out from the IdP. It should be always be an array of URLs that points to the Kong Manager
(for example, `["http://localhost:8002"]`).

Previously, Kong Manager didn't perform an [RP-initiated logout](https://openid.net/specs/openid-connect-rpinitiated-1_0.html#RPLogout)
from the IdP when a user request to logout. From Gateway v3.6 and onwards, Kong Manager will perform
an RP-initiated logout upon user logout.

<!-- vale off -->
### admin_gui_session_conf
<!-- vale on -->

As the OpenID Connect plugin now has a built-in session management mechanism, `admin_gui_session_conf`
is no longer used while authenticating with OIDC. You should also update your configuration
if you have previously configured session management via `admin_gui_session_conf` for OIDC.

Additionally, the default values of some parameters have been changed. 
See the following for more details:

<!--vale off-->
{% table %}
columns:
  - title: Old parameter name and location
    key: old_param
  - title: New parameter name and location
    key: new_param
  - title: Old default
    key: old_default
  - title: New default
    key: new_default
rows:
  - old_param: "[`admin_gui_session_conf.secret`](#secret)"
    new_param: "`admin_gui_auth_conf.session_secret`"
    old_default: "--"
    new_default: "--"
  - old_param: "[`admin_gui_session_conf.cookie_secure`](#cookie-secure)"
    new_param: "`admin_gui_auth_conf.session_cookie_secure`"
    old_default: "`true`"
    new_default: "`false`"
  - old_param: "[`admin_gui_session_conf.cookie_samesite`](#cookie-samesite)"
    new_param: "`admin_gui_auth_conf.session_cookie_same_site`"
    old_default: "`Strict`"
    new_default: "`Lax`"
{% endtable %}
<!--vale on-->

<!-- vale off -->
#### secret
<!-- vale on -->

You should now configure this via `admin_gui_auth_conf.session_secret`.

If not set, {{site.base_gateway}} will randomly generate a secret.

<!-- vale off -->
#### cookie_secure
<!-- vale on -->

You should now configure this via `admin_gui_auth_conf.session_cookie_secure`.

Previously, `cookie_secure` was set to `true` if not specified. However, `admin_gui_auth_conf.session_cookie_secure`
now has a default value of `false`. 
If you are using HTTPS rather than HTTP, we recommend enabling this option to enhance security.

<!-- vale off -->
#### cookie_samesite
<!-- vale on -->

You should now configure this via `admin_gui_auth_conf.session_cookie_same_site`.

Previously, `cookie_samesite` was set to `Strict` if not specified. However, `admin_gui_auth_conf.session_cookie_same_site`
now has a default value of `Lax`. If you are using the same domain for the Admin API and Kong Manager,
