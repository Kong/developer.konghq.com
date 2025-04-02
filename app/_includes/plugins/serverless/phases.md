The {{include.name}} plugin can run custom Lua code in any of the following [phases](/gateway/entities/plugin/#plugin-contexts) in {{site.base_gateway}}'s lifecycle:
* `access`
* `body_filter`
* `certificate`
* `header_filter`
* `log`
* `rewrite`
* `ws_client_frame`
* `ws_close`
* `ws_handshake`
* `ws_upstream_frame`

To run the {{include.name}} plugin in a specific phase, use a `config.{phase_name}` parameter.
For example, to run the plugin in the `header_filter` phase, use `config.header_filter`. 

You can also run the plugin in multiple phases. See [Running {{include.name}} in multiple phases](./examples/run-in-multiple-phases/) for an example.