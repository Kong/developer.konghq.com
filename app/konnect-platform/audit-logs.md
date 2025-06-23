---
title: "{{site.konnect_short_name}} audit logs"
content_type: reference
layout: reference
breadcrumbs: 
  - /konnect/
products:
    - konnect-platform
works_on:
  - konnect

api_specs:
  - konnect/audit-logs

tags:
  - logging
  - audit-logging
search_aliases: 
  - auditing

description: "Review logs for system events in {{site.konnect_short_name}}."
related_resources:
  - text: "Collect {{site.konnect_short_name}} audit logs with SumoLogic"
    url: /how-to/collect-audit-logs-with-sumologic/
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
  - q: How can I verify {{site.konnect_short_name}} audit log signatures
    a: |
      {{site.konnect_short_name}} and Dev Portal use an [ED25519 signature](https://ed25519.cr.yp.to/) on the audit logs they produce. You can verify the signature in your audit logs to confirm that it's from {{site.konnect_short_name}} instead of a bad actor.

      To do that:
      1. Retrieve the public key from the [audit log JWKS endpoint](/api/konnect/audit-logs/v2/#/operations/get-audit-log-jwks). The public key is stored in the `x` field.
      1. Get an audit log from {{site.konnect_short_name}} and remove the `sig` value. Make sure to save the signature, you'll need it in the next step.
      1. Decode the Base64-encoded signature and private key.
      1. Use your preferred tool (for example, [OpenSSL](https://www.openssl.org/)) to verify the ED25519 signature by using the signature-less audit log entry together with the decoded signature and public key.
---


Audit logs can help you detect and respond to potential security incidents when they occur.

Audit logging provides the following benefits:
* **Security**: System events can be used to show abnormalities to be investigated, forensic information related to breaches, or provide evidence for compliance and regulatory purposes.
* **Compliance**: Regulators and auditors may require audit logs to confirm whether certain certification standards are met.
* **Debugging**: Audit logs can help determine the root causes of efficiency or performance issues.
* **Risk management**: Prevent issues or catch them early.


## Configure audit logging

{{site.konnect_short_name}} captures three types of events:

<!--vale off-->
{% table %}
columns:
  - title: Event type
    key: event_type
  - title: Org audit logs
    key: org_audit_logs
rows:
  - event_type: Authentication
    org_audit_logs: "This is triggered when a user attempts to log into the {{site.konnect_short_name}} web application or use the {{site.konnect_short_name}} API via a personal access token. Also triggered when a system account access token is used."
  - event_type: Authorization
    org_audit_logs: "Triggered when a permission check is made for a user or system account against a resource."
  - event_type: Access logs
    org_audit_logs: "Triggered when a request is made to the {{site.konnect_short_name}} API."
{% endtable %}
<!--vale on-->

{{site.konnect_short_name}} retains audit logs for 7 days.

## Audit log webhook status

You can view the webhook status in the UI or via the API for the [{{site.konnect_short_name}} org audit logs](/api/konnect/audit-logs/#/operations/get-audit-log-webhook-status).

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

{{site.konnect_short_name}} delivers log events in [ArcSight CEF Format](https://docs.centrify.com/Content/IntegrationContent/SIEM/arcsight-cef/arcsight-cef-format.htm) or JSON. You may specify which format to use in the audit log webhook endpoints.

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
  - property: "~kong_initiated~"
    description: Whether the action was performed by Kong
  - property: "`trace_id`"
    description: The correlation ID of the request. Use this value to find all log entries for a given request.
  - property: "`user_agent`"
    description: "The user agent of the request: application, operating system, vendor, and version."
  - property: "`sig`"
    description: An ED25519 signature.
{% endtable %}
<!--vale on-->

### Authentication logs

Authentication attempts and their outcomes are logged whenever a user logs in to the {{site.konnect_short_name}} application or the Dev Portal either through the UI or the Konnect API.

Example log entry:

{% navtabs "logs" %}
{% navtab "CEF" %}
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
{:.no-copy-code}

{% endnavtab %}
{% navtab "JSON" %}
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
{:.no-copy-code}

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
  - property: "AUTHENTICATION_TYPE"
    description: |
      Can be one of the following:
      <br> - `AUTHENTICATION_TYPE_BASIC`: Basic email and password authentication
      <br> - `AUTHENTICATION_TYPE_SSO`: Authentication with single sign-on (SSO)
      <br> - `AUTHENTICATION_TYPE_PAT`: Authentication with a personal access token
  - property: "AUTHENTICATION_OUTCOME"
    description: |
      Can be one of the following:
      <br> - `AUTHENTICATION_OUTCOME_SUCCESS`: Authentication is successful
      <br> - `AUTHENTICATION_OUTCOME_NOT_FOUND`: User was not found
      <br> - `AUTHENTICATION_OUTCOME_INVALID_PASSWORD`: Invalid password specified
      <br> - `AUTHENTICATION_OUTCOME_LOCKED`: User account is locked
      <br> - `AUTHENTICATION_OUTCOME_DISABLED`: User account has been disabled
  - property: "success"
    description: "`true` or `false`, depending on whether authentication was successful or not."
{% endtable %}
<!--vale on-->

### Authorization logs

Authorization log entries are created for every permission check in {{site.konnect_short_name}}.

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
{:.no-copy-code}

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
{:.no-copy-code}

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
  - property: "action"
    description: "The type of action the user performed on the resource. For example, `retrieve`, `list`, or `edit`."
  - property: "granted"
    description: "Boolean indicating whether the authorization was granted or not."
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
{:.no-copy-code}

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
{:.no-copy-code}

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
{% endtable %}
<!--vale on-->