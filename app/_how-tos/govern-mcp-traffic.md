---
title: "Part 2: Govern MCP traffic with Kong AI Gateway"
content_type: how_to
related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advance/
  - text: Key Auth plugin
    url: /plugins/key-auth/

description: Learn how to gover MCP traffic within GitHub remote MCP server with the AI Proxy Advanced and AI Prompt Guard plugins

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.11'

plugins:
  - ai-proxy

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - openai

tldr:
  q: How can I gover my MCP traffic using Kong AI Gateway?
  a: |
    ADD


tools:
  - deck

prereqs:
  inline:
    - title: OpenAI
      include_content: prereqs/openai
      icon_url: /assets/icons/openai.svg
    - title: GitHub
      content: |
        To complete this tutorial, you'll need access to GitHub, access to GitHub repository and [Github Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens).

        Once you've created your Github Personal Access Token, make sure to export it as an environment variable by running the following command:

        ```bash
        export GITHUB_PAT=<YOUR_GITHUB_TOKEN>
        ```
      icon_url: /assets/icons/third-party/github.svg
    - inline: Completed [Part 1](/how-to/secure-mcp-traffic/) tutorial
      content: "Before starting, complete Part 1: Secure MCP Traffic with the Key Authentication Plugin."
  prereqs:
    entities:
        services:
            - example-clean-service
        routes:
            - example-clean-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Reconfigure the AI Proxy Advanced Plugin

This configuration uses the `ai-proxy-advanced` plugin to load balance requests between OpenAI’s `gpt-4` and `gpt-4o` models using a round-robin algorithm. Both models are configured to call a GitHub-hosted remote MCP server via the `llm/v1/responses` route. The plugin injects the required OpenAI API key for authentication and logs both payloads and statistics. With equal weights assigned to each target, traffic is split evenly between the two models.

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      config:
        balancer:
          algorithm: round-robin
        targets:
          - model:
              provider: openai
              name: gpt-4
              options:
                max_tokens: 512
                temperature: 1.0
            route_type: llm/v1/responses
            auth:
              header_name: Authorization
              header_value: Bearer ${openai_api_key}
            logging:
              log_payloads: true
              log_statistics: true
            weight: 50
          - model:
              provider: openai
              name: gpt-4o
              options:
                max_tokens: 512
                temperature: 1.0
            route_type: llm/v1/responses
            auth:
              header_name: Authorization
              header_value: Bearer ${openai_api_key}
            logging:
              log_payloads: true
              log_statistics: true
            weight: 50
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}

## Validate MCP Traffic balancing

Now, we can test if the lkoad balancing works


```bash
for i in {1..10}; do
  echo -n "Request #$i — Model: "
  curl -s -X POST "http://localhost:8000/anything/v1/responses" \
    -H "Accept: application/json" \
    -H "apikey: hello_world" \
    -H "Content-Type: application/json" \
    --json "{
      \"tools\": [
        {
          \"type\": \"mcp\",
          \"server_label\": \"gitmcp\",
          \"server_url\": \"https://api.githubcopilot.com/mcp/x/repos\",
          \"require_approval\": \"never\",
          \"headers\": {
            \"Authorization\": \"Bearer $GITHUB_PAT\"
          }
        }
      ],
      \"input\": \"tools available with github mcp\"
    }" | jq -r '.model'
  sleep 3
done
```