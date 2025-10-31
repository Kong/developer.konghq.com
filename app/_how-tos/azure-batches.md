---
title: Send batch requests to Azure OpenAI LLMs
content_type: how_to
related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI Proxy
    url: /plugins/ai-proxy/

description: Reduce costs by using llm/v1/files and llm/v1/batches route_types to send asynchronous batched requests to Azure OpenAI.

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
  - azure

tldr:
  q: How can I run many Azure OpenAI LLM requests at once?
  a: |
    Package your prompts into a JSONL file and upload it to the /files endpoint. Then launch a batch job with /batches to process everything asynchronously, and download the output from /files once the run completes. Batch execution reduces costs by:
    - Cutting per-request overhead
    - Preventing rate-limit penalties
    - Using model capacity more efficiently
    - Lowering unnecessary retry traffic

tools:
  - deck

prereqs:
  inline:
    - title: Azure OpenAI
      icon_url: /assets/icons/azure.svg
      content: |
        This tutorial uses Azure OpenAI service. Configure it as follows:

        1. [Create an Azure account](https://azure.microsoft.com/en-us/get-started/azure-portal).
        2. In the Azure Portal, click **Create a resource**.
        3. Search for **Azure OpenAI** and select **Azure OpenAI Service**.
        4. Configure your Azure resource.
        5. Export your instance name:
           ```bash
           export DECK_AZURE_INSTANCE_NAME='YOUR_AZURE_RESOURCE_NAME'
           ```
        6. Deploy your model in [Azure AI Foundry](https://ai.azure.com/):
           1. Go to **My assets → Models and deployments → Deploy model**.
           {:.warning}
           > Standard deployments (`GlobalStandard`) like `gpt-4o` or `gpt-4o-mini` **cannot process batch files**. Use a `globalbatch` or `datazonebatch` deployment for batch operations.
           2. Export the API key and deployment ID:
           ```bash
           export DECK_AZURE_OPENAI_API_KEY='YOUR_AZURE_OPENAI_MODEL_API_KEY'
           export DECK_AZURE_DEPLOYMENT_ID='YOUR_AZURE_OPENAI_DEPLOYMENT_NAME'```
    - title: Batch .jsonl file
      content: |
        To complete this tutorial, create a `batch.jsonl` to generate asynchronous batched LLM responses. We use `/v1/chat/completions` because it handles chat-based generation requests, enabling the LLM to produce conversational completions in batch mode.

        Run the following command to create the file:

        ```bash
        cat <<EOF > batch.jsonl
        {"custom_id": "prod1", "method": "POST", "url": "/v1/chat/completions", "body": {"model": "gpt-4o", "messages": [{"role": "system", "content": "You are a helpful assistant."}, {"role": "user", "content": "Write a compelling product description for a stainless steel water bottle suitable for outdoor activities."}], "max_tokens": 60}}
        {"custom_id": "prod2", "method": "POST", "url": "/v1/chat/completions", "body": {"model": "gpt-4o", "messages": [{"role": "system", "content": "You are a helpful assistant."}, {"role": "user", "content": "Write a product description for a pair of wireless noise-cancelling headphones with long battery life."}], "max_tokens": 60}}
        {"custom_id": "prod3", "method": "POST", "url": "/v1/chat/completions", "body": {"model": "gpt-4o", "messages": [{"role": "system", "content": "You are a helpful assistant."}, {"role": "user", "content": "Write an engaging product description for a stylish red leather wallet with multiple compartments."}], "max_tokens": 60}}
        {"custom_id": "prod4", "method": "POST", "url": "/v1/chat/completions", "body": {"model": "gpt-4o", "messages": [{"role": "system", "content": "You are a helpful assistant."}, {"role": "user", "content": "Write a detailed product description for a Bluetooth wireless speaker with waterproof features."}], "max_tokens": 60}}
        {"custom_id": "prod5", "method": "POST", "url": "/v1/chat/completions", "body": {"model": "gpt-4o", "messages": [{"role": "system", "content": "You are a helpful assistant."}, {"role": "user", "content": "Write a concise product description for a compact and durable travel backpack with laptop compartment."}], "max_tokens": 60}}
        EOF
        ```
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

automated_tests: false
---


## Configure AI Proxy plugins

Create two separate AI Proxy plugins: one for `llm/v1/files` and one for `llm/v1/batches`. Replace your credentials with the environment variables defined above.

**Files route plugin (`llm/v1/files`)**:

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
          header_value: Bearer ${azure_key}
        model:
          provider: azure
          options:
            azure_api_version: "2025-01-01-preview"
            azure_instance: ${azure_instance}
            azure_deployment_id: ${azure_deployment}
variables:
  azure_key:
    value: "$AZURE_OPENAI_API_KEY"
  azure_instance:
    value: "$AZURE_INSTANCE_NAME"
  azure_deployment:
    value: "$AZURE_DEPLOYMENT_ID"
{% endentity_examples %}


**Batches route plugin (`llm/v1/batches`)**:

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
          header_value: Bearer ${azure_key}
        model:
          provider: azure
          options:
            azure_api_version: "2025-01-01-preview"
            azure_instance: ${azure_instance}
            azure_deployment_id: ${azure_deployment}
variables:
  azure_key:
    value: "$AZURE_OPENAI_API_KEY"
  azure_instance:
    value: "$AZURE_INSTANCE_NAME"
  azure_deployment:
    value: "$AZURE_DEPLOYMENT_ID"
{% endentity_examples %}

## Upload a .jsonl file for batching

```bash
curl localhost:8000/files -F purpose="batch" -F file="@batch.jsonl"
```

You will see a JSON response like this:

```json
{
  "status": "processed",
  "bytes": 1648,
  "purpose": "batch",
  "filename": "batch.jsonl",
  "id": "file-da4364d8fd714dd9b29706b91236ab02",
  "created_at": 1761817541,
  "object": "file"
}
```

Now, let's export the file ID:

```bash
export FILE_ID=YOUR_FILE_ID
```

## Create a batching request

Send a POST request to the `/batches` Route to create a batch using your uploaded file:

{:.info}
> The completion window must be set to `24h`, as it's the only value currently supported by the [OpenAI `/batches` API](https://platform.openai.com/docs/api-reference/batch/create).
>
> In this example we use the `/v1/chat/completions` route for batching because we are sending multiple structured chat-style prompts in OpenAI's chat completions format to be processed in bulk.


```bash
curl http://localhost:8000/batches \
  -H "Content-Type: application/json" \
  -d "{
    \"input_file_id\": \"$FILE_ID\",
    \"endpoint\": \"/v1/chat/completions\",
    \"completion_window\": \"24h\"
  }"
```

You will receive a response similar to:

```json
{
  "cancelled_at": null,
  "cancelling_at": null,
  "completed_at": null,
  "completion_window": "24h",
  "created_at": 1761817562,
  "error_file_id": "",
  "expired_at": null,
  "expires_at": 1761903959,
  "failed_at": null,
  "finalizing_at": null,
  "id": "batch_379f1007-8057-4f43-be38-73f3d233c5da",
  "in_progress_at": null,
  "input_file_id": "file-da4364d8fd714dd9b29706b91236ab02",
  "errors": null,
  "metadata": null,
  "object": "batch",
  "output_file_id": "",
  "request_counts": {
    "total": 0,
    "completed": 0,
    "failed": 0
  },
  "status": "validating",
  "endpoint": ""
}
```
{:.no-copy-code}


Copy the batch ID from this response to check the batch status and export it as an environment variable by running the following command in your terminal:

```bash
export BATCH_ID=YOUR_BATCH_ID
```

## Check batching status

Wait for a moment for the batching request to be completed, then check the status of your batch by sending the following request:

{% validation request-check %}
url: /batches/$BATCH_ID
{% endvalidation %}

A completed batch response looks like this:

```json
{
  "cancelled_at": null,
  "cancelling_at": null,
  "completed_at": 1761817685,
  "completion_window": "24h",
  "created_at": 1761817562,
  "error_file_id": null,
  "expired_at": null,
  "expires_at": 1761903959,
  "failed_at": null,
  "finalizing_at": 1761817662,
  "id": "batch_379f1007-8057-4f43-be38-73f3d233c5da",
  "in_progress_at": null,
  "input_file_id": "file-da4364d8fd714dd9b29706b91236ab02",
  "errors": null,
  "metadata": null,
  "object": "batch",
  "output_file_id": "file-93d91f55-0418-422b-915f-81f4bb334951",
  "request_counts": {
    "total": 5,
    "completed": 5,
    "failed": 0
  },
  "status": "completed",
  "endpoint": "/v1/chat/completions"
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

```bash
curl http://localhost:8000/files/$OUTPUT_FILE_ID/content > batched-response.jsonl
```

This command saves the batched responses to the `batched-response.jsonl` file.

The batched response file contains one JSON object per line, each representing a single batched request's response. Here is an example of content from `batched-response.jsonl` which contains the individual completion results for each request we submitted in the batch input file:


```json
{"custom_id": "prod3", "response": {"body": {"id": "chatcmpl-CWJXmqUroUxgUhqLZH51MAKNCSz0w", "object": "chat.completion", "created": 1761817658, "model": "gpt-4o-2024-11-20", "choices": [{"index": 0, "message": {"role": "assistant", "content": "Introducing the **Radiance Red Leather Wallet** – where timeless elegance meets modern functionality. Crafted from premium, supple leather with a rich crimson hue, this wallet effortlessly blends sophistication and practicality for those who value both style and substance.\n\nDesigned for the organized individual, this wallet boasts **multiple thoughtfully arranged compartments**", "refusal": null, "annotations": []}, "finish_reason": "length", "logprobs": null, "content_filter_results": {"hate": {"filtered": false, "severity": "safe"}, "self_harm": {"filtered": false, "severity": "safe"}, "sexual": {"filtered": false, "severity": "safe"}, "violence": {"filtered": false, "severity": "safe"}}}], "usage": {"completion_tokens": 60, "prompt_tokens": 32, "total_tokens": 92, "completion_tokens_details": {"accepted_prediction_tokens": 0, "audio_tokens": 0, "reasoning_tokens": 0, "rejected_prediction_tokens": 0}, "prompt_tokens_details": {"audio_tokens": 0, "cached_tokens": 0}}, "system_fingerprint": "fp_ee1d74bde0", "prompt_filter_results": [{"prompt_index": 0, "content_filter_results": {"hate": {"filtered": false, "severity": "safe"}, "jailbreak": {"filtered": false, "detected": false}, "self_harm": {"filtered": false, "severity": "safe"}, "sexual": {"filtered": false, "severity": "safe"}, "violence": {"filtered": false, "severity": "safe"}}}]}, "request_id": "1e7c5640-266a-4257-84a1-acd6883e0155", "status_code": 200}, "error": null}
{"custom_id": "prod5", "response": {"body": {"id": "chatcmpl-CWJXmtkylxCEKgv5J9WkPiHupqETG", "object": "chat.completion", "created": 1761817658, "model": "gpt-4o-2024-11-20", "choices": [{"index": 0, "message": {"role": "assistant", "content": "This compact and durable travel backpack is designed for modern adventurers. Featuring a padded laptop compartment, multiple organizer pockets, and water-resistant materials, it offers reliable protection for your essentials while staying lightweight and stylish. Perfect for commuting, exploring, or work trips, its ergonomic design ensures comfort on the go.", "refusal": null, "annotations": []}, "finish_reason": "length", "logprobs": null, "content_filter_results": {"hate": {"filtered": false, "severity": "safe"}, "self_harm": {"filtered": false, "severity": "safe"}, "sexual": {"filtered": false, "severity": "safe"}, "violence": {"filtered": false, "severity": "safe"}}}], "usage": {"completion_tokens": 60, "prompt_tokens": 33, "total_tokens": 93, "completion_tokens_details": {"accepted_prediction_tokens": 0, "audio_tokens": 0, "reasoning_tokens": 0, "rejected_prediction_tokens": 0}, "prompt_tokens_details": {"audio_tokens": 0, "cached_tokens": 0}}, "system_fingerprint": "fp_ee1d74bde0", "prompt_filter_results": [{"prompt_index": 0, "content_filter_results": {"hate": {"filtered": false, "severity": "safe"}, "jailbreak": {"filtered": false, "detected": false}, "self_harm": {"filtered": false, "severity": "safe"}, "sexual": {"filtered": false, "severity": "safe"}, "violence": {"filtered": false, "severity": "safe"}}}]}, "request_id": "917858af-a6de-47bb-8037-dbe84e9e621c", "status_code": 200}, "error": null}
{"custom_id": "prod1", "response": {"body": {"id": "chatcmpl-CWJXml27AnRMBbdsilDK1xGRI1AG6", "object": "chat.completion", "created": 1761817658, "model": "gpt-4o-2024-11-20", "choices": [{"index": 0, "message": {"role": "assistant", "content": "**Stay Hydrated Anywhere with the Ultimate Stainless Steel Water Bottle**\n\nElevate your outdoor adventures with the perfect companion: our premium stainless steel water bottle. Built for durability and designed for convenience, this bottle is your go-to choice for hiking, camping, and all your active pursuits.\n\nCrafted from high", "refusal": null, "annotations": []}, "finish_reason": "length", "logprobs": null, "content_filter_results": {"hate": {"filtered": false, "severity": "safe"}, "self_harm": {"filtered": false, "severity": "safe"}, "sexual": {"filtered": false, "severity": "safe"}, "violence": {"filtered": false, "severity": "safe"}}}], "usage": {"completion_tokens": 60, "prompt_tokens": 33, "total_tokens": 93, "completion_tokens_details": {"accepted_prediction_tokens": 0, "audio_tokens": 0, "reasoning_tokens": 0, "rejected_prediction_tokens": 0}, "prompt_tokens_details": {"audio_tokens": 0, "cached_tokens": 0}}, "system_fingerprint": "fp_ee1d74bde0", "prompt_filter_results": [{"prompt_index": 0, "content_filter_results": {"hate": {"filtered": false, "severity": "safe"}, "jailbreak": {"filtered": false, "detected": false}, "self_harm": {"filtered": false, "severity": "safe"}, "sexual": {"filtered": false, "severity": "safe"}, "violence": {"filtered": false, "severity": "safe"}}}]}, "request_id": "416a869e-42fc-4b91-9a14-0527db68259e", "status_code": 200}, "error": null}
{"custom_id": "prod4", "response": {"body": {"id": "chatcmpl-CWJXm0SK0SSzBwNUZNsbhb5GS82i0", "object": "chat.completion", "created": 1761817658, "model": "gpt-4o-2024-11-20", "choices": [{"index": 0, "message": {"role": "assistant", "content": "**Product Description: UltimateSound AquaWave Bluetooth Wireless Speaker**\n\nExperience unparalleled sound quality and portability with the UltimateSound AquaWave Bluetooth Wireless Speaker, your ideal companion for adventure, relaxation, and everything in between. Packed with innovative features, this waterproof speaker is designed to elevate your audio experience wherever life takes you", "refusal": null, "annotations": []}, "finish_reason": "length", "logprobs": null, "content_filter_results": {"hate": {"filtered": false, "severity": "safe"}, "self_harm": {"filtered": false, "severity": "safe"}, "sexual": {"filtered": false, "severity": "safe"}, "violence": {"filtered": false, "severity": "safe"}}}], "usage": {"completion_tokens": 60, "prompt_tokens": 31, "total_tokens": 91, "completion_tokens_details": {"accepted_prediction_tokens": 0, "audio_tokens": 0, "reasoning_tokens": 0, "rejected_prediction_tokens": 0}, "prompt_tokens_details": {"audio_tokens": 0, "cached_tokens": 0}}, "system_fingerprint": "fp_ee1d74bde0", "prompt_filter_results": [{"prompt_index": 0, "content_filter_results": {"hate": {"filtered": false, "severity": "safe"}, "jailbreak": {"filtered": false, "detected": false}, "self_harm": {"filtered": false, "severity": "safe"}, "sexual": {"filtered": false, "severity": "safe"}, "violence": {"filtered": false, "severity": "safe"}}}]}, "request_id": "c84babdb-a9f5-413f-8582-85a1eecfae00", "status_code": 200}, "error": null}
{"custom_id": "prod2", "response": {"body": {"id": "chatcmpl-CWJXm4JBpFXUecJqkPiTyeurKVmLZ", "object": "chat.completion", "created": 1761817658, "model": "gpt-4o-2024-11-20", "choices": [{"index": 0, "message": {"role": "assistant", "content": "**Ultimate Sound Freedom: Wireless Noise-Cancelling Headphones**\n\nExperience unparalleled audio performance with our premium wireless noise-cancelling headphones designed to deliver crystal-clear sound and immersive silence. Whether you're on a long-haul flight, commuting, or relaxing at home, these headphones let you focus on what matters", "refusal": null, "annotations": []}, "finish_reason": "length", "logprobs": null, "content_filter_results": {"hate": {"filtered": false, "severity": "safe"}, "self_harm": {"filtered": false, "severity": "safe"}, "sexual": {"filtered": false, "severity": "safe"}, "violence": {"filtered": false, "severity": "safe"}}}], "usage": {"completion_tokens": 60, "prompt_tokens": 36, "total_tokens": 96, "completion_tokens_details": {"accepted_prediction_tokens": 0, "audio_tokens": 0, "reasoning_tokens": 0, "rejected_prediction_tokens": 0}, "prompt_tokens_details": {"audio_tokens": 0, "cached_tokens": 0}}, "system_fingerprint": "fp_ee1d74bde0", "prompt_filter_results": [{"prompt_index": 0, "content_filter_results": {"hate": {"filtered": false, "severity": "safe"}, "jailbreak": {"filtered": false, "detected": false}, "self_harm": {"filtered": false, "severity": "safe"}, "sexual": {"filtered": false, "severity": "safe"}, "violence": {"filtered": false, "severity": "safe"}}}]}, "request_id": "2c6e23da-f8c6-49e9-84c2-890720daea19", "status_code": 200}, "error": null}
```