---
#
#  WARNING: this file was auto-generated by a script.
#  DO NOT edit this file directly. Instead, send a pull request to change
#  https://github.com/Kong/kong/tree/master/autodoc/pdk/ldoc/ldoc.ltp
#  or its associated files
#
title: kong.node
source_url: https://github.com/Kong/kong/tree/master/kong/pdk
---

Node-level utilities.



## kong.node.get_id()

Returns the ID used by this node to describe itself.

**Returns**

* `string`:  The v4 UUID used by this node as its ID.


**Usage**

``` lua
local id = kong.node.get_id()
```



## kong.node.get_memory_stats([unit[, scale]])

Returns memory usage statistics about this node.

**Parameters**

* **unit** (`string`, _optional_):  The unit that memory is reported in. Can be
 any of `b/B`, `k/K`, `m/M`, or `g/G` for bytes, kibibytes, mebibytes,
 or gibibytes, respectively. Defaults to `b` (bytes).
* **scale** (`number`, _optional_):  The number of digits to the right of the decimal
 point. Defaults to 2.

**Returns**

* `table`:   A table containing memory usage statistics for this node.
 If `unit` is `b/B` (the default), reported values are Lua numbers.
 Otherwise, reported values are strings with the unit as a suffix.


**Usage**

``` lua
local res = kong.node.get_memory_stats()
-- res will have the following structure:
{
  lua_shared_dicts = {
    kong = {
      allocated_slabs = 12288,
      capacity = 24576
    },
    kong_db_cache = {
      allocated_slabs = 12288,
      capacity = 12288
    }
  },
  workers_lua_vms = {
    {
      http_allocated_gc = 1102,
      pid = 18004
    },
    {
      http_allocated_gc = 1102,
      pid = 18005
    }
  }
}

local res = kong.node.get_memory_stats("k", 1)
-- res will have the following structure:
{
  lua_shared_dicts = {
    kong = {
      allocated_slabs = "12.0 KiB",
      capacity = "24.0 KiB",
    },
    kong_db_cache = {
      allocated_slabs = "12.0 KiB",
      capacity = "12.0 KiB",
    }
  },
  workers_lua_vms = {
    {
      http_allocated_gc = "1.1 KiB",
      pid = 18004
    },
    {
      http_allocated_gc = "1.1 KiB",
      pid = 18005
    }
  }
}
```



## kong.node.get_hostname()

Returns the name used by the local machine.

**Returns**

* `string`:  The local machine hostname.


**Usage**

``` lua
local hostname = kong.node.get_hostname()
```


