---
title: "{{site.base_gateway}}: Custom log format without a custom nginx template"
content_type: support
published: false
description: "You can use the direct injection of nginx parameters to specify a custom log format without maintaining a custom nginx template."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "Kong Gateway: Is it possible to use a custom log format without using a custom nginx template?"
  a: |
    Yes. Set the `nginx_http_log_format` parameter in `kong.conf` (or `KONG_NGINX_HTTP_LOG_FORMAT` in Docker) to define the custom format directly, then point `proxy_access_log` (or `KONG_PROXY_ACCESS_LOG` in Docker) at it. No custom nginx template is required.
related_resources:
  - text: Kong Gateway nginx directives
    url: /gateway/nginx-directives/
---

## {{site.base_gateway}}: Is it possible to use a custom log format without using a custom nginx template

The documentation shows an example of defining a custom nginx log format which uses a custom nginx template. This is an overhead to maintain between versions, is there a way to specify a custom format without a custom nginx file and the associated maintenance overhead?

You can use the direct injection of nginx parameters to specify a log format.

For example, define the desired log format using the `nginx_http_log_format` parameter in the `kong.conf`;

```nginx
nginx_http_log_format=show_everything '\$time_iso8601 - \$bytes_sent - \$request - \$status - \$remote_addr'
```

In Docker, you would use environment variables as per the usual Docker configuration;

```bash
-e "KONG_NGINX_HTTP_LOG_FORMAT=show_everything '\$time_iso8601 - \$bytes_sent - \$request - \$status - \$remote_addr'"
```

and then specify the log file to use the format in the `kong.conf`;

```nginx
proxy_access_log=/dev/stdout show_everything
```

or via environment variables for Docker;

```bash
-e "KONG_PROXY_ACCESS_LOG=/dev/stdout show_everything"
```
