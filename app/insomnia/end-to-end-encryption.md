---
title: End-to-End Encryption (E2EE) in Insomnia

description: Learn how E2EE works in Insomnia.

content_type: reference
layout: reference
breadcrumbs: 
  - /insomnia/
products:
    - insomnia
tier: enterprise
related_resources:
  - text: Enterprise
    url: /insomnia/enterprise/
---

E2EE means that all encryption keys are generated locally, all encryption is performed before sending any data over the network, and all decryption is performed after receiving data from the network. At no point in the sync process can the Insomnia servers, or an intruder, read or access sensitive project data.

All data is encrypted using randomly generated 256-bit symmetric keys for use with AES-GCM-256 (Galois Counter Mode).

## How does E2EE work in Insomnia?

Each user sets their own encryption passphrase. Their passphrase is never shared or stored.
The user's project data is encrypted with a randomly generated symmetric key, which is then encrypted separately for each user using their public encryption key. Only someone with the matching private key can decrypt the symmetric key.

## What does Insomnia store?

Insomnia stores encrypted workspace data and the encrypted symmetric key for each authorized user. Nothing is ever stored in plain text, not even the shared secret key.

