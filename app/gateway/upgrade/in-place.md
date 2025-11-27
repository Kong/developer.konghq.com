---
title: "In-place upgrade for {{site.base_gateway}}"
description: Learn how to perform a in-place upgrade for {{site.base_gateway}}.
content_type: reference
layout: reference
breadcrumbs:
  - /gateway/
  - /gateway/upgrade/
products:
    - gateway

works_on:
    - on-prem

tags:
    - upgrade
    - versioning



related_resources:
  - text: "Upgrading {{site.base_gateway}}"
    url: /gateway/upgrade/
  - text: "Dual-cluster upgrade"
    url: /gateway/upgrade/dual-cluster/
  - text: Rolling upgrade
    url: /gateway/upgrade/rolling/
  - text: "Blue-green upgrade"
    url: /gateway/upgrade/blue-green/
  - text: "{{site.base_gateway}} breaking changes"
    url: /gateway/breaking-changes/
  - text: "Backing up and restoring {{site.base_gateway}}"
    url: /gateway/upgrade/backup-and-restore/
  - text: "{{site.base_gateway}} CLI reference"
    url: /gateway/cli/reference/
  - text: "3.4 to 3.10 LTS upgrade"
    url: /gateway/upgrade/lts-upgrade-34-310/
  - text: "2.8 to 3.4 LTS upgrade"
    url: /gateway/upgrade/lts-upgrade-28-34/
---

The in-place upgrade strategy is a {{site.base_gateway}} upgrade option used primarily for traditional mode deployments and for control planes in hybrid mode. 
An in-place upgrade reuses the existing database.

In comparison to [dual-cluster upgrades](/gateway/upgrade/dual-cluster/), the in-place upgrade uses less resources, but causes business downtime.

This guide refers to the old version as cluster X and the new version as cluster Y.
For this upgrade method, you have to shut down cluster X, then configure the new cluster Y to point to the database.

{% mermaid %}
flowchart TD
    DB[(Database)]
    CPX(Current {{site.base_gateway}} X \n #40;inactive#41;)
    Admin(No Admin API \n write operations)
    CPY(New {{site.base_gateway}} Y)
    API(API requests)

    CPX -.X.-> DB
    API --> CPY
    CPY --kong migrations up \n kong migrations finish--> DB
    Admin -.X.- CPX & CPY

    style CPX stroke-dasharray:3
    style Admin fill:none!important,stroke:none!important,color:#d44324!important
    linkStyle 0,3,4 stroke:#d44324!important,color:#d44324!important
{% endmermaid %}

> _Figure 1: The diagram shows an in-place upgrade workflow, where the current cluster X is directly replaced by a new cluster Y._
_The database is reused by the new cluster Y, and the current cluster X is shut down once all nodes are migrated. No Admin API write operations can be performed during the upgrade._

There is business downtime as cluster X is stopped during the upgrade process. 
You must carefully review the [upgrade considerations](/gateway/upgrade/#preparation-upgrade-considerations) in advance.

{:.warning}
> **Important**: We do not recommend using this strategy unless {{site.base_gateway}} is deployed under 
an extremely resource-constrained environment, or unless you can't obtain new resources in a 
timely manner for a dual-cluster upgrade.
> <br><br>
> The current cluster X can be substituted in place with the new cluster Y.
However, this strategy does not prevent you from deploying the new cluster Y on a different machine.

## Upgrade using the in-place method

{:.info}
> The following steps are intended as a guideline.
The exact execution of these steps will vary depending on your environment. 

### Prerequisites

* Review the [general upgrade guide](/gateway/upgrade/) to prepare for the upgrade and review your options.
* You have a traditional deployment or you need to upgrade the control planes (CPs) in a hybrid mode deployment.
* You can't perform [dual-cluster upgrades](/gateway/upgrade/dual-cluster/) due to resource limitations.

### Prepare the upgrade

1. Stop any {{site.base_gateway}} configuration updates (e.g. Admin API calls). 
This is critical to guarantee data consistency between cluster X and cluster Y.

2. Back up data from the current cluster X by following the 
[backup guide](/gateway/upgrade/backup-and-restore/).

3. Evaluate factors that may impact the upgrade, as described in [Upgrade considerations](/gateway/upgrade/#preparation-upgrade-considerations/).
You may have to consider customization of both `kong.conf` and {{site.base_gateway}} configuration data.

4. Evaluate any changes that have happened between releases:
    * [Breaking changes](/gateway/breaking-changes/)
    * [Full changelog](/gateway/changelog/)

### Switch the cluster

1. Stop the {{site.base_gateway}} nodes of the old cluster X but keep the database running. 
This will create a period of downtime until the upgrade completes.

1. Install a new cluster running version Y as instructed in the 
    [{{site.base_gateway}} Installation Options](/gateway/install/) and 
    point it at the existing database for cluster X.
    
    Provision the new cluster Y with the same-sized resource capacity as that of 
    the current cluster X.

1. Migrate the database to the new version by running `kong migrations up`. 

1. When complete, run `kong migrations finish`.

1. Start the new cluster Y.

1. _(LTS upgrades or 2.x to 3.x upgrades only)_ Using the decK file created during backup, [convert](/deck/file/convert/) your entity configuration and sync the converted file to your newly installed version.

Once this is done, actively monitor all proxy metrics. If you run into any issues, [roll back the upgrade](/gateway/upgrade/backup-and-restore/#restore-gateway-entities). 
Prioritize the database-level restoration method over the application-level method.

When there are no more issues, decommission the old cluster X to complete the upgrade. 

Write updates to {{site.base_gateway}} can now be performed, though we suggest you keep monitoring metrics for a while.

{:.warning}
> **Caution**: {% include_cached /gateway/migration-finish-warning.md %}
