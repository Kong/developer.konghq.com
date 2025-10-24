---
title: Glossary

description: Common terms used across Kong.

permalink: /glossary/

content_type: policy
layout: reference

related_resources:
  - text: Stages of software availability
    url: /stages-of-software-availability/
tags:
  - glossary
---

Common terms used across Kong.

{% assign glossary = site.data.glossary.definitions | sort: "term" %}

<!-- vale off -->
{% table %}
columns:
  - title: Term
    key: term
  - title: Description
    key: description
  - title: Link
    key: link
rows:
{% for item in glossary %}
  - term: "{{ item.term }}"
    description: "{{ item.description }}"
    link: "{{ item.url }}"
{% endfor %}
{% endtable %}

