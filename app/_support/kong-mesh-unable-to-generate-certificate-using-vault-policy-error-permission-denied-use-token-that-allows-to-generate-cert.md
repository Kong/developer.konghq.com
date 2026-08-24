---
title: "Kong Mesh: Unable to generate certificate using Vault policy, error: \"permission denied - use token that allows to generate cert\""
content_type: support
description: "{{site.mesh_product_name}} can fail to generate certificates through Vault Policy when a Hashicorp Vault child token's parent token has a shorter TTL, causing `permission denied` errors; extending the parent TTL or switching to an orphan token resolves it."
products:
  - mesh
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Hashicorp Vault documentation on token hierarchies and orphan tokens
    url: https://developer.hashicorp.com/vault/docs/concepts/tokens#token-hierarchies-and-orphan-tokens
tldr:
  q: "Why does Kong Mesh fail to generate a certificate through Vault Policy with a \"permission denied - use token that allows to generate cert\" error?"
  a: |
    This typically happens when the Hashicorp Vault token Kong Mesh uses is a `child token` whose `parent token` has a shorter TTL — Vault's token hierarchy lets the parent's expiry override the child's, so the child stops working sooner than expected. Fix it by giving the parent token a longer TTL and making the child token `renewable`, or by switching to an `orphan token`, which has no max TTL and lives indefinitely as long as it's renewed.
---

## Problem

We're trying to set up {{site.mesh_product_name}} with the Vault Policy for integration with Hashicorp Vault but we are receiving errors after a period of time. It's as if the Hashicorp token is no longer valid and thus it's unable to generate the certificate. We see this error in the {{site.mesh_product_name}} logs:

```
2023-08-08T17:21:29.041Z ERROR xds-server.dataplane-sync-watchdog OnTick() failed {"dataplaneKey": {"Mesh":"{nameOfMeshCluster}","Name":"cluster-mgi-58cf779d4c-tntjr.kong-mesh-system"}, "error": "failed to generate a snapshot: imports[0]{name=\"gateway-proxy\"}: secrets.Generator failed: failed to generate dataplane identity cert and CAs: could not generate certificates: could not get Dataplane cert pair: could not generate dataplane cert for mesh: \"nonprod\" backend: \"vault-1\" services: \"kuma.io/service={ServiceName} kuma.io/zone={ServiceName}\": permission denied - use token that allows to generate cert of pki-internal/issue/np-kong-mesh", "errorVerbose": "imports[0]{name=\"gateway-proxy\"}: secrets.Generator failed: failed to generate dataplane identity cert and CAs: could not generate certificates: could not get Dataplane cert pair: could not generate dataplane cert for mesh: \"{nameOfMeshCluster}\" backend: \"vault\" services: \"kuma.io/service={ServiceName} kuma.io/zone={ServiceName}\": permission denied - use token that allows to generate cert of pki-internal/issue/np-kong-mesh\nfailed to generate a snapshot\ngithub.com/kumahq/kuma/pkg/xds/server/v3.(*reconciler).Reconcile\n\tgithub.com/kumahq/kuma@v0.0.0-20230414081006-9a2812c6b3a4/pkg/xds/server/v3/reconcile.go:59\ngithub.com/kumahq/kuma/pkg/xds/sync.(*DataplaneWatchdog).syncDataplane\n\tgithub.com/kumahq/kuma@v0.0.0-20230414081006-9a2812c6b3a4/pkg/xds/sync/dataplane_watchdog.go:130\ngithub.com/kumahq/kuma/pkg/xds/sync.(*DataplaneWatchdog).Sync\n\tgithub.com/kumahq/kuma@v0.0.0-20230414081006-9a2812c6b3a4/pkg/xds/sync/dataplane_watchdog.go:66\ngithub.com/kumahq/kuma/pkg/xds/sync.(*dataplaneWatchdogFactory).New.func2\n\tgithub.com/kumahq/kuma@v0.0.0-20230414081006-9a2812c6b3a4/pkg/xds/sync/dataplane_watchdog_factory.go:46\ngithub.com/kumahq/kuma/pkg/util/watchdog.(*SimpleWatchdog).onTick\n\tgithub.com/kumahq/kuma@v0.0.0-20230414081006-9a2812c6b3a4/pkg/util/watchdog/watchdog.go:54\ngithub.com/kumahq/kuma/pkg/util/watchdog.(*SimpleWatchdog).Start\n\tgithub.com/kumahq/kuma@v0.0.0-20230414081006-9a2812c6b3a4/pkg/util/watchdog/watchdog.go:27\nruntime.goexit\n\truntime/asm_amd64.s:1598"}
```

Why is this happening and what is the solution? Why does this token seem to expire so quickly?

## Cause

When using Vault Policy in {{site.mesh_product_name}} with Hashicorp, there are circumstances in which the ability for {{site.mesh_product_name}} to generate a certificate will fail due to the token expiring or being marked as invalid. An invalid token will lead to an HTTP 403 response from Hashicorp back to {{site.mesh_product_name}}, and the error `permission denied - use token that allows to generate cert` is written to the {{site.mesh_product_name}} logs. The most common situation this occurs in is when the token being used is a `child token` with an expiry of 30 days, for example, but the `parent token` has an expiry of a lower value such as 24 hours. The way Hashicorp has designed their token hierarchy, the parent token overrides the child token when it comes to the TTL / expiry of the token.

## Solution

In this situation, there are two solutions that can be used:

1. Modify the parent token to have a longer expiry TTL than the child token being used. Also ensure the child token is set as `renewable`.
2. Switch to using an `orphan token` instead of a child token. The orphan token concept in Hashicorp means there is no max TTL, and as long as the token is renewed before the TTL, it will live indefinitely.
