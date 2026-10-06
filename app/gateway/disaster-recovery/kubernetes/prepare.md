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

Prepare a recovery set that you can use without accessing the original Kubernetes cluster. The walkthrough for your deployment specifies the files and commands needed to restore it.

## Choose the failure you will test

| Walkthrough | Failure and recovery source |
| --- | --- |
| [KIC](/kubernetes-ingress-controller/disaster-recovery/) | The cluster is lost. Reinstall the saved Helm chart and restore application, routing, and TLS files. |
| [Operator](/operator/dataplanes/disaster-recovery/) | The cluster is lost. Reinstall Operator and reapply the desired Gateway resources so it creates new workloads. |
| [Konnect](/gateway/disaster-recovery/kubernetes/konnect/) | The data plane cluster is lost, but the original Konnect control plane survives. Reconnect replacement data planes and recover entity ownership where needed. |
| [Self-managed hybrid](/gateway/disaster-recovery/kubernetes/hybrid/) | The Gateway cluster and database are lost. Restore PostgreSQL, start the control plane, and reconnect data planes. |

Start with one of these scenarios. A successful cluster replacement does not demonstrate recovery during a Konnect outage or simultaneous loss of the application database.

## Manage configuration as code

On Kubernetes, the recommended approach is to keep all configuration in source control and deploy it through a continuous delivery (CD) pipeline or a GitOps controller such as Argo CD or Flux. Recovery then becomes a deployment: point the pipeline at the replacement cluster and apply the revision that was running before the failure. That revision is your recovery point.

Keep these in the repository:

* Helm chart versions and values files, or the CD application definitions that reference them.
* CRD bundles, including Gateway API CRDs, at the versions you run.
* Gateway API resources, Ingresses, and Kong configuration resources such as KongPlugins.
* Gateway entities for {{site.konnect_short_name}} and self-managed hybrid control planes, as declarative configuration such as decK files, Terraform, or Operator manifests.

Don't commit Secrets in plaintext. Keep certificates, keys, tokens, and licenses in an external secret store and reference them from the repository, for example with External Secrets Operator or Sealed Secrets. The recovery cluster needs access to that store, and any decryption keys must survive the loss of the original cluster.

Configure CD to apply resources in dependency order: CRDs, then controllers, then the configuration that uses them. The walkthroughs use explicit `helm` and `kubectl` commands so that you can check each step. With CD, follow the same sequence by syncing each application against the recovery cluster.

A repository doesn't hold everything. The hybrid walkthrough still needs a database backup for entities created outside the repository and for Keyring material. {{site.konnect_short_name}} assigns entity IDs remotely, so record them. For Operator-managed {{site.konnect_short_name}} entities, pause automated sync during recovery, because a sync can apply manifests before stale ownership is released.

If your configuration isn't in source control yet, the KIC and Operator walkthroughs include a fallback that exports routing resources from the running cluster. Treat it as a stopgap and move that configuration into a repository.

## Assemble the recovery set

Each walkthrough uses a directory under `recovery/`. Assemble it while the original deployment is working, then store it outside that environment.

Include:

* The exact Helm chart archive and saved values. Record Gateway and controller image versions or digests.
* Authored manifests for application Services, routing, Kong configuration, and any required cluster-scoped resources.
* Certificates, private keys, license material, and credentials, or a tested way to retrieve them independently.
* A PostgreSQL backup and Keyring recovery material for the hybrid walkthrough.
* The existing control plane and entity IDs for Konnect.

Preserve application configuration and dependencies as well as gateway configuration. Restoring a Service does not restore the application data behind it.

Protect the recovery set as secret material. Helm values and database backups can contain credentials. Keep private keys and plaintext exports out of an ordinary source repository.

## Prepare a separate recovery target

Provision a replacement cluster with compatible Kubernetes APIs, networking, LoadBalancer support, registry access, and access to the upstream applications. For hybrid recovery, provision a separate PostgreSQL target and its database role.

Configure distinct kubeconfig contexts named by `PRIMARY_CONTEXT` and `RECOVERY_CONTEXT`. The walkthroughs pass the context explicitly. Check both mappings before collecting files or restoring resources.

Keep deployment automation from applying stale configuration during recovery. For Operator-managed Konnect entities, the original controller must be stopped or isolated before a replacement takes ownership.

Document the exact external routing change. For example: replace the CNAME target for `api.example.com` with the new LoadBalancer hostname. Record the current value and the rollback value. Recreating a Kubernetes Service does not preserve its external address.

## Record a baseline and target

Before introducing the failure, save:

| Evidence | Example |
| --- | --- |
| Successful request | Route, request headers, HTTP status, and recognizable response body |
| Rejected request | Missing or invalid credentials produce the expected denial |
| Configuration identity | Git revision, PostgreSQL backup time, or Konnect entity IDs |
| Secret identity | Certificate fingerprint and expiry; secret version without its value |
| Client entry point | DNS record or load balancer target and its current destination |
| Recovery target | Kubernetes contexts, database endpoint, and Konnect control plane ID |

Agree how long traffic may be unavailable, your recovery time objective (RTO), and how much recent state may be lost, your recovery point objective (RPO). Measure traffic recovery and the ability to apply a new configuration change separately.

Then run the chosen walkthrough and complete the [recovery drill](/gateway/disaster-recovery/kubernetes/test/). Use measured results to decide whether the recovery set and prepared capacity meet those targets.
