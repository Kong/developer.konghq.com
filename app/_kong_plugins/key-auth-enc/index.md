---
title: 'Key Authentication - Encrypted'
name: 'Key Authentication - Encrypted'

content_type: plugin

publisher: kong-inc
description: 'Add key authentication to your services'


products:
    - gateway

works_on:
    - on-prem

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional

icon: key-auth-enc.png

categories:
  - authentication

related_resources:
  - text: Key Authentication plugin
    url: /plugins/key-auth/
  - text: Enable key authentication on a Gateway Service with {{site.base_gateway}}
    url: /how-to/authenticate-consumers-with-key-auth-enc/

search_aliases:
  - key auth encrypted
  - key authentication encrypted
  - key auth advanced
  - key authentication advanced
  - key-auth-enc
---

This plugin lets you add API key authentication to a [Gateway Service](/gateway/entities/service/) or a [Route](/gateway/entities/route/).
[Consumers](/gateway/entities/consumer/) then add their key either in a query string parameter or a
header to authenticate their requests. 

This plugin provides more functionality than the 
[Key Authentication](/plugins/key-auth/) plugin, 
letting you store API keys in an encrypted format in the {{site.base_gateway}} datastore.

{:.warning}
> **Important**: Before configuring this plugin, you must [enable {{site.base_gateway}}'s encryption Keyring](/gateway/keyring/#enable-keyring). 

## Case sensitivity

According to their respective specifications, HTTP header names are treated as
case _insensitive_, while HTTP query string parameter names are treated as case _sensitive_.
{{site.base_gateway}} follows these specifications as designed, meaning that the [`config.key_names`](/plugins/key-auth-enc/reference/#schema--config-key-names)
configuration values are treated differently when searching the request header fields versus
searching the query string. As a best practice, administrators are advised against defining
case-sensitive [`config.key_names`](/plugins/key-auth-enc/reference/#schema--config-key-names) values when expecting the authorization keys to be sent in the request headers.

Once applied, any user with a valid credential can access the Service or Route.
To restrict usage to certain authenticated users, also add the
[ACL](/plugins/acl/) plugin (not covered here) and create allowed or
denied groups of users.

## Consumer key management

When you [create a Consumer](/gateway/entities/consumer/#set-up-a-consumer), you can specify a `key` with `keyauth_credentials` (declarative configuration) or the `/consumers/{usernameOrId}/key-auth-enc` endpoint.

When authenticating, Consumers must specify their key either in the query, body, or a header:

{% table %}
columns:
  - title: Use
    key: use
  - title: Example
    key: example
  - title: Description
    key: description
rows:
  - use: Key in query
    example: |
      ```bash
      curl http://localhost:8000/{proxyPath}?apikey=<some_key>
      ```
    description: "To use the key in URL queries, set the configuration parameter [`config.key_in_query`](/plugins/key-auth-enc/reference/#schema--config-key-in-query) to `true` (default option)."
  - use: Key in body
    example: |
      ```bash
      curl http://localhost:8000/{proxyPath} \
      --data 'apikey: <some_key>'
      ```
    description: "To use the key in a request body, set the configuration parameter [`config.key_in_body`](/plugins/key-auth-enc/reference/#schema--config-key-in-body) to `true`. The default value is `false`."
  - use: Key in header
    example: |
      ```bash
      curl http://kong:8000/{proxy path} \
      -H 'apikey: <some_key>'
      ```
    description: "To use the key in a request body, set the configuration parameter [`config.key_in_header`](/plugins/key-auth-enc/reference/#schema--config-key-in-header) to `true` (default option)."
{% endtable %}

### API key locations in a request

{% include /plugins/key-auth/api-key-locations.md %}

## Upstream headers

{% include_cached /plugins/upstream-headers.md %}


