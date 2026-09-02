---
title: "{{site.base_gateway}} logs"
content_type: reference
layout: reference
breadcrumbs:
  - /gateway/
products:
    - gateway

tags:
  - logging
  - monitoring
min_version:
  gateway: '3.5'

description: See where {{site.base_gateway}} logs are located, the different log levels, and how to configure logs and log levels.
search_aliases:
  - logging
related_resources:
  - text: "Secure {{site.base_gateway}}"
    url: /gateway/security/
  - text: "{{site.base_gateway}} audit logs"
    url: /gateway/audit-logs/
  - text: "{{site.konnect_short_name}} logs"
    url: /dedicated-cloud-gateways/konnect-logs/
  - text: "{{site.konnect_short_name}} platform audit logs"
    url: /konnect-platform/audit-logs/
  - text: Logging plugins
    url: /plugins/?category=logging
  - text: Add Correlation IDs to {{site.base_gateway}} logs
    url: /how-to/add-correlation-ids-to-gateway-logs/

works_on:
  - on-prem
  - konnect
---

Logging in {{site.base_gateway}} allows you to see information, warnings, and errors about requests that are proxied by {{site.base_gateway}}.

The information in this reference doc helps you understand and modify {{site.base_gateway}} logs. You can also use [logging plugins](/plugins/?category=logging) to extend these capabilities by logging additional information or sending logs to another application.

## Where are {{site.base_gateway}} logs located?

By default, you can view {{site.base_gateway}} logs at `/usr/local/kong/logs/error.log`. If you are running {{site.base_gateway}} on Docker, you can also view them from your Docker container.

## Log levels

By default, logs are set to the recommended `notice` level. If logs are too chatty, you can increase the level to something like `warn`.

<!--vale off-->
{% table %}
columns:
  - title: Level
    key: level
  - title: Description
    key: description
rows:
  - level: "`debug`"
    description: "Provides debug information about the plugin’s run loop and each individual plugin or other components. This should only be used during debugging. If this is enabled for extended periods of time, it can result in excess disk space consumption."
  - level: "`info` and `notice`"
    description: "Provides information about normal behavior, most of which can be ignored."
  - level: "`warn`"
    description: "Logs any abnormal behavior that doesn't result in dropped transactions but requires further investigation."
  - level: "`error`"
    description: "Used for logging errors that result in a request being dropped. For example, getting a `500` error. The rate of these logs must be monitored."
  - level: "`crit`"
    description: "Used when {{site.base_gateway}} is working under critical conditions, affecting several clients. `crit` is the highest severity log level."
{% endtable %}
<!--vale on-->

## Configure log levels dynamically

You can change log levels dynamically, without restarting {{site.base_gateway}}, using the Admin API or the {{site.konnect_short_name}} API.
A dynamic log level change is never persisted to `kong.conf`.
If a node restarts while an override is active, it reverts to the log level set in `kong.conf`, and the `ttl` doesn't carry over.

Alternatively, you can configure log levels using the `log_level` parameter in the [`kong.conf` file](/gateway/configuration/), but this requires you to [restart {{site.base_gateway}}](/how-to/restart-kong-gateway-container/).

### Dynamic log levels for control planes and traditional clusters

You can view and manage log levels dynamically in traditional mode and for control planes in hybrid mode using the following settings and endpoints:

{% navtabs "control plane log level" %}
{% navtab "Self-managed" %}

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: usecase
  - title: Setting or endpoint
    key: config
rows:
  - usecase: "View current log level"
    config: |
      [`GET /debug/node/log-level`](/api/gateway/admin-ee/#/operations/get-debug-node-log-level)
  - usecase: "Modify the log level for an individual {{site.base_gateway}} node"
    config: "[`POST /debug/node/log-level/{logLevel}`](/api/gateway/admin-ee/#/operations/get-debug-node-log-level-log_level)"
  - usecase: "Change the log level of the {{site.base_gateway}} cluster"
    config: "[`/POST debug/cluster/log-level/{loglevel}`](/api/gateway/admin-ee/#/operations/update-debug-cluster-log-level)"
  - usecase: "Keep the log level of new nodes added to the cluster in sync with other nodes in the cluster"
    config: |
      Change the [`log_level`](/gateway/configuration/#log-level) entry in `kong.conf` to `KONG_LOG_LEVEL`, and start every new node with the `KONG_LOG_LEVEL` env variable set.
  - usecase: "Change the log level of all control plane {{site.base_gateway}} nodes"
    config: "[`POST /debug/cluster/control-planes-nodes/log-level/{loglevel}`](/api/gateway/admin-ee/#/operations/create-debug-cluster-control-planes-nodes-log-level)"
{% endtable %}
<!--vale on-->

{% endnavtab %}
{% navtab "{{site.konnect_short_name}}" %}

In {{site.konnect_short_name}}, you can only view the control plane log level. You can't adjust it dynamically.

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: usecase
  - title: Setting or endpoint
    key: config
rows:
  - usecase: "View current log level {% new_in 3.16 %}"
    config: |
      `GET /control-planes/{controlPlaneId}/nodes`: View the `log_level` field in the response
{% endtable %}
<!--vale on-->

{% endnavtab %}
{% endnavtabs %}

### Dynamic log levels for data plane nodes {% new_in 3.16 %} 

In hybrid mode, you can temporarily change the log level of data plane nodes from the control plane.
This is a runtime-only, on-demand override for debugging. It doesn't persist, and it isn't a substitute for permanent configuration in `kong.conf`.

{:.info}
> **Note**: Dynamic log levels are supported for data plane nodes running in hybrid mode. DB-less deployments are not supported.

{% navtabs "dynamic log level endpoints" %}
{% navtab "Self-managed" %}

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: usecase
  - title: Setting or endpoint
    key: config
rows:
  - usecase: "Modify the log level for one or more data plane nodes"
    config: "`POST /debug/cluster/data-planes/log-level-operations`"
  - usecase: "List dynamic log level operations"
    config: "`GET /debug/cluster/data-planes/log-level-operations`"
  - usecase: "Get the status of a dynamic log level operation"
    config: "`GET /debug/cluster/data-planes/log-level-operations/{id}`"
  - usecase: "List the per-node results of a dynamic log level operation"
    config: "`GET /debug/cluster/data-planes/log-level-operations/{id}/results`"
  - usecase: "Get the result for one data plane node in an operation"
    config: "`GET /debug/cluster/data-planes/log-level-operations/{id}/results/{node_id}`"
{% endtable %}
<!--vale on-->

{% endnavtab %}
{% navtab "{{site.konnect_short_name}}" %}

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: usecase
  - title: Setting or endpoint
    key: config
rows:
  - usecase: "Modify the log level for one or more data plane nodes"
    config: "`POST /control-planes/{controlPlaneId}/nodes/log-level-operations`"
  - usecase: "List dynamic log level operations"
    config: "`GET /control-planes/{controlPlaneId}/nodes/log-level-operations`"
  - usecase: "Get the status of a dynamic log level operation"
    config: "`GET /control-planes/{controlPlaneId}/nodes/log-level-operations/{operationId}`"
  - usecase: "List the per-node results of a dynamic log level operation"
    config: "`GET /control-planes/{controlPlaneId}/nodes/log-level-operations/{operationId}/results`"
  - usecase: "Get the result for one data plane node in an operation"
    config: "`GET /control-planes/{controlPlaneId}/nodes/log-level-operations/{operationId}/results/{nodeId}`"
{% endtable %}
<!--vale on-->

{% endnavtab %}
{% endnavtabs %}

When you create an operation, you specify a `log_level`, a target (`all` data plane nodes, or a list of `node_ids`), and an optional `ttl` in seconds. 
The data plane applies the new log level and automatically reverts to the previous level when the `ttl` expires.

{:.info}
> **Note**: The `ttl` must be an integer between 10 and 3600 seconds. If you don't set one, it defaults to 600 seconds (10 minutes). The 10 second minimum exists because data planes poll the control plane for updates every 5 seconds, so the `ttl` needs to cover at least two poll intervals for the node to reliably apply the change before it expires.

Data plane nodes on older {{site.base_gateway}} versions that don't support dynamic log levels report a status of `unsupported` instead of `applied`, both in `GET` and `POST` responses.

Reading the current log level is available to any Control Plane Viewer.
Creating or changing a dynamic log level operation is a privileged action and requires Control Plane Admin permissions or higher.

## Find specific client requests in logs

The `X-Kong-Request-Id` header contains a unique identifier for each client request. You can use this header to match specific requests to their corresponding error logs.

If {{site.base_gateway}} returns an error by calling the PDK `kong.response.error`, the request ID will also be included in the response body generated by {{site.base_gateway}}. In addition, any generated {{site.base_gateway}} error log contains the same request ID with the format `request_id: xxx`. This can help with debugging because you can search for the header when the debug output is too long to fit in the response header.

This feature can be customized for upstreams and downstreams using the `headers` and `headers_upstream` configuration options in [`kong.conf`](/gateway/configuration/):

<!--vale off-->
{% kong_config_table %}
config:
  - name: headers
  - name: headers_upstream
{% endkong_config_table %}
<!--vale on-->

## Customize what {{site.base_gateway}} logs

You may need to customize what {{site.base_gateway}} logs. For instance, you may want to:
* Protect private information
* Comply with GDPR or other data protection regulations
* Remove instances of a specific piece of data from your logs, such as an email address

These changes can be made to {{site.base_gateway}}'s Nginx template and only affect the output of the Nginx access logs. This doesn't have any effect on {{site.base_gateway}}'s [logging plugins](/plugins/?category=logging).

Let's look at an example where you want to remove any instances of an email address from your {{site.base_gateway}} logs. The email addresses may come through in different formats, for example `/servicename/v2/verify/alice@example.com` or `/v3/verify?alice@example.com`. To keep all of these formats from being added to the logs, you need to use a custom Nginx template.

Make a copy of {{site.base_gateway}}'s Nginx template, then edit it to add or remove the data you need. The following template shows an example configuration for removing email addresses from logs:

```nginx
# ---------------------
# custom_nginx.template
# ---------------------

worker_processes ${{NGINX_WORKER_PROCESSES}}; # can be set by kong.conf
daemon ${{NGINX_DAEMON}};                     # can be set by kong.conf

pid pids/nginx.pid;                      # this setting is mandatory
error_log stderr ${{LOG_LEVEL}}; # can be set by kong.conf



events {
    use epoll; # custom setting
    multi_accept on;
}

http {


    map $request_uri $keeplog {
        ~.+\@.+\..+ 0;
        ~/v1/invitation/ 0;
        ~/reset/v1/customer/password/token 0;
        ~/v2/verify 0;

        default 1;
    }
    log_format show_everything '$remote_addr - $remote_user [$time_local] '
        '$request_uri $status $body_bytes_sent '
        '"$http_referer" "$http_user_agent"';

    include 'nginx-kong.conf';
}
```

For this example, we're using the following:

* `map $request_uri $keeplog`: Maps a new variable called `keeplog`, which is dependent on values appearing in the `$request_uri`. Each line in the example starts with a `~` because this is what tells Nginx to use a regex when evaluating the line. This example looks for the following:
  - The first line uses a regex to look for any email address in the `x@y.z` format
  - The second line looks for any part of the URI that contains `/servicename/v2/verify`
  - The third line looks at any part of the URI that contains `/v3/verify`

    Because all of these patterns have a value of something other than `0`, if a request has any of those elements, it will not be added to the log.
* `log_format`: Sets the log format for what {{site.base_gateway}} keeps in the logs. The contents of the log can be customized for your needs. For the purpose of this example, you can assign the new logs with the name `show_everything` and set everything to the {{site.base_gateway}} default standards. To see the full list of options, refer to the [Nginx core module variables reference](https://nginx.org/en/docs/http/ngx_http_core_module.html#variables).

Once you've adjusted the Nginx template for your environment, you need to tell {{site.base_gateway}} to use the newly created log, `show_everything`.

To do this, alter the {{site.base_gateway}} variable `proxy_access_log` by either editing `etc/kong/kong.conf` or using the environmental variable `KONG_PROXY_ACCESS_LOG` adjust the default location:

```sh
proxy_access_log=logs/access.log show_everything if=$keeplog
```

Restart {{site.base_gateway}} to apply changes with the `kong restart` command.

Now, any request made with an email address in it will no longer be logged.

## {{site.ai_gateway}} logs

{{site.base_gateway}} collects logs for the [{{site.ai_gateway}} plugins](/plugins/?category=ai). This allows you to aggregate AI usage analytics across various providers.

Each log entry includes the following details:

<!--vale off-->
{% table %}
columns:
  - title: Property
    key: property
  - title: Description
    key: description
rows:
  - property: "`ai.$PLUGIN_NAME.payload.request`"
    description: The request payload.
  - property: "`ai.$PLUGIN_NAME.payload.response`"
    description: The response payload.
  - property: "`ai.$PLUGIN_NAME.usage.prompt_token`"
    description: The number of tokens used for prompting.
  - property: "`ai.$PLUGIN_NAME.usage.completion_token`"
    description: The number of tokens used for completion.
  - property: "`ai.$PLUGIN_NAME.usage.total_tokens`"
    description: The total number of tokens used.
  - property: "`ai.$PLUGIN_NAME.usage.cost`"
    description: The total cost of the request (input and output cost).
  - property: "`ai.$PLUGIN_NAME.usage.time_per_token`"
    description: |
      {% new_in 3.8 %} The average time to generate an output token, in milliseconds.
  - property: "`ai.$PLUGIN_NAME.meta.request_model`"
    description:  The model used for the AI request.
  - property: "`ai.$PLUGIN_NAME.meta.provider_name`"
    description:  The name of the AI service provider.
  - property: "`ai.$PLUGIN_NAME.meta.response_model`"
    description:  The model used for the AI response.
  - property: "`ai.$PLUGIN_NAME.meta.plugin_id`"
    description:  The unique identifier of the plugin.
  - property: "`ai.$PLUGIN_NAME.meta.llm_latency`"
    description: |
      {% new_in 3.8 %} The time, in milliseconds, it took the LLM provider to generate the full response.
  - property: "`ai.$PLUGIN_NAME.cache.cache_status`"
    description: |
      {% new_in 3.8 %} The cache status. This can be `Hit`, `Miss`, `Bypass` or `Refresh`.
  - property: "`ai.$PLUGIN_NAME.cache.fetch_latency`"
    description: |
      {% new_in 3.8 %} The time, in milliseconds, it took to return a cache response.
  - property: "`ai.$PLUGIN_NAME.cache.embeddings_provider`"
    description: |
      {% new_in 3.8 %} For semantic caching, the provider used to generate the embeddings.
  - property: "`ai.$PLUGIN_NAME.cache.embeddings_model`"
    description: |
      {% new_in 3.8 %} For semantic caching, the model used to generate the embeddings.
  - property: "`ai.$PLUGIN_NAME.cache.embeddings_latency`"
    description: |
      {% new_in 3.8 %} For semantic caching, the time taken to generate the embeddings.{% endtable %}
<!--vale on-->

<!--
## Next steps
* [Debug {{site.base_gateway}} with logs](/gateway/debug/)
-->
