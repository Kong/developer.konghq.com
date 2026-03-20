---
title: 'Syslog'
name: 'Syslog'

content_type: plugin

publisher: kong-inc
description: 'Send request and response logs to Syslog'

products:
    - gateway

works_on:
    - on-prem
    - konnect

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid

icon: syslog.png

categories:
  - logging

tags:
  - logging

faqs:
  - q: How can I avoid truncated logs from the Syslog plugin?
    a: |
       The Syslog plugin doesn't set a limit on the message size.

       The max size that gets logged is determined by the protocol receiver's implementation of it, and limitations of the transport. 
       * If the Syslog receiver is using the older [RFC3164](https://tools.ietf.org/html/rfc3164#section-4.1) standard, the max size will be 1024 octets.
       * If the Syslog receiver is using the modern [RFC 5424](https://tools.ietf.org/html/rfc5424#section-6.1) standard, the minimum max size is 480 octets, and the recommended max size is 2048 octets. 
       Transport receivers may receive messages larger than 2048 octets, but could truncate or discard it if not supported by the implementation.

notes: | 
   **Dedicated and Serverless Cloud Gateways**: This plugin is not supported in Dedicated or 
   Serverless Cloud Gateways because it depends on a local agent, and there are no local nodes 
   in Dedicated or Serverless Cloud Gateways.

min_version:
  gateway: '1.0'
---

Log request and response data to Syslog.

{:.info}
> **Note:** Make sure the Syslog daemon is running on the instance and is configured with a
logging level severity equal to or lower than the one set in the [`config.log_level`](./reference/#schema--config-log-level) parameter for this plugin.

## Log format

{% include /plugins/logging/log-format.md name=page.name %}

{% include /plugins/logging/json-object-log.md %}

## Kong process errors

{% include plugins/logging/kong-process-errors.md %}

{:.info}
> **Note:** If the `max_batch_size` argument > 1, a request is logged as an array of JSON objects.

## Custom fields by Lua

{% include /plugins/logging/log-custom-fields-by-lua.md custom_fields_by_lua='config.custom_fields_by_lua' custom_fields_by_lua_slug='config-custom-fields-by-lua' name=page.name slug=page.slug %}

## Forwarding logs to a remote network host

{{site.base_gateway}} system logs can be forwarded to a Syslog server by changing the {{site.base_gateway}} configuration:

<!--vale off-->
{% kong_config_table %}
config:
  - name: proxy_access_log
  - name: proxy_error_log
  - name: admin_access_log
  - name: admin_error_log
  - name: status_access_log 
  - name: status_error_log
  - name: proxy_stream_access_log
  - name: proxy_stream_error_log
{% endkong_config_table %}
<!--vale on-->

For example, to forward `proxy_access_log` to a remote Syslog server:
```
proxy_access_log=syslog:server={syslog-server-ip}:{syslog-server-port},facility=user,tag=proxy_access_log,severity=info
```
