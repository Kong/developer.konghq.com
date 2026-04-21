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
  - category: Security
    description: |
      The SHA1 algorithm has been deprecated or removed in several places and the default algorithm has changed to SHA256.
      <br><br>
      For the [Event Hooks entity](/gateway/entities/event-hook/), this is a breaking change.
      Event hook calls are now signed with HMAC-SHA256 instead of HMAC-SHA1.
      <br><br>
      For the following plugins, the SHA1 algorithm is deprecated but still supported in existing configurations:
      <br><br>
      * [Basic Auth](/plugins/basic-auth/): Uses SHA256 by default in new configurations.
      * [HMAC Auth](/plugins/hmac-auth/): HMAC-SHA1 is no longer included in the default set of algorithms.
      * [OAuth2](/plugins/oauth2/): Uses SHA256 for the access token cache key instead of SHA1.
    action: |
      Update your Event Hook configurations to account for HMAC-SHA256 signing.
      <br><br>
      We strongly recommend updating plugin configurations to use SHA256 whenever possible.
  - category: Security
    description: |
      The [`untrusted_lua`](/gateway/configuration/#untrusted-lua) configuration option introduces two new modes: `strict` and `lax`, in addition to the existing `sandbox` mode. The default value has changed from `sandbox` to `strict`.
      <br><br>
      * `strict` (new default): Does not permit network operations. Cannot be extended via `untrusted_lua_sandbox_requires` or `untrusted_lua_sandbox_environment`.
      * `lax`: Permits untrusted Lua code to perform network operations.
      * `sandbox`: Previous default.
      <br><br>
      
      Plugins that rely on capabilities previously allowed by `sandbox` mode may fail.
    action: |
      Review any plugins that use Lua sandbox capabilities.
      To revert to the old behavior, set [`untrusted_lua`](/gateway/configuration/#untrusted-lua) to `sandbox` or `on`. 
      <br><br>
      
      {:.warning}
      > These options are not recommended for security reasons.
      <br><br>
      For more information, see [Sandboxing](/plugins/pre-function/#sandboxing).
  - category: SSL
    description: |
      The {{site.base_gateway}} global configuration option [`tls_certificate_verify`](/gateway/configuration/#tls-certificate-verify) now defaults to `on`. This affects a number of entities.
    action: |
      The recommended action depends on the affected item.
      See the following table of [TLS certificate changes](#tls-certificate-changes) for a breakdown and recommended actions for each item.
      <br><br>
      To revert to the old behavior for all of the affected configurations, set [`tls_certificate_verify`](/gateway/configuration/#tls-certificate-verify) to `off`.
{% endtable %}

#### TLS certificate changes

The following configurations are affected by the `tls_certificate_verify` default change:

{% table %}
columns:
  - title: Affected config object
    key: description
  - title: Category
    key: category
  - title: Action Required
    key: action
rows:
  - category: SSL
    description: |
      **PostgreSQL**: 
      When `pg_ssl_verify = off`, {{site.base_gateway}} can fail to start.
    action: |
      Add the PostgreSQL server's certificate to [`lua_ssl_trusted_certificate`](/gateway/configuration/#lua-ssl-trusted-certificate) and set [`pg_ssl_verify`](/gateway/configuration/#pg-ssl-verify) to `on`.
  - category: SSL
    description: |
      **Gateway Services**: [Gateway Service](/gateway/entities/service/) entities with `tls_verify = false` where the protocol is `https`, `tls`, `grpcs`, or `wss` are affected:
      <br><br>
      * **Traditional mode**: The Service can still be loaded and used, but updating its config with `tls_verify = false` returns an error from the Admin API.
      * **DB-less mode**: {{site.base_gateway}} will fail to boot if the declarative configuration contains a Service with `tls_verify = false`.
      * **Hybrid mode**: The data plane can boot but can't receive a valid configuration from the control plane.
    action: |
      Update all affected Gateway Services (where protocol is `https`, `tls`, `grpcs`, or `wss`) by setting `tls_verify = true`.
  - category: SSL
    description: |
      **Plugins and Redis Partials**: Any plugin configured with one of the affected certificate verification fields, either directly or through a [Redis Partial](/gateway/entities/partial/), is affected:
      <br><br>
      * **Traditional mode**: The plugin can still be loaded and used, but updating its config returns an error from the Admin API.
      * **DB-less mode**: {{site.base_gateway}} will fail to boot if the declarative configuration contains these values.
      * **Hybrid mode**: The data plane can't receive a valid configuration from the control plane.
    action: |
      Update all affected plugin configurations by setting `ssl_verify` (or the equivalent field) to `true`.
      See the [full list of affected plugins and fields](/gateway/breaking-changes/#tls-certificate-verify-by-default).
  - category: SSL
    description: |
      **HashiCorp Vault**: HashiCorp Vault won't function if [`lua_ssl_trusted_certificate`](/gateway/configuration/#lua-ssl-trusted-certificate) isn't configured with a valid certificate.
    action: |
      Add the HashiCorp Vault server's certificate to [`lua_ssl_trusted_certificate`](/gateway/configuration/#lua-ssl-trusted-certificate).
  - category: SSL
    description: |
      **Custom plugins**: Custom plugins that use `https`, `tls`, `grpcs`, or `wss` may not work if their implementation doesn't verify the server certificate.
    action: |
      Update your custom plugin implementation to verify the server certificate.
  - category: SSL
    description: |
      **Event Hooks**: The webhook handler's `ssl_verify` setting is now `true` by default.
    action: |
      Ensure your webhook endpoints have a valid TLS certificate.
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
      The default setting for [Route](/gateway/entities/route/) protocols has changed from `http,https` to `https`.
      <br><br>
      New Routes will have this default value, while existing Routes are unaffected.
    action: |
      If you have any automation that creates Routes, update your configuration to set the required protocol explicitly.
  - category: Plugins
    description: |
      `hide_credentials` is now set to `true` by default in the following plugins:
      <br><br>
      * [Basic Auth](/plugins/basic-auth/)
      * [HMAC Auth](/plugins/hmac-auth/)
      * [Key Auth](/plugins/key-auth/)
      * [Key Auth - Encrypted](/plugins/key-auth-enc/)
      * [LDAP Auth](/plugins/ldap-auth/)
      * [LDAP Auth Advanced](/plugins/ldap-auth-advanced/)
      * [OAuth 2.0 Authentication](/plugins/oauth2/)
      * [OAuth 2.0 Introspection](/plugins/oauth2-introspection/)
      * [OpenID Connect](/plugins/openid-connect/)
      * [Vault Auth](/plugins/vault-auth/)
      <br><br>
      
      This change doesn't affect existing plugins, but new plugins will have this setting configured by default.
    action: |
      Review any automation that creates new plugin configurations, and adjust if needed.
  - category: DB config
    description: |
      {{site.base_gateway}} now validates the database connection configuration at startup and won't start if errors are detected.
    action: |
      Before upgrading, verify that your database connection settings in `kong.conf` are correct and that the database is reachable.
  - category: Plugins
    description: |
      **OpenTelemetry**
      <br><br>
      The `config.access_logs_endpoint` parameter has changed to [`config.access_logs.endpoint`](/plugins/opentelemetry/reference/#schema--config-access-logs-endpoint).
      The old field is deprecated and will be removed in a future version.
    action: |
      Update your OpenTelemetry plugin configuration to use `config.access_logs.endpoint`.
  - category: Plugins
    description: |
      **OpenID Connect**
      <br><br>
      The following header claims fields have been replaced with new fields:
      <br><br>
      * `config.upstream_headers_claims` and `config.upstream_headers_names` → replaced by `config.upstream_headers`
      * `config.downstream_headers_claims` and `config.downstream_headers_names` → replaced by `config.downstream_headers`
      <br><br>

      The new fields support nested claims. The old fields are deprecated and will be removed in a future version.
    action: |
      Update your OpenID Connect plugin configuration to use `config.upstream_headers` and `config.downstream_headers`.
  - category: Plugins
    description: |
      **OpenID Connect**
      <br><br>
      The `config.consumer_claim` field has been converted to [`config.consumer_claims`](/plugins/openid-connect/reference/#schema--config-consumer-claims).
      The parameter now accepts an array of arrays instead of an array of strings.
      <br><br>
      The old `config.consumer_claim` field is deprecated and will be removed in a future version.
    action: |
      Update your OpenID Connect plugin configuration to use `config.consumer_claims`.
{% endtable %}
