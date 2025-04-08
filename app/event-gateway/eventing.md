---
title: "Eventing reference"
content_type: reference
layout: reference

breadcrumbs:
  - /event-gateway/

products:
    - event-gateway

tags:
  - logging
  - audit-logging

description: placeholder

works_on:
  - on-prem
  - konnect

related_resources:
  - text: Get started with {{site.event_gateway}}
    url: /how-to/get-started-with-event-gateway/
---

This is where you can write reference pages or explanations.

Some useful template blocks:

## Table

This is a generic table; you can add as many columns and rows as you want.

{% table %}
columns:
  - title: Item
    key: item
  - title: Description
    key: description
rows:
  - item: Something
    description: |
      This is a long description
  - item: Something else
    description: |
      This is a long description
  - item: Another thing
    description: |
      This is a long description
{% endtable %}


## Feature table

This table takes a boolean key and will render checkmarks and Xes.

{% feature_table %} 
item_title: Mesh RBAC Role
columns:
  - title: Description
    key: description
  - title: Scoped Globally
    key: global_scope

features:
  - title: "`AccessRole`"
    description: Specifies the access and resources that are granted.
    global_scope: true
  - title: "`AccessRoleBinding`"
    description: |
      Assigns a set of `AccessRoles` to a set of objects (users and groups). 
    global_scope: true
{% endfeature_table %}


## Tabs

Useful if you want to display something in different options.

{% navtabs "tab-group-name" %}
{% navtab "Admin API" %}

text with a codeblock

```
hello i'm code
```

{% endnavtab %}
{% navtab "decK" %}

other text
* list item
* list item

{% endnavtab %}
{% endnavtabs %}


## Notes/admonitions

{:.warning}
> This is a yellow note


{:.info}
> This is a blue note


{:.success}
> This is a green note


{:.danger}
> This is a red note
