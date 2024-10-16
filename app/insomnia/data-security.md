---
title: Data security

content_type: reference
layout: reference

products:
    - insomnia

faqs:
  - q: How is data encrypted?
    a: All data is encrypted using randomly generated 256 bit symmetric keys for use with AES-GCM-256 (Galois Counter Mode).
  - q: How is data processed when sent to Insomnia servers?
    a: Information is sent over TLS and is end-to-end encrypted.
  - q: What authentication is implemented by the application?
    a: Secure Remote Passwords (SRP) encrypted key exchange protocol. You can read more about the exact SRP implementation that Insomnia paid plans use in [RFC-2945](https://datatracker.ietf.org/doc/html/rfc2945).
  - q: Where is data stored?
    a: Information is stored in GCP, within Postgress, in US Central region.
  - q: What does Insomnia use passphrases for?
    a: Insomnia requires users who use cloud or git sync storage to have a passphrase to decrypt their account keys.
  - q: I lost my passphrase, how can I access my account?
    a: If you lose your passphrase, there is no way to access your account projects and information and your account must be reset. If you have been invited to collaborate with other organizations, you can reset your passphrase and then ask to be invited back. You will only be able to retrieve data for the organizations that you are invited back to. If you have shared your personal organizations or project data, you can ask other users with Admin permissions to also re-invite you after resetting the passphrase.
  - q: Is local data on Scratch Pad encrypted?
    a: Local data is not encrypted on disk. Insomnia currently stores application project data locally on disk in raw form. E2EE only applies to project data that is transmitted over the network. It is still possible for malicious software to access the project data stored on your machine. Please take the usual precautions to keep your local project data safe.
  - q: Is AI data in Insomnia encrypted?
    a: No. Insomnia allows you to choose if you want to use AI for certain features, like generating tests. Data you provide to use these AI tools are not end-to-end encrypted and so this document does not apply to such data.
  - q: What is a resource group in Insomnia and how are they securely shared?
    a: The ability to share Resource Groups is the reason that every Resource Group needs its own key, and every account needs a public/private key-pair to securely share said key. Here’s an example involving two users, Jane and Bob. For Jane to share a Resource Group with Bob, she must encrypt the Resource Group’s key with Bob’s public key and store it on the server (M_Link). Now, Bob can use his account’s private key to decrypt the Resource Group’s key and gain access to the data. This is a classic example of the Diffie-Hellman key exchange being put to good use.
---

All Insomnia project data is encrypted end-to-end (E2EE). E2EE means that all encryption keys are generated locally, all encryption is performed before sending any data over the network, and all decryption is performed after receiving data from the network. At no point in the sync process can the Insomnia servers, or an intruder read or access sensitive application project data.

Insomnia data is stored in a pooled model for multi-tenancy. Each row is separated by a tenant identifier within the database. To retrieve data, the Insomnia Admin API request must have the tenant identifier (organization ID) in the request path and an authenticated user who is a member of the target tenant (organization).

## Data models

The following are data models we use.

| Data Model | Definition |
| ---------- | ----------- |
| `M_Account` | A user that can log in |
| `M_Resource` | An entity that can be synced (eg. Request, Workspace, etc.) |
| `M_ResourceGroup` | A group of M_Resource that can be shared as one |
| `M_Link` | A relationship linking a M_Account to M_ResourceGroup |

## Keys and salts

The following are keys and salts we use.

| Name | Definition | Stored? | Stored with encryption? |
| ---------- | ----------- | ----------- | ----------- |
| `PUB_Account` | Public key for M_Account | Y | N |
| `PRV_Account` | Private key for M_Account | Y | Y |
| `SYM_Account` | Symmetric key for M_Account | Y | Y |
| `SYM_ResourceGroup` | Symmetric Key for data encryption | N | N |
| `SYM_Link` | Encrypted form of SYM_ResourceGroup | Y | Y |
| `SLT_Auth_1` | Salt for PBKDF2 of passphrase for auth | Y | N |
| `SLT_Auth_2` | Salt for SRP authentication process | Y | N |
| `SLT_Enc` | Salt for PBKDF2 of passphrase for encryption | Y | N |
| `SEC_PWD_Auth` | Secret derived from passphrase using SLT_Auth_1 | N | N |
| `SEC_PWD_Enc` | Secret derived from passphrase using SLT_Enc | N | N |
| `SRP_Verifier` | Verification string used for SRP | Y | N |