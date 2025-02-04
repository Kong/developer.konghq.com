---
title: Run {{site.base_gateway}} as a non-root user.
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
    q: How do you configure the datastore for {{site.base_gateway}}?
    a: |
      * Install and configure PostgreSQL.
      * Configure `kong.conf` to interact with the database.
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

@TODO