---
title: 'ACL'
name: 'ACL'

content_type: plugin

publisher: kong-inc
description: 'Control which consumers can access services'
tier: enterprise


products:
    - gateway

works_on:
    - on-prem
    - konnect

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: acl.png

categories:
  - traffic-control
---

## Overview

Restrict access to a service or a route by adding consumers to allowed or
denied lists using arbitrary ACL groups. This plugin requires an [authentication plugin](/hub/#authentication)
(such as [Basic Authentication](/hub/kong-inc/basic-auth/), [Key Authentication](/hub/kong-inc/key-auth/),
[OAuth 2.0](/hub/kong-inc/oauth2/) or [OpenID Connect](/hub/kong-inc/openid-connect/)) to have been already
enabled on the service or route.

{% if_version gte:3.6.x %}
You can also enable the usage of consumer groups by setting the config option [`include_consumer_groups`](/hub/kong-inc/acl/configuration/#include_consumer_groups) to `true`.
This option lets {{site.base_gateway}} take both ACL groups and consumer groups into consideration when evaluating the `allow` and `deny` fields.
{% endif_version %}

You can't configure an ACL with both `allow` and `deny` configurations. An ACL with an `allow` provides a positive security model, in which the configured groups are allowed access to the resources, and all others are inherently rejected. By contrast, a `deny` configuration provides a negative security model, in which certain groups are explicitly denied access to the resource (and all others are allowed).

## Upstream headers

When a consumer has been validated, the plugin appends a `X-Consumer-Groups`
header to the request before proxying it to the Upstream service, so that you can
identify the groups associated with the consumer. The value of the header is a
comma-separated list of groups that belong to the consumer, like `admin, pro_user`.

This header will not be injected in the request to the upstream service if
the `hide_groups_header` config flag is set to `true`.
