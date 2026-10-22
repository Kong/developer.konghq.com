---
title: How to delete a workspace that has Dev Portal enabled via DB
content_type: support
description: How to delete a Dev-Portal-enabled workspace directly via the database when it reports `Workspace is not empty` due to remaining files.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I delete a workspace that has Dev Portal enabled when the Admin API reports `Workspace is not empty`?
  a: |
    A workspace with leftover Dev Portal files refuses deletion with `Workspace is not empty`. If the Portal CLI approach doesn't clear them, disable the Dev Portal for the workspace, then connect to the database directly, delete the workspace's rows from the `files` table, and delete the workspace.
---

## Overview

You probably will meet the below error when deleting a workspace that has Dev Portal files remaining in it:

```json
{"message":{"message":"Workspace is not empty","entities":{"files":103}}}
```

First, please follow the below article to try to delete the target workspace by Portal CLI: [Cannot delete a workspace after enabling the Developer Portal](/support/cannot-delete-a-workspace-after-enabling-the-developer-portal/)

If the Portal CLI does not look good for you, this article will guide you to delete a portal-enabled workspace via DB. *Be careful when operating the database.*

## Steps

1. Disable the Dev Portal for the target workspace.  In this example, the target workspace is called "test".

2. Log in to DB

3. Find the target workspace ID and confirm how many files it has.

You will see there are 103 files in the workspace 'test'.

```sql
kong=# select id from workspaces where name = 'test';
                  id
--------------------------------------
 01aa5640-589a-4687-9cec-3e0e1afc4aae

kong=# select count(*) from files where ws_id = '01aa5640-589a-4687-9cec-3e0e1afc4aae';
 count
-------
   103
```

4. Delete files of the target workspace and then check

```sql
kong=# delete from files where ws_id='01aa5640-589a-4687-9cec-3e0e1afc4aae';
DELETE 103
kong=# select ws_id, path from files where ws_id='01aa5640-589a-4687-9cec-3e0e1afc4aae';
 ws_id | path
-------+------
(0 rows)
```

5. You can delete the workspace now.
