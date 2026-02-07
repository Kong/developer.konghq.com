---
title: Create a Key Set with a JSON Web Key
permalink: /how-to/create-a-key-set-with-a-jwk/
content_type: how_to

description: Create a JSON Web Key and add it to a Key Set using the /key-sets API endpoint.

entities: 
  - key
  - key-set

related_resources:
  - text: Key entity
    url: /gateway/entities/key/
  - text: Key Set entity
    url: /gateway/entities/key-set/
  - text: Create a Key Set with a PEM Key
    url: /how-to/create-a-key-set-with-a-pem-key/
  - text: "Securing {{site.base_gateway}}"
    url: /gateway/security/

tags:
  - security

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.4'

tldr:
  q: How do I create a JWK and add it to a Key Set?
  a: Create a Key Set with the `/key-sets` endpoint, then create a Key and configure the `set.id` or `set.name` parameter to point to the Key Set.

prereqs:
  inline:
    - title: JSON Web Key
      content: |
        This tutorial requires a JSON Web Key. You can generate your own or use this one for testing:
        ```json
        {
            "kty": "RSA",
            "e": "AQAB",
            "use": "enc",
            "kid": "my-key",
            "alg": "RSA1_5",
            "n": "n_03K8g2O_rarMBqBpbDKtRzrKede24g8UQ8Jc_x4-vsBnCFJw_xUcy-j4Ub9hYQZtyBZ5bWuEWC1crsorFgDbzoO1fF237XtCUCb0G6a8-3fbeSQZGwglK_vIy8-pHzZnOC2kgHp-rrNo9xZHnaOkrqqW4CI8izDuxboi_BlGqiNjKqGimj6fCPkiIEFlIrAtQCM9bUJDXv_iIs9blv9StqrfWnwxPIeIuoeruY_eC76twMweH5JHEAx_7BJdTdOXo9lrwmoUYwLAPp9w4E9Dc1lW1gQXh8aK4UUaJcsTjEztPtKsPHkQGSuP5WxM5uNH9Jo3-4wwuoA6BDxBS4sw"
        }
        ```
      icon_url: /assets/icons/key.svg

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Create a Key Set
Using the Admin API, create a Key Set to hold JSON Web keys:
{% control_plane_request %}
url: /key-sets
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
body:
    name: my-key-set
status_code: 201
{% endcontrol_plane_request %}

You will get a `201 Created` response with details about the new Key Set. For example:

```json
{
    "name":"my-key-set",
    "id":"539c3c53-b3ff-43f2-a500-2f812d1d3e09",
    "created_at":1739270324,
    "updated_at":1739270324,
    "tags":null
}
```
{:.no-copy-code}

## Create a Key

Create a Key and use either the `set.id` from the response in the previous step, or the `set.name` parameter to add it to the Key Set:

{% control_plane_request %}
url: /keys
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Kong-Admin-Token: $KONG_ADMIN_TOKEN'
body:
    name: my-key
    kid: my-key
    set:
      name: my-key-set
    jwk: "{\"kty\":\"RSA\",\"e\":\"AQAB\",\"use\":\"enc\",\"kid\":\"my-key\",\"alg\":\"RSA1_5\",\"n\":\"n_03K8g2O_rarMBqBpbDKtRzrKede24g8UQ8Jc_x4-vsBnCFJw_xUcy-j4Ub9hYQZtyBZ5bWuEWC1crsorFgDbzoO1fF237XtCUCb0G6a8-3fbeSQZGwglK_vIy8-pHzZnOC2kgHp-rrNo9xZHnaOkrqqW4CI8izDuxboi_BlGqiNjKqGimj6fCPkiIEFlIrAtQCM9bUJDXv_iIs9blv9StqrfWnwxPIeIuoeruY_eC76twMweH5JHEAx_7BJdTdOXo9lrwmoUYwLAPp9w4E9Dc1lW1gQXh8aK4UUaJcsTjEztPtKsPHkQGSuP5WxM5uNH9Jo3-4wwuoA6BDxBS4sw\"}"
status_code: 201
{% endcontrol_plane_request %}

You will get a `201 Created` response with details about the new Key, including the Key Set ID. For example:

```json
{
  "tags":null,
  "jwk":"{\"kty\":\"RSA\",\"e\":\"AQAB\",\"use\":\"enc\",\"kid\":\"my-key\",\"alg\":\"RSA1_5\",\"n\":\"n_03K8g2O_rarMBqBpbDKtRzrKede24g8UQ8Jc_x4-vsBnCFJw_xUcy-j4Ub9hYQZtyBZ5bWuEWC1crsorFgDbzoO1fF237XtCUCb0G6a8-3fbeSQZGwglK_vIy8-pHzZnOC2kgHp-rrNo9xZHnaOkrqqW4CI8izDuxboi_BlGqiNjKqGimj6fCPkiIEFlIrAtQCM9bUJDXv_iIs9blv9StqrfWnwxPIeIuoeruY_eC76twMweH5JHEAx_7BJdTdOXo9lrwmoUYwLAPp9w4E9Dc1lW1gQXh8aK4UUaJcsTjEztPtKsPHkQGSuP5WxM5uNH9Jo3-4wwuoA6BDxBS4sw\"}",
  "pem":null,
  "name":"my-key",
  "kid":"my-key",
  "id":"03cc15ef-f157-42dd-a43b-9959550ca466",
  "created_at":1739270335,
  "updated_at":1739270335,
  "set":
  {
    "id":"539c3c53-b3ff-43f2-a500-2f812d1d3e09"
  }
}
```
{:.no-copy-code}