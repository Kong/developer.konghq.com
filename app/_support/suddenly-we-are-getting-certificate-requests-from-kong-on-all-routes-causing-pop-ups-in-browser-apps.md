---
title: Suddenly we are getting certificate requests from kong on all routes causing Pop ups in Browser Apps
content_type: support
description: "The `mtls-auth` plugin can start requesting a client certificate on every route, not just the ones it's configured on, if a route is missing its `snis` property or a global instance of the plugin exists."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: here
    url: /plugins/mtls-auth/#client-certificate-request
tldr:
  q: Why is Kong suddenly sending certificate requests on all routes when we're only using the mtls-auth plugin on a few of them?
  a: |
    The `mtls-auth` plugin decides whether to request a client certificate before Kong knows which route or workspace the request belongs to, using an in-memory map of SNIs. A global `mtls-auth` plugin, or any route with the plugin that's missing its `snis` property (or reusing an SNI shared with SNI-less routes), makes Kong request a certificate on every request. This SNI-based behavior only applies to traditional routes — expression-based routes (`router_flavor: expressions`) always request a client certificate. Check for routes with the plugin but no `snis` set, and review audit logs for what changed.
---

## Problem

All of a sudden we are seeing Pop up windows in our Browser Apps which are proxying through Kong asking users to choose a client cert. We are using the `mtls-auth` plugin but only on a small subset of our routes so we would not expect ALL routes to be affected, and it is not clear what configuration change caused this. How can we find out, and fix the change that caused this.

## Cause

When the `mtls-auth` plugin is configured in Kong, there are certain situations where Kong sends certificate requests with all requests, as documented here.

In short kong will start sending certificate requests with all requests if you have a global `mtls-auth` plugin on any workspace or if you have a route with an `mtls-auth` plugin that does NOT have an SNI property or has an SNI property that matches the one used for other routes that do NOT use the SNI property. As the documentation explains in more detail, this is because during the phase where kong needs to send the certificate request, it does not have access to route or workspace information, and uses an in-memory map of SNIs to determine if a certificate request should be sent or not.

Note: if you are using expression-based routes (`router_flavor: expressions`), the client certificate is always requested on every TLS handshake regardless of whether SNIs are configured on those routes — the SNI-based optimization described above only applies to traditional (`traditional_compatible`) routes. If your routes are expression-based, a missing SNI is not the cause and the SQL check below will not find anything to fix.

## Solution

If you have confirmed that you do not have any global `mtls-auth` plugins in any workspace, and your normal procedure is to set a specific SNI property on all routes that are associated with an `mtls-auth` plugin, and you have access to the postgres backend of kong, you may find the following SQL query useful to find any route that may have been updated, and accidentally had the SNI property removed. This will give you the workspace name, route id, and route name of any route that is associated with an `mtls-auth` plugin and does NOT have an SNI property set.

```sql

SELECT w.name workspace_name, r.id, r.name, r.snis FROM routes r INNER JOIN workspaces w ON r.ws_id=w.id WHERE r.id IN (SELECT route_id FROM plugins WHERE name = 'mtls-auth') AND snis IS NULL;
```

You may also want to enable audit logging to be able to check what changes were made before you started seeing the issue, and by whom.
