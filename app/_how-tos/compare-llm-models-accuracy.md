---
title: Control accuracy of LLM models using the AI LLM as judge plugin
content_type: how_to
related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/
  - text: HTTP Log
    url: /plugins/http-log/

description: Learn how to

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.12'

plugins:
  - ai-proxy-advanced
  - ai-llm-as-judge

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - openai

tldr:
  q: How do I control and measure the accuracy of LLM responses?
  a: |
    Use AI Proxy Advanced to manage multiple LLM models, AI LLM as Judge to score responses, and HTTP Log to monitor LLM accuracy.

tools:
  - deck

prereqs:
  inline:
    - title: OpenAI
      include_content: prereqs/openai
      icon_url: /assets/icons/openai.svg
    - title: Ollama
      content: |
        To complete this tutorial, make sure you have Ollama installed and running locally.

        1. Visit the [Ollama download page](https://ollama.com/download) and download the installer for your operating system. Follow the installation instructions for your platform.

        1. Start Ollama:
          ```sh
          ollama start
          ```

        2. After installation, open a new terminal window and run the following command to pull the orca-mini model we will be using in this tutorial:

          ```sh
          ollama run orca-mini
          ```

        3. To set up the AI Proxy plugin, you'll need the upstream URL of your local Llama instance.

          ```sh
          export DECK_OLLAMA_UPSTREAM_URL='http://localhost:11434/api/chat'
          ```
          By default, Ollama runs at `localhost:11434`. You can verify this by running:

          ```sh
          lsof -i :11434
          ```

          - You should see output similar to:

          ```
          COMMAND   PID            USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
          ollama   23909  your_user_name   4u  IPv4 0x...            0t0  TCP localhost:11434 (LISTEN)
          ```

          - If Ollama is running on a different port, run:

          ```sh
          sudo lsof -iTCP -sTCP:LISTEN -n -P
          ```

          - Then look for the `ollama` process in the output and note the port number it’s listening on.

          {:.info}
          > If you're running {{site.base_gateway}} locally in a Docker container, export your upstream URL as `http://host.docker.internal:11434`
      icon_url: /assets/icons/ollama.svg

  entities:
    services:
        - example-service
    routes:
        - example-route

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

## Configure the AI Proxy Advanced plugin

The [AI Proxy Advanced](/plugins/ai-proxy-advanced) plugin allows you to route requests to multiple LLM models and define load balancing, retries, timeouts, and token counting strategies. In this tutorial, we will configure it to send requests to both OpenAI and Ollama models, using the [lowest-usage balancer](/ai-gateway/load-balancing/#load-balancing-algorithms) to direct traffic to the model currently handling the fewest tokens or requests, and prepare them for evaluation by the LLM as Judge plugin.

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      config:
        balancer:
          algorithm: lowest-usage
          connect_timeout: 60000
          failover_criteria:
            - error
            - timeout
          hash_on_header: X-Kong-LLM-Request-ID
          latency_strategy: tpot
          read_timeout: 60000
          retries: 5
          slots: 10000
          tokens_count_strategy: llm-accuracy
          write_timeout: 60000
        genai_category: text/generation
        llm_format: openai
        max_request_body_size: 8192
        model_name_header: true
        response_streaming: allow
        targets:
          - model:
              name: gpt-4.1-mini
              provider: openai
              options:
                cohere:
                  embedding_input_type: classification
            route_type: llm/v1/chat
            auth:
              allow_override: false
              header_name: Authorization
              header_value: Bearer ${openai_api_key}
            logging:
              log_payloads: true
              log_statistics: true
            weight: 100
          - model:
              name: orca-mini
              options:
                llama2_format: ollama
                upstream_url: http://host.docker.internal:11434/api/chat
                cohere:
                  embedding_input_type: classification
              provider: llama2
            route_type: llm/v1/chat
            logging:
              log_payloads: true
              log_statistics: true
            weight: 100
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}

## Configure the AI LLM as Judge plugin

The AI LLM as Judge plugin evaluates responses returned by your models and assigns an accuracy score between 1 and 100. These scores can be used for model ranking, learning, or automated evaluation. In this tutorial, we use GPT-4o as the judge model—a higher-capacity model we recommend for this plugin to ensure consistent and reliable scoring.

{% entity_examples %}
entities:
  plugins:
    - name: ai-llm-as-judge
      config:
        prompt: |
          You are a strict evaluator. You will be given a request and a response.
          Your task is to judge whether the response is correct or incorrect. You must
          assign a score between 1 and 100, where: 100 represents a completely correct
          and ideal response, 1 represents a completely incorrect or irrelevant response.
          Your score must be a single number only — no text, labels, or explanations.
          Use the full range of values (e.g., 13, 47, 86), not just round numbers like
          10, 50, or 100. Be accurate and consistent, as this score will be used by another
          model for learning and evaluation.
        http_timeout: 60000
        https_verify: true
        ignore_assistant_prompts: true
        ignore_system_prompts: true
        ignore_tool_prompts: true
        sampling_rate: 1
        llm:
          auth:
            allow_override: false
            header_name: Authorization
            header_value: Bearer ${openai_api_key}
          logging:
            log_payloads: true
            log_statistics: true
          model:
            name: gpt-4o
            provider: openai
            options:
              temperature: 2
              max_tokens: 5
              top_p: 1
              cohere:
                embedding_input_type: classification
          route_type: llm/v1/chat
        message_countback: 3
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}

## Log model accuracy

The [HTTP Log plugin](/plugins/http-log/) allows you to capture plugin events and responses. We will use it to collect the LLM accuracy scores produced by AI LLM as Judge.

{% entity_examples%}
entities:
  plugins:
    - name: http-log
      service: example-service
      config:
        http_endpoint: http://host.docker.internal:9999/
        headers:
          Authorization: Bearer some-token
        method: POST
        timeout: 3000
{% endentity_examples%}

Let's run a simple log collector script which collect logs at `9999` port. Copy and run this snippet in your terminal:

```
cat <<EOF > log_server.py
from http.server import BaseHTTPRequestHandler, HTTPServer
import datetime

LOG_FILE = "kong_logs.txt"

class LogHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        timestamp = datetime.datetime.now().isoformat()

        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length).decode('utf-8')

        log_entry = f"{timestamp} - {post_data}\n"
        with open(LOG_FILE, "a") as f:
            f.write(log_entry)

        print("="*60)
        print(f"Received POST request at {timestamp}")
        print(f"Path: {self.path}")
        print("Headers:")
        for header, value in self.headers.items():
            print(f"  {header}: {value}")
        print("Body:")
        print(post_data)
        print("="*60)

        # Send OK response
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"OK")

if __name__ == '__main__':
    server_address = ('', 9999)
    httpd = HTTPServer(server_address, LogHandler)
    print("Starting log server on http://0.0.0.0:9999")
    httpd.serve_forever()
EOF
```

Now, run this script with Python:

```sh
python3 log_server.py
```

If script is successful, you'll receive the following prompt in your terminal:

```sh
Starting log server on http://0.0.0.0:9999
```

## Validate your configuration

Send test requests to the `route` route to see model responses scored:

```sh
for i in {1..5}; do
  curl -s -X POST "http://localhost:8000/anything" \
    -H "Content-Type: application/json" \
    --json '{
      "messages": [
        {
          "role": "user",
          "content": "Who was Jozef Mackiewicz?"
        }
      ]
    }'

  sleep 3
done
```

You should see output like this in your HTTP log plugin endpoint, showing how many tokens were saved through compression:

```json
{
  "workspace_name": "default",
  "workspace": "workspace-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "ai": {
    "ai-llm-as-judge": {
      "meta": {
        "llm_latency": 460,
        "request_model": "gpt-4.1-mini",
        "provider_name": "openai",
        "request_mode": "oneshot",
        "plugin_id": "plugin-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
        "response_model": "gpt-4o-2024-08-06"
      },
      "...": "...",
      "tried_targets": [
        {
          "upstream_scheme": "https",
          "port": 443,
          "ip": "xxx.xxx.xxx.xxx",
          "host": "api.openai.com",
          "provider": "openai",
          "upstream_uri": "/v1/chat/completions",
          "model": "gpt-4.1-mini",
          "route_type": "llm/v1/chat"
        }
      ],
      "usage": {
        "completion_tokens": 254,
        "llm_accuracy": 94,
        "prompt_tokens_details": {
          "audio_tokens": 0,
          "cached_tokens": 0
        },
        "..."
      }
    }
  }
}
```
{:.no-copy-code}
