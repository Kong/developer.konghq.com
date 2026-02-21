---
title: Data security

description: Learn the options that Insomnia offers to encrypt and store encrypted data.

content_type: reference
layout: reference
breadcrumbs: 
  - /insomnia/manage-insomnia/
search_aliases:
  - insomnia data policy
  - insomnia data encryption
products:
    - insomnia
related_resources:
  - text: Security at Insomnia
    url: /insomnia/manage-insomnia/#security
  - text: About version control in Insomnia
    url: /insomnia/version-control/
  - text: Insomnia terminology
    url: /insomnia/terminology/
faqs:
  - q: How is data encrypted?
    a: All data is encrypted using randomly generated 256 bit symmetric keys for use with AES-GCM-256 (Galois Counter Mode).
  - q: How is data processed when sent to Insomnia servers?
    a: Information is sent over TLS and is end-to-end encrypted.
  - q: What authentication is implemented by the application?
    a: Secure Remote Passwords (SRP) encrypted key exchange protocol. You can read more about the exact SRP implementation that Insomnia paid plans use in [RFC-2945](https://datatracker.ietf.org/doc/html/rfc2945).
  - q: Where is data stored?
    a: Information is stored in GCP, within Postgres, in US Central region.
  - q: What does Insomnia use passphrases for?
    a: Insomnia requires users who use cloud or git sync storage to have a passphrase to decrypt their account keys.
  - q: I lost my passphrase, how can I access my account?
    a: If you lose your passphrase, there is no way to access your account projects and information and your account must be reset. If you have been invited to collaborate with other organizations, you can reset your passphrase and then ask to be invited back. You will only be able to retrieve data for the organizations that you are invited back to. If you have shared your personal organizations or project data, you can ask other users with Admin permissions to also re-invite you after resetting the passphrase.
  - q: Is local data on Scratch Pad encrypted?
    a: Local data is not encrypted on disk. Insomnia currently stores application project data locally on disk in raw form. E2EE only applies to project data that is transmitted over the network. It is still possible for malicious software to access the project data stored on your machine. Please take the usual precautions to keep your local project data safe.
  - q: Is AI data in Insomnia encrypted?
    a: No. Data sent to AI features is not end-to-end encrypted, and therefore is not covered by this document. Organization administrators can disable specific AI features for all users. Individual users can disable available features in **Preferences > AI Features**. When a feature is disabled at the organization level, its option appears greyed with a tooltip explaining that it has been turned off by an administrator.
  - q: What is a resource group in Insomnia and how are they securely shared?
    a: The ability to share Resource Groups is the reason that every Resource Group needs its own key, and every account needs a public/private key-pair to securely share said key. Here’s an example involving two users, Jane and Bob. For Jane to share a Resource Group with Bob, she must encrypt the Resource Group’s key with Bob’s public key and store it on the server (M_Link). Now, Bob can use his account’s private key to decrypt the Resource Group’s key and gain access to the data. This is a classic example of the Diffie-Hellman key exchange being put to good use.
  - q: What happens to my sensitive data when I log out of Insomnia?
    a: |
      When you log out of Insomnia, the app removes the vault key from your local settings. Without this key, encrypted values from earlier sessions cannot be unlocked. Any files or projects that you saved locally stay on your device until you delete them.  
---

Insomnia implements end-to-end encryption (E2EE), which means that all encryption keys are generated locally, all encryption is performed before sending any data over the network, and all decryption is performed after receiving data from the network. At no point in the sync process can the Insomnia servers, or an intruder read or access sensitive application project data.

Insomnia data is stored in a pooled model for multi-tenancy. Each row is separated by a tenant identifier within the database. To retrieve data, the Insomnia Admin API request must have the tenant identifier (organization ID) in the request path and an authenticated user who is a member of the target tenant (organization).

## Sign up and authentication

Insomnia uses the [Secure Remote Password (SRP)](http://srp.stanford.edu/) protocol to securely manage authentication without sending or storing passphrases in a readable format. This ensures that sensitive user credentials remain protected during account creation and login.

## Account creation

During sign up, the client generates encryption keys, salts, and RSA key-pairs. It derives secure password representations using HKDF and PBKDF2 and encrypts sensitive keys before sending them to the server. The server stores only the SRP verifier and encrypted data, never the raw passphrase.

## Account login

When logging in, the client repeats the password derivation steps and performs an SRP exchange using stored salts. A session key is then generated and used for encrypted communication, ensuring the passphrase itself is never exposed.

## Data models

The following are data models we use.

{% table %}
columns:
  - title: Data Model
    key: model
  - title: Definition
    key: definition
rows:
  - model: "`M_Account`"
    definition: A user that can log in
  - model: "`M_Resource`"
    definition: An entity that can be synced (e.g. Request, Workspace, etc.)
  - model: "`M_ResourceGroup`"
    definition: A group of M_Resource that can be shared as one
  - model: "`M_Link`"
    definition: A relationship linking a M_Account to M_ResourceGroup
{% endtable %}

## Keys and salts

The following are keys and salts we use.

{% table %}
columns:
  - title: Name
    key: name
  - title: Definition
    key: definition
  - title: Stored?
    key: stored
  - title: Stored with encryption?
    key: encrypted
rows:
  - name: "`PUB_Account`"
    definition: Public key for M_Account
    stored: Y
    encrypted: N
  - name: "`PRV_Account`"
    definition: Private key for M_Account
    stored: Y
    encrypted: Y
  - name: "`SYM_Account`"
    definition: Symmetric key for M_Account
    stored: Y
    encrypted: Y
  - name: "`SYM_ResourceGroup`"
    definition: Symmetric Key for data encryption
    stored: N
    encrypted: N
  - name: "`SYM_Link`"
    definition: Encrypted form of SYM_ResourceGroup
    stored: Y
    encrypted: Y
  - name: "`SLT_Auth_1`"
    definition: Salt for PBKDF2 of passphrase for auth
    stored: Y
    encrypted: N
  - name: "`SLT_Auth_2`"
    definition: Salt for SRP authentication process
    stored: Y
    encrypted: N
  - name: "`SLT_Enc`"
    definition: Salt for PBKDF2 of passphrase for encryption
    stored: Y
    encrypted: N
  - name: "`SEC_PWD_Auth`"
    definition: Secret derived from passphrase using SLT_Auth_1
    stored: N
    encrypted: N
  - name: "`SEC_PWD_Enc`"
    definition: Secret derived from passphrase using SLT_Enc
    stored: N
    encrypted: N
  - name: "`SRP_Verifier`"
    definition: Verification string used for SRP
    stored: Y
    encrypted: N
{% endtable %}
