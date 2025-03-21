---
title: "{{site.base_gateway}} audit logs"
content_type: reference
layout: reference

products:
    - gateway

tags:
  - logging
  - audit-logging

min_version:
    gateway: '3.4'

description: placeholder

related_resources:
  - text: "Secure {{site.base_gateway}}"
    url: /gateway/security/
  - text: "{{site.base_gateway}} logs"
    url: /gateway/logs/
  - text: "{{site.base_gateway}} debugging"
    url: /gateway/debug/
  - text: "{{site.konnect_short_name}} audit logs"
    url: /konnect-audit-logs/
---

You can generate {{site.base_gateway}} audit logs using the Admin API and the data is written to {{site.base_gateway}}'s database. Audit logs provide details about HTTP requests handled by the Admin API as well as database changes. This allows cluster administrators to keep track of changes made to the cluster configuration throughout its lifetime, aiding in compliance efforts and providing valuable data points during forensic investigations. 

Because every audit log entry is made available via {{site.base_gateway}}’s Admin API, you can send audit log entries into existing logging warehouses, SIEM solutions, or other remote services for duplication and inspection.

## What type of events are included in audit logs?

{{site.base_gateway}} includes details about the following in audit logs:

| Event | Relevant audit log fields | Admin API endpoint | Description |
|-------|------------------|--------------------|-------------|
| [RBAC](/gateway/entities/rbac/) | `rbac_user_id`<br>`rbac_user_name` | [`/audit/requests`](/api/gateway/admin-ee/#/operations/get-audit-requests) | When RBAC is enforced, the RBAC user’s UUID will be written to the `rbac_user_id` field in the audit log entry, and the username will be written to the `rbac_user_name` field. |
| [Workspace](/gateway/entities/workspace/) | `workspace` | [`/audit/requests`](/api/gateway/admin-ee/#/operations/get-audit-requests) | The `workspace` field is the UUID of the Workspace with which the request is associated. |
| [Kong Manager login](/gateway/kong-manager/) | `"request_source": "kong-manager"`<br>`"method": "GET", "path": "/auth"` | [`/audit/requests`](/api/gateway/admin-ee/#/operations/get-audit-requests) | The `request_source` field tells you that the action occurred in Kong Manager, and the `GET` method and `/auth` path indicate a login event. |
| [Kong Manager logout](/gateway/kong-manager/) | `"request_source": "kong-manager"`<br>`"method": "DELETE", "path": "/auth?session_logout=true"` | [`/audit/requests`](/api/gateway/admin-ee/#/operations/get-audit-requests) | The `DELETE` method and `/auth?session_logout=true` path indicate a logout event. |
| Database entity changes | `payload` (contains changed objects)<br>`request_id` | [`/audit/objects`](/api/gateway/admin-ee/#/operations/get-audit-objects) | Entries for all insertions, updates, and deletions to the cluster database. Database update audit logs are also associated with Admin API request unique IDs. Object audit entries contain information about the entity updated, including the entity body itself, its database primary key, and the type of operation performed (create, update, or delete). It's also associated with the `request_id` field. |

## Enable audit logging

Audit logging is disabled by default. Configure it with the [`audit_log`](/gateway/configuration/#audit_log) {{site.base_gateway}} configuration in `kong.conf`:

```bash
audit_log = on
```

Or via environment variables:

```bash
export KONG_AUDIT_LOG=on
```

As with other Kong configurations, changes take effect on [`kong reload`](/how-to/restart-kong-gateway-container/) or `kong restart`.

## Disable audit logging for certain methods, paths, or database entities

You may want to ignore audit log generation for certain Admin API
requests, such as requests to the `/status` endpoint for
health checking, or to ignore requests to a specific path prefix, for example, a given Workspace.

Use the [`audit_log_ignore_methods`](/gateway/configuration/#audit_log_ignore_methods) and
[`audit_log_ignore_paths`](/gateway/configuration/#audit_log_ignore_paths) configuration options:

```
audit_log_ignore_methods = GET,OPTIONS
# don't generate an audit log entry for GET or OPTIONS HTTP requests
audit_log_ignore_paths = /foo,/status,^/services,/routes$,/one/.+/two,/upstreams/
# don't generate an audit log entry for requests that match the above regular expressions
```

As with request audit logs, you may want to skip generation of audit logs
for certain database tables. This is configurable via the
[`audit_log_ignore_tables`](/gateway/configuration/#audit_log_ignore_tables) Kong config option:

```
audit_log_ignore_tables = consumers
# don't generate database audit logs for changes to the Consumers table
```


The values of `audit_log_ignore_paths` are matched via a Perl-compatible regular expression.

For example, when you configure `audit_log_ignore_paths = /foo,/status,^/services,/routes$,/one/.+/two,/upstreams/`, 
the following request paths don't generate an audit log entry in the database:

- `/status`
- `/status/`
- `/foo`
- `/foo/`
- `/services`
- `/services/example/`
- `/one/services/two`
- `/one/test/two`
- `/routes`
- `/plugins/routes`
- `/one/routes/two`
- `/upstreams/`
- `bad400request`

The following request paths generate an audit log entry in the database:

- `/example/services`
- `/routes/plugins`
- `/one/two`
- `/routes/`
- `/upstreams`


## Audit log retention

Audit log records are kept in the database for a duration defined by the
[`audit_log_record_ttl`](/gateway/configuration/#audit_log_record_ttl)
{{site.base_gateway}} configuration property. Records in the database older than the seconds configured in `audit_log_record_ttl` are automatically purged.

PostgreSQL purges records via the stored procedure that is executed on insert into the 
record database.
Therefore, request audit records may exist in the database longer than the configured TTL 
if no new records are inserted to the audit table following the expiration timestamp.

## Sign audit logs with a private RSA key

To provide non-repudiation, audit logs may be signed with a private RSA key by using [`audit_log_signing_key`](/gateway/configuration/#audit_log_signing_key). When
enabled, a lexically sorted representation of each audit log entry is signed by
the defined private key; the signature is stored in an additional field within
the record itself. The public key should be stored elsewhere and can be used
later to validate the signature of the record. For more information, see [Sign {{site.base_gateway}} audit logs with an RSA key](/how-to/sign-gateway-audit-logs/).


