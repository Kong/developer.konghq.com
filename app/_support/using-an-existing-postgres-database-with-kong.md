---
title: Using an existing PostgreSQL database server with a fresh Kong install
content_type: support
description: Steps to create a Kong role and database in an existing PostgreSQL server, including how to work around a permission error on managed services like RDS.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I use an existing PostgreSQL database server with a fresh Kong install?
  a: |
    Create a dedicated `kong` role and an empty database owned by that role, then point Kong's `PG_DATABASE`, `PG_USER`, and `PG_PASSWORD` settings at those values. On managed services like RDS, the admin user may need to run `grant kong to <admin_user>` before it can create a database owned by the `kong` role.
related_resources: []
---

## Overview

How do I use an existing PostgreSQL database server with a fresh Kong install?

## Steps

When using a preexisting Postgres Database you will need to ensure that the following has been done.

1. Create a `kong` role/user within the database.

2. Create an empty database owned by the `kong` role/user.

From an appropriate tool (`psql` for example) execute the following SQL statements.

```sql

# CREATE USER kong WITH PASSWORD 'super_secret';
# CREATE DATABASE kong OWNER kong;
```

Ensure that within the setup/configuration for Kong the following properties are defined to match the values as used in the SQL commands above.

For example:

```

PG_DATABASE kong
PG_PASSWORD 'super_secret'
PG_USER kong
```

Additionally you may also face another issue when using RDS. We have our database,

```bash

postgres=> \l
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   
-----------+----------+----------+-------------+-------------+-----------------------
 kong      | kong     | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
```

We want to have a fresh start so we remove our db, and for good measure the user/role too,

```bash

postgres=> drop database kong;
DROP DATABASE
postgres=> drop user kong;
DROP ROLE
```

Now we recreate the user and the DB,

```bash

postgres=> create user kong with password 'kong';
CREATE ROLE
postgres=> create database kong owner kong;
ERROR:  must be member of role "kong"
postgres=>
```

But as you can see we got an error.  This is due to the way Postgres is setup in that environment, and so we need to do the following additional step,

```bash

postgres=> grant kong to postgres;
GRANT ROLE
postgres=> 
postgres=> create database kong owner kong;
CREATE DATABASE
```

Here we have to grant the `kong` role to the admin user, in this case Postgres, prior to being able to create the database and setting its ownership to `kong`.
