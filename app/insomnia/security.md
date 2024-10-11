---
title: Security at Insomnia

content_type: reference
layout: reference

sub_text: "Learn how Insomnia prioritizes data protection through encryption, product and application security, and organizational measures."

products:
    - insomnia

tags:
  - security

faqs:
  - q: Does Insomnia have any compliance certifications?
    a: Not at the moment.
  - q: Where do I download the Software Bill of Materials (SBOM) for Insomnia?
    a: From the [Insomnia GitHub Releases](https://docs.insomnia.rest/insomnia/sbom#:~:text=Navigate%20to%20Insomnia%20GitHub%20Releases) page, download the `sbom.spdx.json` and `sbom.cyclonedx.json` SBOM files.
  - q: Do you have any penetration test results from external parties?
    a: Not at the moment.
  - q: How often do you release major updates, and or security patches?
    a: We regularly update the Insomnia desktop application. Security, and hotfix patches are handled on a case-by-case basis and can occur at any time.
  - q: Do you retain server logs, or event logs?
    a: All server logs stored are kept within GCP and only accessed by engineers authorized to manage the Insomnia servers.
  - q: Do you maintain documentation when an incident/event occurs?
    a: When an incident occurs, we perform an internal post-mortem and disseminate information accordingly, either through the site in the form of a blog post, or through social media/support on a case-by-case basis.
  - q: In case of a security breach, do you notify customers?
    a: Yes, via email.
  - q: What is your primary point of contact?
    a: Our [open source GitHub repository](https://github.com/kong/insomnia) and [support channels](https://insomnia.rest/support). 
  - q: How is data processed when sent to Insomnia servers?
    a: Information is sent over TLS and is end-to-end encrypted.
  - q: What authentication is implemented by the application?
    a: Secure Remote Passwords (SRP) encrypted key exchange protocol.
---



## Data security

### Cloud
All Insomnia project data is encrypted end-to-end (E2EE). E2EE means that all encryption keys are generated locally, all encryption is performed before sending any data over the network, and all decryption is performed after receiving data from the network. At no point in the sync process can the Insomnia servers, or an intruder read or access sensitive application project data.

Insomnia data is stored in a pooled model for multi-tenancy. Each row is separated by a tenant identifier within the database. To retrieve data, the Insomnia Admin API request must have the tenant identifier (organization ID) in the request path and an authenticated user who is a member of the target tenant (organization).

All data is encrypted using randomly generated 256 bit symmetric keys for use with AES-GCM-256 (Galois Counter Mode).

Insomnia requires users who use cloud or git sync storage to have a passphrase to decrypt their account keys. If you lose your passphrase, there is no way to access your account projects and information and your account must be reset.

If you have been invited to collaborate with other organizations, you can reset your passphrase and then ask to be invited back. You will only be able to retrieve data for the organizations that you are invited back to.

If you have shared your personal organizations or project data, you can ask other users with Admin permissions to also re-invite you after resetting the passphrase.

Information is stored in GCP, in US Central region
Information inside of GCP is stored within Postgres

You can read more about the exact SRP implementation that Insomnia paid plans use in [RFC-2945](https://datatracker.ietf.org/doc/html/rfc2945).

Please note that the Insomnia service may provide you the ability to develop tests for your API design specifications, as well as other functionality, using artificial intelligence tools. Data you provide to use these AI tools are not end-to-end encrypted and so this document does not apply to such data.

### Locally 
Local data is not encrypted on disk. Insomnia currently stores application project data locally on disk in raw form. E2EE only applies to project data that is transmitted over the network. It is still possible for malicious software to access the project data stored on your machine. Please take the usual precautions to keep your local project data safe.

### Data models, keys, and salts

The following are data models we use.

| Data Model | Definition |
| ---------- | ----------- |
| `M_Account` | A user that can log in |
| `M_Resource` | An entity that can be synced (eg. Request, Workspace, etc.) |
| `M_ResourceGroup` | A group of M_Resource that can be shared as one |
| `M_Link` | A relationship linking a M_Account to M_ResourceGroup |

The following are keys and salts we use.

| Name | Definition | Stored? | Locked? |
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

**What is a Resource group?** 
The ability to share Resource Groups is the reason that every Resource Group needs its own key, and every account needs a public/private key-pair to securely share said key. Here’s an example involving two users, Jane and Bob.

For Jane to share a Resource Group with Bob, she must encrypt the Resource Group’s key with Bob’s public key and store it on the server (M_Link). Now, Bob can use his account’s private key to decrypt the Resource Group’s key and gain access to the data. This is a classic example of the Diffie-Hellman key exchange being put to good use.

## Key security features

### Enterprise Single Sign On (SSO)

Insomnia supports federating user authentication through third-party identity providers for access management. 
Customers can leverage their existing identity management workflow to govern which users can access the application.  
Additionally, users must be entitled to the appropriate Organizations before they can access specific projects managed in Insomnia.  

### Role-Based Access Control
Insomnia Organizations allows Insomnia Users to share Collections and Environments safely and securely with their colleagues using Insomnia Cloud or Git sync for collaboration.
Members of an organization can make commits and set up branches for their collections. They can also view commits and branches from other members.

Insomnia Organization Admins have the ability to administer Role-Based Access Control, providing the ability to scope user access to Design Documents and Request Collections on an as-needed basis.

As Git Sync is also supported, User permissions may also be governed through Git source code management providers.

### Insomnia Storage Options

Insomnia offers various storage options to cater to different user needs and preferences as well as to ensure data compliance requirements. 
Understanding these options is crucial for efficient and secure management of your API projects. 
The three primary storage options available in Insomnia are:
* [Local vault (scratch pad)](/)
* [Cloud sync](/)
* [Git sync](/)


## Infrastructure security

For users and/or organizations that choose to leverage Insomnia Cloud Sync, data is stored in Postgres databases in the Google Cloud Platform (GCP) us-central1 region.

For users and/or organizations that choose to leverage Git Sync, data is stored in the underlying storage for the source code management system and is not under Insomnia’s control.

## Collected data

If users are logged into their Insomnia account or if users have not opted out of analytics in the desktop application, we collect usage data to help improve the application. The usage analytics are collected to evaluate user behavior for the purpose of guiding product decisions.

If you use the Insomnia desktop application without an account, users have the choice to opt out of sending this information in the desktop application user interface. 

Users can opt out of sharing analytics data with Insomnia via the Insomnia app Preference Page by scrolling down to the Network Activity section and checking or unchecking the box next to Send Usage Statistics.

The following is the JSON body sent for usage data collection:
```json
{
  "anonymousId": "device-Specific-UUID-here",
  "context": {
 "app": {
   "name": "Insomnia",
   "version": "8.2.0"
 },
 "library": {
   "name": "@segment/analytics-node",
   "version": "1.0.0"
 },
 "os": {
   "name": "mac",
   "version": "14.0.0"
 }
  },
  "event": "Request Executed",
  "integrations": {},
  "messageId": "node-next-message-specific-id-here",
  "originalTimestamp": "2023-10-10T09:57:53.346Z",
  "properties": {
 "mimeType": "application/json",
 "preferredHttpVersion": "default"
  },
  "receivedAt": "2023-10-10T09:58:05.056Z",
  "sentAt": null,
  "timestamp": "2023-10-10T09:57:53.346Z",
  "type": "track",
  "writeKey": "REDACTED"
}

```

## Shared responsibility model (user best-practices)

