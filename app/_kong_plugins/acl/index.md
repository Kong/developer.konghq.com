---
title: 'ACL'
name: 'ACL'

content_type: plugin

publisher: kong-inc
description: Control which Consumers can access Services and Routes

related_resources:
  - text: Use the ACL plugin with Consumer Groups
    url: /how-to/use-acl-with-consumer-groups/
  - text: "{{site.base_gateway}} traffic control and routing"
    url: /gateway/traffic-control-and-routing/

tags:
  - traffic-control

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

search_aliases:
  - access control list

min_version:
  gateway: '1.0'
---

The ACL (access control list) plugin allows you to restrict [Consumer](/gateway/entities/consumer/) access to a [Gateway Service](/gateway/entities/service/) or [Route](/gateway/entities/route/). You do this by configuring **either** an allow list or a deny list with certain Consumers or [Consumer Groups](/gateway/entities/consumer-group/).

This plugin uses authenticated Consumers to identify who can and can't access the Service or Route. Because of this, you must also configure an [authentication plugin](/plugins/?category=authentication)
(such as [Basic Authentication](/plugins/basic-auth/), [Key Authentication](/plugins/key-auth/),
[OAuth 2.0](/plugins/oauth2/) or [OpenID Connect](/plugins/openid-connect/)) on the Service or Route **before** configuring the ACL plugin.

## Upstream Consumer Groups header

If `hide_groups_header` is set to `false` and a Consumer is validated, the plugin appends a `X-Consumer-Groups` header to the request before proxying it to the upstream service. The header contains a comma separated list of groups that belong to the Consumer, for example `admin, pro_user`. This allows you to identify the groups associated with the Consumer. 
