---
title: Kong Manager with LDAP

description: Bind authentication for Kong Manager admins to an organization’s service directory, and set up authenticated group mapping.
content_type: reference
layout: reference
products:
   - gateway
   
min_version:
  gateway: '3.4'

breadcrumbs:
  - /gateway/
  - /gateway/kong-manager/

works_on:
  - on-prem

tags:
  - kong-manager
  - security
  - ldap

search_aliases:
  - group mapping
  - ldap
  - service directory

related_resources:
  - text: Kong Manager
    url: /gateway/kong-manager/
  - text: LDAP Authentication Advanced plugin reference
    url: /plugins/ldap-auth-advanced/reference/
  - text: Session plugin reference
    url: /plugins/session/reference/
---

{{site.base_gateway}} provides the ability to bind authentication for Kong Manager admins to an organization’s service directory.
 
LDAP authentication for Kong Manager is enabled and configured entirely through `kong.conf`, and uses the [LDAP Authentication Advanced](/plugins/ldap-auth-advanced/) and [Session](/plugins/session/) plugins in the background.
You **do not** need to manually enable either plugin.

## Supported configuration options

{{site.base_gateway}} uses the config parameter [`admin_gui_auth_conf`](/gateway/configuration/#admin-gui-auth-conf) to configure the LDAP plugin, and [`admin_gui_session_conf`](/gateway/configuration/#admin-gui-session-conf) to configure Sessions.

To customize examples in this guide, refer to:
* [LDAP Authentication Advanced plugin parameter reference](/plugins/ldap-auth-advanced/reference/)
* [Session plugin parameter reference](/plugins/session/reference/)

## Enable LDAP for Kong Manager

The following examples show you how to enable LDAP auth for Kong Manager.

{% navtabs "enable-ldap" %}
{% navtab "Docker quickstart" %}

Set the {{site.base_gateway}} license as a variable:
```sh
export KONG_LICENSE_DATA='LICENSE-CONTENTS-GO-HERE'
```

Create the {{site.base_gateway}} container and enable RBAC with LDAP auth. In this example, we can use the quickstart.
Replace any values with your own as needed. At minimum, At minimum, replace all values marked with `YOUR-` with literal values from your service directory:

```bash
curl -Ls get.konghq.com/quickstart | bash -s -- \
  -e "KONG_LICENSE_DATA" \
  -e "KONG_ENFORCE_RBAC=on" \
  -e "KONG_PASSWORD=kong" \
  -e "KONG_ADMIN_GUI_AUTH=ldap-auth-advanced" \
  -e "KONG_ADMIN_GUI_SESSION_CONF={ "secret":"YOUR-SECRET" } \
  -e 'KONG_ADMIN_GUI_AUTH_CONF={ "anonymous":"", "attribute":"YOUR-ATTRIBUTE", "bind_dn":"YOUR-BIND-DN", "base_dn":"YOUR-BASE-DN", "cache_ttl": 2, "consumer_by":["username", "custom_id"], "header_type":"Basic", "keepalive":60000, "ldap_host":"YOUR-LDAP-HOST", "ldap_password":"YOUR-LDAP-PASSWORD", "ldap_port":389, "start_tls":false, "ldaps":false, "timeout":10000, "verify_ldap_host":true }'
```

This enables RBAC, sets `ldap-auth-advanced` as the authentication method, and configures your service directory.
For more information about the values, see the [RBAC](/gateway/entities/rbac/) reference.

{% endnavtab %}
{% navtab "Kong configuration file" %}

Enable RBAC and LDAP auth for Kong Manager by updating your `kong.conf` file with the following configuration.
Replace any values with your own as needed. 
At minimum, set a session secret in `admin_gui_session_conf` and replace all values marked with `YOUR-` with literal values from your service directory:

```
enforce_rbac = on
admin_gui_auth = ldap-auth-advanced
admin_gui_session_conf = { "secret":"YOUR-SECRET" }
admin_gui_auth_conf = {
    "anonymous":"",
    "attribute":"YOUR-ATTRIBUTE",
    "bind_dn":"YOUR-BIND-DN",
    "base_dn":"YOUR-BASE-DN",
    "cache_ttl": 2,
    "consumer_by":["username", "custom_id"],
    "header_type":"Basic",
    "keepalive":60000,
    "ldap_host":"YOUR-LDAP-HOST",
    "ldap_password":"YOUR-LDAP-PASSWORD",
    "ldap_port":389,
    "start_tls":false,
    "ldaps":false,
    "timeout":10000,
    "verify_ldap_host":true
}
```
This enables RBAC, sets `ldap-auth-advanced` as the authentication method, and configures your service directory.
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

Next, to start using LDAP auth, set up [authenticated group mapping](#ldap-authenticated-group-mapping).

### Recommendations to enhance session security

When authenticating Kong Manager with LDAP, the Session plugin is used to persist the authorization state. 
This plugin (configured with `admin_gui_session_conf`) requires a secret and is configured securely by default.

For enhanced security, we recommend setting a few extra session parameters:
* `secret`: Set this to a string value. A randomly generated secret will be used if unspecified.
* `cookie_secure`: Defaults to `false`. We recommend setting this value to `true` when using HTTPS.
* `cookie_same_site`: Consider upgrading this value to `Strict` when using the same domain for the Admin API and Kong Manager. 
If using different domains for the Admin API and Kong Manager, `cookie_same_site` must be set to `Lax`.

## LDAP authenticated group mapping

Using Kong’s [LDAP Auth Advanced plugin](/plugins/ldap-auth-advanced/), you can map service directory groups to Kong roles for authentication and authorization.

Here's how service directory mapping works in {{site.base_gateway}}:

* Roles are created in {{site.base_gateway}} using the Admin API or Kong Manager.
* Groups are created and roles are associated with the groups.
* When users log in to Kong Manager, they get permissions based on the groups they belong to.

When using LDAP service directory mapping, roles assigned to admins are managed by the service directory. 
The mapping removes the task of manually managing access in {{site.base_gateway}}, because it makes the directory the system of record.

If an admin’s group changes in the directory, their Kong admin account’s associated role also changes in {{site.base_gateway}} the next time they log in to Kong Manager. 
Don't assign or unassign admin roles in {{site.base_gateway}} manually, as any changes will be overwritten by the directory during the next login.

### Service directory mapping workflows

The following examples show you how to set up LDAP authenticated group mapping for Kong Manager, then create admins in Kong Manager and map them to service directory groups.

Alternatively, you could also choose one of the following workflows:
* Start {{site.base_gateway}} with RBAC turned off, map a group to the Super Admin role, and then create an admin to correspond to a user belonging to that group. 
This approach ensures that the Super Admin's privileges are entirely tied to the directory group, whereas bootstrapping a Super Admin only uses the directory for authentication.
* Create all admin accounts for matching directory users first and ensure that their existing groups map to appropriate roles before enforcing RBAC.

### Set up authenticated group mapping

Review [supported configuration options](#supported-configuration-options) to customize the configuration stored in `admin_gui_auth_conf` and `admin_gui_session_conf`.

{% navtabs "enable-ldap-mapping" %}
{% navtab "Kubernetes with Helm" %}
1. Create a configuration file for the LDAP Auth Advanced plugin and save it as
`admin_gui_auth_conf`. Adjust your own values as needed:

    ```json
    {
        "anonymous":"",
        "attribute":"YOUR-ATTRIBUTE",
        "bind_dn":"YOUR-BIND-DN",
        "base_dn":"YOUR-BASE-DN",
        "cache_ttl": 2,
        "header_type":"Basic",
        "keepalive":60000,
        "ldap_host":"YOUR-LDAP-HOST",
        "ldap_password":"YOUR-LDAP-PASSWORD",
        "ldap_port":389,
        "start_tls":false,
        "ldaps":false,
        "timeout":10000,
        "verify_ldap_host":true,
        "consumer_by":["username", "custom_id"],
        "group_base_dn":"YOUR-GROUP-BASE-DN",
        "group_name_attribute":"YOUR-GROUP-NAME-ATTRIBUTE",
        "group_member_attribute":"YOUR-GROUP-MEMBER-ATTRIBUTE",
    }
    ```
    Review the [supported configuration options](#supported-configuration-options) to customize any configuration.

1. Create a secret from the file you just created:

    ```sh
    kubectl create secret generic kong-ldap-conf --from-file=admin_gui_auth_conf -n kong
    ```

1. Create a configuration file for the Session plugin and save it as `admin_gui_session_conf`. Adjust your own values as needed:

    ```json
    {"secret":"kong", "cookie_lifetime":300000, "cookie_renew":200000, "cookie_name":"kong_cookie", "cookie_secure":false, "cookie_samesite": "off"}
    ```

1. Create a session secret from the file you just created:

    ```sh
    kubectl create secret generic kong-session-conf --from-file=admin_gui_session_conf -n kong
    ```

1. Update the RBAC section of the deployment `values.yml` file with the
following parameters:

    ```yaml
    rbac:
      enabled: true
      admin_gui_auth: ldap-auth-advanced
      session_conf_secret: kong-session-conf
      admin_gui_auth_conf_secret: kong-ldap-conf
    ```

1. Using Helm, upgrade the deployment with your YAML filename:

    ```sh
    helm upgrade --install kong-ee kong/kong -f ./myvalues.yaml -n kong
    ```
{% endnavtab %}
{% navtab "Docker" %}

Run the following command to set the needed
environment variables and reload the {{site.base_gateway}} configuration.

Replace any values with your own as needed. At minimum, replace all values marked with `YOUR-`:

```sh
echo "
  KONG_ENFORCE_RBAC=on \
  KONG_ADMIN_GUI_AUTH=ldap-auth-advanced \
  KONG_ADMIN_GUI_SESSION_CONF={ "secret":"YOUR-SECRET" } \
  KONG_ADMIN_GUI_AUTH_CONF='{
    \"anonymous\":\"\",
    \"attribute\":\"YOUR-ATTRIBUTE\",
    \"bind_dn\":\"YOUR-BIND-DN\",
    \"base_dn\":\"YOUR-BASE-DN\",
    \"cache_ttl\":2,
    \"header_type\":\"Basic\",
    \"keepalive\":60000,
    \"ldap_host\":\"YOUR-LDAP-HOST\",
    \"ldap_password\":\"YOUR-LDAP-PASSWORD\",
    \"ldap_port\":389,
    \"start_tls\":false,
    \"ldaps\":false,
    \"timeout\":10000,
    \"verify_ldap_host\":true,
    \"consumer_by\":[\"username\",\"custom_id\"],
    \"group_base_dn\":\"YOUR-GROUP-BASE-DN\",
    \"group_name_attribute\":\"YOUR-GROUP-NAME-ATTRIBUTE\",
    \"group_member_attribute\":\"YOUR-GROUP-MEMBER-ATTRIBUTE\"
  }' kong reload exit" | docker exec -i YOUR-KONG-CONTAINER-ID /bin/sh
```
Review the [supported configuration options](#supported-configuration-options) to customize any configuration.

Restart Kong:

```sh
docker restart kong-quickstart-gateway
```

{% endnavtab %}
{% navtab "Kong configuration file" %}

1. Navigate to your `kong.conf` file.

1. With RBAC enabled, add the `admin_gui_auth`, `admin_gui_session_conf`, and `admin_gui_auth_conf`
properties to the file.

    Replace any values with your own as needed. At minimum, replace all values marked with `YOUR-`:
    ```
    enforce_rbac = on
    admin_gui_auth = ldap-auth-advanced
    admin_gui_session_conf = { "secret":"YOUR-SECRET" }
    admin_gui_auth_conf = {
        "anonymous":"",
        "attribute":"YOUR-ATTRIBUTE",
        "bind_dn":"YOUR-BIND-DN",
        "base_dn":"YOUR-BASE-DN",
        "cache_ttl": 2,
        "header_type":"Basic",
        "keepalive":60000,
        "ldap_host":"YOUR-LDAP-HOST",
        "ldap_password":"YOUR-LDAP-PASSWORD",
        "ldap_port":389,
        "start_tls":false,
        "ldaps":false,
        "timeout":10000,
        "verify_ldap_host":true,
        "consumer_by":["username", "custom_id"],
        "group_base_dn":"YOUR-GROUP-BASE-DN",
        "group_name_attribute":"YOUR-GROUP-NAME-ATTRIBUTE",
        "group_member_attribute":"YOUR-GROUP-MEMBER-ATTRIBUTE",
    }
    ```
   Review the [supported configuration options](#supported-configuration-options) to customize any configuration.

1. Restart {{site.base_gateway}} to apply the file:

    ```sh
    kong restart -c /path/to/kong.conf
    ```

{% endnavtab %}
{% endnavtabs %}

### Managing admins for LDAP mapping

With LDAP enabled, you now need to define roles in Kong Manager and create admins for user-admin mapping.

For example:
1. Example Corp maps the service directory group, `T1-Mgmt`, to the Kong role Super Admin.
2. Example Corp maps a service directory user, named `example-user`, to a Kong admin account with the same name, `example-user`.
3. The user, `example-user`, is assigned to the group `T1-Mgmt` in the LDAP Directory.

#### Define roles with permissions

Define roles with permissions in {{site.base_gateway}} using [RBAC](/gateway/entities/rbac/).
You must manually define which Kong roles correspond to each of the service directory's groups using either of the following:

* In Kong Manager's directory mapping section. Find it under **Teams** > **Groups** tab.
* With the Admin API's directory mapping endpoints.

{{site.base_gateway}} **will not** write to the service directory. 
For example, a {{site.base_gateway}} admin can't create users or groups in the directory. 
You must create users and groups independently in the service directory before mapping them to {{site.base_gateway}}.

#### Group-role assignment

Using service directory mapping, groups are mapped to roles.
When a user logs in, they are identified with their admin username and authenticated with the matching user credentials in the service directory.
The groups in the service directory are then automatically matched to the associated roles that the organization has defined.

#### User-admin mapping

To map a service directory user to a {{site.base_gateway}} admin, map the admin's username or custom ID to the DN value corresponding to the attribute configured in `admin_gui_auth_conf`.
If you already have admins in Kong Manager with assigned roles and want to use LDAP group mapping instead, remove all of their roles first.
The service directory will serve as the system of record for user privileges. 

For example, let's assume that:
* LDAP config on Kong side: 
  * `consumer_by` is set to `username`
  * `group_member_attribute` is `UID`
* Service directory user: `UID=example-user`

In this case, you would match the Kong admin's username attribute to the UID in the service directory, which is `example-user`.

We recommend pairing the [bootstrapped Super Admin](/how-to/create-a-super-admin/) with a directory user as the first Super Admin. Using our example values, that would look like this:

<!--vale off-->
{% control_plane_request %}
url: admins/kong_admin
method: PATCH
headers:
  - 'Content-Type: application/json'
  - 'Kong-Admin-Token: $RBAC_TOKEN'
body:
  username: example-user
{% endcontrol_plane_request %}
<!--vale on-->

After creating this admin, map the `super-admin` role to a group that `example-user` is in on the LDAP directory side, 
then delete the `super-admin` role from the `example-user` admin on the {{site.base_gateway}} side.
The group you pick needs to have "super" privileges in your service directory, otherwise as other admins log in with a generic group, they will also become Super Admins.

{:.warning}
> **Important**: If you delete the Super Admin role from your only admin, and have not yet mapped the Super Admin role to a group that admin belongs to, 
then you won't be able to log in to Kong Manager.

See [Admins](/gateway/entities/admin/) for more information on creating admins in Kong Manager.