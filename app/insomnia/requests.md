---
title: Requests in Insomnia

description: Insomnia allows you to configure and send different types of requests.

content_type: reference
layout: reference

products:
- insomnia

breadcrumbs:
- /insomnia/

tags:
- collections

related_resources:
  - text: Collections
    url: /insomnia/collections/
  - text: Keyboard Shortcuts
    url: /insomnia/keyboard-shortcuts/   

faqs:
  - q: What type of requests can I send with Insomnia?
    a: |
      Insomnia supports:
      * HTTP
      * Event streams (SSE)
      * GraphQL
      * gRPC
      * WebSocket
  - q: Does Insomnia automatically encode special characters in request URLs?
    a: |
      Yes. Insomnia automatically encodes special characters in request URLs. This behavior ensures proper formatting for HTTP requests, but it may cause issues for users who intentionally want to send characters without encoding.

  - q: How can I check the actual request URL that Insomnia sends?
    a: |
      After sending a request, open the **Timeline** tab on the right-side panel. This shows the exact encoded request that was transmitted, allowing you to verify how special characters were handled.

  - q: What can I do if auto-encoding is causing problems in my request?
    a: |
      Here are a few options for troubleshooting special character encoding issues:
      * Manually encode your request using tools like [`urlencoder`](https://www.urlencoder.org/) or [W3Schools](https://www.w3schools.com/tags/ref_urlencode.ASP)
      * Use the [Insomnia encoder plugin](https://github.com/sypbiz/insomnia-plugin-encode-uri)
      * Suggest advanced options like:
        - Per-parameter encoding toggle
        - Global workspace setting for encoding behavior
        - Character allowlist for fine-grained control
        - Disabling encoding entirely (not recommended unless necessary)
  - q: How do I delete a large request body that crashes Insomnia?
    a: |
      1. Quit Insomnia and back up your app data directory. See [Application Data](https://docs.insomnia.rest/insomnia/application-data) for location info.
      2. Open the `insomnia.requests.db` file in a code editor.
      3. Find the offending request and clear its `body` field.
      4. Search for any other uses of the same request ID and clear those `body` fields as well.
      5. Save and relaunch Insomnia.
  - q: Can I use variables in request paths?
    a: |
      Yes. Insomnia supports variables in request paths through **template tags** and **environment variables**.  
      Define variables in your environment, then reference them directly in a request URL using Liquid syntax, for example:  
      ```liquid
      {% raw %}https://api.example.com/users/{{ user_id }}{% endraw %}
      ```  
      For detailed usage examples, go to [**Pre-request scripts**](/how-to/write-pre-request-scripts/). 
---

## How do I create requests in Insomnia?

In Insomnia, requests are contained in collections. Before you can create a request, you need to create a collection. To do that, click **Create** > **Request collection** in your Insomnia project.

Once your collection is created, there are several ways to create requests. Click the `+` button and select an option:

{% table %}
columns:
  - title: Option
    key: option
  - title: Steps
    key: steps
rows:
  - option: Create a request from scratch
    steps: Select the type or request to create (HTTP, Event Stream, GraphQL, gRPC, or WebSocket).
  - option: Import a cURL command
    steps: Select **cURL**, paste your command, and click **Import**. Insomnia converts the command into a request and opens it automatically.
  - option: Import from a file (Postman collection, Swagger, OpenAPI, HAR, WSDL)
    steps: Click **From File**, select an import option (file, URL, or clipboard), specify the file to import, then click **Scan** and **Import**.
{% endtable %}

After creating or importing a request, Insomnia automatically opens it in the editor so you can review and send it immediately.

## How can I configure requests?

In Insomnia, you can configure every part of your request, and you can also add scripts and documentation.

{:.info}
> All of these options apply to HTTP, GraphQL, and event stream requests. WebSocket requests have all of these expect for methods and scripts, and gRPC requests have a completely different configuration. <!-- Link to gRPC docs? -->

{% table %}
columns:
  - title: Element
    key: element
  - title: Steps
    key: steps
rows:
  - element: Method
    steps: Select an HTTP method in the dropdown list, or add a custom method.
  - element: Endpoint
    steps: Enter a URL, and use environment variables and template tags if needed.
  - element: Path parameters
    steps: >-
      Define dynamic values that replace variables in the request path. For example, in **Path Parameters**, if the URL is `https://api.example.com/users/{id}` and you set `id = 123`, Insomnia sends the request to `https://api.example.com/users/123`.
  - element: Query parameters
    steps: >-
      In the **Params** tab, click **Add** to create a new query parameter and enter the name and value. You can also add a description. The value can be single line or multi-line text. You can use the checkbox next to the parameter to remove it from the URL without deleting it completely.
  - element: Body
    steps: In the **Body** tab, select the type of body from the dropdown list.
  - element: Authentication
    steps: >-
      In the **Auth** tab, select the authentication type from the dropdown list to get the corresponding form. If the request is in a folder, you can select **Inherit from parent** to use the folder's authentication.
  - element: Headers
    steps: >-
      In the **Headers** tab, click **Add** to create a new header and enter the name and value. You can also add a description. You can use the checkbox next to the header to remove it from the request without deleting it completely.
  - element: Scripts
    steps: In the **Scripts** tab, select **Pre-request** or **After-response** and write your script.
  - element: Docs
    steps: >-
      In the **Docs** tab, select **Write** to add documentation to the request. You can use Markdown and HTML syntax, and you can click **Preview** to see the rendered content.
{% endtable %}


## What can I do with requests?

You can simply click **Send** to send a request, but you can also click the context menu to see more options.

{:.info}
> These options are only available for HTTP and event stream requests.

{% table %}
columns:
  - title: Option
    key: option
  - title: Description
    key: description
rows:
  - option: Generate Client Code
    description: "Generate code based on your request. You can choose from a variety of languages."
  - option: Send After Delay
    description: "Send the request after the specified amount of time."
  - option: Repeat On Interval
    description: "Send the request on a loop with a specific interval. The loop needs to be stopped manually by clicking **Cancel**."
{% endtable %}


## WebSocket support in Insomnia

Insomnia supports WebSocket requests alongside REST, GraphQL, and gRPC, allowing bi-directional data flow over a persistent connection. You can configure authentication, headers, and message formats using the request interface.

WebSocket messages can be sent in JSON or raw formats, and received messages appear in the Events panel. Detailed previews are available for both sent and received messages.

## Environment variables and limitations

Insomnia 2022.6 adds support for [environment variables](/insomnia/environments/) and Nunjucks template tags in WebSocket URLs and message bodies.

Limitations include:

* Custom WebSocket protocols aren't supported.
* Syncing WebSocket requests across different Insomnia versions (pre- and post-2022.6) may result in data loss. Ensure all devices are on version 2022.6 or later when using sync.

## SOAP requests

SOAP (simple object access protocol) is an XML-based protocol used to communicate structured data. To send a SOAP request from Insomnia, select the XML body type and setting the Content-Type header to `text/xml`. Then, construct your XML body as required.

## Posting CSV data

To send CSV data in a POST request, set the request body type to **Binary file** and select your CSV file. Ensure that the appropriate `Content-Type` headers (for example, `text/csv`) are configured based on the API requirements.

This method allows you to send raw CSV files directly in the request payload.

## Generating random data in requests

Insomnia provides [template tags](/insomnia/template-tags/) that allow you to generate random data. Add a template tag in a request URL, query parameters, body, or authentication by pressing `Control+Space` and selecting a **Faker** tag. You can generate random timestamps, dates, text, and passwords.

## What can I do with folders in a request collection?

Folders can be used to organize requests, but you can also add configuration to be used by all requests in the folder:

* Authentication
* Headers
* Scripts
* Environment variables

You can also add documentation about the folder.

## Request timeout (ms)

Use the **Request timeout (ms)** preference to control how long the application waits before failing a network request.

Go to **Preferences > General > Request / Response > Request timeout (ms)**.

Enter the timeout value in milliseconds. The default is **30000 ms**. This value determines how long Insomnia allows a request to remain active before timing out during execution.

To configure request timeout behaviour for automated or CI-based workflows, use the Inso CLI.  
See the following pages for the CLI flag and configuration options:

- [Inso CLI overview](/inso-cli/)
- [Inso CLI configuration](/inso-cli/configuration/)
