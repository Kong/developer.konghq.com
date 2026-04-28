{% table %}
columns:
  - title: Category
    key: category
  - title: Impact
    key: impact
  - title: Action
    key: action
rows:
  - category: PostgreSQL database
    impact: |
      When the PostgreSQL configuration contains `pg_ssl_verify = off`, {{site.base_gateway}} can fail to start.
    action:
      Add the PostgreSQL server's certificate to [`lua_ssl_trusted_certificate`](/gateway/configuration/#lua-ssl-trusted-certificate) and set [`pg_ssl_verify`](/gateway/configuration/#pg-ssl-verify) to `on`.

  - category: Gateway Services
    impact: |
      Gateway Service entities with `tls_verify = false` where the Service protocol is `https`, `tls`, `grpcs`, or `wss` are affected as follows:

      - **Traditional mode:** Existing Gateway Service entities with `tls_verify = false` can still be loaded and used, but updating the Service's config with `tls_verify = false` returns an error from the Admin API.
      - **DB-less mode:** {{site.base_gateway}} will fail to boot if the declarative configuration contains a Service with `tls_verify = false`.
      - **Hybrid mode (on-prem):** The data plane can boot but can't receive a valid configuration from the control plane, and errors will appear in the data plane log.
    action: |
      Update the schema for all affected Gateway Services (where protocol is `https`, `tls`, `grpcs`, or `wss`) by setting `tls_verify = true`.

  - category: Plugins and Redis Partials
    impact: |
      Any plugin or [Redis Partial](/gateway/entities/partial/) configured with one of the affected certificate verification fields below is affected by this change. See the full list of plugins and fields in the following table.
      <br><br>
      If you have existing plugins using these values, {{site.base_gateway}}'s behavior differs based on deployment mode:
      - **Traditional mode:** Plugins can still be loaded and used, but updating the plugin's config returns an error from the Admin API.
      - **DB-less mode:** {{site.base_gateway}} will fail to boot if the declarative configuration contains these values.
      - **Hybrid mode (on-prem):** The data plane can't receive a valid configuration from the control plane, and errors will appear in the data plane log.
    action: |
      Update the schema for all affected plugins by setting these values to `true`.
      See the full list of affected plugins and fields in the table below.
      <br>
      To see your plugin's schema, find your plugin on the [Plugin Hub](/plugins/), then open the **Configuration reference** tab.

  - category: HashiCorp Vault
    impact: |
      HashiCorp Vault won't function if [`lua_ssl_trusted_certificate`](/gateway/configuration/#lua-ssl-trusted-certificate) isn't configured with a valid certificate.
    action: |
      Add the HashiCorp Vault server's certificate to [`lua_ssl_trusted_certificate`](/gateway/configuration/#lua-ssl-trusted-certificate).

  - category: Custom plugins
    impact: |
      Custom plugins that use `https`, `tls`, `grpcs`, or `wss` may not work if their implementation doesn't verify the server certificate.
    action: |
      Manually update the custom plugin implementation to verify the server certificate.
  - category: Event Hooks
    impact: |
      The webhook handler's `ssl_verify` setting is now `true` by default.
    action: |
      Ensure your webhook endpoints have a valid TLS certificate.
{% endtable %}

To revert to the old behavior, set `tls_certificate_verify` to `off`.

The following table lists all of the plugin fields affected by the TLS/SSL certificate verification changes in {{site.base_gateway}} 3.14:

{% table %}
columns:
  - title: Plugin
    key: plugin
  - title: Affected fields
    key: fields
rows:
  - plugin: "[ACE](/plugins/ace/)"
    fields: "`rate_limiting.redis.ssl_verify`"
  - plugin: "[ACME](/plugins/acme/)"
    fields: |
      * `storage_config.redis.ssl_verify`
      * `storage_config.vault.tls_verify`
  - plugin: "[AI AWS Guardrails](/plugins/ai-aws-guardrails/)"
    fields: "`ssl_verify`"
  - plugin: "[AI Azure Content Safety](/plugins/ai-azure-content-safety/)"
    fields: "`ssl_verify`"
  - plugin: "[AI LLM as Judge](/plugins/ai-llm-as-judge/)"
    fields: "`https_verify`"
  - plugin: "[AI Proxy Advanced](/plugins/ai-proxy-advanced/)"
    fields: |
      * `vectordb.pgvector.ssl_verify`
      * `vectordb.redis.ssl_verify`
  - plugin: "[AI RAG Injector](/plugins/ai-rag-injector/)"
    fields: |
      * `vectordb.pgvector.ssl_verify`
      * `vectordb.redis.ssl_verify`
  - plugin: "[AI Rate Limiting Advanced](/plugins/ai-rate-limiting-advanced/)"
    fields: "`redis.ssl_verify`"
  - plugin: "[AI Semantic Cache](/plugins/ai-semantic-cache/)"
    fields: |
      * `vectordb.pgvector.ssl_verify`
      * `vectordb.redis.ssl_verify`
  - plugin: "[AI Semantic Prompt Guard](/plugins/ai-semantic-prompt-guard/)"
    fields: |
      * `vectordb.pgvector.ssl_verify`
      * `vectordb.redis.ssl_verify`
  - plugin: "[AI Semantic Response Guard](/plugins/ai-semantic-response-guard/)"
    fields: |
      * `vectordb.pgvector.ssl_verify`
      * `vectordb.redis.ssl_verify`
  - plugin: "[AWS Lambda](/plugins/aws-lambda/)"
    fields: "`ssl_verify`"
  - plugin: "[Azure Functions](/plugins/azure-functions/)"
    fields: "`https_verify`"
  - plugin: "[Basic Auth](/plugins/basic-auth/)"
    fields: "`brute_force_protection.redis.ssl_verify`"
  - plugin: "[Confluent](/plugins/confluent/)"
    fields: |
      * `security.ssl_verify`
      * `schema_registry.confluent.authentication.oauth2_client.ssl_verify`
  - plugin: "[Confluent Consume](/plugins/confluent-consume/)"
    fields: |
      * `security.ssl_verify`
      * `schema_registry.confluent.authentication.oauth2_client.ssl_verify`
      * `topics.schema_registry.confluent.authentication.oauth2_client.ssl_verify`
  - plugin: "[Datakit](/plugins/datakit/)"
    fields: |
      * `nodes[].ssl_verify` (for nodes with `type: call`)
      * `resources.cache.redis.ssl_verify`
  - plugin: "[Forward Proxy](/plugins/forward-proxy/)"
    fields: "`https_verify`"
  - plugin: "[GraphQL Proxy Cache Advanced](/plugins/graphql-proxy-cache-advanced/)"
    fields: "`redis.ssl_verify`"
  - plugin: "[GraphQL Rate Limiting Advanced](/plugins/graphql-rate-limiting-advanced/)"
    fields: "`redis.ssl_verify`"
  - plugin: "[Header Cert Auth](/plugins/header-cert-auth/)"
    fields: "`ssl_verify`"
  - plugin: "[HTTP Log](/plugins/http-log/)"
    fields: "`ssl_verify`"
  - plugin: "[JWT Signer](/plugins/jwt-signer/)"
    fields: |
      * `access_token_endpoints_ssl_verify`
      * `channel_token_endpoints_ssl_verify`
      * The `/rotate` endpoint now enables certificate verification by default
  - plugin: "[Kafka Consume](/plugins/kafka-consume/)"
    fields: |
      * `security.ssl_verify`
      * `schema_registry.confluent.authentication.oauth2_client.ssl_verify`
      * `topics.schema_registry.confluent.authentication.oauth2_client.ssl_verify`
  - plugin: "[Kafka Log](/plugins/kafka-log/)"
    fields: |
      * `security.ssl_verify`
      * `schema_registry.confluent.authentication.oauth2_client.ssl_verify`
  - plugin: "[Kafka Upstream](/plugins/kafka-upstream/)"
    fields: |
      * `security.ssl_verify`
      * `schema_registry.confluent.authentication.oauth2_client.ssl_verify`
  - plugin: "[LDAP Auth](/plugins/ldap-auth/)"
    fields: "`verify_ldap_host`"
  - plugin: "[LDAP Auth Advanced](/plugins/ldap-auth-advanced/)"
    fields: "`verify_ldap_host`"
  - plugin: "[mTLS Auth](/plugins/mtls-auth/)"
    fields: "`ssl_verify`"
  - plugin: "[OpenID Connect](/plugins/openid-connect/)"
    fields: |
      * `ssl_verify`
      * `cluster_cache_redis.ssl_verify`
      * `redis.ssl_verify`
      * `session_memcached_ssl_verify`
  - plugin: "[Proxy Cache Advanced](/plugins/proxy-cache-advanced/)"
    fields: "`redis.ssl_verify`"
  - plugin: "[Rate Limiting](/plugins/rate-limiting/)"
    fields: "`redis.ssl_verify`"
  - plugin: "[Rate Limiting Advanced](/plugins/rate-limiting-advanced/)"
    fields: "`redis.ssl_verify`"
  - plugin: "[Redis Partials](/gateway/entities/partial/)"
    fields: "`ssl_verify`"
  - plugin: "[Request Callout](/plugins/request-callout/)"
    fields: |
      * `cache.redis.ssl_verify`
      * `callouts.request.http_opts.ssl_verify`
  - plugin: "[Response Rate Limiting](/plugins/response-ratelimiting/)"
    fields: "`redis.ssl_verify`"
  - plugin: "[SAML](/plugins/saml/)"
    fields: "`redis.ssl_verify`"
  - plugin: "[Service Protection](/plugins/service-protection/)"
    fields: "`redis.ssl_verify`"
  - plugin: "[Solace Consume](/plugins/solace-consume/)"
    fields: "`session.ssl_validate_certificate`"
  - plugin: "[Solace Log](/plugins/solace-log/)"
    fields: "`session.ssl_validate_certificate`"
  - plugin: "[Solace Upstream](/plugins/solace-upstream/)"
    fields: "`session.ssl_validate_certificate`"
  - plugin: "[TCP Log](/plugins/tcp-log/)"
    fields: "`ssl_verify`"
  - plugin: "[Upstream OAuth](/plugins/upstream-oauth/)"
    fields: |
      * `client.ssl_verify`
      * `cache.redis.ssl_verify`
{% endtable %}