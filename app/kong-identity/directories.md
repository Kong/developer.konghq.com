---
title: "Directories"
content_type: reference
layout: reference
permalink: /identity/directories/
products:
  - identity
  - konnect
api_specs:
    - konnect/kong-identity-principals
works_on:
  - konnect

breadcrumbs:
  - /identity/

min_version:
  gateway: '3.15'

description: "Learn how {{site.identity}} directories group principals and groups by region, control which control planes can authenticate against them, and cache lookups."

related_resources:
  - text: "{{site.identity}} principals"
    url: /identity/principals/
  - text: "{{site.identity}} auth servers"
    url: /identity/auth-servers/
  - text: "{{site.konnect_short_name}} control plane resource limits"
    url: /gateway/control-plane-resource-limits/
---

{% include sections/principals-and-directories.md %}

A directory is the organizational boundary for grouping [principals](/identity/principals/) and [groups](/identity/groups/) and managing their identities. 
Directories are region-specific, and each directory controls which control planes can make authentication requests to it.

## Control plane access

Each directory controls which control planes can make authentication requests to it. You can either:

* List the control planes that can authenticate against the directory in `allowed_control_planes`. You can specify a maximum of 32 control planes.
* Set `allow_all_control_planes` to `true` to allow every control plane in your organization to make authentication requests. This overrides the `allowed_control_planes` list.

## Lookup caching

{{site.identity}} caches principals on the data plane so that repeated lookups don't require a connection to {{site.konnect_short_name}}. 
You can tune the following settings on a directory:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Description
    key: description
rows:
  - setting: "`ttl_secs`"
    description: "How long a gateway caches a principal after it authenticates successfully from this directory. Defaults to 600 seconds (10 minutes). Minimum is 300 seconds, maximum is 86400 seconds (24 hours)."
  - setting: "`negative_ttl_secs`"
    description: "How long a gateway waits before it looks up a principal again when the principal doesn't exist in the directory or the credentials are invalid. Defaults to 600 seconds (10 minutes). Minimum is 300 seconds, maximum is 86400 seconds (24 hours)."
{% endtable %}

For {{site.base_gateway}}, the effective cache lifetime is the smallest of the directory TTL, the TTL set on a credential, and the `db_cache_ttl` configured on the gateway.

## Create a directory

{% navtabs "create-directory" %}
{% navtab "API" %}

Send a `POST` request to the `/v2/directories` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories
status_code: 201
method: POST
body:
  name: example-directory
  description: Example directory for principals
  allow_all_control_planes: true
{% endkonnect_api_request %}
<!--vale on-->

{% endnavtab %}
{% navtab "UI" %}

{{site.identity}} automatically creates a default directory when you [create your first principal](/identity/principals/#configure-a-principal) in the UI.

{% endnavtab %}
{% endnavtabs %}

## Directory limitations

The following are default limits for directories:

* 1 directory per region.
  Contact Kong Support if you need more than one directory.
* 100,000 principals per directory. Contact Kong Support if you need higher limits.
* 10,000 groups per directory. See [Group limitations](/identity/groups/#group-limitations) for other group limits.
* Limit of 100 authentication or principal lookup requests per second per directory, not counting cached requests
* Maximum of 32 allowed control planes per directory
