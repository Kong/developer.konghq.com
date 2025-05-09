---
content_type: reference
---

## Changelog

### {{site.base_gateway}} 3.8.x
* Fixed an issue where the DP would report that deprecated config fields were used when configuration was pushed from the CP.
  [#13069](https://github.com/Kong/kong/issues/13069)
* Fixed an issue where username and password were not accepted as valid authentication methods.
  [#13496](https://github.com/Kong/kong/issues/13496)
  
### {{site.base_gateway}} 3.7.x
* Fixed an issue where the certificate was not successfully renewed during ACME renewal.
[#12773](https://github.com/Kong/kong/issues/12773)
* Fixed migration of Redis configuration.
* Fixed an issue where the wrong error log was printed regarding private keys.

### {{site.base_gateway}} 3.6.x

* Standardized Redis configuration across plugins. 
The Redis configuration now follows a common schema that is shared across other plugins.
[#12300](https://github.com/Kong/kong/issues/12300)  [#12301](https://github.com/Kong/kong/issues/12301)

### {{site.base_gateway}} 3.5.x

* Exposed the new configuration field `config.storage_config.redis.extra_options.scan_count` for Redis storage, 
which controls how many keys are returned in a `scan` call. 
[#11532](https://github.com/kong/kong/pull/11532)

### {{site.base_gateway}} 3.4.x

* Fixed an issue where the sanity test didn't work with `kong` storage in hybrid mode.
[#10852](https://github.com/Kong/kong/pull/10852)

### {{site.base_gateway}} 3.3.x

* Added the `config.account_key` configuration parameter
* Added the `config.storage_config.redis.namespace` configuration parameter.
  The namespace will be concatenated as a prefix of the key. The default is an empty string (`""`) for backward compatibility. 
  The namespace can be any string that isn't prefixed with any of the [Kong reserved words](/gateway/reserved-entity-names/).

### {{site.base_gateway}} 3.1.x

* Added the `config.storage_config.redis.ssl`, `config.storage_config.redis.ssl_verify`, and `config.storage_config.redis.ssl_server_name` configuration parameters.

### {{site.base_gateway}} 3.0.x
* The `config.storage_config.vault.auth_method` configuration parameter now defaults to `token`.
* Added the `config.allow_any_domain` configuration parameter. If enabled, it lets {{site.base_gateway}}
  ignore the `domains` field.

### {{site.base_gateway}} 2.8.x

* Added the `config.rsa_key_size` configuration parameter.
* The `consul.token`, `redis.auth`, and `vault.token` are now marked as now marked as
referenceable, which means they can be securely stored as [secrets in a Vault](/gateway/entities/vault/). 
References must follow a specific format.

### {{site.base_gateway}} 2.7.x

* Starting with {{site.base_gateway}} 2.7.0.0, if keyring encryption is enabled,
 the `config.account_email`, `config.eab_kid`, and `config.eab_hmac_key` parameter values will be
 encrypted.

### {{site.base_gateway}} 2.4.x
* Added external account binding (EAB) support with the `config.eab_kid` and `config.eab_hmac_key` configuration parameters.

### {{site.base_gateway}} 2.1.x
* Added the `config.fail_backoff_minutes` configuration parameter.
