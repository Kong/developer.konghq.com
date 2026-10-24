---
title: "Platform Tour"
permalink: /how-to/platform-tour/
content_type: how_to
description: "Internal demo page: several custom platform components, rendering for real on a real page."
seo_noindex: true
products:
  - gateway
  - ai-gateway
works_on:
  - konnect
  - on-prem
tools:
  - deck
  - admin-api
  - konnect-api
  - kic
  - terraform
tags:
  - ai
  - konnect
tldr:
  q: What does this page demonstrate?
  a: Several of this platform's custom Liquid components, rendering for real on a real page. Not a mockup. Not a screenshot.
related_resources:
  - text: Gateway Service entity reference
    url: /gateway/entities/service/
  - text: Use LangChain with AI Proxy
    url: /how-to/use-langchain-with-ai-proxy/
  - text: Entitlements
    url: /metering-and-billing/entitlements/
prereqs:
  inline:
  - title: OpenAI
    include_content: prereqs/openai
    icon_url: /assets/icons/openai.svg
cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
---

{% include platform-tour/orientation.md part=1 note="testt" %}

This page shows the how-to content type rendering

### What produces the sidebar and prereqs

The sidebar (tags, related resources, works-on badge, the Konnect/on-prem switch) and the Prerequisites
accordion aren't things this page's body controls. They come entirely from this file's frontmatter and metadata shown here
exactly as written:

{% raw %}
```yaml
products: [gateway, ai-gateway]
works_on: [konnect, on-prem]
tags: [ai, konnect]
prereqs:
  inline:
  - title: OpenAI
    include_content: prereqs/openai
    icon_url: /assets/icons/openai.svg
```
{% endraw %}

* `products` and `works_on` alone auto-generate the Konnect/on-prem Prerequisites cards. No
* `{% raw %}{% konnect %}{% endraw %}`/`{% raw %}{% on_prem %}{% endraw %}` tags are needed for that part. The one inline card (OpenAI) is a `prereqs.inline` entry reusing a shared snippet file.
*This exact mechanism (`prereqs`) is used on 442 of 468 how-to guides (94%).*
* The small italic line right above the title of this page ("Part 1 of 5...") isn't retyped five times. It's an include

{% raw %}
```liquid
*Part {{ include.part }} of {{ include.total | default: 5 }} in the [platform tour](/internal/platform-tour-landing/).{% if include.note %} {{ include.note }}{% endif %}*
```
{% endraw %}



Called from this page as `{% raw %}{% include platform-tour/orientation.md part=1 note="Start there for the full map." %}{% endraw %}`.
Four other pages call the same file with a different number and no note, or a different note. Same pattern as
`{% raw %}{% include prereqs/openai.md %}{% endraw %}` above, just applied to this tour's own scaffolding
instead of product content.

## One page, both hosting modes


Every how-to on this site writes a Konnect version and an on-prem version of a step in the same file. The
reader's own switch, in the sidebar, decides which one shows. Click it.

{% navtabs "platform-tour-hosting-modes" %}
{% navtab "Syntax" %}
{% raw %}
````liquid
{% on_prem %}
content: |
  ```bash
  kong_url = "http://127.0.0.1:8000"
  ```
{% endon_prem %}

{% konnect %}
content: |
  ```bash
  kong_url = os.environ['KONNECT_PROXY_URL']
  ```
{% endkonnect %}
````
{% endraw %}
{% endnavtab %}
{% navtab "Live (flip the sidebar switch)" %}
{% on_prem %}
content: |
  ```bash
  kong_url = "http://127.0.0.1:8000"
  ```
  {: data-test-step="block" }
{% endon_prem %}

{% konnect %}
content: |
  ```bash
  kong_url = os.environ['KONNECT_PROXY_URL']
  ```
  {: data-test-step="block" }
{% endkonnect %}
{% endnavtab %}
{% endnavtabs %}

## Multiple outputs per input


A writer describes a Gateway entity once. The platform generates a separately-built tab per tool.

**Writer types:**

{% raw %}
```liquid
{% entity_example %}
type: service
data:
  name: example-service
  url: "http://httpbin.konghq.com"
{% endentity_example %}
```
{% endraw %}

**Renders as (live, click through the tabs):**

{% entity_example %}
type: service
data:
  name: example-service
  url: "http://httpbin.konghq.com"
{% endentity_example %}



## A real konnect_api_request



This syntax becomes a request/response example, validated at build time. The build fails outright if the page doesn't declare `works_on: konnect`.

This also means we can change something in only one place if the API changes.

**Writer types:**

{% raw %}
```liquid
{% konnect_api_request %}
url: /v3/openmeter/customers/{customerId}/entitlement-access
status_code: 200
method: GET
{% endkonnect_api_request %}
```
{% endraw %}

**Renders as (live):**

{% konnect_api_request %}
url: /v3/openmeter/customers/{customerId}/entitlement-access
status_code: 200
method: GET
{% endkonnect_api_request %}

## Docs that test themselves

*`{% raw %}{% validation %}{% endraw %}`*

This Playwright-and-Docker pipeline runs against a real Kong Gateway before a how-to ships. 

**Writer types:**

{% raw %}
```liquid
{% validation request-check %}
url: /anything
status_code: 200
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
body:
    messages:
        - role: "system"
          content: "You are a mathematician"
        - role: "user"
          content: "What is 1+1?"
{% endvalidation %}
```
{% endraw %}

**Renders as (live):**

{% validation request-check %}
url: /anything
status_code: 200
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
body:
    messages:
        - role: "system"
          content: "You are a mathematician"
        - role: "user"
          content: "What is 1+1?"
{% endvalidation %}



## The Cleanup accordion


The Cleanup accordion on this page was generated the same way the Prerequisites accordion was: from this
page's own frontmatter.

{% raw %}
```yaml
cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
```
{% endraw %}


## See the real pages these were adapted from

Every component on this page was adapted from a real, currently-live page. Worth pulling up side by side:

- [Gateway Service entity reference](/gateway/entities/service/): the source of the entity_example demo.
- [Use LangChain with AI Proxy](/how-to/use-langchain-with-ai-proxy/): the source of the Konnect/on-prem toggle demo.
- [Entitlements](/metering-and-billing/entitlements/): the source of the konnect_api_request demo.
