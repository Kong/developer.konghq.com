---
title: "Migrate from {{site.base_gateway}} OSS to {{site.ee_product_name}}"
permalink: /gateway/upgrade/migrate-oss-to-ee/

description: "Learn how to migrate from {{site.base_gateway}} open source to {{site.ee_product_name}} using the kong migrations CLI."

content_type: how_to

products:
  - gateway

works_on:
  - on-prem

tags:
  - upgrade
  - migration

search_aliases:
  - migrate ce to ee
  - migrate community to enterprise

tldr:
  q: How do I migrate from {{site.base_gateway}} OSS to {{site.ee_product_name}}?
  a: |
    Install the {{site.ee_product_name}} package that matches your OSS version, point it at the same data store, then run `kong migrations up` and `kong migrations finish`.

prereqs:
  skip_product: true
  inline:
    - title: Back up your data
      content: |
        You have backed up your {{site.base_gateway}} data.
        See [Backing up and restoring {{site.base_gateway}}](/gateway/upgrade/backup-and-restore/).

        {:.danger}
        > **Warning:** Migration is irreversible, therefore we strongly recommend backing up your production data before migrating from {{site.base_gateway}} OSS to {{site.ee_product_name}}.

      icon_url: /assets/icons/service-document.svg

related_resources:
  - text: "Upgrade and migrate {{site.base_gateway}}"
    url: /gateway/upgrade/
  - text: "Upgrading {{site.base_gateway}}"
    url: /gateway/upgrade/reference/
  - text: "Backing up and restoring {{site.base_gateway}}"
    url: /gateway/upgrade/backup-and-restore/
  - text: "Migrating from self-managed {{site.base_gateway}} to {{site.konnect_short_name}}"
    url: /gateway/self-managed-migration/
  - text: kong migrations CLI reference
    url: /gateway/cli/reference/#kong-migrations
next_steps:
  - text: Upgrade to your desired version of {{site.ee_product_name}}
    url: /gateway/upgrade/reference/
  - text: Migrate to {{site.konnect_short_name}}
    url: /gateway/self-managed-migration/

automated_tests: false
---

## Review deployment options

Review [{{site.base_gateway}} deployment topologies](/gateway/deployment-topologies/) and choose a target deployment type.

* {{site.base_gateway}} OSS supports only [traditional](/gateway/traditional-mode/) and [DB-less](/gateway/db-less-mode/) deployments.
* {{site.ee_product_name}} supports traditional, DB-less, and also introduces [hybrid mode](/gateway/hybrid-mode/), which separates the control plane and the data plane.

If you choose to migrate to hybrid mode, all data store operations will occur on the control plane.
If you want to migrate to {{site.konnect_short_name}}, first migrate to {{site.ee_product_name}} in hybrid mode, and then migrate to {{site.konnect_short_name}}.

## Download and install the Enterprise package

Download and install the {{site.ee_product_name}} package that matches your installed OSS version from the [{{site.base_gateway}} install page](/gateway/install/).
You can only migrate to an Enterprise version that supports the same OSS version.
The latest supported OSS version is `{{site.latest_gateway_oss_version}}`.

## Run database migrations

Configure the new {{site.ee_product_name}} deployment to point to the same data store as your {{site.base_gateway}} OSS node.
The [`migrations` command](/gateway/cli/reference/#kong-migrations) expects the data store to be up to date on any pending migrations.

Run migrations from the new node, pointing to your existing configuration file:

```bash
kong migrations up [-c configuration_file]
kong migrations finish [-c configuration_file]
```

{:.warning}
> **Caution**: {% include_cached /gateway/migration-finish-warning.md %}

## Confirm your entities

Start your {{site.ee_product_name}} node and confirm that all entities are available.
