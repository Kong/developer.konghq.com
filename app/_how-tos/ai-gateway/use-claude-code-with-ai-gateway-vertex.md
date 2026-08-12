---
title: Route Claude CLI traffic through {{site.ai_gateway}} and Vertex AI
permalink: /ai-gateway/use-claude-code-with-ai-gateway-vertex/
content_type: how_to

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/

description: Configure {{site.ai_gateway}} to proxy Claude CLI traffic using Google Vertex AI models

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kongctl

min_version:
  ai-gateway: '2.0'

tags:
  - ai
  - vertex-ai

tldr:
  q: How do I run Claude CLI through {{site.ai_gateway}} for a Claude model hosted on Google Vertex AI?
  a: Create an AI Model Provider entity to authenticate to Google Vertex AI, add a Policy to strip Anthropic-only request fields Vertex doesn't support, create an AI Model entity that accepts Anthropic-compatible requests and targets your Vertex model. Then, point Claude CLI’s `ANTHROPIC_BASE_URL` at your local {{site.ai_gateway}} endpoint so all requests are proxied for monitoring and control.

prereqs:
  konnect:
     - name: KONG_NGINX_HTTP_CLIENT_BODY_BUFFER_SIZE
       value: 2m
  inline:
    - title: Vertex
      content: |
        Before you begin:

        1. In [Vertex AI Model Garden](https://console.cloud.google.com/vertex-ai/model-garden), enable a Claude model (for example, **Claude Sonnet 4.5**). Note the **location** it's enabled in. Depending on your project, Vertex may offer Claude in a specific region (for example, `us-east5`) or under `global`.
        1. Create a Google Cloud service account with Vertex AI permissions and download its JSON key file.
        1. Export the service account JSON and the full `:rawPredict` upstream URL as environment variables. Vertex encodes your project, location, and model ID directly in this URL, so there are no separate provider or target fields for them. The hostname depends on the location from step 1: a specific region uses a region-prefixed host, while `global` uses the plain host with no region prefix:

            ```sh
            export GCP_SERVICE_ACCOUNT_JSON="$(cat /path/to/service-account.json)"

            # If your model is enabled in a specific region:
            export VERTEX_UPSTREAM_URL="https://us-east5-aiplatform.googleapis.com/v1/projects/<YOUR_PROJECT_ID>/locations/us-east5/publishers/anthropic/models/claude-sonnet-4-5@20250929:rawPredict"

            # If your model is enabled under "global" instead:
            export VERTEX_UPSTREAM_URL="https://aiplatform.googleapis.com/v1/projects/<YOUR_PROJECT_ID>/locations/global/publishers/anthropic/models/claude-sonnet-4-5@20250929:rawPredict"
            ```

        {:.info}
        > Vertex publisher model IDs use the format `name@YYYYMMDD` (for example, `claude-sonnet-4-5@20250929`), not a plain model name. Use the exact ID shown for your enabled model in Model Garden.
      icon_url: /assets/icons/vertex.svg
    - title: Claude Code CLI
      icon_url: /assets/icons/third-party/claude.svg
      include_content: prereqs/claude-code

---

## Create an AI Model Provider entity

Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) entity to define your connection and store your authentication credentials:

{% entity_examples %}
ai_gateway_model_providers:
  - ref: vertex-prod
    name: vertex-prod
    display_name: "Google Vertex Prod"
    ai_gateway: !lookup name:ai-quickstart
    type: vertex
    config:
      auth:
        type: gcp
        service_account_json: !env GCP_SERVICE_ACCOUNT_JSON
{% endentity_examples %}

{:.info}
> `ai-quickstart` references the {{site.ai_gateway}} created by the quickstart script in the prerequisites above, instead of creating a new one.

In this example, we're setting up the AI Model Provider with:

 * `type: vertex`: Specifies that this provider connects to Google Vertex AI.
 * `config.auth.type: gcp`: Uses Google Cloud service account authentication, rather than a bearer token or API key.
 * `config.auth.service_account_json: !env GCP_SERVICE_ACCOUNT_JSON`: Loads the service account JSON, required to access the account, from your environment at apply time.

## Create an AI Policy and AI Model

Create an [AI Model](/ai-gateway/entities/ai-model/) entity to declare which upstream models are available, configure how client requests are routed, and specify which AI Model Provider to use.

Create an [AI Policy](/ai-gateway/entities/ai-policy/) entity using [request transformer](/ai-gateway/policies/ai-request-transformer/) to remove extra fields that Vertex AI's API does not support.

{:.warning}
> Apply the Policy and the AI Model together, in the same `kongctl apply` call, as shown below. The AI Model's `policies` field references the Policy via `!ref`, and `ref` values are local to a single `kongctl apply` call. They're never written to {{site.konnect_short_name}}. If you split this into two separate `kongctl apply` calls, the second one fails with `resource not found: claude-code-compat`, even though the Policy already exists.

{% entity_examples %}
ai_gateway_policies:
  - ref: claude-code-compat
    name: claude-code-compat
    ai_gateway: !lookup name:ai-quickstart
    type: request-transformer-advanced
    enabled: true
    global: false
    config:
      remove:
        headers: [anthropic-beta]
        querystring: [beta]
        body: [output_config, context_management, mcp_servers, container, service_tier, thinking]
ai_gateway_models:
  - ref: claude-code-vertex-sonnet
    name: claude-code-vertex-sonnet
    display_name: "Claude Code - Vertex - Sonnet 4.6"
    ai_gateway: !lookup name:ai-quickstart
    type: model
    enabled: true
    formats:
      - type: anthropic
    config:
      route:
        paths:
          - /
        model:
          body_param: model
          values:
            - claude-code-vertex-sonnet
    capabilities:
      - generate
    policies:
      - !ref claude-code-compat#name
    targets:
      - name: claude-sonnet-4-5@20250929
        provider: !ref vertex-prod#name
        config:
          type: vertex
          upstream_url: !env VERTEX_UPSTREAM_URL
{% endentity_examples %}

{:.info}
> Replace `claude-sonnet-4-5@20250929` with the id of your own enabled model in Vertex AI Model Garden.

The AI Policy uses:

* `type: request-transformer-advanced`: Modifies requests before {{site.ai_gateway}} forwards them upstream.
* `config.remove.headers` / `config.remove.querystring` / `config.remove.body`: Strips fields that {{ site.claude_code }} sends but that Vertex AI's Claude endpoint rejects with a `400 Extra inputs are not permitted`: the `anthropic-beta` header, the `beta` query string, and body fields like `mcp_servers` and `container`. The list also includes `thinking`. {{ site.claude_code }} sends `thinking: {"type": "adaptive", ...}` by default, and Vertex's schema only accepts `disabled` or `enabled` for `thinking.type`, so it must be removed rather than left as-is.

{:.info}
> The Vertex driver injects the `anthropic-version` header into the request body automatically. 

The AI Model uses:

 * `name`/`display_name: claude-code-vertex-sonnet`: The identifier you pass to `claude --model`. {{ site.claude_code }} uses this, not the upstream target ID, to select the model.
 * `formats: [type: anthropic]`: Accepts Anthropic-compatible requests (what {{ site.claude_code }} sends).
 * `capabilities: [generate]`: Enables text generation. For a model using the `anthropic` format, `generate` creates a `/messages` endpoint matching Anthropic's native Messages API.
 * `policies`: Attaches the `claude-code-compat` policy defined above, via `!ref claude-code-compat#name`, so its body-stripping transformation applies to every request sent through this model.
 * `targets[0].provider: vertex-prod`: Routes upstream requests through the Vertex AI Provider created earlier.
 * `targets[0].name: claude-sonnet-4-5@20250929`: The Vertex publisher model ID, in `name@YYYYMMDD` format. It must match a model you've enabled in Vertex AI Model Garden.
 * `targets[0].config.upstream_url`: The full `:rawPredict` URL from the prerequisites, encoding your project, location, and model ID.

## Verify traffic through Kong

Now, we can start a {{ site.claude_code }} session that points it to the local {{site.ai_gateway}} endpoint:

```sh
ANTHROPIC_BASE_URL=http://localhost:8000/ claude --model 'claude-code-vertex-sonnet'
```

Ask a question to confirm that requests reach {{site.ai_gateway}}.

{% validation claude-code %}
prompt: Tell me about the Madrid Skylitzes manuscript.
model: my-claude
{% endvalidation %}


{{ site.claude_code }} might prompt you approve its web search for answering the question. When you select **Yes**, {{ site.claude }} will produce a full-length response to your request:

```text
The Madrid Skylitzes is a remarkable 12th-century illuminated Byzantine
manuscript that represents one of the most important surviving examples
of medieval historical documentation. Here are the key details:

What it is

The Madrid Skylitzes is the only surviving illustrated manuscript of John
Skylitzes' "Synopsis of Histories" (Σύνοψις Ἱστοριῶν), which chronicles
Byzantine history from 811 to 1057 CE - covering the period from the death
of Emperor Nicephorus I to the deposition of Michael VI.

Artistic Significance

- 574 miniature paintings (with about 100 lost over time)
- Lavishly decorated with gold leaf, vibrant pigments, and intricate
detailing
- Depicts everything from imperial coronations and battles to daily life
in Byzantium
- The only surviving Byzantine illuminated chronicle written in Greek

Unique Collaboration

The manuscript is believed to be the work of 7 different artists from
various backgrounds:
- 4 Italian artists
- 1 English or French artist
- 2 Byzantine artists
```
{:.no-copy-code}
