---
title: "Blue-green upgrade for {{site.base_gateway}}"
description: Learn how to perform a blue-green upgrade for {{site.base_gateway}}.
content_type: reference
layout: reference
breadcrumbs:
    - /gateway/
products:
    - gateway

works_on:
    - on-prem

tags:
    - upgrade
    - versioning
    - blue-green
search_aliases:
  - blue green 
  - blue green upgrade

related_resources:
  - text: "Upgrading {{site.base_gateway}}"
    url: /gateway/upgrade/
  - text: "Backing up and restoring {{site.base_gateway}}"
    url: /gateway/upgrade/backup-and-restore/
  - text: "In-place upgrade"
    url: /gateway/upgrade/in-place/
  - text: "{{site.base_gateway}} breaking changes"
    url: /gateway/breaking-changes/
  - text: "Dual-cluster upgrade"
    url: /gateway/upgrade/dual-cluster/
  - text: Rolling upgrade
    url: /gateway/upgrade/rolling/
  - text: "3.4 to 3.10 LTS upgrade"
    url: /gateway/upgrade/lts-upgrade-34-310/
  - text: "2.8 to 3.4 LTS upgrade"
    url: /gateway/upgrade/lts-upgrade-28-34/
---

The blue-green upgrade strategy is a {{site.base_gateway}} upgrade option used primarily for traditional mode deployments 
and for Control Planes in hybrid mode. 

This guide refers to the old version as cluster X and the new version as cluster Y.

Blue-green upgrades are derived from the [in-place upgrade strategy](/gateway/upgrade/in-place/). 
This upgrade strategy benefits from the fact that `kong migrations up` leaves the database in a state 
where it can serve requests by either the current cluster X or the new cluster Y. 
The compatibility of the database with cluster X is only lost when `kong migrations finish` is executed.

This is a more advanced strategy than the [dual-cluster upgrade](/gateway/upgrade/dual-cluster/) in that there is no need to deploy a new database. 
It still supports gradually diverting traffic from the current cluster X to the new cluster Y, shown in the following diagram. 
Furthermore, runtime metrics (for example, [Rate Limiting Advanced plugin](/plugins/rate-limiting-advanced/) counters) are sent to the same database. 
Metrics are continuously collected from both clusters during the upgrade process.

{% mermaid %}
flowchart TD
    DB[(Database)]
    CPX(Current 
    {{site.base_gateway}} X)
    Admin(No admin 
    write operations)
    Admin2(No admin 
    write operations)
    CPY(New 
    {{site.base_gateway}} Y)
    LB(Load balancer)
    API(API requests)

    API --> LB & LB & LB & LB
    Admin2 -."X".- CPX
    LB -.90%.-> CPX
    LB --10%--> CPY
    Admin -."X".- CPY
    CPX -.-> DB
    CPY --"kong migrations up \n (NO kong migrations finish)"--> DB

    style CPX stroke-dasharray:3
    style Admin fill:none!important,stroke:none!important,color:#d44324!important
    style Admin2 fill:none!important,stroke:none!important,color:#d44324!important
    linkStyle 4,7 stroke:#d44324!important,color:#d44324!important
    linkStyle 3,6,9 stroke:#b6d7a8!important
{% endmermaid %}

> _Figure 1: The diagram shows a {{site.base_gateway}} upgrade using the blue-green strategy._
_The new {{site.base_gateway}} cluster Y is deployed alongside the current {{site.base_gateway}} cluster X. Both clusters use the same database._
_Traffic is gradually switched over to the new deployment, until all API traffic is migrated._

Compared to dual-cluster and in-place upgrades, blue-green upgrades consume less resources since there is no extra database required, 
and still allow for no business downtime.

{:.warning}
> **Important**: Support from Kong for upgrades using this strategy is limited.
Though blue-green upgrades are supported, it is nearly impossible to fully cover all migration tests, because we have to cover all 
combinations, given the number of {{site.base_gateway}} versions, upgrade strategies, features adopted, and deployment modes.
> If you must use this strategy, only use it to upgrade between patch versions.
> <br><br>
> In traditional mode, blue-green upgrades are available starting in 2.8.2.x.
If you have a {{site.base_gateway}} 2.8.x version earlier than 2.8.2.x, upgrade to at least 2.8.2.0 before starting any upgrades to the 3.x series.

## Upgrade using the blue-green method

{:.info}
> The following steps are intended as a guideline.
The exact execution of these steps will vary depending on your environment. 

### Prerequisites

* Review the [general upgrade guide](/gateway/upgrade/) to prepare for the upgrade and review your options.
* You have a traditional deployment or you need to upgrade the Control Planes (CPs) in a hybrid mode deployment.
* You have {{site.base_gateway}} 2.8.2.x or later.
* You can't perform [dual-cluster upgrades](/gateway/upgrade/dual-cluster/) due to resource limitations.


In the following procedure, `kong migrations finish` is only executed at the end of the upgrade, 
after you have verified that the new cluster Y is operating as expected.

### Prepare the upgrade

1. Stop any {{site.base_gateway}} configuration updates (e.g. Admin API calls). 
This is critical to guarantee data consistency between cluster X and cluster Y.

2. Back up data from the current cluster X by following the 
[Backup guide](/gateway/upgrade/backup-and-restore/).

3. Evaluate factors that may impact the upgrade, as described in [Upgrade considerations](/gateway/upgrade/#preparation-upgrade-considerations/).
You may have to consider customization of both `kong.conf` and {{site.base_gateway}} configuration data.

4. Evaluate any changes that have happened between releases:
    * [Breaking changes](/gateway/breaking-changes/)
    * [Full changelog](/gateway/changelog/)

### Deploy a new {{site.base_gateway}} cluster of version Y

1. Install a new {{site.base_gateway}} cluster running version Y as instructed in the 
[{{site.base_gateway}} Installation Options](/gateway/install/) and 
point it at the existing database for cluster X.

    Provision the new cluster Y with the same-sized resource capacity as that of 
    the current cluster X.

1. Migrate the database to the new version by running `kong migrations up`. 

    {{site.base_gateway}} will print a warning log entry that pending migrations exist. 
    This is expected.

1. Start the new cluster Y.

1. _(LTS upgrades or 2.x to 3.x upgrades only)_ Using the decK file created during backup, [convert](/deck/file/convert/) your entity configuration and sync the converted file to your newly installed version.

1. Perform staging tests against version Y to make sure it works for all use cases. 

    For example, does the Key Authentication plugin authenticate requests properly?
    
    If the outcome is not as expected, look over the 
    [upgrade considerations](/gateway/upgrade/#preparation-upgrade-considerations/) and the 
    [breaking changes](/gateway/breaking-changes/)
    again to see if you missed anything.

### Divert traffic from old cluster X to new cluster Y

This is usually done gradually and incrementally, depending on the risk profile of the deployment. 
Any load balancers that support traffic splitting will work here, such as DNS, Nginx, Kubernetes rollout mechanisms, and so on.

Once this is done, actively monitor all proxy metrics. If any issues arise, roll back by setting all traffic to cluster X, investigate the issues, and repeat the steps above.

### Finalize the migration

1. Finalize the database migrations with `kong migrations finish`. 

2. When there are no more issues, decommission the old cluster X to complete the upgrade.

Write updates to {{site.base_gateway}} can now be performed, though we suggest you keep monitoring metrics for a while.

{:.info}
> **Note**: This upgrade strategy is not the same thing as the [blue-green deployment](/gateway/traffic-control/blue-green-deployments/). 
That process is meant for upgrading your upstream services and is not related to {{site.base_gateway}} upgrades.

{:.warning}
> **Caution**: {% include_cached /gateway/migration-finish-warning.md %}
