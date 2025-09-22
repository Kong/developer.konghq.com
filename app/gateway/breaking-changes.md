---
title: "{{site.base_gateway}} breaking changes and known issues"
content_type: reference
layout: reference
breadcrumbs:
  - /gateway/
products:
    - gateway

works_on:
    - on-prem

tags:
    - upgrades
    - versioning



description: "Review {{site.base_gateway}} version breaking changes before upgrading."

related_resources:
  - text: Upgrading {{site.base_gateway}}
    url: /gateway/upgrade/
  - text: "{{site.base_gateway}} Version Support"
    url: /gateway/version-support-policy/
  - text: "{{site.base_gateway}} changelog"
    url: /gateway/changelog/
---

Before upgrading, review any configuration or breaking changes in the version you're upgrading to and prior versions that
affect your current installation.

You may need to adopt different [upgrade paths](/gateway/upgrade/) depending on your
deployment methods, set of features in use, or custom plugins, for example.

## 3.11.x breaking changes

Review the [changelog](/gateway/changelog/#31100) for all the changes in this release.

### 3.11.0.0

Breaking changes in the 3.11.0.0 release.

#### AI proxy plugins: preserve route type deprecation

The route type `preserve` has been deprecated and will be removed in a future version. To avoid issues, switch to a route type added in version 3.11.0.0 or later.
* [`route_type` options for AI Proxy](/plugins/ai-proxy/reference/#schema--config-route-type)
* [`route_type` options for AI Proxy Advanced](/plugins/ai-proxy-advanced/reference/#schema--config-route-type)

#### WASM deprecation

Support for the beta WASM module has been removed. To use Datakit, see the [Datakit plugin changes](#datakit-plugin).

#### Datakit plugin

The [Datakit plugin](/plugins/datakit/), which previously required WASM to run, is now bundled as a Kong Lua plugin.
Starting in 3.11.0.0, you don't need to enable WASM to run Datakit; you can enable it just like any other bundled plugin.

The Datakit plugin no longer supports the `handlebars` node type.

#### Known issues in 3.11.0.0

The following is a list of known issues in 3.11.0.0 that may be fixed in a future release.

{% table %}
columns:
  - title: Known issue
    key: issue
  - title: Description
    key: description
  - title: Status
    key: status
rows:
  - issue: AI Gateway license migration
    description: |
      If any [AI Gateway plugin](/plugins/?category=ai) has been enabled in a self-managed {{site.base_gateway}} deployment for more than a week, 
      upgrades from 3.10 versions to 3.11.0.0 will fail due to a license migration issue. This does not affect {{site.konnect_short_name}} deployments.
      <br><br>
      We recommend upgrading to 3.11.0.1 to fix this issue. If needed, you can use the following temporary workaround:
      <br><br>
      1. On your {{site.base_gateway}} machine or in its container, create a file named `reset_license_llm_data.lua` with the following contents:
         <br><br>
         ```lua
         local connector = kong.db.connector
         local query = [[
           TRUNCATE TABLE "public"."license_llm_data";
         ]]

         local res = connector:query(query)
         print(require("pl.pretty").write({res}))
         ```
      2. Run the following CLI command to clean up the LLM usage data stored in the database:
          <br><br>
         ```sh
         kong runner reset_license_llm_data.lua
         ```
      3. Run `kong migrations up`.
      4. Run `kong migrations finish`.
    status: Fixed in 3.11.0.1
  - issue: Incremental config sync doesn't work in stream mode
    description: |
      When running in incremental sync mode ([`incremental_sync=on`](/gateway/configuration/#incremental-sync)), {{site.base_gateway}} can't apply configuration deltas to the stream subsystem. 
      This issue affects versions 3.10.0.0 and above, where incremental sync is enabled alongside stream proxying ([`stream_listen`](/gateway/configuration/#stream-listen)). 
      <br><br>
      The HTTP subsystem is not affected.
      <br><br>
      **Workaround**: 
      * Incremental config sync is `off` by default. If you haven't enabled incremental config sync, there is no action required.
      * If you are using stream proxying and incremental config sync, disable incremental sync by setting `incremental_sync=off`. 
    status: Fixed in 3.11.0.3
  - issue: Brotli module missing from ARM64 {{site.base_gateway}} Docker images
    description: |
      The Brotli module is missing from all the following ARM64 {{site.base_gateway}} Docker images:
      * RHEL 9
      * Debian 12
      * Amazon Linux 2
      * Amazon Linux 2023

      There is no workaround for this issue.
    status: Not fixed
{% endtable %}

## 3.10.x breaking changes

Review the [changelog](/gateway/changelog/#31000) for all the changes in this release.

### 3.10.0.0

Breaking changes in the 3.10.0.0 release.

#### AI plugins: metrics key

The serialized log key of AI metrics has changed from `ai.ai-proxy` to `ai.proxy` to avoid conflicts with metrics generated from plugins other than AI Proxy and AI Proxy Advanced.
If you are using any [logging plugins](/plugins/?category=logging) to log AI metrics (for example, File Log, HTTP Log, and so on),
you will have to update metrics pipeline configurations to reflect this change.

#### AI plugins: deprecated settings

The following settings have been deprecated in all [AI plugins](/plugins/?category=ai), and will be removed in a future release.
Use the following replacement settings instead:

{% table %}
columns:
  - title: Deprecated setting
    key: deprecated
  - title: New setting
    key: new
rows:
  - deprecated: "`preserve` mode in `config.route_type`"
    new: "`config.llm_format`"
  - deprecated: "`config.model.options.upstream_path`"
    new: "`config.model.options.upstream_url`"
{% endtable %}

#### AI Rate Limiting Advanced plugin: multiple providers and limits

The plugin's `config.llm_providers.window_size` and `config.llm_providers.limit` parameters now require an array of numbers instead of a single number.
If you configured the plugin before 3.10 and [upgrade to 3.10 using `kong migrations`](/gateway/upgrade/), it will be automatically migrated to use an array.

#### kong.service PDK module changes

Changed the encoding of spaces in query arguments from `+` to `%20` in the `kong.service.request.clear_query_arg` PDK module.
While the `+` character represents the correct encoding of space in query strings, Kong uses `%20` in many other APIs, which is inherited from Nginx/OpenResty.

#### Free mode

Free mode is no longer available. Running {{site.base_gateway}} without a license will now behave the same as running it with an expired license.

#### Known issues in 3.10.0.0

The following is a list of known issues in 3.10.x that may be fixed in a future release.

{% table %}
columns:
  - title: Known issue
    key: issue
  - title: Description
    key: description
  - title: Status
    key: status
rows:
  - issue: Incremental config sync doesn't work in stream mode
    description: |
      When running in incremental sync mode ([`incremental_sync=on](/gateway/configuration/#incremental-sync)`), {{site.base_gateway}} can't apply configuration deltas to the stream subsystem. 
      This issue affects versions 3.10.0.0 and above, where incremental sync is enabled alongside stream proxying ([`stream_listen`](/gateway/configuration/#stream-listen)). 
      <br><br>
      The HTTP subsystem is not affected.
      <br><br>
      **Workaround**: 
      * Incremental config sync is `off` by default. If you haven't enabled incremental config sync, there is no action required.
      * If you are using stream proxying and incremental config sync, disable incremental sync by setting `incremental_sync=off`. 
    status: Not fixed
  - issue: Brotli module missing from ARM64 {{site.base_gateway}} Docker images
    description: |
      The Brotli module is missing from all the following ARM64 {{site.base_gateway}} Docker images:
      * RHEL 9
      * Debian 12
      * Amazon Linux 2
      * Amazon Linux 2023

      There is no workaround for this issue.
    status: Not fixed
{% endtable %}

## 3.9.x breaking changes

Review the [changelog](/gateway/changelog/#3900) for all the changes in this release.

### 3.9.0.0

Breaking changes in the 3.9.0.0 release.

#### Node ID deprecation in `kong.conf`

Manually specifying a `node_id` via Kong configuration (`kong.conf`) is deprecated.
The `node_id` parameter is planned to be removed in 4.x.

#### AI Rate Limiting advanced plugin

This release adds support for the Hugging Face provider.

To import the decK configuration files that are exported from the 3.9.x series to earlier versions of {{site.base_gateway}}, use the following script to transform it so that the configuration file can be compatible with the latest version:

```
yq -i '(
.plugins[] | select(.name == "ai-rate-limiting-advanced") | .config.llm_providers[] | select(.name == "huggingface") | .name
) |= "requestPrompt" |
(
.consumers[] | .plugins[] | select(.name == "ai-rate-limiting-advanced") | .config.llm_providers[] | select(.name == "huggingface") | .name
) |= "requestPrompt" |
(
.consumer_groups[] | .plugins[] | select(.name == "ai-rate-limiting-advanced") | .config.llm_providers[] | select(.name == "huggingface") | .name
) |= "requestPrompt"
' config.yaml
```

#### Known issues in 3.9.0.0

The following is a list of known issues in 3.9.x that may be fixed in a future release.

{% table %}
columns:
  - title: Known issue
    key: issue
  - title: Description
    key: description
  - title: Status
    key: status
rows:
  - issue: Brotli module missing from ARM64 {{site.base_gateway}} Docker images
    description: |
      The Brotli module is missing from all the following ARM64 {{site.base_gateway}} Docker images:
      * RHEL 9
      * Debian 12
      * Amazon Linux 2
      * Amazon Linux 2023

      There is no workaround for this issue.
    status: Not fixed
{% endtable %}


## 3.8.x breaking changes

Review the [changelog](/gateway/changelog/#3800) for all the changes in this release.

### 3.8.0.0

Breaking changes in the 3.8.0.0 release.

#### `kong.logrotate` configuration file no longer overwritten during upgrade

The `kong.logrotate` configuration file will no longer be overwritten during upgrade.
When upgrading, set the environment variable `DEBIAN_FRONTEND=noninteractive` on Debian/Ubuntu to avoid any interactive prompts and enable fully automatic upgrades.

#### `log_statistics` defaults to `false` for AI Proxy

A configuration validation was added to the [AI Proxy plugin](/plugins/ai-proxy/) to prevent users from enabling `log_statistics` for
providers that don't support statistics. In addition, the default of `log_statistics` was changed from
`true` to `false`, and a database migration is added as well for disabling `log_statistics` if it
has already been enabled upon unsupported providers.

#### Custom plugins that used shared Redis config

In 3.8.0.0, Kong has changed and refactored the shared Redis configuration that previously was imported by `require "kong.enterprise_edition.redis"`. If you created a custom plugin that is using this shared configuration or if you have a forked version of a plugin, like `rate-limiting-advanced`, then you might need to do additional steps before you can upgrade to the new version of this Redis config.

Out of the box, custom plugins should still work since the old shared configuration is still available. The new config adds the `cluster_max_redirections` option for Redis Cluster, and the `cluster_nodes` format and `sentinel_nodes` were changed. Other than that, the initialization step is no longer required.

#### Upgrade custom plugins using a shared Redis config

If your plugin is using a shared Redis config (for example, if you import `require "kong.enterprise_edition.redis"`) you must do the following:

1. Remove the `redis.init_conf(conf)` library initialization call.
    Where `redis` is `local redis = require "kong.enterprise_edition.redis"`.
1. Switch the imports of redis from `local redis = require "kong.enterprise_edition.redis"` to `local redis = require "kong.enterprise_edition.tools.redis.v2"`.

#### Upgrade custom plugins using the rate limiting library

If your plugin is using rate limiting library (as in you import `local ratelimiting = require("kong.tools.public.rate-limiting").new_instance("your-plugin-name")`) you must switch the imports of the following:

* *Shared Redis config:* Change `local redis = require "kong.enterprise_edition.redis"` to `local redis = require "kong.enterprise_edition.tools.redis.v2"`
* *Rate limiting library:* Change `local ratelimiting = require("kong.tools.public.rate-limiting").new_instance("your-plugin-name")` to `local ratelimiting = require("kong.tools.public.rate-limiting").new_instance("your-plugin-name", { redis_config_version = "v2" })`

#### Deprecated `sentinel_addresses` and `cluster_addresses` for Redis

The following plugins switched `cluster_addresses` to `cluster_nodes` and `sentinel_addresses` to `sentinel_nodes` for Redis configuration:

* [AI Rate Limiting Advanced](/plugins/ai-rate-limiting-advanced/)
* [GraphQL Proxy Caching Advanced](/plugins/graphql-proxy-cache-advanced/)
* [GraphQL Rate Limiting Advanced](/plugins/graphql-rate-limiting-advanced/)
* [Proxy Caching Advanced](/plugins/proxy-cache-advanced/)
* [Rate Limiting Advanced](/plugins/rate-limiting-advanced/)

These fields are converted automatically when you run `kong migrations up`. Also, any changes uploaded via decK or the Admin API using the old `cluster_addresses` and `sentinel_addresses` are respected and properly translated to the new fields.

Forked custom plugins aren't automatically migrated. For more information about how to migrate custom plugins, see [Custom plugins that used shared Redis config](#custom-plugins-that-used-shared-redis-config).

#### Known issues in 3.8.0.0

The following is a list of known issues in 3.8.x that may be fixed in a future release.

{% table %}
columns:
  - title: Known issue
    key: issue
  - title: Description
    key: description
  - title: Status
    key: status
rows:
  - issue: Brotli module missing from ARM64 {{site.base_gateway}} Docker images
    description: |
      The Brotli module is missing from all the following ARM64 {{site.base_gateway}} Docker images:
      * RHEL 9
      * Debian 12
      * Amazon Linux 2
      * Amazon Linux 2023

      There is no workaround for this issue.
    status: Not fixed
{% endtable %}

## 3.7.x breaking changes

Review the [changelog](/gateway/changelog/#3700) for all the changes in this release.

### 3.7.0.0

Breaking changes in the 3.7.0.0 release.

#### Configuration

The Granular Tracing feature has been deprecated and removed from {{site.base_gateway}}.

As part of your upgrade to 3.7, remove the following tracing-related parameters from your `kong.conf` file:

* `tracing`
* `tracing_write_strategy`
* `tracing_write_endpoint`
* `tracing_time_threshold`
* `tracing_types`
* `tracing_debug_header`
* `generate_trace_details`

We recommend transitioning to OpenTelemetry Instrumentation instead.

#### Vaults

There are some changes to the configuration of the [HashiCorp Vault entity](/how-to/configure-hashicorp-vault-as-a-vault-backend/).
Starting from this version, a string entirely made of spaces can't be specified as the `role_id` or `secret_id`
value in the HashiCorp Vault entity when using the AppRole authentication method.

Additionally, you must specify at least one of `secret_id` or `secret_id_file` in the HashiCorp Vault
entity when using the AppRole authentication method.

#### Plugin changes

[**AI Proxy**](/plugins/ai-proxy/) (`ai-proxy`): To support the new messages API of `Anthropic`, the upstream
path of the `anthropic` setting for the `llm/v1/chat` Route type has changed from `/v1/complete` to `/v1/messages`.

#### Known issues in 3.7.0.0

The following is a list of known issues in 3.7.x that may be fixed in a future release.

{% table %}
columns:
  - title: Known issue
    key: issue
  - title: Description
    key: description
  - title: Status
    key: status
rows:
  - issue: Brotli module missing from ARM64 {{site.base_gateway}} Docker images
    description: |
      The Brotli module is missing from all the following ARM64 {{site.base_gateway}} Docker images:
      * RHEL 9
      * Debian 12
      * Amazon Linux 2
      * Amazon Linux 2023

      There is no workaround for this issue.
    status: Not fixed
{% endtable %}

## 3.6.x breaking changes

Review the [changelog](/gateway/changelog/#3600) for all the changes in this release.

### 3.6.1.0

Breaking changes in the 3.6.1.0 release.

#### TLS changes

TLSv1.1 and lower is now disabled by default in OpenSSL 3.x.

### 3.6.0.0

Breaking changes in the 3.6.0.0 release.

#### General

If you are using `ngx.var.http_*` in custom code to access HTTP headers, the behavior of that variable changed slightly when the same header is used multiple times in a single request. Previously, it would return the first value only; now it returns all the values, separated by commas. {{site.base_gateway}}'s PDK header getters and setters work as before.

#### Wasm

To avoid ambiguity with other Wasm-related `nginx.conf` directives, the prefix for Wasm `shm_kv` nginx.conf directives was changed from `nginx_wasm_shm_` to `nginx_wasm_shm_kv_`.
 [#11919](https://github.com/Kong/kong/issues/11919)

#### Admin API

The listing endpoints for Consumer Groups (`/consumer_groups`) and Consumers (`/consumers`) now respond
with paginated results. The JSON key for the list has been changed to `data` instead of `consumer_groups`
or `consumers`.

#### Configuration changes

The default value of the [`dns_no_sync`](/gateway/configuration/#dns-no-sync) option has been changed to `off`.

#### TLS changes

The recent OpenResty bump includes TLS 1.3 and deprecates TLS 1.1.
If you still need to support TLS 1.1, set the [`ssl_cipher_suite`](/gateway/configuration/#ssl-cipher-suite) setting to `old`.

In OpenSSL 3.2, the default SSL/TLS security level has been changed from 1 to 2.
This means the security level is set to 112 bits of security.
As a result, the following are prohibited:
* RSA, DSA, and DH keys shorter than 2048 bits
* ECC keys shorter than 224 bits
* Any cipher suite using RC4
* SSL version 3
Additionally, compression is disabled.

#### Kong Manager Enterprise

As of {{site.base_gateway}} 3.6, Kong Manager uses the session management mechanism in the OpenID Connect plugin.
`admin_gui_session_conf` is no longer required when authenticating with OIDC. Instead, session-related
configuration parameters are set in `admin_gui_auth_conf` (like `session_secret`).

See the [migration FAQ](/gateway/kong-manager/openid-connect/#migrate-oidc-configuration-from-older-versions) for more information.

#### Plugin changes

* [**ACME**](/plugins/acme/) (`acme`), [**Rate Limiting**](/plugins/rate-limiting/) (`rate-limiting`), and [**Response Rate Limiting**](/plugins/response-ratelimiting/) (`response-ratelimiting`)
  * Standardized Redis configuration across plugins. The Redis configuration now follows a common schema that is shared across other plugins.
  [#12300](https://github.com/Kong/kong/issues/12300)  [#12301](https://github.com/Kong/kong/issues/12301)

* [**Azure Functions**](/plugins/azure-functions/) (`azure-functions`):
  * The Azure Functions plugin now eliminates the upstream/request URI and only uses the [`routeprefix`](/plugins/azure-functions/reference/#config-routeprefix)
configuration field to construct the request path when requesting the Azure API.

* [**OAS Validation**](/plugins/oas-validation/) (`oas-validation`)
  * The plugin now bypasses schema validation when the content type is not `application/json`.

* [**Proxy Cache Advanced**](/plugins/proxy-cache-advanced/) (`proxy-cache-advanced`)
  * Removed the undesired `proxy-cache-advanced/migrations/001_035_to_050.lua` file, which blocked migration from OSS to Enterprise.
    This is a breaking change only if you are upgrading from a {{site.base_gateway}} version between `0.3.5` and `0.5.0`.

* [**SAML**](/plugins/saml) (`saml`)
  * Adjusted the priority of the SAML plugin to 1010 to correct the integration between the SAML plugin and other Consumer-based plugins.

#### Known issues in 3.6.0.0

The following is a list of known issues in 3.6.x that may be fixed in a future release.

{% table %}
columns:
  - title: Known issue
    key: issue
  - title: Description
    key: description
  - title: Status
    key: status
rows:
  - issue: Operating system requirements
    description: |
      {{site.base_gateway}} 3.6.0.0 requires a higher limit on the number of file descriptions to
      function properly. It will not start properly with a limit set to 1024 or lower. We
      recommend using `ulimit` on your operating system to set it to at least 4096 using
      `ulimit -n 4096`.
    status: |
      *Issue fixed in 3.6.1.0*:
      <br><br>
      Although a higher limit on file descriptors (`uname -n`) is recommended in general for
      {{site.base_gateway}}, you can upgrade to 3.6.1.0 to start with a default of 1024 again.
  - issue: HTTP/2 requires Content-Length for plugins that read request body
    description: |
      Kong 3.6.x has introduced a regression for plugins that read the body of incoming requests.
      Clients must specify a `Content-Length` header that represents the length of the request body.
      Not including this header, or relying on `Transfer-Encoding: chunked` will result in an HTTP response with the error code 500.
      <br><br>
      Currently known affected plugins:
      <br><br>
      * [jq](/plugins/jq/)
      * [Request Size Limiting](/plugins/request-size-limiting/)
      * [Request Validator](/plugins/request-validator/)
      * [AI Request Transformer](/plugins/ai-request-transformer/)
      * [Request Transformer](/plugins/request-transformer/)
      * [Request Transformer Advanced](/plugins/request-transformer-advanced/)
    status: |
      *Issue fixed in 3.6.1.1*:
      <br><br>
      Reverted the hard-coded limitation of the `ngx.read_body()` API in OpenResty upstreams’ new versions when downstream connections are in HTTP/2 or HTTP/3 stream modes.
  - issue: Brotli module missing from ARM64 {{site.base_gateway}} Docker images
    description: |
      The Brotli module is missing from all the following ARM64 {{site.base_gateway}} Docker images:
      * RHEL 9
      * Debian 12
      * Amazon Linux 2
      * Amazon Linux 2023

      There is no workaround for this issue.
    status: Not fixed
{% endtable %}

## 3.5.x breaking changes

### 3.5.0.2

Breaking changes in the 3.5.0.2 release.

#### Configuration changes

The default value of the [`dns_no_sync`](/gateway/configuration/#dns-no-sync) has been changed to `off`.

### 3.5.0.0

Breaking changes in the 3.5.0.0 release.

#### Dev Portal and Vitals

<!--vale off-->
As of this release, the product component known as Kong Enterprise Portal is no longer included in the {{site.ee_product_name}} (previously known as Kong Enterprise) software package. Existing customers who have purchased Kong Enterprise Portal can continue to use it and be supported via a dedicated mechanism.

In addition, the product component known as Vitals is no longer included in {{site.ee_product_name}}.
Existing customers who have purchased Kong Vitals can continue to use it and be supported via a dedicated mechanism.
{{site.konnect_product_name}} users can take advantage of our [API Analytics](/advanced-analytics/) offering, which provides a superset of Vitals functionality.

If you have purchased Kong Enterprise Portal or Vitals in the past and would like to continue to use it with this release or a future release of {{site.ee_product_name}}, contact [Kong Support](https://support.konghq.com/support/s/) for more information.
<!--vale on-->

#### Plugin Changes

{{site.base_gateway}} now requires an Enterprise license to use dynamic plugin ordering.

#### Session Plugin

{{site.base_gateway}} 3.5.x introduced the new configuration field `read_body_for_logout` with a default value of `false`.
This change alters the behavior of `logout_post_arg` in such a way that it is no longer considered, unless `read_body_for_logout` is explicitly set to `true`.
This adjustment prevents the Session plugin from automatically reading request bodies for logout detection, particularly on POST requests.

#### Configuration changes

The default value of the [`dns_no_sync`](/gateway/configuration/#dns-no-sync) option has been changed to `on` for 3.5.0.0 and 3.5.0.1.
As of 3.5.0.2, the default value has been changed to `off`.


## 3.4.x breaking changes

### 3.4.3.5

Breaking changes in the 3.4.3.5 release.

#### TLS changes

In OpenSSL 3.2, the default SSL/TLS security level has been changed from 1 to 2.
This means the security level is set to 112 bits of security.
As a result, the following are prohibited:
* RSA, DSA, and DH keys shorter than 2048 bits
* ECC keys shorter than 224 bits
* Any cipher suite using RC4
* SSL version 3
Additionally, compression is disabled.

### 3.4.0.0

Breaking changes in the 3.4.0.0 release.

#### Amazon Linux 2022 to 2023 rename

Amazon Linux 2022 artifacts are renamed to Amazon Linux 2023, based on AWS's own renaming.

#### Alpine support removed

Alpine packages and Docker images based on Alpine are no longer supported.
Starting with {{site.base_gateway}} 3.4.0.0, Kong is not building new Alpine images or packages.

#### Ubuntu 18.04 support removed

Support for running {{site.base_gateway}} on Ubuntu 18.04 ("Bionic") is now deprecated,
as [Standard Support for Ubuntu 18.04 has ended as of June 2023](https://wiki.ubuntu.com/Releases).
Starting with {{site.base_gateway}} 3.4.0.0, Kong is not building new Ubuntu 18.04
images or packages, and Kong will not test package installation on Ubuntu 18.04.

If you need to install {{site.base_gateway}} on Ubuntu 18.04, see the documentation for
previous versions.

#### Cassandra DB support removed

Cassandra DB support has been removed. It is no longer supported as a data store for {{site.base_gateway}}.

You can migrate from Cassandra DB to PostgreSQL by following the [migration guide](https://legacy-gateway--kongdocs.netlify.app/),
or reach out to your support representative for help.

#### Configuration changes

The following is a list of changes in `kong.conf` in this release.

{% table %}
columns:
  - title: Item
    key: item
  - title: Recommended action
    key: action
rows:
  - item: |
      LMDB encryption has been disabled.
      <br><br>
      The parameter `declarative_config_encryption_mode` has been removed from `kong.conf`.
    action: No action needed.
  - item: |
      Renamed the configuration property `admin_api_uri` to `admin_gui_api_url`.
      The old `admin_api_uri` property is considered deprecated and will be fully removed in a future version of {{site.base_gateway}}.
    action: |
      Update your configuration to use `admin_gui_api_url`.
  - item: |
      The `database` parameter no longer accepts `cassandra` as an option.
      <br><br>
      All Cassandra options have been removed.
    action: |
      If you use Cassandra DB, either migrate to PostgreSQL (`postgres`) or DB-less mode (`off`).
{% endtable %}

#### Admin API changes

The `/consumer_groups/:id/overrides` endpoint is deprecated in favor of a more generic plugin scoping mechanism.
See the new [Consumer Groups](/gateway/entities/consumer-group/) entity.

#### Plugin queues

Validation for plugin queue related parameters has been improved. Certain parameters now have stricter requirements.
* `max_batch_size`, `max_entries`, and `max_bytes` are now declared as `integer` instead of `number`.
* `initial_retry_delay` and `max_retry_delay` must now be numbers greater than 0.001 (in seconds).

This affects the following plugins:
  * [HTTP Log](/plugins/http-log/)
  * [StatsD](/plugins/statsd/)
  * [OpenTelemetry](/plugins/opentelemetry/)
  * [Datadog](/plugins/datadog/)
  * [Zipkin](/plugins/zipkin/)

#### Rate Limiting Advanced plugin

The `/consumer_groups/:id/overrides` endpoint has been deprecated. While this endpoint will still function, we strongly recommend transitioning to the new and improved method for managing Consumer Groups, as documented in the [Enforcing rate limiting tiers with the Rate Limiting Advanced plugin](/how-to/add-rate-limiting-tiers-with-kong-gateway/) guide.

#### Known issues in 3.4.0.0

The following is a list of known issues in 3.4.x that may be fixed in a future release.

{% table %}
columns:
  - title: Known issue
    key: issue
  - title: Description
    key: description
  - title: Status
    key: status
rows:
  - issue: Referenceable fields
    description: |
      Some referenceable configuration fields, such as the `http_endpoint` field
      of the `http-log` plugin and the `endpoint` field of the `opentelemetry` plugin,
      do not accept reference values due to incorrect field validation.
      <br><br>
      When adding new plugins to the existing installation (either manually or via the extension of `bundled` plugins), the `kong migrations finish` or `kong migrations up` must be run with the `-f` flag to forcefully upgrade the plugin schemas.
    status: Not fixed
{% endtable %}

## 3.3.x breaking changes

### 3.3.0.0

Breaking changes in the 3.3.0.0 release.

#### Plugins

For breaking changes to plugins, see the [{{site.base_gateway}} Changelog](/gateway/changelog/) for your {{site.base_gateway}} version.

#### Plugin queuing

The plugin queuing system was reworked in {{site.base_gateway}} 3.3.x, so some plugin parameters may not function as expected anymore. If you use queues in the following plugins, new parameters must be configured:

* [HTTP Log](/plugins/http-log/)
* [OpenTelemetry](/plugins/opentelemetry/)
* [Datadog](/plugins/datadog/)
* [StatsD](/plugins/statsd/)
* [Zipkin](/plugins/zipkin/)

For more information about how plugin queuing works and the plugin queuing parameters you can configure, see the documentation for each plugin.

#### Traditional compatibility router

The `traditional_compat` router mode has been made more compatible with the behavior of `traditional` mode by splitting Routes with multiple paths into multiple `atc` Routes with separate priorities. Since the introduction of the new router in {{site.base_gateway}} 3.0, `traditional_compat` mode assigned only one priority to each Route, even if different prefix path lengths and regular expressions were mixed in a Route. This was not how multiple paths were handled in the `traditional` router and the behavior has now been changed so that a separate priority value is assigned to each path in a Route.

#### Upgrading {{site.base_gateway}} after adopting PostgreSQL 15

PostgreSQL 15 enforces different permissions on the public schema than prior versions of PostgreSQL. This requires an extra step to grant the correct permissions to the Kong user to make schema changes.

You can grant the permissions in one of two ways:
* Assign the Kong database owner to Kong by running `ALTER DATABASE kong OWNER TO kong`.
* Temporarily give the Kong user the ability to modify the public schema and then revoke that permission. This option is more restrictive and is a two-part process:
  1. Before you run the bootstrap migration commands, grant the right to modify the schema with `GRANT CREATE ON SCHEMA public TO kong`.
  2. After the migrations are done, remove this permission by running `REVOKE CREATE ON SCHEMA public FROM kong`.


## 3.2.x breaking changes

### 3.2.2.4

Breaking changes in the 3.2.2.4 release.

#### Amazon Linux 2022 to 2023 rename

Amazon Linux 2022 artifacts are renamed to Amazon Linux 2023, based on AWS's own renaming.

#### Ubuntu 18.04 support removed

Support for running {{site.base_gateway}} on Ubuntu 18.04 ("Bionic") is now deprecated,
as [Standard Support for Ubuntu 18.04 has ended as of June 2023](https://wiki.ubuntu.com/Releases).
Starting with {{site.base_gateway}} 3.2.2.4, Kong is not building new Ubuntu 18.04
images or packages, and Kong will not test package installation on Ubuntu 18.04.

### 3.2.0.0

Breaking changes in the 3.2.0.0 release.

#### Plugins

For breaking changes to plugins, see the [{{site.base_gateway}} Changelog](/gateway/changelog/) for your {{site.base_gateway}} version.

#### PostgreSQL SSL version bump

The default PostgreSQL SSL version has been bumped to TLS 1.2.

This causes changes to [`pg_ssl_version`](/gateway/configuration/#datastore-section) (set through `kong.conf`):
* The default value is now `tlsv1_2`.
* `pg_ssl_version` previously accepted any string. In this version, it requires one of the following values: `tlsv1_1`, `tlsv1_2`, `tlsv1_3` or `any`.

This mirrors the setting `ssl_min_protocol_version` in PostgreSQL 12.x and onward.
See the [PostgreSQL documentation](https://postgresqlco.nf/doc/en/param/ssl_min_protocol_version/)
for more information about that parameter.

To use the default setting in `kong.conf`, verify that your Postgres server supports TLS 1.2 or higher versions, or set the TLS version yourself.

TLS versions lower than `tlsv1_2` are already deprecated and are considered insecure from PostgreSQL 12.x onward.

#### Changes to the Kong-Debug header

Added the [`allow_debug_header`](/gateway/configuration/#allow-debug-header)
configuration property to `kong.conf` to constrain the `Kong-Debug` header for debugging. This option defaults to `off`.

If you were previously relying on the `Kong-Debug` header to provide debugging information, set `allow_debug_header: on` in `kong.conf` to continue doing so.

#### JWT plugin

The [JWT plugin](/plugins/jwt/) now denies any request that has different tokens in the JWT token search locations.

#### Session library upgrade

The [`lua-resty-session`](https://github.com/bungle/lua-resty-session) library has been upgraded to v4.0.0.
This version includes a full rewrite of the session library.

This upgrade affects the following:
* [Session plugin](/plugins/session/)
* [OpenID Connect plugin](/plugins/openid-connect/)
* [SAML plugin](/plugins/saml/)
* Any session configuration that uses the Session or OpenID Connect plugin in the background, including sessions for Kong Manager and Dev Portal.

All existing sessions are invalidated when upgrading to this version.
For sessions to work as expected in this version, all nodes must run {{site.base_gateway}} 3.2.x or later.
If multiple data planes run different versions, every time a user hits a different DP,
even for the same endpoint, the previous session is invalidated.

For that reason, we recommend that during upgrades, proxy nodes with
mixed versions run for as little time as possible. During that time, the invalid sessions could cause
failures and partial downtime.

You can expect the following behavior:
* **After upgrading the control plane**: Existing Kong Manager and Dev Portal sessions will be invalidated and all users will be required to log back in.
* **After upgrading the data planes**: Existing proxy sessions will be invalidated. If you have an IdP configured, users will be required to log back into the IdP.

#### Session configuration parameter changes

The session library upgrade includes new, changed, and removed parameters. Here's how they function:

* The new parameter `idling_timeout`, which replaces `cookie_lifetime`, has a default value of 900.
Unless configured differently, sessions expire after 900 seconds (15 minutes) of idling.
* The new parameter `absolute_timeout` has a default value of 86400.
Unless configured differently, sessions expire after 86400 seconds (24 hours).
* All renamed parameters will still work by their old names.
* Any removed parameters will not work anymore. They won't break your configuration, and sessions will
continue to function, but they will not contribute anything to the configuration.

Existing session configurations will still work as configured with the old parameters.

*Do not* change any parameters to the new ones until all CP and DP nodes are upgraded.

After you have upgraded all of your CP and DP nodes to 3.2 and ensured that your environment is stable, we
recommend updating parameters to their new renamed versions, and cleaning out any removed parameters
from session configuration to avoid unpredictable behavior.

{% navtabs "session-params" %}
{% navtab "Session plugin" %}

The following parameters and the values that they accept have changed.
For details on the new accepted values, see the [Session plugin](/plugins/session/) documentation.

<!--vale off-->
{% table %}
columns:
  - title: Old parameter name
    key: old
  - title: New parameter name
    key: new
rows:
  - old: "`cookie_lifetime`"
    new: "`rolling_timeout`"
  - old: "`cookie_idletime`"
    new: "`idling_timeout`"
  - old: "`cookie_samesite`"
    new: "`cookie_same_site`"
  - old: "`cookie_httponly`"
    new: "`cookie_http_only`"
  - old: "`cookie_discard`"
    new: "`stale_ttl`"
  - old: "`cookie_renew`"
    new: "Removed, no replacement parameter."
{% endtable %}
<!--vale on-->

{% endnavtab %}
{% navtab "SAML plugin" %}

The following parameters and the values that they accept have changed.
For details on the new accepted values, see the [SAML plugin](/plugins/saml/) documentation.

<!--vale off-->
{% table %}
columns:
  - title: Old parameter name
    key: old
  - title: New parameter name
    key: new
rows:
  - old: "`session_cookie_lifetime`"
    new: "`session_rolling_timeout`"
  - old: "`session_cookie_idletime`"
    new: "`session_idling_timeout`"
  - old: "`session_cookie_samesite`"
    new: "`session_cookie_same_site`"
  - old: "`session_cookie_httponly`"
    new: "`session_cookie_http_only`"
  - old: "`session_memcache_prefix`"
    new: "`session_memcached_prefix`"
  - old: "`session_memcache_socket`"
    new: "`session_memcached_socket`"
  - old: "`session_memcache_host`"
    new: "`session_memcached_host`"
  - old: "`session_memcache_port`"
    new: "`session_memcached_port`"
  - old: "`session_redis_cluster_maxredirections`"
    new: "`session_redis_cluster_max_redirections`"
  - old: "`session_cookie_renew`"
    new: "Removed, no replacement parameter."
  - old: "`session_cookie_maxsize`"
    new: "Removed, no replacement parameter."
  - old: "`session_strategy`"
    new: "Removed, no replacement parameter."
  - old: "`session_compressor`"
    new: "Removed, no replacement parameter."
{% endtable %}
<!--vale on-->


{% endnavtab %}
{% navtab "OpenID Connect plugin" %}

The following parameters and the values that they accept have changed.
For details on the new accepted values, see the [OpenID Connect plugin](/plugins/openid-connect/) documentation.

<!--vale off-->
{% table %}
columns:
  - title: Old parameter name
    key: old
  - title: New parameter name
    key: new
rows:
  - old: "`authorization_cookie_lifetime`"
    new: "`authorization_rolling_timeout`"
  - old: "`authorization_cookie_samesite`"
    new: "`authorization_cookie_same_site`"
  - old: "`authorization_cookie_httponly`"
    new: "`authorization_cookie_http_only`"
  - old: "`session_cookie_lifetime`"
    new: "`session_rolling_timeout`"
  - old: "`session_cookie_idletime`"
    new: "`session_idling_timeout`"
  - old: "`session_cookie_samesite`"
    new: "`session_cookie_same_site`"
  - old: "`session_cookie_httponly`"
    new: "`session_cookie_http_only`"
  - old: "`session_memcache_prefix`"
    new: "`session_memcached_prefix`"
  - old: "`session_memcache_socket`"
    new: "`session_memcached_socket`"
  - old: "`session_memcache_host`"
    new: "`session_memcached_host`"
  - old: "`session_memcache_port`"
    new: "`session_memcached_port`"
  - old: "`session_redis_cluster_maxredirections`"
    new: "`session_redis_cluster_max_redirections`"
  - old: "`session_cookie_renew`"
    new: "Removed, no replacement parameter."
  - old: "`session_cookie_maxsize`"
    new: "Removed, no replacement parameter."
  - old: "`session_strategy`"
    new: "Removed, no replacement parameter."
  - old: "`session_compressor`"
    new: "Removed, no replacement parameter."
{% endtable %}
<!--vale on-->

{% endnavtab %}
{% endnavtabs %}

## 3.1.x breaking changes

### 3.1.0.0

Breaking changes in the 3.1.0.0 release.

#### Hybrid mode

The legacy hybrid configuration protocol has been removed in favor of the wRPC protocol introduced in 3.0.0.0.
Rolling upgrades from 2.8.x.y to 3.1.0.0 are not supported.
Operators must upgrade to 3.0.x.x before they can perform a rolling upgrade to 3.1.0.0.


## 3.0.x breaking changes

### 3.0.0.0

Breaking changes in the 3.0.0.0 release.

#### Kong plugins

If you are adding a new plugin to your installation, you need to run
`kong migrations up` with the plugin name specified. For example,
`KONG_PLUGINS=tls-handshake-modifier`.

The 3.0 release includes the following new plugins:
* [OpenTelemetry](/plugins/opentelemetry/) (`opentelemetry`)
* [TLS Handshake Modifier](/plugins/tls-handshake-modifier/) (`tls-handshake-modifier`)
* [TLS Metadata Headers](/plugins/tls-metadata-headers/) (`tls-metadata-headers`)
* [WebSocket Size Limit](/plugins/websocket-size-limit/) (`websocket-size-limit`)
* [WebSocket Validator](/plugins/websocket-validator/) (`websocket-validator`)

Kong plugins no longer support `CREDENTIAL_USERNAME` (`X-Credential-Username`).
Use the constant `CREDENTIAL_IDENTIFIER` (`X-Credential-Identifier`) when
setting the upstream headers for a credential.

#### Deployment

Amazon Linux 1 and Debian 8 (Jessie) containers and packages are deprecated and are no longer produced for new versions of {{site.base_gateway}}.

#### Blue-green deployments

*Traditional mode*: Blue-green upgrades from versions of 2.8.1 and below to 3.0.0 are not currently supported.
This is a known issue planned to be fixed in the next 2.8 release. When that version is released, 2.x users should upgrade to that version before beginning a blue-green upgrade to 3.0.

*Hybrid mode*: See the [upgrade instructions](#migrate-db) below.

#### Dependencies

If you are using the provided binary packages (except Debian and RHEL), all necessary dependencies
for the gateway are bundled and you can skip this section.

As of {{ site.base_gateway }} 3.0, Debian and RHEL images are built with minimal dependencies and run through automated security scanners before being published.
They only contain the bare minimum required to run {{site.base_gateway}}.
If you would like further customize the base image and any dependencies, you can
[build your own Docker images](/how-to/build-custom-docker-image/).


If you are using Debian, RHEL, or building your dependencies by hand, there are changes since the
previous release, so you will need to rebuild them with the latest patches.

The required OpenResty version for {{site.base_gateway}} 3.0.x is
[1.21.4.1](https://openresty.org/en/ann-1021004001.html). In addition to an upgraded
OpenResty, you need the correct [OpenResty patches](https://github.com/Kong/kong-build-tools/tree/master/openresty-build-tools/patches)
for this new version, including the latest release of [lua-kong-nginx-module](https://github.com/Kong/lua-kong-nginx-module).
The [kong-build-tools](https://github.com/Kong/kong-build-tools)
repository contains [openresty-build-tools](https://github.com/Kong/kong-build-tools/tree/master/openresty-build-tools),
which allows you to more easily build OpenResty with the necessary patches and modules.

#### Migrations

The migration helper library (mostly used for Cassandra migrations) is no longer supplied with {{site.base_gateway}}.

PostgreSQL migrations can now have an `up_f` part like Cassandra
migrations, designating a function to call. The `up_f` part is
invoked after the `up` part has been executed against the database
for both PostgreSQL and Cassandra.

#### Deprecations and changed parameters

The StatsD Advanced plugin has been deprecated and will be removed in 4.0.
All capabilities are now available in the [StatsD](/plugins/statsd/) plugin.

The following plugins have had configuration parameters changed or removed. You will need to carefully review and update your configuration as needed:

*[ACL](/plugins/acl/), [Bot Detection](/plugins/bot-detection/), and [IP Restriction](/plugins/ip-restriction/)*
* Removed the deprecated `blacklist` and `whitelist` configuration parameters. Use `allow` or `deny` instead.

*[ACME](/plugins/acme/)*
* The default value of the `auth_method` configuration parameter is now `token`.

*[AWS Lambda](/plugins/aws-lambda/)*
* The AWS region is now required. You can set it through the plugin configuration with the `aws_region` field parameter, or with environment variables.
* The plugin now allows `host` and `aws_region` fields to be set at the same time, and always applies the SigV4 signature.

*[HTTP Log](/plugins/http-log/)*
* The `headers` field now only takes a single string per header name,
where it previously took an array of values.

*[JWT](/plugins/jwt/)*
* The authenticated JWT is no longer put into the nginx
context (`ngx.ctx.authenticated_jwt_token`). Custom plugins which depend on that
value being set under that name must be updated to use Kong's shared context
instead (`kong.ctx.shared.authenticated_jwt_token`) before upgrading to 3.0.

*[Prometheus](/plugins/prometheus/)*
* High cardinality metrics are now disabled by default.

* The following metric names were adjusted to add units to standardize where possible:
  * `http_status` to `http_requests_total`.
  * `latency` to `kong_request_latency_ms` (HTTP), `kong_upstream_latency_ms`, `kong_kong_latency_ms`, and `session_duration_ms` (stream).
      Kong latency and upstream latency can operate at orders of different magnitudes. Separate these buckets to reduce memory overhead.
  * `kong_bandwidth` to `kong_bandwidth_bytes`.
  * `nginx_http_current_connections` and `nginx_stream_current_connections` were merged into `nginx_connections_total`.
  * `request_count` and `consumer_status` were merged into `http_requests_total`.
      If the `per_consumer` config is set to `false`, the `consumer` label will be empty. If the `per_consumer` config is `true`, the `consumer` label will be filled.

* Other metric changes:
  * Removed the following metric: `http_consumer_status`.
  * `http_requests_total` has a new label, `source`. It can be set to `exit`, `error`, or `service`.
  * All memory metrics have a new label: `node_id`.
  * The plugin doesn't export status codes, latencies, bandwidth and upstream
  health check metrics by default. They can still be turned on manually by setting `status_code_metrics`,
  `lantency_metrics`, `bandwidth_metrics` and `upstream_health_metrics` respectively.

*[Pre-function](/plugins/pre-function/) and [Post-function](/plugins/post-function/) plugins*
* Removed the deprecated `config.functions` configuration parameter from the
`post-function` and `pre-function` plugins' schemas. Use the `config.access` phase instead.

*[StatsD](/plugins/statsd/)*
* Any metric name that is related to a Gateway Service now has a `service.` prefix: `kong.service.<service_identifier>.request.count`.
  * The metric `kong.<service_identifier>.request.status.<status>` has been renamed to `kong.service.<service_identifier>.status.<status>`.
  * The metric `kong.<service_identifier>.user.<consumer_identifier>.request.status.<status>` has been renamed to `kong.service.<service_identifier>.user.<consumer_identifier>.status.<status>`.

* The metric `*.status.<status>.total` from metrics `status_count` and `status_count_per_user` has been removed.

*[Proxy Cache](/plugins/proxy-cache/), [Proxy Cache Advanced](/plugins/proxy-cache-advanced/), and [GraphQL Proxy Cache Advanced](/plugins/graphql-proxy-cache-advanced/)*
* These plugins don't store response data in `ngx.ctx.proxy_cache_hit` anymore.
* Logging plugins that need the response data must now read it from `kong.ctx.shared.proxy_cache_hit`.

#### Custom plugins and the PDK

* DAOs in plugins must be listed in an array, so that their loading order is explicit. Loading them in a
  hash-like table is no longer supported.
* Plugins MUST now have a valid `PRIORITY` (integer) and `VERSION` ("x.y.z" format)
  field in their `handler.lua` file, otherwise the plugin will fail to load.
* The old `kong.plugins.log-serializers.basic` library was removed in favor of the PDK
  function `kong.log.serialize`. Upgrade your plugins to use the PDK.
* The support for deprecated legacy plugin schemas was removed. If your custom plugins
  still use the old (`0.x era`) schemas, you are now forced to upgrade them.

* Updated the priority for some plugins.

    This is important for those who run custom plugins as it may affect the sequence in which your plugins are executed.
    This does not change the order of execution for plugins in a standard {{site.base_gateway}} installation.

    Old and new plugin priority values:
    - `acme` changed from `1007` to `1705`
    - `basic-auth` changed from `1001` to `1100`
    - `canary` changed from `13` to `20`
    - `degraphql` changed from `1005` to `1500`
    - `graphql-proxy-cache-advanced` changed from `100` to `99`
    - `hmac-auth` changed from `1000` to `1030`
    - `jwt` changed from `1005` to `1450`
    - `jwt-signer` changed from `999` to `1020`.
    - `key-auth` changed from `1003` to `1250`
    - `key-auth-advanced` changed from `1003` to `1250`
    - `ldap-auth` changed from `1002` to `1200`
    - `ldap-auth-advanced` changed from `1002` to `1200`
    - `mtls-auth` changed from `1006` to `1600`
    - `oauth2` changed from `1004` to `1400`
    - `openid-connect` changed from `1000` to `1050`
    - `rate-limiting` changed from `901` to `910`
    - `rate-limiting-advanced` changed from `902` to `910`
    - `route-by-header` changed from `2000` to `850`
    - `route-transformer-advanced` changed from `800` to `780`
    - `pre-function` changed from `+inf` to `1000000`
    - `vault-auth` change from `1003` to `1350`

* The `kong.request.get_path()` PDK function now performs path normalization
  on the string that is returned to the caller. The raw, non-normalized version
  of the request path can be fetched via `kong.request.get_raw_path()`.

* `pdk.response.set_header()`, `pdk.response.set_headers()`, `pdk.response.exit()` now ignore and emit warnings for manually set `Transfer-Encoding` headers.

* The PDK is no longer versioned.

* The JavaScript PDK now returns `Uint8Array` for `kong.request.getRawBody`,
  `kong.response.getRawBody`, and `kong.service.response.getRawBody`.
  The Python PDK returns `bytes` for `kong.request.get_raw_body`,
  `kong.response.get_raw_body`, and `kong.service.response.get_raw_body`.
  Previously, these functions returned strings.

* The `go_pluginserver_exe` and `go_plugins_dir` directives are no longer supported.
If you are using
 [Go plugin server](https://github.com/Kong/go-pluginserver), migrate your plugins to use the
 [Go PDK](https://github.com/Kong/go-pdk) before upgrading.

* As of 3.0, {{site.base_gateway}}'s schema library's `process_auto_fields` function will not make deep
  copies of data that is passed to it when the given context is `select`. This was
  done to avoid excessive deep copying of tables where Kong believes the data most of
  the time comes from a driver like `pgmoon` or `lmdb`.

  If a custom plugin relied on `process_auto_fields` not overriding the given table, it must make its own copy
  before passing it to the function now.

* The deprecated `shorthands` field in Kong plugin or DAO schemas was removed in favor
  of the typed `shorthand_fields`. If your custom schemas still use `shorthands`, you
  need to update them to use `shorthand_fields`.

* The support for `legacy = true/false` attribute was removed from Kong schemas and
  Kong field schemas.

* The Kong singletons module `kong.singletons` was removed in favor of the PDK `kong.*`.

#### New router

{{site.base_gateway}} no longer uses a heuristic to guess whether a `route.path` is a regex pattern. From 3.0 onward,
all regex paths must start with the `"~"` prefix, and all paths that don't start with `"~"` will be considered plain text.
The migration process should automatically convert the regex paths when upgrading from 2.x to 3.0.

The normalization rules for `route.path` have changed. {{site.base_gateway}} now stores the unnormalized path, but
the regex path always pattern-matches with the normalized URI. Previously, {{site.base_gateway}} replaced percent-encoding
in the regex path pattern to ensure different forms of URI matches.
That is no longer supported. Except for the reserved characters defined in
[rfc3986](https://datatracker.ietf.org/doc/html/rfc3986#section-2.2),
write all other characters without percent-encoding.

#### Declarative and DB-less

The version number (`_format_version`) of declarative configuration has been bumped to `3.0` for changes on `route.path`.
Declarative configurations with older versions will be upgraded to `3.0` during migrations.

{:.warning}
> **Do not sync (`deck gateway sync`) declarative configuration files from 2.8 or earlier to 3.0.**
Old configuration files will overwrite the configuration and create compatibility issues.
To grab the updated configuration, `deck gateway dump` the 3.0 file after migrations are completed.

It is no longer possible to use the `.lua` format to import a declarative configuration file from the `kong`
CLI tool. Only JSON and YAML formats are supported. If your update procedure with {{site.base_gateway}} involves
executing `kong config db_import config.lua`, convert the `config.lua` file into a `config.json` or `config.yml` file
before upgrading.

#### Admin API

The Admin API endpoint `/vitals/reports` has been removed.

`POST` requests on `/targets` endpoints are no longer able to update
existing entities. They are only able to create new ones.
If you have scripts that use `POST` requests to modify `/targets`, change them to `PUT`
requests to the appropriate endpoints before updating to Kong 3.0.

The list of reported plugins available on the server now returns a table of
metadata per plugin instead of a boolean `true`.

#### Configuration

The Kong constant `CREDENTIAL_USERNAME` with the value of `X-Credential-Username` has been
removed.

The default value of `lua_ssl_trusted_certificate` has changed to `system` to automatically load the trusted CA list from the system CA store.

The data plane config cache mechanism and its related configuration options
(`data_plane_config_cache_mode` and `data_plane_config_cache_path`) have been removed in favor of LMDB.

`ngx.ctx.balancer_address` was removed in favor of `ngx.ctx.balancer_data`.

#### Kong for Kubernetes considerations

The Helm chart automates the upgrade migration process. When running `helm upgrade`,
the chart spawns an initial job to run `kong migrations up` and then spawns new
Kong pods with the updated version. Once these pods become ready, they begin processing
traffic and old pods are terminated. Once this is complete, the chart spawns another job
to run `kong migrations finish`.

While the migrations themselves are automated, the chart does not automatically ensure
that you follow the recommended upgrade path. If you are upgrading from more than one minor
{{site.base_gateway}} version back, check the upgrade path recommendations.

Although not required, users should upgrade their chart version and {{site.base_gateway}} version independently.
In the event of any issues, this will help clarify whether the issue stems from changes in
Kubernetes resources or changes in {{site.base_gateway}}.

For specific Kong for Kubernetes version upgrade considerations, see
[Upgrade considerations](https://github.com/Kong/charts/blob/main/charts/kong/UPGRADE.md)

#### Kong deployment split across multiple releases

The standard chart upgrade automation process assumes that there is only a single {{site.base_gateway}} release
in the {{site.base_gateway}} cluster, and runs both `migrations up` and `migrations finish` jobs.

If you split your {{site.base_gateway}} deployment across multiple Helm releases (to create proxy-only
and admin-only nodes, for example), you must set which migration jobs run based on your
upgrade order.

To handle clusters split across multiple releases, you should:

1. Upgrade one of the releases with:

   ```shell
   helm upgrade RELEASENAME -f values.yaml \
   --set migrations.preUpgrade=true \
   --set migrations.postUpgrade=false
   ```
2. Upgrade all but one of the remaining releases with:

   ```shell
   helm upgrade RELEASENAME -f values.yaml \
   --set migrations.preUpgrade=false \
   --set migrations.postUpgrade=false
   ```
3. Upgrade the final release with:

   ```shell
   helm upgrade RELEASENAME -f values.yaml \
   --set migrations.preUpgrade=false \
   --set migrations.postUpgrade=true
   ```

This ensures that all instances are using the new {{site.base_gateway}} package before running
`kong migrations finish`.

#### Hybrid mode considerations

{:.warning}
> **Important:** If you are currently running in [hybrid mode](/gateway/deployment-topologies/),
upgrade the control plane first, and then the data planes.

* If you are currently running 2.8.x in classic (traditional)
  mode and want to run in hybrid mode instead, follow the hybrid mode
  [installation instructions](/gateway/deployment-topologies/)
  after running the migration.
* Custom plugins (either your own plugins or third-party plugins that are not shipped with {{site.base_gateway}})
  need to be installed on both the control plane and the data planes in hybrid mode. Install the
  plugins on the control plane first, and then the data planes.
* The [Rate Limiting Advanced](/plugins/rate-limiting-advanced/) plugin does not
    support the `cluster` strategy in hybrid mode. The `redis` strategy must be used instead.

#### Template changes

There are changes in the Nginx configuration file between every minor and major
version of {{site.base_gateway}} starting with 2.0.x.

In 3.0.x, the deprecated alias of `Kong.serve_admin_api` was removed.
If your custom Nginx templates still use it, change it to `Kong.admin_content`.

{% navtabs "gateway-flavour" %}
{% navtab "OSS" %}
To view all of the configuration changes between versions, clone the
[Kong repository](https://github.com/kong/kong) and run `git diff`
on the configuration templates, using `-w` for greater readability.

Here's how to see the differences between previous versions and 3.0.x:

```
git clone https://github.com/kong/kong
cd kong
git diff -w 2.0.0 3.0.0 kong/templates/nginx_kong*.lua
```

Adjust the starting version number (2.0.0 in the example) to the version number you are currently using.

To produce a patch file, use the following command:

```
git diff 2.0.0 3.0.0 kong/templates/nginx_kong*.lua > kong_config_changes.diff
```

Adjust the starting version number to the version number (2.0.0 in the example) you are currently using.

{% endnavtab %}
{% navtab "Enterprise" %}

The default template for {{site.base_gateway}} can be found using this command
on the system running your {{site.base_gateway}} instance:
`find / -type d -name "templates" | grep kong`.

When upgrading, make sure to run this command on both the old and new clusters,
diff the files to identify any changes, and apply them as needed.

{% endnavtab %}
{% endnavtabs %}

## 2.8.x and earlier breaking changes

### 2.8.4.3

Breaking changes in the 2.8.4.3 release.

#### Ubuntu 18.04 support removed

Support for running {{site.base_gateway}} on Ubuntu 18.04 ("Bionic") is now deprecated,
as [Standard Support for Ubuntu 18.04 has ended as of June 2023](https://wiki.ubuntu.com/Releases).
Starting with {{site.base_gateway}} 2.8.4.3, Kong is not building new Ubuntu 18.04
images or packages, and Kong will not test package installation on Ubuntu 18.04.

### 2.8.0.0

Breaking changes in the 2.8.0.0 release.

#### Amazon Linux 2022 to 2023 rename

Amazon Linux 2022 artifacts are renamed to Amazon Linux 2023, based on AWS's own renaming.



