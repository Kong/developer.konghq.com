---
title: Customer-Managed Encryption Keys (CMEK)
content_type: reference
layout: reference
description: 'Use Customer-Managed Encryption Keys (CMEK) in {{site.konnect_short_name}} to encrypt sensitive data using keys from your AWS Key Management Service (KMS) account.'
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
---

## Overview

{{site.konnect_short_name}} supports **Customer-Managed Encryption Keys (CMEK)**, allowing you to use your own symmetric key stored in **AWS Key Management Service (KMS)** to encrypt sensitive data. This feature enhances privacy, security, and regulatory compliance by enabling customer-controlled encryption.

## Benefits of CMEK

* **Regulatory compliance** with standards such as HIPAA, GDPR, and PCI-DSS
* **Exclusive decryption access** {{site.base_gateway}} cannot access unencrypted data without your key
* **Instant revocation** removing the key from AWS KMS makes encrypted data in {{site.konnect_short_name}} unreadable

## CMEK scope in {{site.konnect_short_name}}

CMEK currently applies to:

* Payloads captured through [the {{site.konnect_short_name}} Debugger](/konnect-platform/debugger/)
* Request logs stored in Debugger workflows

The steps required are: 

1. Create a **symmetric encryption key** in AWS KMS.
1. Provide the **key ARN** to {{site.konnect_short_name}} through the UI.
1. {{site.konnect_short_name}} encrypts specified data using the key during write operations.
1. Decryption occurs via AWS KMS at read time, contingent on key availability.

### User Responsibilities

* **Key rotation**: 
  * AWS KMS can rotate keys automatically if the ARN stays constant.
  * Manual rotation with a new ARN requires updating the key in {{site.konnect_short_name}}. If the key's ARN changes, data encrypted with the previous key cannot be decrypted in {{site.konnect_short_name}}
* **Key revocation**: 
  * Revoking or deleting your key in AWS KMS renders associated data permanently unreadable.
* **Performance impact**: 
  * KMS-based decryption may introduce latency during access operations.
* **Feature limitations**: 
  * Encrypted fields cannot be used in full-text search, filtering, or analytics
  * Alerting features cannot inspect encrypted content


## Managing Keys

### Key Rotation

* Rotating keys within AWS KMS (without changing the ARN) is supported automatically.
* If you change the ARN, you must update the key in {{site.konnect_short_name}} manually.

### Key Revocation

* If the AWS KMS key is revoked or deleted, encrypted data becomes inaccessible.
* {{site.konnect_short_name}} will display decryption errors when this occurs.

## API and Automation Support

* CMEK can currently only be configured via the **{{site.konnect_short_name}} UI**.

Once CMEK has been configured {{site.konnect_short_name}} data that is encrypted using CMEK will be visible from the {{site.konnect_short_name}} UI APIs, decK and Terraform after decryption. 

## Configure CMEK

* A **symmetric key** in AWS KMS
* **Org Admin** role in {{site.konnect_short_name}}

### Setup Workflow

1. Go to **Organization Settings > Encryption Keys** in {{site.konnect_short_name}}.
1. Click **Add Key**.
1. Enter the **Key ARN**, **name**, and an optional **description**.
1. Click **Save** to activate CMEK.
