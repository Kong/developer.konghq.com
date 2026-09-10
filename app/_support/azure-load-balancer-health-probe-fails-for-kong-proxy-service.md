---
title: Azure Load Balancer health probe fails for Kong proxy service
content_type: support
description: When running Kong on Kubernetes v1.24 or higher with Azure Load Balancer, the health probe created by the Load Balancer fails and causes the Azure Kubernetes service to restart the Kong proxy service repeatedly, typically when HTTP is enabled for the proxy service.
products:
  - kic
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does the Azure Load Balancer health probe fail for the Kong proxy service when http is enabled?
  a: |
    On Kubernetes v1.24 and higher, the Azure Load Balancer health probe reads the protocol from `spec.ports.AppProtocol` instead of `spec.ports.Protocol`, so an HTTP-enabled Kong proxy service gets an HTTP health probe that fails and triggers repeated pod restarts. Set `proxy.http.appProtocol` (and/or `proxy.tls.appProtocol`) to `tcp` in your Helm `values.yaml` to force a TCP health probe, or point the Load Balancer's HTTP probe at Kong's status port (8100) instead.
---

## Problem

When running Kong on Kubernetes v1.24 or higher and using Azure Load Balancer, you find the health probe created by the Load Balancer fails and makes the Azure Kubernetes service restart the Kong proxy service constantly.

## Cause

The cause of the problem is a change in the health probe behavior for clusters v1.24 or higher. For clusters <=1.23, the health probe uses the protocol configured in `spec.ports.Protocol` (which is tcp) and for clusters >1.24 the health probe uses the protocol configured in `spec.ports.AppProtocol` (which is http/https). You can find more details here: Custom Load Balancer health probe

Then, when http is enabled for the Kong proxy service and Kubernetes version is >1.24, the Azure Load Balancer health probe uses HTTP and fails.

## Solution

The current Kong Helm chart exposes `appProtocol` as a first-class, conditional field directly in `values.yaml` (`proxy.http.appProtocol` / `proxy.tls.appProtocol`), so you no longer need to hand-patch `_helpers.tpl` to set it. The default value is unset (`""`), so unmodified recent installs may not trigger this bug at all; if you do hit it, set `proxy.http.appProtocol` (and/or `proxy.tls.appProtocol`) to `tcp` in your `values.yaml`. Using pure TCP fixes any problems with HTTP health probes as it removes HTTP health probes from the equation entirely.

Other alternatives are:

- Applying a Kubernetes manifest yaml instead of using Helm
- Adding a `/healthz` endpoint in the Kong proxy (file `/usr/local/share/lua/5.1/kong/templates/nginx_kong.lua`) but it requires creating a custom image.
- A custom image is not actually required to get a working HTTP health check: Kong already ships a dedicated, unauthenticated status endpoint (`status_listen`, default port 8100) that returns a plain `200` unconditionally — live-confirmed (`GET /status` on the status port returns `200` even when the plain proxy port returns `404 {"message":"no Route matched with those values"}` for the same path, since the proxy 404s on any path with no matching Route). Azure's cloud-provider-azure supports redirecting a Service port's health probe to a different port on the backend pods via the per-port annotation `service.beta.kubernetes.io/port_{port}_health-probe_port` (paired with `..._health-probe_protocol: http` and `..._health-probe_request-path: /status`), so the Load Balancer's HTTP probe can be pointed at Kong's existing status port (8100) instead of the proxy port — giving a real HTTP health check without needing `appProtocol: tcp` or a custom `/healthz` image at all.
