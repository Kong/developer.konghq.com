---
title: Control prompt size with the AI Compressor plugin
permalink: /how-to/compress-llm-prompts/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI RAG Injector
    url: /plugins/ai-rag-injector/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/

description: Learn how to use the AI Compressor plugin alongside the RAG Injector and AI Prompt Decorator plugins to keep prompts lean, reduce latency, and optimize LLM usage for cost efficiency

products:
  - ai-gateway
  - gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.11'

plugins:
  - ai-proxy-advanced
  - ai-rag-injector
  - ai-prompt-decorator

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - openai

tldr:
  q: How do I keep RAG prompts under control and avoid bloated LLM requests?
  a: |
    Use the AI RAG Injector in combination with the AI Prompt Compressor and AI Prompt Decorator plugins to retrieve relevant chunks and keep the final prompt within reasonable limits to prevent increased latency, token limit errors and unexpected bills from LLM providers.

tools:
  - deck

prereqs:
  inline:
    - title: OpenAI
      include_content: prereqs/openai
      icon_url: /assets/icons/openai.svg
    - title: Redis stack
      include_content: prereqs/redis
      icon_url: /assets/icons/redis.svg
    - title: Kong Prompt Compressor service via Cloudsmith
      include_content: prereqs/cloudsmith
      icon_url: /assets/icons/cloudsmith.svg
    - title: Langchain splitters
      include_content: prereqs/langchain
      icon_url: /assets/icons/python.svg

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

First, you'll need to configure the AI Proxy Advanced plugin to proxy prompt requests to your model provider, and handle authentication:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      config:
        targets:
          - route_type: llm/v1/chat
            auth:
              header_name: Authorization
              header_value: Bearer ${openai_api_key}
            model:
              provider: openai
              name: gpt-4o
              options:
                max_tokens: 512
                temperature: 1.0
            logging:
              log_payloads: true
              log_statistics: true
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}

## Configure the AI RAG Injector plugin

Next, configure the AI RAG Injector plugin to insert the RAG context into the user message only, and wrap it with `<LLMLINGUA>` tags so the AI Prompt Compressor plugin can compress it effectively.

{% entity_examples %}
entities:
  plugins:
  - name: ai-rag-injector
    config:
      fetch_chunks_count: 5
      inject_as_role: user
      inject_template: <LLMLINGUA><CONTEXT></LLMLINGUA> | <PROMPT>
      embeddings:
        auth:
          header_name: Authorization
          header_value: Bearer ${openai_api_key}
        model:
          provider: openai
          name: text-embedding-3-large
      vectordb:
        strategy: redis
        redis:
          host: ${redis_host}
          port: 6379
        distance_metric: cosine
        dimensions: 3072
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
  redis_host:
    value: $REDIS_HOST
{% endentity_examples %}

{:.info}
> If your Redis instance runs in a separate Docker container from Kong, use `host.docker.internal` for `vectordb.redis.host`.
>
> If you're using a model other than `text-embedding-3-large`, be sure to update the `vectordb.dimensions` value to match the model’s embedding size.

Once the plugin is created, **copy its `id`** from the Deck response. Then, export it so the ingestion script can reference it later:

```bash
export PLUGIN_ID=<YOUR_PLUGIN_ID>
```

Replace `<YOUR_PLUGIN_ID>` with the actual `id` returned from the plugin creation API response. You’ll need this environment variable when generating the ingestion script that sends chunked content to the plugin.

## Ingest data to Redis

Create an `inject_template.py` file by pasting the following into your terminal. This script fetches a Wikipedia article, splits the content into chunks, and sends each chunk to a local RAG ingestion endpoint.

```python
cat <<EOF > inject_template.py
import requests
from langchain_text_splitters import RecursiveCharacterTextSplitter

plugin_id = "${PLUGIN_ID}"

def get_wikipedia_extract(title):
    url = "https://en.wikipedia.org/w/api.php"
    params = {
        "format": "json",
        "action": "query",
        "prop": "extracts",
        "exlimit": "max",
        "explaintext": True,
        "titles": title,
        "redirects": 1
    }

    response = requests.get(url, params=params)
    response.raise_for_status()
    data = response.json()
    pages = data.get("query", {}).get("pages", {})

    for page_id, page in pages.items():
        if "extract" in page:
            return page["extract"]
    return None

title = "Shark"
text = get_wikipedia_extract(title)

if not text:
    print(f"Failed to retrieve Wikipedia content for: {title}")
    exit()

text = f"# {title}\\n\\n{text}"

text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=100)
docs = text_splitter.create_documents([text])

print(f"Injecting {len(docs)} chunks...")

for doc in docs:
    response = requests.post(
        f"http://localhost:8001/ai-rag-injector/{plugin_id}/ingest_chunk",
        data={"content": doc.page_content}
    )
    print(response.status_code, response.text)
EOF
```
Now, run this script with Python:

```sh
python3 inject_template.py
```

If successful, your terminal will print the following:

```sh
Injecting 91 chunks...
200 {"metadata":{"chunk_id":"c55d8869-6858-496f-83d2-abcdefghij12","ingest_duration":615,"embeddings_tokens_count":2}}
200 {"metadata":{"chunk_id":"fc7d4fd7-21e0-443e-9504-abcdefghij13","ingest_duration":779,"embeddings_tokens_count":231}}
200 {"metadata":{"chunk_id":"8d2aebe1-04e4-40c7-b16f-abcdefghij14","ingest_duration":569,"embeddings_tokens_count":184}}
```
{:.info}
> Wait until all 91 chunks have been injected before moving on to the next step.

## Configure the AI Prompt Compressor plugin

Now, you can configure the AI Prompt Compressor plugin to apply compression to the wrapped RAG context using defined token ranges and compression settings.

{% entity_examples %}
entities:
  plugins:
    - name: ai-prompt-compressor
      config:
        compression_ranges:
          - max_tokens: 100
            min_tokens: 20
            value: 0.8
          - max_tokens: 1000000
            min_tokens: 100
            value: 0.3
        compressor_type: rate
        compressor_url: http://compress-service:8080
        keepalive_timeout: 60000
        log_text_data: false
        stop_on_error: true
        timeout: 10000
{% endentity_examples %}

## Log prompt compression

Before we send requests to our LLM, we need to set up the HTTP Logs plugin to check how many tokens we've managed to save by using our configuration. First, create an HTTP logs plugin:

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

When sending the following request:

 {% validation request-check %}
  url: /anything
  headers:
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
  body:
    messages:
      - role: user
        content: How many species of sharks are there in the world?
  {% endvalidation %}

You should see output like this in your HTTP log plugin endpoint, showing how many tokens were saved through compression:

```json
"compressor": {
  "compress_items": [
    {
      "compress_token_count": 244,
      "original_token_count": 700,
      "compress_value": 0.3,
      "information": "Compression was performed and saved 456 tokens",
      "compressor_model": "microsoft/llmlingua-2-xlm-roberta-large-meetingbank",
      "msg_id": 1,
      "compress_type": "rate",
      "save_token_count": 456
    }
  ],
  "duration": 1092
}
```

## Govern your LLM pipeline

You can use the AI Prompt Decorator plugin to make sure that the LLM responds only to questions related to the injected RAG context.
Let's apply the following configuration:


{% entity_examples %}
entities:
  plugins:
    - name: ai-prompt-decorator
      config:
        prompts:
          append:
          - role: system
            content:  Use only the information passed before the question in the user message. If no data is provided with the question, respond with ‘no internal data available'
{% endentity_examples %}

## Validate final configuration

Now, on any request not related to the ingested content, for example:

{% validation request-check %}
  url: /anything
  headers:
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
  body:
    messages:
      - role: user
        content: Who founded the city of Ravenna?
  {% endvalidation %}

  You will receive the following response:

```
"choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "no internal data available",
    ...
      }
    }
]
```

With the following compression applied:

```json
"compress_items": [
  {
    "compress_token_count": 301,
    "original_token_count": 957,
    "compress_value": 0.3,
    "information": "Compression was performed and saved 656 tokens",
    "compressor_model": "microsoft/llmlingua-2-xlm-roberta-large-meetingbank",
    "msg_id": 1,
    "compress_type": "rate",
    "save_token_count": 656
  }
]
```