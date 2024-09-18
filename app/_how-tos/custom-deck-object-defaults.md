---
title: Customize object defaults in decK

works_on:
    - on-prem
    - konnect

product:
  - api-ops

tools:
  - deck

related_resources:
  - text: decK object defaults reference
    url:  /deck/object-defaults

tldr:
  q: |
    How do I set custom default values for Kong Gateway entities?
  a: |
    You can configure your own custom Kong Gateway defaults via decK to
    enforce a set of standard values and avoid repetition in your configuration.

prereqs:
  entities:
    services:
        - example-service
---


You can set custom configuration defaults for the following core
{{site.base_gateway}} objects:
- Service
- Route
- Upstream
- Target

Default values get applied to both new and existing objects. See the
[order of precedence](/deck/object-defaults/#value-order-of-precedence) for more detail on how they
get applied.

You can choose to define custom default values for any subset of entity fields,
or define all of them. decK still finds the default values using a
combination of your defined fields and the object's schema, based on the
order of precedence.

decK supports setting custom object defaults both in self-managed
{{site.base_gateway}} and with {{site.konnect_saas}}.

{:.important}
> **Important:** This feature has the following limitations:
* Custom plugin object defaults are not supported.
* If an existing property's default value changes in a future {{site.base_gateway}} release,
decK has no way of knowing that this change has occurred, as its `defaults`
configuration would overwrite the value in your environment.

## 1. Define default properties

Define the properties you want to customize for {{site.base_gateway}} objects.
See the [object defaults reference](/deck/object-defaults) for all configurable objects and default values.

In the `deck_files` directory you created in the [prerequisites](#prerequisites), create a `defaults.yaml` file
and add an `_info` section with `defaults`. 
You can define a few select properties for a supported entity, such as a service:

```yaml
_format_version: "3.0"
_info:
  defaults:
    service:
      port: 8080
      protocol: https
      retries: 10
```
{: data-file="defaults.yaml" }

Or you could define custom default values for all available fields of a service and a route:

```yaml
_format_version: "3.0"
_info:
  defaults:
    route:
      https_redirect_status_code: 426
      path_handling: v1
      preserve_host: false
      protocols:
      - http
      - https
      regex_priority: 0
      request_buffering: true
      response_buffering: true
      strip_path: true
    service:
      port: 8080
      protocol: https
      connect_timeout: 60000
      write_timeout: 60000
      read_timeout: 60000
      retries: 10
```
{: data-file="defaults.yaml" }

## 2. Validate

Sync your changes with {{site.base_gateway}}:

```sh
deck gateway sync kong.yaml
```

Response:
```sh
Summary:
Created: 0
Updated: 0
Deleted: 0
```

Whether you choose to define a subset of custom defaults or all available
options, the result is the same: the diff summary doesn't show any changes, 
because no entities have actually changed in the database.
