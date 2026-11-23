---
title: Collected data

description: "{{ site.insomnia }} collects usage analytics data to help improve the application."
breadcrumbs: 
  - /insomnia/manage-insomnia/
search_aliases:
  - usage analytics
content_type: reference
layout: reference
related_resources:
  - text: Security at {{ site.insomnia }}
    url: /insomnia/manage-insomnia/#security
  - text: Storage options
    url: /insomnia/storage/
  - text: "{{ site.insomnia }} terminology"
    url: /insomnia/terminology/
products:
    - insomnia

faqs:
  - q: What specific data does {{ site.insomnia }} collect?
    a: |
      {{ site.insomnia }} collects information like the following JSON:

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
  - q: Do you retain server logs, or event logs?
    a: All server logs stored are kept within GCP and only accessed by engineers authorized to manage the {{ site.insomnia }} servers.
  - q: I use the desktop {{ site.insomnia }} app, how do I opt out of data collection?
    a: If you use the {{ site.insomnia }} desktop application without an account, users have the choice to opt out of sending this information in the desktop application user interface. Users can opt out of sharing analytics data with {{ site.insomnia }} via the {{ site.insomnia }} app Preference Page by scrolling down to the Network Activity section and checking or unchecking the box next to Send Usage Statistics.
  - q: Do you retain server logs, or event logs?
    a: All server logs stored are kept within GCP and only accessed by engineers authorized to manage the {{ site.insomnia }} servers.
  - q: What does end-to-end encryption (E2EE) mean in {{ site.insomnia }}?
    a: |
      End-to-end encryption means that all encryption keys are generated locally on your device. 
      All data is encrypted before being sent and only decrypted after being received. 
      At no point during synchronization can {{ site.insomnia }} servers—or anyone with access to those servers—read your encrypted project data.

  - q: What is considered project data in {{ site.insomnia }}?
    a: |
      Project data includes your API design specifications, collections, tests, and other files that you choose to sync and share through {{ site.insomnia }}’s hosted service.

      Data used with artificial intelligence tools is **not** end-to-end encrypted and is excluded from this protection.

  - q: What encryption algorithms does {{ site.insomnia }} use?
    a: |
      {{ site.insomnia }} uses randomly generated 256-bit symmetric keys with `AES-GCM-256` (Galois Counter Mode) to encrypt project data.

  - q: What happens if I forget my passphrase?
    a: |
      If you lose your passphrase, you lose the ability to decrypt your encrypted project data.

      If you were part of an organization, you can be re-invited to recover shared data. 
      If you shared data with others, they can re-invite you to restore access.

  - q: Are any parts of my encrypted data sent in plaintext?
    a: |
      Yes. While project data is fully encrypted, the `id` and `name` of each resource are sent in plaintext along with the encrypted payload.

  - q: Is {{ site.insomnia }} project data encrypted on disk?
    a: |
      No. Project data is stored in raw form on disk. E2EE applies only to data transmitted over the network. 
      You should take appropriate measures to secure your local environment from unauthorized access.
  - q: Where does {{ site.insomnia }} store application data?
    a: |
      {{ site.insomnia }} stores local data in platform-specific `appData` directories:

      * `%APPDATA%\Insomnia` on Windows
      * `$XDG_CONFIG_HOME/Insomnia` or `~/.config/Insomnia` on Linux
      * `~/Library/Application Support/Insomnia` on macOS

      You can access this via **Help** > **Show App Data Folder** in the UI. Files are stored as `insomnia.<resource>.db`.
  - q: Where does {{ site.insomnia }} store logs?
    a: |
      Logs are stored in the following locations:

      * `%APPDATA%\Insomnia\logs` on Windows
      * `$XDG_CONFIG_HOME/Insomnia/logs` or `~/.config/Insomnia/logs` on Linux
      * `~/Library/Logs/Insomnia` on macOS

      Access the log folder via **Help** > **Show App Logs Folder**.
  - q: Where does {{ site.insomnia }} store environment information on a Linux Snap install?
    a: |
      Snap installations store user data and environment settings in the following locations:
      * `/var/snap/`: For system-level snap data
      * `~/snap/`: For user-level, versioned snap data
  - q: Where is my data stored when using {{ site.insomnia }} sync features?
    a: |
      The storage location depends on the sync method you're using:

      * **Cloud sync** – Data is stored in Postgres databases hosted in the Google Cloud Platform (GCP) `us-central1` region.
      * **Git sync** – Data is stored in the underlying storage of your connected source control system (e.g., GitHub, GitLab) and is not managed by {{ site.insomnia }}.
  - q: Does {{ site.insomnia }} sanitize or redact data before sending it to the AI model?
    a: |
      No. {{ site.insomnia }} doesn't inspect, sanitize, redact, or transform AI prompts or responses.
      The data is sent directly to the configured AI model provider. Any data protection, filtering, or handling controls must be handled by the selected model provider or in your own environment.

---

If users are logged into their {{ site.insomnia }} account or if they haven't opted out of analytics in the desktop application, we collect usage data to help improve the application. The usage analytics are collected to evaluate user behavior for the purpose of guiding product decisions.

{{ site.insomnia }} collects usage data like the following:
* {{ site.insomnia }} app version
* OS name and version
* Events (like executing a request)
* Preferred HTTP version



## Data models

The following are data models {{ site.insomnia }} uses:


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
    definition: An entity that can be synced (e.g., Request, Workspace, etc.)
  - model: "`M_ResourceGroup`"
    definition: A group of M_Resource that can be shared as one
  - model: "`M_Link`"
    definition: A relationship linking a M_Account to M_ResourceGroup
{% endtable %}


## Keys and Salts

The following are keys and salts {{ site.insomnia }} uses.


{% table %}
columns:
  - title: Name
    key: name
  - title: Description
    key: description
  - title: Stored?
    key: stored
rows:
  - name: "`PUB_Account`"
    description: Public key for M_Account
    stored: Yes
  - name: "`PRV_Account`"
    description: Private key for M_Account
    stored: Yes
  - name: "`SYM_Account`"
    description: Symmetric key for M_Account
    stored: Yes
  - name: "`SYM_ResourceGroup`"
    description: Symmetric Key for data encryption
    stored: No
  - name: "`SYM_Link`"
    description: Encrypted form of SYM_ResourceGroup
    stored: Yes
  - name: "`SLT_Auth_1`"
    description: Salt for PBKDF2 of passphrase for auth
    stored: Yes
  - name: "`SLT_Auth_2`"
    description: Salt for SRP authentication process
    stored: Yes
  - name: "`SLT_Enc`"
    description: Salt for PBKDF2 of passphrase for encryption
    stored: Yes
  - name: "`SEC_PWD_Auth`"
    description: Secret derived from passphrase using SLT_Auth_1
    stored: No
  - name: "`SEC_PWD_Enc`"
    description: Secret derived from passphrase using SLT_Enc
    stored: No
  - name: "`SRP_Verifier`"
    description: Verification string used for SRP
    stored: Yes
{% endtable %}

**Note**: `SYM_Link` and `SYM_ResourceGroup` are essentially the same thing, but are defined separately for the purpose of discussion. This will become clear later on.

## Data handling

{{ site.insomnia }}’s AI features are designed so that Kong doesn't collect, store, or process customer data.

When you use an AI feature, {{ site.insomnia }} sends the data for AI processing only to the AI model provider you configured. {{ site.insomnia }} doesn't proxy, inspect, or retain AI prompts, responses, or intermediate data.

Depending on your configuration, AI processing can occur in one of the following locations:
- **Locally**: A local large language model that runs entirely on your machine
- **In your environment**: A self-hosted model endpoint
- **With a third-party AI provider**: In accordance with that provider’s data handling policies

{{ site.insomnia }} doesn't store AI-related data on Kong-managed servers or control the configured AI model provider’s data handling or processing behavior.

Enterprise administrators can enable or disable AI features in {{ site.insomnia }} Admin, from **Policies** > **Governance** > **AI Features**. This lets your organization either:
- Disable AI features entirely
- Allow AI features only in approved environments

For more information, navigate to [AI in {{ site.insomnia }}](/insomnia/ai-in-insomnia/#get-started).