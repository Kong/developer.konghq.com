---
title: "Test disaster recovery on Kubernetes"
description: "Run recovery drills, validate traffic and configuration management, measure RTO and RPO, and record failback results for Kong on Kubernetes."
content_type: reference
layout: reference
breadcrumbs:
  - /gateway/
  - /gateway/disaster-recovery/kubernetes/
products:
  - gateway
  - kic
  - operator
works_on:
  - on-prem
  - konnect
tags:
  - kubernetes
  - restore
  - failover
related_resources:
  - text: Choose a recovery guide
    url: /gateway/disaster-recovery/kubernetes/
  - text: Prepare for disaster recovery
    url: /gateway/disaster-recovery/kubernetes/prepare/
---

Run the recovery walkthrough against a separate environment, then record whether its checks passed. Test one complete deployment before expanding the exercise to regional failure or additional dependencies.

## Set up the drill

Choose the [KIC](/kubernetes-ingress-controller/disaster-recovery/), [Operator](/operator/dataplanes/disaster-recovery/), [Konnect](/gateway/disaster-recovery/kubernetes/konnect/), or [hybrid](/gateway/disaster-recovery/kubernetes/hybrid/) walkthrough.

1. Create the stated starting deployment and confirm its baseline request succeeds.
1. Assemble the walkthrough's recovery files and move them to storage accessible without the original cluster.
1. Record the exact Kubernetes, chart, Gateway, and controller versions.
1. Provision a separate empty recovery cluster and, for hybrid mode, a separate PostgreSQL instance.
1. Assign an owner who can stop the drill and restore the original traffic path.

Use a dedicated test hostname and control plane for an initial drill. A recovery exercise that changes shared Konnect entities or production DNS can affect the original deployment.

## Make the original environment unavailable to the recovery procedure

Record the failure time, then perform the restore using only the saved recovery set and the replacement cluster. Do not retrieve a missing Secret, chart version, or manifest from the original cluster after this point. Record each such dependency as a failed preparation check.

For a first rehearsal, keep the original environment intact as a rollback path but exclude it from the restore. This rehearses rebuilding from the saved material; it does not measure an actual regional outage or automatic failure detection.

For Operator-managed Konnect entities, stop or isolate the original entity controller before changing ownership. Do not simulate cluster loss by deleting its managed resources: deletion can remove the remote entities that the walkthrough expects to survive.

## Check the result for your deployment

| Walkthrough | Required result |
| --- | --- |
| KIC | The replacement serves the saved Ingress through HTTPS using the restored certificate; a new route path also works. |
| Operator | The Gateway becomes programmed, newly created workloads serve the saved HTTPRoute, and a route update reaches them. |
| Konnect | New data planes connect to the original control plane; adopted Service and Route IDs remain unchanged; no duplicate entities appear. |
| Hybrid | PostgreSQL restores without errors; saved entity IDs and configuration are present; data planes receive them; encrypted credentials work if Keyring is enabled. |

Perform both the direct-address request and the request through the normal client hostname after the routing change. A successful direct request does not demonstrate DNS or load balancer failover.

Repeat the baseline authentication checks. Valid credentials should succeed, and missing or invalid credentials should still fail with the expected status. Record the observed response rather than treating any HTTP response as success.

Each walkthrough adds and removes a temporary route path. Complete that step to verify configuration updates, then save the final desired configuration in the managed repository. The path must fail before the change and after its removal; a path that an existing route already matches proves nothing.

## Measure recovery time and data loss

Record these timestamps separately:

* Failure introduced or declared.
* Recovery invoked.
* Successful application request through the restored client entry point.
* Successful application of a new configuration change.

Measure RTO from the failure time, including detection and decision time. For a rehearsal where the failure is only declared, identify that limitation in the result.

For RPO, compare the latest change present in the recovered state with the original history. In the hybrid walkthrough, make a known test change after taking the backup, then confirm it is absent after restore. That demonstrates the recovery point rather than inferring it from a successful backup job.

In Konnect recovery, inspect the surviving control plane before restoring an export. Reconnecting data planes should use its current configuration, not revert it to an older backup.

## Complete failback

1. Save any accepted configuration changes made in the recovery environment.
1. Rebuild or synchronize the original environment from the now-authoritative state. For hybrid mode, keep one authoritative database writer.
1. Test the original environment through its own address.
1. Change the test hostname or load balancer target back and repeat the baseline requests.
1. Confirm that backups and monitoring operate in the final active environment.

For Operator-managed Konnect entities, leave one controller responsible for each entity. Returning traffic to the original data planes does not require returning entity ownership to the original operator.

## Record the results

Complete this record for each drill. Do not put credentials or private keys in it.

| Field | Record |
| --- | --- |
| Scenario | Walkthrough, simulated failure, and what the drill did not test |
| Versions | Kubernetes, chart, Gateway, KIC or Operator, and PostgreSQL where used |
| Recovery source | Manifest revision, archive filenames, backup time, and secret versions |
| Identity checks | Expected and observed control plane, Service, and Route IDs |
| Request checks | Direct and client-hostname responses; authorized and rejected requests |
| Configuration check | Temporary route change and confirmation it was removed |
| Timeline | Failure, invocation, traffic recovery, and configuration recovery |
| Data loss | Known changes absent from the recovered state |
| Failback | Final traffic destination and authoritative database or controller |
| Gaps | Failed step, observed error, required correction, and retest result |

A failed step is part of the result. Update the walkthrough or recovery set and repeat the drill before relying on it for an incident.
