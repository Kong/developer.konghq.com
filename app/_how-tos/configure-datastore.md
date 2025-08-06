---
title: Configure the {{site.base_gateway}} datastore on Linux
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


min_version:
    gateway: '3.4'

next_steps:
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

