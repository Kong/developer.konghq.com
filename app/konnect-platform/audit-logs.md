---
title: "{{site.konnect_short_name}} and {{site.dev_portal}} audit logs"
content_type: reference
layout: reference
breadcrumbs: 
  - /konnect/
products:
    - konnect
    - dev-portal
works_on:
  - konnect

api_specs:
  - konnect/audit-logs

tags:
  - logging
  - audit-logging
search_aliases: 
  - auditing
  - Dev Portal audit logs

description: "Review logs for system events in {{site.konnect_short_name}} and {{site.dev_portal}}."
related_resources:
  - text: "Collect {{site.konnect_short_name}} audit logs"
    url: /how-to/collect-audit-logs/
  - text: "Dedicated Cloud Gateways"
    url: /dedicated-cloud-gateways/
  - text: "{{site.konnect_short_name}} Data Plane logs"
    url: /konnect-platform/audit-logs/
  - text: "{{site.konnect_short_name}} org audit log API"
    url: /api/konnect/audit-logs/v2/
  - text: "{{site.base_gateway}} audit logs"
    url: /gateway/audit-logs/
  - text: "{{site.base_gateway}} logs"
    url: /gateway/logs/

faqs:
  - q: How can I verify {{site.konnect_short_name}} audit log signatures?
    a: |
      {{site.konnect_short_name}} and {{site.dev_portal}} use an [ED25519 signature](https://ed25519.cr.yp.to/) on the audit logs they produce. You can verify the signature in your audit logs to confirm that it's from {{site.konnect_short_name}} instead of a bad actor.

      To do that:
      1. Retrieve the public key from the [audit log JWKS endpoint](/api/konnect/audit-logs/v2/#/operations/get-audit-log-jwks). The public key is stored in the `x` field.
      1. Get an audit log from {{site.konnect_short_name}} and remove the `sig` value. Make sure to save the signature, you'll need it in the next step.
      1. Decode the Base64-encoded signature and private key.
      1. Use your preferred tool (for example, [OpenSSL](https://www.openssl.org/)) to verify the ED25519 signature by using the signature-less audit log entry together with the decoded signature and public key.
  - q: Do {{site.konnect_short_name}} audit logs collect personally identifiable information?
    a: No, {{site.konnect_short_name}} audit logs don't collect any PII. See the [audit log examples](#log-formats) for the information that they do collect.
  - q: How many days of {{site.konnect_short_name}} org audit logs can I recover?
    a: |
      {{site.konnect_short_name}} only collects audit logs from the past seven days, so you can only recover up to seven days of logs from the current date.
---

{:.success}
> This is a reference guide, you can also follow along with our tutorials: 
>* [Collect audit logs for {{site.konnect_short_name}}](/how-to/collect-audit-logs/)
>* [Collect audit logs for {{site.dev_portal}}](/how-to/collect-dev-portal-audit-logs/)
>* [Recover {{site.konnect_short_name}} audit logs](/how-to/recover-konnect-org-audit-logs/)
>* [Recover {{site.dev_portal}} audit logs](/how-to/recover-dev-portal-audit-logs/)

Audit logs can help you detect and respond to potential security incidents when they occur.

Audit logging provides the following benefits:
* **Security**: System events can be used to show abnormalities to be investigated, forensic information related to breaches, or provide evidence for compliance and regulatory purposes.
* **Compliance**: Regulators and auditors may require audit logs to confirm whether certain certification standards are met.
* **Debugging**: Audit logs can help determine the root causes of efficiency or performance issues.
* **Risk management**: Prevent issues or catch them early. 

You can collect audit logs for both the {{site.konnect_short_name}} org and [{{site.dev_portal}}](/dev-portal/) using a webhook you configure. 
For {{site.konnect_short_name}} org audit logs, you can also use an [audit log pull](#audit-log-pull-using-the-konnect-api) to retrieve logs on demand from the API.

## Audit log events

{{site.konnect_short_name}} captures three types of events.
Use the `name` field to reliably identify which of the three event types a log entry belongs to:

<!--vale off-->
{% table %}
columns:
  - title: Event type
    key: event_type
  - title: Org audit logs
    key: org_audit_logs
  - title: "{{site.dev_portal}} audit logs"
    key: dev_portal_audit_logs
  - title: "`name` value"
    key: name_value
rows:
  - event_type: Authentication
    org_audit_logs: "This is triggered when a user attempts to log into the {{site.konnect_short_name}} web application or use the {{site.konnect_short_name}} API via a personal access token. Also triggered when a system account access token is used."
    dev_portal_audit_logs: Triggered when a user logs in to the {{site.dev_portal}}.
    name_value: "`AUTHENTICATION_OUTCOME_*`"
  - event_type: Authorization
    org_audit_logs: "Triggered when a permission check is made for a user or system account against a resource."
    dev_portal_audit_logs: Not collected, use the org audit log.
    name_value: "`Authz.*`"
  - event_type: Access logs
    org_audit_logs: "Triggered when a request is made to the {{site.konnect_short_name}} API."
    dev_portal_audit_logs: Not collected, use the org audit log.
    name_value: "`Ingress`"
{% endtable %}
<!--vale on-->

{{site.konnect_short_name}} retains audit logs for 7 days. After 7 days, {{site.konnect_short_name}} permanently deletes them and you cannot recover them.

{:.info}
> * {{site.dev_portal}} audit logs don't collect authorization and access events by design. You can view {{site.dev_portal}} entity creation, edits, and approved state changes from the {{site.konnect_short_name}} audit logs. 
> * Don't rely on `event_class_id` to identify the log type. Its meaning differs per event type.
> For authorization logs, it's the name of whichever Kong platform service performed the authorization check, not a fixed enum value.

Every log entry, regardless of type, follows the same CEF header format:

```
{timestamp} konghq.com CEF:0|{Vendor}|{Product}|{Version}|{Event Class ID}|{Name}|{Severity}|{Extensions}
```
{:.no-copy-code.wrap}

`Vendor` is always `KongInc` and `Version` is always `1.0`. `Product` is `Konnect` for {{site.konnect_short_name}} events and `Dev-Portal` for {{site.dev_portal}} events.

## Audit log webhook status

You can view the webhook status in the UI or via [the API](/api/konnect/audit-logs/#/operations/get-audit-log-webhook-status) for the {{site.konnect_short_name}} org audit logs and {{site.dev_portal}} audit logs:

* To view the {{site.konnect_short_name}} org audit logs webhook status in the UI, navigate to **Organization > Audit Log Setup**, and click the **{{site.konnect_short_name}}** tab.
* To view the {{site.dev_portal}} audit log status in the UI, navigate to your {{site.dev_portal}}, click **Settings**, and click the **Audit log** tab.

The following table describes the webhook statuses:

<!--vale off-->
{% table %}
columns:
  - title: Attribute
    key: attribute
  - title: Description
    key: description
rows:
  - attribute: "`last_attempt_at`"
    description: "The last time {{site.konnect_short_name}} tried to send data to your webhook"
  - attribute: "`last_response_code`"
    description: "The last response code from your webhook"
  - attribute: "`webhook_enabled`"
    description: "The desired status of the webhook (from `audit-log-webhook.enabled`)"
  - attribute: "`webhook_status`"
    description: "The actual status of the webhook"
{% endtable %}
<!--vale on-->

A combination of `webhook_enabled` and `webhook_status` give a full picture of webhook status:

<!--vale off-->
{% table %}
columns:
  - title: "`webhook_enabled`"
    key: webhook_enabled
  - title: "`webhook_status`"
    key: webhook_status
  - title: Description
    key: description
rows:
  - webhook_enabled: "`true`"
    webhook_status: "`active`"
    description: "{{site.konnect_short_name}} is ready to send data to the webhook. Either no attempts have been made yet (`last_attempt_at` is not set), or the last attempt was successful."
  - webhook_enabled: "`true`"
    webhook_status: "`inactive`"
    description: "Last attempt to send data failed, but the webhook is still enabled. This usually means that there was an error in the endpoint or the SIEM provider went down that caused the logs to stop streaming."
  - webhook_enabled: "`false`"
    webhook_status: "`active`"
    description: "Webhook config is saved. {{site.konnect_short_name}} is not shipping data to it per webhook configuration."
  - webhook_enabled: "`false`"
    webhook_status: "`inactive`"
    description: "Last attempt to send data failed, and customer has turned off the webhook."
  - webhook_enabled: "`false`"
    webhook_status: "`unconfigured`"
    description: "The webhook for this region has not been configured yet."

{% endtable %}
<!--vale on-->

## Log formats

{{site.konnect_short_name}} delivers log events in [ArcSight CEF Format](https://docs.centrify.com/Content/IntegrationContent/SIEM/arcsight-cef/arcsight-cef-format.htm) , JSON, or CrowdStrike Parsing Standard (CPS). You may specify which format to use in the audit log webhook endpoints.

Webhook calls include a batch of events. Each event is formatted in either CEF or JSON and separated by a newline. The `Content-Type` is `text/plain`.

To minimize payload size, the message body is compressed. The `Content-Encoding` is `application/gzip`.

All log entries include the following attributes:

<!--vale off-->
{% table %}
columns:
  - title: Property
    key: property
  - title: Description
    key: description
rows:
  - property: Timestamp
    description: Time and date of the event in UTC.
  - property: "`rt`"
    description: Milliseconds since Unix epoch.
  - property: "`src`"
    description: The IP address of the request originator.
  - property: "`org_id`"
    description: The originating organization ID.
  - property: "`principal_id`"
    description: The user ID of the user that performed the action.
  - property: "`principal_name`"
    description: "The resolved display name of the principal. Present only when configured."
  - property: "`kong_initiated`"
    description: "Boolean indicating whether the action was performed by Kong internally. Present on access and authorization logs only, and omitted (not `false`) for user-initiated events."
  - property: "`trace_id`"
    description: The correlation ID of the request. Use this value to find all log entries for a given request.
  - property: "`user_agent`"
    description: "The user agent of the request: application, operating system, vendor, and version."
  - property: "`sig`"
    description: An ED25519 signature. Present only when signing is configured.
{% endtable %}
<!--vale on-->

### Authentication logs

Authentication attempts and their outcomes are logged whenever a user logs in to the {{site.konnect_short_name}} application or the {{site.dev_portal}} either through the UI or the Konnect API.

Example log entry:

{% navtabs "logs" %}
{% navtab "{{site.konnect_short_name}} (CEF)" %}
```
2025-05-19T00:03:39Z
konghq.com CEF:0|ExampleOrg|Konnect|1.0|AUTHENTICATION_TYPE_PAT|AUTHENTICATION_OUTCOME_SUCCESS|0|rt=3958q3097698
src=127.0.0.1
request=/api/v1/personal-access-tokens/introspect
success=true
org_id=b065b594-6afc-4658-9101-5d9cf3f36b7b
principal_id=87655c36-8d63-48fe-9a1e-53b28dfbc19b
trace_id=3895213347334635099
user_agent=grpc-go/1.51.0
sig=N_4q2pCgeg0Fg4oGJSfUWKScnTCiC79vq8PIX6Sc_rwaxdWKpVfPwkW45yK_oOFV9gHOmnJBffcB1NmTSwRRDg
```
{:.no-copy-code.wrap}

{% endnavtab %}
{% navtab "{{site.konnect_short_name}} (JSON)" %}
```json
{
    "cef_version": 0,
    "event_class_id": "AUTHENTICATION_TYPE_BASIC",
    "event_product": "Konnect",
    "event_ts": "2025-05-16T00:28:01Z",
    "event_vendor": "KongInc",
    "event_version": "1.0",
    "name": "AUTHENTICATION_OUTCOME_SUCCESS",
    "org_id": "b065b594-6afc-4658-9101-5d9cf3f36b7b",
    "principal_id": "87655c36-8d63-48fe-9a1e-53b28dfbc19b",
    "request": "/api/v1/authenticate",
    "rt": "1684524079524",
    "severity": 0,
    "sig": "N_4q2pCgeg0Fg4oGJSfUWKScnTCiC79vq8PIX6Sc_rwaxdWKpVfPwkW45yK_oOFV9gHOmnJBffcB1NmTSwRRDg",
    "src": "127.0.0.6",
    "success": "true",
    "trace_id": 6891110586028963295,
    "user_agent": "grpc-node-js/1.8.10"
}
```
{:.no-copy-code.wrap}

{% endnavtab %}
{% navtab "{{site.dev_portal}} (CEF)" %}
```
2025-06-23T14:28:47Z
konghq.com CEF:0|KongInc|Dev-Portal|1.0|AUTHENTICATION_TYPE_BASIC|AUTHENTICATION_OUTCOME_SUCCESS|0|rt=1750688927556
src=172.71.232.22
request=/api/v2/developer/authenticate
success=true
org_id=998db3e4-5cb7-4dd5-b51c-9878096a6999
portal_id=3e551b39-227d-4297-b911-e68fd5d77c17
principal_id=a3d2699a-0ed3-4417-bb10-d8e74a1513a4
trace_id=3360194145499877252
user_agent=
sig=XQC3OSFxLbi5dy2-o4xAXHT-x8oW5Df-zVsACWQLMU9Q-sPnEyk5CVs4JHwuRcwO0QNLsNaP1wsyrXYPeneXDQ
```
{:.no-copy-code.wrap}

{% endnavtab %}
{% navtab "{{site.dev_portal}} (JSON)" %}
```json
{
    "cef_version": 0,
    "event_class_id": "AUTHENTICATION_TYPE_BASIC",
    "event_product": "Dev-Portal",
    "event_ts": "2025-06-23T14:28:47Z",
    "event_vendor": "KongInc",
    "event_version": "1.0",
    "name": "AUTHENTICATION_OUTCOME_SUCCESS",
    "org_id": "998db3e4-5cb7-4dd5-b51c-9878096a6999",
    "portal_id": "3e551b39-227d-4297-b911-e68fd5d77c17",
    "principal_id": "a3d2699a-0ed3-4417-bb10-d8e74a1513a4",
    "request": "/api/v2/developer/authenticate",
    "rt": "1750688927556",
    "severity": 0,
    "sig": "XQC3OSFxLbi5dy2-o4xAXHT-x8oW5Df-zVsACWQLMU9Q-sPnEyk5CVs4JHwuRcwO0QNLsNaP1wsyrXYPeneXDQ",
    "src": "172.71.232.22",
    "success": "true",
    "trace_id": 3360194145499877252,
    "user_agent": ""
}
```
{:.no-copy-code.wrap}

{% endnavtab %}
{% endnavtabs %}

In addition to the defaults, each authentication log entry also contains the following attributes:

<!--vale off-->
{% table %}
columns:
  - title: Property
    key: property
  - title: Description
    key: description
rows:
  - property: "`AUTHENTICATION_TYPE`"
    description: |
      Can be one of the following:
      <br> - `AUTHENTICATION_TYPE_INVALID`: Unknown or unset
      <br> - `AUTHENTICATION_TYPE_BASIC`: Basic email and password authentication
      <br> - `AUTHENTICATION_TYPE_SSO`: Authentication with single sign-on (SSO)
      <br> - `AUTHENTICATION_TYPE_PAT`: Authentication with a personal access token
      <br> - `AUTHENTICATION_TYPE_SPAT`: Authentication with a system personal access token
      <br> - `AUTHENTICATION_TYPE_GOOGLE`: Authentication with Google OAuth
      <br> - `AUTHENTICATION_TYPE_GITHUB`: Authentication with GitHub OAuth
      <br> - `AUTHENTICATION_TYPE_WINDOWSLIVE`: Authentication with Microsoft/Windows Live
      <br> - `AUTHENTICATION_TYPE_FEDERATED`: Authentication with a federated identity provider
  - property: "`AUTHENTICATION_OUTCOME`"
    description: |
      Can be one of the following:
      <br> - `AUTHENTICATION_OUTCOME_SUCCESS`: Authentication is successful
      <br> - `AUTHENTICATION_OUTCOME_NOT_FOUND`: User wasn't found
      <br> - `AUTHENTICATION_OUTCOME_INVALID_PASSWORD`: Invalid password specified
      <br> - `AUTHENTICATION_OUTCOME_TOKEN_EXPIRED`: Token has expired
      <br> - `AUTHENTICATION_OUTCOME_LOCKED`: User account is locked
      <br> - `AUTHENTICATION_OUTCOME_DISABLED`: User account has been disabled
      <br> - `AUTHENTICATION_OUTCOME_INVALID`: Unknown or unset
  - property: "`severity`"
    description: |
      Reflects the authentication outcome:
      <br> - `0`: Authentication succeeded
      <br> - `1`: Credential failure (user not found, invalid password, or expired token)
      <br> - `6`: Account locked or disabled
      <br> - `7`: Unknown or invalid authentication state
  - property: "`success`"
    description: "`true` or `false`, depending on whether authentication was successful or not."
  - property: "`portal_id`"
    description: "The ID of the {{site.dev_portal}} the event occurred in. Only present in {{site.dev_portal}} authentication log entries."
{% endtable %}
<!--vale on-->

### Authorization logs

Authorization log entries are created for every permission check in {{site.konnect_short_name}}.

The `name` field always starts with `Authz.` followed by the resource path that was checked:

<!--vale off-->
{% table %}
columns:
  - title: "`name` pattern"
    key: name_pattern
  - title: When
    key: when
rows:
  - name_pattern: "`Authz.organization`"
    when: Organization-level operation
  - name_pattern: "`Authz.control-planes/*`"
    when: Wildcard across all control planes
  - name_pattern: "`Authz.control-planes/{id}`"
    when: Specific control plane
{% endtable %}
<!--vale on-->

For authorization logs, `event_class_id` is just the name of whichever Kong platform service performed the check, not a fixed enum.
Use `name` to identify the checked resource.

Example log entry:

{% navtabs "logs" %}
{% navtab "CEF" %}
```
2025-05-19T00:03:39Z
konghq.com CEF:0|ExampleOrg|Konnect|1.0|konnect|Authz.portals|1|rt=16738287345642
src=127.0.0.6
action=retrieve
granted=true
org_id=b065b594-6afc-4658-9101-5d9cf3f36b7b
principal_id=87655c36-8d63-48fe-9a1e-53b28dfbc19b
actor_id=
trace_id=8809518331550410226
user_agent=grpc-node/1.24.11 grpc-c/8.0.0 (linux; chttp2; ganges)
sig=N_4q2pCgeg0Fg4oGJSfUWKScnTCiC79vq8PIX6Sc_rwaxdWKpVfPwkW45yK_oOFV9gHOmnJBffcB1NmTSwRRDg
```
{:.no-copy-code.wrap}

{% endnavtab %}
{% navtab "JSON" %}
```json
{
    "action": "list",
    "cef_version": 0,
    "event_class_id": "konnect",
    "event_product": "Konnect",
    "event_ts": "2025-05-16T00:28:01Z",
    "event_vendor": "KongInc",
    "event_version": "1.0",
    "granted": true,
    "name": "Authz.portals",
    "org_id": "b065b594-6afc-4658-9101-5d9cf3f36b7b",
    "principal_id": "87655c36-8d63-48fe-9a1e-53b28dfbc19b",
    "rt": "1684196881193",
    "severity": 1,
    "sig": "N_4q2pCgeg0Fg4oGJSfUWKScnTCiC79vq8PIX6Sc_rwaxdWKpVfPwkW45yK_oOFV9gHOmnJBffcB1NmTSwRRDg",
    "src": "127.0.0.6",
    "trace_id": 6891110586028963295,
    "user_agent": "grpc-node-js/1.8.10"
}
```
{:.no-copy-code.wrap}

{% endnavtab %}
{% endnavtabs %}

In addition to the defaults, each authorization log entry also contains the following attributes:

<!--vale off-->
{% table %}
columns:
  - title: Property
    key: property
  - title: Description
    key: description
rows:
  - property: "`action`"
    description: "The type of action the user performed on the resource. For example, `retrieve`, `list`, or `edit`."
  - property: "`granted`"
    description: "Boolean indicating whether the authorization was granted or not."
  - property: "`severity`"
    description: "`1` when `granted` is `true`, `6` when `granted` is `false`."
{% endtable %}
<!--vale on-->

### Access logs

Access logs include information about create, update, and delete requests to the {{site.konnect_short_name}} API.

Example log entry:

{% navtabs "logs" %}
{% navtab "CEF" %}
```
2025-05-16T20:09:54Z
konghq.com CEF:0|KongInc|Konnect|1.0|KongGateway|Ingress|1|rt=1684267794226
src=127.0.0.6
request=/konnect-api/api/vitals/v1/explore
act=POST
status=200
org_id=b065b594-6afc-4658-9101-5d9cf3f36b7b
principal_id=87655c36-8d63-48fe-9a1e-53b28dfbc19b
user_agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36
trace_id=1146381705542353508
query={"end":"1684270800","start":"1684098000"}
sig=JxJaQG3Bozrb5WdHE_Y0HaOsim2F1Xsq_bCfk71VgsfldkLAD_SF234cnKNS
```
{:.no-copy-code.wrap}

{% endnavtab %}
{% navtab "JSON" %}
```json
{
    "act": "POST",
    "cef_version": 0,
    "event_class_id": "KongGateway",
    "event_product": "Konnect",
    "event_ts": "2025-05-16T00:28:01Z",
    "event_vendor": "KongInc",
    "event_version": "1.0",
    "name": "Ingress",
    "org_id": "b065b594-6afc-4658-9101-5d9cf3f36b7b",
    "principal_id": "87655c36-8d63-48fe-9a1e-53b28dfbc19b",
    "query": "{}",
    "request": "/konnect-api/api/control_planes/1c026712-c17d-4e30-ac27-53a6cdc56b9c/services",
    "rt": "1684196881193",
    "severity": 1,
    "src": "127.0.0.6",
    "status": 201,
    "trace_id": 6891110586028963295,
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
    "sig": "N_4q2pCgeg0Fg4oGJSfUWKScnTCiC79vq8PIX6Sc_rwaxdWKpVfPwkW45yK_oOFV9gHOmnJBffcB1NmTSwRRDg",
}
```
{:.no-copy-code.wrap}

{% endnavtab %}
{% endnavtabs %}

In addition to the defaults, each access log entry also contains the following attributes:

<!--vale off-->
{% table %}
columns:
  - title: Property
    key: property
  - title: Description
    key: description
rows:
  - property: "request"
    description: "The endpoint that was called."
  - property: "query"
    description: "The request query parameters, if any."
  - property: "act"
    description: "The HTTP request method; for example, `POST`, `PATCH`, `PUT`, or `DELETE`."
  - property: "status"
    description: "The HTTP response code; for example, `200` or `403`."
  - property: "`severity`"
    description: |
      Reflects the HTTP response:
      <br> - `1`: Default
      <br> - `6`: HTTP 401 or 403 (authentication failure at the gateway)
      <br> - `10`: HTTP 500 (server error)
{% endtable %}
<!--vale on-->

### JSON and CPS field mapping

The same field values apply across CEF, JSON, and CPS. In JSON and CPS, the CEF header fields are mapped to flat top-level JSON keys:

<!--vale off-->
{% table %}
columns:
  - title: CEF header field
    key: cef_field
  - title: JSON key
    key: json_key
rows:
  - cef_field: Timestamp
    json_key: "`event_ts`"
  - cef_field: Device vendor
    json_key: "`event_vendor`"
  - cef_field: Device product
    json_key: "`event_product`"
  - cef_field: Device version
    json_key: "`event_version`"
  - cef_field: Device event class ID
    json_key: "`event_class_id`"
  - cef_field: Name
    json_key: "`name`"
  - cef_field: Severity
    json_key: "`severity`"
{% endtable %}
<!--vale on-->

Extension values are typed in JSON: 
* `rt`, `status`, and `severity` are `int64`
* `success` and `granted` are `bool`
* All other extensions are `string`

CPS wraps the same object under `{"event": {...}}`.

## Recommended alert conditions

Use the following field conditions to build alerting and monitoring rules in your SIEM:

<!--vale off-->
{% table %}
columns:
  - title: Log type
    key: log_type
  - title: Field condition
    key: field_condition
  - title: Signal
    key: signal
rows:
  - log_type: Access
    field_condition: "`severity` = `10`"
    signal: HTTP 500, server error
  - log_type: Access
    field_condition: "`severity` = `6`"
    signal: HTTP 401 or 403, authentication failure at the gateway
  - log_type: Authentication
    field_condition: "`name` = `AUTHENTICATION_OUTCOME_LOCKED`"
    signal: Account locked
  - log_type: Authentication
    field_condition: "`name` = `AUTHENTICATION_OUTCOME_DISABLED`"
    signal: Attempt on a disabled account
  - log_type: Authentication
    field_condition: "`severity` = `7`"
    signal: Unknown or invalid authentication state
  - log_type: Authentication
    field_condition: "`success` = `false` at volume"
    signal: Potential brute force or credential stuffing
  - log_type: Authorization
    field_condition: "`granted` = `false`"
    signal: Authorization denial
  - log_type: All
    field_condition: "`kong_initiated` = `true`"
    signal: System-generated event, exclude from user-action alerts
{% endtable %}
<!--vale on-->

## Audit log pull using the {{site.konnect_short_name}} API

Retrieve a list of organization audit logs with an audit log pull, by sending a `GET` request to the `/audit-logs` endpoint. 
An audit log pull covers the same three event types as the audit log webhook: authentication, authorization, and access logs. 
Because you initiate the request, you don't need to open inbound ports, expose a publicly accessible endpoint, or set up a proxy to relay logs.

### Filter audit logs

You can narrow the audit logs returned in the response using the `filter` query parameter:

<!--vale off-->
{% table %}
columns:
  - title: Filter
    key: filter
  - title: Example
    key: example
  - title: Description
    key: description
rows:
  - filter: "`filter[ts][gte]`"
    example: "`?filter%5Bts%5D%5Bgte%5D=2026-07-21T00:00:00Z`"
    description: "An RFC3339 lower bound (inclusive) on the audit log timestamp. Defaults to seven days before `filter[ts][lte]` when omitted."
  - filter: "`filter[ts][lte]`"
    example: "`?filter%5Bts%5D%5Blte%5D=2026-07-28T00:00:00Z`"
    description: "An RFC3339 upper bound (inclusive) on the audit log timestamp. Defaults to the current time when omitted."
  - filter: "`filter[type]`"
    example: "`?filter%5Btype%5D=authentication`"
    description: "Filters audit logs by type. Can be one of `authentication`, `authorization`, or `gateway_access`. Omit this parameter to return all types."
{% endtable %}
<!--vale on-->

{:.info}
> {{site.konnect_short_name}} only retains audit logs for seven days, so you can only pull logs from the past seven days. 

### Paginate results

An audit log pull uses cursor-based pagination. Each response includes a `meta.page` object with `next` and `previous` cursors that you can use to page through results:

<!--vale off-->
{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Description
    key: description
rows:
  - parameter: "`page[size]`"
    description: "The maximum number of items to include per page. Defaults to 20, with a maximum of 1000."
  - parameter: "`page[after]`"
    description: "Requests the next page of data, starting with the item after this cursor."
  - parameter: "`page[before]`"
    description: "Requests the previous page of data, starting with the item before this cursor."
{% endtable %}
<!--vale on-->

To collect a full set of logs, make an initial request, then follow the `next` cursor from the `meta.page` object until no further pages remain.

### Example audit log pull request

The following example request pulls authentication logs, starting on July 21, 2026, in pages of 100 entries:

<!--vale off-->
{% konnect_api_request %}
url: /v3/audit-logs?filter%5Bts%5D%5Bgte%5D=2026-07-21T00:00:00Z&filter%5Btype%5D=authentication&page%5Bsize%5D=100
method: GET
status_code: 200
{% endkonnect_api_request %}
{:.wrap}
<!--vale on-->

Each entry in the response is signed in the `sig` field, just like logs delivered by the webhook.

## View past audit logs

You can view past audit logs in two ways:
* **Using the webhook:** Create a [replay job](#konnect-replay-job) to recover audit logs that were collected up to 7 days ago via the webhook. You can replay {{site.konnect_short_name}} and {{site.dev_portal}} audit logs.
* **Using an audit log API poll:** If you just need to read past organizational audit logs that were collected up to 7 days ago, even ones a webhook never received, you can use an [audit log pull](#audit-log-pull-using-the-konnect-api). 

### Recover audit logs

You can use replay jobs in {{site.konnect_short_name}} to recover audit logs. 
These are useful when you've missed audit log entries due to an error or a misconfigured audit log webhook.

You can use either the {{site.konnect_short_name}} UI or the {{site.konnect_short_name}} API to configure a replay job.

#### {{site.konnect_short_name}} replay job

{% navtabs "replay-job" %}
{% navtab "UI" %}
1. Select your {{site.konnect_short_name}} org.
1. Click [**Manage Organization**](https://cloud.konghq.com/organization).
1. Click the **Audit Logs Setup** tab.
1. Do one of the following:
   {% navtabs "portal-konnect" %}
   {% navtab "Konnect" %}
   1. Click the **Konnect** tab.
   1. Navigate to the region you want to configure the replay job for.
   1. Click the **Replay** tab.
   1. Select a time frame from the **Replay Time Range** dropdown menu.
   1. Click **Send Replay**.
   {% endnavtab %}
   {% navtab "{{site.dev_portal}}" %}
   1. Click the **{{site.dev_portal}}** tab.
   1. Click the {{site.dev_portal}} you want to configure the replay job for.
   1. Click the **Replay** tab.
   1. Select a time frame from the **Replay Time Range** dropdown menu.
   1. Click **Send Replay**.
   {% endnavtab %}
   {% endnavtabs %}
{% endnavtab %}
{% navtab "API" %}
Send a `PUT` request to the `/audit-log-replay-job` endpoint:
<!--vale off-->
{% konnect_api_request %}
url: /v3/audit-log-replay-job
status_code: 201
method: PUT
body:
  start_at: $UTF_START_TIME
  end_at: $UTF_END_TIME
{% endkonnect_api_request %}
<!--vale on-->

{:.info}
> **Note:** The replay job is always sent to the webhook that is currently configured for the organization or {{site.dev_portal}} at the time the replay job is executed. There is one webhook configuration per region.
{% endnavtab %}
{% endnavtabs %}

#### Replay job status

Once you configure a replay job, it displays one of the following statuses. 

A replay job can be in one of the following statuses:

<!--vale off-->
{% table %}
columns:
  - title: Status
    key: status
  - title: Description
    key: description
rows:
  - status: "Unconfigured"
    description: The job has not been set up. This is the job's initial state.
  - status: "Accepted"
    description: The job has been accepted for scheduling.
  - status: "Pending"
    description: The job has been scheduled.
  - status: "Running"
    description: The job is in progress. When a replay job is `running`, a request to update the job will return a `409` response code until it has completed or failed.
  - status: "Completed"
    description: The job has finished with no errors.
  - status: "Failed"
    description: The job has failed.
{% endtable %}
<!--vale on-->

Once the replay job is marked as Complete, the audit logs are re-sent to a configured SIEM provider webhook for the specified date and time range.
