---
title: How to manage groups using the Admin API
content_type: support
description: Example Admin API requests to list, create, and update groups within a Kong Gateway workspace.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I create, list, and update groups using the Kong Admin API?
  a: |
    Use the Admin API's `/<workspace>/groups` endpoint: a `GET` request lists groups, a `POST` request creates one, and a `PATCH` request to `/<workspace>/groups/{name_or_id}` updates one.
---

## Overview

In an attempt to automate the deployment of the Gateway we would like to use the Admin API to create groups. How can this be achieved?

## Steps

The below can be used as a reference to using the Admin API to create and update groups. Examples will assume:

- Gateway hostname of `localhost`
- Admin API port of `8001`
- Named workspace of `dev`

These can be modified to suit your environment.

1. List groups.

   ```bash
   curl http://localhost:8001/dev/groups
   ```

2. Create a group.

   ```bash
   curl 'http://localhost:8001/dev/groups' \
     -H 'content-type: application/json;charset=UTF-8' \
     --data-raw '{"name":"dev-group","comment":"on-boarding dev group"}'
   ```

3. Update a group.

   ```bash
   curl 'http://localhost:8001/dev/groups/{name_or_id)' \
     -X 'PATCH' \
     -H 'content-type: application/json;charset=UTF-8' \
     --data-raw '{"name":"dev-group-update","comment":"on-boarding dev group"}'
   ```
