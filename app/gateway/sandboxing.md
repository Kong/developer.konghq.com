---
title: "Lua sandboxing"

description: |
  Reference for Lua sandboxing in {{site.base_gateway}}, including available environments and modules for each sandbox mode.
content_type: reference
layout: reference

breadcrumbs:
  - /gateway/
products:
  - gateway
works_on:
  - on-prem

related_resources:
  - text: "Pre-function plugin"
    url: /plugins/pre-function/
  - text: "Post-function plugin"
    url: /plugins/post-function/
  - text: "Exit Transformer plugin"
    url: /plugins/exit-transformer/
  - text: "{{site.base_gateway}} configuration reference"
    url: /gateway/configuration/
---

Sandboxing imposes several limitations on how custom Lua code can be executed,
for heightened security. The Lua (or LuaJIT) language itself is not limited — only the available
environment and the set of usable modules are restricted.

The limitations can be adjusted with the `untrusted_lua` configuration option.

## Disallow custom code execution

If no custom code is needed, disable all custom code execution by setting `untrusted_lua=off`.
This ensures that the {{site.base_gateway}} node will not attempt to load or execute custom code, such as
serverless functions used by the `pre-function` and `post-function` plugins. The downside is
that Lua-based extensibility will not be available.

## Strict mode (the default)

Strict mode is an allowlist-based execution environment, selected by setting
`untrusted_lua=strict`. This is also the default value in current {{site.base_gateway}} releases. In this mode
you can load and execute custom Lua code with some limitations. Most notably,
all file I/O and network I/O functionality is disallowed.

### Environment in strict mode

In `strict` mode you are allowed to use:

#### Standard Constants
```
_VERSION
```

#### Standard Functions
```
assert  error     ipairs    next  pairs   pcall   print
select  tonumber  tostring  type  unpack  xpcall
```

#### Bit Functions
```
bit.arshift  bit.band    bit.bnot  bit.bor  bit.bswap
bit.bxor     bit.lshift  bit.rol   bit.ror  bit.rshift
bit.tobit    bit.tohex
```

#### Coroutine Functions
```
coroutine.create  coroutine.resume  coroutine.running
coroutine.status  coroutine.wrap    coroutine.yield
```

#### IO Functions
```
io.type
```

#### LuaJIT Functions
```
jit.os  jit.arch  jit.version  jit.version_num
```

#### Math Functions
```
math.abs    math.acos   math.asin   math.atan    math.atan2
math.ceil   math.cos    math.cosh   math.deg     math.exp
math.floor  math.fmod   math.frexp  math.huge    math.ldexp
math.log    math.log10  math.max    math.min     math.modf
math.pi     math.pow    math.rad    math.random  math.sin
math.sinh   math.sqrt   math.tan    math.tanh
```

#### OS Functions
```
os.clock  os.date  os.difftime  os.time
```

#### String Functions
```
string.byte    string.char  string.find     string.format
string.gmatch  string.gsub  string.len      string.lower
string.match   string.rep   string.reverse  string.sub
string.upper
```

#### Table Functions
```
table.clear     table.clone  table.concat  table.foreach
table.foreachi  table.getn   table.insert  table.isarray
table.isempty   table.maxn   table.move    table.new
table.nkeys     table.pack   table.remove  table.sort
table.unpack
```

#### Kong Constants
```
kong.version  kong.version_num  kong.default_workspace
```

#### Kong Configuration (secrets redacted)
```
kong.configuration[*]
```

#### Kong Context
```
kong.ctx.shared[*]  kong.ctx.plugin[*]
```

#### Kong Client PDK
```
kong.client.authenticate
kong.client.authenticate_consumer_group_by_consumer_id
kong.client.get_consumer
kong.client.get_consumer_group
kong.client.get_consumer_groups
kong.client.get_credential
kong.client.get_forwarded_ip
kong.client.get_forwarded_port
kong.client.get_ip
kong.client.get_port
kong.client.get_protocol
kong.client.load_consumer
kong.client.set_authenticated_consumer_group
kong.client.set_authenticated_consumer_groups
kong.client.set_token
kong.client.get_token
kong.client.get_jwt_token_header
kong.client.get_jwt_token_payload
```

#### Kong Cluster PDK
```
kong.cluster.get_id
```

#### Kong IP PDK
```
kong.ip.is_trusted
```

#### Kong JWE PDK
```
kong.jwe.decode  kong.jwe.decrypt  kong.jwe.encrypt
```

#### Kong Log PDK
```
kong.log        kong.log.alert    kong.log.crit
kong.log.debug  kong.log.emerg    kong.log.err
kong.log.info   kong.log.inspect  kong.log.notice
kong.log.warn
```

#### Kong Log Serialize PDK
```
kong.log.serialize  kong.log.set_serialize_value
```

#### Kong Log Deprecation PDK
```
kong.log.deprecation  kong.log.deprecation.write
```

#### Kong Nginx PDK
```
kong.nginx.get_subsystem
```

#### Kong Node PDK
```
kong.node.get_hostname  kong.node.get_id
```

#### Kong Plugin PDK
```
kong.plugin.get_id
```

#### Kong Request PDK
```
kong.request.get_body
kong.request.get_forwarded_host
kong.request.get_forwarded_path
kong.request.get_forwarded_port
kong.request.get_forwarded_prefix
kong.request.get_forwarded_scheme
kong.request.get_header
kong.request.get_headers
kong.request.get_host
kong.request.get_http_version
kong.request.get_method
kong.request.get_path
kong.request.get_path_with_query
kong.request.get_port
kong.request.get_query
kong.request.get_query_arg
kong.request.get_raw_body
kong.request.get_raw_headers
kong.request.get_raw_path
kong.request.get_raw_query
kong.request.get_scheme
kong.request.get_start_time
kong.request.get_uri_captures
```

#### Kong Response PDK
```
kong.response.add_header
kong.response.clear_header
kong.response.error
kong.response.exit
kong.response.get_header
kong.response.get_headers
kong.response.get_raw_body
kong.response.get_source
kong.response.get_status
kong.response.set_header
kong.response.set_headers
kong.response.set_raw_body
kong.response.set_status
```

#### Kong Service Request PDK
```
kong.service.request.add_header
kong.service.request.clear_header
kong.service.request.clear_query_arg
kong.service.request.enable_buffering
kong.service.request.set_authentication_headers
kong.service.request.set_body
kong.service.request.set_header
kong.service.request.set_headers
kong.service.request.set_method
kong.service.request.set_path
kong.service.request.set_query
kong.service.request.set_raw_body
kong.service.request.set_raw_query
kong.service.request.set_scheme
```

#### Kong Service Response PDK
```
kong.service.response.get_body
kong.service.response.get_header
kong.service.response.get_headers
kong.service.response.get_raw_body
kong.service.response.get_status
```

#### Kong Table PDK
```
kong.table.clear  kong.table.merge
```

#### Kong Telemetry PDK
```
kong.telemetry.log
```

#### Kong Tracing PDK
```
kong.tracing.active_span
kong.tracing.create_span
kong.tracing.get_probability_sampling_decision
kong.tracing.get_root_span
kong.tracing.get_sampling_decision
kong.tracing.get_spans
kong.tracing.init_spans
kong.tracing.link_span
kong.tracing.process_span
kong.tracing.set_active_span
kong.tracing.set_should_sample
kong.tracing.start_span
```

#### Nginx Constants
```
ngx.AGAIN                     ngx.ALERT
ngx.CRIT                      ngx.DEBUG
ngx.DECLINED                  ngx.DONE
ngx.EMERG                     ngx.ERR
ngx.ERROR                     ngx.HTTP_ACCEPTED
ngx.HTTP_BAD_GATEWAY          ngx.HTTP_BAD_REQUEST
ngx.HTTP_CLOSE                ngx.HTTP_CONFLICT
ngx.HTTP_CONTINUE             ngx.HTTP_COPY
ngx.HTTP_CREATED              ngx.HTTP_DELETE
ngx.HTTP_FORBIDDEN            ngx.HTTP_GATEWAY_TIMEOUT
ngx.HTTP_GET                  ngx.HTTP_GONE
ngx.HTTP_HEAD                 ngx.HTTP_ILLEGAL
ngx.HTTP_INSUFFICIENT_STORAGE ngx.HTTP_INTERNAL_SERVER_ERROR
ngx.HTTP_LOCK                 ngx.HTTP_METHOD_NOT_IMPLEMENTED
ngx.HTTP_MKCOL                ngx.HTTP_MOVE
ngx.HTTP_MOVED_PERMANENTLY    ngx.HTTP_MOVED_TEMPORARILY
ngx.HTTP_NOT_ACCEPTABLE       ngx.HTTP_NOT_ALLOWED
ngx.HTTP_NOT_FOUND            ngx.HTTP_NOT_IMPLEMENTED
ngx.HTTP_NOT_MODIFIED         ngx.HTTP_NO_CONTENT
ngx.HTTP_OK                   ngx.HTTP_OPTIONS
ngx.HTTP_PARTIAL_CONTENT      ngx.HTTP_PATCH
ngx.HTTP_PAYMENT_REQUIRED     ngx.HTTP_PERMANENT_REDIRECT
ngx.HTTP_POST                 ngx.HTTP_PROPFIND
ngx.HTTP_PROPPATCH            ngx.HTTP_PUT
ngx.HTTP_REQUEST_TIMEOUT      ngx.HTTP_SEE_OTHER
ngx.HTTP_SERVICE_UNAVAILABLE  ngx.HTTP_SPECIAL_RESPONSE
ngx.HTTP_SWITCHING_PROTOCOLS  ngx.HTTP_TEMPORARY_REDIRECT
ngx.HTTP_TOO_MANY_REQUESTS    ngx.HTTP_TRACE
ngx.HTTP_UNAUTHORIZED         ngx.HTTP_UNLOCK
ngx.HTTP_UPGRADE_REQUIRED     ngx.HTTP_VERSION_NOT_SUPPORTED
ngx.INFO                      ngx.NOTICE
ngx.OK                        ngx.STDERR
ngx.WARN
```

#### Nginx Config Constants
```
ngx.config.nginx_version  ngx.config.ngx_lua_version
ngx.config.subsystem
```

#### Nginx
```
ngx.arg[*]        ngx.ctx[*]         ngx.var[*]  ngx.header[*]
ngx.headers_sent  ngx.is_subrequest  ngx.status
```

#### Nginx Functions
```
ngx.cookie_time       ngx.crc32_long      ngx.crc32_short
ngx.decode_args       ngx.decode_base64   ngx.encode_args
ngx.encode_base64     ngx.eof             ngx.escape_uri
ngx.exit              ngx.flush           ngx.get_phase
ngx.get_raw_phase     ngx.hmac_sha1       ngx.http_time
ngx.localtime         ngx.log             ngx.md5
ngx.md5_bin           ngx.now             ngx.null
ngx.parse_http_time   ngx.print           ngx.quote_sql_str
ngx.redirect          ngx.say             ngx.send_headers
ngx.sha1_bin          ngx.sleep           ngx.time
ngx.today             ngx.unescape_uri    ngx.update_time
ngx.utctime
```

#### Nginx Regex Functions
```
ngx.re.find  ngx.re.gmatch  ngx.re.gsub  ngx.re.match
ngx.re.sub
```

#### Nginx Request Functions
```
ngx.req.append_body    ngx.req.clear_header
ngx.req.discard_body   ngx.req.finish_body
ngx.req.get_body_data  ngx.req.get_headers
ngx.req.get_method     ngx.req.get_post_args
ngx.req.get_uri_args   ngx.req.http_version
ngx.req.init_body      ngx.req.is_internal
ngx.req.raw_header     ngx.req.read_body
ngx.req.set_body_data  ngx.req.set_header
ngx.req.set_method     ngx.req.set_uri
ngx.req.set_uri_args   ngx.req.socket
ngx.req.start_time
```

#### Nginx Response Functions
```
ngx.resp.get_headers
```

#### Nginx Worker Functions
```
ngx.worker.count  ngx.worker.exiting
ngx.worker.id     ngx.worker.pid
ngx.worker.pids
```

### Available modules in strict mode

You are also allowed to use the standard `require` function to load modules.
In strict mode, the following modules are available:

#### Bit Library
```
bit
```

#### String Buffer Library
```
string.buffer
```

#### Table Libraries
```
table.clear  table.clone  table.isarray  table.isempty
table.new    table.nkeys
```

#### Argon2 Library
```
argon2
```

#### Bcrypt Library
```
bcrypt
```

#### cJSON Libraries
```
cjson  cjson.safe
```

#### LYAML (Lua YAML) Library
```
lyaml
```

#### Kong Constants and Meta Libraries
```
kong.constants kong.meta
```

#### Kong Tools
```
kong.tools.cjson      kong.tools.gzip
kong.tools.ip         kong.tools.jose
kong.tools.json       kong.tools.mime_type
kong.tools.rand       kong.tools.sha1
kong.tools.sha256     kong.tools.string
kong.tools.table      kong.tools.time
kong.tools.timestamp  kong.tools.uri
kong.tools.utils      kong.tools.uuid
kong.tools.yield
```

#### Nginx Libraries
```
ngx.base64  ngx.re  ngx.req  ngx.resp  ngx.semaphore
```

#### Penlight Libraries
```
pl.stringx  pl.tablex
```

#### OpenResty Libraries
```
resty.aes        resty.lock            resty.md5
resty.random     resty.sha             resty.sha1
resty.sha224     resty.sha256          resty.sha384
resty.sha512     resty.string          resty.upload
resty.core.time  resty.lrucache        resty.lrucache.pureffi
resty.ada        resty.ada.search      resty.cookie
resty.ipmatcher  resty.jit-uuid        resty.jwt
resty.evp        resty.jwt-validators  resty.hmac
resty.passwdqc
```

#### OpenSSL Libraries
```
resty.openssl
resty.openssl.asn1
resty.openssl.bn
resty.openssl.cipher
resty.openssl.ctx
resty.openssl.dh
resty.openssl.digest
resty.openssl.ec
resty.openssl.ecx
resty.openssl.err
resty.openssl.hmac
resty.openssl.kdf
resty.openssl.mac
resty.openssl.objects
resty.openssl.param
resty.openssl.pkcs12
resty.openssl.pkey
resty.openssl.provider
resty.openssl.rand
resty.openssl.rsa
resty.openssl.ssl
resty.openssl.ssl_ctx
resty.openssl.ssl_ctx
resty.openssl.stack
resty.openssl.version
resty.openssl.x509
resty.openssl.x509.altname
resty.openssl.x509.chain
resty.openssl.x509.crl
resty.openssl.x509.csr
resty.openssl.x509.name
resty.openssl.x509.revoked
resty.openssl.x509.store
resty.openssl.x509.extension
resty.openssl.x509.extension.dist_points
resty.openssl.x509.extension.info_access
```

#### LuaSocket URL Library
```
socket.url
```

#### Tablepool Library
```
tablepool
```

#### Version Library
```
version
```

#### XMLua Library
```
xmlua
```

## Lax mode

The lax mode extends the strict mode with network I/O, and some other functionality.

### Environment in lax mode

Lax mode includes everything in strict mode, plus the following:

#### Kong Cache PDK
```
kong.cache:get               kong.cache:get_bulk
kong.cache:probe             kong.cache:invalidate
kong.cache:invalidate_local  kong.cache:safe_set
kong.cache:renew
```

#### Kong Client PDK
```
kong.client.get_aws_vpce_id
```

#### Kong Client TLS PDK
```
kong.client.tls.disable_session_reuse
kong.client.tls.get_full_client_certificate_chain
kong.client.tls.request_client_certificate
kong.client.tls.set_client_verify
```

#### Kong Database PDK
```
kong.db.certificates:cache_key
kong.db.certificates:select
kong.db.certificates:select_by_cache_key
kong.db.consumers:cache_key
kong.db.consumers:select
kong.db.consumers:select_by_cache_key
kong.db.consumers:select_by_custom_id
kong.db.consumers:select_by_username
kong.db.consumers:select_by_username_ignore_case
kong.db.keys:cache_key
kong.db.keys:select
kong.db.keys:select_by_cache_key
kong.db.keys:select_by_name
kong.db.plugins:cache_key
kong.db.plugins:select
kong.db.plugins:select_by_cache_key
kong.db.plugins:select_by_instance_name
kong.db.routes:cache_key
kong.db.routes:select
kong.db.routes:select_by_cache_key
kong.db.routes:select_by_name
kong.db.services:cache_key
kong.db.services:select
kong.db.services:select_by_cache_key
kong.db.services:select_by_name
kong.db.snis:cache_key
kong.db.snis:select
kong.db.snis:select_by_cache_key
kong.db.snis:select_by_name
kong.db.targets:cache_key
kong.db.targets:select
kong.db.targets:select_by_cache_key
kong.db.targets:select_by_target
kong.db.upstreams:cache_key
kong.db.upstreams:select
kong.db.upstreams:select_by_cache_key
kong.db.upstreams:select_by_name
```

#### Kong DNS PDK
```
kong.dns.resolve  kong.dns.toip
```

#### Kong Nginx PDK
```
kong.nginx.get_statistics
```

#### Kong Node PDK
```
kong.node.get_memory_stats
```

#### Kong Router PDK
```
kong.router.get_route  kong.router.get_service
```

#### Kong Service PDK
```
kong.service.enable_recording_upstream_ssl
kong.service.set_retries
kong.service.set_target
kong.service.set_target_retry_callback
kong.service.set_timeouts
kong.service.set_tls_cert_key
kong.service.set_tls_verify
kong.service.set_tls_verify_depth
kong.service.set_tls_verify_store
kong.service.set_upstream
```

#### Kong Vault PDK
```
kong.vault.get              kong.vault.is_reference
kong.vault.parse_reference  kong.vault.try
kong.vault.update
```

#### Kong WebSocket PDK
```
kong.websocket.client.close
kong.websocket.client.drop_frame
kong.websocket.client.get_frame
kong.websocket.client.set_frame_data
kong.websocket.client.set_max_payload_size
kong.websocket.client.set_status
```

#### Kong WebSocket Upstream PDK
```
kong.websocket.upstream.close
kong.websocket.upstream.drop_frame
kong.websocket.upstream.get_frame
kong.websocket.upstream.set_frame_data
kong.websocket.upstream.set_max_payload_size
kong.websocket.upstream.set_status
```

#### Nginx Debug Build Constant
```
ngx.config.debug
```

#### Nginx Subrequest Functions
```
ngx.location.capture  ngx.location.capture_multi
```

#### Nginx Request Functions
```
ngx.req.get_body_file  ngx.req.set_body_file
```

#### Nginx Thread Functions
```
ngx.thread.kill ngx.thread.spawn ngx.thread.wait
```

#### Nginx Socket Functions
```
ngx.socket.connect ngx.socket.stream ngx.socket.tcp ngx.socket.udp
```

### Available modules in lax mode

Lax mode includes everything in strict mode, plus the following:

#### {{site.ee_product_name}} Edition Redis Library
```
kong.enterprise_edition.tools.redis.v2
```

#### Kong Concurrency Library
```
kong.concurrency
```

#### Pgmoon Libraries (PostgreSQL driver)
```
pgmoon  pgmoon.arrays  pgmoon.hstore
```

#### Memcached Library
```
resty.memcached
```

#### MySQL Library
```
resty.mysql
```

#### Redis Libraries
```
resty.redis  resty.rediscluster  resty.xmodem
```

#### DNS Resolver Library
```
resty.dns.resolver
```

#### AWS Libraries
```
resty.aws
resty.aws.utils
resty.aws.config
resty.aws.request.validate
resty.aws.request.build
resty.aws.request.sign
resty.aws.request.execute
resty.aws.request.signatures.utils
resty.aws.request.signatures.v4
resty.aws.request.signatures.presign
resty.aws.request.signatures.none
resty.aws.service.rds.signer
resty.aws.credentials.Credentials
resty.aws.credentials.ChainableTemporaryCredentials
resty.aws.credentials.CredentialProviderChain
resty.aws.credentials.EC2MetadataCredentials
resty.aws.credentials.EnvironmentCredentials
resty.aws.credentials.SharedFileCredentials
resty.aws.credentials.RemoteCredentials
resty.aws.credentials.TokenFileWebIdentityCredentials
resty.aws.raw-api.region_config_data
```

#### Azure Libraries
```
resty.azure
resty.azure.config
resty.azure.utils
resty.azure.credentials.Credentials
resty.azure.credentials.ClientCredentials
resty.azure.credentials.WorkloadIdentityCredentials
resty.azure.credentials.ManagedIdentityCredentials
resty.azure.api.keyvault
resty.azure.api.secrets
resty.azure.api.keys
resty.azure.api.certificates
resty.azure.api.auth
resty.azure.api.request.build
resty.azure.api.request.execute
resty.azure.api.response.handle
```

#### GCP Libraries
```
resty.gcp
resty.gcp.request.credentials.accesstoken
resty.gcp.request.discovery
```

#### HTTP Request Libraries
```
resty.http resty.http_connect resty.http_headers
```

#### jQ Library
```
resty.jq
```

#### Session Library
```
resty.session
```

## Sandbox mode (deprecated)

Sandbox mode is deprecated and may be removed in a future release. Sandbox mode allows (almost)
full access to {{site.base_gateway}} PDK (`kong.*`) and Nginx functions (`ngx.*`). It has somewhat limited access
to standard Lua environment (see the strict mode Lua related environment). This is useful when
upgrading from older {{site.base_gateway}} versions that used the sandbox mode, and thus is backward compatible.

In sandbox mode you are not allowed to use the `require` function to load modules, unless you are
also using `untrusted_lua_sandbox_requires` and listing the allowed modules there.

## Unrestricted mode

It is also possible to run {{site.base_gateway}} in unrestricted mode by setting the `untrusted_lua`
configuration option to `on`. In this mode the access to environment or available modules
is completely unrestricted, and no protections are applied.

## Notes

{{site.base_gateway}} keeps rights to modify the above mentioned allow-lists of environment and modules. Most commonly,
{{site.base_gateway}} will do additions to the allow-lists, but in case a security vulnerability is found, {{site.base_gateway}} may
remove some. In such case, {{site.base_gateway}} will notify the user about the change.
