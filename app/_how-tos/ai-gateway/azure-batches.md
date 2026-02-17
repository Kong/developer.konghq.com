---
title: Send batch requests to Azure OpenAI LLMs
permalink: /how-to/azure-batches/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
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
    Package your prompts into a JSONL file and upload it to the `/files` endpoint. Then launch a batch job with `/batches` to process everything asynchronously, and download the output from /files once the run completes.

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
              > Use a `globalbatch` or `datazonebatch` deployment type for batch operations since standard deployments (`GlobalStandard`) cannot process batch files.

           2. Export the API key and deployment ID:
              ```bash
              export DECK_AZURE_OPENAI_API_KEY='YOUR_AZURE_OPENAI_MODEL_API_KEY'
              export DECK_AZURE_DEPLOYMENT_ID='YOUR_AZURE_OPENAI_DEPLOYMENT_NAME'
              ```
    - title: Batch .jsonl file
      content: |
        To complete this tutorial, create a `batch.jsonl` to generate asynchronous batched LLM responses. We use `/v1/chat/completions` because it handles chat-based generation requests, instructing the LLM to produce conversational completions in batch mode.

        Run the following command to create the file:

        ```bash
        cat <<EOF > batch.jsonl
        {% include _files/ai-gateway/batch.jsonl %}
        EOF

        ```
        {: data-test-prereqs="block"}
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
## Configure AI Proxy plugins for /files route

Let's create an AI Proxy plugin for the `llm/v1/files` route type. It will be used to handle the upload and retrieval of JSONL files containing batch input and output data. This plugin instance ensures that input data is correctly staged for batch processing and that the results can be downloaded once the batch job completes.

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

## Configure AI Proxy plugins for /batches route

Next, create an AI Proxy plugin for the `llm/v1/batches` route. This plugin manages the submission, monitoring, and retrieval of asynchronous batch jobs. It communicates with Azure OpenAI's batch deployment to process multiple LLM requests in a batch.

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

Now, let's use the following command to upload our [batching file](/#batch-jsonl-file) to the `/llm/v1/files` route:

<!-- vale off -->
{% validation request-check %}
url: "/files"
status_code: 201
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

Once processed, you will see a JSON response like this:

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

Now, we can send a `POST` request to the `/batches` Route to create a batch using our uploaded file:

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
  "id": "batch_379f1007-8057-4f43-be38-12f3d456c7da",
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
  "id": "batch_379f1007-8057-4f43-be38-12f3d456c7da",
  "in_progress_at": null,
  "input_file_id": "file-da4364d8fd714dd9b29706b91236ab02",
  "errors": null,
  "metadata": null,
  "object": "batch",
  "output_file_id": "file-93d91f55-0418-abcd-1234-81f4bb334951",
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

{% validation request-check %}
url: "/files/$OUTPUT_FILE_ID/content"
status_code: 200
output: batched-response.jsonl
{% endvalidation %}

This command saves the batched responses to the `batched-response.jsonl` file.

The batched response file contains one JSON object per line, each representing a single batched request's response. Here is an example of content from `batched-response.jsonl` which contains the individual completion results for each request we submitted in the batch input file:


```json
{"custom_id": "prod4", "response": {"body": {"id": "chatcmpl-AB12CD34EF56GH78IJ90KL12MN", "object": "chat.completion", "created": 1761909664, "model": "gpt-4o-2024-11-20", "choices": [{"index": 0, "message": {"role": "assistant", "content": "**EcoFlow Smart Shower Head: Revolutionize Your Daily Routine While Saving Water**\n\nExperience the perfect blend of luxury, sustainability, and smart technology with the **EcoFlow Smart Shower Head** — a cutting-edge solution for modern households looking to conserve water without compromising on comfort. Designed to elevate your shower experience", "refusal": null, "annotations": []}, "finish_reason": "length", "logprobs": null}], "usage": {"completion_tokens": 60, "prompt_tokens": 30, "total_tokens": 90}, "system_fingerprint": "fp_random1234"},"request_id": "req-111aaa22-bb33-cc44-dd55-ee66ff778899", "status_code": 200}, "error": null}
{"custom_id": "prod3", "response": {"body": {"id": "chatcmpl-ZX98YW76VU54TS32RQ10PO98LK", "object": "chat.completion", "created": 1761909664, "model": "gpt-4o-2024-11-20", "choices": [{"index": 0, "message": {"role": "assistant", "content": "**Eco-Friendly Elegance: Biodegradable Bamboo Kitchen Utensil Set**\n\nElevate your cooking experience while making a positive impact on the planet with our **Biodegradable Bamboo Kitchen Utensil Set**. Crafted from 100% natural, sustainably sourced bamboo, this set combines durability, functionality", "refusal": null, "annotations": []}, "finish_reason": "length", "logprobs": null}], "usage": {"completion_tokens": 60, "prompt_tokens": 31, "total_tokens": 91}, "system_fingerprint": "fp_random1234"},"request_id": "req-222bbb33-cc44-dd55-ee66-ff7788990011", "status_code": 200}, "error": null}
{"custom_id": "prod1", "response": {"body": {"id": "chatcmpl-MN34OP56QR78ST90UV12WX34YZ", "object": "chat.completion", "created": 1761909664, "model": "gpt-4o-2024-11-20", "choices": [{"index": 0, "message": {"role": "assistant", "content": "**Illuminate Your Garden with Brilliance: The Solar-Powered Smart Garden Light**  \n\nTransform your outdoor space into a haven of sustainable beauty with the **Solar-Powered Smart Garden Light**—a perfect blend of modern innovation and eco-friendly design. Powered entirely by the sun, this smart light delivers effortless", "refusal": null, "annotations": []}, "finish_reason": "length", "logprobs": null}], "usage": {"completion_tokens": 60, "prompt_tokens": 30, "total_tokens": 90}, "system_fingerprint": "fp_random1234"},"request_id": "req-333ccc44-dd55-ee66-ff77-889900112233", "status_code": 200}, "error": null}
{"custom_id": "prod5", "response": {"body": {"id": "chatcmpl-AQ12WS34ED56RF78TG90HY12UJ", "object": "chat.completion", "created": 1761909664, "model": "gpt-4o-2024-11-20", "choices": [{"index": 0, "message": {"role": "assistant", "content": "Breathe easy with our compact indoor air purifier, designed to deliver fresh and clean air using natural filters. This eco-friendly purifier quietly removes allergens, dust, and odors without synthetic materials, making it perfect for any small space. Stylish, efficient, and sustainable—experience pure air, naturally.", "refusal": null, "annotations": []}, "finish_reason": "stop", "logprobs": null}], "usage": {"completion_tokens": 59, "prompt_tokens": 33, "total_tokens": 92}, "system_fingerprint": "fp_random1234"},"request_id": "req-444ddd55-ee66-ff77-8899-001122334455", "status_code": 200}, "error": null}
{"custom_id": "prod2", "response": {"body": {"id": "chatcmpl-PO98LK76JI54HG32FE10DC98VB", "object": "chat.completion", "created": 1761909664, "model": "gpt-4o-2024-11-20", "choices": [{"index": 0, "message": {"role": "assistant", "content": "**EcoSmart Pro Wi-Fi Thermostat: Energy Efficiency Meets Smart Technology**  \n\nUpgrade your home’s comfort and save energy with the EcoSmart Pro Wi-Fi Thermostat. Designed for modern living, this sleek and intuitive thermostat lets you take control of your heating and cooling while minimizing energy waste. Whether you're", "refusal": null, "annotations": []}, "finish_reason": "length", "logprobs": null}], "usage": {"completion_tokens": 60, "prompt_tokens": 31, "total_tokens": 91}, "system_fingerprint": "fp_random1234"},"request_id": "req-555eee66-ff77-8899-0011-223344556677", "status_code": 200}, "error": null}
```
{:.no-copy-code}