---
title: Object defaults reference

description: "{{site.base_gateway}} sets some default values for most objects, including Kong plugins."

content_type: reference
layout: reference

works_on:
    - on-prem
    - konnect

products:
  - api-ops

tools:
  - deck

related_resources:
  - text: Customize decK object defaults
    url:  /how-to/custom-deck-object-defaults

breadcrumbs:
  - /deck/
---

{{ page.description }} You can see what the defaults are for each object in the
[Admin API reference](https://docs.konghq.com/gateway/latest/admin-api/), or use the
[`/schemas`](#find-defaults-for-an-object) endpoint to
check the latest object schemas for your instance of the {{site.base_gateway}}.

decK recognizes value defaults and doesn't interpret them as changes to
configuration. If you push a config for an object to {{site.base_gateway}} with
`sync`, {{site.base_gateway}} applies its default values to the object,
but a further `diff` or `sync` does not show any changes.

If you upgrade {{site.base_gateway}} to a version that introduces a new
property with a default value, a `diff` will catch the difference.

You can also configure your own [custom defaults](#set-custom-defaults) to
enforce a set of standard values and avoid repetition in your configuration.

## Value order of precedence

decK assigns values in the following order of precedence, from highest to lowest:

1. Values set for a specific instance of an object in the state file
(for example, for a service named `example_service` defined in `kong.yml`).
2. Values set in the `{_info: defaults:}` object in the state file.
3. Self-managed {{site.base_gateway}} only: Values are checked against the Kong
Admin API schemas.
4. {{site.konnect_short_name}} Cloud only: Values are checked against the Kong Admin API for plugins,
and against hardcoded defaults for Service, Route, Upstream, and Target objects.

## Find defaults for an object

{{site.base_gateway}} defines all the defaults it applies in object schema files.
Check the schemas to find the most up-to-date default values for an object.

If you want to completely avoid differences between the configuration file and
the {{site.base_gateway}}, set all possible default values for an object in your
`kong.yaml` file.

{% navtabs %}
{% navtab "Route" %}

Use the Kong Admin API `/schemas` endpoint to find default values:

```sh
curl -i http://localhost:8001/schemas/routes
```

In your `kong.yaml` file, set the default values you want to use across all Routes.
For example:

```yaml
_info:
  defaults:
    route:
      https_redirect_status_code: 426
      path_handling: v0
      preserve_host: false
      protocols:
      - http
      - https
      regex_priority: 0
      request_buffering: true
      response_buffering: true
      strip_path: true
```

{:.note}
> **Note:** If the Route protocols include `grpc` and `grpcs`, the `strip_path`
schema value must be `false`. If set to `true`, deck returns a schema
violation error.

For documentation on all available properties, see the
[Route object](/api/gateway/admin-ee/#/operations/list-route/) documentation.

{% endnavtab %}
{% navtab "Service" %}

Use the Kong Admin API `/schemas` endpoint to find default values:

```sh
curl -i http://localhost:8001/schemas/services
```

In your `kong.yaml` file, set the default values you want to use across all
Services. For example:

```yaml
_info:
  defaults:
    service:
      port: 80
      protocol: http
      connect_timeout: 60000
      write_timeout: 60000
      read_timeout: 60000
      retries: 5
```

For documentation on all available properties, see the
[Service object](/api/gateway/admin-ee/#/operations/list-service) documentation.

{% endnavtab %}
{% navtab "Upstream" %}

Use the Kong Admin API `/schemas` endpoint to find default values:

```sh
curl -i http://localhost:8001/schemas/upstreams
```

In your `kong.yaml` file, set the default values you want to use across all
Upstreams. For example:

```yaml
_info:
  defaults:
    upstream:
      slots: 10000
      algorithm: round-robin
      hash_fallback: none
      hash_on: none
      hash_on_cookie_path: /
      healthchecks:
        active:
          concurrency: 10
          healthy:
            http_statuses:
            - 200
            - 302
            interval: 0
            successes: 0
          http_path: /
          https_verify_certificate: true
          timeout: 1
          type: http
          unhealthy:
            http_failures: 0
            http_statuses:
            - 429
            - 404
            - 500
            - 501
            - 502
            - 503
            - 504
            - 505
            interval: 0
            tcp_failures: 0
            timeouts: 0
        passive:
          healthy:
            http_statuses:
            - 200
            - 201
            - 202
            - 203
            - 204
            - 205
            - 206
            - 207
            - 208
            - 226
            - 300
            - 301
            - 302
            - 303
            - 304
            - 305
            - 306
            - 307
            - 308
            successes: 0
          type: http
          unhealthy:
            http_failures: 0
            http_statuses:
              - 429
              - 500
              - 503
            tcp_failures: 0
            timeouts: 0
        threshold: 0
```

For documentation on all available properties, see the
[Upstream object](/api/gateway/admin-ee/#/operations/list-upstream/) documentation.

{% endnavtab %}
{% navtab "Target" %}

Use the Kong Admin API `/schemas` endpoint to find default values:

```sh
curl -i http://localhost:8001/schemas/targets
```

In your `kong.yaml` file, set the default values you want to use across all
Targets. For example:

```yaml
_info:
  defaults:
    target:
      weight: 100
```
For all available properties, see the
[Target object](/api/gateway/admin-ee/#/operations/list-target-with-upstream/) documentation.

{% endnavtab %}
{% navtab "Plugins" %}

Use the Kong Admin API `/schemas` endpoint to find default values:

```sh
curl -i http://localhost:8001/schemas/plugins/<plugin-name>
```

decK doesn't support setting custom default values for the plugin object.

{% endnavtab %}
{% endnavtabs %}
