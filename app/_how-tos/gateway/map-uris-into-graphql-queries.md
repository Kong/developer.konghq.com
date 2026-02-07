---
title: Map URIs into GraphQL queries with DeGraphQL
permalink: /how-to/map-uris-into-graphql-queries/
content_type: how_to
description: Learn how to use the DeGraphQL plugin to map URIs into GraphQL queries.
related_resources:
  - text: GraphQL plugins
    url: /plugins/?terms=graphql

products:
  - gateway

works_on:
  - on-prem
  - konnect

plugins: 
  - degraphql

entities:
  - service
  - route
  - plugin

tools:
  - deck

tldr:
  q: How do I pass HTTP requests into GraphQL with {{site.base_gateway}}?
  a: |
    Use the DeGraphQL plugin to map URIs into GraphQL queries. 
    In this tutorial, you'll learn how to use DeGraphQL to query the [GitHub GraphQL API](https://docs.github.com/en/graphql/overview/about-the-graphql-api).

tags:
  - graphql

prereqs:
  inline:
  - title: GitHub account and access token
    content: |
      For this task, you need a GitHub account and a personal access token to access the GitHub API.
      
      For the purposes of the example, the token must contain read permissions for your user profile.

      Export the token into an environment variable:
      ```
      export GITHUB_TOKEN='YOUR TOKEN GOES HERE'
      ```
    icon_url: /assets/icons/git.svg

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.4'
---

## Create a Gateway Service and a Route

DeGraphQL needs a GraphQL endpoint to query. 
In this tutorial, we're going to build a REST API around the `https://api.github.com` GraphQL service. 
Make sure you have created a [GitHub personal access token](#github-account-and-access-token) to use with the API.

Create a Gateway Service and Route in {{site.base_gateway}}, with the Service pointing to the `https://api.github.com` API:

{% entity_examples %}
entities:
  services:
    - name: github
      tags:
        - graphql
      url: "https://api.github.com"
      routes:
        - name: github-api
          paths: 
            - /api
{% endentity_examples %}

## Configure the DeGraphQL plugin on the Service

Set up the DeGraphQL plugin on the `github` Service:

{% entity_examples %}
entities:
  plugins:
    - name: degraphql
      service: github
{% endentity_examples %}

Enabling the plugin disables regular Service function. 
Instead, the plugin now builds the path and GraphQL query to hit the GraphQL service with.

From this point on, the Service represents your REST API and not the GraphQL endpoint itself.
It will return a `404 Not Found` status code if no DeGraphQL routes have been configured.

## Configure DeGraphQL routes on the Service
 
Now that the plugin is activated on the `github` Service, you can add your own routes
by defining URIs and associating them to GraphQL queries. 

Let's add a DeGraphQL route to retrieve the username of the logged in user:

<!-- @todo: turn this into an entity example and remove default_lookup_tags after the command is fixed deck-side -->

```yaml
echo '
_format_version: "3.0"
_info:
  default_lookup_tags:
    services:
      - graphql
custom_entities:
  - type: degraphql_routes
    fields:
      service:
        name: "github"
      uri: /me
      query: "query { viewer { login } }"
' | deck gateway apply -
```

You don’t need to include the GraphQL server path prefix in the URI parameter (`/graphql` by default), so the URI is just `/me`.

## Validate

Now you can send HTTP requests to the GraphQL endpoint without having to pass GraphQL queries directly.

Send a GET request to the `/me` endpoint to retrieve your username:

{% validation request-check %}
url: /api/me
headers:
  - 'Authorization: Bearer $GITHUB_TOKEN'
status_code: 200
{% endvalidation %}

You'll get your GitHub username in response:

```json
{"data":{"viewer":{"login":"your-username"}}}
```
{:.no-copy-code}