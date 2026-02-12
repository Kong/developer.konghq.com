---
title: Konnect Search reference
content_type: reference
layout: reference
breadcrumbs:
  - /konnect/

products:
  - konnect

works_on:
  - konnect

search_aliases: 
  - ksearch

description: "Learn how to use the {{site.konnect_short_name}} Search to search through all {{site.konnect_short_name}} entities."

related_resources:
  - text: "{{site.konnect_short_name}} Search API"
    url: /api/konnect/ksearch/
---

{{site.konnect_short_name}} Search allows to search across all {{site.konnect_short_name}} entities within an organization using simple keywords as well as precise query syntax.. 
You can access search using the search bar (_Command+K_ or _Control+K_) at the top of every page in {{site.konnect_short_name}} or using the [{{site.konnect_short_name}} Search API](/api/konnect/ksearch/).

The {{site.konnect_short_name}} Search, by default, searches for both global and regional entities (with regional-awareness for the [currently selected region](/konnect-platform/geos/)). This ensures that returned entities are relevant to their geographical location. By default, every search performs:
* A global resources fetch for global {{site.konnect_short_name}} entities, such as users, teams, and networks
* A geo-scoped fetch, searching through [entities](/gateway/entities/) in the current {{site.konnect_short_name}} geo. For example, if you've selected the US geo, {{site.konnect_short_name}} search will only search for entities in the US geo.

{{site.konnect_short_name}} allows you to perform basic search (simple keyword match) as well as advanced search (query syntax). To perform a basic search, click the **Basic** tab. You can search for a known entity, like a Service, API, or team, using basic search. You can also perform an advanced search by clicking the **Advanced** tab and using {{site.konnect_short_name}}'s [query syntax](#query-syntax) to get more precise results or results that match a specified criteria.

Here are a few example use cases where you can use the {{site.konnect_short_name}} Search capabilities:

<!--vale off-->
{% table %}
columns:
  - title: You want to...
    key: use_case
  - title: Then use...
    key: method
rows:
  - use_case: Navigate to a specific entity that you know exists
    method: |
      Click the **Basic** tab and search for the name, ID, description, or keywords of the entity in the {{site.konnect_short_name}} search bar to quickly navigate to the entity page in {{site.konnect_short_name}}.
  - use_case: |
      Find entities that match specific criteria
    method: |
      Click the **Advanced** search tab and specify your search criteria using [query syntax](#query-syntax).
{% endtable %}
<!--vale on-->

## Query syntax

{{site.konnect_short_name}} Search provides selectors, reserved characters, and logical operators that you can use to narrow your entity search. 
By combining these selectors, reserved characters, and logical operators, you can construct complex and precise queries to effectively use {{site.konnect_short_name}} Search. 

Perform an advanced search with query syntax by clicking the **Advanced** tab. The following is an example advanced search query syntax:

```
type:team AND NOT label.department:eng AND name:*_qa
```

In this example, the query syntax is made up of the following components:
* Selectors: `type`, `label`, and `name`. They define what you are searching by. 
* Entity type: `team`. These define what {{site.konnect_short_name}} entity you want to search for.
* Logical operator: `AND NOT` and `AND`. These are used to combine multiple criteria in a query.
* Wildcard: `*` to denote any a suffix match.
* Search values: `eng` and `_qa`. These are the values that the search service is matching for.

### Entity types

The following {{site.konnect_short_name}} entity types are supported: 

- `api`
- `api_product`  
- `api_product_version`  
- `application`
- `catalog_service`  
- `ca_certificate`  
- `certificate`  
- `consumer`  
- `consumer_group`  
- `control_plane`
- `dashboard`
- `data_plane`  
- `developer`  
- `developer_team`    
- `key`  
- `key_set`   
- `mesh`  
- `mesh_control_plane`  
- `plugin`  
- `portal`  
- `report`  
- `route`
- `service`  
- `sni`  
- `system_account`  
- `target`  
- `team`  
- `upstream`  
- `user`  
- `vault`  
- `zone`  

Additional entities may be added in future releases. You can view a list of all the supported entities by sending the following API request:

<!--vale off-->
{% http_request %}
  url: https://global.api.konghq.com/v1/search/types
  method: GET
  headers:
      - 'Accept: application/json'
      - 'Authorization: Bearer $KONNECT_TOKEN'
{% endhttp_request %}
<!--vale on-->

#### Searchable attributes

For each entity type, there is a list of entity specific attributes that are searchable. 
These attributes are returned in the attributes object in the search response, while the schema of the searchable attributes can be found in the `/types` endpoint.

To search by an attribute in the {{site.konnect_short_name}} UI, use syntax like `@{attribute_key}:{attribute_value}`. For example, to search by entities that were updated at a certain date, you'd use `@updated_at:2026-02-24`. 

### Selectors

Selectors are used to define the criteria of the search. 
The following table describes the different selectors and their functions:

<!--vale off-->
{% table %}
columns:
  - title: Selector
    key: selector
  - title: Function
    key: function
  - title: Example
    key: example
rows:
  - selector: |
      `type:{entity_type}`
    function: Searches for a specific entity type.
    example: |
      `type:control_plane`
  - selector: "`{value}`"
    function: "Searches for a match in `{value}` on any all searchable attributes."
    example: "`foobar`"
  - selector: |
      `id:{value}`
    function: "Searches for a match on `id`."
    example: |
      `id:df968c45-3f20-4b80-8980-e223b250dec5`
  - selector: |
      `name:{value}`
    function: "Searches for a match on `name`."
    example: |
      `name:default`
  - selector: |
      `description:{value}`
    function: "Searches for a match on `description`."
    example: |
      `description:temporary`
  - selector: |
      `labels.{label_key}:{label_value}`
    function: "Searches for an exact match for a labeled entity."
    example: |
      `labels.env:prod`
  - selector: |
      `@public_labels.{label_key}:{label_value}`
    function: "Searches for an exact match for a labeled entity in Dev Portal."
    example: "`@public_labels.env:prod`"
  - selector: |
      `@{attribute_key}:{attribute_value}`
    function: "Searches for an exact match for an entity specific attribute."
    example: |
function: |
  Searches for an exact match for an entity specific attribute.
  <br><br>
  If searching for a date, the value _must_ be in the [ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html) format of `YYYY-MM-DD`.
example: |
`@email:"admin@domain.com"`
<br>
`@updated_at:2026-02-24`
{% endtable %}
<!--vale on-->

### Reserved characters

The following table describes the characters with special meanings in the query syntax:

<!--vale off-->
{% table %}
columns:
  - title: Character
    key: character
  - title: Function
    key: function
rows:
  - character: "`*`"
    function: Use as a wildcard.
  - character: |
      `""`
    function: Denotes an exact match. This is case insensitive and includes spaces.
{% endtable %}
<!--vale on-->

### Logical operators

Logical operators are used to combine multiple criteria in a search query. 
Operators are case-sensitive. 

The following table describes each operator and how it functions in the query syntax:

<!--vale off-->
{% table %}
columns:
  - title: Operator
    key: operator
  - title: Function
    key: function
rows:
  - operator: "`AND`"
    function: Searches for entities that are in all of the listed fields.
  - operator: "`OR`"
    function: Searches for entities that are in one or more of the listed fields.
  - operator: "`NOT`"
    function: Searches for entities that are not in a field.
{% endtable %}
<!--vale on-->

## Example search queries

The following table describes different example search queries:

<!--vale off-->
{% table %}
columns:
  - title: Search type
    key: type
  - title: Query
    key: query
  - title: Description
    key: description
rows:
  - type: Simple
    query: "`Dana`"
    description: "This query searches for entities with a searchable attribute containing the value `Dana`."
  - type: Simple
    query: |
      `name:Dana`
    description: "This query searches for entities with the name `Dana`."
  - type: Simple
    query: |
      `name:"Dana H"`
    description: |
      This query searches for entities with the name `"Dana H"`. The quotes around `"Dana H"` indicate an exact match, including spaces.
  - type: Logical
    query: |
      `type:team AND name:*_qa`
    description: |
      This query finds teams in the QA department. 
      It combines multiple selectors: `type:team` limits the search to the `teams` entity type and `name:*_qa` filters for teams that have a `_qa` suffix.
  - type: Logical
    query: |
      `type:service AND @updated_at:2026-02-24`
    description: |
      This query finds services that were updated on 24 February 2026. 
      It combines multiple selectors: `type:service` limits the search to the `service` entity type and `@updated_at:2026-02-24` filters for services that match that date. When you search by date, you _must_ use the [ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html) format of `YYYY-MM-DD`.
  - type: Logical
    query: |
      `name:*dev* OR name:*qa* OR name:*test`
    description: "This query finds any entities that contain `dev` or `qa` or `test` in its name. It combines multiple `name:` selectors to limit the results to entities that match one of these terms."
  - type: Exclusion
    query: |
      `type:system_account AND NOT *temp*`
    description: "This query finds system accounts that don't contain `temp` in their name and description. The `NOT` logical operator is used to exclude entities."
  - type: Exclusion
    query: |
      `type:team AND NOT name:team-blue AND NOT description:*blue*`
    description: "This query finds teams that are not named `team-blue` and don't contain `blue` in its description. The `NOT` logical operator is used to exclude entities."
  - type: Wildcards
    query: |
      `name:Project*`
    description: "This query uses a wildcard to find entities starting with the prefix `Project`. The `*` serves as a wildcard."
  - type: Wildcards
    query: |
      `description:*_prod`
    description: "This query uses a wildcard to find entities ending with the description `_prod`. The `*` serves as a wildcard."
{% endtable %}
<!--vale on-->
