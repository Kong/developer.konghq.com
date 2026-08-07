# mb-event-dimensions

Extracts the Metering & Billing plugin's emitted CloudEvent field catalog from the
LuaLS annotations in kong-ee `cloudevent.lua`, and detects drift between those fields
and the docs (the `Captured event dimensions` reference on the plugin page).

The fields are declared as `---@class` / `---@field` annotations in
`kong/plugins/metering-and-billing/cloudevent.lua`; `lua-language-server --doc` exports
them to a `doc.json`, which these scripts consume.

## How it works

Requires `Kong/kong-ee` available locally and `lua-language-server` on `PATH`. From the
root of your clone of the dev site repo:

```bash
cd tools/mb-event-dimensions
npm ci
```

Export the annotations to `doc.json` (point `<kong-ee>` at your kong-ee clone):

```bash
mkdir -p /tmp/mb-ws /tmp/mb-out
cp <kong-ee>/kong/plugins/metering-and-billing/cloudevent.lua /tmp/mb-ws/
echo '{ "runtime.version": "LuaJIT", "diagnostics.globals": ["kong","ngx"] }' > /tmp/mb-ws/.luarc.json
lua-language-server --doc /tmp/mb-ws --doc_out_path /tmp/mb-out
```

## How to run it

Extract the catalog (`{ "kong.api_request": [...], "kong.llm_request": [...] }`):

```bash
node extract-catalog.js /tmp/mb-out/doc.json            # prints JSON
node extract-catalog.js /tmp/mb-out/doc.json --out event-fields.snapshot.json
```

Check for drift against the committed snapshot and the rendered data file
(`app/_data/plugins/metering-and-billing.yaml`):

```bash
node check-drift.js /tmp/mb-out/doc.json
```

Exit `0` when everything agrees; exit `1` with a printed diff (added/removed fields) when
the plugin's emitted fields no longer match the snapshot or the docs.

`event-fields.snapshot.json` is the committed baseline. The scheduled workflow
`.github/workflows/watch-mb-cloudevent.yml` runs this check daily; on drift it bumps the
snapshot, opens a PR, and pings the docs maintainers to update the reference.

## Example drift output

New field added (`cache_region`):

```
DRIFT vs snapshot [kong.api_request]:
  + cache_region: string?   (new in cloudevent.lua)
DOC MISMATCH [kong.api_request] (data file vs cloudevent.lua):
  emitted but undocumented:     cache_region

2 problem(s) found — the docs reference needs updating.
```

Field removed (`upstream_status`):

```
DRIFT vs snapshot [kong.api_request]:
  - upstream_status: integer?   (gone from cloudevent.lua)
DOC MISMATCH [kong.api_request] (data file vs cloudevent.lua):
  data-file only (not emitted): upstream_status

2 problem(s) found — the docs reference needs updating.
```

Field type changed (`service_port` `integer?` → `string?`):

```
DRIFT vs snapshot [kong.api_request]:
  ~ service_port: integer? → string?   (type changed)

1 problem(s) found — the docs reference needs updating.
```

Add/remove trip both checks (the field-name set changes); a pure type change trips only the
snapshot check (the data-file cross-check is name-only). All exit `1`.
