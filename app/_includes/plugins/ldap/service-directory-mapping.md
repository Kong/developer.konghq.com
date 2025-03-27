When using only RBAC Token authorization, service directory mapping to {{site.base_gateway}} roles doesn't take effect. If you need to use CLI access with your service directory mapping, you can use the same authentication mechanism that [Kong Manager](/gateway/kong-manager/) uses to secure browser sessions.

#### Authenticate user session

Retrieve a secure cookie session with the authorized LDAP user credentials:

```sh
$ curl -c /tmp/cookie http://localhost:8001/auth \
-H 'Kong-Admin-User: <ldap-username>' \
--user <ldap-username>:<ldap-password>
```

Now the cookie is stored at `/tmp/cookie` and can be read for future requests:

```sh
$ curl -c /tmp/cookie -b /tmp/cookie http://localhost:8001/consumers \
-H 'Kong-Admin-User: <ldap-username>'
```

Because Kong Manager is a browser application, if any HTTP responses see the `Set-Cookie` header, then it will automatically attach it to future requests. This is why it's helpful to use [cURL's cookie engine](https://ec.haxx.se/http/cookies/index.html) or [HTTPie sessions](https://httpie.org/docs/0.9.7#sessions). If you don't want to store the session, then the `Set-Cookie` header value can be copied directly from the `/auth` response and used with subsequent requests.
