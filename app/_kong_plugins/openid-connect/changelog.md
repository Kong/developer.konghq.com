---
content_type: reference

---

## Changelog

### {{site.base_gateway}} 3.10.x
* Removed issuer discovery from schema to improve performance upon plugin initialization or updating. 
The issuer discovery will only be triggered by client requests.
* Fixed an issue where forbidden requests were redirected to `unauthorized_redirect_uri` if configured. After the fix, forbidden requests will be redirected to `forbidden_redirect_uri` if configured.

### {{site.base_gateway}} 3.9.x
* The `http_proxy_authorization` and `https_proxy_authorization` fields are now referenceable.
* Added the `introspection_post_args_client_headers` config option, 
allowing you to pass client headers as introspection POST body arguments.
* Fixed an `500` error caused by JSON `null` from the request body when parsing bearer tokens or client IDs.
* Fixed an issue where the configured Redis database was ignored.
* Fixed an issue where the `token_cache_key_include_scope` feature was not considering scopes defined via `config.scopes` to generate the cache key.

### {{site.base_gateway}} 3.8.x
* Added support for Redis caching introspection results with the new fields `cluster_cache_strategy` and `cluster_cache_redis`. 
  When configured, the plugin will share the token introspection response cache across nodes configured to use the same Redis database.
* Added the `claims_forbidden` property to restrict access.
* Fixed an issue where anonymous consumers could be cached as nil under a certain condition.
* Updated the rediscovery to use a short lifetime (5s) if the last discovery failed.
* Fixed an issue where `using_pseudo_issuer` didn't work when sending `PATCH` requests.

### {{site.base_gateway}} 3.7.x

* Added support for DPoP (Demonstrating Proof-of-Possession) token validation. 
You can enable it using the configuration parameter `proof_of_possession_dpop`.
* Added support for JWT Secured Authorization Requests (JAR) on Authorization and Pushed Authorization (PAR) endpoints. 
See the configuration parameter `require_signed_request_object`.
* Added support for JARM response modes: `query.jwt`, `form_post.jwt`, `fragment.jwt`, and `jwt`.

### {{site.base_gateway}} 3.6.x

Features:
* The configuration parameters `scopes`, `login_redirect_uri`, `logout_redirect_uri`, and `introspection_headers_values` 
can now be referenced as secrets in the Kong Vault.
* Extended the `token_post_args_client` configuration parameter to support injection from headers.
* Added support for explicit proof key for code exchange (PKCE).
* Added support for pushed authorization requests (PAR).
* Added support for the `tls_client_auth` and `self_signed_tls_client_auth` authentication methods, allowing 
mTLS client authentication with the IdP.

Fixes:
* Fixed logout URI suffix detection by using the normalized version of `kong.request.get_forwarded_path()` instead of 
`ngx.var.request_uri`, especially when passing query strings to logout.
* The `introspection_headers_values` configuration parameter can now be encrypted.
* Removed the unwanted argument `ignore_signature.userinfo` from the `userinfo_load` function.
* Added support for consumer group scoping by using the PDK `kong.client.authenticate` function.
* Fixed the cache key collision when config `issuer` and `extra_jwks_uris` contain the same URI.
* The plugin now correctly handled boundary conditions for token expiration time checking.
* The plugin now updates the time when calculating token expiration.

### {{site.base_gateway}} 3.5.x
* Added the new field `unauthorized_destroy_session`. 
When set to `true`, it destroys the session when receiving an unauthorized request by deleting the user's session cookie.
* Added the new field `using_pseudo_issuer`. 
When set to `true`, the plugin instance will not discover configuration from the issuer.
* Added support for public clients for token revocation and introspection.
* Added support for designating parameter names `introspection_token_param_name` and `revocation_token_param_name`.
* Added support for mTLS proof of possession. The feature is available by enabling `proof_of_possession_mtls`.

### {{site.base_gateway}} 3.4.x
* This plugin now supports the error reason header. 
This header can be turned off by setting `expose_error_code` to `false`.
* OpenID Connect now supports adding scope to the token cache key by 
setting `token_cache_key_include_scope` to `true`.
* Changed some log levels from `notice` to `error` for better visibility.
* Correctly set the right table key on `log` and `message`.
* If an invalid opaque token is provided but verification fails, the plugin now prints the correct error.

### {{site.base_gateway}} 3.2.x
* The plugin has been updated to use version 4.0.0 of the `lua-resty-session` library which introduced several new features such as the possibility to specify audiences.
The following configuration parameters have been affected:

Added:
  * `session_audience`
  * `session_remember`
  * `session_remember_cookie_name`
  * `session_remember_rolling_timeout`
  * `session_remember_absolute_timeout`
  * `session_absolute_timeout`
  * `session_request_headers`
  * `session_response_headers`
  * `session_store_metadata`
  * `session_enforce_same_subject`
  * `session_hash_subject`
  * `session_hash_storage_key`

Renamed:
  * `authorization_cookie_lifetime` to `authorization_rolling_timeout`
  * `authorization_cookie_samesite` to `authorization_cookie_same_site`
  * `authorization_cookie_httponly` to `authorization_cookie_http_only`
  * `session_cookie_lifetime` to `session_rolling_timeout`
  * `session_cookie_idletime` to `session_idling_timeout`
  * `session_cookie_samesite` to `session_cookie_same_site`
  * `session_cookie_httponly` to `session_cookie_http_only`
  * `session_memcache_prefix` to `session_memcached_prefix`
  * `session_memcache_socket` to `session_memcached_socket`
  * `session_memcache_host` to `session_memcached_host`
  * `session_memcache_port` to `session_memcached_port`
  * `session_redis_cluster_maxredirections` to `session_redis_cluster_max_redirections`

Removed:
  * `session_cookie_renew`
  * `session_cookie_maxsize`
  * `session_strategy`
  * `session_compressor`

### {{site.base_gateway}} 3.0.x
* The deprecated `session_redis_auth` field has been removed from the plugin.

### {{site.base_gateway}} 2.8.x

* Added the `session_redis_username` and `session_redis_password` configuration
parameters.

    {:.warning}
    > These parameters replace the `session_redis_auth` field, which is
    now **deprecated** and planned to be removed in 3.x.x.

* Added the `resolve_distributed_claims` configuration parameter.

* The `client_id`, `client_secret`, `session_secret`, `session_redis_username`,
and `session_redis_password` configuration fields are now marked as
referenceable, which means they can be securely stored as
[secrets](/gateway/entities/vault/) in a Vault.

### {{site.base_gateway}} 2.7.x

* Starting with {{site.base_gateway}} 2.7.0.0, if keyring encryption is enabled,
 the `config.client_id`, `config.client_secret`, `config.session_auth`, and
 `config.session_redis_auth` parameter values will be encrypted.

  Additionally, the `d`, `p`, `q`, `dp`, `dq`, `qi`, `oth`, `r`, `t`, and `k`
  fields inside `openid_connect_jwks.previous[...].` and `openid_connect_jwks.keys[...]`
  will be marked as encrypted.

  {:.warning}
  > There's a bug in {{site.base_gateway}} that prevents keyring encryption
  from working on deeply nested fields, so the `encrypted=true` setting does not
  currently have any effect on the nested fields in this plugin.

* The plugin now allows Redis cluster nodes to be specified by hostname through
the `session_redis_cluster_nodes` field, which is helpful if the cluster IPs are
not static.

### {{site.base_gateway}} 2.6.x

* The OpenID Connect plugin can now handle JWT responses from a `userinfo` endpoint.
* Added support for JWE introspection.
* Added a new parameter, `by_username_ignore_case`, which allows `consumer_by` username
values to be matched case-insensitive with identity provider (IdP) claims.
