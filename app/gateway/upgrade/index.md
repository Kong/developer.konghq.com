---
title: "Upgrading {{site.base_gateway}}"
content_type: reference
layout: reference
breadcrumbs:
  - /gateway/
products:
    - gateway

works_on:
    - on-prem
    - konnect

description: This guide walks you through upgrade paths for {{site.base_gateway}} and helps you prepare for an upgrade.

related_resources:
  - text: "{{site.base_gateway}} breaking changes"
    url: /gateway/breaking-changes/
  - text: "Backing up and restoring {{site.base_gateway}}"
    url: /gateway/upgrade/backup-and-restore/
  - text: "Dual-cluster upgrade"
    url: /gateway/upgrade/dual-cluster/
  - text: "In-place upgrade"
    url: /gateway/upgrade/in-place/
  - text: "Rolling upgrade"
    url: /gateway/upgrade/rolling/
  - text: "Blue-green upgrade"
    url: /gateway/upgrade/blue-green/
  - text: "3.4 to 3.10 LTS upgrade"
    url: /gateway/upgrade/lts-upgrade-34-310/
  - text: "2.8 to 3.4 LTS upgrade"
    url: /gateway/upgrade/lts-upgrade-28-34/
tags:
  - versioning
  - upgrade
---

This guide walks you through preparing for a {{site.base_gateway}} upgrade, helps you determine which upgrade path to use, and helps you decide on the best strategy for each {{site.base_gateway}} deployment mode.

Additionally, this guide lists some fundamental factors that play important roles in the upgrade process, and explains how to back up and recover data.

This guide uses the following terms in the context of {{site.base_gateway}}:
* **Upgrade**: The overall process of switching from an older to a newer version of {{site.base_gateway}}. 
* **Migration**: The migration of your data store data into a new environment. 
For example, the process of moving data from an old PostgreSQL instance to a new one is referred to as database migration.

{:.info}
> **Note**: If you are interested in upgrading between the {{site.ee_product_name}} long-term 
support (LTS) versions, see:
> * [{{site.base_gateway}} 3.4 to 3.10 LTS upgrade guide](/gateway/upgrade/lts-upgrade-34-310/)
> * [{{site.base_gateway}} 2.8 to 3.4 LTS upgrade guide](/gateway/upgrade/lts-upgrade-28-34/)

## Upgrade overview

A {{site.base_gateway}} upgrade requires two phases of work: preparing for the upgrade and applying the upgrade.

### Preparation phase

1. Review version compatibility between your platform version and the version of {{site.base_gateway}} that you are upgrading to:
    * [OS version](/gateway/version-support-policy/)
    * [Kubernetes version and Helm prerequisites](/kubernetes-ingress-controller/support/)
    * [Database and dependency versions](/gateway/third-party-support/)
1. Determine your [upgrade path](#preparation-choose-an-upgrade-path) based on the release you're starting from and the release you're upgrading to.
1. [Back up](#preparation-choose-a-backup-strategy) your database or your declarative configuration files.
1. Choose the right [strategy for upgrading](#preparation-choose-an-upgrade-strategy-based-on-deployment-mode) based on your deployment topology.
1. Review the [breaking changes](#preparation-review-breaking-changes-and-changelogs) for the version you're upgrading to.
1. Review any remaining [upgrade considerations](#preparation-upgrade-considerations).
1. Test migration in a pre-production environment.

### Performing the upgrade

The actual execution of the upgrade depends on type of deployment you have with {{site.base_gateway}}. 
In this part of the upgrade journey, you will use the strategy you determined during the preparation phase.

1. [Execute your chosen upgrade strategy on dev](#perform-the-upgrade).
2. Move from dev to prod.
3. Run smoke tests.
4. Wrap up the upgrade or roll back and try again.

Now, let's move on to preparation, starting with determining your upgrade path.

## Preparation: Choose an upgrade path

{{site.base_gateway}} adheres to a structured approach to versioning its products, which makes a
distinction between major, minor, and patch versions.

The upgrade from 2.x to 3.x is a **major** upgrade.
The lowest version that {{site.base_gateway}} 3.0.x supports migrating from is 2.1.x.

{{site.base_gateway}} does not support directly upgrading from 1.x to 3.x.
If you are running 1.x, upgrade to 2.1.0 first at a minimum, then upgrade to 3.0.x from there.

While you can upgrade directly to the latest version, be aware of any [breaking changes](/gateway/breaking-changes/) 
between the 2.x and 3.x series (both this version and prior versions) and in the Gateway [changelog](/gateway/changelog/).

Upgrade paths are subject to a wide spectrum of conditions, and there is not a one-size-fits-all way applicable to all users.
Factors include, but are not limited to:
* Deployment modes
* Custom plugins
* Technical capabilities or limitations of the environment
* Hardware capacities
* SLA

You should discuss the upgrade process thoroughly and carefully with Kong's support engineers before you take any action.

We encourage you to stay up-to-date with {{site.base_gateway}} releases, as that helps maintain a smooth upgrade path. 
The smaller the version gap is, the less complex the upgrade process becomes.

### Guaranteed upgrade paths

By default, {{site.base_gateway}} has migration tests between adjacent versions, therefore the following upgrade paths are guaranteed officially:

1. Between patch releases of the same major and minor version (for example, 3.8.0.0 to 3.8.1.0).
2. Between adjacent minor releases of the same major version (for example, 3.7.x to 3.8.x).
3. Between adjacent [LTS (Long Term Support) versions](/gateway/version-support-policy/#long-term-support).

    {{site.base_gateway}} maintains LTS versions and guarantees upgrades between adjacent LTS versions.
    The current LTS in the 2.x series is 2.8, and the current LTS in the 3.x series is 3.10.
    If you want to upgrade between LTS versions, see the upgrade guides:
    * [{{site.base_gateway}} 3.4 to 3.10 LTS upgrade guide](/gateway/upgrade/lts-upgrade-34-310/)
    * [{{site.base_gateway}} 2.8 to 3.4 LTS upgrade guide](/gateway/upgrade/lts-upgrade-28-34/)

## Preparation: Choose a backup strategy

{% include_cached /upgrade/backup.md %}

## Preparation: Choose an upgrade strategy based on deployment mode

Though you could define your own upgrade procedures, we recommend using one of the strategies in this section.
Any custom upgrade requirements may require a well-tailored upgrade strategy. 
For example, if you only want a small group of objects to be directed to the new version, use the 
[Canary plugin](/plugins/canary/) and a load balancer that supports traffic interception.

Whichever upgrade strategy you choose, you should account for management downtime for {{site.base_gateway}}, as 
Admin API operations and database updates are not allowed during the upgrade process.

Based on your deployment type, we recommend one of the following upgrade strategies.
Carefully read the descriptions for each option to choose the upgrade strategy that works best for your situation.

* [Traditional](#traditional-mode) or [Hybrid mode Control Planes](#control-planes):
    * [Dual-cluster upgrade](/gateway/upgrade/dual-cluster/)
    * [In-place upgrade](/gateway/upgrade/in-place/)
    * [Blue-green upgrade](/gateway/upgrade/blue-green/) (not recommended)

* [DB-less mode](#db-less-mode) or [Hybrid mode Data Planes](#data-planes):
    * [Rolling upgrade](/gateway/upgrade/rolling/)

Here's a flowchart that breaks down how the decision process works:

{% include_cached /upgrade/flow.md %}

See the following sections for breakdowns and links to each upgrade strategy guide.

### Traditional mode

{% include_cached /upgrade/traditional.md %}

{:.warning}
> **Important**: While the [blue-green upgrade strategy](/gateway/upgrade/blue-green/) is an option,
we do not recommend it. Support from Kong for upgrades using this strategy is limited. 
It is nearly impossible to fully cover all migration tests, because we have to cover all 
combinations, given the number of {{site.base_gateway}} versions, upgrade strategies, features adopted, and deployment modes. 
If you must use this strategy, only use it to upgrade between patch versions.

### DB-less mode

{% include_cached /upgrade/db-less.md %}

### Hybrid mode

{% include_cached /upgrade/hybrid.md %}

#### Upgrades from 3.1.0.0 or 3.1.1.1

There is a special case if you deployed {{site.base_gateway}} in Hybrid mode and the version you are using is 3.1.0.0 or 3.1.1.1.
Kong removed the legacy WebSocket protocol between the CP and DP, replaced it with a new WebSocket protocol in 3.1.0.0,
and added back the legacy one in 3.1.1.2. 
So, upgrade to 3.1.1.2 first before moving forward to later versions. 

Additionally, the new WebSocket protocol has been completely removed since 3.2.0.0.
See the following table for the version breakdown:

<!--vale off-->
{% feature_table %}
item_title: {{site.base_gateway}} Version
columns:
  - title: Legacy WebSocket (JSON)
    key: legacy
  - title: New WebSocket (RPC)
    key: new

features:
  - title: 3.0.0.0
    legacy: true
    new: true
  - title: 3.1.0.0
    legacy: false
    new: true
  - title: 3.1.1.1
    legacy: false
    new: true
  - title: 3.1.1.2
    legacy: true
    new: true
  - title: 3.2.0.0
    legacy: true
    new: false
    
{% endfeature_table %}
<!--vale on-->

## Preparation: Review breaking changes and changelogs

Review the [breaking changes](/gateway/breaking-changes/) and [changelogs](/gateway/changelog/) for the release or 
releases that you are upgrading to. 
Make any preparations or adjustments as directed in the breaking changes.

## Preparation: Upgrade considerations

There are some universal factors that may also influence the upgrade, regardless of your deployment mode.

Selecting a strategy for the target deployment mode doesn't guarantee that you can start the upgrade immediately.
You must also account for the following factors:

* During the upgrade process, no changes can be made to the database. 
Until the upgrade is completed:
  * Don't write to the database via the [Admin API](/admin-api/).
  * Don't operate on the database directly.
  * Don't update configuration through [Kong Manager](/gateway/kong-manager/), 
  [decK](/deck/), or the [kong config CLI](/gateway/cli/reference/#kong-config).
* Review the compatibility between the new version Y and your existing platform. 
Factors may include, but are not limited to:
  * [OS version](/gateway/version-support-policy/#supported-versions)
  * [Kubernetes version and Helm prerequisites](/kubernetes-ingress-controller/support/)
  * [Hardware resources](/gateway/resource-sizing-guidelines/)
  * [Database and dependency versions](/gateway/third-party-support/)
* Carefully review all [changelogs](/gateway/changelog/) starting from your current version X,
 all the way up to the target version Y. 
  * Look for any potential conflicts, especially for schema changes and functionality removal.
  * When configuring the new cluster, update `kong.conf` directly or via environment variables based on the changelog.

    Breaking changes in `kong.conf` in a minor version upgrade are infrequent, but do happen.

    For example, the parameter `pg_ssl_version` defaults to `tlsv1` in 2.8.2.4, but in 3.2.2.1, `tlsv1` is not a valid argument anymore.
    If you were depending on this setting, you would have to adjust your environment to fit one of the new options.

* If you have custom plugins, review the code against changelog and test the custom plugin using the new version Y.
* If you have modified any Nginx templates like `nginx-kong.conf` and `nginx-kong-stream.conf`, also make those changes to the templates for the new version Y. 
See the [Nginx Directives reference](/gateway/nginx-directives/) for a detailed customization guide.
* If you're using {{site.ee_product_name}}, make sure to [apply the enterprise license](/gateway/entities/license/) to the new Gateway cluster.
* Always remember to take a [backup](/gateway/upgrade/backup-and-restore/).
* Cassandra DB support has been removed from {{site.base_gateway}} with 3.4.0.0.
Work with the Kong support team to migrate from Cassandra to PostgreSQL.

## Perform the upgrade

Once you have reviewed everything and chosen a strategy, proceed to upgrade {{site.base_gateway}} 
using your chosen strategy:

* [Dual-cluster upgrade](/gateway/upgrade/dual-cluster/)
* [In-place upgrade](/gateway/upgrade/in-place/)
* [Blue-green upgrade](/gateway/upgrade/blue-green/)
* [Rolling upgrade](/gateway/upgrade/rolling/)
