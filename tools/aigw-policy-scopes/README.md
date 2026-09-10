# aigw-policy-scopes

Fetches the available policies (and their scopes) for an AI Gateway instance from the Konnect API and writes them to `app/_data/policies/ai-gateway/scopes.json` so the site can render them.

## Usage

```bash
node tools/aigw-policy-scopes/fetch-scopes.js \
  --konnect-token <KONNECT_PAT> \
  --aigw-id <AI_GATEWAY_ID> \
  [--domain com]
```

Or via the npm script:

```bash
cd tools/aigw-policy-scopes
npm run fetch-scopes -- --konnect-token <KONNECT_PAT> --aigw-id <AI_GATEWAY_ID>
```

### Arguments

| Flag | Env var | Required | Default | Description |
|------|---------|----------|---------|-------------|
| `--konnect-token` | `KONNECT_TOKEN` | yes | — | Konnect personal access token (sent as `Authorization: Bearer`). |
| `--aigw-id` | `AIGW_ID` | yes | — | The AI Gateway instance ID. |
| `--domain` | `KONNECT_DOMAIN` | no | `com` | The Konnect TLD (`com`, `tech`, etc.). The host is built as `us.api.konghq.<domain>`. |

## What it does

1. Calls `GET https://us.api.konghq.<domain>/v1/ai-gateways/<aigw-id>/available-policies`.
2. Extracts the `data` array from the response.
3. Writes it (pretty-printed JSON) to `app/_data/policies/ai-gateway/scopes.json`, creating the directory if needed.

The resulting file looks like:

```json
[
  {
    "name": "ace",
    "scopes": ["models", "mcp-servers", "agents", "consumers", "consumer-groups", "global"]
  }
]
```
