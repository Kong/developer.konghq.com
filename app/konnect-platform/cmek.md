---
title: Customer-Managed Encryption Keys (CMEK)
content_type: reference
layout: reference
description: 'Use Customer-Managed Encryption Keys (CMEK) in {{site.konnect_short_name}} to encrypt pre-determined sets of sensitive data using keys from your AWS Key Management Service (KMS) account.'
breadcrumbs:
  - /konnect/
products:
    - konnect-platform
tags:
  - encryption
  - security
  - compliance
works_on:
  - konnect
faqs:
  - q: Can I use automation to configure CMEK in {{site.konnect_short_name}}?
    a: Yes, you can use the {{site.konnect_short_name}} UI, API, and [Terraform](/terraform/) to configure CMEK.
  - q: Can I bring in symmetric keys from other key management services?
    a: No. CMEK currently only supports AWS Key Management Service (KMS).
related_resources:
  - text: {{site.konnect_short_name}} Debugger
    url: /gateway/debugger/
  - text: Debugger spans
    url: /gateway/debugger-spans/
  - text: "{{site.base_gateway}} tracing reference"
    url: /gateway/tracing/
---

{{site.konnect_short_name}} supports **Customer-Managed Encryption Keys (CMEK)**, allowing you to use your own symmetric key stored in **AWS Key Management Service (KMS)** to encrypt a pre-determined set of sensitive data. This feature enhances privacy, security, and regulatory compliance by enabling customer-controlled encryption.


## Benefits of CMEK

* **Regulatory compliance** with standards such as HIPAA, GDPR, and PCI-DSS
* **Exclusive decryption access** Encrypted data can't be accessed without a key.
* **Instant revocation** removing the key from AWS KMS makes encrypted data in {{site.konnect_short_name}} unreadable

## CMEK scope in {{site.konnect_short_name}}

CMEK currently applies to:

* Payloads captured through [the {{site.konnect_short_name}} Debugger](/gateway/debugger/)
* Request logs stored in Debugger workflows

To use CMEK, you must

1. [Create a **symmetric encryption key** in AWS KMS.](https://docs.aws.amazon.com/kms/latest/developerguide/create-keys.html)
1. Provide the **key ARN** to [{{site.konnect_short_name}}](https://cloud.konghq.com/global/organization/settings/encryption-keys/)

## Configure CMEK in {{site.konnect_short_name}}

To configure CMEK, you need:
* A **symmetric key** in AWS KMS
* **Org Admin** role in {{site.konnect_short_name}}

### Setup Workflow

1. Go to [**Encryption Keys**](https://cloud.konghq.com/global/organization/settings/encryption-keys/) in {{site.konnect_short_name}}.
1. Click **Link key**.
1. Enter the **Name**, **Amazon Resource Name**, **description**, and **Region**. 
1. Click **Connect**. 

## User responsibilities

When you configure CMEK, you are responsible for the following:

* **Key rotation**: 
  * AWS KMS takes care of key rotation automatically. 
  * Manual rotation with a new ARN requires updating the key in {{site.konnect_short_name}}. If the key's ARN changes, data encrypted with the previous key cannot be decrypted in {{site.konnect_short_name}}.
* **Key revocation**: 
  * Revoking or deleting your key in AWS KMS renders associated data permanently unreadable.
* **Performance impact**: 
  * KMS-based decryption may introduce latency during access operations.
* **Feature limitations**: 
  * CMEK encrypted fields cannot be used in full-text search, filtering, or analytics.
  * Alerting features cannot inspect CMEK encrypted content.
* **Cost**: 
  * Any costs incurred in AWS KMS.


## Managing keys

See the following sections for information about how to manage CMEK keys.

### Key Rotation

* Rotating keys within AWS KMS (without changing the ARN) is supported automatically.
* If you change the ARN, you must update the key in {{site.konnect_short_name}} manually. 
  * Data encrypted with the previous key cannot be decrypted and will be lost.

### Key revocation

The following happens if the AWS KMS key is revoked:
* If the AWS KMS key is revoked or deleted, encrypted data becomes inaccessible.
* {{site.konnect_short_name}} will display decryption errors when this occurs.


