---
title: Request and Response Settings

description: Reference documentation for all Request and Response settings available in Insomnia Desktop.

content_type: reference
layout: reference

products:
- insomnia

breadcrumbs:
- /insomnia/

related_resources:
  - text: Collections
    url: /insomnia/collections/
  - text: Keyboard Shortcuts
    url: /insomnia/keyboard-shortcuts/
  - text: Requests in Insomnia
    url: /insomnia/requests/  

faqs:
    - q: How do I configure request timeout behaviour for automated or CI workflows?
      a: |
       Insomnia Desktop includes a **Request timeout (ms)** preference that applies to interactive requests made from the application interface.

       For automated or CI-driven execution, configure request timeout behaviour in the **Inso CLI**.

       Use the `--request-timeout <milliseconds>` flag to set the timeout for a single run, for example:

       ```bash
       inso run collection wrk_123 --request-timeout 30000
       ```

       To set a default timeout for all CLI operations, add the corresponding option to your `.insorc` file:

       ```yaml
       options:
         requestTimeout: 30000
       ```

       See the following pages for full details:

       - [Inso CLI overview](/inso-cli/)
       - [Inso CLI configuration](/inso-cli/configuration/)

    - q: Where do I find the request timeout setting in Insomnia?
      a: |
       Go to **Preferences > General > Request / Response > Request timeout (ms)**.

       Enter the timeout value in milliseconds. The default value is **30000 ms**.

---
Insomnia provides options that control how requests are sent and how responses are displayed.  

These settings cover network behaviour, security validation, redirect handling, request timeouts, and response-viewer limits.

All of the following settings are available in **Preferences > General > Request / Response**:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Description
    key: description
rows:
  - setting: Validate certificates
    description: "Validate SSL certificates for HTTPS requests. Disable this setting only when working with untrusted or development certificates. The default value is enabled."
  - setting: Follow redirects
    description: "Follow HTTP 3xx redirects until the redirect limit is reached. The default value is enabled."
  - setting: Filter responses by environment
    description: "Show only responses that were executed within the currently selected environment."
  - setting: Disable JS in HTML preview
    description: "Prevent JavaScript from running in the HTML preview pane when viewing HTML responses."
  - setting: Disable links in response viewer
    description: "Disable clickable links in the response viewer to avoid accidental navigation."
  - setting: Disable default User-Agent on new requests
    description: "Create new requests without a default User-Agent header."
  - setting: Preferred HTTP version
    description: "Select the HTTP version used when sending requests. Available options include Default, HTTP/1.1, and HTTP/2."
  - setting: Maximum redirects
    description: "Set how many redirects Insomnia follows automatically. The default value is 10."
  - setting: Request timeout (ms)
    description: "Set how long Insomnia waits before failing a network request. The value is in milliseconds. The default value is 30000."
  - setting: Response history limit
    description: "Define how many past responses Insomnia stores and displays. The default value is 20."
  - setting: Max timeline chunk size (KiB)
    description: "Set the maximum size of a timeline chunk in the response viewer to manage memory usage. The default value is 10 KiB."
{% endtable %}
