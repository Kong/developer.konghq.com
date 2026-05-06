---
title: "Style guide"
content_type: reference
layout: reference

breadcrumbs:
  - /contributing/

tags:
  - contributing

description: "Writing and formatting guidelines for contributing to the Kong Developer site. Covers language, tone, grammar, capitalization, code formatting, icons, and third-party tool documentation."

products:
  - gateway

works_on:
  - on-prem
  - konnect

llm: false
---
Writing and formatting guidelines for contributing to the Kong Developer site. Covers language, tone, grammar, capitalization, code formatting, icons, and third-party tool documentation.
<!--vale off-->

## Language

The Kong docs use [American English (US English)](https://en.wikipedia.org/wiki/American_English).

{% table %}
columns:
  - title: "✅ Do use (American English)"
    key: do
  - title: "❌ Don't use (other variations)"
    key: dont
rows:
  - do: The response **should** look like...
    dont: The response **shall** look like...
  - do: In the previous section, you **learned**...
    dont: In the previous section, you **learnt**...
  - do: "Color, recognize, analyze"
    dont: "Colour, recognise, analyse"
  - do: While
    dont: Whilst
{% endtable %}

## Voice and tone

At Kong, we try to keep our tone **conversational**, but not at the expense of clarity.
We keep language simple and concise, take things seriously when we need to, and keep our readers in mind in whatever we write.

Prefer plain, direct language over formal or technical-sounding alternatives:

{% table %}
columns:
  - title: "✅ Do use"
    key: do
  - title: "❌ Don't use"
    key: dont
rows:
  - do: "*Run* the program."
    dont: "*Execute* the program."
  - do: "*Use* the Admin API."
    dont: "*Utilize* the Admin API."
  - do: "Open the link *to* do the thing."
    dont: "Open the link *in order to* do the thing."
  - do: "In the open tab, do the thing."
    dont: |
      In the open tab that *appears*, do the thing.
      In the open tab that *displays*, do the thing.
  - do: |
      Clearly refer to subjects.
      For example: "Once you have added *the inputs section*, ..."
    dont: |
      Avoid generic pronouns.
      For example, don't say: "Once you have added *this*, ..."
{% endtable %}

### Active voice

Use active voice, and avoid passive voice.

With active voice, the subject performs an action. With passive voice, the action is performed upon the subject:

{% table %}
columns:
  - title: "✅ Active"
    key: active
  - title: "❌ Passive"
    key: passive
rows:
  - active: The plugin *applies* rate limiting to consumers.
    passive: Rate limits *are applied to* consumers by the plugin.
  - active: You *can explore* the API using a browser.
    passive: The API *can be explored* using a browser.
  - active: The YAML file *specifies* the replica count.
    passive: The replica count *is specified* in the YAML file.
{% endtable %}

There are exceptions. You might use passive voice when the subject is genuinely passive and isn't performing any action.
For example: "The CA provider's external account can be registered automatically."
In this sentence, the account isn't doing anything, so passive voice is appropriate.

### Present tense for references

Whenever possible, use present tense instead of past or future tense for documentation.

{% table %}
columns:
  - title: "✅ Do use"
    key: do
  - title: "❌ Don't use"
    key: dont
rows:
  - do: This `command` *starts* a proxy.
    dont: This `command` *will start* a proxy.
  - do: This `command` *starts* a proxy.
    dont: This `command` *has started* a proxy.
{% endtable %}

Just like for active voice, there are exceptions here too. 
In how-to guides, we use a more natural tone, so using "will" in phrases like "You'll see this result on the screen" is completely fine. 

### Contractions

Don't be afraid to use contractions (*can't*, *isn't*, *you'll*, and so on). They contribute to our conversational tone.

There are exceptions. Omit contractions when aiming for a more serious tone, such as in a warning or caution:

- **Contraction (informational):** "This plugin isn't available in Konnect."
- **No contraction (warning):** "**Do not** use this plugin in Konnect because it will break your configuration."

### Latin phrases

Don't use Latin abbreviations or phrases. Use the English equivalent instead.

{% table %}
columns:
  - title: "✅ Do use"
    key: do
  - title: "❌ Don't use"
    key: dont
rows:
  - do: "For example, ..."
    dont: "e.g., ex., ..."
  - do: "That is, ..."
    dont: "i.e., ..."
  - do: "So (or therefore), ..."
    dont: "Ergo, ..."
{% endtable %}

### Bias-free language

Use gender-neutral and unbiased language.

{% table %}
columns:
  - title: "✅ Do use"
    key: do
  - title: "❌ Don't use"
    key: dont
rows:
  - do: "Denylist, allowlist"
    dont: "Blacklist, whitelist"
  - do: Main branch
    dont: Master branch
  - do: "Neutral pronouns (you, they/them)"
    dont: "Gendered pronouns (he/his, she/her)"
{% endtable %}

### Recommendations

A recommendation should:
- Apply to most users in the given context — it's not a general suggestion
- Always include a reason so readers understand *why* it's recommended

Use the phrase "we recommend" rather than "Kong recommends" or "it is recommended":

{% table %}
columns:
  - title: "✅ Do use"
    key: do
  - title: "❌ Don't use"
    key: dont
rows:
  - do: "**We recommend** using an access token **because it's more secure**."
    dont: "**Kong recommends** using an access token."
  - do: "**We don't recommend** storing a password in plaintext **because it's not secure**."
    dont: "**It is recommended** that you use an access token."
{% endtable %}

## Grammar and syntax

### Punctuation

Commas and periods always go inside quotation marks. Colons, semicolons, and dashes go outside.

For example: "There was a storm last night," Paul said.

#### List punctuation

Use end punctuation when list items are full sentences:

{:.info .no-icon}
> In DB-less mode, you configure {{site.base_gateway}} declaratively. Therefore, the Admin API is mostly read-only. The only tasks it can perform are all related to handling the declarative configuration, including:
>
> - Setting a target's health status in the load balancer.
> - Validating configurations against schemas.
> - Uploading the declarative configuration using the `/config` endpoint.

Don't use end punctuation when list items are fragments that complete the introductory sentence:

{:.info .no-icon}
> {{site.mesh_product_name}} enables the microservices transformation with:
> - Out-of-the-box service connectivity and discovery
> - Zero-trust security
> - Traffic reliability
> - Global observability across all traffic

### Headings and page titles

Be descriptive. A heading should tell readers what they'll find in the section or on the page — not just label it generically.

{% table %}
columns:
  - title: "✅ Do use"
    key: do
  - title: "❌ Don't use"
    key: dont
rows:
  - do: "What is {{site.base_gateway}}?"
    dont: Overview
  - do: Query frequency and precision
    dont: Query behavior
{% endtable %}

Use sentence case for section headings. Capitalize only the first word and proper nouns — not every word:

{% table %}
columns:
  - title: "✅ Do use"
    key: do
  - title: "❌ Don't use"
    key: dont
rows:
  - do: "Understanding traffic flow in {{site.base_gateway}}"
    dont: "Understanding Traffic Flow in {{site.base_gateway}}"
  - do: Get started with the Request Transformer Advanced plugin
    dont: Get Started with the Request Transformer Advanced Plugin
{% endtable %}

### Capitalization

When documenting a user interface (UI), follow its formatting.
If a term is capitalized in the UI and you're referring to that specific UI element, capitalize it in the documentation too.

#### Terms that are capitalized

The following terms should be capitalized:

**Gateway API entity names**:
- Certificate
- Consumer
- Plugin
- Route
- Service (Gateway Service)
- Target
- Upstream
- Vault

The following terms should not be capitalized. They should be lowercase unless at the start of a sentence:
* control plane
* data plane
* application
* database
* developer
* hybrid mode
* service mesh

#### Plugin name capitalization

1. Capitalize the plugin *name* but not the word *plugin*. For example, "Rate Limiting plugin".
2. Don't capitalize in code. For example, `rate-limiting`.
3. Don't capitalize if you're referring to the concept rather than the plugin itself.
   For example: "Set up rate limiting in {{site.base_gateway}} with the Rate Limiting plugin."

## Formatting

### Placeholder and example values

The type of placeholder you use depends on context:

- **Generic placeholder values** — in most situations (such as plugin parameters, YAML examples, or Kong configuration), use all-caps text with underscores between words.

  For example: `service: SERVICE_NAME`

- **Placeholders in API URLs or OpenAPI specs** — enclose in `{ }` and use the parameter name defined by the API or spec, per [Swagger guidelines](https://swagger.io/docs/specification/describing-parameters/).

  For example: `/services/{serviceId}/plugins`

- **Hostnames and example URLs:**
  - For guides with examples intended to be run as-is, use `localhost` as the domain or `$KONNECT_PROXY_URL` for {{site.konnect_short_name}} documentation.

    For example: `curl -i -X GET https://localhost:8001/services`

    A reader following this guide with {{site.base_gateway}} running locally can copy and paste the command directly into a terminal.

  - For illustrative examples that are not intended to be run as-is, use `example` or `example.com`.

    For example: `user@example.com` or `https://example.okta.admin.com`

- **Path parameters** — always denote with curly braces `{}`.

  For example: `http://localhost:8001/services/{serviceId|serviceName}/routes/{routeId|routeName}`

#### Inline placeholders

If you're adding a placeholder inline in a sentence, enclose it in single backticks: \`EXAMPLE_TEXT\`

### Code formatting

- Separate commands from their output. Put each in its own code block. Use `{:.no-copy-code}` directly under an output if users won't need to copy the output.
- Include properly formatted code comments.
- For long commands, split the code block across multiple lines using `\` to avoid horizontal scrolling.
- Never include more than one command in a single code block.
- Use yaml liquid blocks for code when it's supported (for example, `entity_example`, `konnect_api_request`). If there are no corresponding liquid blocks, always set a language for code blocks (for example, `bash`, `yaml`) to enable syntax highlighting.
- Do **not** use the command prompt marker (`$`) in code snippets.

## Icons

For inline icons in prose or tables, use SVG files from the [`/app/assets/icons/`](https://github.com/Kong/developer.konghq.com/tree/main/app/assets/icons) directory. Browse the directory to find the icon you need, then reference it with a relative path.

## Documenting third-party tools

When a how-to guide requires a third-party tool (such as an identity provider, cloud service, or external API) to be configured in a specific way to work with Kong, include complete setup instructions rather than linking out to third-party documentation and expecting readers to figure it out.

In most cases, the third-party instructions should be a prerequisite.
Write the prerequisite steps in a file under `app/_includes/prereqs/` and include it at the top of the how-to. This keeps the how-to self-contained: readers can follow the entire guide in one place without switching between multiple sources.

For an example, see [`app/_includes/prereqs/gemini.md`](https://github.com/Kong/developer.konghq.com/blob/main/app/_includes/prereqs/gemini.md), which walks users through getting a {{ site.gemini }} API key from {{ site.google}} Cloud before the main tutorial begins.

In certain cases, the third-party instructions should be in the main how-to body.
For example, if users need to update a routing table in AWS after they've set up their Dedicated Cloud Gateway network or if they need to approve a Catalog integration in the third-party provider after they configure it in Catalog.

### Writing prerequisite instructions

When writing third-party setup steps:

- Include every required step, in order. Don't assume users have already completed any part of the setup.
- Use action-oriented steps: "Go to...", "Click...", "Copy the...".
- Export any required values as environment variables so readers can reference them in later commands without having to look them up again.
- Keep instructions generic enough to survive minor UI changes. Refer to UI elements by their label only, not by their location or visual appearance.

### Pitfalls to avoid

Third-party UIs change frequently. To reduce maintenance overhead:

- **Do not** include screenshots of third-party UIs.
- Refer to UI elements by their label only — not their color, position, or visual style:

{% table %}
columns:
  - title: "✅ Do use"
    key: do
  - title: "❌ Don't use"
    key: dont
rows:
  - do: Click **Add**.
    dont: Click the blue **Add** button in the top-right corner.
  - do: Enter the API key provided by your API provider.
    dont: "Enter the API key found in the **Security tab** under **API Settings**."
{% endtable %}

## Links

Write descriptive link text that tells readers what they'll find when they click. Don't use vague phrases like "click here" or "read more".

{% table %}
columns:
  - title: "✅ Do use"
    key: do
  - title: "❌ Don't use"
    key: dont
rows:
  - do: "For more information, see the [style guide](#)."
    dont: "For more information, [click here](#)."
  - do: "Learn about [content best practices](#) in the Kong style guide."
    dont: "Learn about content best practices [here](#)."
{% endtable %}

<!--vale on-->