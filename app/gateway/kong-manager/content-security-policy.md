---
title: Content Security Policy for Kong Manager

description: Strengthen security in Kong Manager by setting a Content Security Policy (CSP).
content_type: reference
layout: reference
products:
   - gateway
   
min_version:
  gateway: '3.10'

breadcrumbs:
  - /gateway/
  - /gateway/kong-manager/

works_on:
  - on-prem

tags:
  - kong-manager

related_resources:
  - text: Content Security Policy (CSP) on MDN Web Docs
    url: https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP
---

A Content Security Policy (CSP) is a standard that helps prevent or minimize the risk of certain types of security threats. 
It consists of a series of instructions from a website to a browser, which instruct the browser to place restrictions on the things that the code comprising the site is allowed to do.

Kong Manager provides the following settings to manage the CSP through `kong.conf`:

<!--vale off-->
{% kong_config_table %}
config:
  - name: admin_gui_csp_header
  - name: admin_gui_csp_header_value
{% endkong_config_table %}
<!--vale on-->

## Default CSP

When `admin_gui_csp_header` is enabled, Kong Manager enforces a default CSP composed of the following directives:

```
default-src 'self';
connect-src {source};
img-src 'self' data:;
script-src 'self' 'wasm-unsafe-eval';
script-src-elem 'self';
style-src 'self' 'unsafe-inline';
```

The value of the `connect-src` directive depends on the [`admin_gui_api_url`](/gateway/configuration/#admin-gui-api-url) setting.

If `admin_gui_api_url` is **not specified**, the `connect-src` directive depends on the requesting host and port. 
For example:
* If the request URL is `http://localhost:9112`, the `connect-src` directive is `http://localhost:9112`
* If the request URL is `https://localhost:9112`, the `connect-src` directive is `https://localhost:9112`

If `admin_gui_api_url` is **specified**, the `connect_src` directive depends on the presence of the `http` or `https` prefix.
For example:
* If `admin_gui_api_url` starts with `http://` or `https://`, the `connect-src` directive is the value of `admin_gui_api_url`. 
* If `admin_gui_api_url` doesn't start with `http://` or `https://`, the `connect-src` directive is the value of `admin_gui_api_url` prefixed with `http://` when being accessed over HTTP, and `https://` when being accessed over HTTPS.

## Customize the CSP header

Sometimes, the default CSP may not fit your needs. You can customize the Content Security Policy by setting the [`admin_gui_csp_header_value`](/gateway/configuration/#admin-gui-csp-header-value) parameter in your Kong configuration. 
For example:

```
admin_gui_csp_header_value = default-src 'self'; connect-src 'self' https://my-admin-api.tld;
```

{:.warning}
> **Note:** An invalid Content Security Policy may break the functionality of Kong Manager or even expose it to security risks. 
Make sure to test the Content Security Policy before using it in production.
