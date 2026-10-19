---
title: "Lua sandboxing in {{site.ai_gateway}}"
content_type: reference
layout: reference

description: "Reference for Lua sandboxing in {{site.ai_gateway}}, including the available sandbox modes, how to set them, and how sandboxed code interacts with AI entities."

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

Some {{site.ai_gateway}} [AI Policies](/ai-gateway/entities/ai-policy/) let you run Lua code to change requests and responses, read the authenticated [AI Consumer](/ai-gateway/entities/ai-consumer/), or share values between AI Policies.
Anyone who can create or edit one of these AI Policies can run code on your data planes, so sandboxing limits what that code can do.
Sandboxing restricts the available environment and the set of modules that the code can load.
All Lua (or LuaJIT) language features remain available.

The [`untrusted_lua`](/ai-gateway/configuration/#untrusted-lua) data plane setting controls which restrictions apply.
Each data plane node reads this setting from its own [`kong.conf`](/ai-gateway/configuration/) file.
The setting applies to every AI Policy on that node.

## What the sandbox applies to

The following AI Policies run Lua code that you provide in their configuration:

<!--vale off-->
{% table %}
columns:
  - title: AI Policy
    key: policy
  - title: Runs
    key: runs
  - title: What you can do with it
    key: use
rows:
  - policy: "[Pre-Function](/ai-gateway/policies/pre-function/)"
    runs: "Before the other AI Policies in each phase, and before authentication."
    use: |
      Change a request or answer it early.
      For example, add a header to the request that {{site.ai_gateway}} sends to the upstream.
  - policy: "[Post-Function](/ai-gateway/policies/post-function/)"
    runs: "After the other AI Policies in each phase, and after authentication."
    use: |
      Read the authenticated Consumer, or change a response.
      For example, add or remove response headers.
  - policy: "[Exit Transformer](/ai-gateway/policies/exit-transformer/)"
    runs: "When an AI Policy or {{site.ai_gateway}} returns a response early."
    use: |
      Rewrite the status code, body, and headers of that response, such as the `401` from authentication.
      The Exit Transformer rewrites a response that reports no matching Route only when [`handle_unknown`](/ai-gateway/policies/exit-transformer/reference/#schema--config-handle-unknown) is `true`.
{% endtable %}
<!--vale on-->

Other AI Policies also use the sandbox when their configuration contains Lua expressions, functions, or templates:

* **Templates, expressions, and functions**: [AI Custom Guardrail](/ai-gateway/policies/ai-custom-guardrail/), [Request Transformer](/ai-gateway/policies/request-transformer/), [Route Transformer Advanced](/ai-gateway/policies/route-transformer-advanced/), [Response Transformer Advanced](/ai-gateway/policies/response-transformer-advanced/), and [Request Callout](/ai-gateway/policies/request-callout/).
* **Custom log fields**: logging AI Policies such as [File Log](/ai-gateway/policies/file-log/) and [OpenTelemetry](/ai-gateway/policies/opentelemetry/).
* **Message functions**: messaging AI Policies such as [Confluent](/ai-gateway/policies/confluent/), [Confluent Consume](/ai-gateway/policies/confluent-consume/), and [Kafka Consume](/ai-gateway/policies/kafka-consume/).

{{site.ai_gateway}} also generates a Pre-Function for each [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) of type `conversion-only`.
A `conversion-only` server exposes its tools only through the `listener` AI MCP Servers that name it in `config.sources`.
The generated Pre-Function returns a `404` to any request that doesn't arrive through the internal connection that the listener uses.
You don't create this Pre-Function, and it runs in the sandbox like any other Pre-Function.
If you set `untrusted_lua` to `off`, it can't run, and tool calls through the listener fail.
See [Disable custom code execution](#disable-custom-code-execution).

## Sandbox modes

The `untrusted_lua` setting accepts the following sandbox modes:

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
      Disallows all custom Lua code.
      A data plane node doesn't load or run code from any AI Policy that depends on the sandbox.
      See [Disable custom code execution](#disable-custom-code-execution).
  - mode: "`strict`"
    description: |
      The default.
      An allowlist-based environment with limited access to the Lua standard library, the [Kong PDK](/gateway/pdk/reference/), and Nginx APIs.
      All file I/O and network I/O is disallowed.
      See [Strict mode](#strict-mode).
  - mode: "`lax`"
    description: |
      Extends `strict` with network I/O, vault access, cache access, and read-only access to configuration.
      See [Lax mode](#lax-mode).
  - mode: "`sandbox`"
    description: |
      Deprecated.
      Gives nearly full access to the Kong PDK and Nginx APIs with limited access to the standard Lua environment.
      You can extend it with `untrusted_lua_sandbox_requires` and `untrusted_lua_sandbox_environment`.
  - mode: "`on`"
    description: |
      Unrestricted.
      Code has complete access to the environment and to all modules, and no protections apply.
{% endtable %}
<!--vale on-->

{:.warning}
> LuaJIT is not a secure sandbox for running malicious code.
>
> The sandbox prevents trivial attacks and accidental changes to global state.
>
> Use access controls alongside the sandbox, because it does not replace them.
>
> Anyone who can create or edit an AI Policy that runs custom Lua can execute code on your data planes, so limit who can create these AI Policies.

## Choose a sandbox mode

We recommend `strict`, the default, because it blocks file I/O and network I/O, so custom Lua code can't read files or call external services.
Choose another mode only when you need what it provides:

* **`lax`**: Use it when the Lua code in an AI Policy has to make network calls or use vaults, the cache, or read-only configuration.
  Lax mode adds all of these to strict mode.
* **`off`**: Use it when your organization doesn't allow custom Lua code.
  Setting `off` also stops the AI Policies that depend on the sandbox, and some of them make the data plane reject the entire configuration.
  Check the table in [Disable custom code execution](#disable-custom-code-execution) before you set it.
* **`sandbox` and `on`**: We don't recommend either.
  The `sandbox` mode is deprecated, and `on` removes all restrictions.

## Set the sandbox mode

{{site.ai_gateway}} data planes are self-managed, and the {{site.konnect_short_name}} control plane has no setting for `untrusted_lua`.
Set the parameter on each data plane node, in its `kong.conf` file or with the equivalent environment variable:

```sh
KONG_UNTRUSTED_LUA=strict
```

The value applies to one node, so set the same value on every data plane node.
See [`untrusted_lua`](/ai-gateway/configuration/#untrusted-lua) in the {{site.ai_gateway}} configuration reference.

The [`untrusted_lua_sandbox_requires`](/ai-gateway/configuration/#untrusted-lua-sandbox-requires) and [`untrusted_lua_sandbox_environment`](/ai-gateway/configuration/#untrusted-lua-sandbox-environment) parameters apply only in `sandbox` mode.
Other modes ignore both parameters.

## Disable custom code execution

If you don't need custom Lua code, set `untrusted_lua=off`.
The data plane node still starts and runs AI Policies that don't use the sandbox.
What happens to an AI Policy with custom Lua depends on when {{site.ai_gateway}} checks its code:

* **At request time**: The AI Policy syncs normally, and a request that triggers it fails.
  The data plane logs `loading of untrusted Lua code disabled because 'untrusted_lua' config option is set to 'off'`.
* **When the data plane loads the configuration**: The data plane rejects the entire configuration and logs `Error parsing function: loading of untrusted Lua code disabled because 'untrusted_lua' config option is set to 'off'`.
  The node then applies no configuration changes until you remove the AI Policy.

Before you set `off`, check which of your AI Policies depend on the sandbox:

<!--vale off-->
{% table %}
columns:
  - title: AI Policy
    key: policy
  - title: Lua code in
    key: field
  - title: Effect with `untrusted_lua=off`
    key: effect
rows:
  - policy: "[Pre-Function](/ai-gateway/policies/pre-function/) and [Post-Function](/ai-gateway/policies/post-function/)"
    field: "The [phase](/gateway/entities/plugin/#plugin-contexts) fields, such as `config.access`"
    effect: "Requests that trigger the AI Policy fail."
  - policy: "[AI Custom Guardrail](/ai-gateway/policies/ai-custom-guardrail/)"
    field: "`$(...)` templates in `config.request` and `config.response`"
    effect: |
      Every request that triggers the AI Policy fails, even when the configuration has no `$(...)` expression.
  - policy: "[Request Transformer](/ai-gateway/policies/request-transformer/)"
    field: "`$(...)` templates, such as in `config.add.headers`"
    effect: "Requests that trigger the AI Policy fail."
  - policy: "[Exit Transformer](/ai-gateway/policies/exit-transformer/)"
    field: "[`functions`](/ai-gateway/policies/exit-transformer/reference/#schema--config-functions)"
    effect: "The data plane rejects the entire configuration."
  - policy: "[Response Transformer Advanced](/ai-gateway/policies/response-transformer-advanced/)"
    field: "`transform.functions`"
    effect: "The data plane rejects the entire configuration."
  - policy: "[File Log](/ai-gateway/policies/file-log/), [HTTP Log](/ai-gateway/policies/http-log/), [Loggly](/ai-gateway/policies/loggly/), [Syslog](/ai-gateway/policies/syslog/), [TCP Log](/ai-gateway/policies/tcp-log/), and [UDP Log](/ai-gateway/policies/udp-log/)"
    field: "[`custom_fields_by_lua`](/ai-gateway/policies/file-log/reference/#schema--config-custom-fields-by-lua)"
    effect: "The data plane rejects the entire configuration."
  - policy: "[OpenTelemetry](/ai-gateway/policies/opentelemetry/)"
    field: "`access_logs.custom_attributes_by_lua`"
    effect: "The data plane rejects the entire configuration."
  - policy: "[Confluent](/ai-gateway/policies/confluent/), [Confluent Consume](/ai-gateway/policies/confluent-consume/), and [Kafka Consume](/ai-gateway/policies/kafka-consume/)"
    field: "`message_by_lua_functions`"
    effect: "The data plane rejects the entire configuration."
{% endtable %}
<!--vale on-->

`off` also affects the Pre-Function that {{site.ai_gateway}} generates for each `conversion-only` AI MCP Server, as described in the following paragraphs.

With `untrusted_lua=off`, tool calls through a `listener` AI MCP Server that aggregates a `conversion-only` server fail with `request failed: closed`, because the generated Pre-Function can't run.
A direct request to the `conversion-only` server's route returns an empty reply instead of a `404`.
The `listener` itself still answers MCP requests such as `initialize`.

An AI Custom Guardrail fails on every request, even when its configuration uses a plain string for `request.url` and no `$(...)` expression.
The request returns a `500` error with the message `failed to sanitize request: failed to invoke custom guardrail service: failed to render url: failed to render by template: loading of untrusted Lua code disabled because 'untrusted_lua' config option is set to 'off'`.

Because the sandbox applies per data plane node, a configuration that works on one node can fail on a node where `untrusted_lua` is `off`.

## Strict mode

Strict mode is an allowlist-based execution environment and is the default.
You can load and run custom Lua code with some limitations.
Most notably, strict mode disallows all file I/O and network I/O.

For example, in strict mode:

* `require("resty.http")` fails with `require("resty.http") not allowed within sandbox`.
* `io.open`, `os.execute`, and `ngx.socket.tcp` aren't available.
* `require("cjson")` works.

The following lists show what strict mode allows.
They differ from the {{site.base_gateway}} sandboxing reference as described in [Differences in the allowlists](#differences-in-the-allowlists).

### Environment in strict mode

In strict mode you can use:

#### Standard constants and functions

```text
_VERSION  assert  error   ipairs  next
pairs     pcall   print   select  tonumber
tostring  type    unpack  xpcall
```
{:.no-copy-code}

#### Bit functions

```text
bit.arshift  bit.band    bit.bnot  bit.bor  bit.bswap
bit.bxor     bit.lshift  bit.rol   bit.ror  bit.rshift
bit.tobit    bit.tohex
```
{:.no-copy-code}

#### Coroutine functions

```text
coroutine.create  coroutine.resume  coroutine.running  coroutine.status
coroutine.wrap    coroutine.yield
```
{:.no-copy-code}

#### IO functions

```text
io.type
```
{:.no-copy-code}

#### LuaJIT functions

```text
jit.os  jit.arch  jit.version  jit.version_num
```
{:.no-copy-code}

#### Math functions

```text
math.abs    math.acos   math.asin   math.atan    math.atan2
math.ceil   math.cos    math.cosh   math.deg     math.exp
math.floor  math.fmod   math.frexp  math.huge    math.ldexp
math.log    math.log10  math.max    math.min     math.modf
math.pi     math.pow    math.rad    math.random  math.sin
math.sinh   math.sqrt   math.tan    math.tanh
```
{:.no-copy-code}

#### OS functions

```text
os.clock  os.date  os.difftime  os.time
```
{:.no-copy-code}

#### String functions

```text
string.byte     string.char  string.find   string.format  string.gmatch
string.gsub     string.len   string.lower  string.match   string.rep
string.reverse  string.sub   string.upper
```
{:.no-copy-code}

#### Table functions

```text
table.clear  table.clone   table.concat   table.foreach  table.foreachi
table.getn   table.insert  table.isarray  table.isempty  table.maxn
table.move   table.new     table.nkeys    table.pack     table.remove
table.sort   table.unpack
```
{:.no-copy-code}

#### Kong constants

```text
kong.default_workspace  kong.version  kong.version_num
```
{:.no-copy-code}

#### Kong context

```text
kong.ctx.shared[*]  kong.ctx.plugin[*]
```
{:.no-copy-code}

#### Kong client PDK

```text
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
{:.no-copy-code}

#### Kong cluster PDK

```text
kong.cluster.get_id
```
{:.no-copy-code}

#### Kong IP PDK

```text
kong.ip.is_trusted
```
{:.no-copy-code}

#### Kong JWE PDK

```text
kong.jwe.decode  kong.jwe.decrypt  kong.jwe.encrypt
```
{:.no-copy-code}

#### Kong log PDK

```text
kong.log              kong.log.alert              kong.log.crit
kong.log.debug        kong.log.emerg              kong.log.err
kong.log.info         kong.log.inspect            kong.log.notice
kong.log.warn         kong.log.serialize          kong.log.set_serialize_value
kong.log.deprecation  kong.log.deprecation.write
```
{:.no-copy-code}

#### Kong Nginx PDK

```text
kong.nginx.get_subsystem
```
{:.no-copy-code}

#### Kong node PDK

```text
kong.node.get_hostname  kong.node.get_id
```
{:.no-copy-code}

#### Kong plugin PDK

```text
kong.plugin.get_id
```
{:.no-copy-code}

#### Kong request PDK

```text
kong.request.get_body              kong.request.get_forwarded_host
kong.request.get_forwarded_path    kong.request.get_forwarded_port
kong.request.get_forwarded_prefix  kong.request.get_forwarded_scheme
kong.request.get_header            kong.request.get_headers
kong.request.get_host              kong.request.get_http_version
kong.request.get_method            kong.request.get_path
kong.request.get_path_with_query   kong.request.get_port
kong.request.get_query             kong.request.get_query_arg
kong.request.get_raw_body          kong.request.get_raw_path
kong.request.get_raw_query         kong.request.get_scheme
kong.request.get_start_time        kong.request.get_uri_captures
```
{:.no-copy-code}

#### Kong response PDK

```text
kong.response.add_header    kong.response.clear_header
kong.response.error         kong.response.exit
kong.response.get_header    kong.response.get_headers
kong.response.get_raw_body  kong.response.get_source
kong.response.get_status    kong.response.set_header
kong.response.set_headers   kong.response.set_raw_body
kong.response.set_status
```
{:.no-copy-code}

#### Kong service request PDK

```text
kong.service.request.add_header
kong.service.request.clear_header
kong.service.request.clear_query_arg
kong.service.request.enable_buffering
kong.service.request.set_authentication_header
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
{:.no-copy-code}

#### Kong service response PDK

```text
kong.service.response.get_body     kong.service.response.get_header
kong.service.response.get_headers  kong.service.response.get_raw_body
kong.service.response.get_status
```
{:.no-copy-code}

#### Kong table PDK

```text
kong.table.clear  kong.table.merge
```
{:.no-copy-code}

#### Kong telemetry PDK

```text
kong.telemetry.log
```
{:.no-copy-code}

#### Kong tracing PDK

```text
kong.tracing.active_span                        kong.tracing.create_span
kong.tracing.get_probability_sampling_decision  kong.tracing.get_root_span
kong.tracing.get_sampling_decision              kong.tracing.get_spans
kong.tracing.init_spans                         kong.tracing.link_span
kong.tracing.process_span                       kong.tracing.set_active_span
kong.tracing.set_should_sample                  kong.tracing.start_span
```
{:.no-copy-code}

#### Kong metrics PDK

```text
kong.metrics.counter     kong.metrics.gauge  kong.metrics.histogram
kong.metrics.VALUE_TYPE
```
{:.no-copy-code}

#### Nginx constants

```text
ngx.AGAIN                      ngx.ALERT
ngx.CRIT                       ngx.DEBUG
ngx.DECLINED                   ngx.DONE
ngx.EMERG                      ngx.ERR
ngx.ERROR                      ngx.HTTP_ACCEPTED
ngx.HTTP_BAD_GATEWAY           ngx.HTTP_BAD_REQUEST
ngx.HTTP_CLOSE                 ngx.HTTP_CONFLICT
ngx.HTTP_CONTINUE              ngx.HTTP_COPY
ngx.HTTP_CREATED               ngx.HTTP_DELETE
ngx.HTTP_FORBIDDEN             ngx.HTTP_GATEWAY_TIMEOUT
ngx.HTTP_GET                   ngx.HTTP_GONE
ngx.HTTP_HEAD                  ngx.HTTP_ILLEGAL
ngx.HTTP_INSUFFICIENT_STORAGE  ngx.HTTP_INTERNAL_SERVER_ERROR
ngx.HTTP_LOCK                  ngx.HTTP_METHOD_NOT_IMPLEMENTED
ngx.HTTP_MKCOL                 ngx.HTTP_MOVE
ngx.HTTP_MOVED_PERMANENTLY     ngx.HTTP_MOVED_TEMPORARILY
ngx.HTTP_NOT_ACCEPTABLE        ngx.HTTP_NOT_ALLOWED
ngx.HTTP_NOT_FOUND             ngx.HTTP_NOT_IMPLEMENTED
ngx.HTTP_NOT_MODIFIED          ngx.HTTP_NO_CONTENT
ngx.HTTP_OK                    ngx.HTTP_OPTIONS
ngx.HTTP_PARTIAL_CONTENT       ngx.HTTP_PATCH
ngx.HTTP_PAYMENT_REQUIRED      ngx.HTTP_PERMANENT_REDIRECT
ngx.HTTP_POST                  ngx.HTTP_PROPFIND
ngx.HTTP_PROPPATCH             ngx.HTTP_PUT
ngx.HTTP_REQUEST_TIMEOUT       ngx.HTTP_SEE_OTHER
ngx.HTTP_SERVICE_UNAVAILABLE   ngx.HTTP_SPECIAL_RESPONSE
ngx.HTTP_SWITCHING_PROTOCOLS   ngx.HTTP_TEMPORARY_REDIRECT
ngx.HTTP_TOO_MANY_REQUESTS     ngx.HTTP_TRACE
ngx.HTTP_UNAUTHORIZED          ngx.HTTP_UNLOCK
ngx.HTTP_UPGRADE_REQUIRED      ngx.HTTP_VERSION_NOT_SUPPORTED
ngx.INFO                       ngx.NOTICE
ngx.OK                         ngx.STDERR
ngx.WARN
```
{:.no-copy-code}

#### Nginx config constants

```text
ngx.config.nginx_version  ngx.config.ngx_lua_version  ngx.config.subsystem
```
{:.no-copy-code}

#### Nginx fields

```text
ngx.arg[*]         ngx.ctx[*]  ngx.var[*]  ngx.header[*]  ngx.headers_sent
ngx.is_subrequest  ngx.status
```
{:.no-copy-code}

#### Nginx functions

```text
ngx.cookie_time    ngx.crc32_long       ngx.crc32_short    ngx.decode_args
ngx.decode_base64  ngx.encode_args      ngx.encode_base64  ngx.eof
ngx.escape_uri     ngx.exit             ngx.flush          ngx.get_phase
ngx.get_raw_phase  ngx.hmac_sha1        ngx.http_time      ngx.localtime
ngx.log            ngx.md5              ngx.md5_bin        ngx.now
ngx.null           ngx.parse_http_time  ngx.print          ngx.quote_sql_str
ngx.redirect       ngx.say              ngx.send_headers   ngx.sha1_bin
ngx.sleep          ngx.time             ngx.today          ngx.unescape_uri
ngx.update_time    ngx.utctime
```
{:.no-copy-code}

#### Nginx regex functions

```text
ngx.re.find  ngx.re.gmatch  ngx.re.gsub  ngx.re.match  ngx.re.sub
```
{:.no-copy-code}

#### Nginx request functions

```text
ngx.req.append_body   ngx.req.clear_header   ngx.req.discard_body
ngx.req.finish_body   ngx.req.get_body_data  ngx.req.get_headers
ngx.req.get_method    ngx.req.get_post_args  ngx.req.get_uri_args
ngx.req.http_version  ngx.req.init_body      ngx.req.is_internal
ngx.req.raw_header    ngx.req.read_body      ngx.req.set_body_data
ngx.req.set_header    ngx.req.set_method     ngx.req.set_uri
ngx.req.set_uri_args  ngx.req.socket         ngx.req.start_time
```
{:.no-copy-code}

#### Nginx response functions

```text
ngx.resp.get_headers
```
{:.no-copy-code}

#### Nginx worker functions

```text
ngx.worker.count  ngx.worker.exiting  ngx.worker.id  ngx.worker.pid
ngx.worker.pids
```
{:.no-copy-code}

### Available modules in strict mode

You can use the standard `require` function to load the following modules in strict mode:

#### Lua and LuaJIT libraries

```text
bit            string.buffer  table.clear  table.clone  table.isarray
table.isempty  table.new      table.nkeys
```
{:.no-copy-code}

#### Argon2 library

```text
argon2
```
{:.no-copy-code}

#### Bcrypt library

```text
bcrypt
```
{:.no-copy-code}

#### cJSON libraries

```text
cjson  cjson.safe
```
{:.no-copy-code}

#### LYAML library

```text
lyaml
```
{:.no-copy-code}

#### Kong constants and meta libraries

```text
kong.constants  kong.meta
```
{:.no-copy-code}

#### Kong tools

```text
kong.tools.cjson      kong.tools.gzip       kong.tools.ip     kong.tools.jose
kong.tools.json       kong.tools.mime_type  kong.tools.rand   kong.tools.sha1
kong.tools.sha256     kong.tools.string     kong.tools.table  kong.tools.time
kong.tools.timestamp  kong.tools.uri        kong.tools.utils  kong.tools.uuid
kong.tools.yield
```
{:.no-copy-code}

#### Nginx libraries

```text
ngx.base64  ngx.re  ngx.req  ngx.resp  ngx.semaphore
```
{:.no-copy-code}

#### Penlight libraries

```text
pl.stringx  pl.tablex
```
{:.no-copy-code}

#### OpenResty libraries

```text
resty.aes         resty.lock      resty.md5               resty.random
resty.sha         resty.sha1      resty.sha224            resty.sha256
resty.sha384      resty.sha512    resty.string            resty.upload
resty.core.time   resty.lrucache  resty.lrucache.pureffi  resty.ada
resty.ada.search  resty.cookie    resty.ipmatcher         resty.jit-uuid
resty.jwt         resty.evp       resty.jwt-validators    resty.hmac
resty.passwdqc
```
{:.no-copy-code}

#### OpenSSL libraries

```text
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
{:.no-copy-code}

#### LuaSocket URL library

```text
socket.url
```
{:.no-copy-code}

#### Tablepool library

```text
tablepool
```
{:.no-copy-code}

#### Version library

```text
version
```
{:.no-copy-code}

#### XMLua library

```text
xmlua
```
{:.no-copy-code}

## Lax mode

Lax mode includes everything in strict mode, plus network I/O and some other functionality.
It also adds `kong.router.get_route`, `kong.router.get_service`, and `kong.configuration`.

### Environment in lax mode

Lax mode adds the following to the strict mode environment:

#### Kong cache PDK

```text
kong.cache:get         kong.cache:get_bulk          kong.cache:probe
kong.cache:invalidate  kong.cache:invalidate_local  kong.cache:safe_set
kong.cache:renew
```
{:.no-copy-code}

#### Kong client PDK (lax mode)

```text
kong.client.get_aws_vpce_id
```
{:.no-copy-code}

#### Kong client TLS PDK

```text
kong.client.tls.disable_session_reuse
kong.client.tls.get_full_client_certificate_chain
kong.client.tls.request_client_certificate
kong.client.tls.set_client_verify
```
{:.no-copy-code}

#### Kong DB PDK

```text
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
{:.no-copy-code}

#### Kong DNS PDK

```text
kong.dns.resolve  kong.dns.toip
```
{:.no-copy-code}

#### Kong Nginx PDK (lax mode)

```text
kong.nginx.get_statistics
```
{:.no-copy-code}

#### Kong node PDK (lax mode)

```text
kong.node.get_memory_stats
```
{:.no-copy-code}

#### Kong router PDK

```text
kong.router.get_route  kong.router.get_service
```
{:.no-copy-code}

#### Kong service PDK

```text
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
{:.no-copy-code}

#### Kong vault PDK

```text
kong.vault.get  kong.vault.is_reference  kong.vault.parse_reference
kong.vault.try  kong.vault.update
```
{:.no-copy-code}

#### Kong WebSocket client PDK

```text
kong.websocket.client.close
kong.websocket.client.drop_frame
kong.websocket.client.get_frame
kong.websocket.client.set_frame_data
kong.websocket.client.set_max_payload_size
kong.websocket.client.set_status
```
{:.no-copy-code}

#### Kong WebSocket upstream PDK

```text
kong.websocket.upstream.close
kong.websocket.upstream.drop_frame
kong.websocket.upstream.get_frame
kong.websocket.upstream.set_frame_data
kong.websocket.upstream.set_max_payload_size
kong.websocket.upstream.set_status
```
{:.no-copy-code}

#### Nginx debug build constant

```text
ngx.config.debug
```
{:.no-copy-code}

#### Nginx subrequest functions

```text
ngx.location.capture  ngx.location.capture_multi
```
{:.no-copy-code}

#### Nginx request functions (lax mode)

```text
ngx.req.get_body_file  ngx.req.set_body_file
```
{:.no-copy-code}

#### Nginx thread functions

```text
ngx.thread.kill  ngx.thread.spawn  ngx.thread.wait
```
{:.no-copy-code}

#### Nginx socket functions

```text
ngx.socket.connect  ngx.socket.stream  ngx.socket.tcp  ngx.socket.udp
```
{:.no-copy-code}

#### Kong configuration (secrets redacted)

```text
kong.configuration[*]
```
{:.no-copy-code}

### Available modules in lax mode

Lax mode adds the following modules to the strict mode modules:

#### Redis libraries

```text
kong.enterprise_edition.tools.redis.v2  resty.redis  resty.rediscluster
resty.xmodem
```
{:.no-copy-code}

#### Kong concurrency library

```text
kong.concurrency
```
{:.no-copy-code}

#### PostgreSQL libraries

```text
pgmoon  pgmoon.arrays  pgmoon.hstore
```
{:.no-copy-code}

#### Memcached library

```text
resty.memcached
```
{:.no-copy-code}

#### MySQL library

```text
resty.mysql
```
{:.no-copy-code}

#### DNS resolver library

```text
resty.dns.resolver
```
{:.no-copy-code}

#### AWS libraries

```text
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
{:.no-copy-code}

#### Azure libraries

```text
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
{:.no-copy-code}

#### GCP libraries

```text
resty.gcp                    resty.gcp.request.credentials.accesstoken
resty.gcp.request.discovery
```
{:.no-copy-code}

#### HTTP request libraries

```text
resty.http  resty.http_connect  resty.http_headers
```
{:.no-copy-code}

#### jq library

```text
resty.jq
```
{:.no-copy-code}

#### Session library

```text
resty.session
```
{:.no-copy-code}

## Differences from {{site.base_gateway}}

The sandbox is the same one that {{site.base_gateway}} uses, but {{site.ai_gateway}} generates the resources that your code runs against.
If you already use sandboxed Lua in {{site.base_gateway}}, the following differences apply to AI Policies.

### Differences in the allowlists

The {{site.base_gateway}} sandboxing reference lists the following as available in strict mode, but they aren't available in {{site.ai_gateway}} 2.2:

* `kong.router.get_route` and `kong.router.get_service`:
  In {{site.ai_gateway}}, `kong.router` is `nil` in strict mode and available only in lax mode.
* `kong.configuration`:
  It is `nil` in strict mode and available in lax mode.
* `kong.client.get_principal`, `kong.client.get_identity_realm_source`, and `kong.client.set_identity_realm_source`:
  All three are `nil` in strict mode.
* `kong.request.get_id` and `kong.request.get_raw_forwarded_path`:
  Both are `nil` in strict mode.
* `kong.table.new`:
  It is `nil` in strict mode.
  The standard `table.new` function is available.

{{site.ai_gateway}} saves an AI Policy that calls one of these functions in strict mode without an error, and the call fails when a request runs it.

To read the {{site.identity}} [Principal](/identity/principals/) of a request, use a [condition](/ai-gateway/conditions/) with the `principal.id` field instead.

### Generated Routes and Services

{{site.ai_gateway}} [generates Routes and Services](/ai-gateway/configure-on-prem/#how-entities-translate-to-kong-gateway-configuration) from your AI entities.
In lax mode, PDK calls that return a Route or a Service, such as `kong.router.get_route` and `kong.router.get_service`, return those generated resources, not your [AI Model](/ai-gateway/entities/ai-model/), [AI Agent](/ai-gateway/entities/ai-agent/), or [AI MCP Server](/ai-gateway/entities/ai-mcp-server/).
The same applies to `kong.db.routes`, `kong.db.services`, and the `kong.service.set_*` calls.
In strict mode, `kong.router` isn't available, as described in [Differences in the allowlists](#differences-in-the-allowlists).

The generated names depend on the type of entity:

* **AI Model**: `kong.router.get_route` returns a Route named for the provider endpoint, such as `openai-chat`, and `kong.router.get_service` returns a Service named `ai-gateway`.
  AI Models that resolve to the same provider endpoint share one Route, so the Route name doesn't identify a single AI Model.
* **AI Agent and AI MCP Server**: `kong.router.get_service` returns a Service with the same name as the entity.
  `kong.router.get_route` returns a Route with the entity name followed by `-route`, such as `my-agent` and `my-agent-route`.

The generated Routes and Services have no tags.

### Consumers

An [AI Consumer](/ai-gateway/entities/ai-consumer/) becomes a {{site.base_gateway}} Consumer with the AI Consumer's name as its `username`.
For an authenticated AI Consumer, `kong.client.get_consumer` returns a table with `id` and `username`.
The table includes [`custom_id`](/ai-gateway/entities/ai-consumer/#schema-aigateway-consumer-custom-id) and `tags` when the AI Consumer sets them.
The `tags` list contains the AI Consumer's labels as `key:value` strings.
`kong.client.get_consumer_groups` returns a table of the [AI Consumer Groups](/ai-gateway/entities/ai-consumer-group/) that the AI Consumer belongs to, and each entry has a `name`.
It returns `nil` when the AI Consumer has no groups.

An `oauth` AI Consumer behaves the same way.
{{site.ai_gateway}} matches the token claim in [`config.consumer_claims`](/ai-gateway/entities/ai-auth-strategy/#schema-aigateway-auth-strategy-open-idconnect-config-config-consumer-claims) to the AI Consumer's `custom_id`.
`kong.client.get_consumer` then returns that AI Consumer's `id`, `username`, `custom_id`, and `tags`.

When you enable {{site.identity}} Principal mapping ([`config.principals`](/ai-gateway/entities/ai-auth-strategy/#schema-aigateway-auth-strategy-open-idconnect-config-config-principals)) on an `openid-connect` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/), set [`config.consumer_optional`](/ai-gateway/entities/ai-auth-strategy/#schema-aigateway-auth-strategy-open-idconnect-config-config-consumer-optional) to `true` if the Principal has no linked AI Consumer.
Otherwise, {{site.ai_gateway}} rejects the request with a `401`, even when the Principal matches.
When the Principal has no linked AI Consumer, `kong.client.get_consumer` returns `nil`.

A [Pre-Function](/ai-gateway/policies/pre-function/) runs before authentication, so `kong.client.get_consumer` returns `nil` there.
A [Post-Function](/ai-gateway/policies/post-function/) runs after authentication, so use a Post-Function to read the Consumer.
A request without a valid key fails authentication, and the AI Policy doesn't run.

### Shared state

The AI Policies that run during a request share the `kong.ctx.shared` table.
A global Pre-Function can write a value that a Post-Function scoped to an AI Model reads in the same request.

### AI Policy configuration

The {{site.ai_gateway}} Pre-Function and Post-Function AI Policies accept only a field for each [phase](/gateway/entities/plugin/#plugin-contexts):

* `certificate`
* `rewrite`
* `access`
* `header_filter`
* `body_filter`
* `log`
* `ws_handshake`
* `ws_client_frame`
* `ws_upstream_frame`
* `ws_close`

The last four fields run in the WebSocket phases.
The Pre-Function and Post-Function AI Policies don't accept the deprecated `config.functions` field from the {{site.base_gateway}} Pre-Function plugin.
The [Exit Transformer](/ai-gateway/policies/exit-transformer/) AI Policy takes its code in `config.functions`, a list of functions.

You can apply Pre-Function and Post-Function AI Policies to an AI Model, AI MCP Server, AI Agent, or globally.
You can't apply them to an AI Consumer or an AI Consumer Group.
You can't apply an Exit Transformer AI Policy to an AI Consumer Group.
See [AI Policy scopes](/ai-gateway/entities/ai-policy/#ai-policy-scopes).

{:.warning}
> {{site.konnect_short_name}} accepts a Pre-Function or Post-Function AI Policy attached to an AI Consumer or an AI Consumer Group, but the data plane rejects the configuration with `in 'consumer': value must be null` or `in 'consumer_group': value must be null`.
> The data plane then applies no further configuration changes until you remove the AI Policy from the AI Consumer or AI Consumer Group.

An AI Policy scoped to an AI Model runs only when the `model` field of the request body names that AI Model.
A request that names a different model, such as the provider's own model name, doesn't run the AI Policy.

If several global Pre-Function AI Policies exist, only the one with the highest ID takes effect.
{{site.ai_gateway}} ignores the others without reporting an error.

### Exit Transformer

An Exit Transformer AI Policy rewrites responses that other AI Policies send, including authentication `401` responses and responses that a Pre-Function or Post-Function returns with `kong.response.exit`.
Each function receives the status code, the body, and the headers, and returns the new values.
By default, it doesn't rewrite responses that {{site.ai_gateway}} sends for unknown conditions, such as the `404` for a request that matches no Route.
Set [`handle_unknown`](/ai-gateway/policies/exit-transformer/reference/#schema--config-handle-unknown) and [`handle_unexpected`](/ai-gateway/policies/exit-transformer/reference/#schema--config-handle-unexpected) to `true` to rewrite those too.

### Conditions

Unlike the {{site.base_gateway}} Pre-Function and Post-Function plugins, the {{site.ai_gateway}} Pre-Function and Post-Function AI Policies support the `condition` field.
When the condition evaluates to `false`, {{site.ai_gateway}} skips the AI Policy.
See [AI Policy conditions](/ai-gateway/conditions/).

## Examples

The following examples run in strict mode, the default.
Each example is an AI Policy that you attach to an AI Model, or apply globally.
For how the scope affects when an AI Policy runs, see [AI Policy configuration](#ai-policy-configuration).

### Read the AI Consumer in a Post-Function

A [Post-Function](/ai-gateway/policies/post-function/) runs after authentication, so `kong.client.get_consumer` returns the authenticated AI Consumer.
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
In this example, a global [Pre-Function](/ai-gateway/policies/pre-function/) stores a value and a Post-Function on an AI Model reads it.

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

An [Exit Transformer](/ai-gateway/policies/exit-transformer/) function receives the status code, the body, and the headers, and returns the new values.
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

This Post-Function reports which operations the sandbox allows.
In strict mode, `resty_http`, `io_open`, `tcp_socket`, and `os_execute` are `false`, and `cjson` is `true`.

{% entity_example %}
type: policy
data:
  display_name: "Check sandbox restrictions"
  name: check-sandbox-restrictions
  type: post-function
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

## Allowlist changes

{{site.ai_gateway}} can change the sandbox allowlists of environment and modules.
Most changes add entries.
If {{site.ai_gateway}} finds a security vulnerability, it can remove entries and notifies you of the change.
