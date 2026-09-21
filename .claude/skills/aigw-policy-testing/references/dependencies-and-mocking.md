# Dependencies, the Docker network, and mocking third-party backends

## Starting AI Gateway with a chosen name, and fetching the Docker network

Ask the user two things before writing this step, rather than assuming either:

1. **The `-a` name.** Suggest the convention already used elsewhere: `ai-quickstart-<name>`
   (e.g. `ai-quickstart-prompt-guard-test`). The script deletes any existing AI Gateway
   with that name first, so it must not collide with a gateway the user still wants.
2. **Which Konnect domain**: production (`konghq.com`, the default) or the prerelease
   test domain (`konghq.tech`). Only use `.tech` if they ask for it — it targets
   unreleased builds and needs `DEBUG=true` plus a local `./quickstart` checkout, see
   `aigw-doc-testing`'s `references/deploy-and-tooling.md` for the full prerelease flow.

```bash
export KONNECT_TOKEN='<your PAT>'
export AIGW_APP_NAME='ai-quickstart-<name>'   # the name the user picked
curl -Ls https://get.konghq.com/ai | bash -s -- -k "$KONNECT_TOKEN" -a "$AIGW_APP_NAME"

# Capture the printed values (adjust to what actually printed):
export AI_GATEWAY_ID="<printed AI_GATEWAY_ID>"
export KONNECT_CONTROL_PLANE_NAME="$AIGW_APP_NAME"
export KONNECT_CONTROL_PLANE_URL=https://us.api.konghq.com
export KONNECT_PROXY_URL='http://localhost:8000'
```

For the `.tech` domain instead, run with `KONNECT_DOMAIN=konghq.tech` and correct the
printed `KONNECT_CONTROL_PLANE_URL` by hand (it always prints `.com`, a known script bug):

```bash
DEBUG=true KONNECT_DOMAIN=konghq.tech sh ai/index -k "$KONNECT_TOKEN" -a "$AIGW_APP_NAME"
export KONNECT_CONTROL_PLANE_URL=https://us.api.konghq.tech
```

**Only fetch the Docker network at all if a later step actually starts another
container** (a vectordb, a mock webhook, a local LLM backend). Most policies don't need
one — don't add this as a rote "standard practice" step when nothing downstream uses it.

When a later step does need it, fetch the real network name from the running gateway
container immediately before that step, rather than assuming a naming pattern (the
quickstart script's internal naming is an implementation detail that can change):

```bash
export KONG_DOCKER_NETWORK=$(docker inspect "${AIGW_APP_NAME}-gateway" \
  --format '{{range $net, $_ := .NetworkSettings.Networks}}{{$net}}{{end}}')
echo "$KONG_DOCKER_NETWORK"   # confirm it's non-empty before using it
```

Always use `$KONG_DOCKER_NETWORK` (never a hardcoded network name) when starting that
other container — that's what lets the AI Gateway data-plane container reach it by
container name.

The classic Kong Admin API is **not** exposed on the AI Gateway 2.0 data-plane image. If
a runbook step needs to inspect config or logs, use `docker logs <gw-container>` or the
Konnect API (`GET /v1/ai-gateways/{id}/nodes`), never `curl localhost:8001`.

## kongctl config and apply

Apply the declarative config **inline**, piping the YAML straight into
`kongctl apply -f -` via a heredoc, rather than writing an intermediate `.yaml` file to
disk first — one fewer artifact for the reader to manage, and it's the same pattern real
how-tos render from an `entity_examples` block. **Keep `!ref` and `!lookup` as real
kongctl YAML tags** — they're kongctl features (not Jekyll rendering), so the runbook
should exercise them for real rather than pre-resolving them to literal values:

```bash
export OPENAI_API_KEY='<your OpenAI API key>'
export OPENAI_AUTH_HEADER="Bearer $OPENAI_API_KEY"

kongctl apply -f - --pat "$KONNECT_TOKEN" --auto-approve <<'EOF'
ai_gateway_model_providers:
  - ref: my-openai
    name: my-openai
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !secret {source: !env OPENAI_AUTH_HEADER}
ai_gateway_policies:
  - ref: my-<policy-slug>
    name: my-<policy-slug>
    display_name: my-<policy-slug>
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    type: <policy-slug>
    enabled: true
    global: false
    config:
      # fields from Step 1's schema read, not memory
ai_gateway_models:
  - ref: my-model
    name: my-model
    display_name: my-model
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    type: model
    enabled: true
    formats: [{ type: openai }]
    config:
      route:
        paths: ["/"]
    capabilities: [generate]
    policies: [ !ref my-<policy-slug>#name ]
    targets:
      - name: gpt-4o-mini
        provider: my-openai
        config:
          type: openai
EOF
```

Note the scoping rule: `!ref my-<policy-slug>#name` only resolves because the Policy and
the Model that references it are declared in the **same** `kongctl apply` file/block. If
a runbook step ever needs to attach to an entity created in an *earlier*, separate apply,
use `!lookup {id: !env SOME_ID}` instead — never split a same-file `!ref` across two
applies expecting it to still resolve.

**`display_name` is required on `ai_gateway_policies` and `ai_gateway_models` entries**,
confirmed live: omitting it fails apply with `missing required fields: display_name`
against `CreateAIGatewayModelRequest`/the policy's equivalent create request, even
though the field doesn't otherwise do anything for a throwaway test entity. Always set
it (same value as `name` is fine). `ai_gateway_model_providers` doesn't need it — match
the real published example (`use-ai-prompt-guard-policy.md`) rather than assuming the
same requirement applies uniformly across every entity type.

## Kong's own schema DSL (`version: kong`) is not JSON Schema

Request Validator's `config.body_schema`/`config.parameter_schema` with `version: kong`
(the default) uses Kong's own Lua-style schema DSL, not JSON Schema — a field of
`type: array` **must** declare an `elements` sub-schema, or `kongctl apply` fails live
with `schema violation (<field>: field of type 'array' must declare 'elements')`.
Likewise `type: record` needs `fields` (an array of single-key `{field_name: {type:
...}}` objects) and `type: map` needs `keys`/`values`. Confirm the exact DSL shape in
`app/_kong_plugins/request-validator/index.md` (the "Array"/"Record"/"Map" tabs) before
writing a `body_schema`/`parameter_schema` — don't assume plain JSON Schema syntax works
just because the value looks like JSON.

## Default LLM backend: OpenAI

Default every runbook's AI Model Provider to a real OpenAI account
(`app/_includes/md/ai-gateway/v2/prereqs/openai-kongctl.md`) unless the user asks for a
different provider or the policy under test only supports a specific one (check the
schema/provider docs for that). This matches what every other published v2 how-to
assumes, keeps the runbook's prerequisites list short and familiar, and avoids a second
"which local LLM" decision on top of the "which policy" one.

```bash
export OPENAI_API_KEY='<YOUR_OPENAI_API_KEY>'
export OPENAI_AUTH_HEADER="Bearer $OPENAI_API_KEY"
```

Verify the exact `targets[].config` field names for whichever provider you use
(`app/ai-gateway/ai-providers/<provider>.md`, `app/_ai_gateway_entities/ai-model.md`)
before relying on the example above — provider config shapes are documented per-provider
and do shift.

## `vectordb`-backed policies need Redis **Stack**, not plain Redis

AI RAG Injector, AI Semantic Cache, AI Semantic Prompt Guard, and AI Semantic Response
Guard all have a `config.vectordb` block. Plain `redis-server` (including Homebrew's) is
missing the RediSearch module and fails index creation — use Redis Stack, on the same
network:

```bash
docker run -d --name redis-stack --network "$KONG_DOCKER_NETWORK" -p 6379:6379 redis/redis-stack-server:latest
```

Point `config.vectordb` at `{ strategy: redis, redis: { host: redis-stack, port: 6379 } }`
(container name, not `localhost`, since the gateway reaches it over `$KONG_DOCKER_NETWORK`).

**Don't trust a `200` alone as validation for these policies.** With `stop_on_failure:
false` (the schema default for at least AI RAG Injector), a broken vector index still
returns a normal response — it silently skips retrieval/grounding. The runbook's Validate
step for these policies must also grep the data-plane container's logs for the policy's
own warn/error line (`docker logs <gw-container> | grep -i <policy-slug>`) and/or query
the index directly (`redis-cli -h localhost FT.INFO idx:vss_<policy-slug>`) to confirm
retrieval actually happened, not just that the request didn't error.

## Webhook-shaped guardrails: mock the endpoint locally

AI Custom Guardrail (and similar `request`/`response`-shaped policies) calls an
arbitrary URL you configure in `config.request.url` — this is trivial to mock locally
instead of standing up a real backend service. A tiny local HTTP responder on the same
network is enough to prove the policy calls out correctly and handles the response:

```bash
docker run -d --name guardrail-mock --network "$KONG_DOCKER_NETWORK" \
  -p 8080:8080 mendhak/http-https-echo
```

Point `config.request.url` at `http://guardrail-mock:8080/` and check the mock's own logs
(`docker logs guardrail-mock`) as part of Validate, to confirm the policy actually sent
the expected request shape — not just that the overall proxy call succeeded.

## No local stand-in exists for these — say so plainly in the runbook

Some policies wrap a specific third-party managed service and have no meaningful local
mock, because the point of testing them *is* confirming real integration with that
service:

- **AI AWS Guardrails** — needs a real `guardrails_id` in an AWS account plus
  `aws_access_key_id`/`aws_secret_access_key` (or an assumable role).
- **AI Azure Content Safety** — needs a real Azure Content Safety resource + key.
- **AI GCP Model Armor** — needs a real GCP project with Model Armor enabled.
- **AI Lakera Guard** — needs a real Lakera API key.
- **AI NVIDIA NeMo Guardrail** — needs a running NeMo Guardrails service (this one *can*
  run locally in Docker if the user has the NeMo config — check with them rather than
  assuming).

For these, the runbook's prerequisites section must name the credential/resource plainly
and note there's no cheaper local alternative — don't invent a fake stand-in that would
give a false pass/fail.
