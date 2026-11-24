---
title: "Migrate {{site.ai_gateway}} Consumers to users"

description: "Move {{site.ai_gateway}} callers from AI Consumers to users and agents backed by {{site.identity}} principals, without changing the API key any client sends."

content_type: reference
layout: reference

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kongctl

min_version:
  ai-gateway: '2.3'

tags:
  - ai
  - migration

breadcrumbs:
  - /ai-gateway/

related_resources:
  - text: "{{site.identity}} principals"
    url: /identity/principals/
  - text: "{{site.identity}} directories"
    url: /identity/directories/
  - text: "AI Access Management concepts"
    url: /ai-access-management/concepts/
  - text: "AI Consumers"
    url: /ai-gateway/entities/ai-consumer/
  - text: "AI Auth Strategies"
    url: /ai-gateway/entities/ai-auth-strategy/
  - text: "AI Models"
    url: /ai-gateway/entities/ai-model/
  - text: "AI Agents"
    url: /ai-gateway/entities/ai-agent/
  - text: "AI Policy conditions"
    url: /ai-gateway/conditions/
  - text: "Configure dynamic Policy config with CEL in {{site.ai_gateway}}"
    url: /ai-gateway/configure-dynamic-plugin-config-with-cel/
---

This guide explains how to move {{site.ai_gateway}} traffic from [AI Consumers](/ai-gateway/entities/ai-consumer/) to users and agents in [AI Access Management](/ai-access-management/concepts/) without changing the API key any client sends.
Users and agents are [{{site.identity}} principals](/identity/principals/): AI Access Management displays them as users and agents, and {{site.identity}} stores them as principals in a [directory](/identity/directories/).
You create a principal for each AI Consumer, import its existing key, link the two, switch authentication, and then retire the AI Consumer after nothing depends on it.

This guide is for {{site.konnect_short_name}} customers on {{site.ai_gateway}} 2.3 or later who authenticate callers with AI Consumers, by API key or [OpenID Connect (OIDC)](/ai-gateway/openid-connect/).
AI Consumers stay supported in the API and at runtime, so you can pause between any two steps and nothing breaks.

What changes for you:

- **Clients:** Nothing changes. These use the same key, same header or query parameter.
- **Identity:** Each caller becomes a user or an agent in your {{site.identity}} directory, visible in AI Access Management.
- **Policy:** [AI Policies](/ai-gateway/entities/ai-policy/) scoped to AI Consumers or [AI Consumer Groups](/ai-gateway/entities/ai-consumer-group/) become conditions on principal metadata, which you can change without editing policies.

## Prerequisites

{:.warning}
> **Before you start, confirm you hold the plaintext of every API key in use.**
> {{site.konnect_short_name}} doesn't return an AI Consumer's key after it's created, and {{site.identity}} stores only one-way hashes of imported keys.
> Typical sources are the secret store behind your [`kongctl`](/kongctl/) or Terraform configuration (`!secret` references), a secrets manager, or the systems your clients read keys from.
> If some keys exist only in client applications, talk to your Kong account team before you start: those callers need new keys.

Before migrating, make sure you have the following:

- An {{site.ai_gateway}} 2.3 or later control plane and data planes that authenticates callers with AI Consumers.
- A {{site.konnect_short_name}} [Personal Access Token (PAT) or System Account Access Token](/konnect-api/#konnect-api-authentication) with permission to manage the {{site.ai_gateway}} control plane and the {{site.identity}} directory.
- A {{site.identity}} directory that accepts your {{site.ai_gateway}}. The directory needs `allow_all_control_planes: true`, or your gateway listed in `allowed_control_planes` (32 maximum). An org gets one directory per region. See [Directories](/identity/directories/).
- The plaintext of every API key you want to keep, and a place to read it from, such as a secrets manager.
- The [`kongctl` CLI](/kongctl/), to export AI Consumers.
- Read [Principals](/identity/principals/) and [AI Access Management concepts](/ai-access-management/concepts/).

Set the following environment variables:

* `KONNECT_TOKEN`: The token from the prerequisites.
* `KONNECT_PROXY_URL`: The address your clients send requests to, for example `http://localhost:8000` for a local data plane.
* `AI_GATEWAY_ID` and `DIRECTORY_ID`: Captured by name in the following requests.

```sh
export KONNECT_TOKEN='YOUR-KONNECT-TOKEN'
export KONNECT_PROXY_URL='http://localhost:8000'
```

Capture the ID of your {{site.ai_gateway}} by name.
Export `AI_GATEWAY_NAME` as the name of your {{site.ai_gateway}} first:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways?page%5Bsize%5D=100
status_code: 200
method: GET
capture:
  - variable: AI_GATEWAY_ID
    command: "jq -r '.data[] | select(.name == env.AI_GATEWAY_NAME) | .id'"
{% endkonnect_api_request %}
<!--vale on-->

Capture the ID of your {{site.identity}} directory by name.
Export `DIRECTORY_NAME` as the name of your directory first:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories
status_code: 200
method: GET
capture:
  - variable: DIRECTORY_ID
    command: "jq -r '.data[] | select(.name == env.DIRECTORY_NAME) | .id'"
{% endkonnect_api_request %}
<!--vale on-->

The commands in step 2 and step 3 call a `fetch_secret` shell function to read a key's plaintext from your secret store, using the `key_ref` from the manifest.
Define the function in your shell so that it prints the key for a given `key_ref`.
For example, to read keys from AWS Secrets Manager, where each `key_ref` is a secret name:

```sh
fetch_secret() {
  aws secretsmanager get-secret-value --secret-id "$1" --query SecretString --output text
}
```

To read keys from files instead, where each `key_ref` is a filename in a directory that only you can read:

```sh
fetch_secret() {
  cat "$HOME/migration-secrets/$1"
}
```

For another secret store, replace the command with that store's CLI.
Run the step 2 loop and the step 3 key import in the same shell session so that they can call the function.

## Migration overview

By [linking a principal](/identity/principals/#principal-entity-mapping) and its AI Consumer makes every step before the last one in the migration reversible.
When a principal is linked to an AI Consumer through a `control_plane_consumer` identity, the gateway loads that AI Consumer into the request context as if it had authenticated directly. 
Policies, ACLs, AI Consumer Group membership, and per-Consumer analytics keep working while the principal does the authenticating.

In the migration, you'll build the principal side alongside the AI Consumer side, prove it works, switch traffic, move policy across, then remove the link.
Work in cohorts rather than all at once: a low-risk team or one AI Model first, then the rest.

The following table summarizes each step:

{% table %}
columns:
  - title: Step
    key: step
  - title: What you do
    key: what
  - title: Traffic impact
    key: impact
  - title: Rollback
    key: rollback
rows:
  - step: "Inventory"
    what: "Export AI Consumers, credentials, groups, and Policies. Check limits and collisions."
    impact: "None"
    rollback: "Not needed"
  - step: "Verify keys"
    what: "Prove each plaintext key authenticates as the AI Consumer it original belonged to."
    impact: "None (test entity only)"
    rollback: "Not needed"
  - step: "Create shadow principals"
    what: "Create principals, import keys, and link each to its AI Consumer and groups."
    impact: "None"
    rollback: "Delete the principals"
  - step: "Verify principals"
    what: "Prove each key authenticates against {{site.identity}}."
    impact: "None (test entity only)"
    rollback: "Not needed"
  - step: "Cut over"
    what: "Point each [AI Model](/ai-gateway/entities/ai-model/), [AI Agent](/ai-gateway/entities/ai-agent/), and [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) at a principal-backed [auth strategy](/ai-gateway/entities/ai-auth-strategy/)."
    impact: "All traffic on that entity"
    rollback: "Point it back at the old strategy"
  - step: "Move policy"
    what: "Rewrite AI Consumer- and group-scoped policy as conditions on principal metadata."
    impact: "Per policy"
    rollback: "Revert that policy"
  - step: "Unlink and soak"
    what: "Remove the AI Consumer links and group mappings, one cohort at a time."
    impact: "Per cohort"
    rollback: "Relink"
  - step: "Delete"
    what: "Delete AI Consumers, their credentials, and AI Consumer Groups."
    impact: "None if step 7 was clean"
    rollback: "None, so back up first"
{% endtable %}

### Step 1: Inventory and pre-flight

Step 1 produces a migration manifest with one row per credential, mapping each key to its AI Consumer and, later, its principal.
Nothing in this step changes configuration.

#### Build the manifest

Export your AI Consumers, their credentials and group memberships, AI Consumer Groups, AI Policies, and every AI Model, AI Agent, and AI MCP Server with its `access` block.
Use the {{site.ai_gateway}} API to list [AI Consumers](/api/konnect/ai-gateway/#/operations/list-ai-gateway-consumers), [AI Consumer Groups](/api/konnect/ai-gateway/#/operations/list-ai-gateway-consumer-groups), [AI Models](/api/konnect/ai-gateway/#/operations/list-ai-gateway-models), [AI Agents](/api/konnect/ai-gateway/#/operations/list-ai-gateway-agents), [AI MCP Servers](/api/konnect/ai-gateway/#/operations/list-ai-gateway-mcp-servers), [AI Policies](/api/konnect/ai-gateway/#/operations/list-ai-gateway-policies), and [AI Auth Strategies](/api/konnect/ai-gateway/#/operations/list-ai-gateway-auth-strategies), or run `kongctl dump declarative --resources=ai_gateways --include-child-resources --filter-name "$AI_GATEWAY_NAME" --output-file ai-gateway-dump.yaml`.
The dump includes AI Consumers, AI Consumer Groups, and credential metadata, but not key values.
Then track the migration in a manifest with one row per credential.
The following command creates `manifest.csv` with a header row for the columns, which you fill in as you go:

```sh
echo 'ai_gateway_id,consumer_id,consumer_name,custom_id,consumer_type,credential_name,ttl,key_ref,key_sha256,groups,group_ids,policies,principal_kind,principal_id,step2_ok,step4_ok' > manifest.csv
```

The columns hold the following:

- `key_ref` is where the plaintext lives, such as a secrets manager path or an environment variable name. Never write the key itself into the manifest.
- `key_sha256` is a fingerprint, so you can spot duplicates without handling plaintext.
- `group_ids` are the IDs of the AI Consumer Groups in `groups`. Step 3 needs them for the `consumer_groups` metadata key. To get a group's ID, send a `GET` request to `/v1/ai-gateways/$AI_GATEWAY_ID/consumer-groups/$GROUP_NAME` and read `id`.
- `principal_kind` is `user` (a person) or `agent` (software, including shared team keys). You fill `principal_id` and the two check columns in later steps.
- For OAuth AI Consumers, record the issuer and the claim that your OpenID Connect auth strategy maps in `consumer_claims`. The AI Consumer's `custom_id` is the value that claim carries.

If a cell holds several values, such as `groups`, separate them with semicolons so that every row keeps the same number of columns.

The step 2 loop reads a two-column file named `manifest-keys.csv`, with `consumer_name` and `key_ref` on each row.
After you fill in the manifest, create `manifest-keys.csv` from those two columns:

```sh
cut -d, -f3,8 manifest.csv | tail -n +2 > manifest-keys.csv
```

#### Pre-flight checks

Resolve every item before step 2.

- **Every key has a plaintext source.** Any credential without a `key_ref` can't move transparently. Plan a key rotation for that caller instead.
- **No duplicate keys.** API keys must be unique within a {{site.identity}} directory. Group rows by `key_sha256`. The same key for the same caller on two {{site.ai_gateway}} control planes is fine: one principal, one key, two AI Consumer links. The same key for different callers must be rotated for one of them first.
- **Five keys or fewer per caller.** A principal holds up to 5 credentials of each type and 10 identities. See [Principal limitations](/identity/principals/#principal-limitations). Consolidate any AI Consumer that has more.
- **Within directory limits.** The default is 100,000 principals per directory and 100 lookups per second that bypass the cache. Note your caller count and your data plane node count. Together they size your cutover waves in step 5. See [Directory limitations](/identity/directories/#directory-limitations).
- **The directory accepts your {{site.ai_gateway}}.** It needs `allow_all_control_planes: true` or your gateway in `allowed_control_planes`.
- **Make changes in your configuration files.** If `kongctl` or Terraform manages your {{site.ai_gateway}}, make every change in those files. Otherwise the next apply reverts it.
- **Idle AI Consumers are flagged.** Check {{site.konnect_short_name}} [Explorer](/observability/explorer/) for AI Consumers without traffic in 30 days. Delete those instead of migrating them.

Run everything that touches plaintext keys from a locked-down host, with shell history and request logging turned off.

### Step 2: Verify the keys you hold

Prove every plaintext key authenticates as the AI Consumer your manifest says owns it, before you import anything.
A stale or mislabeled key that you import onto a principal fails only at cutover, which is the worst time to find it.

The check sends each key to a throwaway AI Agent that echoes request headers.
Your existing Key Auth strategy authenticates the request and adds `X-Consumer-*` headers upstream, so the echo shows which AI Consumer the key resolved to.
No LLM is called, so it doesn't incur token costs.

#### Create the check agent

Use your current Key Auth strategy, without ACLs or Policies.
Pick a route path that no AI Model or AI MCP Server already uses.
Confirm that `hide_credentials` is `true` on that strategy first (it's the default).
Otherwise your keys are forwarded to the echo service.

Create the check agent with the AI Agents endpoint.
Export `KEY_AUTH_STRATEGY_NAME` as the name of your current Key Auth strategy first:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/agents
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: migration-consumer-check
  display_name: "Migration: Consumer key check"
  type: http
  access:
    auth_strategies:
      - $KEY_AUTH_STRATEGY_NAME
  policies: []
  config:
    url: https://httpbin.konghq.com/anything
    route:
      paths:
        - /migration-consumer-check
{% endkonnect_api_request %}
<!--vale on-->

If your data planes can't reach `httpbin.konghq.com`, or your policy forbids sending headers to a public service, set `config.url` to an internal echo service instead.

#### Run every key through the agent

The check loop calls the `fetch_secret` function from the [prerequisites](#prerequisites), so define it in your shell first.
It reads each key from your secret store, sends it once, and compares the AI Consumer the gateway resolved with the one in the manifest.
Use the header name from your strategy's `key_names`.

```sh
while IFS=, read -r consumer_name key_ref; do
  key="$(fetch_secret "$key_ref")" 
  resp=$(curl -s -w '\n%{http_code}' -H "apikey: $key" \
    "$KONNECT_PROXY_URL/migration-consumer-check")
  code=$(tail -n1 <<<"$resp")
  got=$(sed '$d' <<<"$resp" | jq -r '.headers["X-Consumer-Username"] // empty')
  if [ "$code" = 200 ] && [ "$got" = "$consumer_name" ]; then
    echo "$consumer_name,ok"
  else
    echo "$consumer_name,FAIL,$code,$got"
  fi
done < manifest-keys.csv > step2-results.csv
```

`X-Consumer-Username` carries the AI Consumer's `name`.

#### Read the results

Open the `step2-results.csv` file and look at the results.
The following table lists each result, what it means, and the fix:

{% table %}
columns:
  - title: Result
    key: result
  - title: Meaning
    key: meaning
  - title: Fix
    key: fix
rows:
  - result: "`200`, name matches"
    meaning: "The key is current and belongs to that AI Consumer."
    fix: "Set `step2_ok`."
  - result: "`200`, different name"
    meaning: "The key is valid, but your manifest has it on the wrong AI Consumer."
    fix: "Correct the manifest, then re-run that row."
  - result: "`401`"
    meaning: "The gateway doesn't recognize this key. It was probably rotated, or it's a different credential."
    fix: "Find the current key. If nobody has it, plan a rotation for that caller."
  - result: "`403` or `429`"
    meaning: "A global AI Policy (an ACL or rate limit) acted on the request."
    fix: "Exclude the check agent from that Policy, or re-run later."
{% endtable %}

Move on only when every in-scope row passes.
Each check counts as one request in that AI Consumer's analytics.

### Step 3: Create shadow principals

Create one principal per AI Consumer, import its keys, and link the two.
Traffic still authenticates through the AI Consumer until step 5, so this step can't break anything.

All calls go to the {{site.identity}} API in your directory's region and use the `$DIRECTORY_ID` from the prerequisites.

#### Determine if you need to create users or agents

You set this with the principal's `type` field when you create it, and you can't change it afterward.
Choose the type that matches the AI Consumer:

- **User (`"type": "user"`):** The AI Consumer represents one person. Users appear in AI Access Management, can join groups, and carry spend limits. See [AI Access Management concepts](/ai-access-management/concepts/).
- **Agent (`"type": "agent"`):** The AI Consumer represents software, such as a service, a pipeline, a coding agent, or a key shared by a team. A shared team key stays one agent for now. Giving each person their own user and key is a separate project, after this migration.

#### Create the principal with its metadata

Create one principal for each AI Consumer in your manifest.
Set the principal's metadata to the AI Consumer's AI Consumer Group IDs, plus the AI Consumer's ID and name.

First, capture the ID of the AI Consumer.
Export `CONSUMER_NAME` as a name from your manifest first:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/consumers/$CONSUMER_NAME
status_code: 200
method: GET
capture:
  - variable: CONSUMER_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

Then capture the ID of the AI Consumer Group that the AI Consumer belongs to.
Export `GROUP_NAME` as a group from your manifest first:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/consumer-groups/$GROUP_NAME
status_code: 200
method: GET
capture:
  - variable: GROUP_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

Create the principal and capture its ID:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  display_name: $CONSUMER_NAME
  description: Migrated from AI Consumer $CONSUMER_NAME
  type: agent
  metadata:
    legacy_consumer_id: $CONSUMER_ID
    legacy_consumer_name: $CONSUMER_NAME
    tier: gold
    team: mobile
    consumer_groups:
      - $GROUP_ID
capture:
  - variable: PRINCIPAL_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

In this request:

- `type` comes from `principal_kind` in the manifest.
- `consumer_groups` is a reserved metadata key. It keeps the principal in its AI Consumer Groups after you unlink the AI Consumer in step 7. See [Principal entity mapping](/identity/principals/#principal-entity-mapping).
  Its values are the AI Consumer Group IDs from `group_ids`.
  <!-- TODO: The original draft said consumer_groups must hold runtime Kong Consumer Group IDs, not AI Consumer Group IDs. In testing on 2.3.2, a principal with an AI Consumer Group ID in consumer_groups passed a gold-only ACL, while a different group's ID and a made-up ID were denied. The API also doesn't expose any runtime group ID. Confirm that AI Consumer Group IDs are the intended value before publishing. -->
- Turn each group that expresses a tier, team, or budget into a plain attribute (`tier`, `team`) now. Step 6 Policies read these attributes directly.
- A principal holds up to 50 metadata keys.

#### Import each key

Import the same value the client already sends.
{{site.konnect_short_name}} stores only a salted one-way hash, so after this call your secret store is the only place the plaintext exists.

Import each credential in your manifest separately.
Repeat this section once for every credential row. 

Get `KEY_REF` and `CREDENTIAL_NAME` from the `key_ref` and `credential_name` columns of that row in your manifest, and read the key from your secret store:

```sh
export KEY_REF='YOUR-KEY-REF'
export CREDENTIAL_NAME='YOUR-CREDENTIAL-NAME'
export KEY="$(fetch_secret "$KEY_REF")"
```

Import the key.
The request writes the response to `/dev/null` because the response echoes the key back:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals/$PRINCIPAL_ID/api-keys
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
output: /dev/null
body:
  type: imported
  name: $CREDENTIAL_NAME
  secret: $KEY
{% endkonnect_api_request %}
<!--vale on-->

After the request succeeds, remove the key from your shell environment:

```sh
unset KEY
```

In this request:

- The key value goes in `secret`. `name` is optional. Reusing the credential's name keeps the two easy to match.
- If the AI Consumer's credential expires, add `expires_at` to the request body with the same time as an ISO-8601 timestamp, for example `2027-03-01T00:00:00Z`. Omit it for keys that don't expire.

A rejection for a duplicate means another principal already holds that key.
Go back to the duplicate-key check in step 1.

#### Link the principal to its AI Consumer

Link each principal to its AI Consumer by adding a `control_plane_consumer` identity to the principal. 
When a request authenticates as the principal, {{site.ai_gateway}} loads the linked AI Consumer into the request context, so AI Consumer-scoped Policies, ACLs, and analytics keep working.

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals/$PRINCIPAL_ID/identities
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  type: control_plane_consumer
  control_plane_id: $AI_GATEWAY_ID
  consumer_id: $CONSUMER_ID
{% endkonnect_api_request %}
<!--vale on-->

`control_plane_id` is the ID of the {{site.ai_gateway}} (`$AI_GATEWAY_ID`).
A principal links to at most one AI Consumer per {{site.ai_gateway}}.
If the same caller exists on several {{site.ai_gateway}} control planes, add one link per control plane, each with that control plane's ID.

#### Add an OIDC identity for OAuth AI Consumers

For AI Consumers that authenticate with a token, add an OIDC identity that matches what your OpenID Connect auth strategy maps: the strategy's issuer, the claim in `consumer_claims`, and the AI Consumer's `custom_id` as the value.

Capture the issuer from the strategy.
Export `OIDC_STRATEGY_NAME` as the name of your OpenID Connect auth strategy first:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/auth-strategies/$OIDC_STRATEGY_NAME
status_code: 200
method: GET
capture:
  - variable: ISSUER_URL
    jq: ".config.issuer"
{% endkonnect_api_request %}
<!--vale on-->

Capture the `custom_id` from the AI Consumer.
Export `OAUTH_CONSUMER_NAME` as the name of the AI Consumer first:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/consumers/$OAUTH_CONSUMER_NAME
status_code: 200
method: GET
capture:
  - variable: CUSTOM_ID
    jq: ".custom_id"
{% endkonnect_api_request %}
<!--vale on-->

Then create the identity:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals/$PRINCIPAL_ID/identities
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  type: oidc
  issuer: $ISSUER_URL
  claim:
    name: sub
    value: $CUSTOM_ID
{% endkonnect_api_request %}
<!--vale on-->

The issuer must match the token's `iss` claim exactly, including any trailing slash.
Then add the `control_plane_consumer` link as well.

#### Record the principal ID

Write `principal_id` into the manifest.
Make your script skip rows that already have one, so you can safely re-run it after a partial failure.

### Step 4: Verify principals before cutover

Run every key through {{site.identity}} on a test entity and expect a pass for each one.
This is the same check as step 2, pointed at a principal-backed auth strategy instead of the AI Consumer one.

#### Shorten the negative cache

By default, a gateway caches a failed lookup for 10 minutes, so a key you fix keeps failing until the cache expires.
Lower `negative_ttl_secs` to its 300-second minimum for the migration.
See [Lookup caching](/identity/directories/#lookup-caching).

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID
status_code: 200
method: PATCH
headers:
  - 'Content-Type: application/json'
body:
  negative_ttl_secs: 300
{% endkonnect_api_request %}
<!--vale on-->

#### Create the principal-backed Key Auth strategy

Create a new strategy rather than editing your current one, so production is untouched.
Copy `key_names`, `key_in_header`, `key_in_query`, and `key_in_body` exactly from your current strategy.
Clients keep working unchanged only if the key is read from the same place.

The strategy refers to the directory by name.
Capture the name from the directory ID:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID
status_code: 200
method: GET
capture:
  - variable: DIRECTORY_NAME
    jq: ".name"
{% endkonnect_api_request %}
<!--vale on-->

Then create the strategy:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/auth-strategies
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: kong-identity-key-auth
  display_name: Kong Identity key auth
  type: key-auth
  config:
    key_names:
      - apikey
    key_in_header: true
    key_in_query: true
    hide_credentials: true
    identity_realms: []
    principals:
      enabled: true
      directory: $DIRECTORY_NAME
{% endkonnect_api_request %}
<!--vale on-->

Principal mapping can't be combined with `identity_realms`, which is why that list is empty.
See [Configure dynamic Policy config with CEL in {{site.ai_gateway}}](/ai-gateway/configure-dynamic-plugin-config-with-cel/).

{:.danger}
> **Leave `principals.error_on_miss` at its default (`true`), and never set it to `false` on a Key Auth strategy.**
> With `false`, a key that {{site.identity}} doesn't recognize isn't rejected.
> The request is processed without an AI Consumer and without a principal, or as the anonymous AI Consumer if the strategy has one.
> Any key, including a made-up one, is then sent to your upstreams.
> A request without a key is still rejected.
> <!-- TODO (Andrew): The original draft said Key-Auth clears any client-supplied Consumer headers in this case. In testing on 2.3.2, a made-up key with error_on_miss set to false was forwarded upstream together with a client-supplied X-Consumer-Username header. Confirm the intended behavior before adding any statement about headers. -->

When a key resolves to a principal with an AI Consumer link, Key-Auth binds the linked AI Consumer as it does for a direct AI Consumer key, and sets `X-Consumer-ID`, `X-Consumer-Custom-ID`, and `X-Consumer-Username` wherever the AI Consumer has those values.
That's why the step 2 check works unchanged here.

#### Create a second check agent and run the keys

Create a second check agent named `migration-principal-check`.
It matches the step 2 agent, except that it uses the `kong-identity-key-auth` strategy and its own route path:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/agents
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: migration-principal-check
  display_name: "Migration: Principal key check"
  type: http
  access:
    auth_strategies:
      - kong-identity-key-auth
  policies: []
  config:
    url: https://httpbin.konghq.com/anything
    route:
      paths:
        - /migration-principal-check
{% endkonnect_api_request %}
<!--vale on-->

Then run the check loop from step 2 against the new route, and write the results to `step4-results.csv`.
Define `fetch_secret` in your shell first, as in step 2:

```sh
while IFS=, read -r consumer_name key_ref; do
  key="$(fetch_secret "$key_ref")"
  resp=$(curl -s -w '\n%{http_code}' -H "apikey: $key" \
    "$KONNECT_PROXY_URL/migration-principal-check")
  code=$(tail -n1 <<<"$resp")
  got=$(sed '$d' <<<"$resp" | jq -r '.headers["X-Consumer-Username"] // empty')
  if [ "$code" = 200 ] && [ "$got" = "$consumer_name" ]; then
    echo "$consumer_name,ok"
  else
    echo "$consumer_name,FAIL,$code,$got"
  fi
done < manifest-keys.csv > step4-results.csv
```

The following table lists the possible results:

{% table %}
columns:
  - title: Result
    key: result
  - title: Meaning
    key: meaning
rows:
  - result: "`200`, `X-Consumer-Username` matches"
    meaning: "The key resolved to a principal, and the link loaded the right AI Consumer. Set `step4_ok`."
  - result: "`200`, no `X-Consumer-Username`"
    meaning: "The key resolved to a principal, but the AI Consumer link is missing or points at the wrong control plane. Recheck the link in step 3. If this happens for every key, check that `error_on_miss` hasn't been set to `false`."
  - result: "`401`"
    meaning: "The key isn't in the directory, or this gateway isn't allowed to use the directory. Fix it, wait out the negative cache, then retry."
{% endtable %}

Keys are unique within a directory, so a `200` can only mean the principal you imported that key onto.

#### Check OIDC callers

For OAuth AI Consumers, get a token for one test client per issuer and confirm the OIDC identity matches its claim.
The live check happens in step 5, because a gateway uses a single OpenID Connect auth strategy for its AI Models.

### Step 5: Cut over authentication

Cut over by swapping each entity's Key Auth strategy reference from your current strategy to `kong-identity-key-auth`.
Clients send the same key to the same place, and the linked AI Consumer keeps every existing Policy in force.
To roll back, make the same swap in reverse.

An AI Model takes one Key Auth strategy and one OpenID Connect auth strategy.
An AI Agent or AI MCP Server takes one strategy in total, see [Assigning an AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/#assigning-an-ai-auth-strategy).
You can't run both key-auth strategies on one entity at once, so swap one entity at a time to limit the impact.

#### API key callers

Cut over API key callers in waves, starting with a canary:

1. **Pick a canary.** Choose one low-traffic AI Model, AI Agent, or AI MCP Server whose callers all passed step 4.
1. **Swap the reference.** Only replace the old strategy in its `access.auth_strategies` with `kong-identity-key-auth`. If `kongctl` or Terraform manages it, make the change there.
1. **Watch for an hour.** In {{site.konnect_short_name}} Explorer, compare the entity's `401` rate and request volume to the previous hour. Per-Consumer analytics should be unchanged, because the link still loads each AI Consumer.
1. **Continue in waves.** Move the remaining entities in batches. A directory serves 100 lookups per second that bypass the cache, and each data plane node keeps its own cache. See [Directory limitations](/identity/directories/#directory-limitations). A caller's first request on each node is a separate lookup that bypasses the cache: with 10 nodes behind a load balancer, one wave of 50 callers can cause up to 500 lookups. Size each wave by callers multiplied by nodes, and keep the number of simultaneous lookups well under the limit.

To swap the reference through the API, send a `PUT` request with the entity's full body.
`PATCH` isn't supported.
First, read the entity.
The following request reads an AI Agent named `orders-agent`.
Use `models` or `mcp-servers` in place of `agents` for AI Models and AI MCP Servers:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/agents/orders-agent
status_code: 200
method: GET
{% endkonnect_api_request %}
<!--vale on-->

Then send the body back with `kong-identity-key-auth` in place of the old strategy.
Remove the read-only `id`, `created_at`, and `updated_at` fields and the deprecated `access.identity_providers` field, and keep every other field from the response.
The following example is the body for the `orders-agent` AI Agent:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/agents/orders-agent
status_code: 200
method: PUT
headers:
  - 'Content-Type: application/json'
body:
  name: orders-agent
  display_name: Orders agent
  type: http
  enabled: true
  policies: []
  access:
    auth_strategies:
      - kong-identity-key-auth
  config:
    url: https://httpbin.konghq.com/anything
    route:
      paths:
        - /orders-agent
{% endkonnect_api_request %}
<!--vale on-->

You can instead enable `principals` on your existing strategy, which cuts over every entity that references it in one change.
That's faster but leaves no canary, so reserve it for small gateways.
The same `error_on_miss` rule applies: leave it at `true`.

#### OIDC callers

An OpenID Connect auth strategy can map to a principal and an AI Consumer at the same time.
With `match_consumer` (on by default), a [matched principal](/ai-gateway/entities/ai-auth-strategy/#principal-mapping) loads its linked AI Consumer.
Add principal mapping to your existing strategy, with `error_on_miss: false` so tokens without a principal still authenticate through `consumer_claims` as they do without principal mapping.

Updating a strategy takes a `PUT` request with the full body.
Read the current body with a `GET` request to `/v1/ai-gateways/$AI_GATEWAY_ID/auth-strategies/$OIDC_STRATEGY_NAME`.
The response doesn't include write-only fields such as `client_secret`, so add the secret to the body again.
Set the secret from your secret store first:

```sh
export CLIENT_SECRET='YOUR-OIDC-CLIENT-SECRET'
```

Then send the full body with `principals` added.
The following example updates an OpenID Connect auth strategy named `legacy-oidc`.
Copy the other fields from your `GET` response:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/auth-strategies/legacy-oidc
status_code: 200
method: PUT
headers:
  - 'Content-Type: application/json'
body:
  name: legacy-oidc
  display_name: Legacy OIDC
  type: openid-connect
  config:
    issuer: $ISSUER_URL
    client_id:
      - $CLIENT_ID
    client_secret:
      - $CLIENT_SECRET
    auth_methods:
      - bearer
    scopes:
      - my-scope
    consumer_claims:
      - - sub
    cache_tokens_salt: legacy-oidc-salt
    principals:
      enabled: true
      directory: $DIRECTORY_NAME
      error_on_miss: false
{% endkonnect_api_request %}
<!--vale on-->

Invalid tokens are still rejected.
`error_on_miss` only affects valid tokens without a matching principal, see [Default termination behavior](/ai-gateway/entities/ai-auth-strategy/#default-termination-behavior).
For those tokens, the plugin falls back to `consumer_claims`: if the claim matches an AI Consumer, the request is mapped to that AI Consumer without an authenticated principal, the same as before you enabled principal mapping.
You set `error_on_miss` back to `true` in step 8, after you remove `consumer_claims`.

`X-Consumer-*` headers are set for an OIDC caller only when `match_consumer` is on and the principal's linked AI Consumer loads.
If you've turned `match_consumer` off, or the link is missing, the request still authenticates as the principal, but anything upstream that reads those headers doesn't get values.

#### Rollback

To roll back the cutover, undo whichever change you made in this step:

- For Key Auth, set the AI Model, AI Agent, or AI MCP Server back to the old Key Auth strategy.
- For OIDC, update the OpenID Connect auth strategy to remove `principals`.

The AI Consumers and their credentials still exist, so the old configuration applies again as soon as the data planes receive the update.
Clients keep using the same keys and tokens.

### Step 6: Move policy off AI Consumers and groups

Rewrite everything that names an AI Consumer or AI Consumer Group so that it reads principal attributes instead.
While the links are in place, `consumer.*` and `consumer_group.*` still resolve, so you can make this change one Policy at a time.
The following table maps each AI Consumer-scoped rule to its replacement:

{% table %}
columns:
  - title: What you have
    key: today
  - title: What replaces it
    key: replacement
rows:
  - today: "An AI Policy in an AI Consumer's `policies` list"
    replacement: "The same Policy on the AI Model, AI Agent, or AI MCP Server (or global), with a `condition` such as `principal.id == \"YOUR-PRINCIPAL-ID\"`"
  - today: "An AI Policy attached to an AI Consumer Group"
    replacement: "The same Policy with a metadata condition: `has(principal.metadata.tier) && principal.metadata.tier == \"gold\"`"
  - today: "A `condition` that reads `consumer.username` or `consumer_group.names`"
    replacement: "The same condition rewritten against `principal.id` or `principal.metadata`. See [AI Policy conditions](/ai-gateway/conditions/)."
  - today: "`access.acls` `allow` or `deny` lists of AI Consumers or groups"
    replacement: "`access.acls.allow_when` or `deny_when` with a CEL expression on `principal.id` or `principal.metadata`. This works the same on AI Models, AI Agents, and AI MCP Servers."
  - today: "Per-tier rate limit Policies, one per AI Consumer Group"
    replacement: "One [Rate Limiting Advanced Policy](/ai-gateway/policies/rate-limiting-advanced/) (type `rate-limiting-advanced`) with `identifier: principal` and `expressions.limit` read from `principal.metadata`. The [AI Rate Limiting Advanced Policy](/ai-gateway/policies/ai-rate-limiting-advanced/) doesn't support `expressions`. See [Configure dynamic Policy config with CEL in {{site.ai_gateway}}](/ai-gateway/configure-dynamic-plugin-config-with-cel/)."
{% endtable %}

#### Rules for writing conditions

Follow these rules when you write a condition:

- **Always guard metadata with `has()`.** Reading a metadata key that a principal doesn't have is a runtime error, and the data plane returns a `500` for that request. Write `has(principal.metadata.tier) && principal.metadata.tier == "gold"`, never the bare comparison.
- **Prefer one Policy with expressions over many conditioned copies.** An AI Consumer-scoped Policy overrides the same Policy type at a broader scope. A condition doesn't recreate that override: If the most specific Policy's condition is false, {{site.ai_gateway}} skips it and doesn't fall back to a broader one. A single Policy whose limit comes from metadata avoids the problem.
- **Order ACL entries deliberately.** `allow_when` entries are evaluated in order, and an entry that fails to evaluate can deny the request or fail it with a `500`. See [CEL-based ACLs](/ai-gateway/entities/ai-model/#cel-based-acls). Guard every entry with `has()`.

#### Avoid double enforcement

For limits, budgets, and guardrails, swap the old Policy for the new one in a single update.
If both run during an overlap, callers hit the stricter of the two, or are counted twice.

Rate limit counters keyed by AI Consumer aren't transferred to counters keyed by principal.
Make the swap at a window boundary, especially for daily or monthly token budgets.
Otherwise a caller near their limit starts again from zero.

#### Check before moving on

Before you continue to step 7, migrate every AI Policy, condition, and ACL that references an AI Consumer or AI Consumer Group by name or ID, so that none of them still do.
The only exception is the `consumer_groups` metadata key, if you've chosen to keep using AI Consumer Groups.

### Step 7: Unlink and soak

Remove the AI Consumer links one cohort at a time and confirm that nothing changes.
Gateway behavior should be identical with and without the link, because step 6 moved every rule onto the principal.
If behavior changes, something still depends on an AI Consumer: relink and fix it.

1. **Unlink.** Delete each principal's `control_plane_consumer` identity. If you're also retiring AI Consumer Groups, remove the `consumer_groups` metadata key in the same pass. Get the principal ID from your manifest, then capture the identity ID and delete the identity:

   <!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals/$PRINCIPAL_ID/identities
status_code: 200
method: GET
capture:
  - variable: IDENTITY_ID
    command: "jq -r '.data[] | select(.type == \"control_plane_consumer\") | .id'"
indent: 3
{% endkonnect_api_request %}
   <!--vale on-->

   <!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals/$PRINCIPAL_ID/identities/$IDENTITY_ID
status_code: 204
method: DELETE
indent: 3
{% endkonnect_api_request %}
   <!--vale on-->
1. **Wait for the cache to expire.** Data planes keep a principal, link included, for the directory's `ttl_secs`: 10 minutes by default. Verify the change only after that.
1. **Watch the same signals as step 5.** Look at `401` and `403` rates, rate limit headers on a sample of callers, and guardrail and ACL outcomes. In AI Policy conditions, `consumer.*` fields now evaluate to `null` for this cohort, so any condition that still reads them stops matching without an error.
1. **Soak.** Leave each cohort unlinked for at least 7 days. Make it longer for callers with weekly or monthly jobs, so every pattern has run at least once.

After unlinking, new usage is attributed to principals instead of AI Consumers.
Use the `legacy_consumer_id` metadata to join reports across the cutover.

To roll back, re-add the `control_plane_consumer` identity from step 3.
The AI Consumer loads again on that principal's next lookup, after the cache expires.

### Step 8: Delete AI Consumers and AI Consumer Groups

Delete a cohort's AI Consumers only after its soak shows zero traffic attributed to them.
This is the one step you can't undo: after an AI Consumer and its credentials are deleted, your secret store and the principal's hashed copy are the only record of each key.

#### Before you delete

Complete the following before you delete anything:

- Export the cohort's AI Consumers, credentials, AI Consumer Groups, and any AI Consumer-scoped AI Policies, and keep the export with the manifest. For the AI Consumers, use `kongctl dump declarative --resources=ai_gateways --include-child-resources --filter-name "$AI_GATEWAY_NAME"`. The dump holds configuration only: {{site.konnect_short_name}} can't return generated API key secrets, so the plaintext keys exist only in your secret store.
- Confirm in {{site.konnect_short_name}} Explorer that the cohort's AI Consumers received no requests during the soak.
- Confirm that no AI Policy, condition, or ACL references them (run the step 6 check again). The AI Rate Limiting Advanced Policy still relies on AI Consumer Groups. See [Known issues](#known-issues).

#### Delete in this order

Delete the following, in this order:

1. AI Policies that were attached only to these AI Consumers or groups. They no longer run for anyone.
1. The AI Consumers. Remove them from your `kongctl` or Terraform files in the same change, so the next apply doesn't recreate them.
1. AI Consumer Groups that are now empty and not referenced. Check that no principal's `consumer_groups` metadata still holds the group's ID.
1. The two check agents from steps 2 and 4. The step 2 agent still references the old Key Auth strategy, so delete it first.
1. The old Key Auth strategy, after no entity references it. To see what still uses it, send a `GET` request to `/v1/ai-gateways/$AI_GATEWAY_ID/auth-strategies/$KEY_AUTH_STRATEGY_NAME/usage`.

#### Finish the auth configuration

After you delete the AI Consumers, make the following changes:

- **OIDC:** After every OAuth AI Consumer is gone, remove `consumer_claims` from the OpenID Connect auth strategy and set `principals.error_on_miss` to `true`. From then on, a valid token without a matching principal is rejected.
- **Directory:** Set `negative_ttl_secs` back to your preferred value (600 seconds is the default).

## Known issues

The AI Rate Limiting Advanced Policy can't be applied to groups in AI Access Management.
Until that's supported, use AI Consumer Groups for this Policy.

## Troubleshooting

Most failures come from one of three causes: a cache that hasn't expired yet, a key read from a different place than before, or a rule that still references an AI Consumer.
The following table lists common symptoms, their likely causes, and the fixes:

{% table %}
columns:
  - title: Symptom
    key: symptom
  - title: Likely cause
    key: cause
  - title: Fix
    key: fix
rows:
  - symptom: "Step 2 returns `401`"
    cause: "The key you hold isn't the AI Consumer's current credential."
    fix: "Look for a rotated or second credential. If nobody has the current key, plan a rotation for that caller."
  - symptom: "Step 2 returns `200` with a different AI Consumer name"
    cause: "The manifest maps the key to the wrong AI Consumer."
    fix: "Correct the manifest before importing."
  - symptom: "Key import is rejected as a duplicate"
    cause: "Another principal in the directory already holds that key."
    fix: "Find the matching `key_sha256` in the manifest and rotate one of the two keys."
  - symptom: "`401` after you fixed a key"
    cause: "The data plane cached the failed lookup."
    fix: "Wait for `negative_ttl_secs` (300 seconds minimum), then retry."
  - symptom: "Every caller gets `401` after cutover"
    cause: "The new strategy reads the key from a different header or parameter, the directory name is wrong, or the directory doesn't allow this gateway."
    fix: "Roll back. Compare `key_names` and `key_in_*` with the old strategy, and check `allowed_control_planes`."
  - symptom: "`500` with \"error evaluating plugin condition\""
    cause: "A condition reads a metadata key that the principal doesn't have."
    fix: "Guard it with `has()`."
  - symptom: "`403` after changing an ACL to `allow_when`"
    cause: "An entry failed to evaluate, or a data plane older than {{site.ai_gateway}} 2.3 skipped the configuration."
    fix: "Add `has()` guards. Check the data plane's compatibility status."
  - symptom: "A Policy stops applying after unlinking"
    cause: "It's still scoped to an AI Consumer or group, or its condition reads `consumer.*`."
    fix: "Relink, finish step 6 for that Policy, then unlink again."
  - symptom: "A metadata change doesn't take effect yet"
    cause: "The principal is still cached on the data plane."
    fix: "Wait up to the directory's `ttl_secs` (600 seconds by default)."
  - symptom: "A spike of slow first requests or lookup errors at cutover"
    cause: "Too many lookups that bypass the cache at once against the 100-per-second directory limit. Each data plane node looks up a caller separately."
    fix: "Roll back that wave and cut over in smaller batches, sized by callers multiplied by nodes."
  - symptom: "Unknown or made-up keys get `200`"
    cause: "`principals.error_on_miss` is `false` on a Key Auth strategy, so an unrecognized key is processed without an identity."
    fix: "Set it back to `true` immediately."
  - symptom: "Principal isn't in its AI Consumer Group after unlinking"
    cause: "The `consumer_groups` metadata key is missing, or it holds a value that isn't an AI Consumer Group ID from this {{site.ai_gateway}}."
    fix: "Set it to the AI Consumer Group IDs from the `group_ids` column of the manifest."
{% endtable %}
