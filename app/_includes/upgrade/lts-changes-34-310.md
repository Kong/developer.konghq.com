### Removed or deprecated

The feature or behaviors in the following table have been permanently removed.
By updating settings based on the table below, you can avoid any potential 
issues that may arise from using deprecated aliases and ensure
that your {{site.base_gateway}} instance functions correctly with the most recent changes and improvements.

It's essential to keep configurations up to date to maintain the system's stability, 
security, and optimal performance. 

{% table %}
columns:
  - title: Change
    key: description
  - title: Category
    key: category
  - title: Action Required
    key: action
rows:
  - category: Deployment
    description: |
      Deprecated and stopped producing Debian 10 containers and packages, as this version reached its End of Life (EOL) date on June 30, 2024. 
      <br><br>
      As 3.4.3.12, Kong is not building {{site.base_gateway}} installation packages or Docker images for Debian 10. Kong is no longer providing official support for any Kong version running on this system. 
    action: |
      Debian 11 and 12 are available. Upgrade to one of these versions before 
      upgrading to {{site.base_gateway}} 3.10.
  - category: Deployment
    description: |
      Deprecated and stopped producing CentOS containers and packages. 
      <br><br>
      As 3.4.3.12, Kong is not building {{site.base_gateway}} installation packages or Docker images for CentOS. Kong is no longer providing official support for any Kong version running on this system. 
    action: |
      Migrate to a different OS before upgrading to {{site.base_gateway}} 3.10.
  - category: Deployment
    description: |
      Deprecated and stopped producing RHEL 7 containers and packages, as this version reached its End of Life (EOL) date on June 30, 2024.
      <br><br>
      As 3.4.3.12, Kong is not building {{site.base_gateway}} installation packages or Docker images for RHEL 7. Kong is no longer providing official support for any Kong version running on this system. 
    action: |
      RHEL 8 and 9 are available. Upgrade to one of these versions before 
      upgrading to {{site.base_gateway}} 3.10.
  - category: Developer Portal
    description: |
      <!--vale off-->
      The product component known as Kong Enterprise Portal (Developer Portal) is no longer included in {{site.ee_product_name}}. Existing customers who have purchased Kong Enterprise Portal can continue to use it and be supported via a dedicated mechanism.
      <!--vale on-->
    action: |
      <!--vale off-->
      If you have purchased Kong Enterprise Portal in the past and would like to continue to use it in 3.10, contact [Kong Support](https://support.konghq.com) for more information.
      <!--vale on-->
  - category: Vitals
    description: |
      The product component known as Vitals is no longer included in {{site.ee_product_name}}. Existing customers who have purchased Kong Vitals can continue to use it and be supported via a dedicated mechanism. {{site.konnect_short_name}} users can take advantage of our {{site.observability}} offering, which provides a superset of Vitals functionality.
    action: |
      If you have purchased Vitals in the past and would like to continue to use it in 3.10, contact [Kong Support](https://support.konghq.com) for more information.
  - category: Plugins
    description: |
      **SAML**
      <br><br>
      The priority of the SAML plugin changed to 1010 to correct the integration 
      between the SAML plugin and other Consumer-based plugins.
      <br><br>
      This is important for those who run custom plugins, as it may affect the sequence in which your plugins are executed.
      This does not change the order of execution for plugins in a standard {{site.base_gateway}} installation.
      <br><br>
    action: |
      Review custom plugin priorities.
      If any of the changes in priorities break expected behaviour, adjust as necessary.
  - category: SSL
    description: |
      In OpenSSL 3.2, the default SSL/TLS security level has been changed from 1 to 2.
      This means the security level is set to 112 bits of security.
      <br><br>
      As a result, the following are prohibited:
      * RSA, DSA, and DH keys shorter than 2048 bits
      * ECC keys shorter than 224 bits
      * Any cipher suite using RC4
      * SSL version 3
      Additionally, compression is disabled.
    action: |
      Review your security configurations and keys to ensure that they comply to the new standard.
  - category: SSL
    description: |
      OpenSSL 3.x now includes TLS 1.3. TLS 1.1 and earlier versions have been deprecated and are disabled by default.
    action: |
      If you still need to support TLS 1.1, set the [`ssl_cipher_suite`](/gateway/configuration/#ssl-cipher-suite) setting to `old`.
  - category: Plugins
    description: |
      Standardized Redis configuration across plugins.
      The Redis configuration now follows a common schema that is shared across other plugins.
      <br><br>
      Kong has changed and refactored the shared Redis configuration that previously was imported by `require "kong.enterprise_edition.redis"`. If you created a custom plugin that is using this shared configuration or if you have a forked version of a plugin, like `rate-limiting-advanced`, then you might need to do additional steps before you can upgrade to the new version of this Redis config.
      <br><br>
      Out of the box, custom plugins should still work since the old shared configuration is still available. The new config adds the `cluster_max_redirections` option for Redis Cluster, and the `cluster_nodes` format and `sentinel_nodes` were changed. Other than that, the initialization step is no longer required.
      <br><br>
      As part of this change, the following plugins switched `cluster_addresses` to `cluster_nodes` and `sentinel_addresses` to `sentinel_nodes` for Redis configuration:
      <br><br>
      * [AI Rate Limiting Advanced](/plugins/ai-rate-limiting-advanced/)
      * [GraphQL Proxy Caching Advanced](/plugins/graphql-proxy-cache-advanced/)
      * [GraphQL Rate Limiting Advanced](/plugins/graphql-rate-limiting-advanced/)
      * [Proxy Caching Advanced](/plugins/proxy-cache-advanced/)
      * [Rate Limiting Advanced](/plugins/rate-limiting-advanced/)
      <br><br>

      The following plugins are also now using standardized Redis configuration:
      <br><br>
      * [ACME](/plugins/acme/)
      * [Rate Limiting](/plugins/rate-limiting/)
      * [Response Rate Limiting](/plugins/response-ratelimiting/)

    action: |
      For bundled plugins, there is no action required. These fields are converted automatically when you run `kong migrations up`. Also, any changes uploaded via decK or the Admin API using the old `cluster_addresses` and `sentinel_addresses` are respected and properly translated to the new fields.
      <br><br>
      Forked custom plugins aren't automatically migrated. For more information about how to migrate custom plugins, see [Custom plugins that used shared Redis config](/gateway/breaking-changes/#custom-plugins-that-used-shared-redis-config).
      
  - category: Plugins
    description: |
      **Azure Functions plugin**
      <br><br>
      The Azure Functions plugin now eliminates the upstream/request URI and only uses the [`config.routeprefix`](/plugins/azure-functions/reference/#config-routeprefix) configuration field to construct the request path when requesting the Azure API.
    action: |
      Update your plugin configuration to use `config.routeprefix` instead of the deprecated upstream/request URI fields.
  - category: Plugins
    description: |
      **OAS Validation plugin**
      <br><br>
      The plugin now bypasses schema validation when the content type is not `application/json`.
    action: |
      Ensure that all requests have `Content-type: application/json`.
  - category: Kong Manager
    description: |   
      Kong Manager now uses the session management mechanism in the OpenID Connect plugin.
      `admin_gui_session_conf` is no longer required when authenticating with OIDC. Instead, session-related
      configuration parameters are set in `admin_gui_auth_conf` (like `session_secret`).
    action: |
      We recommend reviewing your configuration, as some session-related parameters in `admin_gui_auth_conf` have different default values compared to the ones in `admin_gui_session_conf`.
      <br><br>
      See the [migration FAQ](/gateway/kong-manager/openid-connect/#migrate-oidc-configuration-from-older-versions) for more information.
  - category: Admin API
    description: |
      The listing endpoints for Consumer Groups (`/consumer_groups`) and Consumers (`/consumers`) now respond
      with paginated results. 
      The JSON key for the list has been changed to `data` instead of `consumer_groups` or `consumers`.
    action: |
      Update any CI that requires access to the Consumer and Consumer Groups lists.
  - category: Nginx Templates
    description: |
      If you are using `ngx.var.http_*` in custom code to access HTTP headers, the behavior of that variable changed slightly when the same header is used multiple times in a single request. Previously, it would return the first value only; now it returns all the values, separated by commas. 
      <br><br>
      {{site.base_gateway}}'s PDK header getters and setters work as before.
    action: |
      Adjust your custom code accordingly.
  - category: Vaults
    description: |
      There are some changes to the configuration of the [HashiCorp Vault entity](/how-to/configure-hashicorp-vault-as-a-vault-backend/) when using the AppRole authentication method:
      - A string entirely made of spaces can't be specified as the `role_id` or `secret_id`.
      - One of `secret_id` or `secret_id_file` is required.

    action: |
      - If you have any strings entirely made of spaces as the `role_id` or `secret_id`, change them.
      - Specify at least one of `secret_id` or `secret_id_file` in the HashiCorp Vault entity when using the AppRole authentication method.
  - category: Tracing
    description: |
      The Granular Tracing feature has been deprecated and removed from {{site.base_gateway}}.
    action: |
      Remove the following tracing-related parameters from your `kong.conf` file:
      <br><br>
      * `tracing`
      * `tracing_write_strategy`
      * `tracing_write_endpoint`
      * `tracing_time_threshold`
      * `tracing_types`
      * `tracing_debug_header`
      * `generate_trace_details`
      <br><br>
      
      We recommend transitioning to [OpenTelemetry Instrumentation](/plugins/opentelemetry/) instead.
  - category: Logging
    description: |
      The `kong.logrotate` configuration file will no longer be overwritten during upgrade.
    action: |
      If running on Debian or Ubuntu, set the environment variable `DEBIAN_FRONTEND=noninteractive` when upgrading to avoid any interactive prompts and enable fully automatic upgrades.
  - category: PDK
    description: |
      Changed the encoding of spaces in query arguments from `+` to `%20` in the `kong.service.request.clear_query_arg` PDK module.
      While the `+` character represents the correct encoding of space in query strings, Kong uses `%20` in many other APIs, which is inherited from Nginx/OpenResty.
    action: |
      No
          
{% endtable %}


### Compatible

The following table lists behavior changes that may cause your database configuration 
or `kong.conf` to fail.
This includes deprecated (but not removed) features.

{% table %}
columns:
  - title: Change
    key: description
  - title: Category
    key: category
  - title: Action Required
    key: action
rows:
  - category: Plugins
    description: |
      **GraphQL Rate Limiting Advanced plugin**
      <br><br>
      Schema validation has been updated so that Redis cluster mode is now supported. 
      This schema change does not impact other implementations of this plugin.
    action: |
      No
  - category: "kong.conf"
    description: |
      The default value of the [`dns_no_sync`](/gateway/configuration/#dns-no-sync) option has been changed to `off`.
    action: |
      Check if you need to adjust this value.

  - category: Plugins
    description: |
      **Session plugin**
      <br><br>
      Introduced the new configuration field `read_body_for_logout` with a default value of `false`.
      This change alters the behavior of `logout_post_arg` in such a way that it is no longer considered, unless `read_body_for_logout` is explicitly set to `true`.
      <br><br>
      This adjustment prevents the Session plugin from automatically reading request bodies for logout detection, particularly on POST requests.
    action: |
      If you are using `logout_post_arg` in your Session plugin configuration, set `read_body_for_logout` to `true` to activate it.
  - category: "kong.conf"
    description: |
      Manually specifying a `node_id` via Kong configuration (`kong.conf`) is deprecated.
      The `node_id` parameter is planned to be removed in a future version.
    action: |
      We recommend not manually specifying a `node_id` in configuration.
{% endtable %}


### Possible support required

Upgrades using the following features might require help from Kong.
      
Kong's support team provides advanced features and professional services tailored to meet 
specific business needs, including data migration, custom plugin integration, 
and seamless coordination with existing settings PDK.

{% table %}
columns:
  - title: Change
    key: description
  - title: Category
    key: category
  - title: Action Required
    key: action
rows:
  - category: Plugins
    description: |
      {{site.base_gateway}} now requires an Enterprise license to use dynamic plugin ordering.

    action: |
      If you have plugin configurations that use dynamic plugin ordering in a free Gateway installation, they won't work.
      Remove these configurations before upgrading, or reach out to [Kong Support](https://support.konghq.com).
  - category: Licensing
    description: |
      Free mode is deprecated and will be removed in a future 3.x version of {{site.ee_product_name}}.
      At that point, running {{site.base_gateway}} without a license will behave the same as running it with an expired license.
    action: |
      Try out [{{site.konnect_short_name}}](https://konghq.com/products/kong-konnect/register?utm_medium=referral&utm_source=docs&utm_content=upgrade-guide), or reach out to [Kong Sales](https://konghq.com/contact-sales?utm_medium=referral&utm_source=docs&utm_content=upgrade-guide) for a demo.
{% endtable %}
