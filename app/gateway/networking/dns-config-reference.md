---
title: DNS configuration reference

description: This reference explains DNS clients, CORS, and cookie management in {{site.base_gateway}}
content_type: reference
layout: reference
products:
   - gateway
   
min_version:
  gateway: '3.5'
  
plugins:
  - cors
  - mocking
  - session
  - openid-connect

breadcrumbs:
  - /gateway/networking/dns-config-reference/
---

{{site.base_gateway}} provides Kong Manager, which must be able to interact with the Admin API. This application is subject to security restrictions enforced by browsers, and Kong must send appropriate information to browsers in order for it to function properly.

These security restrictions use the applications’ DNS hostnames to evaluate whether the applications’ metadata satisfies the security constraints. As such, you must design your DNS structure to meet the requirements.


## DNS structure requirements

The two types of requirements are: 

* Kong Manager and the Admin API are served from the same hostname, typically by placing the Admin API under an otherwise unused path, such as `/_adminapi/`.

* Kong Manager and the Admin API are served from different hostnames with a shared suffix (e.g. `kong.example` for `api.admin.kong.example` and `manager.admin.kong.example`). Admin session configuration sets `cookie_domain` to the shared suffix.

The first option simplifies configuration in kong.conf, but requires an HTTP proxy in front of the applications (because it uses HTTP path-based routing). The Kong proxy can be used for this. The second option requires more configuration in kong.conf, but can be used without proxying the applications.

## CORS

[Cross-Origin Resource Sharing](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS), or CORS, is a set of rules for web
applications that make requests across origins, to URLs that don't share
the same scheme, hostname, and port as the page making the request. When making
a cross-origin request, browsers send an `Origin` request header, and servers
must respond with a matching `Access-Control-Allow-Origin` (ACAO) header. If
the two headers do not match, the browser will discard the response.

### CORS and Kong Manager


Kong Manager operate by issuing requests to the Admin API using JavaScript. These requests may be cross-origin depending on your environment. The Admin API obtains its ACAO header value from the `admin_gui_url` in kong.conf.

You can configure your environment such that these requests are not cross-origin by accessing both the Kong Manager and its associated API via the same hostname, for example: `https://admin.kong.example/` and the Admin API at `https://admin.kong.example/_api/`. This option requires placing a proxy in front of both Kong Manager and the Admin API to handle path-based routing. You can use Kong’s proxy for this purpose. Kong Manager must be served at the root of the domains and you cannot place the APIs at the root and Kong Manager under a path. You can manage CORS in {{site.base_gateway}} using the [CORS plugin](/plugins/cors/).


### Troubleshooting CORS

CORS errors are shown in the browser developer console with
explanations of the specific issue. ACAO/Origin mismatches are most common, but
other error conditions can appear as well.

For example, if you mistyped your `admin_api_uri`, you will see something
like the following:

```
Access to XMLHttpRequest at 'https://admin.kong.example' from origin 'https://manager.kong.example' has been blocked by CORS policy: Response to preflight request doesn't pass access control check: The 'Access-Control-Allow-Origin' header has a value 'https://typo.kong.example' that is not equal to the supplied origin.
```

These errors are generally self-explanatory, but if the issue is not clear,
check the Network developer tool, find the requests for the path in the error,
and compare its `Origin` request header and `Access-Control-Allow-Origin`
response header.

## Cookies

[Cookies](https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies) are small pieces of data saved by browsers for use in
future requests. Servers include a [Set-Cookie header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie) in their
response headers to set cookies, and browsers include a [Cookie
header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cookie) when making subsequent requests.

### Cookies and Kong Manager

After you log in to Kong Manager, Kong stores session information in a cookie
to recognize your browser during future requests. These cookies are created
using the [Session plugin](/plugins/session/) or
[OpenID Connect plugin](/plugins/openid-connect/).

The following parameters are used in the Session plugin:
* `cookie_domain` should match the common hostname suffix shared by the GUI and
  its API. For example, if you use `api.admin.kong.example` and
  `manager.admin.kong.example` for the Admin API and Kong Manager,
  `cookie_domain` should be `admin.kong.example`.
* `cookie_same_site` should typically be left at its default, `Strict`.
    * `None` is 
    not necessary if you have your DNS records and 
    `cookie_domain` set following the examples in this document.
    * `Lax` is only needed if the GUI and
    API are on entirely separate hostnames, e.g. `admin.kong.example` for the API
    and `manager.example.com` for Kong Manager. This configuration is not
    recommended because `Lax` opens a vector for cross-site request forgery
    attacks. It may be needed in some development or testing environments, but
    should not be used in production.
* `cookie_secure` controls whether cookies can be sent over unsecured
  (plaintext HTTP) requests. By default, it is set to `true`, which does not
  permit sending the cookie over unsecured connections. This setting should
  also remain on the default, but may be disabled in some development or
  testing environments where HTTPS is not used.

The OpenID Connect plugin uses the same settings, but prefixed with `session_`.

As with CORS, the above is not necessary if both the GUI and API use the same
hostname, with both behind a proxy and the API under a specific path on the
hostname.

### Troubleshooting cookies

Issues with session cookies broadly fall into cases where the cookie is not
sent and cases where the cookie is not set. Network developer tools can 
assist with investigating these.

* In the network tool, selecting individual requests will show their request and
response headers. Successful authentication requests should see a `Set-Cookie`
response header including a cookie whose name matches `cookie_name` setting,
and subsequent requests should include the same cookie in the `Cookie` request
header.
* If `Set-Cookie` is not present, it may be stripped by some intermediate
proxy, or may indicate that the authentication handler encountered an error.
There should typically be other evidence in the response status and body in the
event of an error, and possible additional information in {{site.base_gateway}}'s error logs.
* If the cookie is set but not sent, it may have been deleted or may not match
requests that need it. The application/storage tool will show current cookies
and their parameters. Review these to see if your requests do not meet the
criteria to send the cookie (e.g. the cookie domain is not a suffix for a
request that requires the cookie, or is not present) and adjust your session
configuration accordingly.
* If cookies are *not* present in application/storage, but were previously set
with `Set-Cookie`, they may have since been deleted, or may have expired.
Review the `Set-Cookie` information to see when the cookie was set to expire
and subsequent requests to determine if any other response has issued a
`Set-Cookie` that deleted it (by setting expiration to a date in the past).