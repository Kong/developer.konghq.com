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

related_resources:
  - text: LDAP Authentication
    url: /plugins/ldap-auth/
---

{% include /plugins/ldap/description.md %}

The LDAP Authentication Advanced plugin
provides features not available in the [LDAP Authentication plugin](/plugins/ldap-auth/), including:
* LDAP searches for group and consumer mapping
* Authentication of Consumers based on username or custom ID
* Binding to an enterprise LDAP directory with a password
* Authentication/authorization using a group base DN and specific group member or group name attributes
* Obtaining LDAP groups and setting them in a request header before proxying to the upstream. This is useful for Kong Manager role mapping.

## Usage

{% include /plugins/ldap/usage.md %}

### Upstream headers

{% include_cached /plugins/upstream-headers.md %}

### LDAP search and `config.bind_dn`

LDAP directory searching is performed during the request/plugin lifecycle. It's
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

### Using service directory mapping on the CLI

{% include /plugins/ldap/service-directory-mapping.md %}

## LDAP groups

The plugin obtains LDAP groups and sets them in the `x-authenticated-groups` request header before proxying to the upstream. 
This is useful for Kong Manager role mapping.

{:.info}
> The plugin doesn’t authenticate users based on group membership. If the user is not a member of an LDAP group, the request is still allowed.

## Limitations

* The `config.group_base_dn` and `config.base_dn` parameters have to fully match the exact DN of the group; 
a generic DN won’t work. 
For example, consider a case where there are nested organizational units: if a
top-level DN such as `"ou=dev,o=company"` is specified instead of
`"ou=role,ou=groups,ou=dev,o=company"`, the authentication will fail.

* Referrals are not supported in the plugin. A workaround is
to hit the LDAP Global Catalog instead, which is usually listening on a
different port than the default `389`. That way, referrals don't get sent
back to the plugin.
