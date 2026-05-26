---
title: "{{ site.konnect_short_name }} Gateway Service routes integration in {{ site.data.products.insomnia.name }}"

description: "Connect your Gateway Service routes and test them in {{ site.data.products.insomnia.name }}." 

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

faqs:
  - q: Why does Insomnia skip some routes?
    a: |
      Insomnia skips routes that use a protocol Insomnia doesn't support, such as SNI matching, TCP, or UDP.

---

Starting from {{ site.data.products.insomnia.name }} 13, Enterprise users can link {{ site.data.products.insomnia.name }} to gateway service routes deployed in Konnect and test them from the app.

## Prerequisites

- An {{ site.data.products.insomnia.name }} [Enterprise account](/insomnia/enterprise/)
- A {{ site.konnect_short_name }} [Gateway Service route](/gateway/)

## Available features

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
    usage: "Link Insomnia to your Gateway Service routes."
    how: |
      1. From Konnect, generate a [Personal Access Token (PAT)](/konnect-api/#personal-access-tokens).
      1. Copy the PAT.
      1. In Insomnia, open **Preferences** > **Konnect**.
      1. Paste the PAT.
      1. Click **Validate & Save**.
  - feature: |
      **Konnect** tab
    usage: |
      List your gateway service routes, next to your **Projects** tab.
    how: |
      Open the personal workspace linked to Konnect.
  - feature: "Sync"
    usage: "Pull the latest updates from Konnect into Insomnia."
    how: |
      From the **Konnect** tab, click **Sync**.
{% endtable %}
