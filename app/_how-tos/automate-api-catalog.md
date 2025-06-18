---
title: Automate your API catalog with Dev Portal
description: Learn how to automate your API catalog in Dev Portal using Konnect APIs.
content_type: how_to

products:
    - gateway
    - dev-portal
beta: true
works_on:
    - konnect

entities: []
tools:
    - deck
    # - konnect-api
tags:
    - dynamic-client-registration
    - application-registration
    - openid-connect
    - authentication
    - auth0
search_aliases:
    - dcr
    - OpenID Connect

tldr:
    q: placeholder
    a: placeholder

prereqs:
  inline:
    - title: Dev Portal
      include_content: prereqs/api-catalog
      icon_url: /assets/icons/dev-portal.svg
  entities:
    services:
        - example-service
    routes:
        - example-route

cleanup:
  inline:
    - title: Clean up {{site.konnect_short_name}} environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.4'
related_resources:
  - text: placeholder
    url: /

next_steps:
  - text: placeholder
    url: /
---

## Create an API

(/api/konnect/api-builder/v3/#/operations/create-api)

<!--vale off-->
{% control_plane_request %}
url: /v3/apis
status_code: 201
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $DECK_KONNECT_TOKEN'
body:
    name: myApi
{% endcontrol_plane_request %}
<!--vale on-->

```sh
export API_ID='YOUR-API-ID'
```

## Create and associate an API document 

(/api/konnect/api-builder/v3/#/operations/create-api-document)

<!--vale off-->
{% control_plane_request %}
url: /v3/apis/$API_ID/documents
status_code: 201
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $DECK_KONNECT_TOKEN'
body:
    slug: api-document
    status: published
    title: API Document
    content: '# API Document Header'
{% endcontrol_plane_request %}
<!--vale on-->

## Create and associate an API spec

(/api/konnect/api-builder/v3/#/operations/create-api-spec)

<!--vale off-->
{% control_plane_request %}
url: /v3/apis/$API_ID/specifications
status_code: 201
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $DECK_KONNECT_TOKEN'
body:
    content: '{"openapi":"3.0.3","info":{"title":"Example API","version":"1.0.0"},"paths":{"/example":{"get":{"summary":"Example endpoint","responses":{"200":{"description":"Successful response"}}}}}}'
    type: oas3
{% endcontrol_plane_request %}
<!--vale on-->

## Associate the API with a Gateway Service

(/api/konnect/control-planes/v2/#/operations/list-control-planes)

<!--vale off-->
{% control_plane_request %}
url: /v2/control-planes
status_code: 201
method: GET
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $DECK_KONNECT_TOKEN'
{% endcontrol_plane_request %}
<!--vale on-->

```sh
export CONTROL_PLANE_ID='YOUR-CONTROL-PLANE-ID'
```

(/api/konnect/control-planes-config/v2/#/operations/list-service)

<!--vale off-->
{% control_plane_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/services
status_code: 201
method: GET
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $DECK_KONNECT_TOKEN'
{% endcontrol_plane_request %}
<!--vale on-->

```sh
export SERVICE_ID='YOUR-GATEWAY-SERVICE-ID'
```

(/api/konnect/api-builder/v3/#/operations/create-api-implementation)

<!--vale off-->
{% control_plane_request %}
url: /v3/apis/$API_ID/implementations
status_code: 201
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $DECK_KONNECT_TOKEN'
body:
    service:
        control_plane_id: $CONTROL_PLANE_ID
        id: $SERVICE_ID
{% endcontrol_plane_request %}
<!--vale on-->

## Publish the API to Dev Portal

(/api/konnect/portal-management/v3/#/operations/list-portals)

<!--vale off-->
{% control_plane_request %}
url: /v3/portals
status_code: 201
method: GET
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $DECK_KONNECT_TOKEN'
{% endcontrol_plane_request %}
<!--vale on-->

```sh
export PORTAL_ID='YOUR-DEV-PORTAL-ID'
```

(/api/konnect/api-builder/v3/#/operations/publish-api-to-portal)

<!--vale off-->
{% control_plane_request %}
url: /v3/apis/$API_ID/publications/$PORTAL_ID
status_code: 201
method: PUT
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $DECK_KONNECT_TOKEN'
{% endcontrol_plane_request %}
<!--vale on-->