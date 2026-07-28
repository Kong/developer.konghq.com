---
title: "`authenticated_groups_claim only supports 1 claim` error when mapping OIDC groups from a nested claim"
content_type: support
published: false
description: This error occurs when `authenticated_groups_claim` is mapped from a nested claim; it must reference a top-level claim instead.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does Kong Manager OIDC group mapping fail with `authenticated_groups_claim only supports 1 claim`?
  a: |
    `authenticated_groups_claim` must point to a top-level claim in the token — nested claims can't be traversed. Move the group claim so it's a top-level field instead of nesting it inside another object (for example, instead of nesting it under `resources.kong.roles`).
related_resources: []
---

## Problem

When using OIDC authentication with Kong Manager you may experience the below error when mapping groups:

```
Error: 
/usr/local/share/lua/5.1/kong/cmd/migrations.lua:210: authenticated_groups_claim only supports 1 claim
stack traceback:
     [C]: in function 'assert'
     /usr/local/share/lua/5.1/kong/cmd/migrations.lua:210: in function 'cmd_exec'
     /usr/local/share/lua/5.1/kong/cmd/init.lua:97: in function </usr/local/share/lua/5.1/kong/cmd/init.lua:97>
     [C]: in function 'xpcall'
     /usr/local/share/lua/5.1/kong/cmd/init.lua:97: in function </usr/local/share/lua/5.1/kong/cmd/init.lua:54>
     /usr/local/bin/kong:9: in function 'file_gen'
     init_worker_by_lua:48: in function <init_worker_by_lua:46>
     [C]: in function 'xpcall'
     init_worker_by_lua:55: in function <init_worker_by_lua:53>
```

This error can occur when you are attempting to map the group from a nested claim, as seen here.

i.e.

```json
{
	"iss": "https://accounts.google.com",
	"azp": "kong",
	"aud": "14d7b878-76bf-4518-840b-38600cdb009e",
	"sub": "14d7b878-76bf-4518-840b-38600cdb009e",
	"iat": 1667220111,
	"exp": 1667223711,
	"resources": {
		"kong": {
			"roles": ["default:super-admin"]
		}
	}
}
```

## Solution

Currently, this must be specified as a top-level object as nested claims cannot be traversed.
