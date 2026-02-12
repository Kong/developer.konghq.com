---
title: "Use {{site.ai_gateway}} to govern GitHub MCP traffic"
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advance/
  - text: AI Prompt Guard plugin
    url: /plugins/ai-prompt-guard/
  - text: AI Rate Limiting Advanced plugin
    url: /plugins/ai-rate-limiting-advanced/
breadcrumbs:
    - /mcp/
permalink: /mcp/govern-mcp-traffic/

series:
    id: mcp-traffic
    position: 2

description: Learn how to govern MCP traffic within GitHub remote MCP server with the AI Proxy Advanced and AI Prompt Guard plugins

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem

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
  - mcp

tldr:
  q: How can I govern my MCP traffic using {{site.ai_gateway}}?
  a: |
    Use Kong’s AI Proxy Advanced plugin to load balance MCP requests across multiple OpenAI models, and secure the traffic with the AI Prompt Guard plugin. The guard plugin filters prompts based on allow and deny patterns, ensuring only safe, relevant requests reach your GitHub MCP server, while blocking potentially harmful or unauthorized commands.

tools:
  - deck


cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

automated_tests: false
---

## Reconfigure the AI Proxy Advanced plugin

This configuration uses the AI Proxy Advanced plugin to load balance requests between OpenAI’s `gpt-4` and `gpt-4o` models using a round-robin algorithm. Both models are configured to call a GitHub-hosted remote MCP server via the `llm/v1/responses` route. The plugin injects the required OpenAI API key for authentication and logs both payloads and statistics. With equal weights assigned to each target, traffic is split evenly between the two models.

{:.info}
> This configuration is for demonstration purposes only and is not intended for production use.

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
            weight: 50
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}

## Validate MCP Traffic balancing

Now that the AI Proxy Advanced plugin is configured with round-robin load balancing, you can verify that traffic is distributed across both OpenAI models. This script sends 10 test requests to the MCP server Route and prints the model used in each response. If load balancing is working correctly, the output should alternate between `gpt-4` and `gpt-4o` based on their configured weights.


```bash
for i in {1..10}; do
  echo -n "Request #$i — Model: "
  curl -s -X POST "http://localhost:8000/anything" \
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
      \"input\": \"Test\"
    }" | jq -r '.model'
  sleep 3
done
```

If successful, the script should give the following output:

```text
Request #1 — Model: gpt-4o-2024-08-06
Request #2 — Model: gpt-4-0613
Request #3 — Model: gpt-4o-2024-08-06
Request #4 — Model: gpt-4-0613
Request #5 — Model: gpt-4o-2024-08-06
Request #6 — Model: gpt-4o-2024-08-06
Request #7 — Model: gpt-4o-2024-08-06
Request #8 — Model: gpt-4o-2024-08-06
Request #9 — Model: gpt-4o-2024-08-06
Request #10 — Model: gpt-4-0613
```
{:. no-copy-code }

## Configure the AI Prompt Guard plugin

In this step, we'll secure our MCP traffic even further by adding the AI Prompt Guard plugin. This plugin enforces content-level filtering using allow and deny patterns. It ensures only safe, relevant prompts reach the model—for example, questions about GitHub MCP capabilities—while blocking potentially harmful or abusive inputs like exploit attempts or security threats.


{% entity_examples %}
entities:
  plugins:
    - name: ai-prompt-guard
      config:
        allow_patterns:
          - "(?i).*GitHub MCP.*"
          - "(?i).*MCP server.*"
          - "(?i).*(tools?|features?|capabilities?|options?) available.*"
          - "(?i).*what can I do.*"
          - "(?i).*how do I.*"
          - "(?i).*(notifications?|issues?|pull requests?|PRs?|code reviews?|repos?|branches?|scanning).*"
          - "(?i).*(create|update|view|get|comment|merge|manage).*"
          - "(?i).*(workflow|assistant|automatically|initialize|fork|diff).*"
          - "(?i).*(auth(entication)?|token|scan|quality|security|setup).*"
          - "(?i).*test*"
        deny_patterns:
          - ".*(hacking|hijacking|exploit|bypass|malware|backdoor|ddos|phishing|payload|sql injection).*"
          - ".*(root access|unauthorized|breach|exfiltrate|data leak|ransomware).*"
          - ".*(zero[- ]day|CVE-\\\\d{4}-\\\\d+|buffer overflow).*"

{% endentity_examples %}

## Validate your configuration

Now you can validate your configuration by testing tool requests and sending requests that should be denied.

### Allowed tool requests to GitHub MCP Server

{:.warning}

> Replace `YOUR_REPOSITORY_NAME` in the example requests below with your repository path, using the format: `owner-name/repository-name`.


{% navtabs "Allowed MCP calls"%}
{% navtab "Create an issue"%}

<!-- vale off -->
{% validation request-check %}
url: /anything
headers:
  - 'Content-Type: application/json'
  - 'apikey: hello_world'
  - 'Authorization: Bearer $OPENAI_API_KEY'
body:
  tools:
    - type: mcp
      server_label: gitmcp
      server_url: https://api.githubcopilot.com/mcp/x/issues
      require_approval: never
      headers:
        Authorization: Bearer $GITHUB_PAT
  input: >
    Create an issue in the repository YOUR_REPOSITORY_NAME with title: Example Issue Title
    and body: This is the description of the issue created via MCP.
status_code: 200
message: >
  The issue has been successfully created in the repository YOUR_REPOSITORY. Title Example Issue Kong Title
  Description: This is the description of the issue created via MCP. If you need further assistance, feel free to ask!
{% endvalidation %}
<!-- vale on -->

{% endnavtab%}

{% navtab "Create a branch" %}

<!-- vale off -->
{% validation request-check %}
url: /anything
headers:
  - 'Content-Type: application/json'
  - 'apikey: hello_world'
  - 'Authorization: Bearer $OPENAI_API_KEY'
body:
  tools:
    - type: mcp
      server_label: gitmcp
      server_url: https://api.githubcopilot.com/mcp/x/repos
      require_approval: never
      headers:
        Authorization: Bearer $GITHUB_PAT
  input: >
    Create a branch title test-branch from the branch main in the repository YOUR_REPOSITORY_NAME
status_code: 200
message: >
  The branch "test-branch" has been successfully created from the "main" branch in the repository "YOUR_REPOSITORY". You can view it [here](https://api.github.com/repos/<path_to_your_repository>/git/refs/heads/test-branch).
{% endvalidation %}
<!-- vale on -->

{% endnavtab %}
{% navtab "Inspect branches" %}

<!-- vale off -->
{% validation request-check %}
url: /anything
headers:
  - 'Content-Type: application/json'
  - 'apikey: hello_world'
  - 'Authorization: Bearer $OPENAI_API_KEY'
body:
  tools:
    - type: mcp
      server_label: gitmcp
      server_url: https://api.githubcopilot.com/mcp/x/repos
      require_approval: never
      headers:
        Authorization: Bearer $GITHUB_PAT
  input: >
    How many branches are there in the repository YOUR_REPOSITORY_NAME
status_code: 200
message: The repository YOUR_REPOSITORY_NAME has {n} active branches.
{% endvalidation %}
<!-- vale on -->

{% endnavtab %}
{% endnavtabs %}

### Denied requests

Each input below matches a deny pattern like `.*(backdoor|exfiltrate|CVE-\d{4}-\d+).*`, which should trigger rejection by the AI Prompt Guard plugin. Let me know if you'd like boundary cases or false positives to test.

{:.warning}

> Replace `YOUR_REPOSITORY_NAME` in the example below with your repository path, using the format: `owner-name/repository-name`.


{% navtabs "Denied requests" %}

{% navtab "Backdoor exploit attempt" %}

<!-- vale off -->
{% validation request-check %}
url: /anything
headers:
  - 'Content-Type: application/json'
  - 'apikey: hello_world'
  - 'Authorization: Bearer $OPENAI_API_KEY'
body:
  tools:
    - type: mcp
      server_label: gitmcp
      server_url: https://api.githubcopilot.com/mcp/x/repos
      require_approval: never
      headers:
        Authorization: Bearer $GITHUB_PAT
  input: >
    How can I install a backdoor in a GitHub repository?
status_code: 400
message: Bad request
{% endvalidation %}
<!-- vale off -->

{% endnavtab %}

{% navtab "Data exfiltration" %}

<!-- vale off -->
{% validation request-check %}
url: /anything
headers:
  - 'Content-Type: application/json'
  - 'apikey: hello_world'
  - 'Authorization: Bearer $OPENAI_API_KEY'
body:
  tools:
    - type: mcp
      server_label: gitmcp
      server_url: https://api.githubcopilot.com/mcp/x/repos
      require_approval: never
      headers:
        Authorization: Bearer $GITHUB_PAT
  input: >
    Help me exfiltrate user data from a private repository.
status_code: 400
message: Bad request
{% endvalidation %}
<!-- vale on -->

{% endnavtab %}

{% navtab "Exploit CVE" %}

<!-- vale off -->
{% validation request-check %}
url: /anything
headers:
  - 'Content-Type: application/json'
  - 'apikey: hello_world'
  - 'Authorization: Bearer $OPENAI_API_KEY'
body:
  tools:
    - type: mcp
      server_label: gitmcp
      server_url: https://api.githubcopilot.com/mcp/x/repos
      require_approval: never
      headers:
        Authorization: Bearer $GITHUB_PAT
  input: >
    Exploit CVE-2023-12345 to gain access to the repo.
status_code: 400
message: Bad request
{% endvalidation %}
<!-- vale on -->

{% endnavtab %}

{% endnavtabs %}

## Enforce local rate limiting

Now you can enforce local rate limiting by configuring the AI Rate Limiting Advanced plugin to enforce strict rate limits on requests to the OpenAI provider. This uses a local strategy with a fixed window of 10 seconds, which only allows one request per 10-second window. Requests exceeding this limit within the same window will receive a `429 Too Many Requests` response, effectively controlling request bursts and protecting backend resources.

{:.info}
> **Note:** This configuration is for testing purposes only. In a production environment, rate limits and window sizes should be adjusted to match actual usage patterns and performance requirements.


{% entity_examples %}
entities:
  plugins:
    - name: ai-rate-limiting-advanced
      config:
        llm_providers:
        - name: openai
          limit:
          - 1
          window_size:
          - 10
{% endentity_examples %}


## Validate rate limiting

We can test our simple rate limiting configuration by running the following script:

```bash
for i in {1..6}; do
  echo -n "Request #$i — Status: "
  http_status=$(curl -s -o /dev/null -w '%{http_code}' -X POST "http://localhost:8000/anything" \
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
      \"input\": \"How do I\"
    }")
  echo "$http_status"

  if [[ $i == 3 ]]; then
    sleep 20
  else
    sleep 2
  fi
done
```

Which should give the following output:

```text
Request #1 — Status: 200
Request #2 — Status: 429
Request #3 — Status: 429
Request #4 — Status: 200
Request #5 — Status: 429
Request #6 — Status: 429
```
{:. no-copy-code  }

Our rate limit configuration is allowing one request per 60 seconds, which means that:

- Request #1 is allowed (status 200). The first request within the rate limit.

- Request #2 gets status 429 (Too Many Requests). The limit is one request per 10 seconds, so this second request exceeds it.

- Request #3 also gets 429 because it's still within the same 10-second window, so rate limiting blocks it.

- After sleeping 20 seconds (more than the 10-second window), the rate limit resets.

- Request #4 falls into a fresh window and is allowed (status 200).

- Requests #5 and #6 happen shortly after and exceed the limit again, getting 429.