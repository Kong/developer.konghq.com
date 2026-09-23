# Kubernetes disaster recovery documentation plan

Status: Revised as concrete recovery walkthroughs after review. No recovery scenario has been lab-tested yet; the author will run the drills. Front matter, internal link destinations, shell syntax, and YAML examples have static checks only. Visual review remains outstanding. This file is an editorial plan, not customer recovery instructions.

## Current drafting decisions and test gates

The original page briefs are retained as planning history. The implemented recovery pages now narrow the initial scenarios to make them testable:

* **KIC:** Restore the `kong/ingress` Helm release, an echo application, an Ingress, and its TLS certificate into an empty cluster. Test HTTPS with the original hostname and CA, then add and remove a route path. Verify the controller can become available before gateway configuration is restored.
* **Operator:** Restore the Operator chart and authored GatewayConfiguration, GatewayClass, Gateway, application, and HTTPRoute files. Verify the operator generates new workloads, programs the Gateway, serves the route, and processes a route change. The initial example uses HTTP and a chart-managed CA; TLS, authentication, and external CA scenarios require additional drills.
* **Konnect:** Restore Helm-managed data planes against a surviving hybrid control plane. Separately recover Operator-managed Service and Route ownership by recorded IDs. Operator's `adoptService` and `adoptKongRoute` implementations reject a different `k8s-uid` tag. The draft therefore includes a manual, single-entity stale-tag update after isolating the old controller. Test this entire sequence on the selected release, including retained tags, matching, subsequent reconciliation, original IDs, and duplicate prevention, before publication. Do not present it as an already validated DR procedure.
* **Hybrid:** Restore a PostgreSQL custom-format dump into an empty database owned by the original role. Reinstall the same Gateway version with migration jobs disabled. Verify the saved chart honors `migrations.init`, `preUpgrade`, and `postUpgrade`, and test both ordinary and Keyring-enabled restores. Confirm the private Admin API is reachable at the documented point in the sequence.

For each drill, record the exact chart and image versions, supply every file named in the recovery set, and capture the observed output at each checkpoint. Fix the walkthrough rather than relying on unstated manual intervention. PostgreSQL restore commands were checked against its official reference; chart migration switches and naming were checked against Kong's chart source. Neither check replaces runtime testing.

The first Konnect walkthrough does not cover KIC-managed Konnect configuration, Operator-generated Konnect Gateways, cold start during a Konnect outage, or cross-geo failover. Those are follow-on scenarios, not claims established by the initial drill. Shared preparation and test pages have been shortened to support these walkthroughs.

Scope agreed on September 18, 2026: Kong Gateway on customer-managed Kubernetes, including Kong Ingress Controller (KIC), Kong Operator, and Konnect-managed control planes with customer-managed data planes. A dedicated Kong Mesh recovery guide is outside the first release.

Source draft: `/Users/justin.davies/Documents/GitHub/kong-operator/docs/kubernetes-disaster-recovery.md`.

## Recommended structure

Create seven pages: one short landing page, one shared preparation reference, four deployment-specific recovery guides, and one drill and validation reference. Most readers use four pages: choose their deployment, prepare, recover, and test. They do not need to read every recovery guide.

Use a linked collection rather than a numbered tutorial series. The recovery guides are alternative paths, not sequential steps. The site's `series.id` and `series.position` mechanism is useful for sequential how-tos, but would imply that a customer must work through unrelated deployment models here.

Keep the guides independently usable. Each recovery page states its assumptions, required recovery material, ordered actions, and success criteria. Link to preparation for deeper planning guidance rather than making readers reconstruct an incident procedure across multiple pages. This follows the contributing guide's “Every page is page one” principle.

| Page | Reader question | Proposed URL | Format |
| --- | --- | --- | --- |
| Disaster recovery for Kong Gateway on Kubernetes | Which recovery guide applies to my deployment? | `/gateway/disaster-recovery/kubernetes/` | YAML landing page |
| Prepare for disaster recovery on Kubernetes | What must I configure, preserve, and test before a failure? | `/gateway/disaster-recovery/kubernetes/prepare/` | Reference |
| Recover Konnect-managed data planes on Kubernetes | How do I recover my data planes and their configuration management? | `/gateway/disaster-recovery/kubernetes/konnect/` | Reference with recovery procedures |
| Recover a self-managed hybrid deployment on Kubernetes | How do I recover the control plane, database, and data planes? | `/gateway/disaster-recovery/kubernetes/hybrid/` | Reference with recovery procedures |
| Recover a DB-less deployment managed by KIC | How do I rebuild routing from Kubernetes resources? | `/kubernetes-ingress-controller/disaster-recovery/` | Reference with recovery procedures |
| Recover a Gateway deployment managed by Kong Operator | How do I recover the operator, Gateway resources, and data planes? | `/operator/dataplanes/disaster-recovery/` | Reference with recovery procedures |
| Test disaster recovery on Kubernetes | How do I prove recovery and safely return to normal operation? | `/gateway/disaster-recovery/kubernetes/test/` | Reference with drill procedure and evidence template |

### Deployment selection

The landing page asks where Gateway configuration is managed:

* Konnect: use the Konnect guide, including its Operator-managed resources path when applicable.
* A self-managed hybrid control plane backed by PostgreSQL: use the hybrid guide.
* Standalone KIC reading Kubernetes routing resources: use the KIC guide.
* An embedded controller in Kong Operator managing Gateway deployments: use the Operator guide.

Operator is a management layer that also integrates with Konnect. Do not describe “Operator” and “Konnect” as mutually exclusive deployment topologies. Likewise, DB-less data plane operation alone does not identify the source of configuration: Konnect and self-managed hybrid data planes also operate without a local Kong database.

Traditional database-backed Gateway, manually managed DB-less configuration without KIC or Operator, Kong-managed cloud data planes, and recovery of the entire Konnect organization are outside this release. Link to applicable existing documentation and state these boundaries explicitly.

## Page briefs

### 1. Disaster recovery for Kong Gateway on Kubernetes

Target length: 300–500 words. No shell commands.

Include a short explanation of what the bundle covers and a deployment selection table linking directly to the four recovery guides. Add separate links for preparing a recovery environment and running a drill.

Explain the distinction between high availability, disaster recovery, and restoring configuration management. A surviving gateway may continue serving traffic while configuration updates are unavailable. A newly created gateway still needs a configuration source, credentials, and working dependencies.

Use one compact architecture diagram only if it clarifies customer-managed components and Konnect-managed components. Avoid a large multi-provider reference architecture.

Source material: introduction, state inventory, and the introduction to the topology runbooks.

### 2. Prepare for disaster recovery on Kubernetes

Target length: 1,000–1,400 words. Primarily prose and two useful tables, with no installation tutorial or bulk automation script.

Proposed sections:

1. **Define recovery objectives.** Define recovery time objective (RTO) and recovery point objective (RPO). Record traffic recovery and configuration management recovery separately. Identify which state each RPO measures. Include a named recovery owner and the conditions for invoking the plan.
2. **Inventory recovery material.** Use a table with component, authoritative source, backup or rebuild mechanism, recovery owner, and last successful test. Cover routing resources, cluster-scoped resources, Helm values, versions, images, plugin code, certificates, secrets, keyring recovery material, PostgreSQL where applicable, and external entity identities.
3. **Choose recovery capacity.** Explain backup and restore, pilot light, warm standby, and active-active as choices. Describe the tradeoffs without assigning universal recovery times or recommending active-active for every customer. Include surviving capacity, quotas, application availability, and external dependencies.
4. **Prepare the recovery environment.** Cover infrastructure as code, Git and artifact availability, access to secret stores and decryption keys, and the dependency order for bootstrap. Restore persistent state where rebuilding cannot reproduce it. Distinguish surviving cache from a backup.
5. **Prepare traffic failover.** Identify who manages DNS and the global and regional load balancers, how a healthy replacement becomes eligible, how existing connections are handled, and how traffic is returned. Kubernetes Service recreation can change addresses. Readiness is one signal; validate representative application paths and required dependencies too.
6. **Protect against configuration loss.** Keep versioned recovery points, including protection against deletion or corruption that replication can propagate. Address GitOps pruning and the consequences of deleting resources that manage remote Konnect entities.

Output: a completed recovery inventory and a documented recovery strategy for the customer's deployment.

Source material: draft sections 1–10, condensed. Link to established product features for detailed configuration. Keep cloud provider comparisons, database operator internals, and long GitOps examples out of this shared page.

### 3. Recover Konnect-managed data planes on Kubernetes

Target length: 900–1,300 words, excluding essential examples.

Scope: Konnect-managed Gateway control planes with customer-managed Kubernetes data planes. Distinguish a cluster outage from a Konnect outage. Do not promise cross-geo control plane failover or recovery of unrelated Konnect applications.

Proposed sections:

* **Before recovery:** recorded control plane ID and geo, pinned deployment versions, manifests and images, client certificates, authentication material, and a validated configuration source.
* **When Konnect is unreachable:** check surviving traffic, identify frozen configuration management, and distinguish an existing pod with usable cached configuration from a replacement pod without it. Link to the supported data plane resilience procedure for preconfigured fallback storage.
* **Recover after cluster loss:** restore access and prerequisites, redeploy data planes, reconnect to the intended surviving control plane, verify configuration and application behavior, and restore traffic through the customer's prepared traffic mechanism.
* **If Operator manages Konnect resources:** before recreating resources or enabling reconciliation, verify the surviving control plane and entity identities. Explain the difference between an abrupt cluster loss and an orderly teardown that runs deletion finalizers. Reference the existing mirror and adoption guides, but include the recovery order and identity checks here. Verify adoption support per resource and Operator version rather than suggesting all entities share one mechanism.
* **Return to normal operation:** restore capacity, confirm configuration synchronization, reconcile the source of truth deliberately, and test the intended traffic distribution.

For the Operator path, recovery must verify entity IDs and references, not just that a route responds. A recovery that creates duplicate entities is not successful. An inventory helps preserve identities, but do not claim that an inventory is the only possible way to discover surviving remote entities.

Source material: runbook A and the Konnect ownership and adoption portions of runbook D.

### 4. Recover a self-managed hybrid deployment on Kubernetes

Target length: 1,000–1,400 words, excluding essential examples.

Scope: self-managed hybrid control planes backed by PostgreSQL and Kubernetes-hosted data planes. State that the database recovery procedure depends on the customer's tested database platform.

Proposed sections:

* **Before recovery:** database recovery point, compatible Gateway and database versions, control plane settings, cluster mTLS material, license, custom plugins, and keyring recovery material if enabled.
* **Determine what failed:** distinguish the control plane process, database, gateway cluster, and region. Preserve healthy data planes where possible.
* **Restore service:** use the prepared traffic mechanism to route to validated surviving capacity. Traffic recovery need not wait for control plane recovery when data planes already have usable configuration and upstream dependencies remain healthy.
* **Recover configuration management:** isolate the failed writer before database promotion, restore or promote PostgreSQL using the platform-specific procedure, restore control plane connectivity, and recover keyring access in the correct tested order.
* **Validate and reconcile:** check encrypted configuration, entity coverage, data plane synchronization, application behavior, and drift between the restored database and declarative files. Review a diff before a destructive sync.
* **Fail back:** prevent two active database writers, synchronize the recovered environment, verify it independently, shift traffic deliberately, and confirm backup protection has resumed.

Link to the existing Gateway backup and restore and keyring pages. Do not duplicate a partial PostgreSQL administration guide or recommend a database product without checking Gateway support and testing the selected configuration.

Source material: runbook B and the relevant portions of sections 2, 9, and 10.

### 5. Recover a DB-less deployment managed by KIC

Target length: 700–1,000 words, excluding essential examples.

Scope: standalone KIC that configures DB-less Gateway from Kubernetes resources. Include Ingress and Gateway API routing in the inventory without making customers follow two separate recovery procedures unless the tested steps require it.

Proposed sections:

* **Before recovery:** manifests, CRDs, Helm values, pinned images, license material, certificate and credential Secrets, custom plugins, and application Services and endpoints.
* **Recover a controller outage:** explain that existing gateways retain configuration while endpoint information can become stale as application pods change. Restore reconciliation and validate endpoint updates.
* **Rebuild after cluster loss:** restore prerequisites and Secrets, install compatible CRDs and KIC, restore routing and application dependencies in order, and verify the resulting Gateway configuration.
* **Restore traffic and fail back:** verify route behavior, authentication and authorization, TLS, plugins, and capacity before traffic cutover. Account for changed Service addresses and reconcile GitOps ownership.

Link to last known good configuration and fallback configuration as preparation features. Neither should be presented as a complete cluster backup. Keep a single-resource example where an example is necessary; avoid loops over the entire customer estate.

Source material: runbook C and the applicable bootstrap and secret inventory from Part 1.

### 6. Recover a Gateway deployment managed by Kong Operator

Target length: 800–1,100 words, excluding essential examples.

Scope: the self-hosted, embedded-controller deployment model supported by the selected Operator versions. Direct customers whose data planes use a Konnect control plane to the Konnect guide.

Proposed sections:

* **Before recovery:** Operator and CRD versions, Helm values, GatewayClass and GatewayConfiguration resources, Gateways and routes, authentication material, operator certificates, license material, and plugin images.
* **Recover an Operator outage:** explain what stops reconciling and what continues serving. Tie controller behavior to the documented version and deployment mode.
* **Rebuild after cluster loss:** restore prerequisite controllers and Secrets, install compatible Operator CRDs and the operator, apply the supported desired-state resources in dependency order, and let the operator recreate generated workloads.
* **Validate the replacement:** verify conditions and application traffic, TLS and authentication, expected generated Services, and capacity. Avoid treating generated status and owner references as portable desired state without a supported restore procedure.
* **Restore traffic and fail back:** use the prepared traffic mechanism and verify that GitOps and Operator ownership have resumed as intended.

Reuse the existing architecture, GatewayConfiguration, PodDisruptionBudget, and custom plugin installation documentation. Move blue/green rollout guidance into related resources unless it is required by the chosen recovery procedure.

Source material: the local Gateway deployment parts of runbook D, with the Kubernetes recovery inventory from runbook C repeated where needed for an independently usable guide.

### 7. Test disaster recovery on Kubernetes

Target length: 700–1,000 words. One small drill matrix and a reusable evidence table, not a verification shell script.

Proposed sections:

1. **Choose a failure scenario.** Include controller loss, loss of all gateway pods, cluster or region loss, configuration corruption, and unavailable bootstrap dependencies. Include keyring and remote identity tests only for applicable deployments.
2. **Define the drill boundary.** Name the owner, test environment, start and stop conditions, expected behavior, and rollback or failback procedure.
3. **Run the deployment-specific recovery procedure.** Measure from failure or invocation using a documented start point, through traffic validation and configuration management recovery. Record these as separate milestones.
4. **Validate recovery.** Check representative business paths, TLS, authentication and authorization, plugins, upstream reachability, configuration freshness, and restored external identities. Test a replacement data plane with no usable cache where that is in scope.
5. **Complete failback and record results.** Reconcile recovered state and writers before restoring normal traffic distribution. Record measured recovery time, recovered state age or lost changes, failures, remediation owners, and retest results.

Suggested evidence fields: scenario, date, versions, participants, target RTO/RPO, last recoverable change, failure timestamp, traffic recovery timestamp, configuration recovery timestamp, validation evidence, failback result, and remediation tracking.

Treat the evidence as operational records customers can use in their own compliance process. Do not claim the guide satisfies SOC 2 or ISO requirements, rank evidence on an auditor's behalf, or embed contractual availability percentages.

Source material: draft sections 11–12. Add failback, data-loss measurement, and tests of recovery dependencies.

## Source material to reuse, condense, or defer

| Draft material | Treatment |
| --- | --- |
| Rebuild-first thesis | Recast as a scoped recommendation to rebuild reproducible infrastructure and restore non-reproducible state. Do not suggest backups are unnecessary. |
| State inventory and material outside Git | Make this the preparation page's main practical artifact, with topology-specific items repeated in runbooks. |
| Recovery tier tables | Keep the choices and tradeoffs. Remove invented tier numbering and apparently guaranteed recovery times. |
| PDBs, probes, scheduling, and graceful termination | Summarize preparation requirements and link to existing resilience documentation. Do not turn DR into a second installation guide. |
| Argo CD and Flux deployment examples | Condense into desired-state ownership and bootstrap requirements. Defer provider/tool-specific examples to separately scoped and tested how-tos. |
| Global load balancer comparisons | Replace numeric vendor rankings with factors to measure: detection, capacity, routing convergence, connections, and upstream health. |
| Secrets and database chapters | Preserve the dependency inventory and Kong-specific recovery items. Link to current platform procedures for detailed administration. |
| Four topology runbooks | Use as raw material for four recovery pages, moving remote Konnect ownership into the Konnect path. |
| Drill schedule and audit discussion | Produce one drill guide with an adaptable schedule and evidence template. Keep legal and compliance review notes internal. |
| Claims, sources, and gaps appendix | Keep as an internal evidence register. Put concise supporting links next to customer-facing claims. |
| Mesh, Event Gateway, Dev Portal, Catalog, and whole-organization Konnect recovery | Outside this first release. Link to relevant existing documentation without implying complete DR coverage. |

## Accuracy work before publication

The source is useful research material, but it should not be split and published verbatim. This is a targeted review, not an exhaustive validation of its claims.

| Claim or gap | Required treatment |
| --- | --- |
| Data planes are stateless and serve indefinitely | Distinguish continuity with valid configuration from a pod restart or replacement that loses ephemeral storage. Include configuration freshness, licenses, secrets, plugin dependencies, and upstream availability as applicable. |
| decK cannot cover Workspaces or RBAC roles | The current entity reference describes Workspace support with limitations and support for RBAC roles and endpoint permissions. The backup overview contains broader exclusions. Resolve the documentation discrepancy against the supported decK version and keep the statement that decK is not a complete backup. |
| Export Konnect configuration directly into Git | Treat dumps as potentially sensitive configuration. Define access control and secret handling before recommending storage in a repository. |
| Fallback configuration export belongs to the Konnect control plane | Align with the supported backup-node/exporter architecture in the current outage-management guide. Verify environment variable names, storage backends, minimum versions, permissions, and cold-start behavior. |
| Database alone determines RPO | Define RPO for configuration, credentials, certificates, identities, and any external runtime state separately. Database replication alone does not determine end-to-end application recovery. |
| Git implies zero configuration loss | State when changes become protected and account for uncommitted changes, replication lag, secret rotation, and configuration not managed in Git. |
| Restoring etcd restores all cluster identity | Validate cluster PKI, service account signing keys, encryption configuration, persistent volumes, and external infrastructure separately. Do not imply an etcd snapshot includes files and key material stored outside etcd. |
| DB-less rejects all Admin API writes | Distinguish entity CRUD from supported configuration-loading operations. Scope descriptions to the APIs actually used. |
| Disabling prune disables drift correction | Separate deletion/pruning from update reconciliation and self-healing. Verify behavior for the selected GitOps configuration. |
| Every Konnect resource has identical deletion/adoption behavior | Verify resource kind, Operator version, finalizers, ownership conflicts, mirror semantics, and adoption support. Do not equate a surviving remote resource with a safely adoptable resource. |
| Keyring recovery before starting an API endpoint | Test and document the actual service readiness and recovery order. Reconcile the native database restore sequence with the supported backup method. |
| Static SLA percentages, token lifetimes, CA paths, and cloud timings | Verify current authoritative sources and versions before inclusion. Prefer links for changeable contractual details and measured objectives for recovery claims. |
| Active-active always provides the best default | Make the recommendation conditional on workload dependencies, capacity, consistency, cost, and tested failure behavior. |
| Recovery stops when traffic resumes | Add reconciliation, failback, prevention of concurrent writers, and restoration of backups and monitoring. |

## Kong layout and writing conventions

Use the repository's current style and content guidance:

* US English, active voice, descriptive sentence-case headings, and concise present-tense explanations.
* Use product variables such as `{{site.base_gateway}}`, `{{site.kic_product_name}}`, `{{site.operator_product_name}}`, and `{{site.konnect_short_name}}`.
* Prefer normal prose to info boxes. Reserve warnings for actions that can lose data, delete remote entities, create competing writers, or redirect production traffic.
* Keep one command per code block, with a language identifier. Separate command output and apply `{:.no-copy-code}` to non-copyable output.
* Use short, named-resource examples. Do not add bulk discovery, estate-wide patch loops, or a general verification script.
* Use approved Liquid blocks for entity examples and validation where they fit. Include enough context to understand expected results.
* Use tables for recovery inventories and deployment selection. Use at most one small diagram per recovery guide when it clarifies ownership or dependency order.
* Describe an example's tested versions and prerequisites. Do not imply that one provider-specific command works across all Kubernetes installations.
* If a future how-to depends on a particular third-party configuration, include complete required setup using `app/_includes/prereqs/` where appropriate. General runbooks can refer to a customer's pre-established, tested platform procedures.

These are operational references because the customer already has a deployment and platform recovery procedures. Use `content_type: reference` and `layout: reference`. If we later add a fully reproducible lab, put it in `app/_how-tos/` with `tldr`, `permalink`, complete prerequisites, and final validation. Do not label environment-dependent recovery guidance as a copy-and-paste tutorial.

### Proposed repository changes

New customer content:

* `app/_landing_pages/gateway/disaster-recovery/kubernetes.yaml`
* `app/gateway/disaster-recovery/kubernetes/prepare.md`
* `app/gateway/disaster-recovery/kubernetes/konnect.md`
* `app/gateway/disaster-recovery/kubernetes/hybrid.md`
* `app/kubernetes-ingress-controller/disaster-recovery.md`
* `app/operator/dataplanes/disaster-recovery.md`
* `app/gateway/disaster-recovery/kubernetes/test.md`

Use landing-page `metadata` and `rows`, following the existing Gateway upgrade landing page. Use product-specific breadcrumbs on recovery pages and related-resource links back to the DR landing page and preparation/test pages. Set `products` and `works_on` per page rather than copying all values onto every page. The current schema uses `konnect` as a product slug; use the schema as authority where prose documentation lists an older value.

Navigation changes:

* Add the landing page and shared Gateway recovery pages to an appropriate production/operations section in `app/_indices/gateway.yaml`.
* Add recovery entries in `app/_indices/kic.yaml` and `app/_indices/operator.yaml`.
* Add a Konnect index link to customer-managed data plane recovery where it fits the existing navigation in `app/_indices/konnect.yaml`.
* Add related-resource links from the existing backup/restore, outage-management, KIC availability, and Operator architecture pages. Keep those pages as the canonical feature references.
* Reuse approved tags such as `kubernetes`, `backup`, `restore`, and `failover`. Add a new tag only through the tag schema if needed.
* Do not modify `app/_data/series.yml` for this branching collection.

## Existing documentation to build on

| Existing page | Use in the bundle |
| --- | --- |
| `/gateway/upgrade/backup-and-restore/` | Native and declarative backup scope; reconcile its entity coverage statements with decK's current reference. |
| `/deck/reference/entities/` | Supported entity coverage and limitations. |
| `/gateway/keyring/` | Recovery key preparation and supported recovery mechanism. |
| `/gateway/hybrid-mode/` | Hybrid connectivity, cached configuration, and topology limitations. |
| `/gateway/cp-outage/` | Preparing new data planes for a control plane outage. |
| `/kubernetes-ingress-controller/kic-high-availability/` | KIC availability and controller failure behavior. |
| `/kubernetes-ingress-controller/last-known-good-config/` | Scope and limits of configuration recovery from a running gateway. |
| `/kubernetes-ingress-controller/fallback-configuration/` | Handling invalid configuration without presenting it as a backup strategy. |
| `/operator/reference/architecture/` | Self-hosted and Konnect-hosted control plane models. |
| `/operator/konnect/reconciliation-loop/` | Remote create, update, and deletion behavior. |
| `/operator/konnect/crd/control-planes/mirror/` | Referencing a surviving control plane. |
| `/operator/konnect/crd/adoption/gateway/` | Adopting supported surviving entities and respecting dependencies. |
| `/mesh/disaster-recovery/` | Related reading only; no new Mesh recovery procedure in this release. |

## Delivery and review sequence

1. Resolve the evidence gaps that affect architecture and recovery ordering. Record source, version, and test status for each material claim.
2. Draft the landing and preparation pages, then one recovery page to establish the editorial pattern. Start with KIC because its Kubernetes source of truth makes the recovery boundary clear.
3. Draft the Operator, Konnect, and hybrid pages against their distinct state and ownership requirements. Verify commands and prerequisites for the supported versions before publication.
4. Draft the drill page, including both traffic and configuration recovery, failback, and identity checks.
5. Exercise each complete runbook in an isolated environment. For hybrid, include database and keyring recovery where enabled. For Konnect resources, confirm no unintended deletions or duplicate identities. Keep measured results as test evidence, not universal product guarantees.
6. Have Gateway, KIC, Operator, and Konnect subject-matter reviewers check their relevant sections. Request review of any contractual or compliance statements retained in customer content.
7. Validate front matter, tags, internal links, code syntax, and style. Render the affected pages and check navigation and reading flow before submission.

Completion means a customer can identify the right guide, list the recovery material they must preserve, follow one ordered recovery path, validate both traffic and configuration management, and return to normal operation. Page count alone is not the acceptance criterion.

## References used for this plan

Repository conventions: `app/contributing/style-guide.md`, `app/contributing/index.md`, `docs/front-matter-reference.md`, `docs/update-tag-schema.md`, `app/_data/schemas/frontmatter/`, and `app/_data/series.yml`.

Existing layout example: `app/_landing_pages/gateway/upgrade.yaml`. Product behavior references are listed in the reuse table.

External primary references reviewed for scope and validation planning:

* [AWS disaster recovery options](https://docs.aws.amazon.com/whitepapers/latest/disaster-recovery-workloads-on-aws/disaster-recovery-options-in-the-cloud.html): strategy choices, infrastructure recovery, testing, and the distinction between replication and protection from corruption.
* [Kubernetes etcd operations](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/): etcd recovery is one component of cluster recovery.
* [Kong control plane outage management](https://developer.konghq.com/gateway/cp-outage/): fallback configuration preparation for new data planes.

This plan does not certify the original draft's vendor timing figures, legal interpretations, or recovery commands. Those remain evidence and test tasks before publication.
