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
  - text: Dynamic plugin config with CEL
    url: /gateway/plugins/expressible-fields/

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

## Dynamic allow and deny rules {% new_in 3.16 %}

Instead of an allow or deny list of group names, you can use [`allow_when`](/plugins/acl/reference/#schema--config-allow-when) or [`deny_when`](/plugins/acl/reference/#schema--config-deny-when) to allow or deny requests based on a list of [CEL](https://cel.dev/) boolean expressions, evaluated against the same fields available to [plugin conditions](/gateway/plugins/conditions/) (for example, the authenticated Consumer, Principal, or HTTP request attributes).

`allow`, `deny`, `allow_when`, and `deny_when` are mutually exclusive. Configure exactly one of them on a given ACL plugin instance:

```yaml
config:
  allow_when:
    - "has(principal.metadata.tier) && principal.metadata.tier == \"partner\""
```

Each entry in `allow_when` or `deny_when` is evaluated in order, with OR semantics:

* For `allow_when`, the request is allowed as soon as any expression matches. If none match, the request is denied with a `403` response, the same behavior as when no group in an `allow` list matches.
* For `deny_when`, the request is denied with a `403` response as soon as any expression matches. If none match, the request is allowed, **unless** one or more expressions failed to compile or evaluate. In that case, the plugin fails closed and returns a `500` response, since treating an evaluation failure the same as "no match" could let through a request that should have been denied.

When `allow_when` or `deny_when` is configured:
* `hide_groups_header`, `include_consumer_groups`, and `always_use_authenticated_groups` are all ignored.
* The `X-Consumer-Groups` header isn't sent to the upstream service, since there's no matched group list to report.

For example plugin configurations, see [Allow by Principal metadata](/plugins/acl/examples/allow-when-principal-metadata/) and [Deny by Principal metadata](/plugins/acl/examples/deny-when-principal-metadata/).

For general information on this class of CEL-driven plugin config, see [Dynamic plugin config with CEL](/gateway/plugins/expressible-fields/).
