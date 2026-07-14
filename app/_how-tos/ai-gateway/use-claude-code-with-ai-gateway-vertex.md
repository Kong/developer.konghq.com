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
  q: How do I run Claude CLI through {{site.ai_gateway}} against a Vertex AI model?
  a: Create an AI Provider entity to store your GCP service account credentials, create an AI Model entity with an Anthropic-compatible format that routes to a Gemini model on Vertex AI through that provider, then point Claude CLI's `ANTHROPIC_BASE_URL` at your local {{site.ai_gateway}} endpoint so all LLM requests pass through the gateway for monitoring and control.

prereqs:
  inline:
    - title: Vertex
      content: |
        Before you begin, you must get the following credentials from Google Cloud:

        - **Service Account Key**: A JSON key file for a service account with Vertex AI permissions
        - **Project ID**: Your Google Cloud project identifier
        - **Location ID**: The region where your Vertex AI endpoint is deployed (for example, `us-central1`)
        - **API Endpoint**: The Vertex AI API endpoint URL (typically `https://{location}-aiplatform.googleapis.com`)

        Export these values as environment variables:
        ```sh
        export GEMINI_API_KEY="<your_gemini_api_key>"
        export GCP_PROJECT_ID="<your-gemini-project-id>"
        export GEMINI_LOCATION_ID="<your-gemini-location_id>"
        export GEMINI_API_ENDPOINT="<your_gemini_api_endpoint>"
        ```
      icon_url: /assets/icons/vertex.svg
    - title: Claude Code CLI
      icon_url: /assets/icons/third-party/claude.svg
      include_content: prereqs/claude-code

---

## Create an AI Provider entity

Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) entity to define your connection to Vertex AI and store your GCP service account credentials:

```sh
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
_defaults:
  kongctl:
    namespace: ai-gateway-get-started

ai_gateways:
  - ref: ai-quickstart
    name: ai-quickstart
    display_name: "ai-quickstart"

ai_gateway_model_providers:
  - ref: my-vertex-account
    ai_gateway: ai-quickstart
    name: my-vertex-account
    display_name: "my-vertex-account"
    type: vertex
    config:
      auth:
        type: gcp
        use_gcp_service_account: true
        service_account_json: !env GEMINI_API_KEY
EOF
```

In this example, we're setting up the AI Model Provider with:

* `type: vertex`: Specifies that this provider connects to Google Cloud Vertex AI.
* `name: my-vertex-account`: A unique identifier that AI Models will reference to route requests through this provider.
* `config.auth`: Authenticates to Vertex AI with a GCP service account. `use_gcp_service_account: true` tells {{site.ai_gateway}} to authenticate using service account credentials, and `service_account_json: !env GEMINI_API_KEY` loads the service account JSON key from your environment at apply time instead of embedding it in the YAML. `kongctl` redacts it in plan and diff output. {{site.ai_gateway}} securely manages this credential and injects it into upstream requests automatically, eliminating the need for clients to pass credentials.

## Create an AI Model entity

Create an [AI Model](/ai-gateway/entities/ai-model/) entity to declare which upstream models are available, configure how client requests are routed, and specify which AI Provider to use:

```sh
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
_defaults:
  kongctl:
    namespace: ai-gateway-get-started

ai_gateways:
  - ref: ai-quickstart
    name: ai-quickstart
    display_name: "ai-quickstart"

ai_gateway_models:
  - ref: my-claude-vertex
    ai_gateway: ai-quickstart
    name: my-claude-vertex
    display_name: "my-claude-vertex"
    type: model
    formats:
      - type: anthropic
    config:
      route:
        paths:
          - /
      model:
        alias: my-claude-vertex
    targets:
      - name: gemini-2.5-flash
        provider: my-vertex-account
        config:
          type: vertex
          api_endpoint: !env GEMINI_API_ENDPOINT
          project_id: !env GCP_PROJECT_ID
          location_id: !env GEMINI_LOCATION_ID
    policies: []
    capabilities:
      - generate
EOF
```

In this example, we're setting up the AI Model with:

* `type: model`: Specifies this is a synchronous model for request/response workloads.
* `name: my-claude-vertex`: A unique identifier for this model.
* `formats: [type: anthropic]`: Declares that this model accepts requests in Anthropic-compatible format, matching what {{ site.claude_code }} sends natively, even though the upstream model is a Gemini model on Vertex AI.
* `config.route.paths: [/]`: Configures the custom base path where this model's Routes will be accessible. Setting this to a unique value avoids clashes when you have multiple AI Models.
* `capabilities: [generate]`: Enables the text generation capability. For a model using the `anthropic` format, the `generate` capability creates a `/messages` endpoint matching Anthropic's native Messages API, so combined with your base path, clients send requests to `/v1/messages`.
* `targets`: Specifies which upstream AI Provider model to route requests to. Here, `provider: my-vertex-account` references the AI Provider we created earlier, and `name: gemini-2.5-flash` specifies which Gemini model to call upstream. `config.api_endpoint`, `config.project_id`, and `config.location_id` identify the specific Vertex AI deployment to route requests to.

## Verify traffic through Kong

Now, we can start a {{ site.claude_code }} session that points it to the local {{site.ai_gateway}} endpoint:

```sh
ANTHROPIC_BASE_URL=http://localhost:8000/ ANTHROPIC_MODEL=my-claude-vertex claude
```

{{ site.claude_code }} asks for permission before it runs tools or interacts with files:

```text
I'll need permission to work with your files.

This means I can:
- Read any file in this folder
- Create, edit, or delete files
- Run commands (like npm, git, tests, ls, rm)
- Use tools defined in .mcp.json

Learn more ( https://docs.claude.com/s/claude-code-security )

❯ 1. Yes, continue
2. No, exit
```
{:.no-copy-code}

Select **Yes, continue**. The session starts. Ask a simple question to confirm that requests reach {{site.ai_gateway}}.

```text
Tell me about Anna Komnene's Alexiad.
```

{{ site.claude_code }} might prompt you approve its web search for answering the question. When you select **Yes**, {{ site.claude }} will produce a full-length response to your request:

```text
Anna Komnene (1083-1153?) was a Byzantine princess, scholar, physician,
hospital administrator, and historian. She is known for writing the
Alexiad, a historical account of the reign of her father, Emperor Alexios
I Komnenos (r. 1081-1118). The Alexiad is a valuable primary source for
understanding Byzantine history and the First Crusade.
```
{:.no-copy-code}
