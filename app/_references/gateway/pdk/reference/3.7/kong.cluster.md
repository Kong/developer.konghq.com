---
#
#  WARNING: this file was auto-generated by a script.
#  DO NOT edit this file directly. Instead, send a pull request to change
#  https://github.com/Kong/kong/tree/master/autodoc/pdk/ldoc/ldoc.ltp
#  or its associated files
#
title: kong.cluster
source_url: https://github.com/Kong/kong/tree/master/kong/pdk
---

Cluster-level utilities.



## kong.cluster.get_id()

Returns the unique ID for this Kong cluster.  If Kong
 is running in DB-less mode without a cluster ID explicitly defined,
 then this method returns `nil`.

 For hybrid mode, all control planes and data planes belonging to the same
 cluster return the same cluster ID. For traditional database-based
 deployments, all Kong nodes pointing to the same database also return
 the same cluster ID.


**Returns**

1.  `string|nil`:  The v4 UUID used by this cluster as its ID.

1.  `string|nil`:  An error message.


**Usage**

``` lua
local id, err = kong.cluster.get_id()
if err then
  -- handle error
end

if not id then
  -- no cluster ID is available
end

-- use id here
```


