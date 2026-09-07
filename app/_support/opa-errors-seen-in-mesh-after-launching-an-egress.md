---
title: OPA errors seen in Mesh after launching an Egress
content_type: support
description: OPA isn't supported on Kong Mesh Zone Egress data planes, which causes a `could not receive OPA Config` error; disabling the OPA policy for the Egress data plane resolves it.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: 'Why does Kong Mesh log "could not receive OPA Config" after launching a Zone Egress?'
  a: |
    Kong Mesh's OPA integration doesn't support Zone Egress data planes — only regular sidecars and the built-in gateway. Disable the OPA policy for the Egress data plane to resolve it (historically `--opa-enabled=false` on `kuma-dp`; on current Kong Mesh, scope `MeshOPA` away from the Egress DP, or set `KMESH_OPA_ENABLED=false` there).
---

## Problem

When launching a Mesh Egress, a `could not receive OPA Config` error is seen for the OPA config;

```

2026-09-07T17:34:36.643Z ERROR component terminated with an error {"generationID": 57, "error": "could not receive OPA Config: rpc error: code = Unknown desc = resource \".kong-mesh-egress-85f68d64fd-wxnxm.kong-app-mesh\" not found; create a Dataplane in Kuma CP first or pass it as an argument to kuma-dp", "errorVerbose": "rpc error: code = Unknown desc = resource \".kong-mesh-egress-85f68d64fd-wxnxm.kong-app-mesh\" not found; create a Dataplane in Kuma CP first or pass it as an argument to kuma-dp
could not receive OPA Config
github.com/Kong/kong-mesh/app/kuma-dp/pkg/opa.(*opaConfigurer).Start
\t/home/circleci/kong-mesh/app/kuma-dp/pkg/opa/configurer.go:61
github.com/kumahq/kuma/pkg/core/runtime/component.(*resilientComponent).Start.func1
\t/home/circleci/.go_workspace/pkg/mod/github.com/kumahq/kuma@v0.0.0-20220411101831-653f19867b50/pkg/core/runtime/component/resilient.go:43
runtime.goexit
\t/home/circleci/go/src/runtime/asm_amd64.s:1581"}
```

## Cause

OPA does not work with Egress and the OPA policy should be disabled.

## Solution

To disable this policy, set `--opa-enabled=false` for the Mesh DP

**Update for current Kong Mesh (2.x/current MeshOPA-based releases)**: the specific `--opa-enabled` `kuma-dp` CLI flag shown above reflects the older, pre-policy-API way OPA was wired into a Data Plane proxy. Current Kong Mesh configures OPA via a dedicated `MeshOPA` policy resource instead (embedded in the sidecar itself, gated by the `KMESH_OPA_ENABLED` environment variable, which defaults to `true`), rather than a bare CLI flag on `kuma-dp`. **This review could not fully live-reproduce the original error against a real Kuma/Kong Mesh Egress deployment** (that requires a licensed Kong Mesh control plane, Envoy sidecar injection, and a live Egress data plane, which is outside what this Kong-Gateway-focused stack/cluster can stand up) — the correction below is a source/docs cross-check against `/mesh/policies/meshopa/`, not a fresh live repro.

That said, the underlying limitation this article documents still holds today: `MeshOPA`'s current supported `targetRef` kinds only cover regular sidecars (`Mesh`, `Dataplane` on 2.11+; the older `MeshSubset`/`MeshService`/`MeshServiceSubset` kinds were removed in 2.11) and the built-in gateway (`Mesh`, `MeshGateway`) — Zone Egress/Egress data planes do not appear anywhere in the supported-target list, consistent with this article's original "OPA does not work with Egress" finding. If you hit this error on a current Kong Mesh version, the equivalent fix is to ensure no `MeshOPA` policy is scoped to reach the Egress data plane (or set `KMESH_OPA_ENABLED=false` on the Egress data plane specifically) rather than looking for the old `--opa-enabled` flag, which may no longer exist on current `kuma-dp` builds.
