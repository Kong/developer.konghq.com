---
title: Use Azure Content Safety plugin
content_type: how_to
related_resources:
  - text: AI Proxy
    url: /plugins/ai-proxy/
  - text: Azure AI Content Safety
    url: /plugins/ai-azure-content-safety/

description: Learn how to use Azure AI Content Safety

products:
    - gateway
    - ai-gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.6'

plugins:
  - ai-proxy
  - key-auth

entities:
  - service
  - route
  - plugin

tags:
    - ai
    - openai
    - ai-gateway

tldr:
    q: How can I use Azure Content Safety plugin with AI Gateway?
    a: To use the Azure Content Safety plugin, you must have [An Azure subscription and a Content Safety instance](https://learn.microsoft.com/en-us/azure/ai-services/content-safety/quickstart-text?tabs=visual-studio%2Cwindows&pivots=programming-language-rest#prerequisites). Then, you must configure an [AI proxy plugin](./#configure-this-ai-proxy-plugin) and then create the [AI Azure Content Safety plugin](./#configure-the-ai-azure-content-safety-plugin).

tools:
    - deck

prereqs:
  inline:
  - title: OpenAI
    include_content: prereqs/openai
    icon_url: /assets/icons/openai.svg
  - title: Azure Content Safety key
    content: |
        To complete this task, you must have an Azure subscription and Content Safety Key (static key generated from Azure Portal). Follow the [quickstart from Microsoft](https://learn.microsoft.com/en-us/azure/ai-services/content-safety/quickstart-text?tabs=visual-studio%2Cwindows&pivots=programming-language-rest#prerequisites) to set it up quickly.
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

## Configure the AI Proxy plugin

Enable the [AI Proxy](/plugins/ai-proxy/) plugin with your OpenAI API key and the model details. In this example, we'll use the GPT-4o model.

{% entity_examples %}
entities:
    plugins:
    - name: ai-proxy
      config:
        route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: Bearer ${openai_key}
        model:
          provider: openai
          name: gpt-4o
variables:
  openai_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}

## Configure the AI Azure Safety plugin

{:.info}
> We configure the plugin with an array of supported categories, as defined by Azure Content Safety:
> * [Content Services REST API documentation](https://azure-ai-content-safety-api-docs.developer.azure-api.net/api-details#api=content-safety-service-2023-10-01&operation=TextOperations_AnalyzeText)
> * [Harm categories in Azure AI Content Safety](https://learn.microsoft.com/en-us/azure/ai-services/content-safety/concepts/harm-categories)

**In this guide, we will use the following configuration first:**

* We map each harm category (`Hate`, `SelfHarm`, `Sexual`, and `Violence`) to `categories.name`.
* We set `rejection_level: 2` for each category.<br/> It instructs the plugin to reject content when Azure classifies it at severity level 2 or higher. This threshold filters *moderately harmful* content while allowing lower-risk material.
- We configure `output_type: FourSeverityLevels`.<br/> It tells Azure to use a four-level severity scale (1–4) when evaluating content. If needed, we could instead configure `output_type: EightSeverityLevels` for finer-grained filtering.

    {:.info}
    > For more details about severity grading, see [Azure severity grading](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/content-filter#content-filtering-categories).

- We also set `reveal_failure_reason: true`<br/> We want to make sure that if the plugin blocks content, the caller receives a clear explanation. Revealing failure reasons helps with transparency and debugging. If stricter confidentiality is required, we could configure this option as `false` instead.

Here’s the full plugin configuration:

{% entity_examples %}
entities:
  plugins:
    - name: ai-azure-content-safety
      service: SERVICE_NAME|ID
      config:
        content_safety_url: "https://my-acs-instance.cognitiveservices.azure.com/contentsafety/text:analyze"
        content_safety_key: "{vault://env/AZURE_CONTENT_SAFETY_KEY}"
        categories:
          - name: Hate
            rejection_level: 2
          - name: SelfHarm
            rejection_level: 2
          - name: Sexual
            rejection_level: 2
          - name: Violence
            rejection_level: 2
        text_source: concatenate_user_content
        reveal_failure_reason: true
        output_type: FourSeverityLevels
{% endentity_examples %}

{:.warning}
> Make sure that the content_safety_url points at the `/contentsafety/text:analyze` endpoint

## Test the configuration

Using this configuration, given the following AI Chat request:

```json
{
  "messages": [
    {
      "role": "system",
      "content": "You are a mathematician."
    },
    {
      "role": "user",
      "content": "What is 1 + 1?"
    },
    {
      "role": "assistant",
      "content": "The answer is 3."
    },
    {
      "role": "user",
      "content": "You lied, I hate you!"
    }
  ]
}
```

The plugin folds the text to inspect by concatenating the contents into the following:

```plaintext
You are a mathematician.; What is 1 + 1?; The answer is 3.; You lied, I hate you!
```

Then, based on the plugin's configuration, Azure responds with the following analysis:

```json
{
    "categoriesAnalysis": [
        {
            "category": "Hate",
            "severity": 2
        }
    ]
}
```

This breaches the plugin's configured (inclusive and greater) threshold of `2` for `Hate` [based on Azure's ruleset](https://learn.microsoft.com/en-us/azure/ai-services/content-safety/concepts/harm-categories?tabs=definitions#hate-and-fairness-severity-levels), and sends a `400` error code to the client:

```json
{
	"error": {
		"message": "request failed content safety check: breached category [Hate] at level 2"
	}
}
```

### (Optional) Hide the failure reason from the API response

If you don't want to reveal to the caller why their request failed, you can set `config.reveal_failure_reason` to `false`, in which
case the response looks like this:

```json
{
	"error": {
		"message": "request failed content safety check"
	}
}
```

### (Optional) Use blocklists

<!-- FYI: TO BE CHECKED, FOR SOME REASON I KEEP GETTING 500 WHENEVER THE BLOCKLIST IS ENABLED -->

The plugin supports previously-created blocklists in Azure Content Safety.

Using the [Azure Content Safety API](https://learn.microsoft.com/en-us/azure/ai-services/content-safety/how-to/use-blocklist)
or the Azure Portal, you can create a series of blocklists for banned phrases or patterns.
You can then reference their unique names in the plugin configuration.

In the following example, the plugin takes two existing blocklists from Azure, `company_competitors` and
`financial_properties`:

{% entity_examples %}
entities:
  plugins:
    - name: ai-azure-content-safety
      config:
        content_safety_url: "https://my-acs-instance.cognitiveservices.azure.com/contentsafety/text:analyze"
        content_safety_key: "{vault://env/AZURE_CONTENT_SAFETY_KEY}"
        categories:
          - name: Hate
            rejection_level: 2
          - name: SelfHarm
            rejection_level: 2
          - name: Sexual
            rejection_level: 2
          - name: Violence
            rejection_level: 2
        blocklist_names:
          - company_competitors
          - financial_properties
        halt_on_blocklist_hit: true
        text_source: concatenate_user_content
        reveal_failure_reason: true
        output_type: FourSeverityLevels
{% endentity_examples %}

{{site.base_gateway}} will then command Content Safety to enable and execute these blocklists against the content. The plugin property `config.halt_on_blocklist_hit` is used to tell Content Safety to stop analyzing the content as soon as any blocklist hit matches.

Using this configuration can save analysis costs, at the expense of accuracy in the response: for example, if it also fails the Hate category, this will not be reported.