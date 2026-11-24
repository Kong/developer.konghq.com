---
title: "{{ site.konnect_short_name }} Gateway Service integration in {{ site.insomnia }}"

description: "Link {{ site.konnect_short_name }} to send requests from {{ site.insomnia }} to Routes in your Gateway Services."

content_type: reference
layout: reference

breadcrumbs:
  - /insomnia/
  - /insomnia/enterprise/
min_version:
  insomnia: '13'
products:
    - insomnia
tier: enterprise

next_steps:
  - text: Link a {{ site.konnect_short_name }} Gateway Service to {{ site.insomnia }}
    url: /how-to/link-konnect-to-insomnia/

related_resources:
  - text: Security at {{ site.insomnia }}
    url: /insomnia/manage-insomnia/#security
  - text: Enterprise
    url: /insomnia/enterprise/
  - text: Enterprise account management
    url: /insomnia/enterprise-account-management/
  - text: Enterprise user management
    url: /insomnia/enterprise-user-management/
  - text: Migrate from scratch pad to Enterprise
    url: /insomnia/migrate-to-enterprise-from-scratchpad/
  - text: Link Konnect to {{ site.insomnia }}
    url: /how-to/link-konnect-to-insomnia/

faqs:
  - q: Can I use the {{ site.konnect_short_name }} integration with my on-prem Gateway?
    a: |
      No, the {{ site.konnect_short_name }} integration only works with Gateway Services hosted in {{ site.konnect_short_name }}, not on-prem {{site.base_gateway}}.
  - q: What is the "Skipped Routes" Collection?
    a: |
      The "Skipped Routes" Collection contains Routes using an unsupported protocol. You can't use the Collection runner to send requests against them.    
  - q: Why does {{ site.insomnia }} skip some Routes?
    a: |
      {{ site.insomnia }} skips Routes that use an unsupported protocol, such as SNI matching, TCP, or UDP. {{ site.insomnia }} displays the skipped Routes in a separate collection named "Skipped Routes".

---

## About the {{ site.konnect_short_name }} integration

Starting from {{ site.insomnia }} 13, Enterprise users can link {{ site.insomnia }} to Gateway Services deployed in {{ site.konnect_short_name }}. The integration allows sending requests from Collections against Routes pulled from {{ site.konnect_short_name }}, using the {{ site.insomnia }} app.

After connecting and syncing your Gateway Services, {{ site.insomnia }}:

- Displays the list of your control planes in {{ site.konnect_short_name }} as projects.
- Nests the Gateway Services on each control plane as Collections under each project.
- Pulls the Routes from each Gateway Service.
- Lists the Routes in Collections for each Gateway Service.

### Requirements

- An {{ site.insomnia }} [Enterprise account](/insomnia/enterprise/)
- A {{ site.konnect_short_name }} [Gateway Service](/gateway/).
- A [Personal Access Token (PAT)](/konnect-api/#personal-access-tokens) 

## Available features

Collections work the same as for local Routes. The following table lists the features that allow you to link {{ site.insomnia }} to {{ site.konnect_short_name }}:

{% table %}
columns:
  - title: Feature
    key: feature
  - title: Usage
    key: usage
  - title: How to
    key: how
rows:
  - feature: "Authenticate"
    usage: "Link {{ site.insomnia }} to your Gateway Service"
    how: |
      1. From {{ site.konnect_short_name }}, generate a [Personal Access Token (PAT)](/konnect-api/#personal-access-tokens).
      1. Copy the PAT.
      1. In {{ site.insomnia }}, open **Preferences** > **Konnect**.
      1. Paste the PAT.
      1. Click **Validate & Save**.
  - feature: |
      **Konnect** tab
    usage: |
      List your gateway services in {{ site.konnect_short_name }}, next to the **Projects** tab
    how: |
      Open the personal workspace linked to {{ site.konnect_short_name }}.
  - feature: "Sync"
    usage: "Pull the latest updates from {{ site.konnect_short_name }} into {{ site.insomnia }}."
    how: |
      From the **Konnect** tab, click **Sync**.
  - feature: |
      **Plugins** tab
    usage: "List the {{ site.konnect_short_name }} plugins that can apply to a synced request. {% new_in 13.5 %}"
    how: |
      Open a synced request and click the **Plugins** tab in the request pane. See [Plugins tab](#plugins-tab).
  - feature: "Debugger"
    usage: "Capture traces from your data plane nodes with a {{ site.konnect_short_name }} debug session. Available in {{ site.insomnia }} 13.5 and later."
    how: |
      Send a synced request and click **Debug** in the response pane. See [Debugger](#debugger).
{% endtable %}

### Sync

Every time you click **Sync** from the {{ site.konnect_short_name }} tab, {{ site.insomnia }} pulls changes from {{ site.konnect_short_name }}. Syncing:

- Doesn't push any changes from {{ site.insomnia }} to {{ site.konnect_short_name }}.
- Pulls changes or configurations from {{ site.konnect_short_name }} for the related Routes.


This preserves the local changes on Routes while allowing pulling any updates from {{ site.konnect_short_name }}.

Syncing preserves or resets the following data for each pulled route in {{ site.insomnia }}:


- Parameters
- Auth
- Body
- Custom headers
- Scripts
- Environment variables

{:.info}
Note: Overridden headers aren't preserved. They revert to the values configured in {{ site.konnect_short_name }}.

## Plugins tab

{% new_in 13.5 %} Requests synced from {{ site.konnect_short_name }} have a **Plugins** tab in the request pane. The tab is available for HTTP, gRPC, and WebSocket requests in a project linked to a {{ site.konnect_short_name }} control plane. It lists every plugin instance that can apply to the request's Route.

{{ site.insomnia }} skips plugins scoped to other Routes or Gateway Services, and plugins whose protocols don't match the Route's protocol.

If the plugin has a condition or uses [dynamic plugin ordering](/gateway/entities/plugin/#dynamic-plugin-ordering), {{ site.insomnia }} shows that too. {{ site.insomnia }} doesn't display plugin configuration values.

Each plugin has the following actions:

* **Docs**: Opens the plugin's documentation.
* **Edit in Konnect**: Opens the plugin's configuration page in {{ site.konnect_short_name }}.
* **decK command**: Shows the [decK](/deck/) commands to export the control plane configuration, edit the plugin in the exported file, and apply the change.

Click **Refresh** to reload the plugins from {{ site.konnect_short_name }}, or click **View all in Konnect** to open the control plane's plugin list.

### Suggested plugins

The **Suggested plugins** section lists commonly used plugins that aren't applied to the Route yet, such as [Key Authentication](/plugins/key-auth/), [OpenID Connect](/plugins/openid-connect/), or [CORS](/plugins/cors/). {{ site.insomnia }} only suggests plugins that are available on the control plane. Each suggestion has a **Docs** action, an **Add in Konnect** action, and a **decK command** action that shows a starting configuration for the plugin.

### Plugins tab limitations

* The plugin tab lists every configured plugin instance in the order the {{ site.konnect_short_name }} API returns them, not in execution order. For more information, see [plugin priority](/gateway/entities/plugin/#plugin-priority).
* {{ site.insomnia }} caches the plugin list for one minute. Click **Refresh** to load the latest changes from {{ site.konnect_short_name }}.
* The decK command for a suggested plugin includes an empty `config` block. Fill in the required configuration fields from the plugin documentation before you apply it.

## Debugger

{% new_in 13.5 %} You can start a [{{ site.konnect_short_name }} Debugger](/observability/debugger/) session from {{ site.insomnia }} and view the captured traces without leaving the app.

To open the Debugger, do one of the following:

* After you send a synced request, click **Debug** in the response pane.
* In the sidebar, open the dropdown menu of a {{ site.konnect_short_name }} project and select "Start Debugging".

The Debugger opens in a new tab for the project's control plane. To capture traces, do the following:

1. From the **Duration** dropdown menu, select a duration between "15 seconds" and "30 minutes".
1. Click **Start debugging**.
1. Send requests to the Routes on this control plane.
1. Click a trace in the **Captured** list to view its details.

To end the session before the duration runs out, click **Stop**. After a session ends, click **Restart** to start a new one.

The trace details show the response status, time, and size, and a link to the matching request in your collection when {{ site.insomnia }} finds one. A time split shows how much of the request was spent in each of the following parts:

* **Kong (internal)**
* **Upstream**
* **Client**
* **3rd-party**

The waterfall under the time split lists each [span](/observability/debugger-spans/) of the trace. Click a span name to view its attributes.

### Debugger requirements

* A {{ site.konnect_short_name }} personal access token configured in {{ site.insomnia }}.
* At least one data plane node connected to the control plane.
* The [requirements for {{ site.konnect_short_name }} Debugger](/observability/debugger/#start-your-first-debug-session), including the {{site.base_gateway}} version and the permissions needed to create debug sessions.

### Debugger limitations

* The session captures traces for all traffic on every data plane node of the control plane, not only the requests you send from {{ site.insomnia }}. You can't set sampling rules from {{ site.insomnia }}. To narrow a session, start it from {{ site.konnect_short_name }} instead.
* {{ site.konnect_short_name }} allows one active debug session per data plane node. If a session is already running on the control plane's nodes, starting a new one returns an error.