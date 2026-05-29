---
title: "{{ site.konnect_short_name }} Gateway Service integration in {{ site.data.products.insomnia.name }}"

description: "Link {{ site.konnect_short_name }} to send requests from Insomnia against Routes in  your Gateway Services from {{ site.data.products.insomnia.name }}." 

content_type: reference
layout: reference

breadcrumbs:
  - /insomnia/
  - /insomnia/enterprise/
min_version:
  insomnia: '13'
products:
    - insomnia
tier: enterprise

next_steps:
  - text: Link a {{ site.konnect_short_name }} Service Gateway to {{ site.data.products.insomnia.name }}
    url: /how-to/link-konnect-to-insomnia/

related_resources:
  - text: Security at Insomnia
    url: /insomnia/manage-insomnia/#security
  - text: Enterprise
    url: /insomnia/enterprise/
  - text: Enterprise account management
    url: /insomnia/enterprise-account-management/
  - text: Enterprise user management
    url: /insomnia/enterprise-user-management/
  - text: Migrate from scratch pad to Enterprise
    url: /insomnia/migrate-from-scratch-pad-to-enterprise/
  - text: Link Konnect to Insomnia
    url: /how-to/link-konnect-to-insomnia/

faqs:
  - q: Can I use the {{ site.konnect_short_name }} integration with my on-prem Gateway?
    a: |
      No, the {{ site.konnect_short_name }} integration only works with Gateway Services hosted in {{ site.konnect_short_name }}, not on-prem {{site.base_gateway}}.
  - q: What is the "Skipped routes" Collection?
    a: |
      The "Skipped Routes" Collection contains Routes using an unsupported protocal. You can't use the Collection runner to send requests against them.    
  - q: Why does {{ site.data.products.insomnia.name }} skip some Routes?
    a: |
      {{ site.data.products.insomnia.name }} skips Routes that use an unsupported protocol, such as SNI matching, TCP, or UDP. {{ site.data.products.insomnia.name }} displays the skipped routes in a separate collection named "Skipped routes".
  - q: Can I use the {{ site.konnect_short_name }} integration with my on-prem Gateway?
    a: |
      No, the {{ site.konnect_short_name }} integration only works with Gateway Services hosted in {{ site.konnect_short_name }}, not on-prem {{site.base_gateway}}.

---

## About the {{ site.konnect_short_name }} integration

Starting from {{ site.data.products.insomnia.name }} `v13`, Enterprise users can link {{ site.data.products.insomnia.name }} to Gateway Services deployed in {{ site.konnect_short_name }}. The integration allows sending requests from Collections against Routes pulled from {{ site.konnect_short_name }}, using the {{ site.data.products.insomnia.name }} app.

After connecting and syncing your Gateway Services, {{ site.data.products.insomnia.name }}:

- Displays a list of your Gateway Services from {{ site.konnect_short_name }}.
- Pulls the Routes from each Gateway Service.
- Lists the Routes in Collections for each Gateway Service.

## Prerequisites

- An {{ site.data.products.insomnia.name }} [Enterprise account](/insomnia/enterprise/)
- A {{ site.konnect_short_name }} [Gateway Service](/gateway/).
- A [Personal Access Token (PAT)](/konnect-api/#personal-access-tokens) 

## Available features

Collections work the same as for local Routes. The following table lists the features that allow you to link {{ site.data.products.insomnia.name }} to {{ site.konnect_short_name }}:

{% table %}
columns:
  - title: Feature
    key: feature
  - title: Usage
    key: usage
  - title: How to
    key: how
rows:
  - feature: "Authenticate"
    usage: "Link {{ site.data.products.insomnia.name }} to your Gateway Service"
    how: |
      1. From {{ site.konnect_short_name }}, generate a [Personal Access Token (PAT)](/konnect-api/#personal-access-tokens).
      1. Copy the PAT.
      1. In Insomnia, open **Preferences** > **Konnect**.
      1. Paste the PAT.
      1. Click **Validate & Save**.
  - feature: |
      **Konnect** tab
    usage: |
      List your gateway services in {{ site.konnect_short_name }}, next to the **Projects** tab
    how: |
      Open the personal workspace linked to {{ site.konnect_short_name }}.
  - feature: "Sync"
    usage: "Pull the latest updates from {{ site.konnect_short_name }} into {{ site.data.products.insomnia.name }}."
    how: |
      From the **Konnect** tab, click **Sync**.
{% endtable %}

### Syncing

Every time you click **Sync** from the {{ site.konnect_short_name }} tab, {{ site.data.products.insomnia.name }} pulls changes from {{ site.konnect_short_name }}. Syncing:

- Doesn't push any changes from {{ site.data.products.insomnia.name }} to {{ site.konnect_short_name }}.
- Pulls any changes or configurations from {{ site.konnect_short_name }} for the related Routes.


This preserves the local changes on Routes while allowing pulling any updates from {{ site.konnect_short_name }}.

Syncing preserves or resets the following data for each pulled route in {{ site.data.products.insomnia.name }}:


- Parameters
- Auth
- Body
- Custom headers
- Scripts
- Environment variables

{:.info}
Note: Overridden headers aren't preserved — they revert to the values configured in {{ site.konnect_short_name }}.