---
title: "Kong Mesh: Empty responses in cURL tests service-to-service, Error: \"exit code 52\""
content_type: support
description: Empty cURL responses with `exit code 52` between mTLS-enabled Kong Mesh services usually mean the application and `kuma-sidecar` containers share the same user/group ID.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: this webpage which explains each exit code number for cURL and what they mean
    url: https://everything.curl.dev/usingcurl/returns
tldr:
  q: Why do cURL tests between Kong Mesh services return empty responses with `exit code 52` when mTLS is enabled?
  a: |
    This happens when the application container and the `kuma-sidecar` container share the same `runAsUser`/`runAsGroup` ID (for example, both set to `10001`). The sidecar's ID is excluded from Envoy traffic redirection, so a matching ID lets the application bypass the sidecar entirely, and the mTLS-enforced target rejects the direct request. Use a different ID (for example, `20001`) for the application container so it is distinct from the `kuma-sidecar` container.
---

## Problem

We are trying to set up Kong Mesh and we are not seeing our services communicating with each other. When we run cURL tests from a service to another service, we see empty responses coming back with `exit code 52`, suggesting that communication is not working somehow. We are using mTLS in our services too.

```bash
k exec -n $app $podname -c $app -- bash -c 'curl -I --silent <appName>:<port>/<path>'
command terminated with exit code 52
```

## Cause

This situation can occur when a user/group ID number on the application container matches the same one set on the `kuma-sidecar` container. These numbers must be different. For example, if `runAsUser` and/or `runAsGroup` is defined as `10001` and it's set on both the application container and the `kuma-sidecar` container, this will present the reported issue. It's important to understand that the ID number specified for the sidecar is excluded from traffic redirects to Envoy as we do not want the Mesh's own traffic to be intercepted. When the application is also set with this ID, the IPtables rules would execute and bypass the sidecar, allowing you to hit the target directly. Because mTLS is being enforced at the target, the request is rejected.

## Solution

If the intention is to use non-standard IDs for user and group on the containers for security reasons, that is still achievable, however it must be unique between the application container and the `kuma-sidecar` container, they cannot use the same ID numbers. For example, set the `kuma-sidecar` container with an ID of `10001` and then use a different ID of `20001` on the application container, essentially any number not set on the `kuma-sidecar` container.

Sidenote: if cURL exit code numbers are not known to a user, we recommend reviewing this webpage which explains each exit code number for cURL and what they mean. In this case, exit code 52 means "The server did not reply anything, which in this context is considered an error. When an HTTP(S) server responds to an HTTP(S) request, it will always return something as long as it is alive and sound. All valid HTTP responses have a status line and responses header. Not getting anything at all back is an indication the server is faulty or perhaps that something prevented curl from reaching the right server or that you are trying to connect to the wrong port number etc."
