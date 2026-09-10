The {{include.name}} Policy can run custom Lua code in any of the following [phases](/gateway/entities/plugin/#plugin-contexts) of {{site.ai_gateway}}'s request lifecycle:
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

To run the {{include.name}} Policy in a specific phase, use a `config.PHASE_NAME` parameter.
For example, to run the Policy in the `header_filter` phase, use `config.header_filter`.

You can also run the Policy in multiple phases at once by setting more than one phase parameter in `config`.
