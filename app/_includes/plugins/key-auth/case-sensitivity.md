According to their respective specifications, HTTP header names are treated as
case _insensitive_, while HTTP query string parameter names are treated as case _sensitive_.
{{site.base_gateway}} follows these specifications as designed, meaning that the [`config.key_names`](./reference/#schema--config-key-names)
configuration values are treated differently when searching the request header fields versus
searching the query string. As a best practice, administrators are advised against defining
case-sensitive [`config.key_names`](./reference/#schema--config-key-names) values when expecting the authorization keys to be sent in the request headers.

Once applied, any user with a valid credential can access the Service or Route.
To restrict usage to certain authenticated users, also add the
[ACL](/plugins/acl/) plugin and create allowed or
denied groups of users.