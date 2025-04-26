---
title: '{{site.konnect_short_name}} labels'
content_type: reference
layout: reference

products:
    - gateway

works_on:
  - konnect

description: Learn about labels in {{site.konnect_short_name}}

related_resources:
  - text: Use custom data plane labels
    url: /how-to/use-custom-data-plane-labels/
---

Labels are `key:value` pairs. They are case-sensitive attributes associated with entities. 
Labels allow an organization to specify metadata on an entity.

For example, you might use the label `location:us-west`, where `location` is the key and the `us-west` is the value.

## Label requirements

A maximum of 5 user-defined labels are allowed on each resource. 

Each label must follow these requirements:
* Both the key and value must be 63 characters or less, beginning and ending with an alphanumeric character (`[a-z0-9A-Z]`). You can use dashes (`-`), underscores (`_`), dots (`.`), and alphanumeric characters in between.
* The key must not start with `kong`, `konnect`, `insomnia`, `mesh`, `kic`, `kuma`, or `_`. These strings are reserved for Kong.
* The value must not be empty.

{:.info}
> Keys are case-sensitive, but values are not.


## Setting labels

You can use labels separately on the control plane and data plane nodes:
* On the control plane, you can set a label for `control plane` and for individual API products.
* On data plane nodes, set labels through `kong.conf` or via environment variables using the [`cluster_dp_labels`](/gateway/configuration/#cluster-dp-labels) property. 
These labels are exposed through the [`/nodes`](/api/konnect/control-planes-config/v2/#/operations/list-dataplane-nodes/) endpoint of the {{site.konnect_short_name}} API.