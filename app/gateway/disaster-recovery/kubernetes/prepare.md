---
title: "Prepare for disaster recovery on Kubernetes"
description: "Define recovery objectives, protect configuration and secrets, and prepare capacity and traffic failover for Kong Gateway on Kubernetes."
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
  - backup
  - restore
  - failover
related_resources:
  - text: Choose a Kubernetes recovery guide
    url: /gateway/disaster-recovery/kubernetes/
  - text: Test disaster recovery
    url: /gateway/disaster-recovery/kubernetes/test/
  - text: Back up and restore Kong Gateway
    url: /gateway/upgrade/backup-and-restore/
---

A recovery set is the collection of files, secrets, and records that you need to rebuild a {{site.base_gateway}} deployment on Kubernetes.
Prepare a recovery set that you can use without access to the original Kubernetes cluster.
The walkthrough for your deployment lists the files and commands that you need to restore it.

## Choose the failure you will test

Each walkthrough covers one failure and one recovery source:

{% table %}
columns:
  - title: Walkthrough
    key: walkthrough
  - title: Failure and recovery source
    key: failure
rows:
  - walkthrough: "[{{site.kic_product_name_short}}](/kubernetes-ingress-controller/disaster-recovery/)"
    failure: "You lose the cluster. Reinstall the saved Helm chart, then restore the application, routing, and TLS files."
  - walkthrough: "[{{site.operator_product_name}}](/operator/dataplanes/disaster-recovery/)"
    failure: "You lose the cluster. Reinstall {{site.operator_product_name}} and reapply the desired Gateway resources so that it creates new workloads."
  - walkthrough: "[{{site.konnect_short_name}}](/gateway/disaster-recovery/kubernetes/konnect/)"
    failure: "You lose the data plane cluster, but the original {{site.konnect_short_name}} control plane survives. Reconnect replacement data planes and recover entity ownership where needed."
  - walkthrough: "[Self-managed hybrid](/gateway/disaster-recovery/kubernetes/hybrid/)"
    failure: "You lose the {{site.base_gateway}} cluster and its database. Restore PostgreSQL, start the control plane, and reconnect data planes."
{% endtable %}

Start with one of these scenarios.
A successful cluster replacement doesn't show that you can recover during a {{site.konnect_short_name}} outage, or when you also lose the application database.

## Manage configuration as code

We recommend that you keep all Kubernetes configuration in source control and deploy it through a continuous delivery (CD) pipeline or a GitOps controller such as Argo CD or Flux.
With this approach, recovery is a normal deployment: you point the pipeline at the replacement cluster and apply the revision that was running before the failure.
That revision is your recovery point.

Keep these items in the repository:

* Helm chart versions and values files, or the CD application definitions that reference them.
* CRD bundles, including Gateway API CRDs, at the versions you run.
* Gateway API resources, Ingresses, and Kong configuration resources such as KongPlugins.
* Gateway entities for {{site.konnect_short_name}} and self-managed hybrid control planes, as declarative configuration such as decK files, Terraform, or {{site.operator_product_name}} manifests.

Don't commit Secrets in plaintext.
Keep certificates, keys, tokens, and licenses in an external secret store, and reference them from the repository with a tool such as External Secrets Operator or Sealed Secrets.
The recovery cluster needs access to that store.
Any decryption keys must survive the loss of the original cluster.

Configure CD to apply resources in dependency order: CRDs first, then controllers, then the configuration that uses them.
The walkthroughs use explicit `helm` and `kubectl` commands so that you can check each step.
If you use CD, follow the same sequence and sync each application against the recovery cluster.

A repository doesn't hold everything:

* The hybrid walkthrough still needs a database backup for entities created outside the repository, and for Keyring material.
* {{site.konnect_short_name}} assigns entity IDs, so record them.
* For {{site.operator_product_name}}-managed {{site.konnect_short_name}} entities, pause automated sync during recovery. A sync can apply manifests before you release stale ownership.

If your configuration isn't in source control yet, the {{site.kic_product_name_short}} and {{site.operator_product_name}} walkthroughs include a fallback that exports routing resources from the running cluster.
Use the export only as a temporary measure, and move that configuration into a repository.

## Assemble the recovery set

Each walkthrough uses a directory under `recovery/`.
Assemble the recovery set while the original deployment works, then store it outside that environment.

Include the following items:

* The exact Helm chart archive and the saved values. Record the image versions or digests for {{site.base_gateway}} and the controller.
* The manifests you wrote for application Services, routing, Kong configuration, and any required cluster-scoped resources.
* Certificates, private keys, license material, and credentials, or a tested way to retrieve them independently.
* For the hybrid walkthrough, a PostgreSQL backup and the Keyring recovery material.
* For the {{site.konnect_short_name}} walkthrough, the existing control plane and entity IDs.

Preserve application configuration and dependencies, not only the gateway configuration.
Restoring a Service doesn't restore the application data behind it.

Protect the recovery set as secret material, because Helm values and database backups can contain credentials.
Keep private keys and plaintext exports out of an ordinary source repository.

## Prepare a separate recovery target

Provision a replacement cluster with the following:

* Compatible Kubernetes APIs and networking
* LoadBalancer support
* Access to the container registries
* Access to the upstream applications

For hybrid recovery, also provision a separate PostgreSQL target and its database role.

Configure two distinct kubeconfig contexts, and store their names in `PRIMARY_CONTEXT` and `RECOVERY_CONTEXT`.
The walkthroughs pass the context explicitly in each command.
Make sure that each variable points to the correct cluster before you collect files or restore resources.

Stop deployment automation from applying stale configuration during recovery.
For {{site.operator_product_name}}-managed {{site.konnect_short_name}} entities, stop or isolate the original controller before a replacement controller takes ownership.

Document the exact external routing change, and record the current value and the rollback value.
For example, the change can replace the CNAME target for `api.example.com` with the new LoadBalancer hostname.
When you recreate a Kubernetes Service, it gets a new external address.

## Record a baseline and target

Before you introduce the failure, save the following evidence:

{% table %}
columns:
  - title: Evidence
    key: evidence
  - title: Example
    key: example
rows:
  - evidence: Successful request
    example: Route, request headers, HTTP status, and a recognizable response body
  - evidence: Rejected request
    example: The expected denial for missing or invalid credentials
  - evidence: Configuration identity
    example: Git revision, PostgreSQL backup time, or {{site.konnect_short_name}} entity IDs
  - evidence: Secret identity
    example: Certificate fingerprint and expiry, and the secret version without its value
  - evidence: Client entry point
    example: DNS record or load balancer target, and its current destination
  - evidence: Recovery target
    example: Kubernetes contexts, database endpoint, and {{site.konnect_short_name}} control plane ID
{% endtable %}

Agree on two targets before the drill:

* **Recovery time objective (RTO)**: How long traffic can be unavailable.
* **Recovery point objective (RPO)**: How much recent configuration you can lose.

Measure traffic recovery separately from the ability to apply a new configuration change.

Then run the walkthrough for your deployment and complete the [recovery drill](/gateway/disaster-recovery/kubernetes/test/).
Use the measured results to decide whether the recovery set and the prepared capacity meet your targets.
