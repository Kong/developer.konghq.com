<!---shared with plugins that accept custom lua code --->

Sandboxing imposes several limitations on how custom Lua code can be executed,
for heightened security. The Lua (or LuaJIT) language itself is not limited — only the available
environment and the set of usable modules are restricted.

The limitations can be adjusted with the `untrusted_lua=off|strict|lax|sandbox|on` setting.

See the [sandboxing reference](/gateway/sandboxing/) for more information.
