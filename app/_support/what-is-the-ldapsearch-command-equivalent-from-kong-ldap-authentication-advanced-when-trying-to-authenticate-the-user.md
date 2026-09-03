---
title: "The `ldapsearch` command equivalent to the Kong LDAP Authentication Advanced plugin's query"
content_type: support
published: false
description: "Shows the equivalent `ldapsearch` command for troubleshooting queries made by the LDAP Authentication Advanced plugin when authenticating a user."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "What is the `ldapsearch` command equivalent from Kong LDAP Authentication Advanced plugin when trying to authenticate the user?"
  a: |
    The plugin performs the LDAP equivalent of an `ldapsearch` command built from the `bind_dn`, `base_dn`, `attribute`, and `group_member_attribute` config values. Running that same `ldapsearch` command manually against your LDAP server is a useful first step for troubleshooting authentication.
related_resources: []
---

## What is the `ldapsearch` command equivalent from the Kong LDAP Authentication Advanced plugin when trying to authenticate the user

What is the `ldapsearch` command equivalent from the Kong LDAP Authentication Advanced plugin when trying to authenticate the user?

When troubleshooting the Kong LDAP Authentication Advanced plugin to search for an authenticated user, the plugin similarly makes a query search command equivalent to the `ldapsearch` command below:

```bash
ldapsearch -H ldap://<ldap host> -D "<config.bind_dn>" -b "<config.base_dn>" -W -s sub "(<config.attribute>=<user to be authenticated>)" <config.group_member_attribute>

#example(for ldap)
ldapsearch -H ldap://<your ldap host> -D "CN=kong_ldap_admin,OU=Generic Accounts,OU=testgroup,DC=test,DC=com" -b "DC=TEST,DC=COM" -W -s sub "(sAMAccountName=foo)" memberOf

#example(for ldaps)
LDAPTLS_REQCERT=never ldapsearch -H ldaps://<your ldap host> -D "CN=kong_ldap_admin,OU=Generic Accounts,OU=testgroup,DC=test,DC=com" -b "DC=TEST,DC=COM" -W -s sub "(sAMAccountName=foo)" memberOf
```

p.s: `LDAPTLS_REQCERT` is an environment variable to verify LDAPS server certificate. Setting it up to `never` will ignore ldap server certificate verification which is useful during debugging.

The query search above should give first step troubleshoot to query the user using similar configuration set in the plugin.
