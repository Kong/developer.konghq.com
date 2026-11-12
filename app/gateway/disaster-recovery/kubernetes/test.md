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

A recovery drill is a planned run of a recovery walkthrough against a separate environment.
Run the drill, then record whether its checks passed.
Test one complete deployment before you expand the drill to a regional failure or to more dependencies.

## Set up the drill

Choose the [{{site.kic_product_name_short}}](/kubernetes-ingress-controller/disaster-recovery/), [{{site.operator_product_name}}](/operator/dataplanes/disaster-recovery/), [{{site.konnect_short_name}}](/gateway/disaster-recovery/kubernetes/konnect/), or [hybrid](/gateway/disaster-recovery/kubernetes/hybrid/) walkthrough, then prepare the drill:

1. Create the starting deployment that the walkthrough describes, and make sure that its baseline request succeeds.
1. Assemble the recovery files for the walkthrough, and move them to storage that you can reach without the original cluster.
1. Record the exact versions of Kubernetes, the Helm chart, {{site.base_gateway}}, and the controller.
1. Provision a separate, empty recovery cluster. For hybrid mode, also provision a separate PostgreSQL instance.
1. Assign an owner who can stop the drill and restore the original traffic path.

For a first drill, use a dedicated test hostname and control plane.
A drill that changes shared {{site.konnect_short_name}} entities or production DNS can affect the original deployment.

## Make the original environment unavailable to the recovery procedure

Record the failure time.
Then restore using only the saved recovery set and the replacement cluster.
After this point, don't retrieve a missing Secret, chart version, or manifest from the original cluster.
If you need one, record it as a failed preparation check.

For a first rehearsal, keep the original environment intact as a rollback path, but don't use it in the restore.
This rehearsal tests that you can rebuild from the saved material.
It doesn't measure a regional outage or automatic failure detection.

For {{site.operator_product_name}}-managed {{site.konnect_short_name}} entities, stop or isolate the original entity controller before you change ownership.
Don't simulate cluster loss by deleting the resources that the controller manages.
Deleting them can remove the remote entities that the walkthrough expects to survive.

## Check the result for your deployment

Each walkthrough passes when you see the following result:

{% table %}
columns:
  - title: Walkthrough
    key: walkthrough
  - title: Required result
    key: result
rows:
  - walkthrough: "{{site.kic_product_name_short}}"
    result: "The replacement serves the saved Ingress over HTTPS with the restored certificate. A new route path also works."
  - walkthrough: "{{site.operator_product_name}}"
    result: "The Gateway becomes programmed, the new workloads serve the saved HTTPRoute, and a route update reaches them."
  - walkthrough: "{{site.konnect_short_name}}"
    result: "New data planes connect to the original control plane. The IDs of the adopted Gateway Service and Route don't change. No duplicate entities appear."
  - walkthrough: Hybrid
    result: "PostgreSQL restores without errors. The saved entity IDs and configuration are present, and data planes receive them. If Keyring is enabled, encrypted credentials work."
{% endtable %}

Send two requests after the routing change: one to the direct address, and one through the normal client hostname.
A successful direct request doesn't show that DNS or load balancer failover works.

Repeat the baseline authentication checks.
Requests with valid credentials must succeed.
Requests with missing or invalid credentials must still fail with the expected status.
Record the response that you get, and don't count every HTTP response as a success.

Each walkthrough adds and removes a temporary route path to check that configuration updates work.
Complete that step, then save the final desired configuration in the managed repository.
The path must fail before the change and after you remove it.
If an existing route already matches the path, the check doesn't test the update.

## Measure recovery time and data loss

Record these timestamps separately:

* The failure is introduced or declared.
* You start the recovery.
* An application request succeeds through the restored client entry point.
* A new configuration change applies successfully.

Measure the recovery time from the failure time, including the time to detect the failure and decide to recover.
Compare it with your [recovery time objective (RTO)](/gateway/disaster-recovery/kubernetes/prepare/#record-a-baseline-and-target).
If you only declared the failure during a rehearsal, state that limitation in the result.

To measure data loss against your recovery point objective (RPO), compare the latest change in the recovered state with the original history.
In the hybrid walkthrough, make a known test change after you take the backup, then make sure that the change is absent after the restore.
This test shows the actual recovery point, instead of assuming it from a successful backup job.

In a {{site.konnect_short_name}} recovery, inspect the surviving control plane before you restore an export.
Reconnected data planes use the current configuration of the control plane, so don't revert it to an older backup.

## Complete failback

Failback returns traffic to the original environment after a recovery:

1. Save any accepted configuration changes that you made in the recovery environment.
1. Rebuild or synchronize the original environment from the state that's now authoritative. For hybrid mode, keep one authoritative database writer.
1. Test the original environment through its own address.
1. Change the test hostname or load balancer target back, and repeat the baseline requests.
1. Make sure that backups and monitoring work in the final active environment.

For {{site.operator_product_name}}-managed {{site.konnect_short_name}} entities, keep one controller responsible for each entity.
You can return traffic to the original data planes without returning entity ownership to the original {{site.operator_product_name}}.

## Record the results

Complete this record for each drill.
Don't put credentials or private keys in the record.

{% table %}
columns:
  - title: Field
    key: field
  - title: Record
    key: record
rows:
  - field: Scenario
    record: Walkthrough, simulated failure, and what the drill didn't test
  - field: Versions
    record: Kubernetes, chart, {{site.base_gateway}}, {{site.kic_product_name_short}} or {{site.operator_product_name}}, and PostgreSQL where used
  - field: Recovery source
    record: Manifest revision, archive filenames, backup time, and secret versions
  - field: Identity checks
    record: Expected and observed control plane, Gateway Service, and Route IDs
  - field: Request checks
    record: Direct and client-hostname responses, for both authorized and rejected requests
  - field: Configuration check
    record: Temporary route change, and confirmation that you removed it
  - field: Timeline
    record: Failure, start of recovery, traffic recovery, and configuration recovery
  - field: Data loss
    record: Known changes that are absent from the recovered state
  - field: Failback
    record: Final traffic destination, and the authoritative database or controller
  - field: Gaps
    record: Failed step, observed error, required correction, and retest result
{% endtable %}

A failed step is part of the result.
Update the walkthrough or the recovery set, and repeat the drill before you rely on it during an incident.
