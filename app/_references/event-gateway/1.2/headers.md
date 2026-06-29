---
# **Auto-generated** - Do not edit manually. See https://github.com/kong-gateway/event-gateway/blob/main/api/headers.md

title: "{{site.event_gateway}} headers"

description: Reference for all headers added or interpreted by {{site.event_gateway}}.

related_resources:
  - text: "{{site.event_gateway}}"
    url: /event-gateway/
  - text: "{{site.event_gateway}} metrics"
    url: /event-gateway/metrics/
---

This document lists every Kafka record header {{site.event_gateway}} may add or interpret.

## enc

### `kong/enc`

Encryption metadata: which of record key/value is encrypted and the key id(s) used. Also carries the (deduplicated) list of key ids referenced by per-field encrypted payloads when the `field_encryption` sub-policy is configured (see MADR 046). The `decrypt` and `field_decryption` policies read this to know which key(s) to fetch.

|Field        |Value     |
|:------------|:---------|
|Encoding     |`binary` (schema: `EncryptionMetadata`)|
|Max size     |_unbounded_|
|Producer     |encrypt policy / field_encryption sub-policy|
|Consumer     |decrypt policy / field_decryption sub-policy|
|Direction    |`both`|
|Visibility   |`internal`|

## policy

### `kong/policy-failure-{konnect_id}`

Policy failure marker, written when a policy's failure mode is `mark`. The placeholder is the Konnect id of the failing policy; the value is the failure reason text.

|Field        |Value     |
|:------------|:---------|
|Encoding     |`utf8`|
|Max size     |512 bytes|
|Producer     |policy framework (mark failure mode)|
|Consumer     |external (downstream consumer)|
|Direction    |`both`|
|Visibility   |`external`|

## sverr

### `kong/sverr-{part}`

{:.info}
> **Deprecated.** Replaced by the unified policy-failure marker header `kong/policy-failure-{konnect_id}`. This header will be removed in the future.

Legacy schema-validation failure marker. The placeholder is `key` or `value`; the value is the producer's client id.

|Field        |Value     |
|:------------|:---------|
|Encoding     |`utf8`|
|Max size     |_unbounded_|
|Producer     |schema_validation policy (mark_record_on_failure)|
|Consumer     |external (downstream consumer)|
|Direction    |`both`|
|Visibility   |`external`|
