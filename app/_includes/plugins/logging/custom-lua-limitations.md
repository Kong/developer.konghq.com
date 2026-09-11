Lua code runs in a restricted sandbox environment, whose behavior is governed
by the `untrusted_lua` [configuration properties](/gateway/configuration/).

{% include /plugins/sandbox.md %}

Further, as code runs in the context of the log phase, only [PDK](/gateway/pdk/reference/) methods
that can run in said phase can be used.