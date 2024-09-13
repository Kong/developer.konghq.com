---
title: decK object defaults reference

works_on:
    - on-prem
    - konnect

tags:
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
---


You can set custom configuration defaults for the following core
{{site.base_gateway}} objects:
- Service
- Route
- Upstream
- Target

Default values get applied to both new and existing objects. See the
[order of precedence](#value-order-of-precedence) for more detail on how they
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

1. In your `kong.yaml` configuration file, add an `_info` section with
`defaults`:

   ```yaml
   _format_version: "3.0"
   _info:
     defaults:
   services:
     - host: httpbin.org
       name: example_service
       routes:
         - name: mockpath
           paths:
             - /mock
   ```

    {:.note}
    > For production use in larger systems, we recommend that you break out
    your defaults into a [separate `defaults.yaml` file](/deck/{{page.release}}/guides/multi-file-state/)
    or use [tags](/deck/{{page.release}}/guides/distributed-configuration/)
    to apply the defaults wherever they are needed.

1. Define the properties you want to set for {{site.base_gateway}} objects.

    You can define custom defaults for `service`, `route`, `upstream`, and
    `target` objects.

    For example, you could define default values for a few fields of the
    Service object:

   ```yaml
   _format_version: "3.0"
   _info:
     defaults:
       service:
         port: 8080
         protocol: https
         retries: 10
   services:
     - host: httpbin.org
       name: example_service
       routes:
         - name: mockpath
           paths:
             - /mock
   ```

    Or you could define custom default values for all available fields:

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
   services:
     - host: httpbin.org
       name: example_service
       routes:
         - name: mockpath
           paths:
             - /mock
   ```

1. Sync your changes with {{site.base_gateway}}:

    ```sh
    deck gateway sync kong.yaml
    ```

1.  Run a diff and note the response:

    ```sh
    deck gateway diff kong.yaml
    ```
    Response:
    ```sh
    Summary:
    Created: 0
    Updated: 0
    Deleted: 0
    ```

    Whether you choose to define a subset of custom defaults or all available
    options, the result is the same: the diff doesn't show any changes.
