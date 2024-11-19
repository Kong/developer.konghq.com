---
title: Kong Gateway Enterprise changelog

content_type: reference
layout: reference

---

## Kong


### Performance
#### Core

- Removed unnecessary DNS client initialization
 [#10016](https://github.com/Kong/kong-ee/issues/10016)
 [KAG-5059](https://konghq.atlassian.net/browse/KAG-5059)

- Improved latency performance when gzipping/gunzipping large data (such as CP/DP config data).
 [#9771](https://github.com/Kong/kong-ee/issues/9771)
 [KAG-4878](https://konghq.atlassian.net/browse/KAG-4878)


### Deprecations
#### Default

- Debian 10, CentOS 7, and RHEL 7 reached their End of Life (EOL) dates on June 30, 2024. As of version 3.8.0.0 onward, Kong is not building installation packages or Docker images for these operating systems. Kong is no longer providing official support for any Kong version running on these systems.
 [#9927](https://github.com/Kong/kong-ee/issues/9927)
 [KAG-4847](https://konghq.atlassian.net/browse/KAG-4847) [FTI-6054](https://konghq.atlassian.net/browse/FTI-6054) [KAG-4549](https://konghq.atlassian.net/browse/KAG-4549) [KAG-5122](https://konghq.atlassian.net/browse/KAG-5122)

### Dependencies
#### Core

- Bumped lua-resty-acme to 0.15.0 to support username/password auth with redis.
 [#8901](https://github.com/Kong/kong-ee/issues/8901)
 [KAG-4330](https://konghq.atlassian.net/browse/KAG-4330)

- Bumped lua-resty-aws to 1.5.3 to fix a bug related to STS regional endpoint.
 [#8871](https://github.com/Kong/kong-ee/issues/8871)
 [KAG-3424](https://konghq.atlassian.net/browse/KAG-3424) [FTI-5732](https://konghq.atlassian.net/browse/FTI-5732)

- Bumped lua-resty-healthcheck from 3.0.1 to 3.1.0 to fix an issue that was causing high memory usage
 [#9145](https://github.com/Kong/kong-ee/issues/9145)
 [FTI-5847](https://konghq.atlassian.net/browse/FTI-5847)

- Bumped lua-resty-lmdb to 1.4.3 to get fixes from the upstream (lmdb 0.9.33), which resolved numerous race conditions and fixed a cursor issue.
 [#8652](https://github.com/Kong/kong-ee/issues/8652)


- Bumped lua-resty-openssl to 1.5.1 to fix some issues including a potential use-after-free issue.
 [#8439](https://github.com/Kong/kong-ee/issues/8439)


- Bumped OpenResty to 1.25.3.2 to improve the performance of the LuaJIT hash computation.
 [#7867](https://github.com/Kong/kong-ee/issues/7867)
 [KAG-3515](https://konghq.atlassian.net/browse/KAG-3515) [JIT-2](https://konghq.atlassian.net/browse/JIT-2)

- Bumped PCRE2 to 10.44 to fix some bugs and tidy-up the release (nothing important)
 [#7961](https://github.com/Kong/kong-ee/issues/7961)
 [KAG-3571](https://konghq.atlassian.net/browse/KAG-3571) [KAG-3521](https://konghq.atlassian.net/browse/KAG-3521) [KAG-2025](https://konghq.atlassian.net/browse/KAG-2025) [KAG-3614](https://konghq.atlassian.net/browse/KAG-3614)

- Introduced a yieldable JSON library `lua-resty-simdjson`,
which would improve the latency significantly.
 [#9826](https://github.com/Kong/kong-ee/issues/9826)
 [KAG-3647](https://konghq.atlassian.net/browse/KAG-3647)
#### Default

- Bumped lua-protobuf 0.5.2
 [#8750](https://github.com/Kong/kong-ee/issues/8750)
 [KAG-4192](https://konghq.atlassian.net/browse/KAG-4192)

- Bumped LuaRocks from 3.11.0 to 3.11.1
 [#8431](https://github.com/Kong/kong-ee/issues/8431)
 [KAG-3883](https://konghq.atlassian.net/browse/KAG-3883)

- Bumped `ngx_wasm_module` to `96b4e27e10c63b07ed40ea88a91c22f23981db35`
 [#7554](https://github.com/Kong/kong-ee/issues/7554)


- Bumped `Wasmtime` version to `23.0.2`
 [#7554](https://github.com/Kong/kong-ee/issues/7554)


- Made the RPM package relocatable with the default prefix set to `/`.
 [#9927](https://github.com/Kong/kong-ee/issues/9927)
 [KAG-4847](https://konghq.atlassian.net/browse/KAG-4847) [FTI-6054](https://konghq.atlassian.net/browse/FTI-6054) [KAG-4549](https://konghq.atlassian.net/browse/KAG-4549) [KAG-5122](https://konghq.atlassian.net/browse/KAG-5122)

### Features
#### Configuration

- Configure Wasmtime module cache when Wasm is enabled
 [#9389](https://github.com/Kong/kong-ee/issues/9389)
 [KAG-4372](https://konghq.atlassian.net/browse/KAG-4372)
#### Core

- **prometheus**: Added `ai_requests_total`, `ai_cost_total` and `ai_tokens_total` metrics in the Prometheus plugin to start counting AI usage.
 [#9592](https://github.com/Kong/kong-ee/issues/9592)


- Added a new configuration `concurrency_limit`(integer, default to 1) for Queue to specify the number of delivery timers.
Note that setting `concurrency_limit` to `-1` means no limit at all, and each HTTP log entry would create an individual timer for sending.
 [#9996](https://github.com/Kong/kong-ee/issues/9996)
 [FTI-6022](https://konghq.atlassian.net/browse/FTI-6022)

- Append gateway info to upstream `Via` header like `1.1 kong/3.8.0`, and optionally to
response `Via` header if it is present in the `headers` config of "kong.conf", like `2 kong/3.8.0`,
according to `RFC7230` and `RFC9110`.
 [#9716](https://github.com/Kong/kong-ee/issues/9716)
 [FTI-5807](https://konghq.atlassian.net/browse/FTI-5807)

- Starting from this version, a new DNS client library has been implemented and added into Kong, which is disabled by default. The new DNS client library has the following changes - Introduced global caching for DNS records across workers, significantly reducing the query load on DNS servers. - Introduced observable statistics for the new DNS client, and a new Status API `/status/dns` to retrieve them. - Simplified the logic and make it more standardized
 [#8694](https://github.com/Kong/kong-ee/issues/8694)
 [KAG-3220](https://konghq.atlassian.net/browse/KAG-3220)
#### PDK

- Added `0` to support unlimited body size. When parameter `max_allowed_file_size` is `0`, `get_raw_body` will return the entire body, but the size of this body will still be limited by Nginx's `client_max_body_size`.
 [#9856](https://github.com/Kong/kong-ee/issues/9856)
 [KAG-4698](https://konghq.atlassian.net/browse/KAG-4698)

- extend kong.request.get_body and kong.request.get_raw_body to read from buffered file
 [#9383](https://github.com/Kong/kong-ee/issues/9383)


- Added a new PDK module `kong.telemetry` and function: `kong.telemetry.log`
to generate log entries to be reported via the OpenTelemetry plugin.
 [#9681](https://github.com/Kong/kong-ee/issues/9681)
 [KAG-4848](https://konghq.atlassian.net/browse/KAG-4848)
#### Plugin

- **acl:** Added a new config `always_use_authenticated_groups` to support using authenticated groups even when an authenticated consumer already exists.
 [#9879](https://github.com/Kong/kong-ee/issues/9879)
 [FTI-5945](https://konghq.atlassian.net/browse/FTI-5945)

- AI plugins: retrieved latency data and pushed it to logs and metrics.
 [#9828](https://github.com/Kong/kong-ee/issues/9828)


- allow AI plugin to read request from buffered file
 [#9383](https://github.com/Kong/kong-ee/issues/9383)


- **AI-proxy-plugin**: Add `allow_override` option to allow overriding the upstream model auth parameter or header from the caller's request.
 [#9970](https://github.com/Kong/kong-ee/issues/9970)


- Kong AI Gateway (AI Proxy and associated plugin family) now supports 
all AWS Bedrock "Converse API" models.
 [#9678](https://github.com/Kong/kong-ee/issues/9678)


- Kong AI Gateway (AI Proxy and associated plugin family) now supports 
the Google Gemini "chat" (generateContent) interface.
 [#9678](https://github.com/Kong/kong-ee/issues/9678)


- **ai-proxy**: Allowed mistral provider to use mistral.ai managed service by omitting upstream_url
 [#9929](https://github.com/Kong/kong-ee/issues/9929)


- **ai-proxy**: Added a new response header X-Kong-LLM-Model that displays the name of the language model used in the AI-Proxy plugin.
 [#9912](https://github.com/Kong/kong-ee/issues/9912)


- **AI-Prompt-Guard**: add `match_all_roles` option to allow match all roles in addition to `user`.
 [#9736](https://github.com/Kong/kong-ee/issues/9736)


- **AWS-Lambda**: A new configuration field `empty_arrays_mode` is now added to control whether Kong should send `[]` empty arrays (returned by Lambda function) as `[]` empty arrays or `{}` empty objects in JSON responses.`
 [#9370](https://github.com/Kong/kong-ee/issues/9370)
 [FTI-5937](https://konghq.atlassian.net/browse/FTI-5937) [KAG-4622](https://konghq.atlassian.net/browse/KAG-4622) [KAG-4615](https://konghq.atlassian.net/browse/KAG-4615)

- Added support for json_body rename in response-transformer plugin
 [#9497](https://github.com/Kong/kong-ee/issues/9497)
 [KAG-4664](https://konghq.atlassian.net/browse/KAG-4664)

- **OpenTelemetry:** Added support for OpenTelemetry formatted logs.
 [#9399](https://github.com/Kong/kong-ee/issues/9399)
 [KAG-4712](https://konghq.atlassian.net/browse/KAG-4712)

- **standard-webhooks**: Added standard webhooks plugin.
 [#9104](https://github.com/Kong/kong-ee/issues/9104)
 [KAG-4825](https://konghq.atlassian.net/browse/KAG-4825)

- **Request-Transformer**: Fixed an issue where renamed query parameters, url-encoded body parameters, and json body parameters were not handled properly when target name is the same as the source name in the request.
 [#9975](https://github.com/Kong/kong-ee/issues/9975)
 [KAG-4915](https://konghq.atlassian.net/browse/KAG-4915)
#### Admin API

- Added support for brackets syntax for map fields configuration via the Admin API
 [#9655](https://github.com/Kong/kong-ee/issues/9655)
 [KAG-4827](https://konghq.atlassian.net/browse/KAG-4827)

### Fixes
#### CLI Command

- Fixed an issue where some debug level error logs were not being displayed by the CLI.
 [#9382](https://github.com/Kong/kong-ee/issues/9382)
 [FTI-5995](https://konghq.atlassian.net/browse/FTI-5995)
#### Configuration

- Re-enabled the Lua DNS resolver from proxy-wasm by default.
 [#9801](https://github.com/Kong/kong-ee/issues/9801)
 [KAG-4671](https://konghq.atlassian.net/browse/KAG-4671)
#### Core

- Fixed an issue where 'read' was not always passed to Postgres read-only database operations.
 [#10034](https://github.com/Kong/kong-ee/issues/10034)
 [KAG-5196](https://konghq.atlassian.net/browse/KAG-5196)

- Deprecated shorthand fields don't take precedence over replacement fields when both are specified.
 [#9932](https://github.com/Kong/kong-ee/issues/9932)
 [KAG-5134](https://konghq.atlassian.net/browse/KAG-5134)

- Fixed an issue where `lua-nginx-module` context was cleared when `ngx.send_header()` triggered `filter_finalize` [openresty/lua-nginx-module#2323](https://github.com/openresty/lua-nginx-module/pull/2323).
 [#9717](https://github.com/Kong/kong-ee/issues/9717)
 [FTI-6005](https://konghq.atlassian.net/browse/FTI-6005)

- Changed the way deprecated shorthand fields are used with new fields.
If the new field contains null it allows for deprecated field to overwrite it if both are present in the request.
 [#10148](https://github.com/Kong/kong-ee/issues/10148)
 [KAG-5287](https://konghq.atlassian.net/browse/KAG-5287)

- Fixed an issue where unnecessary uninitialized variable error log is reported when 400 bad requests were received.
 [#9718](https://github.com/Kong/kong-ee/issues/9718)
 [FTI-6025](https://konghq.atlassian.net/browse/FTI-6025)

- Fixed an issue where the URI captures are unavailable when the first capture group is absent.
 [#9253](https://github.com/Kong/kong-ee/issues/9253)
 [KAG-4474](https://konghq.atlassian.net/browse/KAG-4474)

- Fixed an issue where the priority field can be set in a traditional mode route
When 'router_flavor' is configured as 'expressions'.
 [#9342](https://github.com/Kong/kong-ee/issues/9342)
 [KAG-4411](https://konghq.atlassian.net/browse/KAG-4411)

- Fixed an issue where setting `tls_verify` to `false` didn't override the global level `proxy_ssl_verify`.
 [#9959](https://github.com/Kong/kong-ee/issues/9959)
 [FTI-6095](https://konghq.atlassian.net/browse/FTI-6095)

- Fixed an issue where the sni cache isn't invalidated when a sni is updated.
 [#9702](https://github.com/Kong/kong-ee/issues/9702)
 [FTI-6009](https://konghq.atlassian.net/browse/FTI-6009)

- The kong.logrotate configuration file will no longer be overwritten during upgrade.
When upgrading, set the environment variable `DEBIAN_FRONTEND=noninteractive` on Debian/Ubuntu to avoid any interactive prompts and enable fully automatic upgrades.
 [#9770](https://github.com/Kong/kong-ee/issues/9770)
 [FTI-6079](https://konghq.atlassian.net/browse/FTI-6079)

- Fixed an issue where the Vault secret cache got refreshed during `resurrect_ttl` time and could not be fetched by other workers.
 [#10074](https://github.com/Kong/kong-ee/issues/10074)
 [FTI-6137](https://konghq.atlassian.net/browse/FTI-6137)

- Error logs during Vault secret rotation are now logged at the `notice` level instead of `warn`.
 [#10061](https://github.com/Kong/kong-ee/issues/10061)
 [FTI-5775](https://konghq.atlassian.net/browse/FTI-5775)

- fix a bug that the `host_header` attribute of upstream entity can not be set correctly in requests to upstream as Host header when retries to upstream happen.
 [#9348](https://github.com/Kong/kong-ee/issues/9348)
 [FTI-5987](https://konghq.atlassian.net/browse/FTI-5987)

- Moved internal Unix sockets to a subdirectory (`sockets`) of the Kong prefix.
 [#9884](https://github.com/Kong/kong-ee/issues/9884)
 [KAG-4947](https://konghq.atlassian.net/browse/KAG-4947)

- Changed the behaviour of shorthand fields that are used to describe deprecated fields. If
both fields are sent in the request and their values mismatch - the request will be rejected.
 [#10149](https://github.com/Kong/kong-ee/issues/10149)
 [KAG-5262](https://konghq.atlassian.net/browse/KAG-5262)

- Reverted DNS client to original behaviour of ignoring ADDITIONAL SECTION in DNS responses.
 [#9541](https://github.com/Kong/kong-ee/issues/9541)
 [FTI-6039](https://konghq.atlassian.net/browse/FTI-6039)

- Shortened names of internal Unix sockets to avoid exceeding the socket name limit.
 [#10129](https://github.com/Kong/kong-ee/issues/10129)
 [KAG-5136](https://konghq.atlassian.net/browse/KAG-5136)
#### PDK

- **PDK**: Fixed a bug that log serializer will log `upstream_status` as nil in the requests that contains subrequest
 [#9381](https://github.com/Kong/kong-ee/issues/9381)
 [FTI-5844](https://konghq.atlassian.net/browse/FTI-5844)

- **Vault**: Reference ending with slash when parsed should not return a key.
 [#10040](https://github.com/Kong/kong-ee/issues/10040)
 [KAG-5181](https://konghq.atlassian.net/browse/KAG-5181)

- Fixed an issue that pdk.log.serialize() will throw an error when JSON entity set by serialize_value contains json.null
 [#9764](https://github.com/Kong/kong-ee/issues/9764)
 [FTI-6096](https://konghq.atlassian.net/browse/FTI-6096)
#### Plugin

- **AI-proxy-plugin**: Fixed a bug where certain Azure models would return partial tokens/words 
when in response-streaming mode.
 [#9558](https://github.com/Kong/kong-ee/issues/9558)
 [KAG-4596](https://konghq.atlassian.net/browse/KAG-4596)

- **AI-Transformer-Plugins**: Fixed a bug where cloud identity authentication 
was not used in `ai-request-transformer` and `ai-response-transformer` plugins.
 [#9990](https://github.com/Kong/kong-ee/issues/9990)


- **AI-proxy-plugin**: Fixed a bug where Cohere and Anthropic providers don't read the `model` parameter properly 
from the caller's request body.
 [#9558](https://github.com/Kong/kong-ee/issues/9558)
 [KAG-4596](https://konghq.atlassian.net/browse/KAG-4596)

- **AI-proxy-plugin**: Fixed a bug where using "OpenAI Function" inference requests would log a 
request error, and then hang until timeout.
 [#9558](https://github.com/Kong/kong-ee/issues/9558)
 [KAG-4596](https://konghq.atlassian.net/browse/KAG-4596)

- **AI-proxy-plugin**: Fixed a bug where AI Proxy would still allow callers to specify their own model,  
ignoring the plugin-configured model name.
 [#9558](https://github.com/Kong/kong-ee/issues/9558)
 [KAG-4596](https://konghq.atlassian.net/browse/KAG-4596)

- **AI-proxy-plugin**: Fixed a bug where AI Proxy would not take precedence of the 
plugin's configured model tuning options, over those in the user's LLM request.
 [#9558](https://github.com/Kong/kong-ee/issues/9558)
 [KAG-4596](https://konghq.atlassian.net/browse/KAG-4596)

- **AI-proxy-plugin**: Fixed a bug where setting OpenAI SDK model parameter "null" caused analytics 
to not be written to the logging plugin(s).
 [#9558](https://github.com/Kong/kong-ee/issues/9558)
 [KAG-4596](https://konghq.atlassian.net/browse/KAG-4596)

- **ACME**: Fixed an issue of DP reporting that deprecated config fields are used when configuration from CP is pushed
 [#9591](https://github.com/Kong/kong-ee/issues/9591)
 [KAG-4515](https://konghq.atlassian.net/browse/KAG-4515)

- **ACME**: Fixed an issue where username and password were not accepted as valid authentication methods.
 [#10003](https://github.com/Kong/kong-ee/issues/10003)
 [FTI-6143](https://konghq.atlassian.net/browse/FTI-6143)

- **AI-Proxy**: Fixed issue when response is gzipped even if client doesn't accept.
 [#9912](https://github.com/Kong/kong-ee/issues/9912)


- "**Prometheus**: Fixed an issue where CP/DP compatibility check was missing for the new configuration field `ai_metrics`.
 [#9807](https://github.com/Kong/kong-ee/issues/9807)
 [KAG-4934](https://konghq.atlassian.net/browse/KAG-4934)

- Fixed certain AI plugins cannot be applied per consumer or per service.
 [#9563](https://github.com/Kong/kong-ee/issues/9563)


- **AI-Prompt-Guard**: Fixed an issue when `allow_all_conversation_history` is set to false, the first user request is selected instead of the last one.
 [#9736](https://github.com/Kong/kong-ee/issues/9736)


- **AI-Proxy**: Resolved a bug where the object constructor would set data on the class instead of the instance
 [#9411](https://github.com/Kong/kong-ee/issues/9411)


- **AWS-Lambda**: Fixed an issue that the plugin does not work with multiValueHeaders defined in proxy integration and legacy empty_arrays_mode.
 [#9763](https://github.com/Kong/kong-ee/issues/9763)
 [FTI-6100](https://konghq.atlassian.net/browse/FTI-6100)

- **AWS-Lambda**: Fixed an issue that the `version` field is not set in the request payload when `awsgateway_compatible` is enabled.
 [#9126](https://github.com/Kong/kong-ee/issues/9126)
 [FTI-5949](https://konghq.atlassian.net/browse/FTI-5949)

- **correlation-id**: Fixed an issue where the plugin would not work if we explicitly set the `generator` to `null`.
 [#9886](https://github.com/Kong/kong-ee/issues/9886)
 [FTI-6134](https://konghq.atlassian.net/browse/FTI-6134)

- **CORS**: Fixed an issue where the `Access-Control-Allow-Origin` header was not sent when `conf.origins` has multiple entries but includes `*`.
 [#9781](https://github.com/Kong/kong-ee/issues/9781)
 [FTI-6062](https://konghq.atlassian.net/browse/FTI-6062)

- **grpc-gateway**: When there is a JSON decoding error, respond with status 400 and error information in the body instead of status 500.
 [#9011](https://github.com/Kong/kong-ee/issues/9011)


- **HTTP-Log**: Fix an issue where the plugin doesn't include port information in the HTTP host header when sending requests to the log server.
 [#9359](https://github.com/Kong/kong-ee/issues/9359)


- "**AI Plugins**: Fixed an issue for multi-modal inputs are not properly validated and calculated.
 [#9989](https://github.com/Kong/kong-ee/issues/9989)


- **OpenTelemetry:** Fixed an issue where migration fails when upgrading from below version 3.3 to 3.7.
 [#9804](https://github.com/Kong/kong-ee/issues/9804)
 [FTI-6109](https://konghq.atlassian.net/browse/FTI-6109)

- **OpenTelemetry / Zipkin**: remove redundant deprecation warnings
 [#9483](https://github.com/Kong/kong-ee/issues/9483)
 [KAG-4744](https://konghq.atlassian.net/browse/KAG-4744)

- **Basic-Auth**: Fix an issue of realm field not recognized for older kong versions (before 3.6)
 [#9427](https://github.com/Kong/kong-ee/issues/9427)
 [KAG-4516](https://konghq.atlassian.net/browse/KAG-4516)

- **Key-Auth**: Fix an issue of realm field not recognized for older kong versions (before 3.7)
 [#9427](https://github.com/Kong/kong-ee/issues/9427)
 [KAG-4516](https://konghq.atlassian.net/browse/KAG-4516)

- **Request Size Limiting**: Fixed an issue where the body size doesn't get checked when the request body is buffered to a temporary file.
 [#9638](https://github.com/Kong/kong-ee/issues/9638)
 [FTI-6034](https://konghq.atlassian.net/browse/FTI-6034)

- **Response-RateLimiting**: Fixed an issue of DP reporting that deprecated config fields are used when configuration from CP is pushed
 [#9591](https://github.com/Kong/kong-ee/issues/9591)
 [KAG-4515](https://konghq.atlassian.net/browse/KAG-4515)

- **Rate-Limiting**: Fixed an issue of DP reporting that deprecated config fields are used when configuration from CP is pushed
 [#9591](https://github.com/Kong/kong-ee/issues/9591)
 [KAG-4515](https://konghq.atlassian.net/browse/KAG-4515)

- **OpenTelemetry:** Improved accuracy of sampling decisions.
 [#9588](https://github.com/Kong/kong-ee/issues/9588)
 [KAG-4785](https://konghq.atlassian.net/browse/KAG-4785)

- **hmac-auth**: Add WWW-Authenticate headers to 401 responses.
 [#9494](https://github.com/Kong/kong-ee/issues/9494)
 [KAG-4742](https://konghq.atlassian.net/browse/KAG-4742)

- **Prometheus**: Improved error logging when having inconsistent labels count.
 [#9361](https://github.com/Kong/kong-ee/issues/9361)


- **jwt**: Add WWW-Authenticate headers to 401 responses.
 [#9494](https://github.com/Kong/kong-ee/issues/9494)
 [KAG-4742](https://konghq.atlassian.net/browse/KAG-4742)

- **ldap-auth**: Add WWW-Authenticate headers to all 401 responses.
 [#9494](https://github.com/Kong/kong-ee/issues/9494)
 [KAG-4742](https://konghq.atlassian.net/browse/KAG-4742)

- **OAuth2**: Add WWW-Authenticate headers to all 401 responses and realm option.
 [#9494](https://github.com/Kong/kong-ee/issues/9494)
 [KAG-4742](https://konghq.atlassian.net/browse/KAG-4742)

- **proxy-cache**: Fixed an issue where the Age header was not being updated correctly when serving cached responses.
 [#9786](https://github.com/Kong/kong-ee/issues/9786)

#### Admin API

- Fixed an issue where validation of the certificate schema failed if the `snis` field was present in the request body.
 [#9823](https://github.com/Kong/kong-ee/issues/9823)

#### Clustering

- Fixed an issue where hybrid mode not working if the forward proxy password contains special character(#). Note that the `proxy_server` configuration parameter still needs to be url-encoded.
 [#9955](https://github.com/Kong/kong-ee/issues/9955)
 [FTI-6145](https://konghq.atlassian.net/browse/FTI-6145)
#### Default

- **AI-proxy**: A configuration validation is added to prevent from enabling `log_statistics` upon
providers not supporting statistics. Accordingly, the default of `log_statistics` is changed from
`true` to `false`, and a database migration is added as well for disabling `log_statistics` if it
has already been enabled upon unsupported providers.
 [#8872](https://github.com/Kong/kong-ee/issues/8872)

## Kong-Enterprise


### Performance
#### Plugin

- **Rate Limiting Advanced:** Improved that timer spikes do not occur when there is network instability with the central data store.
 [#9076](https://github.com/Kong/kong-ee/issues/9076)
 [FTI-5926](https://konghq.atlassian.net/browse/FTI-5926)
#### Default

- Improved the performance of Konnect Analytics by fetching Rate Limiting context more efficiently.
 [#9502](https://github.com/Kong/kong-ee/issues/9502)
 [KAG-4679](https://konghq.atlassian.net/browse/KAG-4679)

- Improved the performance of Konnect Analytics by optimizing the buffering mechanism.
 [#9273](https://github.com/Kong/kong-ee/issues/9273)
 [KAG-4270](https://konghq.atlassian.net/browse/KAG-4270)


### Deprecations
#### PDK

- The shared configuration for Redis `kong/enterprise_edition/redis/init.lua` was deprecated in favor of `kong/enterprise_edition/tools/redis/v2/init.lua`
 [#9802](https://github.com/Kong/kong-ee/issues/9802)
 [KAG-5024](https://konghq.atlassian.net/browse/KAG-5024)
#### Plugin

- **ai-rate-limiting-advanced**: Switched to sentinel_nodes and cluster_nodes for redis configuration.
 [#8645](https://github.com/Kong/kong-ee/issues/8645)
 [KAG-2130](https://konghq.atlassian.net/browse/KAG-2130)

- **ai-rate-limiting-advanced**: Deprecated timeout config field in redis config in favor of connect_/send_/read_timeout (timeout field will be removed in 4.0).
 [#9704](https://github.com/Kong/kong-ee/issues/9704)
 [KAG-2130](https://konghq.atlassian.net/browse/KAG-2130)

- **graphql-proxy-cache-advanced**: Switched to sentinel_nodes and cluster_nodes for redis configuration.
 [#8645](https://github.com/Kong/kong-ee/issues/8645)
 [KAG-2130](https://konghq.atlassian.net/browse/KAG-2130)

- **graphql-proxy-cache-advanced**: Deprecated timeout config field in redis config in favor of connect_/send_/read_timeout (timeout field will be removed in 4.0).
 [#8621](https://github.com/Kong/kong-ee/issues/8621)
 [KAG-3947](https://konghq.atlassian.net/browse/KAG-3947)

- **graphql-rate-limiting-advanced**: Deprecated timeout config field in redis config in favor of connect_/send_/read_timeout (timeout field will be removed in 4.0).
 [#8621](https://github.com/Kong/kong-ee/issues/8621)
 [KAG-3947](https://konghq.atlassian.net/browse/KAG-3947)

- **graphql-rate-limiting-advanced**: Switched to sentinel_nodes and cluster_nodes for redis configuration.
 [#8645](https://github.com/Kong/kong-ee/issues/8645)
 [KAG-2130](https://konghq.atlassian.net/browse/KAG-2130)

- **proxy-cache-advanced**: Deprecated timeout config field in redis config in favor of connect_/send_/read_timeout (timeout field will be removed in 4.0).
 [#8621](https://github.com/Kong/kong-ee/issues/8621)
 [KAG-3947](https://konghq.atlassian.net/browse/KAG-3947)

- **proxy-cache-advanced**: Switched to sentinel_nodes and cluster_nodes for redis configuration.
 [#8645](https://github.com/Kong/kong-ee/issues/8645)
 [KAG-2130](https://konghq.atlassian.net/browse/KAG-2130)

- **rate-limiting-advanced**: Deprecated timeout config field in redis config in favor of connect_/send_/read_timeout (timeout field will be removed in 4.0).
 [#8621](https://github.com/Kong/kong-ee/issues/8621)
 [KAG-3947](https://konghq.atlassian.net/browse/KAG-3947)

- **rate-limiting-advanced**: Switched to sentinel_nodes and cluster_nodes for redis configuration.
 [#8645](https://github.com/Kong/kong-ee/issues/8645)
 [KAG-2130](https://konghq.atlassian.net/browse/KAG-2130)

- **openid-connect**: Standardized Redis configuration across plugins. The Redis configuration now follows a common schema shared with other plugins.
 [#9900](https://github.com/Kong/kong-ee/issues/9900)
 [KAG-2386](https://konghq.atlassian.net/browse/KAG-2386)

- **SAML**: Standardized Redis configuration across plugins. The Redis configuration now follows a common schema shared with other plugins.
 [#8369](https://github.com/Kong/kong-ee/issues/8369)
 [KAG-2387](https://konghq.atlassian.net/browse/KAG-2387)

### Dependencies
#### Core

- Bumped libxml2 to 2.12.9.
 [#9993](https://github.com/Kong/kong-ee/issues/9993)
 [KAG-5089](https://konghq.atlassian.net/browse/KAG-5089)

- Bumped libxslt to 1.1.42.
 [#9868](https://github.com/Kong/kong-ee/issues/9868)
 [KAG-5090](https://konghq.atlassian.net/browse/KAG-5090)

- Bumped msgpack-c to 6.1.0.
 [#9994](https://github.com/Kong/kong-ee/issues/9994)
 [KAG-509](https://konghq.atlassian.net/browse/KAG-509) [KAG-5091](https://konghq.atlassian.net/browse/KAG-5091)
#### Default

- Bumped `kong-lua-resty-kafka` to `0.20` to support TCP socket keepalive and allow client_id to be set for the kafka client.
 [#9947](https://github.com/Kong/kong-ee/issues/9947)
 [KAG-5132](https://konghq.atlassian.net/browse/KAG-5132)

- Bump lua-resty-jsonschema-rs to 0.1.5
 [#8886](https://github.com/Kong/kong-ee/issues/8886)


- bump lua-resty-cookie to 0.3.0
 [#9330](https://github.com/Kong/kong-ee/issues/9330)
 [KAG-4615](https://konghq.atlassian.net/browse/KAG-4615) [KAG-4628](https://konghq.atlassian.net/browse/KAG-4628)

- Bumped `lua-resty-azure` to `1.6.0` to support more Azure authentication methods.
 [#9822](https://github.com/Kong/kong-ee/issues/9822)
 [FTI-5972](https://konghq.atlassian.net/browse/FTI-5972)

- Bumped luaexpat to 1.5.2.
 [#9598](https://github.com/Kong/kong-ee/issues/9598)
 [KAG-4816](https://konghq.atlassian.net/browse/KAG-4816)

- Bumped `kong-redis-cluster` to `1.5.4`, fixing the following issues.

1. Fixed an issue where Kong Gateway cannot recover if partial or all pods were restared with new IPs in Kubernetes environment.
2. Fixed a memory leak issue where master nodes cache expanded infinitely upon refresh.
3. Fixed an issue where multiple cluster instances were accidently flushed.
 [#9705](https://github.com/Kong/kong-ee/issues/9705)
 [FTI-5647](https://konghq.atlassian.net/browse/FTI-5647)

### Features
#### Core

- **analytics**: send AI analytics about latency and caching to Konnect.
 [#9837](https://github.com/Kong/kong-ee/issues/9837)
 [KAG-4857](https://konghq.atlassian.net/browse/KAG-4857)

- **analytics**: Added support for also sending cache data of AI analytics to Konnect
 [#9496](https://github.com/Kong/kong-ee/issues/9496)


- Added connection support via Redis Proxy (e.g. Envoy Redis proxy or Twemproxy) via configuration field `connection_is_proxied`.
 [#9928](https://github.com/Kong/kong-ee/issues/9928)
 [FTI-6085](https://konghq.atlassian.net/browse/FTI-6085)

- Added support for AWS IAM role assuming in AWS IAM Database Authentication, with new configuration fields: "pg_iam_auth_assume_role_arn", "pg_iam_auth_role_session_name", "pg_ro_iam_auth_assume_role_arn", and "pg_ro_iam_auth_role_session_name."
 [#8721](https://github.com/Kong/kong-ee/issues/8721)
 [KAG-4561](https://konghq.atlassian.net/browse/KAG-4561)

- Added keyring encryption support to license database entity payloads.
 [#9885](https://github.com/Kong/kong-ee/issues/9885)
 [KAG-4858](https://konghq.atlassian.net/browse/KAG-4858) [KAG-5057](https://konghq.atlassian.net/browse/KAG-5057)

- Added support for a configurable STS endpoint for RDS IAM Authentication, with new configuration fields: `pg_iam_auth_sts_endpoint_url` and `pg_ro_iam_auth_sts_endpoint_url`.
 [#9654](https://github.com/Kong/kong-ee/issues/9654)
 [KAG-4599](https://konghq.atlassian.net/browse/KAG-4599)

- Added support for a configurable STS endpoint for AWS Vault. This can either be configured by `vault_aws_sts_endpoint_url` as a global configuration, or `sts_endpoint_url` on a custom AWS vault entity.
 [#9654](https://github.com/Kong/kong-ee/issues/9654)
 [KAG-4599](https://konghq.atlassian.net/browse/KAG-4599)
#### Plugin

- **ai-proxy-advanced:** Added the `ai-proxy-advanced` plugin that supports advanced load balancing between LLM services.
 [#9562](https://github.com/Kong/kong-ee/issues/9562)


- **ai-semantic-caching**: Introduced AI Semantic Caching plugin, enabling you 
to configure an embeddings-based caching system for Large Language Model responses.
 [#9624](https://github.com/Kong/kong-ee/issues/9624)


- **ai-semantic-prompt-guard:** Added the `ai-semantic-prompt-guard` plugin that supports semantic similarity-based prompt guarding.
 [#9842](https://github.com/Kong/kong-ee/issues/9842)


- **confluent:** Added the `confluent` plugin which allows to interface with Confluent.
 [#9947](https://github.com/Kong/kong-ee/issues/9947)
 [KAG-5132](https://konghq.atlassian.net/browse/KAG-5132)

- **ai-rate-limiting-advanced**: Add the cost strategy to AI rate Limiting plugin.
 [#9495](https://github.com/Kong/kong-ee/issues/9495)


- **json-threat-protection**: Added JSON threat protection plugin. Validates JSON nesting depth, array elements, object entries, key length, and string length. Logs or terminates violating requests.
 [#9472](https://github.com/Kong/kong-ee/issues/9472)
 [KAG-4698](https://konghq.atlassian.net/browse/KAG-4698)

- **ai-rate-limiting-advanced:** Added the `bedrock` and `gemini` providers to the providers list in 
the `ai-rate-limiting-advanced` plugin.
 [#9986](https://github.com/Kong/kong-ee/issues/9986)


- **app-dynamics**: Added new ANALYTICS_ENABLE flag and collected more snapshot userdata in runtime.
 [#9312](https://github.com/Kong/kong-ee/issues/9312)
 [FTI-5974](https://konghq.atlassian.net/browse/FTI-5974) [FTI-5970](https://konghq.atlassian.net/browse/FTI-5970) [FTI-6043](https://konghq.atlassian.net/browse/FTI-6043)

- **ai-rate-limiting-advanced**: Add the stats when reaching limit and exiting AI rate Limiting plugin.
 [#9778](https://github.com/Kong/kong-ee/issues/9778)


- "**AWS-Lambda**: Added support for a configurable STS endpoint with the new configuration field `aws_sts_endpoint_url`.
 [#9654](https://github.com/Kong/kong-ee/issues/9654)
 [KAG-4599](https://konghq.atlassian.net/browse/KAG-4599)

- **header-cert-auth**: Added a new plugin for header-based certificate authentication.
 [#9723](https://github.com/Kong/kong-ee/issues/9723)
 [KAG-4558](https://konghq.atlassian.net/browse/KAG-4558)

- **JWT Signer**: Supported `/jwt-signer/jwks/:jwt_signer_jwks` endpoint in dbless mode.
 [#9857](https://github.com/Kong/kong-ee/issues/9857)
 [FTI-5718](https://konghq.atlassian.net/browse/FTI-5718)

- **ldap-auth-advanced**: Supported decoding an empty sequence or set represented in long form length
 [#9843](https://github.com/Kong/kong-ee/issues/9843)
 [FTI-6147](https://konghq.atlassian.net/browse/FTI-6147)

- **OpenID-connect:** Added `claims_forbidden` property to restrict access.
 [#9221](https://github.com/Kong/kong-ee/issues/9221)
 [FTI-5976](https://konghq.atlassian.net/browse/FTI-5976)

- **ai-rate-limiting-advanced**: Added Redis cluster_max_redirections configuration option.
 [#9706](https://github.com/Kong/kong-ee/issues/9706)
 [KAG-2130](https://konghq.atlassian.net/browse/KAG-2130)

- **GraphQL-Proxy-Cache-Advanced**: Added Redis cluster_max_redirections configuration option.
 [#8620](https://github.com/Kong/kong-ee/issues/8620)
 [KAG-3947](https://konghq.atlassian.net/browse/KAG-3947)

- **GraphQL-Rate-Limiting-Advanced**: Added Redis cluster_max_redirections configuration option.
 [#8620](https://github.com/Kong/kong-ee/issues/8620)
 [KAG-3947](https://konghq.atlassian.net/browse/KAG-3947)

- **OAS-Validation**: Fixed an issue where the plugin cannot obtain the value when the path parameter name contains hyphen characters.
 [#9782](https://github.com/Kong/kong-ee/issues/9782)
 [FTI-6111](https://konghq.atlassian.net/browse/FTI-6111)

- **Proxy-Cache-Advanced**: Added Redis cluster_max_redirections configuration option.
 [#8620](https://github.com/Kong/kong-ee/issues/8620)
 [KAG-3947](https://konghq.atlassian.net/browse/KAG-3947)

- **Rate-Limiting-Advanced**: Added Redis cluster_max_redirections configuration option.
 [#8620](https://github.com/Kong/kong-ee/issues/8620)
 [KAG-3947](https://konghq.atlassian.net/browse/KAG-3947)

- **OpenID-Connect**: Added support for redis cache for introspection result with new fields `cluster_cache_strategy` and `cluster_cache_redis`. When configured, the plugin will share the tokens introspection responses cache across nodes configured to use the same Redis Database.
 [#9785](https://github.com/Kong/kong-ee/issues/9785)
 [KAG-4560](https://konghq.atlassian.net/browse/KAG-4560) [GTWY-206](https://konghq.atlassian.net/browse/GTWY-206) [KAG-5033](https://konghq.atlassian.net/browse/KAG-5033) [KAG-4660](https://konghq.atlassian.net/browse/KAG-4660)

- **upstream-oauth**: Added the Upstream OAuth plugin, enabling Kong to obtain an OAuth2 token to consume an upstream API.
 [#9883](https://github.com/Kong/kong-ee/issues/9883)
 [KAG-5056](https://konghq.atlassian.net/browse/KAG-5056)
#### Default

- Added two configurations, `admin_gui_auth_change_password_attempts` (default value `0`) and `admin_gui_auth_change_password_ttl` (default value `86400`), to limit the number of password change attempts.
 [#9424](https://github.com/Kong/kong-ee/issues/9424)


- Added a new sub-command `status` to the `kong debug` CLI tool.
 [#9685](https://github.com/Kong/kong-ee/issues/9685)
 [KAG-2589](https://konghq.atlassian.net/browse/KAG-2589)

### Fixes
#### CLI Command

- Fixed an issue where `db_import` fails when there are licenses in declarative YAML.
 [#9756](https://github.com/Kong/kong-ee/issues/9756)
 [FTI-6105](https://konghq.atlassian.net/browse/FTI-6105)
#### Configuration

- The behavior of the configuration option `analytics_flush_interval` has changed
for saving memory resources by flushing analytics messages more frequently.
It now controls the maximum time interval between two flushes of
analytics messages to the configured backend, which means that
if there are enough (less than `analytics_buffer_size_limit`)
messages have already been buffered,
the flush will happen before the configured interval.
Previously, Kong always tries to flush messages after the configured interval,
regardless of the number of messages in the buffer.
 [#9273](https://github.com/Kong/kong-ee/issues/9273)
 [KAG-4270](https://konghq.atlassian.net/browse/KAG-4270)

- Fixed an issue where `debug_listen` incorrectly used the SSL-related configuration of `status_listen`.
 [#9815](https://github.com/Kong/kong-ee/issues/9815)
 [FTI-6123](https://konghq.atlassian.net/browse/FTI-6123)
#### Core

- Built-in RBAC roles for admins (`admin` under the default workspace and `workspace-admin` under non-default workspaces) now disallow CRUD actions to `/groups` and `/groups/*` endpoints.
 [#8823](https://github.com/Kong/kong-ee/issues/8823)


- Fixed an issue where luarocks-admin was not available in /usr/local/bin.
 [#9671](https://github.com/Kong/kong-ee/issues/9671)
 [KAG-911](https://konghq.atlassian.net/browse/KAG-911)

- Fixed an issue where running Kong CLI commands with database configurations containing Hashicorp Vault references would fail to execute.
 [#9797](https://github.com/Kong/kong-ee/issues/9797)
 [FTI-6106](https://konghq.atlassian.net/browse/FTI-6106)

- Fixed an issue where the CPs won't trigger a configuration push after a keyring recovery.
 [#8876](https://github.com/Kong/kong-ee/issues/8876)
 [FTI-5900](https://konghq.atlassian.net/browse/FTI-5900)
#### Plugin

- Fixed a bug where Azure Managed-Identity tokens would never rotate  
in case of a network failure when authenticating.
 [#9930](https://github.com/Kong/kong-ee/issues/9930)


- **oauth2-introspection**: Fixed an issue where the consumer's cache cannot be invalidated when oauth2-introspection uses `client_id` as `consumer_by`.
 [#9612](https://github.com/Kong/kong-ee/issues/9612)


- **ai-rate-limiting-advanced**: Edit the logic for the window ajustement and fix missing passing window to shm
 [#9262](https://github.com/Kong/kong-ee/issues/9262)
 [FTI-5984](https://konghq.atlassian.net/browse/FTI-5984)

- **ai-semantic-caching:** Fix the `ai-semantic-caching` plugin with a condition for calculating latencies when no embeddings, add deep copy for the request table and fix countback.
 [#9865](https://github.com/Kong/kong-ee/issues/9865)


- **OAS Validation:** Fixed an issue where parameter serialization does not behave the same as in the OpenAPI specification
 [#10102](https://github.com/Kong/kong-ee/issues/10102)
 [FTI-6101](https://konghq.atlassian.net/browse/FTI-6101) [FTI-6170](https://konghq.atlassian.net/browse/FTI-6170) [FTI-6172](https://konghq.atlassian.net/browse/FTI-6172) [FTI-6161](https://konghq.atlassian.net/browse/FTI-6161) [FTI-6178](https://konghq.atlassian.net/browse/FTI-6178)

- **OpenID Connect**: Fixed a bug where anonymous consumers may be cached as nil under a certain condition.
 [#9271](https://github.com/Kong/kong-ee/issues/9271)
 [FTI-5861](https://konghq.atlassian.net/browse/FTI-5861)

- **OpenID Connect:** Updated the rediscovery to use a short lifetime (5s) if the last discovery failed.
 [#9255](https://github.com/Kong/kong-ee/issues/9255)
 [FTI-5753](https://konghq.atlassian.net/browse/FTI-5753)

- Fixed a Redis schema issue where `connect_timeout`, `read_timeout`, `send_timeout` were
reset to `null` if the deprecated `timeout` is `null`.
 [#9758](https://github.com/Kong/kong-ee/issues/9758)
 [FTI-6110](https://konghq.atlassian.net/browse/FTI-6110)

- **Rate Limiting Advanced:** Fixed an issue where if the `window_size` in the consumer group overriding config is different from the `window_size` in the default config, the rate limiting of that consumer group would fall back to local strategy.
 [#9485](https://github.com/Kong/kong-ee/issues/9485)
 [FTI-6024](https://konghq.atlassian.net/browse/FTI-6024)

- **Rate Limiting Advanced:** Fixed an issue where the sync timer may stop working due to race condition.
 [#9721](https://github.com/Kong/kong-ee/issues/9721)
 [FTI-6082](https://konghq.atlassian.net/browse/FTI-6082)

- **tls-metadata-headers**: Fixed an issue where intermediate certificates details were not added to request headers.
 [#10139](https://github.com/Kong/kong-ee/issues/10139)
 [KAG-4951](https://konghq.atlassian.net/browse/KAG-4951)

- **Konnect Application Auth**: ensure 'key_names' from correct auth strategy are used.
 [#9393](https://github.com/Kong/kong-ee/issues/9393)
 [TDX-4259](https://konghq.atlassian.net/browse/TDX-4259)

- **key-auth-enc**: Added WWW-Authenticate headers to all 401 responses.
 [#6956](https://github.com/Kong/kong-ee/issues/6956)
 [KAG-321](https://konghq.atlassian.net/browse/KAG-321)

- **konnect-application-auth:**  Fixed an issue where Konnect Application Auth exited early if an invalid OIDC application was configured.
 [#9595](https://github.com/Kong/kong-ee/issues/9595)
 [TDX-4359](https://konghq.atlassian.net/browse/TDX-4359) [KAG-4822](https://konghq.atlassian.net/browse/KAG-4822)

- **ldap-auth-adv**: Added WWW-Authenticate headers to all 401 response.
 [#6960](https://github.com/Kong/kong-ee/issues/6960)
 [KAG-321](https://konghq.atlassian.net/browse/KAG-321)

- **OpenID-connect:** Fixed an issue where using_pseudo_issuer does not work when patching.
 [#9835](https://github.com/Kong/kong-ee/issues/9835)
 [FTI-6129](https://konghq.atlassian.net/browse/FTI-6129)

- **degraphql**: Fixed an issue where multiple parameter types were not handled correctly when converting query parameters.
 [#9911](https://github.com/Kong/kong-ee/issues/9911)
 [FTI-6153](https://konghq.atlassian.net/browse/FTI-6153)

- **OAS-Validation**: Fixed a bug where the non-string primitive types passed via URL query were unexpectedly cast to string when OpenAPI spec is v3.1.0.
 [#9864](https://github.com/Kong/kong-ee/issues/9864)
 [FTI-6150](https://konghq.atlassian.net/browse/FTI-6150)

- **proxy-cache-advanced**: Fixed a bug where the Age header was not being updated correctly when serving cached requests
 [#9747](https://github.com/Kong/kong-ee/issues/9747)


- **Request-Validator**: Fix an issue where the plugin may fail to handle requests when param_schema is $ref schema.
 [#9102](https://github.com/Kong/kong-ee/issues/9102)
 [FTI-5958](https://konghq.atlassian.net/browse/FTI-5958)

- **Request-Validator**: Added a new configuration field `content_type_parameter_validation` to determine whether to enable Content-Type parameters validation.
 [#9384](https://github.com/Kong/kong-ee/issues/9384)
 [FTI-5979](https://konghq.atlassian.net/browse/FTI-5979)

- **statsd**:Fixed an issue where the exported workspace was always `default` when the workspace identifier was set to the workspace name.
 [#9854](https://github.com/Kong/kong-ee/issues/9854)

#### Admin API

- Fixed an issue where resetting the token was allowed while disabling rbac_token_enabled.
 [#9058](https://github.com/Kong/kong-ee/issues/9058)


- The `application-registration` plugin will be hidden from `available_plugins` when the Dev Portal is disabled.
 [#8656](https://github.com/Kong/kong-ee/issues/8656)


- Fixed an issue where the field `is_default` should be immutable when updating the rbac_roles.
 [#9226](https://github.com/Kong/kong-ee/issues/9226)


- Fixed an issue where the license report returns 500 when non-required fields are not specified in the Lambda and Kafka plugins.
 [#9336](https://github.com/Kong/kong-ee/issues/9336)
 [FTI-5971](https://konghq.atlassian.net/browse/FTI-5971)

- Returns a detailed error message when failed to cascade delete a workspace caused by admins associated.
 [#9075](https://github.com/Kong/kong-ee/issues/9075)
 [FTI-5921](https://konghq.atlassian.net/browse/FTI-5921)
#### Default

- Fixed an issue where the stale license expiry warning continued to be logged even if the license was updated.
 [#9672](https://github.com/Kong/kong-ee/issues/9672)
 [FTI-5836](https://konghq.atlassian.net/browse/FTI-5836)

- License expiry warnings are no longer logged and license info is removed from /metrics in Konnect.
 [#9689](https://github.com/Kong/kong-ee/issues/9689)
 [KAG-4225](https://konghq.atlassian.net/browse/KAG-4225)
## Kong-Manager-Enterprise






### Features
#### Default

- Kong Manager will now show input boxes that allow optionally creating SNIs while creating a certificate.
 [#3488](https://github.com/Kong/kong-admin/issues/3488)


- While deleting a workspace, Kong Manager will now list admins that prevent the operation.
 [#3427](https://github.com/Kong/kong-admin/issues/3427)


- Kong Manager will now show scoping entities as links in the plugin detail page.
 [#3454](https://github.com/Kong/kong-admin/issues/3454)


- Added UI components for building the vault reference easily while configuring referenceable fields for plugins.
 [#3495](https://github.com/Kong/kong-admin/issues/3495)
s

### Fixes
#### Default

- Fixed an issue where dynamic ordering was configurable for plugins scoped by consumers and/or consumer groups. These plugins does not support dynamic ordering.
 [#3415](https://github.com/Kong/kong-admin/issues/3415)


- Removed redundant data previously saved in browser's local storage.
 [#3438](https://github.com/Kong/kong-admin/issues/3438)


- Fixed issues with `cluster_addresses` and `sentinel_addresses` fields for plugins that support Redis clusters.
 [#3375](https://github.com/Kong/kong-admin/issues/3375)


- Fixed an issue where the overview page for Dev Portal was not correctly rendered.
 [#3395](https://github.com/Kong/kong-admin/issues/3395)


- Fixed an issue where user info was not refreshed after the active admin was updated.
 [#3386](https://github.com/Kong/kong-admin/issues/3386)