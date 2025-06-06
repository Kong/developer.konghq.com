To authenticate a user, the client must set credentials in either the
`Proxy-Authorization` or `Authorization` header in the following format:
```
credentials := [ldap | LDAP] base64(username:password)
```
The `Authorization` header would look like this:
```
Authorization:  ldap dGxibGVzc2luZzpLMG5nU3RyMG5n
```
The plugin validates the user against the LDAP server and caches the
credentials for future requests for the duration specified in
`config.cache_ttl`.

You can set the header type `ldap` to any string (such as `basic`) using
`config.header_type`.