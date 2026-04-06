---
title: 413 Request Entity Too Large
content_type: support
description: Create an admin user using the Kong Admin API instead of Kong Manager.
products:
  - gateway

works_on:
  - on-prem
  - konnect


related_resources:
  - text: RBAC reference
    url: /gateway/kong-enterprise/rbac/
  - text: Admin API reference
    url: /gateway/admin-api/

tldr:
  q: How do I create an admin using the API instead of Kong Manager?
  a: Temporarily disable RBAC, create an RBAC user with the super-admin role, re-enable RBAC, then use that user to create and register the new admin.

---

This error can occur for a few reasons:

1. You are attempting to proxy a payload through the Gateway that is larger than it is configured to allow.

2. You are attempting to upload a config file in DB-less mode to the /config endpoint that exceeds the configured size.

To address this you can adjust the payload size by setting the appropriate parameter:

In the case of proxying: nginx_proxy_client_max_body_size

In the case of DB-less config: nginx_admin_client_max_body_size

This can be changed either through injecting Nginx directives in your Kong configuration (kong.conf/values/environment variables) or using a custom Nginx template.

References:

Client Max Body Size : Nginx documentation on client max body size parameter

Directive Injection : Nginx Directive Injection in Kong Gateway

Custom Nginx template : Custom Nginx templates in Kong Gateway
