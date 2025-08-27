### New features

The following table lists new features introduced in a 3.x release prior or equal to 3.4.0.0. 
These features may affect existing configurations.

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
      **Request Validator plugin**
      <br><br>
      The Request Validator plugin now allows requests carrying a 
      `content-type` with a parameter to match its `content-type` without a parameter.
    action: |
      No
  - category: DB config
    description: |
      The Data Plane configuration cache was removed. 
      Configuration persistence is now done automatically with LMDB.
      <br><br>
      The Data Plane config cache mechanism and its related configuration options 
      (`data_plane_config_cache_mode` and `data_plane_config_cache_path`) have been removed in favor of LMDB.
    action: |
      Remove parameters from {{site.base_gateway}} configuration.
  - category: DB config
    description: |
      Bumped the version number of declarative configuration to 3.0 for changes on `route.path`.
      <br><br>
      Declarative configurations using older versions are upgraded to 3.0 during migrations.
    action: |
      If any configurations are stored in a repository (following a GitOps model),
      these need to be upgraded using [`deck file convert`](/deck/file/convert/).
  - category: DB config
    description: Tags may now contain space characters.
    action: |
      No
  - category: "kong.conf"
    description: |
      The default value of `lua_ssl_trusted_certificate` has changed to system to automatically load the
      trusted CA list from the system CA store. 
    action: |
      If you don't have this field explicitly configured, make sure that the new default value's behavior
      of automatically pulling in all certs on the server suits your deployment. Otherwise, adjust the setting.
  - category: Plugins
    description: |
      **Rate Limiting, Rate Limiting Advanced, and Response Rate Limiting plugins**
      <br><br>
      The default policy for these plugins is now `local` for all deployment modes.
    action: |
      No
  - category: Plugins
    description: |
      Plugin batch queuing: **HTTP Log, StatsD, OpenTelemetry, and Datadog plugins**
      <br><br>
      The queuing system has been reworked, causing some plugin parameters to not function as expected anymore.
    action: | 
      If you use queues in these plugins, new parameters must be configured. 
      See each plugin's documentation for details.
      <br><br>
      The module `kong.tools.batch_queue` has been renamed to `kong.tools.batch` and the API was changed. 
      If your custom plugin uses queues, it must be updated to use the new parameters.

  - category: OpenSSL
    description: |
      > _Applies to 3.4.3.5 and later versions._
      <br><br>
      In OpenSSL 3.2, the default SSL/TLS security level has been changed from 1 to 2.
      <br><br>
      This means the security level is set to 112 bits of security and compression is disabled.
      As a result, the following are prohibited:
      <br><br>
      * RSA, DSA, and DH keys shorter than 2048 bits
      * ECC keys shorter than 224 bits
      * Any cipher suite using RC4
      * SSL version 3
    action: |
      Ensure that your configuration complies with the new security level requirements.
{% endtable %}

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
      Deprecated and stopped producing Debian 8 (Jessie) and Debian 10 (Buster) containers and packages.
    action: |
      Debian 11 and 12 are available. Upgrade to one of these versions before 
      upgrading to {{site.base_gateway}} 3.4.

  - category: Deployment
    description: |
      Deprecated and stopped producing Amazon Linux 1 containers and packages.
    action: |
       We recommend migrating to Amazon Linux 2 or another supported operating 
       system to continue receiving updates, security patches, and support from AWS.
  
  - category: Deployment
    description: |
      Deprecated and stopped producing Alpine Linux images and packages.
      <br><br>
      The underlying operating system (OS) for our convenience Docker tags 
      (for example, `latest`, `3.4.0.0`, `3.4`) has changed from Alpine to Ubuntu.
    action: |
      Review your Dockerfiles for OS-specific configuration and adjust as necessary.
      <br><br>
      If you are using one of the convenience images, adjust your configuration for Ubuntu.
      Otherwise, switch to an image using a specific OS tag 
      (for example, `3.4.0.0-debian`).

  - category: Deployment
    description: |
      Deprecated and stopped producing Ubuntu 18.04 (Bionic) packages, as Standard Support for 
      Ubuntu 18.04 has ended as of June 2023.
    action: |
      Ubuntu 20.04 and 22.04 are available. Upgrade to one of these versions before upgrading to {{site.base_gateway}} 3.4.

  - category: Plugins
    description: |
      The deprecated shorthands field in Kong plugin or DAO schemas was removed 
      in favor of the typed `shorthand_fields`. 
    action: |
      If your custom schemas still use `shorthands`, you need to update them to 
      use `shorthand_fields`. This update is necessary to ensure 
      compatibility with the latest version of {{site.base_gateway}}.
  
  - category: PDK
    description: |
      Support for the `legacy = true | false` attribute was removed from {{site.base_gateway}} 
      schemas and {{site.base_gateway}} field schemas.
    action: |
      You can no longer use the `legacy` attribute in your schemas. 
      
      Any references to `legacy=true | false` in your custom schemas should be 
      updated to conform to the latest schema specifications without the `legacy` attribute.
  
  - category: Nginx templates
    description: |
      The deprecated alias of `Kong.serve_admin_api` was removed. 
    action: |
      If your custom Nginx templates still use the alias, change it to `Kong.admin_content`.

  - category: PDK
    description: | 
      The {{site.base_gateway}} singletons module `kong.singletons` was removed in favor of the PDK `kong.*`.
    action: |
      Remove the `kong.singletons` module and use the `kong` global variable instead. 
      <br><br>
      For example: `singletons.db.daos` -> `kong.db.daos`
      
  - category: Tracing
    description: |
      `ngx.ctx.balancer_address` was removed in favor of `ngx.ctx.balancer_data`.
    action: |
      If you were previously using `ngx.ctx.balancer_address`, use `ngx.ctx.balancer_data` instead.
  
  - category: Router
    description: |
      The normalization rules for `route.path` have changed. 
      {{site.base_gateway}} now stores the unnormalized path, but the regex path always pattern-matches 
      with the normalized URI.
      <br><br>
      Previously, {{site.base_gateway}} replaced percent-encoding in the regex path pattern to
      ensure different forms of URI matches. That is no longer supported. 
      <br><br>
      Write all characters without percent-encoding, except for the reserved characters defined in 
      [RFC 3986](https://datatracker.ietf.org/doc/html/rfc3986), 
       
    action: |
      After the upgrade, if you configure Routes using the old method, 
      you will receive an alert and need to reconfigure the affected Routes using the new Route 
      configuration method.

  - category: Router
    description: |
      {{site.base_gateway}} no longer uses a heuristic to guess whether a Route path is a regex pattern. 
      From 3.0 onward, all regex paths must start with the `~` prefix, and all paths that don't start with `~` are
      considered plain text. 
    action: |
      No manual migration required.       
      The migration process should automatically convert the regex paths when upgrading from 2.8 to 3.4. 
      <br><br>
      Going forward, when writing a regex, it must start with the `~` symbol.

  - category: Tracing
    description: |
      Support for the `nginx-opentracing` module is deprecated as of 3.0 and will be removed from {{site.base_gateway}} in 4.0.
    action: |
      No

  - category: Admin API
    description: |
      The Admin API endpoints `/vitals/reports` and `/vitals/reports/:entity_type` have been removed. 

    action: |
      After the upgrade, use one of the following endpoints from the Vitals API instead:
      <br><br>
      * For `/vitals/reports/consumer`, use `/<workspace_name>/vitals/status_codes/by_consumer` instead
      * For `/vitals/reports/service`, use `/<workspace_name>/vitals/status_codes/by_service` instead
      * For `/vitals/reports/hostname`, use `/<workspace_name>/vitals/nodes` instead

  - category: Admin API
    description: |
      POST requests on `/targets` endpoints are no longer able to update existing entities. 
      They are only able to create new ones.

    action: |
      If you have scripts that use POST requests to modify `/targets`, change them to PUT requests to the appropriate 
      endpoints before updating to {{site.base_gateway}} 3.4. 

  - category: Admin API
    description: |
      Insert and update operations on duplicated targets return a 409 error.
    action: |
      If you have duplicate targets, remove them.

  - category: PDK
    description: |
      The `kong.request.get_path()` PDK function now performs path normalization on the string that is returned to the caller. 
      The raw, non-normalized version of the request path can be fetched via `kong.request.get_raw_path()`. 
    action: |
      No

  - category: PDK
    description: |
      `pdk.response.set_header()`, `pdk.response.set_headers()`, and `pdk.response.exit()` now ignore and 
      emit warnings for manually set Transfer-Encoding headers. 
    action: |
      No

  - category: Go PDK
    description: |
      The `go_pluginserver_exe` and `go_plugins_dir` directives are no longer supported. 
    action: |
      If you are using Go plugin server, migrate your plugins to use the Go PDK before upgrading.

  - category: Plugins
    description: |
      The {{site.base_gateway}} constant `CREDENTIAL_USERNAME` with the value of `X-Credential-Username` has been removed. 
      <br><br>
      Kong plugins also don't support this constant.
    action: |
      Use the constant `CREDENTIAL_IDENTIFIER` (`X-Credential-Identifier`) when setting the upstream 
      headers for a credential. 

  - category: Declarative config
    description: |
      It is no longer possible to use `.lua` format to import a declarative configuration file via
      the Kong CLI tool. Only JSON and YAML formats are supported. 
    action: |
      If your update with {{site.base_gateway}} involves executing `kong config db_import config.lua`,
      convert the `config.lua` file into a `config.json` or `config.yml` file before upgrading. 

  - category: Plugins
    description: |
      DAOs in plugins must be listed in an array, so that their loading order is explicit. 
      Loading them in a hash-like table is no longer supported.
    action: |
      Review your custom plugins. If you have plugins that use hash-like tables for listing DAOs, convert them into arrays.

  - category: Plugins
    description: |
      Plugins now must have a valid PRIORITY (integer) and VERSION (`x.y.z` format) field in their `handler.lua` 
      file, otherwise the plugin will fail to load.
    action: |
      Review your custom plugins. Add a PRIORITY and VERSION in their respective formats to all of your custom plugins.

  - category: PDK
    description: |
      The `kong.plugins.log-serializers.basic` library was removed in favor of the PDK function `kong.log.serialize`. 
    action: |
      Upgrade your plugins to use the new PDK function.

  - category: Plugins
    description: |
      The support for deprecated legacy plugin schemas was removed. 
    action: |
      If your custom plugins still use the old (0.x era) schemas, you must upgrade them. 

  - category: Plugins
    description: |
      Updated the priority for some plugins.
      <br><br>
      This is important for those who run custom plugins as it may affect the sequence in which your plugins are executed.
      This does not change the order of execution for plugins in a standard {{site.base_gateway}} installation.
      <br><br>
      Old and new plugin priority values:
      <br><br>
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
      - `vault-auth` changed from `1003` to `1350`
  
    action: |
      Review custom plugin priorities. 
      If any of the changes in priorities break expected behaviour, adjust as necessary.

  - category: Plugins
    description: |
      **JWT plugin**
      <br><br>
      The authenticated JWT is no longer put into the Nginx context (`ngx.ctx.authenticated_jwt_token`).
    action: |
      Custom plugins which depend on that value being set under that name must be updated to use 
      {{site.base_gateway}}'s shared context instead (`kong.ctx.shared.authenticated_jwt_token`) before upgrading to 3.4.

  - category: Plugins
    description: |
      **JWT plugin**
      <br><br>
      The JWT plugin now denies any request that has different tokens in the JWT token search locations. 
    action: |
      No

  - category: Plugins
    description: |
      **StatsD plugin** 
      <br><br>
      Any metric name that is related to a Gateway Service now has a `service.` prefix: 
      <br><br>
      `kong.service.<service_identifier>.request.count`.
      * The metric `kong.<service_identifier>.request.status.<status>` has been renamed to 
      `kong.service.<service_identifier>.status.<status>`.
      * The metric `kong.<service_identifier>.user.<consumer_identifier>.request.status.<status>` has been renamed to 
      `kong.service.<service_identifier>.user.<consumer_identifier>.status.<status>`.
      * The metric `*.status.<status>.total` from metrics `status_count` and `status_count_per_user` has been removed.
    action: |
      No

  - category: Plugins
    description: |
      **Proxy Cache, Proxy Cache Advanced, and GraphQL Proxy Cache Advanced plugins**
      <br><br>
      These plugins don't store response data in `ngx.ctx.proxy_cache_hit` anymore. 
      They store it in `kong.ctx.shared.proxy_cache_hit`.
    action: |
      Logging plugins that need the response data must now read it from `kong.ctx.shared.proxy_cache_hit`.

  - category: DB config
    description: |
      Added the `allow_debug_header` configuration property to `kong.conf` to constrain the `Kong-Debug` header for debugging. 
      This option defaults to `off`.
    action: |
      If you were previously relying on the `Kong-Debug` header to provide debugging information, 
      set `allow_debug_header=on` to continue doing so.
      <br><br>
      If you're using Response Transformer plugin as a workaround to remove headers,
      you no longer need the plugin. Disable and remove it.

  - category: Plugins
    description: |
      The `lua-resty-session` library has been upgraded to v4.0.0. This version includes a full 
      rewrite of the session library, and is not backwards compatible.
      <br><br>
      This library is used by the following plugins: Session, OpenID Connect, and SAML. 
      Many session parameters used by these plugins have been renamed or removed. 
      <br><br>
      This also affects any session configuration that uses the Session or OpenID Connect 
      plugin in the background, including sessions for Kong Manager and Dev Portal.

    action: |
      All existing sessions are invalidated when upgrading to this version. 
      For sessions to work as expected in this version, all nodes must run {{site.base_gateway}} 3.4.x.
      <br><br>
      For that reason, we recommend that during upgrades, proxy nodes with mixed versions run for as little time as possible. 
      During that time, the invalid sessions could cause failures and partial downtime.
      <br><br>
      You can expect the following behavior:
      <br><br>
      * **After upgrading the Control Plane**: Existing Kong Manager and Dev Portal sessions will be 
      invalidated and all users will be required to log back in.
      * **After upgrading the Data Planes**: Existing proxy sessions will be invalidated. 
      If you have an IdP configured, users will be required to log back into the IdP.
      <br><br>
      **After you have upgraded** all of your CP and DP nodes to 3.4 and ensured that your environment is stable, 
      you can update parameters to their new renamed versions. Although your configuration will continue to work as 
      previously configured, we recommend adjusting your configuration to avoid future unexpected behavior.
      <br><br>
      See the [breaking changes doc](/gateway/breaking-changes/) for all session configuration 
      changes and guidance on how to convert your existing session configuration.

  - category: DB config
    description: |
      Cassandra DB support has been removed. It is no longer supported as a data store for {{site.base_gateway}}.
    action: |
      Reach out to Kong Support for help with migrating Cassandra to PostgreSQL.

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
  - category: Router
    description: | 
      Regex look-around and backreference support in the `atc-router` have been removed. 
      These are rarely used features and removing support for them improves the speed of our regex matching.
      <br><br>
      If your current regexes use look-around or backreferences, you will receive an error when attempting to start {{site.base_gateway}}, 
      showing exactly which regex is incompatible. 
      
    action: |
      To ensure consistency of behavior after the upgrade, set `router_flavor = traditional`, 
      or change the regex to remove look-around or backreferences.
      <br><br>
      Review the regex paths and ensure these removed features are not in use. 
      Update the regex router accordingly.

  - category: Plugins
    description: |
      **ACL, Bot Detection, and IP Restriction plugins**
      <br><br>
      Removed the deprecated `config.blacklist` and `config.whitelist` configuration parameters.

    action: |
      Remove the deprecated `config.blacklist` and `config.whitelist` configuration parameters.
      Use `config.denylist` and `config.allowlist` instead.

  - category: Plugins
    description: |
      **ACME plugin** 
      <br><br>
      The default value of the `config.auth_method` configuration parameter is now `token`.

    action: |
      Following the upgrade, the `config.auth_method` will persist as `null`
      (if this configuration is not used), which deviates from the new version's default 
      setting of `token`. Update the value if necessary.

  - category: Plugins
    description: |
      **AWS Lambda plugin**
      <br><br>
      * The AWS region is now required. You can set it through the plugin configuration with the `config.aws_region` field parameter, or with environment variables.
      * The plugin now allows host and `config.aws_region` fields to be set at the same time, and always applies the SigV4 signature. 

    action: |
      Review your configuration or consult with the Kong Support team.

  - category: Plugins
    description: |
      **HTTP Log plugin**
      <br><br>
      The `config.headers` field now only takes a single string per header name, 
      where it previously took an array of values.

    action: |
      Review your configuration or consult with the Kong Support team.

  - category: Plugins
    description: |
      **Prometheus plugin**
      <br><br>
      Complete overhaul of the plugin:
      <br><br>
      * High cardinality metrics are now disabled by default.
      * Decreased performance penalty to proxy traffic when collecting metrics.
      * The following metric names were adjusted to add units to standardize where possible:
        * `http_status` to `http_requests_total`.
        * `latency` to `kong_request_latency_ms` (HTTP), `kong_upstream_latency_ms`, `kong_kong_latency_ms`, and `session_duration_ms` (stream).

            {{site.base_gateway}} latency and upstream latency can operate at orders of different magnitudes. Separate these buckets to reduce memory overhead.

        * `kong_bandwidth` to `kong_bandwidth_bytes`.
        * `nginx_http_current_connections` and `nginx_stream_current_connections` were merged into to `nginx_hconnections_total`
        *  `request_count` and `consumer_status` were merged into `http_requests_total`.

            If the `per_consumer` config is set to `false`, the `consumer` label will be empty. If the `per_consumer` config is `true`, the `consumer` label will be filled.
            
      * Removed the following metric: `http_consumer_status`
      * New metrics:
        * `session_duration_ms`: monitoring stream connections.
        * `node_info`: Single gauge set to 1 that outputs the node's ID and {{site.base_gateway}} version.

      * `http_requests_total` has a new label, `source`. It can be set to `exit`, `error`, or `service`.
      * All memory metrics have a new label: `node_id`.
      * Updated the Grafana dashboard that comes packaged with {{site.base_gateway}}

    action: |
      To make sure you don't miss any data, adjust your plugin configuration to use the new settings.
      <br><br>
      If you have any custom dashboards or have written any custom PromQL, review them and ensure the name changes haven't broken anything.

  - category: Plugins
    description: |
      **StatsD Advanced plugin**
      <br><br>
      The StatsD Advanced plugin has been deprecated and will be removed in 4.0. 
      All capabilities are now available in the StatsD plugin.

    action: |
      We recommend migrating over to the StatsD plugin, however StatsD Advanced continues to function in 3.4.
  - category: Plugins
    description: | 
      **Serverless Functions (`post-function` or `pre-function`)**
      <br><br>
      Removed the deprecated `config.functions` configuration parameter from the Serverless Functions 
      plugins' schemas.

    action: |
      Use the `config.access` phase instead.

  - category: DB config
    description: |
      The default PostgreSQL SSL version has been bumped to TLS 1.2. In `kong.conf`:
      <br><br>
      * The default [`pg_ssl_version`](/gateway/configuration/#datastore-section)
      is now `tlsv1_2`.
      * Constrained the valid values of this configuration option to only accept the following: `tlsv1_1`, `tlsv1_2`, `tlsv1_3` or `any`.
      <br><br>
      This mirrors the setting `ssl_min_protocol_version` in PostgreSQL 12.x and onward. 
      See the [PostgreSQL documentation](https://postgresqlco.nf/doc/en/param/ssl_min_protocol_version/)
      for more information about that parameter.
  
    action: |
      Change the value in your `kong.conf` or environment variables from `tlsv1_0` to `tlsv1_2`.
      <br><br>
      To use the default setting in `kong.conf`, verify that your PostgreSQL server supports TLS 1.2 or higher versions, or set the TLS version yourself. 
      TLS versions lower than `tlsv1_2` are already deprecated and considered insecure from PostgreSQL 12.x onward.
  
  - category: Admin API
    description: |
      The `/consumer_groups/:id/overrides` endpoint is deprecated in favor of a more generic plugin scoping mechanism. 

    action: |
      Instead of setting overrides, you can apply a plugin instance to a Consumer Group entity. See the 
      [Rate Limiting Advanced](/plugins/rate-limiting-advanced/examples/)
      documentation for an example.

  - category: Admin API
    description: |
      The `admin_api_uri` property is now deprecated and will be fully removed in a future version of {{site.base_gateway}}.
    action: |
      Rename the configuration property `admin_api_uri` to `admin_gui_api_url`. 

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
      As of 3.0, {{site.base_gateway}}'s schema library's `process_auto_fields` function doesn't make deep copies of data that is passed to it when the given context is `select`.
      This was done to avoid excessive deep copying of tables where we believe the data most of the time comes from a driver like `pgmoon` or `lmdb`.
      <br><br>
      If a custom plugin relied on `process_auto_fields` not overriding the given table, it must make its own copy before passing it to the function. 

    action: |
      If a custom plugin needs to fetch data by deep copying, perform it on the `select` context before calling the function. 
      <br><br>
      Define `context = “select”` to trigger deep copying:
      <br><br>
      ```lua
      local is_select = context == "select"
        if not is_select then
          data = tablex.deepcopy(data)
        end
      ```

  - category: Plugins
    description: |
      The list of reported plugins available on the server now returns a table of 
      metadata per plugin instead of the boolean `true`. 
      <br><br>
      For example:
      <br><br>
      ```json
      plugins": {
        "available_on_server": {
            "acl": "3.0.1",
            "acme": "0.4.0",
            "aws-lambda": "3.6.3",
            "azure-functions": "1.0.1",
            "basic-auth": "2.2.0",
            "bot-detection": "2.0.0",
        ...
        }
      }
      ```
    action: |
      Adapt to use the new metadata instead of boolean values.

{% endtable %}


### Notifications of changed behavior

The following table lists changes that you should be aware of, but require no action.

{% table %}
columns:
  - title: Change
    key: description
  - title: Category
    key: category
  - title: Action Required
    key: action
rows:
  - category: PDK
    description: |
      The PDK is no longer versioned.
    action: |
      No

  - category: DB config
    description: |
      The migration helper library (mostly used for Cassandra migrations) is no longer supplied with {{site.base_gateway}}. 
    action: |
      No

  - category: DB config
    description: |
      PostgreSQL migrations can now have an `up_f` part like Cassandra migrations, designating a function to call. 
      The `up_f` part is invoked after the `up` part has been executed against the database.
    action: |
      No

  - category: Plugins
    description: |
      Kong plugins are no longer individually versioned.
      Starting in 3.0.0, every plugin's version has been updated to match {{site.base_gateway}}'s version.
    action: |
      No

  - category: Plugins
    description: |
      **HTTP Log plugin** 
      <br><br>
      If the log server responds with a 3xx HTTP status code, the plugin now considers it to be 
      an error and retries according to the retry configuration. Previously, 3xx status codes would be interpreted 
      as a success, causing the log entries to be dropped. 

    action: |
      No

  - category: Plugins
    description: |
      **Serverless Functions (post-function or pre-function)**
      <br><br>
      `kong.cache` now points to a cache instance that is 
      dedicated to the Serverless Functions plugins. It does not provide access to the global {{site.base_gateway}} cache. 
      Access to certain fields in `kong.conf` has also been restricted. 

    action: |
      No

  - category: Plugins
    description: |
      **Zipkin plugin**
      <br><br>
      This plugin now uses queues for internal buffering. 
      The standard queue parameter set is available to control queuing behavior.
    action: |
      No
      
{% endtable %}

### kong.conf changes

The following table lists changes to parameters managed in the [`kong.conf`](/gateway/configuration/) configuration file:

{% table %}
columns:
  - title: 2.8
    key: 28
  - title: 3.4
    key: 34
rows:
  - 28: "`data_plane_config_cache_mode = unencrypted`"
    34: "Removed in 3.4"
  - 28: "`data_plane_config_cache_path`"
    34: "Removed in 3.4"
  - 28: "`admin_api_uri`"
    34: "Deprecated. Use `admin_gui_api_url` instead."
  - 28: "`database` Cassandra support"
    34: "Accepted values are `postgres` and `off`. All Cassandra options have been removed."
  - 28: "`pg_keepalive_timeout = 60000`"
    34: |
      You can now specify the maximal idle timeout (in ms) for the Postgres connections in the pool.
      If this value is set to 0 then the timeout interval is unlimited. 
      If not specified, this value will be the same as `lua_socket_keepalive_timeout`.
  - 28: "`worker_consistency = strict`"
    34: "`worker_consistency = eventual`"
  - 28: "`prometheus_plugin_*`"
    34: "Disabled Prometheus plugin high-cardinality metrics."
  - 28: "`lua_ssl_trusted_certificate` with no default value."
    34: "Default value: `lua_ssl_trusted_certificate = system`"
  - 28: "`pg_ssl_version = tlsv1`"
    34: "`pg_ssl_version = tlsv1_2`"
  - 28: "--"
    34: "New parameter:`allow_debug_header = off`"
{% endtable %}
