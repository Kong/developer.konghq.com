---
title: GraphQL queries
description: 'Learn how to write, send, and debug GraphQL queries in Insomnia using the built-in query editor, variable section, and schema introspection.'
content_type: reference
layout: reference
products:
  - insomnia
tags:
  - graphql
breadcrumbs:
  - /insomnia/
permalink: /insomnia/graphql/
search_aliases:
  - schema fetching
  - insomnia graphql
faqs:
  - q: How does schema fetching work in Insomnia for GraphQL?
    a: |
      Insomnia automatically fetches your GraphQL schema using an introspection query. 
      This enables features like auto-completion, error checking, and documentation browsing. 
      The schema is fetched when you switch to a new GraphQL request or change properties like the request URL.

      All request attributes—including authentication, headers, and others—are sent with the introspection query.

  - q: How can I explore a GraphQL schema in Insomnia?
    a: |
      You can visually browse your GraphQL schema in several ways:
      * Click **Show Documentation** from the Schema dropdown near the query editor.
      * Hover over a field and click the inline popup that appears.
      * On macOS, press `Control + Click` on a field in the query editor.
---

[GraphQL](https://graphql.org/) is a query language for APIs that uses a type system to help with correctness and maintainability. Insomnia uses this type system to provide auto-completion and linting of GraphQL queries. This reference explains how to create and execute GraphQL queries in Insomnia.

## Using GraphQL

Create a GraphQL request in Insomnia by selecting the **GraphQL** request type during creation, or by switching an existing request to the GraphQL body type using the body menu.

Once selected, you'll see the **Query** and **Variables** sections.

### Query section

The query is the only required field of a GraphQL request. Queries can include arguments, comments, fragments, and other standard GraphQL syntax. While editing, Insomnia provides:

- Auto-completion based on schema introspection
- Inline validation with helpful error messages

{:.info}
> **Note**: GraphQL queries cannot include Insomnia templating, but variables can.

### Variables section

GraphQL [variables](https://graphql.org/learn/queries/#variables) are defined in the **Query Variables** section below the query. They must be a valid JSON object.


If left empty, the `variables` key is omitted from the request payload.

### Constructing the request payload

Insomnia automatically constructs the body of the GraphQL request when either the query or variables are edited.

The body includes:

* `query` (string): Your GraphQL query.
* `variables` (object): Optional.
* `operationName` (string): Optional. Populated from the first named query, if it exists.


```json
{
  "query": "query MyQuery($id: string) { thing(id: $id) { id name created } }",
  "variables": {
    "id": "thing_123"
  },
  "operationName": "MyQuery"
}
```

## Schema fetching

Insomnia automatically fetches your schema via an introspection query to support the following:

* Auto-completion
* Error checking
* Documentation browsing

The schema is fetched when switching to a new GraphQL request or changing request properties like the URL.