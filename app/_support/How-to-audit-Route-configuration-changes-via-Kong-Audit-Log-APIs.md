---
title: Auditing Route configuration changes via Kong Audit Log APIs
content_type: support
description: Use the Kong Enterprise audit log APIs to trace who changed a route and to detect routes created with empty or missing paths.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How to audit Route configuration changes via Kong Audit Log APIs?
related_resources: []
---

## Overview

In large-scale Kong Gateway deployments, teams often automate route provisioning via CI/CD. A common issue arises when routes are created with missing or empty `paths`, leading to 409 Conflict errors during deployment due to route collisions.

## Steps

In environments where multiple teams or pipelines interact with Kong Gateway, it is vital to trace configuration changes, especially for objects like routes. Kong Enterprise provides two audit log endpoints:

1. `/audit/requests`: captures who did what, including HTTP method, user, and payload.
2. `/audit/objects`: captures what data entity was created/updated, with full snapshots.

The script below was built to:

- Help customers identify the RBAC user who made a route change.
- Pinpoint changes to a specific route.
- Enable SRE or Platform teams to perform accountable debugging based on audit trails.

### Script

This script helps identify who created a specific route, or detect routes with empty/missing paths (which can cause conflicts). Output includes the RBAC user, method, workspace, and full route payload.

```bash
#!/bin/bash

BASE="http://localhost:8081"
TOKEN="password"
ROUTE_NAME="$1"
NEXT="/audit/requests"

log() {
    local ts="$1"
    local msg="$2"
    local dt
    dt=$(date -d "@$ts" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -r "$ts" '+%Y-%m-%d %H:%M:%S')
    echo "[$dt] $msg"
}

validate_json() {
    echo "$1" | jq empty >/dev/null 2>&1
}

get_next_page() {
    echo "$1" | jq -r '.next // "null"'
}

process_route_audit() {
    echo "$1" | jq -r --arg name "$2" '
        .data[]?
        | select(.method | test("POST|PUT|PATCH|DELETE"))
        | select(.path | test("/routes"))
        | select(.payload != null)
        | (.payload | fromjson? // {}) as $pl
        | select($pl.name == $name)
        | {
            summary: "User: \(.rbac_user_name // "UNKNOWN") | Workspace: \(.workspace // "N/A") | Request Source: \(.request_source // "N/A") | Method: \(.method) | Path: \(.path) | Route name: \($name) | At: \(.request_timestamp)",
            payload: $pl
        }
        | .summary, (.payload | @json)
    '
}

process_empty_paths_audit() {
    echo "$1" | jq -r '
        .data[]?
        | select(.method | test("POST|PUT|PATCH|DELETE"))
        | select(.path | test("/routes"))
        | select(.payload != null)
        | (.payload | fromjson? // {}) as $pl
        | select(($pl.paths? == null) or ($pl.paths | length == 0))
        | {
            summary: "User: \(.rbac_user_name // "UNKNOWN") | Workspace: \(.workspace // "N/A") | Request Source: \(.request_source // "N/A") | Method: \(.method) | Path: \(.path) | Changed Route has EMPTY or MISSING paths | At: \(.request_timestamp)",
            payload: $pl
        }
        | .summary, (.payload | @json)
    '
}

pretty_print_json() {
    local line="$1"
    if echo "$line" | jq empty >/dev/null 2>&1; then
        echo "Payload:"
        echo "$line" | jq .
        echo "---"
    else
        echo "$line"
    fi
}

main() {
    log "$(date +%s)" "Starting Kong audit query (route filter: '${ROUTE_NAME:-<none>}')"

    while [ "$NEXT" != "null" ]; do
        URL="${BASE}${NEXT}"
        RESP=$(http --body "$URL" "kong-admin-token:$TOKEN")

        if ! validate_json "$RESP"; then
            echo "[ERROR] Invalid JSON response from $URL" >&2
            break
        fi

        if [ -n "$ROUTE_NAME" ]; then
            process_route_audit "$RESP" "$ROUTE_NAME" | while IFS= read -r line; do
                pretty_print_json "$line"
            done
        else
            process_empty_paths_audit "$RESP" | while IFS= read -r line; do
                pretty_print_json "$line"
            done
        fi

        NEXT=$(get_next_page "$RESP")
    done

    log "$(date +%s)" "Audit query completed."
}

main
```

Note: Replace the `BASE` and `PASSWORD` in the script with the Admin API endpoint and the RBAC password/token.

### Setup instructions

1. Save the script as `kong-audit-query.sh`.

1. Make it executable:

   ```bash
   chmod +x kong-audit-query.sh
   ```

1. Ensure Kong audit logging is enabled in your Kong configuration:

   ```bash
   KONG_AUDIT_LOG: "on"
   ```

   Without this, Kong will not emit any audit log events, and the script will return empty results.

### Usage

- To check who created a specific route:

  ```bash
  ./kong-audit-query.sh <route-name>
  ```

- To scan all routes with missing/empty paths:

  ```bash
  ./kong-audit-query.sh
  ```
