---
title: DNS Config Reference

description: This reference explains DNS clients, CORS, and Cookie management in {{site.base_gateway}}
content_type: reference
layout: reference
tier: enterprise
products:
   - gateway
   

plugins:
  - cors
  - mocking
  - sessions
  - oidc


breadcrumbs:
  - /gateway/networking/dns-config-reference
---

## Overview 

{{site.base_gateway}} provides the Kong Manager, which must be able to interact with the Admin API. This application is subject to security restrictions enforced by browsers, and Kong must send appropriate information to browsers in order for it to function properly.

These security restrictions use the applications’ DNS hostnames to evaluate whether the applications’ metadata satisfies the security constraints. As such, you must design your DNS structure to meet the requirements.


## DNS structure requirements


* Kong Manager and the Admin API are served from the same hostname, typically by placing the Admin API under an otherwise unused path, such as `/_adminapi/`.

* Kong Manager and the Admin API are served from different hostnames with a shared suffix (e.g. `kong.example` for `api.admin.kong.example` and `manager.admin.kong.example`). Admin session configuration sets `cookie_domain` to the shared suffix.

The first option simplifies configuration in kong.conf, but requires an HTTP proxy in front of the applications (because it uses HTTP path-based routing). The Kong proxy can be used for this. The second option requires more configuration in kong.conf, but can be used without proxying the applications.


{% include sections/cors-and-kong-gateway.md %}

### CORS and Kong Manager


Kong Manager operate by issuing requests to the Admin API using JavaScript. These requests may be cross-origin depending on your environment. The Admin API obtains its `ACAO header` value from the `admin_gui_url` in kong.conf.

You can configure your environment such that these requests are not cross-origin by accessing both the Kong Manager and its associated API via the same hostname, like: https://admin.kong.example/ and the Admin API at https://admin.kong.example/_api/. This option requires placing a proxy in front of both Kong Manager and the Admin API to handle path-based routing. You can use Kong’s proxy for this purpose. Kong Manager must be served at the root of the domains and you cannot place the APIs at the root and Kong Manager under a path.


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