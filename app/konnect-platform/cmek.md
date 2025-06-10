---
title: Customer-Managed Encryption Keys (CMEK)
content_type: reference
layout: reference
description: 'Use Customer-Managed Encryption Keys (CMEK) in Konnect to encrypt sensitive data using keys from your AWS KMS account.'
breadcrumbs:
  - /konnect/
content_type: reference

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

Konnect supports **Customer-Managed Encryption Keys (CMEK)**, allowing you to use your own symmetric key stored in **AWS Key Management Service (KMS)** to encrypt sensitive data. This feature enhances privacy, security, and regulatory compliance by enabling customer-controlled encryption.

## Benefits of CMEK

* **Regulatory compliance** with standards such as HIPAA, GDPR, and PCI-DSS
* **Exclusive decryption access** {{site.base_gateway}} cannot access unencrypted data without your key
* **Instant revocation** removing the key from AWS KMS makes encrypted data unreadable

## CMEK Scope in {{site.konnect_short_name}}

CMEK currently applies to:

* Payloads captured through [**Active Tracing**](/konnect-platform/active-tracing/)
* Request logs stored in tracing workflows


## How It Works

1. You create a **symmetric encryption key** in AWS KMS.
1. You provide the **key ARN** to Konnect through the UI.
1. Konnect encrypts specified data using the key during write operations.
1. Decryption occurs via AWS KMS at read time, contingent on key availability.

### User Responsibilities

* **Key rotation**: 
  * AWS KMS can rotate keys automatically if the ARN stays constant.
  * Manual rotation with a new ARN requires updating the key in Konnect.
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
* If you change the ARN, you must update the key in Konnect manually.

### Key Revocation

* If the AWS KMS key is revoked or deleted, encrypted data becomes inaccessible.
* Konnect will display decryption errors when this occurs.

## API and Automation Support

* CMEK can currently only be configured via the **Konnect UI**.
* API and Terraform support are planned for future releases.

## Configure CMEK

* A **symmetric key** in AWS KMS
* **Org Admin** role in Konnect

### Setup Workflow

1. Go to **Organization Settings > Encryption Keys** in Konnect.
1. Click **Add Key**.
1. Enter the **Key ARN**, **name**, and an optional **description**.
1. Click **Save** to activate CMEK.
