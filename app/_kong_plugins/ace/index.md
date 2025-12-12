---
title: 'Access Control Enforcement'
name: 'Access Control Enforcement'

content_type: plugin

publisher: kong-inc
description: 'The ACE plugin manages developer access control to APIs published with Dev Portal.'

products:
  - gateway

works_on:
  - konnect

min_version:
   gateway: '3.13'

topologies:
  on_prem:
    - hybrid
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

tags:
  - traffic-control

icon: ace.png 

categories:
  - traffic-control

related_resources:
  - text: Dev Portal API packaging
    url: /dev-portal/api-catalog-and-packaging/
---

{:.warning}
> **Important:** The Access Control Enforcement plugin can only be used with APIs that are linked to a control plane, which is a private beta feature. Contact your account manager for access.

The Access Control Enforcement (ACE) plugin manages developer access control to APIs published with Dev Portal.

Previously, when you created an API catalog in Dev Portal and linked the APIs to a Gateway Service, {{site.konnect_short_name}} would automatically apply the {{site.konnect_short_name}} application auth (KAA) plugin automatically. API packages uses the ACE plugin instead to manage developer access control to APIs. Unlike the KAA plugin, the ACE plugin can link to control planes to configure access control and create operations for Gateway Services in those control planes.

The ACE plugin runs *after* all other [authentication plugins](/plugins/?category=authentication) run. For example, if you have Key Authentication configured and it rejects a request, the ACE plugin *will not* run. To allow for multiple authentication plugins, each must set the `config.anonymous` plugin configuration. Additionally, the choice to allow or reject an `anonymous` result after all authentication plugins have run needs to be controlled as described in [using multiple authentication methods](gateway/authentication/#using-multiple-authentication-methods).

## Route matching policy

When you configure the ACE plugin, you must set either `required` or `present` for `config.match_policy`. This determines how the ACE plugin will behave when a request doesn't match an existing Route.

Keep in mind that misconfigurations can overexpose unintended Routes. 

The following table describes what the `match_policy` values do and when to use each:
{% table %}
columns:
  - title: Setting
    key: setting
  - title: Description
    key: description
  - title: Limitations
    key: limitations
  - title: Use cases
    key: use-case
rows:
  - setting: |
      `required`
    description: |
      Requires every incoming request to match a defined operation from an API or API package in Dev Portal. If a request doesn't match, ACE rejects the request outright with a 404. All traffic will be rejected except operations or Routes in published APIs linked to an ACE-enabled {{site.base_gateway}}. 

      {:.danger}
      > **Warning:** Setting the `match_policy` to `required` can **block all traffic with a 404**. Any undefined endpoints will be blocked. If you accidentally enable this in your control planes, this could cause a potential outage in production.
    limitations: |
      * Shuts down all traffic outside of ACE-enabled Dev Portal APIs.
      * If the plugin is improperly configured, potentially all traffic could be terminated.
    use-case: |
      * You want to lock down {{site.konnect_short_name}} so that only traffic that is part of an explicitly defined API operation is allowed through.
      * You only plan to provide self-service access via your Dev Portal. 
  - setting: |
      `if_present`
    description: |
      By default, the ACE plugin only engages with a request when it matches an operation. If a request doesn't match, ACE lets the request pass through untouched. This means that non-matching requests aren't rejected, but ACE also won't perform authentication and authorization on them. This allows a request to still be processed by other plugins with a [lower priority](/gateway/entities/plugin/#plugin-priority) than ACE.  
    limitations: |
      * All traffic outside of published APIs linked to an ACE-enabled {{site.base_gateway}} won't be access controlled, this must be configured with a different plugin. Dev Portal will not be able to protect all operations.
      * Since Routes aren't protected by default in this mode, any mistyped or omitted operation in API entities could result in open access.
    use-case: |
      * You have an environment where some Gateway Services or Routes are governed by Dev Portal–exposed APIs (with ACE), while others are regular Routes that should be left alone.
      * You already have existing traffic and other access controls in place and want to avoid interruption.
{% endtable %}