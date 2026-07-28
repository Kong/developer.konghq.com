---
title: "Kong Gateway: Kong Manager Login Not Working in OpenShift"
content_type: support
description: "In OpenShift, using HTTP/2 with passthrough Routes that share the same SSL certificate across the Kong Manager and Admin API routes causes connection coalescing, which crisscrosses requests between them and breaks Kong Manager login."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Configuring ingress cluster traffic - Using HTTP/2 (Red Hat OpenShift documentation)
    url: https://access.redhat.com/documentation/zh-cn/openshift_container_platform/4.5/html/networking/nw-http2-haproxy_configuring-ingress
tldr:
  q: Why does Kong Manager login fail with OIDC when running Kong Gateway in OpenShift?
  a: |
    In OpenShift, using HTTP/2 on passthrough Routes that share the same SSL certificate for the Kong Manager and Admin API causes HAProxy to coalesce the connections, crisscrossing requests between them. This breaks Manager login, content-type handling, cookies, CORS, and `DELETE` requests. Fix it by giving each Route its own SSL certificate, or by disabling HTTP/2 on passthrough Routes that share a certificate.
---

## Problem

We've recently installed Kong Gateway with Manager and OIDC Auth enabled in OpenShift, here is what we are seeing during login:

1) Manager login fails

2) Unexpected content types being returned from the underlying Admin API requests (`text/html` instead of `application/json`)

3) Session cookies not being set appropriately

4) CORS errors

5) Certain request method types appear to be failing (`DELETE` specifically)

This same setup works in our non-OpenShift environment.

## Solution

Assuming `admin_gui_session_conf` is set appropriately and we are confident in the OIDC configuration (worked elsewhere):

The issue stems from making use of HTTP/2 with passthrough OpenShift Routes and having the same SSL certificate bound to those routes.

In OpenShift, if you are doing the above, it will attempt to coalesce the connections and you will effectively see it criss-crossing (sending requests meant for the Admin API to the Manager, and vice versa).

This leads to the issues stated above and logging in will not function.

Details of this can be found here:

"To enable the use of HTTP/2 for the connection from the client to HAProxy, a route must specify a custom certificate. A route that uses the default certificate cannot use HTTP/2. This restriction is necessary to avoid problems from connection coalescing, where the client re-uses a connection for different routes that use the same certificate."

To remedy the situation, you can take one of two actions:

1) Ensure that your OpenShift Routes all make use of different SSL certificates

2) Turn off HTTP/2 when using passthrough OpenShift Routes with the same SSL certificate
