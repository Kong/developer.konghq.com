---
title: Data security

description: Learn the options that {{ site.insomnia }} offers to encrypt and store encrypted data.

content_type: reference
layout: reference
breadcrumbs: 
  - /insomnia/manage-insomnia/
search_aliases:
  - insomnia data policy
  - insomnia data encryption
  - insomnia local encryption key
products:
    - insomnia
related_resources:
  - text: Incident response and vulnerability management
    url: /insomnia/incident-response/
  - text: Security at {{ site.insomnia }}
    url: /insomnia/manage-insomnia/#security
  - text: Storage options
    url: /insomnia/storage/
  - text: "{{ site.insomnia }} terminology"
    url: /insomnia/terminology/
  - text: Inso CLI encryption key
    url: /inso-cli/configuration/#encryption-key
faqs:
  - q: How is data encrypted?
    a: All data is encrypted using randomly generated 256 bit symmetric keys for use with AES-GCM-256 (Galois Counter Mode).
  - q: How is data processed when sent to {{ site.insomnia }} servers?
    a: Information is sent over TLS and is end-to-end encrypted.
  - q: What authentication is implemented by the application?
    a: Secure Remote Passwords (SRP) encrypted key exchange protocol. You can read more about the exact SRP implementation that {{ site.insomnia }} paid plans use in [RFC-2945](https://datatracker.ietf.org/doc/html/rfc2945).
  - q: Where is data stored?
    a: Information is stored in GCP, within Postgres, in US Central region.
  - q: What does {{ site.insomnia }} use passphrases for?
    a: "{{ site.insomnia }} requires users who use cloud or git sync storage to have a passphrase to decrypt their account keys."
  - q: I lost my passphrase, how can I access my account?
    a: If you lose your passphrase, there is no way to access your account projects and information and your account must be reset. If you have been invited to collaborate with other organizations, you can reset your passphrase and then ask to be invited back. You will only be able to retrieve data for the organizations that you are invited back to. If you have shared your personal organizations or project data, you can ask other users with Admin permissions to also re-invite you after resetting the passphrase.
  - q: Is local data on Scratch Pad encrypted?
    a: |
      Partly. In {{ site.insomnia }} 13.5 and later, sensitive fields such as passwords, tokens, cookie values, and client certificate secrets are encrypted in the local database for all projects, including Scratch Pad. {{ site.insomnia }} creates the key on first launch and protects it with your operating system's credential store. Other project data, such as request URLs and bodies, is still stored on disk without encryption, and E2EE only applies to project data that is transmitted over the network. For more information, see [Local database encryption](#local-database-encryption).
  - q: Can I still use {{ site.insomnia }} 13.4 or earlier after opening my data in 13.5?
    a: |
      Yes. You can open every project, collection, and request in an earlier version. However, values that 13.5 encrypted appear as text that starts with `enc:insomnia:v1:`, and requests that use them fail. To use these requests in the earlier version, enter the values again. Cloud Sync, Git Sync, and exported files aren't affected. For more information, see [Downgrade to an earlier version](#downgrade-to-an-earlier-version).
  - q: Is AI data in {{ site.insomnia }} encrypted?
    a: No. Data sent to AI features is not end-to-end encrypted, and therefore is not covered by this document. Organization administrators can disable specific AI features for all users. Individual users can disable available features in **Preferences > AI Features**. When a feature is disabled at the organization level, its option appears greyed with a tooltip explaining that it has been turned off by an administrator.
  - q: What is a resource group in {{ site.insomnia }} and how are they securely shared?
    a: The ability to share Resource Groups is the reason that every Resource Group needs its own key, and every account needs a public/private key-pair to securely share said key. Here’s an example involving two users, Jane and Bob. For Jane to share a Resource Group with Bob, she must encrypt the Resource Group’s key with Bob’s public key and store it on the server (M_Link). Now, Bob can use his account’s private key to decrypt the Resource Group’s key and gain access to the data. This is a classic example of the Diffie-Hellman key exchange being put to good use.
---

## End-to-end encryption

{{ site.insomnia }} implements end-to-end encryption (E2EE), which means that all encryption keys are generated locally, all encryption is performed before sending any data over the network, and all decryption is performed after receiving data from the network. At no point in the sync process can the {{ site.insomnia }} servers read or access sensitive application project data.

Each user sets their own encryption passphrase, which is never shared or stored. Project data is encrypted with a randomly generated symmetric key, which is then encrypted separately for each user using their public encryption key. Only someone with the matching private key can decrypt the symmetric key. {{ site.insomnia }} stores encrypted workspace data and the encrypted symmetric key for each authorized user — nothing is ever stored in plain text.

{{ site.insomnia }} data is stored in a pooled model for multi-tenancy. Each row is separated by a tenant identifier within the database. To retrieve data, the {{ site.insomnia }} Admin API request must have the tenant identifier (organization ID) in the request path and an authenticated user who is a member of the target tenant (organization).

## Local database encryption

{% new_in 13.5 %} {{ site.insomnia }} encrypts sensitive fields in the local database that it keeps on your machine. Encryption applies to every project, including Scratch Pad and local projects, and doesn't require you to log in or do anything. Values are encrypted with AES-256-GCM.

The following fields are encrypted:

* Authentication credentials on requests, folders, and collections, such as passwords, tokens, client secrets, private keys, and API key values. This also applies to gRPC, WebSocket, Socket.IO, and MCP requests.
* Cookie values in the cookie jar.
* Client certificate files, keys, and passphrases.
* OAuth 2.0 access, identity, and refresh tokens.
* Cloud provider credentials used for [external vaults](/insomnia/external-vault/).
* Git credentials and tokens.
* The stored copies of requests in the response history.

Other data, such as environment variables, headers, request bodies, and URLs, is stored on disk without encryption. Data that {{ site.insomnia }} sends to Cloud Sync is protected by [end-to-end encryption](#end-to-end-encryption) separately.

Local encryption doesn't change Cloud Sync, Git Sync, or exported files. {{ site.insomnia }} decrypts values before it syncs or exports them, so teammates on any version of {{ site.insomnia }} can still collaborate with you.

### Local encryption key

{{ site.insomnia }} generates a random 256-bit key on first launch and stores it protected by your operating system's credential store: Keychain on macOS, DPAPI on Windows, or Secret Service on Linux. {{ site.insomnia }} never writes the key to disk without encryption.

You don't need the key to use the {{ site.insomnia }} app. You need it only to run [Inso CLI](/inso-cli/configuration/#encryption-key) against {{ site.insomnia }}'s local database files.

To get the key:

1. In {{ site.insomnia }}, open **Preferences**.
1. Click the **General** tab.
1. In the **Security** section, find **Local Encryption Key**.
1. Click **Copy Key** to copy the key as a single line of text, or click **Export Key** to save it to a file.
1. In the confirmation dialog, click **I understand, continue**.
1. If you clicked **Export Key**, choose a location and click **Save**. The default filename is `insomnia-encryption-key.json`.

On macOS and Linux, the exported file can only be read and written by its owner (mode `600`). On Windows, the file gets the permissions of the folder you save it in.

Both forms of the key work with Inso CLI. The key also records the name of the machine it was exported on.

{:.warning}
> * **Never share the key.** Anyone with the key can decrypt the tokens and other values stored in your local database. Don't commit it to a repository or paste it into shared logs.
> * **Never use the key on another machine.** Using the wrong key can make values unreadable for the {{ site.insomnia }} app on that machine.

### Decryption issues

If {{ site.insomnia }} can't use its key at startup, for example because the application data was moved from another machine or the operating system's credential store was reset, it shows a **The local encryption key is not available** dialog. For that session, values that are already encrypted don't work, and new values are stored without encryption. {{ site.insomnia }} doesn't delete anything, and tries again the next time it starts. If the key will never be available again, click **Reset local encryption key** to give up the encrypted values and start over with a new key.

If only some values can't be decrypted, {{ site.insomnia }} shows a **Some encrypted data could not be decrypted** dialog that lists the affected fields. Click **Reset affected fields** to clear these values so you can enter them again, or click **Continue without decryption** to keep them as they are.

### Downgrade to an earlier version

After you open your data with {{ site.insomnia }} 13.5 or later, you can still open it with an earlier version. {{ site.insomnia }} versions 13.5 and later share the same data folder and key, so you can move between them freely.

In {{ site.insomnia }} 13.4 and earlier, every project, collection, and request still opens, and you can still create, edit, and send requests. However, encrypted values appear as text that starts with `enc:insomnia:v1:`, and the earlier version sends that text in place of the real value. Requests that depend on an encrypted value, such as a request with a token on its **Auth** tab, fail.

To use these requests in the earlier version, enter the values again. When you return to {{ site.insomnia }} 13.5 or later, it decrypts the values that are still encrypted and encrypts the values you entered in the earlier version.

## Sign up and authentication

{{ site.insomnia }} uses the [Secure Remote Password (SRP)](http://srp.stanford.edu/) protocol to securely manage authentication without sending or storing passphrases in a readable format. This ensures that sensitive user credentials remain protected during account creation and login.

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

