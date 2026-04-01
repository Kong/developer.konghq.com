---
title: DNS configuration reference

description: This reference explains DNS clients, CORS, and cookie management in {{site.base_gateway}}.
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
  - /gateway/
  - /gateway/network/

works_on:
  - on-prem

tags:
  - network

related_resources:
  - text: "{{site.base_gateway}} network"
    url: /gateway/network/
  - text: "Optimize {{site.base_gateway}} performance"
    url: /gateway/performance/optimize/
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

For example, if you mistyped your `admin_gui_api_url`, you will see something
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

## Migrate to the new DNS client {% new_in 3.8 %}

The 3.8 DNS client introduces a new standardized way to configure a Gateway Service, and helps improve performance.
When migrating to the new client, review the following changes and make adjustments as necessary.

{:.info}
> While migration isn't necessary and the old DNS client is still supported, we recommend migrating to the new DNS client for better performance and observable statistics via the `/status/dns` API endpoint.

### Record types

The new DNS client introduces some changes in the support for different record types. 
To avoid issues, make sure that your SRV records configuration is compatible with the new client before migrating.

#### SRV

SRV is included by default in the `resolver_family` directive, however the client will only query SRV records if the domain name follows the [RFC 2782](https://datatracker.ietf.org/doc/html/rfc2782) format (`_SERVICE._PROTO.NAME`). 
If the SRV record query fails, the client will not attempt to query the domain's IP addresses (A and AAAA records) again.

Before enabling SRV support with the new DNS client, make sure that the domain name is registered with your DNS service provider in the supported format. 
This standard format also works with the old DNS. 
Once you change the SRV format, it will continue to work with the old client, and there will no downtime during migration.

#### CNAME

The new DNS client doesn't need CNAME dereferencing. 
This task is entirely handled by the DNS server, per the industry standard.

{:.info}
> The new DNS client doesn't consider the order of record types when querying a domain. 
It only queries either IP addresses (A and AAAA records) or SRV records, but not both.

### Custom directives

If you had custom values for the directives in the [`DNS RESOLVER`](/gateway/configuration/#dns-resolver-section) section in `kong.conf`, 
you will need to manually add these values to the corresponding directives under [`New DNS RESOLVER`](/gateway/configuration/#new-dns-resolver-section).

{% table %}
columns:
  - title: Old DNS resolver directive
    key: old
  - title: New DNS resolver directive
    key: new
  - title: Notes
    key: note
rows:
  - old: "`dns_resolver`"
    new: "`resolver_address`"
    note: Same behavior.
  - old: "`dns_hostsfile`"
    new: "`resolver_hostsfile`"
    note: Same behavior.
  - old: "`dns_order`"
    new: "`resolver_family`"
    note: The new directive is only used to define the supported query types. There is no specific order.
  - old: "`dns_valid_ttl`"
    new: "`resolver_valid_ttl`"
    note: Same behavior.
  - old: "`dns_stale_ttl`"
    new: "`resolver_stale_ttl`"
    note: Same behavior.
  - old: "`dns_not_found_ttl` and `dns_error_ttl`"
    new: "`resolver_error_ttl`"
    note: "The two old directives are combined into a single directive in the new client."
  - old: "`dns_cache_size`"
    new: "`resolver_lru_cache_size` and `resolver_mem_cache_size`"
    note: |
      The old directive is split into the following new directives:
      * `resolver_lru_cache_size` specifies the size of the L1 LRU lua VM cache
      * `resolver_mem_cache_size` specifies the size of the L2 shared memory cache
  - old: "`dns_no_sync`"
    new: "N/A"
    note: This directive no longer exists. Requests are always synchronized in the new client.
{% endtable %}

### Enable the new DNS client

The new DNS client is disabled by default. 
To enable it, set [`new_dns_client=on`](/gateway/configuration/#new-dns-client) in your `kong.conf` file.
