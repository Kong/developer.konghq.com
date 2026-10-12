---
title: "Lua sandboxing in {{site.ai_gateway}}"
content_type: reference
layout: reference

description: "Reference for Lua sandboxing in {{site.ai_gateway}}, including the available sandbox modes, how to set them, and how sandboxed code sees AI entities."

breadcrumbs:
  - /ai-gateway/

products:
  - ai-gateway

works_on:
  - konnect

min_version:
  ai-gateway: '2.0'

tags:
  - ai
  - security

related_resources:
  - text: Pre-Function AI Policy
    url: /ai-gateway/policies/pre-function/
  - text: Post-Function AI Policy
    url: /ai-gateway/policies/post-function/
  - text: Exit Transformer AI Policy
    url: /ai-gateway/policies/exit-transformer/
  - text: "{{site.ai_gateway}} configuration reference"
    url: /ai-gateway/configuration/
  - text: "How entities translate to {{site.base_gateway}} configuration"
    url: /ai-gateway/configure-on-prem/#how-entities-translate-to-kong-gateway-configuration
  - text: "Lua sandboxing in {{site.base_gateway}}"
    url: /gateway/sandboxing/
---

Some {{site.ai_gateway}} AI Policies run Lua code that you write in the AI Policy configuration.
Sandboxing restricts that code for heightened security.
The Lua (or LuaJIT) language itself isn't limited. Sandboxing restricts only the available environment and the set of modules that the code can load.

The `untrusted_lua` data plane setting controls which restrictions apply.
Each data plane node reads this setting from its own `kong.conf` file, and the setting applies to every AI Policy on that node.

## What the sandbox applies to

The following AI Policies run Lua code that you provide in their configuration:

* [Pre-Function](/ai-gateway/policies/pre-function/)
* [Post-Function](/ai-gateway/policies/post-function/)
* [Exit Transformer](/ai-gateway/policies/exit-transformer/)

Other AI Policies evaluate Lua expressions or templates in their configuration and use the same sandbox.
For example, [AI Custom Guardrail](/ai-gateway/policies/ai-custom-guardrail/) templates, Request Transformer templates, and custom fields in logging AI Policies.
<!-- TODO: confirm the exact list of AI Policies that use the sandbox with engineering. The kong-ee sandbox module is required by the AI Policies' plugin code, but not every use is an AI Policy surface. -->

{{site.ai_gateway}} also uses a Pre-Function AI Policy internally.
When you create an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) of type `conversion-only`, {{site.ai_gateway}} generates a Pre-Function that rejects requests that don't arrive through the internal listener connection.
This generated AI Policy runs in the sandbox like any other Pre-Function.

## Sandbox modes

Set `untrusted_lua` to one of the following values:

<!--vale off-->
{% table %}
columns:
  - title: Mode
    key: mode
  - title: Description
    key: description
rows:
  - mode: "`off`"
    description: |
      Disallows all custom Lua code. A data plane node doesn't load or run code from any AI Policy that depends on the sandbox.
      See [Disable custom code execution](#disable-custom-code-execution).
  - mode: "`strict`"
    description: |
      The default. An allowlist-based environment with limited access to the Lua standard library, the Kong PDK, and Nginx APIs. All file I/O and network I/O is disallowed.
      See [Strict mode](#strict-mode).
  - mode: "`lax`"
    description: |
      Extends `strict` with network I/O, vault access, cache access, and read-only access to configuration.
      See [Lax mode](#lax-mode).
  - mode: "`sandbox`"
    description: |
      Deprecated. Gives nearly full access to the Kong PDK and Nginx APIs with limited access to the standard Lua environment.
      You can extend it with `untrusted_lua_sandbox_requires` and `untrusted_lua_sandbox_environment`.
  - mode: "`on`"
    description: |
      Unrestricted. Code has complete access to the environment and to all modules, and no protections apply.
{% endtable %}
<!--vale on-->

{:.warning}
> LuaJIT isn't a secure sandbox for running malicious code.
> The sandbox prevents trivial attacks and accidental changes to global state. It doesn't replace access controls.
> Anyone who can create or edit an AI Policy that runs custom Lua can execute code on your data planes, so limit who can create these AI Policies.

## Set the sandbox mode

Set the `untrusted_lua` parameter in the `kong.conf` file of each data plane node, or set the equivalent environment variable:

```sh
KONG_UNTRUSTED_LUA=strict
```

See [`untrusted_lua`](/ai-gateway/configuration/#untrusted-lua) in the {{site.ai_gateway}} configuration reference.
<!-- TODO: confirm how to set untrusted_lua on a Konnect-managed data plane. koko-private has no control plane setting for it, so this is a data plane setting only. Confirm the #untrusted-lua anchor renders on /ai-gateway/configuration/. -->

The [`untrusted_lua_sandbox_requires`](/ai-gateway/configuration/#untrusted-lua-sandbox-requires) and [`untrusted_lua_sandbox_environment`](/ai-gateway/configuration/#untrusted-lua-sandbox-environment) parameters apply only in `sandbox` mode. They have no effect in other modes.

## Disable custom code execution

If you don't need custom Lua code, set `untrusted_lua=off`.
The data plane node still starts, syncs configuration, and runs AI Policies that don't use the sandbox.
A request that reaches an AI Policy running custom Lua fails, and the data plane logs the message `loading of untrusted Lua code disabled because 'untrusted_lua' config option is set to 'off'`.

Before you set `off`, check which of your AI Policies depend on the sandbox.
Setting `off` affects more than Pre-Function and Post-Function. It also affects AI Policies that evaluate Lua templates or expressions, and the Pre-Function that {{site.ai_gateway}} generates for `conversion-only` AI MCP Servers.
With `untrusted_lua=off`, tool calls through a `listener` AI MCP Server that aggregates a `conversion-only` server fail with `request failed: closed`, because the generated Pre-Function can't run.
A direct request to the `conversion-only` server's route returns an empty reply instead of a `404`.
The `listener` itself still answers MCP requests such as `initialize`.

An AI Custom Guardrail fails on every request, even when its configuration uses a plain string for `request.url` and no `$(...)` expression.
The request returns a `500` error with the message `failed to sanitize request: failed to invoke custom guardrail service: failed to render url: failed to render by template: loading of untrusted Lua code disabled because 'untrusted_lua' config option is set to 'off'`.
<!-- TODO: verified live on 2.2.0 on a second data plane with a Model-scoped Post-Function, a conversion-only AI MCP Server behind a listener, and a Model-scoped AI Custom Guardrail (INPUT mode, static url, $(content) in the body, $(true) as the block expression). Under strict the same guardrail rendered its templates and blocked the request. Not tested: Request Transformer templates and custom fields in logging AI Policies. -->

Because the sandbox applies per data plane node, an AI Policy that works on one node fails on a node where `untrusted_lua` is `off`.

## Strict mode

Strict mode is an allowlist-based execution environment and is the default.
You can load and run custom Lua code with some limitations. Most notably, all file I/O and network I/O is disallowed.

For example, in strict mode:

* `require("resty.http")` fails with `require("resty.http") not allowed within sandbox`.
* `io.open`, `os.execute`, and `ngx.socket.tcp` aren't available.
* `require("cjson")` works.

The following lists show what strict mode allows in {{site.ai_gateway}} 2.2.
They differ from the {{site.base_gateway}} sandboxing reference as described in [Differences in the allowlists](#differences-in-the-allowlists).
<!-- TODO: these lists were generated from kong-ee aigw-master (commit 64c616d2b9) and checked against a 2.2.0 data plane for kong.router, kong.configuration, kong.client.get_principal, and kong.log. Regenerate them when the sandbox changes. -->

### Environment in strict mode

In strict mode you can use:

#### Standard constants and functions

```text
_VERSION  assert  error  ipairs  next  pairs  pcall  print  select  tonumber
tostring  type  unpack  xpcall
```

#### Bit functions

```text
bit.arshift  bit.band  bit.bnot  bit.bor  bit.bswap  bit.bxor  bit.lshift
bit.rol  bit.ror  bit.rshift  bit.tobit  bit.tohex
```

#### Coroutine functions

```text
coroutine.create  coroutine.resume  coroutine.running  coroutine.status
coroutine.wrap  coroutine.yield
```

#### IO functions

```text
io.type
```

#### LuaJIT functions

```text
jit.os  jit.arch  jit.version  jit.version_num
```

#### Math functions

```text
math.abs  math.acos  math.asin  math.atan  math.atan2  math.ceil  math.cos
math.cosh  math.deg  math.exp  math.floor  math.fmod  math.frexp  math.huge
math.ldexp  math.log  math.log10  math.max  math.min  math.modf  math.pi
math.pow  math.rad  math.random  math.sin  math.sinh  math.sqrt  math.tan
math.tanh
```

#### OS functions

```text
os.clock  os.date  os.difftime  os.time
```

#### String functions

```text
string.byte  string.char  string.find  string.format  string.gmatch
string.gsub  string.len  string.lower  string.match  string.rep
string.reverse  string.sub  string.upper
```

#### Table functions

```text
table.clear  table.clone  table.concat  table.foreach  table.foreachi
table.getn  table.insert  table.isarray  table.isempty  table.maxn
table.move  table.new  table.nkeys  table.pack  table.remove  table.sort
table.unpack
```

#### Kong constants

```text
kong.default_workspace  kong.version  kong.version_num
```

#### Kong context

```text
kong.ctx.shared[*]  kong.ctx.plugin[*]
```

#### Kong client PDK

```text
kong.client.authenticate
kong.client.authenticate_consumer_group_by_consumer_id
kong.client.get_consumer  kong.client.get_consumer_group
kong.client.get_consumer_groups  kong.client.get_credential
kong.client.get_forwarded_ip  kong.client.get_forwarded_port
kong.client.get_ip  kong.client.get_port  kong.client.get_protocol
kong.client.load_consumer  kong.client.set_authenticated_consumer_group
kong.client.set_authenticated_consumer_groups  kong.client.set_token
kong.client.get_token  kong.client.get_jwt_token_header
kong.client.get_jwt_token_payload
```

#### Kong cluster PDK

```text
kong.cluster.get_id
```

#### Kong IP PDK

```text
kong.ip.is_trusted
```

#### Kong JWE PDK

```text
kong.jwe.decode  kong.jwe.decrypt  kong.jwe.encrypt
```

#### Kong log PDK

```text
kong.log  kong.log.alert  kong.log.crit  kong.log.debug  kong.log.emerg
kong.log.err  kong.log.info  kong.log.inspect  kong.log.notice
kong.log.warn  kong.log.serialize  kong.log.set_serialize_value
kong.log.deprecation  kong.log.deprecation.write
```

#### Kong Nginx PDK

```text
kong.nginx.get_subsystem
```

#### Kong node PDK

```text
kong.node.get_hostname  kong.node.get_id
```

#### Kong plugin PDK

```text
kong.plugin.get_id
```

#### Kong request PDK

```text
kong.request.get_body  kong.request.get_forwarded_host
kong.request.get_forwarded_path  kong.request.get_forwarded_port
kong.request.get_forwarded_prefix  kong.request.get_forwarded_scheme
kong.request.get_header  kong.request.get_headers  kong.request.get_host
kong.request.get_http_version  kong.request.get_method
kong.request.get_path  kong.request.get_path_with_query
kong.request.get_port  kong.request.get_query  kong.request.get_query_arg
kong.request.get_raw_body  kong.request.get_raw_path
kong.request.get_raw_query  kong.request.get_scheme
kong.request.get_start_time  kong.request.get_uri_captures
```

#### Kong response PDK

```text
kong.response.add_header  kong.response.clear_header  kong.response.error
kong.response.exit  kong.response.get_header  kong.response.get_headers
kong.response.get_raw_body  kong.response.get_source
kong.response.get_status  kong.response.set_header
kong.response.set_headers  kong.response.set_raw_body
kong.response.set_status
```

#### Kong service request PDK

```text
kong.service.request.add_header  kong.service.request.clear_header
kong.service.request.clear_query_arg  kong.service.request.enable_buffering
kong.service.request.set_authentication_header
kong.service.request.set_authentication_headers
kong.service.request.set_body  kong.service.request.set_header
kong.service.request.set_headers  kong.service.request.set_method
kong.service.request.set_path  kong.service.request.set_query
kong.service.request.set_raw_body  kong.service.request.set_raw_query
kong.service.request.set_scheme
```

#### Kong service response PDK

```text
kong.service.response.get_body  kong.service.response.get_header
kong.service.response.get_headers  kong.service.response.get_raw_body
kong.service.response.get_status
```

#### Kong table PDK

```text
kong.table.clear  kong.table.merge
```

#### Kong telemetry PDK

```text
kong.telemetry.log
```

#### Kong tracing PDK

```text
kong.tracing.active_span  kong.tracing.create_span
kong.tracing.get_probability_sampling_decision  kong.tracing.get_root_span
kong.tracing.get_sampling_decision  kong.tracing.get_spans
kong.tracing.init_spans  kong.tracing.link_span  kong.tracing.process_span
kong.tracing.set_active_span  kong.tracing.set_should_sample
kong.tracing.start_span
```

#### Kong metrics PDK

```text
kong.metrics.counter  kong.metrics.gauge  kong.metrics.histogram
kong.metrics.VALUE_TYPE
```

#### Nginx constants

```text
ngx.AGAIN  ngx.ALERT  ngx.CRIT  ngx.DEBUG  ngx.DECLINED  ngx.DONE  ngx.EMERG
ngx.ERR  ngx.ERROR  ngx.HTTP_ACCEPTED  ngx.HTTP_BAD_GATEWAY
ngx.HTTP_BAD_REQUEST  ngx.HTTP_CLOSE  ngx.HTTP_CONFLICT  ngx.HTTP_CONTINUE
ngx.HTTP_COPY  ngx.HTTP_CREATED  ngx.HTTP_DELETE  ngx.HTTP_FORBIDDEN
ngx.HTTP_GATEWAY_TIMEOUT  ngx.HTTP_GET  ngx.HTTP_GONE  ngx.HTTP_HEAD
ngx.HTTP_ILLEGAL  ngx.HTTP_INSUFFICIENT_STORAGE
ngx.HTTP_INTERNAL_SERVER_ERROR  ngx.HTTP_LOCK
ngx.HTTP_METHOD_NOT_IMPLEMENTED  ngx.HTTP_MKCOL  ngx.HTTP_MOVE
ngx.HTTP_MOVED_PERMANENTLY  ngx.HTTP_MOVED_TEMPORARILY
ngx.HTTP_NOT_ACCEPTABLE  ngx.HTTP_NOT_ALLOWED  ngx.HTTP_NOT_FOUND
ngx.HTTP_NOT_IMPLEMENTED  ngx.HTTP_NOT_MODIFIED  ngx.HTTP_NO_CONTENT
ngx.HTTP_OK  ngx.HTTP_OPTIONS  ngx.HTTP_PARTIAL_CONTENT  ngx.HTTP_PATCH
ngx.HTTP_PAYMENT_REQUIRED  ngx.HTTP_PERMANENT_REDIRECT  ngx.HTTP_POST
ngx.HTTP_PROPFIND  ngx.HTTP_PROPPATCH  ngx.HTTP_PUT
ngx.HTTP_REQUEST_TIMEOUT  ngx.HTTP_SEE_OTHER  ngx.HTTP_SERVICE_UNAVAILABLE
ngx.HTTP_SPECIAL_RESPONSE  ngx.HTTP_SWITCHING_PROTOCOLS
ngx.HTTP_TEMPORARY_REDIRECT  ngx.HTTP_TOO_MANY_REQUESTS  ngx.HTTP_TRACE
ngx.HTTP_UNAUTHORIZED  ngx.HTTP_UNLOCK  ngx.HTTP_UPGRADE_REQUIRED
ngx.HTTP_VERSION_NOT_SUPPORTED  ngx.INFO  ngx.NOTICE  ngx.OK  ngx.STDERR
ngx.WARN
```

#### Nginx config constants

```text
ngx.config.nginx_version  ngx.config.ngx_lua_version  ngx.config.subsystem
```

#### Nginx fields

```text
ngx.arg[*]  ngx.ctx[*]  ngx.var[*]  ngx.header[*]  ngx.headers_sent
ngx.is_subrequest  ngx.status
```

#### Nginx functions

```text
ngx.cookie_time  ngx.crc32_long  ngx.crc32_short  ngx.decode_args
ngx.decode_base64  ngx.encode_args  ngx.encode_base64  ngx.eof
ngx.escape_uri  ngx.exit  ngx.flush  ngx.get_phase  ngx.get_raw_phase
ngx.hmac_sha1  ngx.http_time  ngx.localtime  ngx.log  ngx.md5  ngx.md5_bin
ngx.now  ngx.null  ngx.parse_http_time  ngx.print  ngx.quote_sql_str
ngx.redirect  ngx.say  ngx.send_headers  ngx.sha1_bin  ngx.sleep  ngx.time
ngx.today  ngx.unescape_uri  ngx.update_time  ngx.utctime
```

#### Nginx regex functions

```text
ngx.re.find  ngx.re.gmatch  ngx.re.gsub  ngx.re.match  ngx.re.sub
```

#### Nginx request functions

```text
ngx.req.append_body  ngx.req.clear_header  ngx.req.discard_body
ngx.req.finish_body  ngx.req.get_body_data  ngx.req.get_headers
ngx.req.get_method  ngx.req.get_post_args  ngx.req.get_uri_args
ngx.req.http_version  ngx.req.init_body  ngx.req.is_internal
ngx.req.raw_header  ngx.req.read_body  ngx.req.set_body_data
ngx.req.set_header  ngx.req.set_method  ngx.req.set_uri
ngx.req.set_uri_args  ngx.req.socket  ngx.req.start_time
```

#### Nginx response functions

```text
ngx.resp.get_headers
```

#### Nginx worker functions

```text
ngx.worker.count  ngx.worker.exiting  ngx.worker.id  ngx.worker.pid
ngx.worker.pids
```

### Available modules in strict mode

You can use the standard `require` function to load the following modules in strict mode:

#### Lua and LuaJIT libraries

```text
bit  string.buffer  table.clear  table.clone  table.isarray  table.isempty
table.new  table.nkeys
```

#### Argon2 library

```text
argon2
```

#### Bcrypt library

```text
bcrypt
```

#### cJSON libraries

```text
cjson  cjson.safe
```

#### LYAML library

```text
lyaml
```

#### Kong constants and meta libraries

```text
kong.constants  kong.meta
```

#### Kong tools

```text
kong.tools.cjson  kong.tools.gzip  kong.tools.ip  kong.tools.jose
kong.tools.json  kong.tools.mime_type  kong.tools.rand  kong.tools.sha1
kong.tools.sha256  kong.tools.string  kong.tools.table  kong.tools.time
kong.tools.timestamp  kong.tools.uri  kong.tools.utils  kong.tools.uuid
kong.tools.yield
```

#### Nginx libraries

```text
ngx.base64  ngx.re  ngx.req  ngx.resp  ngx.semaphore
```

#### Penlight libraries

```text
pl.stringx  pl.tablex
```

#### OpenResty libraries

```text
resty.aes  resty.lock  resty.md5  resty.random  resty.sha  resty.sha1
resty.sha224  resty.sha256  resty.sha384  resty.sha512  resty.string
resty.upload  resty.core.time  resty.lrucache  resty.lrucache.pureffi
resty.ada  resty.ada.search  resty.cookie  resty.ipmatcher  resty.jit-uuid
resty.jwt  resty.evp  resty.jwt-validators  resty.hmac  resty.passwdqc
```

#### OpenSSL libraries

```text
resty.openssl  resty.openssl.asn1  resty.openssl.bn  resty.openssl.cipher
resty.openssl.ctx  resty.openssl.dh  resty.openssl.digest  resty.openssl.ec
resty.openssl.ecx  resty.openssl.err  resty.openssl.hmac  resty.openssl.kdf
resty.openssl.mac  resty.openssl.objects  resty.openssl.param
resty.openssl.pkcs12  resty.openssl.pkey  resty.openssl.provider
resty.openssl.rand  resty.openssl.rsa  resty.openssl.ssl
resty.openssl.ssl_ctx  resty.openssl.stack  resty.openssl.version
resty.openssl.x509  resty.openssl.x509.altname  resty.openssl.x509.chain
resty.openssl.x509.crl  resty.openssl.x509.csr  resty.openssl.x509.name
resty.openssl.x509.revoked  resty.openssl.x509.store
resty.openssl.x509.extension  resty.openssl.x509.extension.dist_points
resty.openssl.x509.extension.info_access
```

#### LuaSocket URL library

```text
socket.url
```

#### Tablepool library

```text
tablepool
```

#### Version library

```text
version
```

#### XMLua library

```text
xmlua
```

## Lax mode

Lax mode includes everything in strict mode, plus network I/O and some other functionality.
It also adds `kong.router.get_route`, `kong.router.get_service`, and `kong.configuration`.

### Environment in lax mode

Lax mode includes everything in strict mode, plus the following:

#### Kong cache PDK

```text
kong.cache:get  kong.cache:get_bulk  kong.cache:probe  kong.cache:invalidate
kong.cache:invalidate_local  kong.cache:safe_set  kong.cache:renew
```

#### Kong client PDK (lax mode)

```text
kong.client.get_aws_vpce_id
```

#### Kong client TLS PDK

```text
kong.client.tls.disable_session_reuse
kong.client.tls.get_full_client_certificate_chain
kong.client.tls.request_client_certificate
kong.client.tls.set_client_verify
```

#### Kong DB PDK

```text
kong.db.certificates:cache_key  kong.db.certificates:select
kong.db.certificates:select_by_cache_key  kong.db.consumers:cache_key
kong.db.consumers:select  kong.db.consumers:select_by_cache_key
kong.db.consumers:select_by_custom_id  kong.db.consumers:select_by_username
kong.db.consumers:select_by_username_ignore_case  kong.db.keys:cache_key
kong.db.keys:select  kong.db.keys:select_by_cache_key
kong.db.keys:select_by_name  kong.db.plugins:cache_key
kong.db.plugins:select  kong.db.plugins:select_by_cache_key
kong.db.plugins:select_by_instance_name  kong.db.routes:cache_key
kong.db.routes:select  kong.db.routes:select_by_cache_key
kong.db.routes:select_by_name  kong.db.services:cache_key
kong.db.services:select  kong.db.services:select_by_cache_key
kong.db.services:select_by_name  kong.db.snis:cache_key  kong.db.snis:select
kong.db.snis:select_by_cache_key  kong.db.snis:select_by_name
kong.db.targets:cache_key  kong.db.targets:select
kong.db.targets:select_by_cache_key  kong.db.targets:select_by_target
kong.db.upstreams:cache_key  kong.db.upstreams:select
kong.db.upstreams:select_by_cache_key  kong.db.upstreams:select_by_name
```

#### Kong DNS PDK

```text
kong.dns.resolve  kong.dns.toip
```

#### Kong Nginx PDK (lax mode)

```text
kong.nginx.get_statistics
```

#### Kong node PDK (lax mode)

```text
kong.node.get_memory_stats
```

#### Kong router PDK

```text
kong.router.get_route  kong.router.get_service
```

#### Kong service PDK

```text
kong.service.enable_recording_upstream_ssl  kong.service.set_retries
kong.service.set_target  kong.service.set_target_retry_callback
kong.service.set_timeouts  kong.service.set_tls_cert_key
kong.service.set_tls_verify  kong.service.set_tls_verify_depth
kong.service.set_tls_verify_store  kong.service.set_upstream
```

#### Kong vault PDK

```text
kong.vault.get  kong.vault.is_reference  kong.vault.parse_reference
kong.vault.try  kong.vault.update
```

#### Kong WebSocket client PDK

```text
kong.websocket.client.close  kong.websocket.client.drop_frame
kong.websocket.client.get_frame  kong.websocket.client.set_frame_data
kong.websocket.client.set_max_payload_size  kong.websocket.client.set_status
```

#### Kong WebSocket upstream PDK

```text
kong.websocket.upstream.close  kong.websocket.upstream.drop_frame
kong.websocket.upstream.get_frame  kong.websocket.upstream.set_frame_data
kong.websocket.upstream.set_max_payload_size
kong.websocket.upstream.set_status
```

#### Nginx debug build constant

```text
ngx.config.debug
```

#### Nginx subrequest functions

```text
ngx.location.capture  ngx.location.capture_multi
```

#### Nginx request functions (lax mode)

```text
ngx.req.get_body_file  ngx.req.set_body_file
```

#### Nginx thread functions

```text
ngx.thread.kill  ngx.thread.spawn  ngx.thread.wait
```

#### Nginx socket functions

```text
ngx.socket.connect  ngx.socket.stream  ngx.socket.tcp  ngx.socket.udp
```

#### Kong configuration (secrets redacted)

```text
kong.configuration[*]
```

### Available modules in lax mode

Lax mode includes every module in strict mode, plus the following:

#### Redis libraries

```text
kong.enterprise_edition.tools.redis.v2  resty.redis  resty.rediscluster
resty.xmodem
```

#### Kong concurrency library

```text
kong.concurrency
```

#### PostgreSQL libraries

```text
pgmoon  pgmoon.arrays  pgmoon.hstore
```

#### Memcached library

```text
resty.memcached
```

#### MySQL library

```text
resty.mysql
```

#### DNS resolver library

```text
resty.dns.resolver
```

#### AWS libraries

```text
resty.aws  resty.aws.utils  resty.aws.config  resty.aws.request.validate
resty.aws.request.build  resty.aws.request.sign  resty.aws.request.execute
resty.aws.request.signatures.utils  resty.aws.request.signatures.v4
resty.aws.request.signatures.presign  resty.aws.request.signatures.none
resty.aws.service.rds.signer  resty.aws.credentials.Credentials
resty.aws.credentials.ChainableTemporaryCredentials
resty.aws.credentials.CredentialProviderChain
resty.aws.credentials.EC2MetadataCredentials
resty.aws.credentials.EnvironmentCredentials
resty.aws.credentials.SharedFileCredentials
resty.aws.credentials.RemoteCredentials
resty.aws.credentials.TokenFileWebIdentityCredentials
resty.aws.raw-api.region_config_data
```

#### Azure libraries

```text
resty.azure  resty.azure.config  resty.azure.utils
resty.azure.credentials.Credentials
resty.azure.credentials.ClientCredentials
resty.azure.credentials.WorkloadIdentityCredentials
resty.azure.credentials.ManagedIdentityCredentials  resty.azure.api.keyvault
resty.azure.api.secrets  resty.azure.api.keys  resty.azure.api.certificates
resty.azure.api.auth  resty.azure.api.request.build
resty.azure.api.request.execute  resty.azure.api.response.handle
```

#### GCP libraries

```text
resty.gcp  resty.gcp.request.credentials.accesstoken
resty.gcp.request.discovery
```

#### HTTP request libraries

```text
resty.http  resty.http_connect  resty.http_headers
```

#### jq library

```text
resty.jq
```

#### Session library

```text
resty.session
```

<!-- TODO: verified live on 2.2.0 in lax mode: kong.router, kong.configuration, resty.http, and ngx.socket.tcp are available. Confirm which other lax mode modules are relevant for AI Gateway data planes, for example resty.aws and resty.redis. -->

## Differences in the allowlists

The {{site.base_gateway}} sandboxing reference lists the following as available in strict mode, but they aren't available in {{site.ai_gateway}} 2.2:

* `kong.router.get_route` and `kong.router.get_service`. In {{site.ai_gateway}}, `kong.router` is `nil` in strict mode and available only in lax mode.
* `kong.configuration`. It is `nil` in strict mode and available in lax mode.
* `kong.client.get_principal` and `kong.client.get_identity_realm_source`. Both are `nil` in strict mode.

To read the {{site.identity}} Principal of a request, use a [condition](/ai-gateway/conditions/) with the `principal.id` field instead.

<!-- TODO: confirmed live on 2.2.0 (kong.router and kong.configuration are nil in strict) and in kong-ee aigw-master (kong.router is in environment/lax.lua only). Confirm with engineering whether the base Gateway reference or the runtime is the source of truth, and which AI Gateway versions this applies to. -->
## Differences from {{site.base_gateway}}

The sandbox is the same one that {{site.base_gateway}} uses, but {{site.ai_gateway}} generates the resources that your code runs against.
If you already use sandboxed Lua in {{site.base_gateway}}, the following differences apply to AI Policies.

### Generated Routes and Services

{{site.ai_gateway}} [generates Routes and Services](/ai-gateway/configure-on-prem/#how-entities-translate-to-kong-gateway-configuration) from your AI entities.
In lax mode, PDK calls that return a Route or a Service, such as `kong.router.get_route` and `kong.router.get_service`, return those generated resources, not your [AI Model](/ai-gateway/entities/ai-model/), [AI Agent](/ai-gateway/entities/ai-agent/), or [AI MCP Server](/ai-gateway/entities/ai-mcp-server/).
Generated names don't match your entity names, so don't compare them to your entity names.
The same applies to `kong.db.routes`, `kong.db.services`, and the `kong.service.set_*` calls.
In strict mode, `kong.router` isn't available. See [Differences in the allowlists](#differences-in-the-allowlists).
For a request to an AI Model, `kong.router.get_route` returns a Route named for the provider endpoint, such as `openai-chat`, and `kong.router.get_service` returns a Service named `ai-gateway`.
Neither has tags.
Models that resolve to the same provider endpoint share one Route, so the Route name doesn't identify a single Model.
<!-- TODO: verified live on 2.2.0 in lax mode for an AI Model with an OpenAI target. Not tested: AI Agent and AI MCP Server Route and Service names, and other providers. -->
### Consumers

An [AI Consumer](/ai-gateway/entities/ai-consumer/) becomes a {{site.base_gateway}} Consumer with the AI Consumer's name as its `username`.
For an authenticated AI Consumer, `kong.client.get_consumer` returns a table with `id` and `username`. It includes `custom_id` and `tags` when the AI Consumer sets them. The `tags` list contains the AI Consumer's labels as `key:value` strings.
`kong.client.get_consumer_groups` returns a table of the AI Consumer Groups that the AI Consumer belongs to, and each entry has a `name`.
It returns `nil` when the AI Consumer has no groups.

An `oauth` AI Consumer behaves the same way. {{site.ai_gateway}} matches the token claim in `config.consumer_claims` to the AI Consumer's `custom_id`, and `kong.client.get_consumer` then returns that AI Consumer's `id`, `username`, `custom_id`, and `tags`.

When you enable {{site.identity}} Principal mapping (`config.principals`) on an `openid-connect` AI Auth Strategy, set `config.consumer_optional` to `true` if the Principal has no linked AI Consumer. Otherwise, {{site.ai_gateway}} rejects the request with a `401` even when the Principal matches.
In that case, `kong.client.get_consumer` returns `nil`.

{{site.ai_gateway}} authenticates a request before a Post-Function runs, but after a Pre-Function runs.
To read the Consumer, use a Post-Function.
<!-- TODO: verified live on 2.2.0 with an api-key AI Consumer and a Model-scoped Post-Function. A global Pre-Function that calls get_consumer with a valid key got nil, and it ran before the authentication check. custom_id, labels as tags, and AI Consumer Group names were verified live with an api-key AI Consumer. OAuth AI Consumers were verified live with a Kong Identity auth server and client_credentials token (sub equals the client ID). Principal mapping was verified live with a Kong Identity directory, a Principal, and an auth_server_client identity: the `principal.id != null` condition matched, kong.client.get_principal and get_identity_realm_source were nil in the sandbox, and the request returned 401 until consumer_optional was true. Not verified: Principal metadata, the match_consumer path with a control_plane_consumer identity, and Principals through other identity providers. -->

Without a valid key, the request fails authentication and the AI Policy doesn't run.

### Shared state

The `kong.ctx.shared` table is shared by the AI Policies that run during a request.
A global Pre-Function can write a value that a Model-scoped Post-Function reads in the same request.
<!-- TODO: verified live on 2.2.0 for a global Pre-Function and a Model-scoped Post-Function. Not verified: other scope combinations, and the priority order for Pre-Function and Post-Function relative to other AI Policies. -->

### AI Policy configuration

The {{site.ai_gateway}} versions of these AI Policies accept only the per-phase fields: `certificate`, `rewrite`, `access`, `header_filter`, `body_filter`, `log`, and the WebSocket phases `ws_handshake`, `ws_client_frame`, `ws_upstream_frame`, and `ws_close`.
They don't accept the deprecated `config.functions` field from the {{site.base_gateway}} Pre-Function plugin.

You can apply Pre-Function, Post-Function, and Exit Transformer AI Policies to an AI Model, AI MCP Server, AI Agent, AI Consumer, AI Consumer Group, or globally.
See [AI Policy scopes](/ai-gateway/entities/ai-policy/#ai-policy-scopes).

A Model-scoped AI Policy runs only when the request body names the Model in the `model` field.
A request that names a different model, such as the provider's own model name, doesn't run the AI Policy.

<!-- TODO: on 2.2.0, a Model-scoped Pre-Function never ran in testing, even with no other Pre-Function present, while a Model-scoped Post-Function, a Model-scoped request-termination AI Policy, and a global Pre-Function all ran. A Model-scoped Pre-Function (priority 1000000) may run before {{site.ai_gateway}} has selected the Model. Confirm with engineering whether this is a bug or a documented limitation before publishing, and test the Consumer, Consumer Group, AI MCP Server, and AI Agent scopes. -->
<!-- TODO: on 2.2.0, with three global Pre-Function AI Policies, only one took effect. Confirm whether only one AI Policy of a type can apply at a scope. -->

### Exit Transformer

An Exit Transformer AI Policy rewrites responses that other AI Policies send, including authentication `401` responses and responses that a Pre-Function or Post-Function returns with `kong.response.exit`.
Each function receives the status code, the body, and the headers, and returns the new values.
By default, it doesn't rewrite responses that {{site.ai_gateway}} sends for unknown conditions, such as the `404` for a request that matches no Route.
Set `handle_unknown` and `handle_unexpected` to `true` to rewrite those too.
<!-- TODO: verified live on 2.2.0 as a global AI Policy under strict mode. With the default flags it rewrote a plugin exit and an auth 401 but not a no-Route 404. With both flags true it also rewrote the 404. A Model-scoped Exit Transformer did not rewrite a Model-scoped request-termination 403 in testing, like the Model-scoped Pre-Function. Confirm with engineering. -->

### Conditions

Unlike the {{site.base_gateway}} Pre-Function and Post-Function plugins, the {{site.ai_gateway}} Pre-Function and Post-Function AI Policies support the `condition` field.
When the condition evaluates to `false`, {{site.ai_gateway}} skips the AI Policy.
See [AI Policy conditions](/ai-gateway/conditions/).
<!-- TODO: verified live on 2.2.0 for a global Pre-Function and a Model-scoped Post-Function: with `condition: 'http.headers.x_test == "go"'` the AI Policy ran with the header and was skipped without it. The {{site.base_gateway}} docs list both as unsupported. Confirm the {{site.ai_gateway}} behavior with engineering, then update the TODO in /ai-gateway/conditions/. -->

## Examples

The following examples run in strict mode, the default.
Each example is an AI Policy that you attach to an AI Model, or apply globally.
A Model-scoped AI Policy runs only when the request body names the Model in the `model` field.

### Read the AI Consumer in a Post-Function

A Post-Function runs after authentication, so `kong.client.get_consumer` returns the authenticated AI Consumer.
This example returns the AI Consumer's identity and its AI Consumer Group names in the response.

{% entity_example %}
type: policy
data:
  display_name: "Return AI Consumer details"
  name: return-ai-consumer-details
  type: post-function
  config:
    access:
    - |
      local c = kong.client.get_consumer()
      local g = kong.client.get_consumer_groups()
      local names = {}
      if type(g) == "table" then
        for _, group in ipairs(g) do
          names[#names + 1] = group.name
        end
      end
      return kong.response.exit(200, {
        consumer = c and { id = c.id, username = c.username, custom_id = c.custom_id, tags = c.tags } or "nil",
        groups = names,
      })
formats:
  - kongctl
{% endentity_example %}

### Share a value between AI Policies

`kong.ctx.shared` holds values for the duration of a request.
In this example, a global Pre-Function stores a value and a Post-Function on an AI Model reads it.

{% entity_example %}
type: policy
data:
  display_name: "Store a shared value"
  name: store-shared-value
  type: pre-function
  global: true
  config:
    access:
    - |
      kong.ctx.shared.probe = "from-pre-function"
formats:
  - kongctl
{% endentity_example %}

{% entity_example %}
type: policy
data:
  display_name: "Read the shared value"
  name: read-shared-value
  type: post-function
  config:
    access:
    - |
      return kong.response.exit(200, { probe = kong.ctx.shared.probe or "nil" })
formats:
  - kongctl
{% endentity_example %}

### Rewrite error responses

An Exit Transformer function receives the status code, the body, and the headers, and returns the new values.
This example replaces every response that the Exit Transformer handles with a `418` response that includes the original status code.

{% entity_example %}
type: policy
data:
  display_name: "Rewrite error responses"
  name: rewrite-error-responses
  type: exit-transformer
  global: true
  config:
    functions:
    - |
      return function(status, body, headers)
        return 418, { message = "rewritten", original_status = status }, headers
      end
formats:
  - kongctl
{% endentity_example %}

### Check what strict mode blocks

This Pre-Function reports which operations the sandbox allows.
In strict mode, `resty_http`, `io_open`, `tcp_socket`, and `os_execute` are `false`, and `cjson` is `true`.

{% entity_example %}
type: policy
data:
  display_name: "Check sandbox restrictions"
  name: check-sandbox-restrictions
  type: pre-function
  global: true
  config:
    access:
    - |
      local ok_http = pcall(require, "resty.http")
      local ok_io = pcall(function() return io.open("/etc/passwd") end)
      local ok_tcp = pcall(function() return ngx.socket.tcp() end)
      local ok_os = pcall(function() return os.execute("true") end)
      local ok_cjson = pcall(require, "cjson")
      return kong.response.exit(200, {
        resty_http = ok_http, io_open = ok_io, tcp_socket = ok_tcp, os_execute = ok_os, cjson = ok_cjson,
      })
formats:
  - kongctl
{% endentity_example %}

<!-- TODO: the Lua in these examples ran on 2.2.0 under strict mode as Model-scoped Post-Function, global Pre-Function, and global Exit Transformer AI Policies. The entity_example blocks were not rendered. Only one global Pre-Function took effect when several existed, so use one at a time. -->

## Allowlist changes

{{site.ai_gateway}} can change the sandbox allowlists of environment and modules.
Most changes add entries. If {{site.ai_gateway}} finds a security vulnerability, it can remove entries, and it notifies you of the change.
