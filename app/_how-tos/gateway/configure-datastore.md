---
title: Configure the {{site.base_gateway}} datastore on Linux
permalink: /how-to/configure-datastore/
content_type: how_to
products:
    - gateway
breadcrumbs:
    - /gateway/
works_on:
    - on-prem
search_aliases:
    - datastore
tldr:
  q: How do I configure the datastore for {{site.base_gateway}} when running on Linux?
  a: |
    After installing the database, configure `kong.conf` to connect to PostgreSQL,
    run `kong migrations bootstrap` to initialize the schema, then start {{site.base_gateway}}.


prereqs:
  skip_product: true
  inline:
    - title: Install {{site.base_gateway}}
      content: |
       [Install {{site.base_gateway}}](/gateway/install/#linux)
    - title: Install PostgreSQL
      include_content: prereqs/postgres
    - title: Configure PostgreSQL authentication (RHEL only)
      content: |
        On Red Hat–based distributions, PostgreSQL defaults to `ident` or `peer`
        authentication. {{site.base_gateway}} requires password-based authentication.

        Edit the active `pg_hba.conf` file and update local and localhost rules to use `md5`,
        then restart PostgreSQL: 
        ```sh
        sudo systemctl restart postgresql
        ```
        By default, the `pg_hba.conf` file is located at `/var/lib/pgsql/data/pg_hba.conf`.

    - title: Configure environment variables
      content: |
        Set the following variables so that `kong.conf` can interact with the datastore:

        ```sh
        export KONG_DATABASE=postgres
        export KONG_PG_HOST=127.0.0.1
        export KONG_PG_PORT=5432
        export KONG_PG_USER=kong
        export KONG_PG_PASSWORD=super_secret
        export KONG_PG_DATABASE=kong
        ```

faqs:
  - q: Can I run a multi-node PostgreSQL cluster for failover with {{site.base_gateway}}?
    a: |
      {% new_in 3.17 %} Yes. Set `pg_host` to a comma-separated list of every node in the cluster, and {{site.base_gateway}} connects to the node that accepts writes.
      When the primary moves, {{site.base_gateway}} finds the new primary without a reload.

      This works in traditional mode and for the control plane in hybrid mode, without a virtual IP (VIP) or load balancer in front of the cluster.
      It doesn't apply to DB-less mode, data planes, or {{site.konnect_short_name}}.

      All nodes must belong to the same cluster and share the same database and credentials.
      See [Use {{site.base_gateway}} with a PostgreSQL cluster without a VIP](/how-to/use-kong-with-a-postgres-cluster-without-a-vip/) and the [PostgreSQL multi-host reference](/gateway/postgresql-multi-host-reference/).

min_version:
    gateway: '3.4'

next_steps:
  - text: Harden the datastore with minimal PostgreSQL privileges
    url: /gateway/postgresql-privileges-reference/
  - text: Use {{site.base_gateway}} with a PostgreSQL cluster without a VIP
    url: /how-to/use-kong-with-a-postgres-cluster-without-a-vip/
  - text: Learn about {{site.base_gateway}} entities
    url: /gateway/entities/
  - text: Learn about {{site.base_gateway}} plugins
    url: /plugins/
  - text: Learn about decK
    url: /deck/
---


## Configure PostgreSQL

1. Switch to the default PostgreSQL user:

    ```sh
    sudo -i -u postgres
    ```
1. Start the PostgreSQL shell:

    ```
    psql
    ```
1. Create a `kong` user and password:

    ```
    CREATE USER kong WITH PASSWORD 'super_secret';
    ```
1. Create a database titled `kong` and assign the user as an owner:

    ```
    CREATE DATABASE kong OWNER kong;
    ```
1. Exit PostgreSQL:

    ```
    \quit
    ```

1. Exit the PostgreSQL shell:

    ```
    exit
    ```

## Run a {{site.base_gateway}} database migration

`kong migrations` is used to configure the database for the first time.
Running `bootstrap` forces {{site.base_gateway}} to bootstrap the database set up in the previous step and run all of the migrations:

```sh
sudo -E kong migrations bootstrap
```

This command must be run as the `root` user.

{:.warning}
> This command must be run with `sudo -E` to preserve the environment variables set in the prerequisites.
> If the `kong` command is not found when running with `sudo`, you can create a symlink so it is available from the default PATH:
> `sudo ln -s /usr/local/bin/kong /usr/bin/kong`

## Validate

You can validate that the datastore was configured correctly by starting {{site.base_gateway}}.

1. Start {{site.base_gateway}}:

    ```sh
    sudo -E kong start
    ```
2. Verify the installation:

    ```sh
    curl -i http://localhost:8001
    ```
If you receive a `200` status code, {{site.base_gateway}} was configured correctly. You can now start to configure your API gateway with [plugins](/plugins/) and other [entities](/gateway/entities/).

