---
title: Control accuracy of LLM models using the AI LLM as judge plugin
permalink: /how-to/compare-llm-models-accuracy/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/
  - text: HTTP Log
    url: /plugins/http-log/

description: Learn how to compare LLM models accuracy using the AI LLM as Judge plugin

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
  - llama

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

        {% capture ollama %}
        {% validation custom-command %}
        command: docker run -d -v ollama:/root/.ollama -p 11434:11434 --name ollama ollama/ollama
        expected:
          return_code: 0
        render_output: false
        section: prereqs
        {% endvalidation %}
        {% endcapture %}

        1. Start Ollama:
           {{ollama | indent: 3}}

        2. After installation, open a new terminal window and run the following command to pull the orca-mini model we will be using in this tutorial:

           ```sh
           curl http://host.docker.internal:11434/api/generate -d '{ "model": "orca-mini" }' > orca.log 2>&1 &
           ```
           {: data-test-prereqs="block" }

        3. To set up the AI Proxy plugin, you'll need the upstream URL of your local Llama instance.

           In this example, we're running {{site.base_gateway}} locally in a Docker container, so the host is `host.docker.internal`:

           {% env_variables %}
           DECK_OLLAMA_UPSTREAM_URL: 'http://host.docker.internal:11434/api/chat'
           indent: 3
           section: prereqs
           {% endenv_variables %}
      icon_url: /assets/icons/ollama.svg

  entities:
    services:
        - example-service
    routes:
        - example-route

cleanup:
  inline:
    - title: Remove Ollama's container
      content: |
        ```sh
        docker rm -f ollama
        ```
        {: data-test-cleanup="block" }
      icon_url: /assets/icons/ollama.svg
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

---

## Configure the AI Proxy Advanced plugin

The [AI Proxy Advanced](/plugins/ai-proxy-advanced) plugin allows you to route requests to multiple LLM models and define load balancing, retries, timeouts, and token counting strategies. The AI LLM as Judge plugin requires AI Proxy Advanced with [`config.balancer.tokens_count_strategy`](/plugins/ai-proxy-advanced/reference/#schema--config-balancer-tokens-count-strategy) set to `llm-accuracy`. This setting enables the balancer to compare responses from multiple LLM models and pass them to the judge for evaluation.

In this tutorial, we configure AI Proxy Advanced to send requests to both OpenAI and Ollama models, using the [lowest-usage balancer](/ai-gateway/load-balancing/#load-balancing-algorithms) to direct traffic to the model currently handling the fewest tokens or requests. For testing purposes only, we include a less reliable Ollama model in the configuration. This makes it easier to demonstrate the evaluation differences when responses are judged by the AI LLM as Judge plugin.

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
                upstream_url: ${ollama_upstream_url}
              provider: llama2
            route_type: llm/v1/chat
            logging:
              log_payloads: true
              log_statistics: true
            weight: 100
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
  ollama_upstream_url:
    value: $OLLAMA_UPSTREAM_URL
{% endentity_examples %}

## Configure the AI LLM as Judge plugin

The [AI LLM as Judge](/plugins/ai-llm-as-judge/) plugin evaluates responses returned by your models and assigns an accuracy score between 1 and 100. These scores can be used for model ranking, learning, or automated evaluation. In this tutorial, we use GPT-4o as the judge model—a higher-capacity model we recommend for this plugin to ensure consistent and reliable scoring.

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
          route_type: llm/v1/chat
        message_countback: 3
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}

## Log model accuracy

The [HTTP Log plugin](/plugins/http-log/) allows you to capture plugin events and responses. We'll use it to collect the LLM accuracy scores produced by AI LLM as Judge.

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

Let's run a simple log collector script which collects logs at the `9999` port. Copy and run this snippet in your terminal:

<!-- vale off -->
{% validation custom-command %}
command: |
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
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!-- vale on -->

Now, run this script with Python:

<!-- vale off -->
{% validation custom-command %}
command: python3 log_server.py 2>&1 &
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!-- vale on -->

If the script is successful, you'll receive the following prompt in your terminal:

```sh
Starting log server on http://0.0.0.0:9999
```

## Validate your configuration

Send test requests to the `example-route` Route to see model responses scored:

<!-- vale off -->
{% validation traffic-generator %}
iterations: 5
url: '/anything'
method: POST
status_code: 200
body:
  messages:
    - role: "user"
      content: "Who was Jozef Mackiewicz?"
inline_sleep: 3
{% endvalidation %}
<!-- vale on -->

You should see JSON logs from your HTTP log plugin endpoint in `kong_logs.txt`. The `llm_accuracy` field reflects how well the model’s response aligns with the judge model's evaluation.

When comparing two models, notice how `gpt-4.1-mini` produces a **much higher `llm_accuracy` score** than `orca-mini`, showing that the judged responses are significantly more accurate.

{% navtabs "response-accuracy" %}
{% navtab "orca-mini" %}

```json
{
  "workspace_name": "default",
  "workspace": "3ec2d3e1-92d8-abcd-b3da-2732abcdefgh",
  "ai": {
    "ai-llm-as-judge": {
      "meta": {
        "request_mode": "oneshot",
        "provider_name": "openai",
        "request_model": "orca-mini",
        "response_model": "gpt-4o-2024-08-06",
        "llm_latency": 1491,
        "plugin_id": "8ccfd8b8-f5bc-4af9-8951-123456789abc"
      },
      "payload": {
        "...": "..."
      },
      "tried_targets": [
        {
          "route_type": "llm/v1/chat",
          "upstream_scheme": "http",
          "upstream_uri": "/api/chat",
          "ip": "192.168.00.001",
          "port": 11434,
          "provider": "llama2",
          "host": "host.docker.internal",
          "model": "orca-mini"
        }
      ],
      "usage": {
        "completion_tokens": 114,
        "llm_accuracy": 14,
        "prompt_tokens_details": {
          "cached_tokens": 0,
          "audio_tokens": 0
        },
        "completion_tokens_details": {
          "reasoning_tokens": 0,
          "audio_tokens": 0,
          "accepted_prediction_tokens": 0,
          "rejected_prediction_tokens": 0
        },
        "prompt_tokens": 49,
        "total_tokens": 163,
        "time_to_first_token": 1491,
        "time_per_token": 21.77
      }
    }
  }
}
```
{:.no-copy-code}

{% endnavtab %}

{% navtab "gpt-4.1-mini" %}

Notice the jump in `llm_accuracy` from `14` with orca-mini to `88` with gpt-4.1-mini:

```json
{
  "workspace_name": "default",
  "workspace": "3ec2d3e1-92d8-abcd-b3da-2732abcdefgh",
  "ai": {
    "ai-llm-as-judge": {
      "meta": {
        "request_mode": "oneshot",
        "provider_name": "openai",
        "request_model": "gpt-4.1-mini",
        "response_model": "gpt-4o-2024-08-06",
        "llm_latency": 1525,
        "plugin_id": "8ccfd8b8-f5bc-4af9-8951-123456789abc"
      },
      "payload": {
        "...": "..."
      },
      "tried_targets": [
        {
          "route_type": "llm/v1/chat",
          "upstream_scheme": "https",
          "upstream_uri": "/v1/chat/completions",
          "ip": "172.66.0.243",
          "port": 443,
          "host": "api.openai.com",
          "provider": "openai",
          "model": "gpt-4.1-mini"
        }
      ],
      "usage": {
        "completion_tokens": 266,
        "llm_accuracy": 88,
        "prompt_tokens": 15,
        "total_tokens": 281,
        "time_to_first_token": 1525,
        "time_per_token": 22.38,
        "prompt_tokens_details": {
          "cached_tokens": 0,
          "audio_tokens": 0
        },
        "completion_tokens_details": {
          "reasoning_tokens": 0,
          "audio_tokens": 0,
          "accepted_prediction_tokens": 0,
          "rejected_prediction_tokens": 0
        }
      }
    }
  }
}
```
{:.no-copy-code}

{% endnavtab %}
{% endnavtabs %}
