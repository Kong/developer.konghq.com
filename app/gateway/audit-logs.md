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

description: "{{site.base_gateway}} audit logs provide details about HTTP requests handled by the Admin API, as well as database changes."

related_resources:
  - text: "Secure {{site.base_gateway}}"
    url: /gateway/security/
  - text: "{{site.base_gateway}} logs"
    url: /gateway/logs/
#  - text: "{{site.base_gateway}} debugging"
#    url: /gateway/debug/
  - text: "{{site.konnect_short_name}} logs"
    url: /konnect-logs/
  - text: Sign {{site.base_gateway}} audit logs with an RSA key
    url: /how-to/sign-gateway-audit-logs/

works_on:
  - on-prem
---

You can generate {{site.base_gateway}} audit logs using the Admin API.
Audit logs provide details about:
* HTTP requests handled by the Admin API
* Database changes

This allows cluster administrators to keep track of changes made to the cluster configuration throughout its lifetime, aiding in compliance efforts and providing valuable data points during forensic investigations. 

Because every audit log entry is made available via {{site.base_gateway}}’s Admin API, you can send audit log entries into existing logging warehouses, SIEM solutions, or other remote services for duplication and inspection.

## What type of events are included in audit logs?

{{site.base_gateway}} includes details about the following in audit logs:

<!--vale off-->
{% table %}
columns:
  - title: Event
    key: event
  - title: Fields
    key: fields
  - title: Endpoint
    key: endpoint
  - title: Description
    key: description
rows:
  - event: "[RBAC](/gateway/entities/rbac/)"
    fields: |
      `rbac_user_id`
      <br>
      `rbac_user_name`
    endpoint: "[`/audit/requests`](/api/gateway/admin-ee/#/operations/get-audit-requests)"
    description: |
      When RBAC is enforced, the RBAC user’s UUID will be written to the `rbac_user_id` field in the audit log entry, and the username will be written to the `rbac_user_name` field.
  - event: "[Workspace](/gateway/entities/workspace/)"
    fields: "`workspace`"
    endpoint: "[`/audit/requests`](/api/gateway/admin-ee/#/operations/get-audit-requests)"
    description: "The `workspace` field is the UUID of the Workspace with which the request is associated."
  - event: "[Kong Manager login](/gateway/kong-manager/)"
    fields: |
       `"request_source": "kong-manager"`
       <br>
       `"method": "GET", "path": "/auth"`
    endpoint: "[`/audit/requests`](/api/gateway/admin-ee/#/operations/get-audit-requests)"
    description: |
      The `request_source` field tells you that the action occurred in Kong Manager, and the `GET` method and `/auth` path indicate a login event.
  - event: "[Kong Manager logout](/gateway/kong-manager/)"
    fields: |
      `"request_source": "kong-manager"`
      <br>
      `"method": "DELETE", "path": "/auth?session_logout=true"`
    endpoint: "[`/audit/requests`](/api/gateway/admin-ee/#/operations/get-audit-requests)"
    description: "The `DELETE` method and `/auth?session_logout=true` path indicate a logout event."
  - event: "Database entity changes"
    fields: |
      `payload` (contains changed objects)
      <br>
      `request_id`
    endpoint: "[`/audit/objects`](/api/gateway/admin-ee/#/operations/get-audit-objects)"
    description: 
      Entries for all insertions, updates, and deletions to the cluster database. Database update audit logs are also associated with Admin API request unique IDs. Object audit entries contain information about the entity updated, including the entity body itself, its database primary key, and the type of operation performed (create, update, or delete). It's also associated with the `request_id` field.
{% endtable %}
<!--vale on-->

## Enable audit logging

Audit logging is disabled by default. Configure it with the [`audit_log`](/gateway/configuration/#audit-log) {{site.base_gateway}} configuration in `kong.conf`:

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
You can use the following configuration options in `kong.conf`:

<!--vale off-->
{% kong_config_table %}
config:
  - name: audit_log_ignore_methods
  - name: audit_log_ignore_paths
{% endkong_config_table %}
<!--vale on-->

For example, if you set `audit_log_ignore_methods = GET,OPTIONS`, you won't get any audit log entries for `GET` or `OPTIONS` requests.

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

As with request audit logs, you may want to skip generation of audit logs
for certain database tables:

<!--vale off-->
{% kong_config_table %}
config:
  - name: audit_log_ignore_tables
{% endkong_config_table %}
<!--vale on-->

For example, `audit_log_ignore_tables = consumers` would skip generating audit logs for changes to the Consumers table.

## Audit log retention

Audit log records are kept in the database for a duration defined by the
[`audit_log_record_ttl`](/gateway/configuration/#audit-log-record-ttl)
{{site.base_gateway}} configuration property. Records in the database older than the seconds configured in `audit_log_record_ttl` are automatically purged.

PostgreSQL purges records via the stored procedure that is executed on insert into the 
record database.
Therefore, request audit records may exist in the database longer than the configured TTL 
if no new records are inserted to the audit table following the expiration timestamp.

## Sign audit logs with a private RSA key

To provide non-repudiation, audit logs may be signed with a private RSA key by using [`audit_log_signing_key`](/gateway/configuration/#audit-log-signing-key). 
When enabled, a lexically sorted representation of each audit log entry is signed by
the defined private key, and the signature is stored in an additional field within
the record itself. The public key should be stored elsewhere and can be used
later to validate the signature of the record. For more information, see [Sign {{site.base_gateway}} audit logs with an RSA key](/how-to/sign-gateway-audit-logs/).


