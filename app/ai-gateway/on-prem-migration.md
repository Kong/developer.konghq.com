---
title: "Migrate on-prem {{site.base_gateway}} 3.x to on-prem {{site.ai_gateway_name}} 2.x"

description: "Migrate an on-prem Kong Gateway 3.x deployment running AI plugins to on-prem Kong AI Gateway 2.x using a blue/green strategy. Covers version compatibility, configuration changes required before the move, and cutover."

content_type: reference
layout: reference

products:
  - ai-gateway

works_on:
  - on-prem

min_version:
  gateway: '3.14'

tags:
  - ai
  - upgrade
  - migration
  - blue-green

breadcrumbs:
  - /ai-gateway/

related_resources:
  - text: "Migrate to {{site.ai_gateway}} 2.x in {{site.konnect_short_name}}"
    url: /ai-gateway/v2-migration-guide/
  - text: "Configure {{site.ai_gateway_name}} on-prem"
    url: /ai-gateway/configure-on-prem/
  - text: "{{site.ai_gateway}} 2.x concepts"
    url: /ai-gateway/ai-gateway-v2-concepts/
  - text: "Blue-green upgrade for {{site.base_gateway}}"
    url: /gateway/upgrade/blue-green/
  - text: "{{site.base_gateway}} breaking changes"
    url: /gateway/breaking-changes/
  - text: AI Proxy Advanced plugin
    url: /plugins/ai-proxy-advanced/
  - text: AI Rate Limiting Advanced plugin
    url: /plugins/ai-rate-limiting-advanced/
---

This guide migrates an on-prem {{site.base_gateway}} 3.14 or later deployment that runs {{site.ai_gateway}} 1.x to on-prem {{site.ai_gateway_name}} 2.x.
The {{site.ai_gateway}} 1.x mode means using AI plugins, such as [AI Proxy Advanced](/plugins/ai-proxy-advanced/) and [AI Rate Limiting Advanced](/plugins/ai-rate-limiting-advanced/).

By using this migration method, you will have a fully on-prem deployment of {{site.ai_gateway}} 2.x.
The approach is blue/green migration, not an in-place upgrade.
Throughout this guide, **blue** refers to your current {{site.base_gateway}} 3.x control plane and data planes.
**Green** refers to the control plane and data planes running {{site.ai_gateway_name}} 2.x, configured with the same plugins as blue.

{:.warning}
> This guide doesn't move you to the {{site.ai_gateway}} 2.x entity and policy model ([AI Models](/ai-gateway/entities/ai-model/), [AI Policies](/ai-gateway/entities/ai-policy/), and so on).
> You keep managing {{site.ai_gateway_name}} with the same plugins and the same pipeline you use today. Only the runtime version changes.
>
> If you want to move to the entity/policy model instead in {{site.konnect_short_name}}, see [Migrate to {{site.ai_gateway}} 2.x in {{site.konnect_short_name}}](/ai-gateway/v2-migration-guide/).

## Migration assertions

Review [{{site.ai_gateway}} 2.x concepts](/ai-gateway/ai-gateway-v2-concepts/) for what changed between {{site.ai_gateway}} 1.x and 2.x versions before you plan this migration.
Five assertions guide this migration:

1. **The control plane and every data plane must run the exact same {{site.ai_gateway_name}} version.** An {{site.ai_gateway}} 2.x control plane rejects {{site.base_gateway}} 3.x data planes, and a {{site.base_gateway}} 3.x control plane can't serve {{site.ai_gateway}} 2.x data planes. There's no mixed-version window, which is why this migration is blue/green instead of an in-place upgrade.
2. **Rate limits have to move from `llm_providers` to `policies` before the version changes.** The [AI Rate Limiting Advanced](/plugins/ai-rate-limiting-advanced/) plugin's `llm_providers` field is removed in {{site.ai_gateway}} 2.x. An {{site.ai_gateway}} 2.x data plane rejects any configuration that still uses it.
3. **One default changes, and some fields are gone.** The request-body-size limit on several AI plugins moves from 1 MiB on {{site.base_gateway}} 3.x to 8 MiB on {{site.ai_gateway}} 2.x by default. A handful of plugin fields are also removed. See [Before you begin](#before-you-begin) and [Migrate from {{site.base_gateway}} 3.x to {{site.ai_gateway}} 2.x](#migrate-from-kong-gateway-3x-to-ai-gateway-2x).
4. **The [AI Proxy](/plugins/ai-proxy/) plugin is removed.** Any Route using it has to move to [AI Proxy Advanced](/plugins/ai-proxy-advanced/) before you migrate.
5. **Your starting version matters.** You need {{site.base_gateway}} 3.14 or later to make the rate limit change, and the {{site.ai_gateway}} 2.x release you target has to support every {{site.base_gateway}} feature your configuration uses. See [Which versions this covers](#which-versions-this-covers).

## How the migration works

In this migration, you'll make the {{site.ai_gateway}} 2.x changes in your {{site.base_gateway}} 3.14 (**blue**) or later configuration first..
After you confirm that blue still behaves exactly as it did before, you can point the same pipeline at a new environment running {{site.ai_gateway_name}} 2.x (**green**), and deploy the identical configuration to it.

1. Update your {{site.base_gateway}} 3.14 (**blue**) or later configuration so it's valid on both {{site.base_gateway}} 3.x and {{site.ai_gateway}} 2.x.
2. Confirm blue's behavior hasn't changed.
3. Build green by creating a new control plane and data planes running {{site.ai_gateway_name}} 2.x, on a new, empty database.
4. Deploy the same configuration to green and validate it before any traffic arrives.
5. Shift traffic from blue to green gradually.
6. Decommission blue once green is stable through a soak period.

{% mermaid %}
flowchart TD
    DBX[(Blue Postgres)]
    DBY[(Green Postgres<br/>new and empty)]
    CPX(Blue CP<br/>{{site.base_gateway}} 3.x)
    CPY(Green CP<br/>{{site.ai_gateway_name}} 2.x)
    DPX(Blue DPs)
    DPY(Green DPs)
    LB(Load balancer)
    API(AI traffic)

    API --> LB
    LB -."90%".-> DPX
    LB --"10%"--> DPY
    DPX --- CPX
    DPY --- CPY
    CPX --> DBX
    CPY --> DBY

    style CPX stroke-dasharray:3
    linkStyle 1 stroke:#d44324!important
    linkStyle 2 stroke:#b6d7a8!important
{% endmermaid %}

> _Figure 1: Blue ({{site.base_gateway}} 3.x) and green ({{site.ai_gateway_name}} 2.x) run on separate, independent databases._
_Traffic shifts gradually from blue to green. Nothing is shared between the two beyond the pipeline that deploys the same configuration to both._

## Which versions this covers

The following table describes which {{site.ai_gateway}} 2.x release you should target:

{% table %}
columns:
  - title: Target
    key: target
  - title: Status
    key: status
rows:
  - target: "{{site.ai_gateway_name}} 2.1.0"
    status: "Can be migrated to from {{site.base_gateway}} 3.14 without any regressions."
  - target: "{{site.ai_gateway_name}} 2.2.0"
    status: "Needs the same configuration changes as 2.1.0. Two known regressions compared with 2.1.0: AI Prompt Template templates aren't applied before the request reaches the model provider, and consumer groups named `admins` can't be read by name, which breaks decK (see [Known issues and notes](#known-issues-and-notes)). If you use AI Prompt Template, target 2.1.0 until a 2.2.x patch fixes it."
{% endtable %}

{{site.ai_gateway}} 2.x's control plane and every {{site.ai_gateway}} 2.x data plane run the same exact version, whichever you choose.

### Which {{site.base_gateway}} 3.x versions can start

`policies` is supported on [AI Rate Limiting Advanced](/plugins/ai-rate-limiting-advanced/) in {{site.base_gateway}} 3.14.0.0 or later, the same release that deprecated `llm_providers`.

{% table %}
columns:
  - title: Your version
    key: version
  - title: Path
    key: path
rows:
  - version: "3.13 or earlier"
    path: "`policies` doesn't exist yet, so you can't make the rate limit change on {{site.base_gateway}} 3.x. Upgrade to {{site.base_gateway}} 3.14 or later first (an ordinary {{site.base_gateway}} 3.x upgrade), then follow this guide."
  - version: "3.14.x"
    path: "Validated end-to-end. Follow this guide as written."
  - version: "3.15.x"
    path: "The same steps, plus 43 more fields on 14 plugins that {{site.ai_gateway}} 2.x doesn't have. See [Considerations for {{site.base_gateway}} 3.15 to {{site.ai_gateway}} 2.x migrations](#considerations-for-kong-gateway-315-to-ai-gateway-2x-migrations). If your configuration uses none of them, 2.1.0 is a valid target. If it does and you want to continue using the new fields, you should not migrate at this time."
  - version: "3.16.x"
    path: "{{site.ai_gateway}} 2.1.0 and 2.2.0 doesn't have support for all 3.16 features, including the plugin-level `expressions` field on every plugin. If your configuration uses none of them, 2.1.0 is a valid target. If it does and you want to continue using the new fields, you should not migrate at this time."
{% endtable %}

## Before you begin

Before you begin the migration, you must go over the following requirements and audit your existing configuration.

### Requirements

* {{site.ai_gateway}} running on on-prem {{site.base_gateway}} 3.14.0.0 or later.
* Your existing configuration pipeline (decK, {{site.kic_product_name}}, Terraform, or similar) is able to target a second control plane. The examples in this guide use decK. The same field changes apply with any tool.
* Access to install a second environment. These examples assume the `kong/kong` Helm chart on Kubernetes. On VMs or containers, set the equivalent `kong.conf` settings or `KONG_*` environment variables.

### Discovery checklist

Before you schedule anything, inventory the following.
Each answer changes a later step.

{% table %}
columns:
  - title: Item to audit
    key: item
  - title: Why it matters
    key: why
rows:
  - item: "Every [AI Rate Limiting Advanced](/plugins/ai-rate-limiting-advanced/) plugin: does it use `llm_providers`? What's its `llm_format` and `strategy` (`local` or `redis`)?"
    why: "Scopes the configuration change in [Update your configuration on {{site.base_gateway}} 3.x](#update-your-configuration-on-kong-gateway-3x), and how counters behave at cutover."
  - item: "Do you have AI plugins relying on the default `max_request_body_size`?"
    why: "The 3.x default is 1 MiB. The {{site.ai_gateway}} 2.x default is 8 MiB."
  - item: "Do you have plugins using a field {{site.ai_gateway}} 2.x removed (see [Update your configuration on {{site.base_gateway}} 3.x](#update-your-configuration-on-kong-gateway-3x), and [Considerations for {{site.base_gateway}} 3.15 to {{site.ai_gateway}} 2.x migrations](#considerations-for-kong-gateway-315-to-ai-gateway-2x-migrations) on {{site.base_gateway}} 3.15)?"
    why: "That behavior has to be addressed before you build the {{site.ai_gateway}} 2.x deployment."
  - item: "Do you have Routes using the [AI Proxy](/plugins/ai-proxy/) plugin?"
    why: "Not available in {{site.ai_gateway}} 2.x. Move them to [AI Proxy Advanced](/plugins/ai-proxy-advanced/) first."
  - item: "What does {{site.base_gateway}} 3.14 use that your pipeline doesn't manage? For example, RBAC users and admins, Kong Manager settings, the license, keyring material, and anything created at runtime."
    why: "The {{site.ai_gateway}} 2.x deployment is built by your pipeline, so you recreate each of these on it separately."
  - item: "Does your pipeline define Consumers, Consumer Groups, and credentials, or are they created at runtime (Admin API, Dev Portal)? Are any Consumer Groups named after an Admin API endpoint (`admins`, `developers`, and so on)?"
    why: "Only what the pipeline defines reaches the {{site.ai_gateway}} 2.x deployment. Reserved group names break decK (see [Known issues and notes](#known-issues-and-notes))."
  - item: "Do you use a [Vault](/gateway/entities/vault/) backend with the secrets or environment variables your data planes need to resolve references?"
    why: "The {{site.ai_gateway}} 2.x data planes need the same secret material."
  - item: "Do you use cluster mTLS mode (shared or PKI)?"
    why: "The {{site.ai_gateway}} 2.x deployment uses the same mode with its own certificate."
  - item: "How does configuration reach the control plane? For example, the tool, its version, how it runs in CI/CD, and whether it's the complete source of truth."
    why: "Every step in [Migrate from {{site.base_gateway}} 3.x to {{site.ai_gateway}} 2.x](#migrate-from-kong-gateway-3x-to-ai-gateway-2x) runs through your pipeline, and it has to be able to target the {{site.ai_gateway}} 2.x deployment."
  - item: "What is your traffic entry point and is weighted splitting possible?"
    why: "Determines how [Cut over](#cut-over) actually shifts traffic."
{% endtable %}

## Migrate from {{site.base_gateway}} 3.x to {{site.ai_gateway}} 2.x

The following detail the migration steps. 
You must follow each in order to complete the migration.

### Update your configuration on {{site.base_gateway}} 3.x

In this step, you'll make your {{site.base_gateway}} 3.x configuration {{site.ai_gateway}} 2.x-ready, and prove it still behaves the same on {{site.base_gateway}} 3.x before the version changes.
Make every change in the source of your configuration (decK state files, {{site.kic_product_name}} resources, or Terraform), not on the running gateway.

#### Move AI Proxy routes to AI Proxy Advanced

Move every [AI Proxy](/plugins/ai-proxy/) plugin to [AI Proxy Advanced](/plugins/ai-proxy-advanced/).
The single model becomes one entry under `targets`, with the same provider, model, and auth settings.

Before, on [AI Proxy](/plugins/ai-proxy/):

<!--vale off-->
```yaml
config:
  route_type: llm/v1/chat
  auth:
    header_name: Authorization
    header_value: Bearer ${key}
  model:
    provider: openai
    name: gpt-4
    options:
      max_tokens: 512
      temperature: 1.0
```
{:.collapsible}
<!--vale on-->

After, on [AI Proxy Advanced](/plugins/ai-proxy-advanced/):

<!--vale off-->
```yaml
config:
  targets:
  - route_type: llm/v1/chat
    auth:
      header_name: Authorization
      header_value: Bearer ${key}
    model:
      provider: openai
      name: gpt-4
      options:
        max_tokens: 512
        temperature: 1.0
```
{:.collapsible}
<!--vale on-->

#### Move rate limits from `llm_providers` to `policies`

For each [AI Rate Limiting Advanced](/plugins/ai-rate-limiting-advanced/) plugin that uses `llm_providers`:

1. Create one entry under `policies` for each `llm_providers` entry, matched on that provider: `match: [{type: provider, values: [<provider name>]}]`.
2. Pair each `limit[i]` with its `window_size[i]` into that policy's `limits` list.
3. Copy the plugin's `tokens_count_strategy` into every limit. A limit's own default is `total_tokens`, so if you don't copy the strategy into the limit, a cost budget silently becomes a token limit.
4. Set `window_type` on each policy to the plugin's `window_type` (default `sliding`).
5. Remove `llm_providers` and `llm_format`.

Providers you didn't list under `llm_providers` stay unlimited, exactly as they are today, so don't add a catch-all policy.
Plugins already using `policies` don't need a change.
A plugin without any limits at all needs `policies`, or needs to be removed, because {{site.ai_gateway}} 2.x requires it.

The following is an example configuration on {{site.base_gateway}} 3.x with the deprecated field:

<!--vale off-->
```yaml
config:
  tokens_count_strategy: cost
  llm_format: openai
  llm_providers:
  - name: azure
    limit: [0.0015]
    window_size: [3600]
```
{:.collapsible}
<!--vale on-->

The following is an example configuration after it's been updated so it's valid on {{site.base_gateway}} 3.14 and later and on {{site.ai_gateway}} 2.x:

<!--vale off-->
```yaml
config:
  tokens_count_strategy: cost
  policies:
  - match: [{type: provider, values: [azure]}]
    window_type: sliding
    limits:
    - {limit: 0.0015, window_size: 3600, tokens_count_strategy: cost}
```
{:.collapsible}
<!--vale on-->

#### Set the request-body limit explicitly

Set `max_request_body_size: 1048576` on every instance of the following plugins that don't already set it, to keep today's 1 MiB limit on {{site.ai_gateway}} 2.x: 
* [AI A2A Proxy](/plugins/ai-a2a-proxy/)
* [AI MCP OAuth2](/plugins/ai-mcp-oauth2/)
* [AI MCP Proxy](/plugins/ai-mcp-proxy/)
* [AI Prompt Decorator](/plugins/ai-prompt-decorator/)
* [AI Prompt Guard](/plugins/ai-prompt-guard/)
* [AI Prompt Template](/plugins/ai-prompt-template/)
* [AI Proxy Advanced](/plugins/ai-proxy-advanced/)
* [AI Request Transformer](/plugins/ai-request-transformer/)
* [AI Response Transformer](/plugins/ai-response-transformer/).

Omit `max_request_body_size: 1048576` only when you deliberately want the new 8 MiB default.

#### Remove fields {{site.ai_gateway}} 2.x doesn't have

{{site.ai_gateway}} 2.x doesn't support the fields listed in the following table.
Where a field is set to its default (empty, or the default shown), delete it.
Where a field has a value other than its default, that behavior doesn't carry over automatically.
Contact Kong Support before you migrate to find out whether a {{site.ai_gateway}} 2.x equivalent exists.

`upstream_path` has been deprecated since at least {{site.base_gateway}} 3.12 in favor of `upstream_url`.
If you set it anywhere, move that target to `upstream_url` (the full upstream URL, including the path) as part of this step.
{{site.base_gateway}} 3.x accepts both.

{% table %}
columns:
  - title: Plugin
    key: plugin
  - title: Fields removed in {{site.ai_gateway}} 2.x
    key: fields
rows:
  - plugin: "[AI Rate Limiting Advanced](/plugins/ai-rate-limiting-advanced/)"
    fields: "`llm_providers`, `llm_format` (handled in [Move rate limits from `llm_providers` to `policies`](#move-rate-limits-from-llm_providers-to-policies))"
  - plugin: "[AI LLM as Judge](/plugins/ai-llm-as-judge/), [AI Request Transformer](/plugins/ai-request-transformer/), [AI Response Transformer](/plugins/ai-response-transformer/)"
    fields: "`http_proxy_host`, `http_proxy_port`, `https_proxy_host`, `https_proxy_port`"
  - plugin: "[AI MCP OAuth2](/plugins/ai-mcp-oauth2/)"
    fields: "`http_proxy`, `http_proxy_authorization`, `https_proxy`, `https_proxy_authorization`, `no_proxy`"
  - plugin: "[AI Proxy Advanced](/plugins/ai-proxy-advanced/)"
    fields: "`targets[].model.options.upstream_path`"
  - plugin: "[AI LLM as Judge](/plugins/ai-llm-as-judge/), [AI Request Transformer](/plugins/ai-request-transformer/), [AI Response Transformer](/plugins/ai-response-transformer/)"
    fields: "`llm.model.options.upstream_path`"
  - plugin: "[AI Semantic Prompt Guard](/plugins/ai-semantic-prompt-guard/)"
    fields: "`llm_format` (default `openai`), `max_request_body_size` (default `1048576`), `rules.max_request_body_size`"
  - plugin: "[Forward Proxy](/plugins/forward-proxy/)"
    fields: "`ca_certificates`"
  - plugin: "[Request Validator](/plugins/request-validator/)"
    fields: "`array_length_compat` (default `true`)"
{% endtable %}

##### Considerations for {{site.base_gateway}} 3.15 to {{site.ai_gateway}} 2.x migrations

Beyond the fields in [Remove fields {{site.ai_gateway}} 2.x doesn't have](#remove-fields-ai-gateway-2x-doesnt-have), {{site.base_gateway}} 3.15 plugins have the following fields that {{site.ai_gateway}} 2.x plugins don't (paths are under `config`).
As with that section, delete any of these your configuration sets to its default.
If one is set to a value other than its default, that feature isn't available on the {{site.ai_gateway}} 2.x releases covered by this guide.

The `openid-connect` plugin's `bearer_token_header_name` doesn't have a default on {{site.base_gateway}} 3.15 and defaults to `authorization:bearer` on {{site.ai_gateway}} 2.x.
Set it explicitly if you rely on this behavior.

{% table %}
columns:
  - title: Plugin
    key: plugin
  - title: Fields not in 2.x
    key: fields
rows:
  - plugin: aws-lambda
    fields: "`preserve_lambda_api_error_code`"
  - plugin: confluent
    fields: "`error_handling`, `headers`, `oauthbearer`, `schema_registry.confluent.authentication` (`identity_pool_id`, `logical_cluster_id`)"
  - plugin: confluent-consume
    fields: "`consumer_group`, `error_handling`, `oauthbearer`, `schema_registry.confluent.authentication` (`identity_pool_id`, `logical_cluster_id`), and the same two under `topics[]`"
  - plugin: http-log
    fields: "`client_certificate`"
  - plugin: kafka-consume
    fields: "`authentication.oauthbearer`, `consumer_group`, `error_handling`, `schema_registry.confluent.authentication` (`identity_pool_id`, `logical_cluster_id`), and the same two under `topics[]`"
  - plugin: kafka-log
    fields: "`authentication.oauthbearer`, `schema_registry.confluent.authentication` (`identity_pool_id`, `logical_cluster_id`)"
  - plugin: kafka-upstream
    fields: "`authentication.oauthbearer`, `error_handling`, `headers`, `schema_registry.confluent.authentication` (`identity_pool_id`, `logical_cluster_id`)"
  - plugin: konnect-application-auth
    fields: "Under `v2_strategies.openid_connect[].config`: `cluster_cache_items`, `proof_of_possession_mtls_from_header`, `token_exchange.subject_token_issuers[].jwks_uri`, `token_exchange.subject_token_issuers[].verify_signature`"
  - plugin: oas-validation
    fields: "`max_structured_errors`, `structured_errors`"
  - plugin: openid-connect
    fields: "`cluster_cache_items`, `proof_of_possession_mtls_from_header`, `token_exchange.subject_token_issuers[].jwks_uri`, `token_exchange.subject_token_issuers[].verify_signature`"
  - plugin: rate-limiting-advanced
    fields: "`counter_key`"
  - plugin: "solace-consume, solace-log, solace-upstream"
    fields: "`session.authentication.client_credentials`"
{% endtable %}

#### Rename reserved Consumer Group names

If you manage Consumer Groups through decK, rename any group whose name matches an Admin API endpoint, for example `admins` or `developers`.
The Admin API refuses to look those groups up by name, and decK reads groups by name, so its diff and sync fail on affected versions (see [Known issues and notes](#known-issues-and-notes)).
Rename the group in your source.
Its members and plugins move with it in the same change.
Update anything that refers to it by name.

#### Deploy and gate

1. Open a pull request with these changes, and review it like any configuration change.
2. Compare it against {{site.base_gateway}} 3.x (using `deck gateway diff`, `terraform plan`, or an equivalent). Only the intended plugin updates should display.

   ```bash
   deck gateway diff kong.yaml --kong-addr https://kong-admin.example.com:8444
   ```

   Replace `https://kong-admin.example.com:8444` with your {{site.base_gateway}} 3.x Admin API address.
3. Deploy the configuration changes to {{site.base_gateway}} 3.x through your normal pipeline.

Before you move on to [Build the {{site.ai_gateway}} 2.x deployment](#build-the-ai-gateway-2x-deployment), confirm all of the following:

* Your configuration source doesn't contain `llm_providers`, `llm_format` on rate limit plugins, `name: ai-proxy`,`upstream_path`, and any other field removed in [Remove fields {{site.ai_gateway}} 2.x doesn't have](#remove-fields-ai-gateway-2x-doesnt-have) (or in [Considerations for {{site.base_gateway}} 3.15 to {{site.ai_gateway}} 2.x migrations](#considerations-for-kong-gateway-315-to-ai-gateway-2x-migrations) on {{site.base_gateway}} 3.15). Consumer Groups don't use a reserved name.
* The {{site.base_gateway}} 3.x control plane logs don't show `config.llm_providers is deprecated` warnings.
* A preview against {{site.base_gateway}} 3.x doesn't show any pending changes. This also confirms your source is complete: it contains everything your pipeline manages on {{site.base_gateway}} 3.x.
* Your per-Route smoke test set passes on {{site.base_gateway}} 3.x, and every rate limit policy you run is driven to its enforcement point (`429`).

### Build the {{site.ai_gateway}} 2.x deployment

1. Freeze configuration changes on {{site.base_gateway}} 3.x from this point until the soak in [Cut over](#cut-over) ends.
2. Install the {{site.ai_gateway}} 2.x control plane on a new, empty Postgres database, from the {{site.base_gateway}} 3.x control plane settings with only the image, database host, and cluster certificate changed. Set the image to `kong/kong-ai-gateway`, tagged with the version you're targeting from [Which {{site.ai_gateway}} 2.x release to target](#which-versions-this-covers). On a fresh database, the install runs `kong migrations bootstrap` with that image. The `kong/kong` chart does this on `helm install`. Elsewhere, run it once before starting the control plane. If {{site.base_gateway}} 3.x enforces RBAC, also set the admin password on the {{site.ai_gateway}} 2.x control plane so the bootstrap creates the `kong_admin` super admin.
   
   ```
   image:
     repository: kong/kong-ai-gateway
     tag: "2.1.0"
   env:
     pg_host: kong-ai-gateway-postgres.example.com
     cluster_cert: /etc/secrets/kong-ai-gateway-cluster-cert/tls.crt
     cluster_cert_key: /etc/secrets/kong-ai-gateway-cluster-cert/tls.key
   secretVolumes:
   - kong-ai-gateway-cluster-cert
   ```

   Replace `kong-ai-gateway-postgres.example.com` with your new Postgres host, and `kong-ai-gateway-cluster-cert` with the name of your new cluster certificate secret.
3. Load the license into the {{site.ai_gateway}} 2.x database. In hybrid mode, the control plane sends the license to its data planes only from the [`/licenses` endpoint](/api/gateway/admin-ee/#/operations/create-licenses). The control plane's license environment variable alone isn't enough, and without it, data planes reject the configuration.

   ```bash
   curl -X POST https://kong-ai-gateway-admin.example.com:8444/licenses \
     --data-urlencode "payload@license.json"
   ```

   Replace `https://kong-ai-gateway-admin.example.com:8444` with your {{site.ai_gateway_name}} 2.x Admin API address, and `license.json` with your license file.
4. Recreate what your pipeline doesn't manage, from the discovery checklist: RBAC users and admins, Kong Manager settings, the keyring material for encrypted credentials, and any Consumers or credentials created outside the pipeline.
5. Point your pipeline at {{site.ai_gateway}} 2.x and deploy the configuration from [Update your configuration on {{site.base_gateway}} 3.x](#update-your-configuration-on-kong-gateway-3x): the same source and the same commit that's running on {{site.base_gateway}} 3.x. With decK, that's your normal sync. decK creates each Workspace if it doesn't exist. With {{site.kic_product_name}}, it's a controller instance configured with the {{site.ai_gateway}} 2.x deployment's Admin API.

   ```bash
   deck gateway sync kong.yaml --kong-addr https://kong-ai-gateway-admin.example.com:8444
   ```

   Replace `https://kong-ai-gateway-admin.example.com:8444` with your {{site.ai_gateway_name}} 2.x Admin API address.
6. Install the {{site.ai_gateway}} 2.x data planes from the {{site.base_gateway}} 3.x data plane settings. Change the image to `kong/kong-ai-gateway`, tagged with the same version as the {{site.ai_gateway}} 2.x control plane, point the cluster control plane and telemetry endpoint at the {{site.ai_gateway}} 2.x control plane, and use the {{site.ai_gateway}} 2.x cluster certificate. Carry over the vault environment variables and secrets your data planes resolve.

   ```
   image:
     repository: kong/kong-ai-gateway
     tag: "2.1.0"
   env:
     role: data_plane
     cluster_control_plane: kong-ai-gateway-admin.example.com:8005
     cluster_telemetry_endpoint: kong-ai-gateway-admin.example.com:8006
     cluster_cert: /etc/secrets/kong-ai-gateway-cluster-cert/tls.crt
     cluster_cert_key: /etc/secrets/kong-ai-gateway-cluster-cert/tls.key
   secretVolumes:
   - kong-ai-gateway-cluster-cert
   ```

   Replace `kong-ai-gateway-admin.example.com` with your {{site.ai_gateway_name}} 2.x control plane's cluster address, and `kong-ai-gateway-cluster-cert` with the name of your new cluster certificate secret.
7. If any plugin uses `strategy: redis` for rate limiting, give {{site.ai_gateway}} 2.x its own Redis database or namespace now, and don't share {{site.base_gateway}} 3.x's. Rate limit counters start fresh on {{site.ai_gateway}} 2.x regardless of strategy. With `strategy: local` this happens automatically. With `strategy: redis` it depends on this separate database being in place before any traffic reaches {{site.ai_gateway}} 2.x.

{:.warning}
> Build the {{site.ai_gateway}} 2.x deployment from your configuration source, not from a `deck gateway dump` of {{site.base_gateway}} 3.x.
> In Kong's own validation of this migration path, a dump of a {{site.base_gateway}} 3.x control plane carried `upstream_path: null` on every AI model, which {{site.ai_gateway}} 2.x rejects, and it dropped an OpenTelemetry `queue.max_batch_size` setting, silently resetting it on {{site.ai_gateway}} 2.x.

### Validate the {{site.ai_gateway}} 2.x deployment

Do not allow any traffic to reach {{site.ai_gateway}} 2.x until all of the following pass:

{% table %}
columns:
  - title: Gate
    key: gate
  - title: How
    key: how
rows:
  - gate: Deployment is complete
    how: "A preview of your configuration against {{site.ai_gateway}} 2.x shows no pending changes in any workspace."
  - gate: Every {{site.ai_gateway}} 2.x data plane is in sync
    how: "Confirm this by sending a `GET` request to the [`/clustering/data-planes` endpoint](/api/gateway/admin-ee/#/operations/get-data-planes). Every data plane is listed, all report the same configuration hash, and data plane logs have no configuration-sync errors."
  - gate: License present
    how: "Confirm this by sending a `GET` request to the [`/licenses` endpoint](/api/gateway/admin-ee/#/operations/get-licenses) on {{site.ai_gateway}} 2.x. It returns the license."
  - gate: Non-pipeline items recreated
    how: "Admins and RBAC users can log in and act as they do on {{site.base_gateway}} 3.x. Encrypted credentials authenticate."
  - gate: Parity with {{site.base_gateway}} 3.x
    how: "The same per-Route smoke test set, using existing Consumer credentials, gives the same statuses on {{site.base_gateway}} 3.x and {{site.ai_gateway}} 2.x. Every rate limit plugin you run reaches its enforcement point on {{site.ai_gateway}} 2.x. Soak under representative load."
{% endtable %}

If an {{site.ai_gateway}} 2.x data plane reports configuration-sync errors, it rejects the whole configuration and serves nothing.
The most likely cause is a rate limit still on `llm_providers`, or a removed field still set.
Fix it in the source, redeploy to {{site.base_gateway}} 3.x and to {{site.ai_gateway}} 2.x, and recheck.

This gate is also where you confirm the items flagged in [Before you begin](#before-you-begin): test every rate limit policy you actually run to its enforcement point on both {{site.base_gateway}} 3.x and {{site.ai_gateway}} 2.x, not only the ones easiest to exercise, and smoke-test your own Routes, plugins, and credentials rather than relying on a generic check.

### Cut over

1. Shift traffic at your entry point from {{site.base_gateway}} 3.x to {{site.ai_gateway}} 2.x in weighted steps, for example 5%, 25%, 50%, then 100%. Check your error-rate and latency SLOs at each step before moving on.
2. Rate limit counters on {{site.ai_gateway}} 2.x start fresh, using the Redis database or namespace you prepared in [Build the {{site.ai_gateway}} 2.x deployment](#build-the-ai-gateway-2x-deployment) if you run `strategy: redis`.
3. Keep the configuration freeze in place until the soak ends, so {{site.base_gateway}} 3.x stays a valid rollback target.

### Roll back

If you need to roll back, shift traffic back to {{site.base_gateway}} 3.x at your entry point.
{{site.base_gateway}} 3.x still runs a valid configuration: the changes in [Update your configuration on {{site.base_gateway}} 3.x](#update-your-configuration-on-kong-gateway-3x) are native to {{site.base_gateway}} 3.14 and later, and its database was never touched.

The configuration freeze keeps the two sides' configuration identical.
Data that clients create at runtime on {{site.ai_gateway}} 2.x during the soak, for example credentials issued through the Admin API, doesn't exist on {{site.base_gateway}} 3.x.
Check for it before rolling back.

### Decommission the {{site.base_gateway}} 3.x deployment

After the soak, do the following:

1. Make {{site.ai_gateway}} 2.x your pipeline's only target.
2. Lift the configuration freeze.
3. Tear down {{site.base_gateway}} 3.x and its database.

## Known issues and notes

* **decK and Consumer Groups**: See [Rename reserved Consumer Group names](#rename-reserved-consumer-group-names). If your groups can't be renamed before the migration, diff and sync with `--skip-consumers` and compare Consumers, groups, and memberships through the Admin API instead.

  ```bash
  deck gateway diff kong.yaml --skip-consumers --kong-addr https://kong-ai-gateway-admin.example.com:8444
  deck gateway sync kong.yaml --skip-consumers --kong-addr https://kong-ai-gateway-admin.example.com:8444
  ```

  Replace `https://kong-ai-gateway-admin.example.com:8444` with your {{site.ai_gateway_name}} 2.x Admin API address.
* **AI Prompt Compressor on 2.2.0**: 2.2.0 adds a `headroom` block to this plugin. decK shows a permanent one-plugin diff on it after deployment, listing its default values. This is cosmetic. Every value shown is the default.
* **Exact versions**: The {{site.ai_gateway}} 2.x control plane and every {{site.ai_gateway}} 2.x data plane must be on the same version. Upgrading {{site.ai_gateway}} 2.x later follows the same rule: a new {{site.ai_gateway}} 2.x deployment, not a rolling image change.
* **Vault rendering**: The {{site.ai_gateway}} 2.x Admin API renders an environment vault without its default configuration block, which can show as a one-line decK diff. Confirm the behavior for your vault type during discovery.
* **Traditional (non-hybrid) deployments** aren't covered by this guide. Contact Kong before performing a migration on a traditional deployment.
