---
title: Sort order of the Audit Log API response
content_type: support
description: The Audit Log API sorts both the Request Audits and Database/Object Audits endpoints by `request_timestamp` descending by default, but this can be overridden with the standard `sort_by` and `sort_desc` query parameters.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: What is the sort order of the Audit Log API response?
  a: |
    Both the Request Audits (`/audit/requests`) and Database/Object Audits (`/audit/objects`) endpoints sort by `request_timestamp` descending by default. Override this with the standard `sort_by` and `sort_desc` query parameters, for example `sort_by=request_id&sort_desc=false`, using any field present in the entity's schema.
related_resources: []
---

## Problem

The Audit Log API returns responses sorted by `request_timestamp` in descending order by default, and it isn't clear whether that sort order can be changed to something else.

## Solution

(1) The Request Audits API (`GET /audit/requests`) response is sorted by the `request_timestamp` attribute, descending (most recent first), by default.

(2) The Database/Object Audits API (`GET /audit/objects`) response is sorted by the same `request_timestamp` attribute, descending, by default.

Can we change it to another order?

Yes. Both endpoints accept the standard Admin API collection query parameters `sort_by` and `sort_desc`. Passing an explicit `sort_by=<field>` overrides the default `request_timestamp` sort — for example, `GET /audit/requests?sort_by=request_id&sort_desc=false` sorts by `request_id` ascending instead, and `GET /audit/objects?sort_by=id&sort_desc=false` sorts by the object audit's own `id` field ascending. Any field present in the respective entity's schema can be used with `sort_by`. Note that the field is named `request_id` on `/audit/requests` and `id` on `/audit/objects` — neither entity has a field literally named `id` on `/audit/requests` (attempting `sort_by=id` there returns `400 {"message":"invalid option (sort_by: cannot order by unknown field 'id')"}`).

When no explicit `sort_by` is supplied, the paginated `next` link on both endpoints carries the default sort forward, e.g. `.../audit/requests?offset=...&sort_by=request_timestamp&sort_desc=true&size=...`, so pagination remains consistent across pages without you needing to add the parameters yourself.
