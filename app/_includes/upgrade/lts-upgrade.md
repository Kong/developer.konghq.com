{%- assign lts_version_from = include.lts_version_from %}
{%- assign lts_version_to = include.lts_version_to %}

{{site.base_gateway}} supports direct upgrades between long-term support (LTS) versions of {{site.ee_product_name}}.
This guide walks you through upgrading from {{site.ee_product_name}} {{ lts_version_from }} LTS to {{site.ee_product_name}} {{ lts_version_to }} LTS.

There are three upgrade strategies available when upgrading from an LTS version to a newer LTS version: in-place, dual-cluster, and rolling.
This guide describes the best applicable strategy for each deployment mode that {{site.base_gateway}} supports. 
Additionally, it lists some fundamental factors that play important roles in the upgrade process, and explains how to back up and recover data.

This guide uses the following terms in the context of {{site.base_gateway}}:
* **Upgrade**: The overall process of switching from an older to a newer version of {{site.base_gateway}}. 
* **Migration**: The migration of your data store data into a new environment. 
For example, the process of moving data from an old PostgreSQL instance to a new one is referred to as database migration.

To make sure your upgrade is successful, carefully review all the steps in this guide. It’s very important to understand all the preparation steps and choose the recommended upgrade path based on your deployment type.

{:.warning}
> **Caution**: The migration pattern described in this document can only happen between two LTS versions, {{site.ee_product_name}} {{ lts_version_from }} LTS and {{site.ee_product_name}} {{ lts_version_to }} LTS. If you apply this document to other release intervals, database modifications may be run in the wrong sequence and leave the database schema in a broken state.
{%- if include.lts_version_from == "2.8" %}
> * To migrate between 3.4 and 3.10 LTS versions, see the [{{site.base_gateway}} 3.4 to 3.10 LTS upgrade guide](/gateway/upgrade/lts-upgrade-34-310/)
{%- elsif include.lts_version_from == "3.4" %}
> * To migrate between 2.8 and 3.4 LTS versions, see the [{{site.base_gateway}} 2.8 to 3.4 LTS upgrade guide](/gateway/upgrade/lts-upgrade-28-34/)
{%- endif %}
> * To migrate between other versions, see the [general upgrade guide](/gateway/upgrade/).

## Prerequisites

Read this document thoroughly to successfully complete the upgrade process, as it includes all the necessary operational knowledge for the upgrade.

* Review version compatibility between your platform version and the version of {{site.kong_gateway}} that you are upgrading to:
  * [OS version](/gateway/version-support-policy/#supported-versions)
  * [Kubernetes version and Helm prerequisites](/kubernetes-ingress-controller/support/)
  * [Hardware resources](/gateway/resource-sizing-guidelines/)
  * [Database and dependency versions](/gateway/third-party-support/)
* If you're using decK, [upgrade it to the latest version](/deck/).

{% if include.lts_version_from == "2.8" %}
{:.info}
> Starting from {{site.base_gateway}} 3.4, Cassandra is not supported. 
> If you're using Cassandra as your data store, migrate off of Cassandra first and upgrade second.
> Work with the Kong support team to migrate from Cassandra to PostgreSQL.
{% endif %}

<!--vale off-->
{% if include.lts_version_from == "3.4" %}
{:.warning}
> Starting from {{site.base_gateway}} 3.5, Enterprise Developer Portal and Vitals are no longer 
included in {{site.ee_product_name}}. 
> Existing customers who have purchased Kong Enterprise Portal or Vitals can continue to use them and be supported via a dedicated mechanism.
> If you have purchased Kong Enterprise Portal or Vitals in the past and would like to continue to use them in 3.10, contact [Kong Support](https://support.konghq.com) for more information.
{% endif %}
<!--vale on-->

## Upgrade journey overview

### Preparation phase

There are a number of steps you must complete before upgrading to {{site.base_gateway}} {{ lts_version_to }} LTS:

1. Work through any listed prerequisites.
1. [Back up](#preparation-choose-a-backup-strategy) your database or your declarative configuration files.
1. Choose the right [strategy for upgrading](#preparation-choose-an-upgrade-strategy-based-on-deployment-mode) based on your deployment topology.
1. Review the [{{site.base_gateway}} changes from {{ lts_version_from }} to {{ lts_version_to }}](#preparation-review-gateway-changes) for any breaking changes that may affect your deployments.
1. Review any [modifications made to the `kong.conf` file](#kong-conf-changes) between the LTS releases.
1. Using your chosen strategy, test migration in a pre-production environment.

### Performing the upgrade

The actual execution of the upgrade depends on type of deployment you have with {{site.base_gateway}}. 
In this part of the upgrade journey, you will use the strategy you determined during the preparation phase.

1. Execute your chosen upgrade strategy on dev.
2. Move from dev to prod.
3. Smoke test.
4. Finish the upgrade or roll back and try again.

Now, let's move on to preparation, starting with your backup options.

## Preparation: Choose a backup strategy

{% include_cached /upgrade/backup.md %}

## Preparation: Choose an upgrade strategy based on deployment mode

Choose your deployment mode:
* [Traditional](#traditional-mode)
* [DB-less](#db-less-mode)
* [Hybrid](#hybrid-mode)

Here's a flowchart that breaks down how the decision process works:

{% include_cached /upgrade/flow.md %}

See the following sections for breakdowns of each strategy.

### Traditional mode

{% include_cached /upgrade/traditional.md %}

#### Dual-cluster upgrade

Upgrading {{site.base_gateway}} from one LTS version to another LTS version with zero downtime can be achieved through a [dual-cluster upgrade strategy](/gateway/upgrade/dual-cluster/). 
This approach involves setting up a new cluster running the upgraded version of {{site.base_gateway}} alongside the existing cluster running the current version.

At a high level, the process typically involves the following steps:

1. **Provisioning a same-size deployment**: You need to ensure that the new cluster, which will run the upgraded version of {{site.base_gateway}}, has the same capacity and resources as the existing cluster. This ensures that both clusters can handle the same amount of traffic and workload.

1. **Setting up dual-cluster deployment**: Once the new cluster is provisioned, you can start deploying your APIs and configurations to both clusters simultaneously. The dual cluster deployment allows both the old and new clusters to coexist and process requests in parallel.

1. **Data synchronization**:  During the dual cluster deployment, data synchronization is crucial to ensure that both clusters have the same data. This can involve migrating data from the old cluster to the new one or setting up a shared data storage solution to keep both clusters in sync. Import the database from the old cluster to the new cluster by using a snapshot or `pg_restore`.

1. **Traffic rerouting**: As the new cluster is running alongside the old one, you can start gradually routing incoming traffic to the new cluster. This process can be done gradually or through a controlled switchover mechanism to minimize any impact on users. This can be achieved by any load balancer, like DNS, Nginx, F5, or even a {{site.base_gateway}} node with Canary plugin enabled.

1. **Testing and validation**: Before performing a complete switchover to the new cluster, it is essential to thoroughly test and validate the functionality of the upgraded version. This includes testing APIs, plugins, authentication mechanisms, and other functionalities to ensure they are working as expected.

1. **Complete switchover**: Once you are confident that the upgraded cluster is fully functional and stable, you can redirect all incoming traffic to the new cluster. This step completes the upgrade process and decommissions the old cluster.

By following this dual cluster deployment strategy, you can achieve a smooth and zero-downtime upgrade from one LTS version of {{site.base_gateway}} to another. This approach helps ensure high availability and uninterrupted service for your users throughout the upgrade process.

#### In-place upgrade

While an [in-place upgrade](/gateway/upgrade/in-place/) allows you to perform the upgrade on the same infrastructure, 
it does require some downtime during the actual upgrade process.
Plan a suitable maintenance or downtime window during which you can perform the upgrade.
During this period, the {{site.base_gateway}} will be temporarily unavailable.

For scenarios where zero downtime is critical, consider the [dual-cluster upgrade](#dual-cluster-upgrade) method, 
keeping in mind the additional resources and complexities.

### DB-less mode

{% include_cached /upgrade/db-less.md %}

### Hybrid mode

{% include_cached /upgrade/hybrid.md %}

## Preparation: Review gateway changes

{% if include.lts_version_from == "2.8" %}

The following tables categorize all relevant changelog entries from {{site.ee_product_name}} 2.8.0.0-2.8.4.1 up to 3.4.0.0.
Carefully review each entry and make changes to your configuration accordingly.

{% include_cached /upgrade/lts-changes-28-34.md %}

{% elsif include.lts_version_from == "3.4" %}

The following tables categorize all relevant changelog entries from {{site.ee_product_name}} 3.4.0.0 up to 3.10.0.3.
Carefully review each entry and make changes to your configuration accordingly.

{% include_cached /upgrade/lts-changes-34-310.md %}
{% endif %}

## Perform upgrade

Now that you have chosen an upgrade strategy and reviewed all the relevant changes between the {{ lts_version_from }} and {{ lts_version_to }} LTS releases, you can start the upgrade with your chosen strategy:

Traditional mode or control planes in hybrid mode:
* [Dual-cluster upgrade](/gateway/upgrade/dual-cluster/)
* [In-place upgrade](/gateway/upgrade/in-place/)

DB-less mode or data planes in hybrid mode:
* [Rolling upgrade](/gateway/upgrade/rolling/)

## Troubleshooting

If you run into issues during the upgrade and need to roll back, [restore {{site.base_gateway}}](/gateway/upgrade/backup-and-restore/) based on the backup method.
