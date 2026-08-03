---
title: Kong strips headers with period characters
content_type: support
description: Kong inherits header validation behavior from NGINX, which strips HTTP headers containing period characters in their names; this can be disabled with the `ignore_invalid_headers` directive.
products:
  - gateway
works_on:
  - on-prem
  - konnect
published: false
related_resources:
  - text: the `nginx_http_` directive injector
    url: /gateway/configuration/#nginx-injected-directives-section
tldr:
  q: Why does Kong strip HTTP headers with period characters in their names?
  a: |
    Kong inherits header-name validation from NGINX, which strips headers containing periods (for example `Foo.Bar`) before they reach the upstream. Set the `ignore_invalid_headers` directive to `off` in `kong.conf` (via the `nginx_http_` directive injector) to disable this behavior.
---

## Kong strips headers with period characters

HTTP headers containing periods, e.g. "Foo.Bar: Baz", are stripped by Kong and are not passed upstream.

Kong inherits some header validation behavior from NGINX, which strips headers containing period characters in their names. This can be disabled by adding an `ignore_invalid_headers` directive set to `off` in `kong.conf`, using the `nginx_http_` directive injector.
</content>
