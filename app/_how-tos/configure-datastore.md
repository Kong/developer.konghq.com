---
title: Configure the {{site.base_gateway}} datastore on Linux
content_type: how_to
related_resources:
  - text: Enable RBAC
    url: /gateway/entities/rbac/#enable-rbac
  - text: Create a Super Admin
    url: /how-to/create-a-super-admin/

products:
    - gateway

works_on:
    - on-prem

tldr:
    q: How do I configure the datastore for {{site.base_gateway}} when running on a Linux OS?
    a: |
      To set up a datastore for your {{site.base_gateway}} on Linux, you need to:
      * Install and configure PostgreSQL.
      * Configure `kong.conf` to interact with the PostgreSQL database.
      * Run a database migration.

prereqs:
  inline:
    - title: Install {{site.base_gateway}} on Ubuntu
      include_content: prereqs/install/ubuntu
    - title: Install PostgreSQL
      include_content: prereqs/postgres
      icon_url: /assets/icons/key.svg
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

tags:
  - install
---


## 1. Configure PostgreSQL 

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
1. Exit PostgreSQL, and exit the PostgreSQL shell:
    
    ```
    exit
    ```

## 2. Run a {{site.base_gateway}} database migration

`kong migrations` is used to configure the database for the first time. 
Running `bootstrap` forces {{site.base_gateway}} to bootstrap the database set up in the previous step and run all of the migrations: 

```sh
kong migrations bootstrap
```

This command must be run as the `root` user. 

## 3. Validate

You can validate that the datastore was configured correctly by starting {{site.base_gateway}}. 

1. Start {{site.base_gateway}}:

    ```sh
    kong start
    ```
2. Verify the installation:

    ```sh
    curl -i http://localhost:8001
    ```
If you receive a `200` status code, {{site.base_gateway}} was configured correctly. 