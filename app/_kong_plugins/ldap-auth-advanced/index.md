---
title: 'LDAP Authentication Advanced'
name: 'LDAP Authentication Advanced'

content_type: plugin

publisher: kong-inc
description: 'Secure Kong with username and password protection, use LDAP search and service directory mapping'


products:
    - gateway

works_on:
    - on-prem
    - konnect

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: ldap-auth-advanced.png

categories:
  - authentication

search_aliases:
  - ldap-auth-advanced
  - ldap auth advanced
---

---
nav_title: Overview
---

{% include /plugins/ldap/description.md %}

The LDAP Authentication Advanced plugin
provides features not available in the [LDAP Authentication plugin](/plugins/ldap-auth/), including:
* LDAP searches for group and consumer mapping
* Ability to authenticate based on username or custom ID
* The ability to bind to an enterprise LDAP directory with a password
* The ability to authenticate/authorize using a group base DN and specific group member or group name attributes
* The ability to obtain LDAP groups and set them in a header to the request before proxying to the upstream. 
This is useful for Kong Manager role mapping.

## Usage

{% include /plugins/ldap/usage.md %}

### Upstream Headers

{% include_cached /plugins/upstream-headers.md %}


### LDAP Search and `config.bind_dn`

LDAP directory searching is performed during the request/plugin lifecycle. It is
used to retrieve the fully qualified DN of the user so a bind
request can be performed with a user's given LDAP username and password. The
search for the user being authenticated uses the `config.bind_dn` property. The
search uses `scope="sub"`, `filter="<config.attribute>=<username>"`, and
`base_dn=<config.base_dn>`. Here is an example of how it performs the search
using the `ldapsearch` command line utility:

```bash
ldapsearch -x \
  -h "<config.ldap_host>" \
  -D "<config.bind_dn>" \
  -b "<config.attribute>=<username><config.base_dn>" \
  -w "<config.ldap_password>"
```

### Using Service Directory Mapping on the CLI

{% include /md/gateway/ldap-service-directory-mapping.md %}

## Notes

`config.group_base_dn` and `config.base_dn` do not accept an array and
it has to fully match the full DN the group is in - it won’t work if it
is specified a more generic DN, therefore it needs to be specific. For
example, considering a case where there are nested `"OU's"`. If a
top-level DN such as `"ou=dev,o=company"` is specified instead of
`"ou=role,ou=groups,ou=dev,o=company"`, the authentication will fail.

Referrals are not supported in the plugin. A workaround is
to hit the LDAP Global Catalog instead, which is usually listening on a
different port than the default `389`. That way, referrals don't get sent
back to the plugin.

The plugin doesn’t authenticate users (allow/deny requests) based on group
membership. For example:
- If the user is a member of an LDAP group, the request is allowed.
- if the user is not a member of an LDAP group, the request is still allowed.

The plugin obtains LDAP groups and sets them in a header, `x-authenticated-groups`,
to the request before proxying to the upstream. This is useful for Kong Manager role
mapping.
