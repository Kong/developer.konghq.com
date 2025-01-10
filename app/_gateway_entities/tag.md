---
title: Tags
content_type: reference
entities:
  - tag

description: Tags are strings associated with entities in {{site.base_gateway}}, which you can use to filter entities on most GET endpoints.

tools:
    - admin-api
    - konnect-api
    - kic
    - deck
    - terraform

schema:
    api: gateway/admin-ee
    path: /schemas/Tag

api_specs:
    - gateway/admin-oss
    - gateway/admin-ee
    - konnect/control-planes-config

related_resources:
    - text: Distributed Configuration for Kong using decK
      url: /deck/distributed-config/

---

## What is a tag?

Tags are strings that provide a way to associate metadata with entities in {{site.base_gateway}}. 
You can apply tags to an entity when creating or editing it, and you can filter entities by tags 
when using the list (`GET`) endpoints of the Kong Admin API.

Most {{site.base_gateway}} entities can be tagged via their `tags` attribute. 
[Check the schema](/gateway/entities/) for the entity that you're interested in to find out if it supports tagging.

## Tag requirements

Tags can contain almost all UTF-8 characters, with the following exceptions:

* `,` and `/` are reserved for filtering tags with AND and OR, so they are not allowed in tags.
* Non-printable ASCII (for example, the space character) is not allowed.

## Filtering entities using tags

You can use tags to filter most entities via the `?tags` querystring parameter.

Filtering requirements and considerations:
* A maximum of 5 tags can be queried simultaneously in a single request with the `,` (AND) or `/` (OR) operators.
* Mixing operators is not supported. If you try to mix `,` with `/` in the same querystring,
you will receive an error.
* You may need to quote or escape some characters when using them from the command line.
* Filtering by `tags` is not supported in foreign key relationship endpoints. For example,
  the `tags` parameter will be ignored in a request such as `GET /services/foo/routes?tags=a,b`.
* `offset` parameters are not guaranteed to work if the `tags` parameter is altered or removed.

## Filtering examples 

The following examples show how you would filter Gateway Services based on the tags `example` and `admin`:

Use case | Example
-------- | --------
Get the list of all Services tagged `example` by passing the `example` tag as a querystring parameter | <code>GET /services?tags=example</code>
Filter Services with the AND (`,`) delimiter to get all entities that match multiple tags | <code>GET /services?tags=example,admin</code>
Filter Services with the OR (`/`) delimited to get entities that only match one of the specified tags | <code>GET /services?tags=example/admin</code>

## Schema

{% entity_schema %}

## Add tags to a Gateway Service

The following examples show how you would tag a Gateway Service, however most {{site.base_gateway}} entities can be tagged in the same way.

{% entity_example %}
type: service
data:
  name: example-service
  url: "http://httpbin.konghq.com"
  tags: 
  - example
  - test
{% endentity_example %}
