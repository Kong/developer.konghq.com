---
title: "Konnect API Errors"
content_type: reference
layout: reference

products:
  - konnect

tags:
  - errors
breadcrumbs:
  - /api/
description: "Documentation on common API errors when working with Kong products"

related_resources:
  - text: API specifications
    url: /api/

works_on:
  - on-prem
  - konnect
---

<!--vale off-->
{% table %}
columns:
  - title: Error Code
    key: code
  - title: Description
    key: description
  - title: Resolution
    key: resolution
rows:
  - code: bad-request
    description: Your API request did not match the expected schema
    resolution: "Check the [request schema](/api/) for the API that you're calling"
  - code: unauthorized
    description: "The `Authorization` header is missing from your request, or an invalcode token has been provided"
    resolution: "Ensure that your have specified a `Authorization: Bearer TOKEN_HERE` header in your request"
  - code: forbidden
    description: "You do not have permission to call the specified API"
    resolution: "Reach out to your organization administrator to request elevated permissions"
  - code: not-found
    description: The endpoint that you have requested does not exist, or belongs to a different organization
    resolution: "Check your request URL and try again"
  - code: conflict
    description: The resource could not be created due to an existing resource on the remote server
    resolution: "Change your API request to contain unique details"
  - code: internal
    description: There has been a server error. This requires intervention from the Kong team to fix.
    resolution: "Check the [Kong Status Page](https://kong.statuspage.io/) for any updates"
{% endtable %}
<!--vale on-->