---
title: Send asynchronous requests to LLMs
permalink: /how-to/send-asynchronous-llm-requests/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy
    url: /plugins/ai-proxy/

description: Reduce costs by using llm/v1/files and llm/v1/batches route_types to send asynchronous batched requests to LLMs.

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
  q: How do I send asynchronous batched requests to large language models (LLMs) to reduce costs?
  a: |
    Upload a batch file in JSONL format to the `/files` Route, then create a batch request via the `/batches` Route to process multiple LLM queries asynchronously, and finally retrieve the batched responses from the `/files` Route. Batching requests allows you to reduce LLM usage costs by:
    - Minimizing per-request overhead
    - Avoiding rate-limit penalties
    - Enabling efficient model usage
    - Reducing wasted retries

tools:
  - deck

prereqs:
  inline:
    - title: OpenAI
      include_content: prereqs/openai
      icon_url: /assets/icons/openai.svg
    - title: Batch .jsonl file
      content: |
        To complete this tutorial, create a `batch.jsonl` to generate asynchronous batched LLM responses. We use `/v1/chat/completions` because it handles chat-based generation requests, enabling the LLM to produce conversational completions in batch mode.

        Run the following command to create the file:

        ```bash
        cat <<EOF > batch.jsonl
        {% include _files/ai-gateway/batch.jsonl %}
        EOF
        ```
        {: data-test-prereqs="block" }
  entities:
    services:
      - files-service
      - batches-service
    routes:
      - files-route
      - batches-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Configure AI Proxy plugins

Configure two separate AI Proxy plugins: one for the `llm/v1/files` Route and another for the `llm/v1/batches` Route. Each Route type requires its own dedicated Gateway Service and Route to function correctly. In this setup, all requests to the files Route are forwarded to `/files` endpoint, while batch requests go to `/batches` endpoint.


AI Proxy plugin for the `route_type: llm/v1/files` :

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      service: files-service
      config:
        model_name_header: false
        route_type: llm/v1/files
        auth:
          header_name: Authorization
          header_value: Bearer ${openai_api_key}
        model:
          provider: openai
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}

AI Proxy plugin for the `route_type: llm/v1/batches`:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      service: batches-service
      config:
        model_name_header: false
        route_type: llm/v1/batches
        auth:
          header_name: Authorization
          header_value: Bearer ${openai_api_key}
        model:
          provider: openai
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}

## Upload a .jsonl file for batching

Use the following command to upload your [batching file](./#batch-jsonl-file) to the `/files` route:

<!-- vale off -->
{% validation request-check %}
url: "/files"
status_code: 200
method: POST
form_data:
  purpose: "batch"
  file: "@batch.jsonl"
file_dir: ai-gateway
extract_body:
  - name: 'id'
    variable: FILE_ID
{% endvalidation %}
<!-- vale on -->


You will see a JSON response like this:

```json
{
  "object": "file",
  "id": "file-abc123xyz456789lmn0pq",
  "purpose": "batch",
  "filename": "1.jsonl",
  "bytes": 1672,
  "created_at": 1751281528,
  "expires_at": null,
  "status": "processed",
  "status_details": null
}
```
{:.no-copy-code}

Copy the file ID from the response, you will need it to create a batch. Export it as an environment variable:

```bash
export FILE_ID=YOUR_FILE_ID
```

## Create a batching request

Send a POST request to the `/batches` Route to create a batch using your uploaded file:

{:.info}
> The completion window must be set to `24h`, as it's the only value currently supported by the [OpenAI `/batches` API](https://platform.openai.com/docs/api-reference/batch/create).
>
> In this example we use the `/v1/chat/completions` route for batching because we are sending multiple structured chat-style prompts in OpenAI's chat completions format to be processed in bulk.

<!-- vale off -->
{% validation request-check %}
url: '/batches'
method: POST
status_code: 200
body:
  input_file_id: $FILE_ID
  endpoint: "/v1/chat/completions"
  completion_window: "24h"
extract_body:
  - name: 'id'
    variable: BATCH_ID
{% endvalidation %}
<!-- vale on -->

You will receive a response similar to:

```json
{
  "id": "batch_d41d8cd98f00b204e9800998ecf8427e",
  "object": "batch",
  "endpoint": "/v1/chat/completions",
  "errors": null,
  "input_file_id": "file-TgJnwX6nHPPvb5W4abcdef",
  "completion_window": "24h",
  "status": "validating",
  "output_file_id": null,
  "error_file_id": null,
  "created_at": 1751281814,
  "in_progress_at": null,
  "expires_at": 1751368214,
  "finalizing_at": null,
  "completed_at": null,
  "failed_at": null,
  "expired_at": null,
  "cancelling_at": null,
  "cancelled_at": null,
  "request_counts": {
    "total": 0,
    "completed": 0,
    "failed": 0
  },
  "metadata": null
}
```
{:.no-copy-code}


Copy the batch ID from this response to check the batch status and export it as an environment variable by running the following command in your terminal:

```bash
export BATCH_ID=YOUR_BATCH_ID
```

## Check batching status

Wait for a moment for the batching request to be completed, then check the status of your batch by sending the following request:

<!-- vale off -->
{% validation request-check %}
url: /batches/$BATCH_ID
status_code: 200
extract_body:
  - name: 'output_file_id'
    variable: OUTPUT_FILE_ID
retry: true
{% endvalidation %}
<!-- vale on -->

A completed batch response looks like this:

```json
{
  "id": "batch_a1b2c3d4e5f60789abcdef0123456789",
  "object": "batch",
  "endpoint": "/v1/chat/completions",
  "errors": null,
  "input_file_id": "file-XyZ123abc456Def789Ghij",
  "completion_window": "24h",
  "status": "completed",
  "output_file_id": "file-Lmn987Qrs654Tuv321Wxyz",
  "error_file_id": null,
  "created_at": 1751281998,
  "in_progress_at": 1751281999,
  "expires_at": 1751368398,
  "finalizing_at": 1751282173,
  "completed_at": 1751282174,
  "failed_at": null,
  "expired_at": null,
  "cancelling_at": null,
  "cancelled_at": null,
  "request_counts": {
    "total": 5,
    "completed": 5,
    "failed": 0
  },
  "metadata": null
}
```
{:.no-copy-code}

You can notice The `"request_counts"` object shows that all five requests in the batch were successfully completed (`"completed": 5`, `"failed": 0`).


Now, you can copy the `output_file_id` to retrieve your batched responses and export it as environment variable:

```bash
export OUTPUT_FILE_ID=YOUR_OUTPUT_FILE_ID
```

The output file ID will only be available once the batch request has completed. If the status is `"in_progress"`, it won’t be set yet.

## Retrieve batched responses

Now, we can download the batched responses from the `/files` endpoint by appending `/content` to the file ID URL. For details, see the [OpenAI API documentation](https://platform.openai.com/docs/api-reference/files/retrieve-contents).

{% validation request-check %}
url: "/files/$OUTPUT_FILE_ID/content"
status_code: 200
output: batched-response.jsonl
{% endvalidation %}


This command saves the batched responses to the `batched-response.jsonl` file.

The batched response file contains one JSON object per line, each representing a single batched request's response. Here is an example of content from `batched-response.jsonl` which contains the individual completion results for each request we submitted in the batch input file:


```json
{"id": "batch_req_686271fdfdd88190afc7c1da9a67f59f", "custom_id": "prod1", "response": {"status_code": 200, "request_id": "31043970a729289021c4de02f4d9d4f4", "body": {"id": "chatcmpl-Bo6lqlrGydPEceKXlWmh0gYIGpA4o", "object": "chat.completion", "created": 1751282126, "model": "gpt-4o-mini-2024-07-18", "choices": [{"index": 0, "message": {"role": "assistant", "content": "**Elevate Your Hydration Game: The Ultimate Stainless Steel Water Bottle**\n\nIntroducing the **AdventureHydrate Stainless Steel Water Bottle** — your perfect companion for all outdoor adventures! Whether you're hiking rugged trails, camping under the stars, or simply enjoying a day at the beach, this water bottle is designed", "refusal": null, "annotations": []}, "logprobs": null, "finish_reason": "length"}], "usage": {"prompt_tokens": 33, "completion_tokens": 60, "total_tokens": 93, "prompt_tokens_details": {"cached_tokens": 0, "audio_tokens": 0}, "completion_tokens_details": {"reasoning_tokens": 0, "audio_tokens": 0, "accepted_prediction_tokens": 0, "rejected_prediction_tokens": 0}}, "service_tier": "default", "system_fingerprint": "fp_34a54ae93c"}}, "error": null}
{"id": "batch_req_686271fe13148190b00f0d8d4a237e0c", "custom_id": "prod2", "response": {"status_code": 200, "request_id": "75e72b39c1e25a076486ad0a56ef9040", "body": {"id": "chatcmpl-Bo6jypac8GcC4dEE91NiERhqbI68M", "object": "chat.completion", "created": 1751282010, "model": "gpt-4o-mini-2024-07-18", "choices": [{"index": 0, "message": {"role": "assistant", "content": "**Product Description: NoiseBlock Pro Wireless Noise-Cancelling Headphones**\n\nExperience the ultimate in sound clarity and comfort with the NoiseBlock Pro Wireless Noise-Cancelling Headphones. Designed for audiophiles and casual listeners alike, these state-of-the-art headphones combine advanced noise-cancellation technology with an", "refusal": null, "annotations": []}, "logprobs": null, "finish_reason": "length"}], "usage": {"prompt_tokens": 36, "completion_tokens": 60, "total_tokens": 96, "prompt_tokens_details": {"cached_tokens": 0, "audio_tokens": 0}, "completion_tokens_details": {"reasoning_tokens": 0, "audio_tokens": 0, "accepted_prediction_tokens": 0, "rejected_prediction_tokens": 0}}, "service_tier": "default", "system_fingerprint": "fp_34a54ae93c"}}, "error": null}
{"id": "batch_req_686271fe20d48190acc5b34cb9a3dca9", "custom_id": "prod3", "response": {"status_code": 200, "request_id": "4e27db53d730a1404b1f43953f6191e5", "body": {"id": "chatcmpl-Bo6k2pEvK0tTUmjvdQ3H1ysGnCn9d", "object": "chat.completion", "created": 1751282014, "model": "gpt-4o-mini-2024-07-18", "choices": [{"index": 0, "message": {"role": "assistant", "content": "### Elevate Your Everyday with the Red Luxe Leather Wallet\n\nStep into sophistication with our stunning Red Luxe Leather Wallet, where style meets functionality in perfect harmony. Crafted from premium, supple leather, this wallet boasts a rich, vibrant hue that adds a bold statement to any ensemble. \n\n**Features:**\n", "refusal": null, "annotations": []}, "logprobs": null, "finish_reason": "length"}], "usage": {"prompt_tokens": 32, "completion_tokens": 60, "total_tokens": 92, "prompt_tokens_details": {"cached_tokens": 0, "audio_tokens": 0}, "completion_tokens_details": {"reasoning_tokens": 0, "audio_tokens": 0, "accepted_prediction_tokens": 0, "rejected_prediction_tokens": 0}}, "service_tier": "default", "system_fingerprint": "fp_62a23a81ef"}}, "error": null}
{"id": "batch_req_686271fe2f14819099e646c0c43c364c", "custom_id": "prod4", "response": {"status_code": 200, "request_id": "1c26a143c432ee43e36a7fb302d56a89", "body": {"id": "chatcmpl-Bo6k8mCzyUcgZNWEAEL6LzBdmuaIy", "object": "chat.completion", "created": 1751282020, "model": "gpt-4o-mini-2024-07-18", "choices": [{"index": 0, "message": {"role": "assistant", "content": "**Product Description: Wireless Waterproof Bluetooth Speaker**\n\n**Elevate Your Sound Experience Anywhere!**\n\nIntroducing the Ultimate Wireless Waterproof Bluetooth Speaker, designed for the adventurer in you! Whether you're lounging by the pool, trekking in the mountains, or hosting a beach party, this speaker combines impressive audio quality with robust", "refusal": null, "annotations": []}, "logprobs": null, "finish_reason": "length"}], "usage": {"prompt_tokens": 31, "completion_tokens": 60, "total_tokens": 91, "prompt_tokens_details": {"cached_tokens": 0, "audio_tokens": 0}, "completion_tokens_details": {"reasoning_tokens": 0, "audio_tokens": 0, "accepted_prediction_tokens": 0, "rejected_prediction_tokens": 0}}, "service_tier": "default", "system_fingerprint": "fp_34a54ae93c"}}, "error": null}
{"id": "batch_req_686271fe3c108190bdd6a64f7231191a", "custom_id": "prod5", "response": {"status_code": 200, "request_id": "3613bb32e5afef94cab0ad41c19ee2dc", "body": {"id": "chatcmpl-Bo6jwAbdiD35WsrppVDcIR15yJQNr", "object": "chat.completion", "created": 1751282008, "model": "gpt-4o-mini-2024-07-18", "choices": [{"index": 0, "message": {"role": "assistant", "content": "Discover the ultimate travel companion with our Compact and Durable Travel Backpack. Designed for the modern traveler, this sleek backpack features a padded laptop compartment that securely fits devices up to 15.6 inches, ensuring your tech stays safe on the go. Crafted from high-quality, water-resistant materials, it withstands", "refusal": null, "annotations": []}, "logprobs": null, "finish_reason": "length"}], "usage": {"prompt_tokens": 33, "completion_tokens": 60, "total_tokens": 93, "prompt_tokens_details": {"cached_tokens": 0, "audio_tokens": 0}, "completion_tokens_details": {"reasoning_tokens": 0, "audio_tokens": 0, "accepted_prediction_tokens": 0, "rejected_prediction_tokens": 0}}, "service_tier": "default", "system_fingerprint": "fp_34a54ae93c"}}, "error": null}
```
{:.no-copy-code}

