---
title: How to change Kong manager password from database
content_type: support
description: Update the `basicauth_credentials` table directly in Postgres to reset the Kong Manager `kong_admin` login password when SMTP-based resets aren't available.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I change the Kong Manager login password directly in the database?
  a: |
    Kong Manager's `kong_admin` password is stored in the `basicauth_credentials` table as `sha256(password + consumer_id)`. Compute the new hash for your desired password and consumer_id, update the row directly with `UPDATE basicauth_credentials SET password = '<hash>' WHERE username = 'default:kong_admin';`, then clear Kong's cache (via the Admin API `/cache` endpoint or a container restart) so the new password takes effect. This only resets the Kong Manager login, not the RBAC token, and should be a last resort — set up SMTP for password resets when possible.
related_resources: []
---

## Overview

Kong manager and RBAC token are the same during the initial set up. This token is the `KONG_PASSWORD` user set during the database migration. After the initial log in, users can change Kong manager log in and RBAC for user `kong_admin` to different values. If users forgot `kong_admin` password for logging in Kong manager, how could they modify this password in the database directly?

## Steps

As this will touch your database, please have a full backup before following this article. This method should only be used as the last resource, please set up SMTP for password resets.

This method does NOT reset RBAC token, it changes the Kong manager log-in password only.

Prerequisites:

- Kong Gateway (Enterprise), self-managed/on-prem, with RBAC turned on and Basic Auth as Kong Manager authentication method (this method requires direct `psql` access to the underlying database, so it does not apply to Konnect, where the control plane database is managed by Kong and not reachable by the customer)
- Postgres as database
- User has access to the Postgresql database

First of all, please log in to `psql` and connect to your Kong database.

### List tables in the database

Use `\dt` command show tables. We can see there is one table named `basicauth_credentials`. Kong manager's password stores here.

```
kong=# \dt
                           List of relations
 Schema |                     Name                      | Type  | Owner
--------+-----------------------------------------------+-------+-------
 public | acls                                          | table | kong
 public | admins                                        | table | kong
 public | apis                                          | table | kong
 public | application_instances                         | table | kong
 public | applications                                  | table | kong
 public | audit_objects                                 | table | kong
 public | audit_requests                                | table | kong
 public | basicauth_credentials                         | table | kong
```

### Check `basicauth_credentials`

Use `SELECT * FROM basicauth_credentials WHERE username = 'default:kong_admin';`, we should see below result. Note down `consumer_id.`

```
                  id                  |       created_at       |             consumer_id              |      username      |                 password                 | tags
--------------------------------------+------------------------+--------------------------------------+--------------------+------------------------------------------+------
 bc20f220-2dd9-49c5-9493-3fb22bc4d405 | 2026-09-07 12:54:02+00 | 63cdda87-1254-4a5a-b1dd-13f901df04d3 | default:kong_admin | 6473882f46d452da7cdb5eb1a71247149e9891b9 |
(1 row)
```

### Create new password

The way `basic-auth` creates the password is `sha256(password + consumer_id)`.

Let's say we want the new password to be `abcd`, we need to calculate `sha256(abcd63cdda87-1254-4a5a-b1dd-13f901df04d3)`

You can use any of the following commands: `$ printf 'abcd63cdda87-1254-4a5a-b1dd-13f901df04d3' | shasum -a 256` -> `6d28f6d18ffbb49f38943977dcf72645288db273817f32a7e0728494d692d077`, or `$ echo -n 'abcd63cdda87-1254-4a5a-b1dd-13f901df04d3' | openssl sha256` -> same result

### Update Database

Let's go back to the database, now we need to use below SQL to update record. If it goes well, we should see `UPDATE 1`.

```sql
UPDATE basicauth_credentials SET password = '6d28f6d18ffbb49f38943977dcf72645288db273817f32a7e0728494d692d077' WHERE username = 'default:kong_admin';
```

Note: older Kong Gateway versions hashed this password with SHA1 instead of SHA256. Kong still accepts a stored SHA1 hash for backward compatibility (it distinguishes the two purely by the stored hash's length: 40 hex characters for SHA1 vs. 64 for SHA256), but SHA256 is the algorithm current Kong Gateway versions use when writing a new credential, so a manually-computed hash should use SHA256 to match.

### Clear cache or restart Kong container

The old password will still be in cache. You can use Admin-API to remove cache.

```bash
curl -X DELETE http://<admin_api_url>:<admin_api_port>/cache -H "Kong-Admin-Token:<RBAC_TOKEN>" -i
HTTP/1.1 204 No Content
```

User can also restart the kong container to clear cache.

After that, user can access Kong manager with username `kong_admin` and password `abcd`.
