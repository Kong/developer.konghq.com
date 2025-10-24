---
title: API specs in Insomnia

description: API specifications explain how an API behaves and how it interacts with other APIs.

content_type: reference
layout: reference

related_resources:
  - text: Design APIs in Insomnia
    url: /insomnia/design/
  - text: Create a design document in Insomnia
    url: /how-to/create-a-design-document/
  - text: Generate a collection from a design document
    url: /how-to/generate-a-collection-from-a-design-document/

tags:
    - insomnia-documents
    - collections
    - design-apis

products:
    - insomnia

faqs:
  - q: What API spec formats are supported in Insomnia?
    a: Specs must be in the OpenAPI 2.0.x or later format. You can create specs for a REST API or GraphQL API.
  - q: Why is a preview not displaying for my spec?
    a: Check to make sure your spec is in the OpenAPI 2.0.x or later format. Next, check for any errors in the linting and resolve those.
  - q: Why can't I generate a collection from the API spec in my design document?
    a: Check the linting errors, if there's any warning level errors, you won't be able to generate a collection from your spec.
  - q: How do I migrate my specs from another API client, like Postman, to Insomnia?
    a: You can import any of your specs from another API client to Insomnia. Just import the file in your Insomnia workspace. 
  - q: Can I create a GraphQL API spec in Insomnia?
    a: Yes. For Insomnia to autodetect that your spec is in GraphQL format, the path must be `/graphql`, the method must be `POST`, the request body must be application/json and must contain a property query with the type string, and the response body must be application/json.
  - q: Can I create a spec in a collection?
    a: No, you can import an existing spec into a collection, but you can only create a new API spec in a document.

breadcrumbs:
  - /insomnia/
---

## What are API specs?

API specifications explain how an API behaves and how it interacts with other APIs.

API specs can function like API documentation, but they also explain the values, parameters, and objects in the schema of the API. An API spec helps users know how to make requests to the APIs contained within the spec.

## How does Insomnia parse API specs?

Insomnia parses the following from your API specs and displays these in the sidebar of the API spec in the Insomnia UI:

<!--vale off-->
{% table %}
columns:
  - title: API spec definition
    key: spec
  - title: Object in Insomnia
    key: object
rows:
  - spec: "`description`"
    object: Displays in the Docs tab of a request.
  - spec: info
    object: Displays in the left-sidebar of the spec under INFO.
  - spec: "`servers.url`"
    object: Displays in the left-sidebar of the spec under SERVERS.
  - spec: "`paths`"
    object: Displays in the left-sidebar of the spec under PATHS.
  - spec: "`requestBodies`"
    object: Displays in the left-sidebar of the spec under REQUEST BODIES.
  - spec: "`schemas`"
    object: Displays in the left-sidebar of the spec under SCHEMAS.
  - spec: "`securitySchemes`"
    object: Authentication information and options. Displays in the left-sidebar of the spec under SECURITY.
  - spec: "`responses`"
    object: List of structured, expected responses for each request. Displays in the left-sidebar of the spec under RESPONSES.
  - spec: "`parameters`"
    object: List of parameters that the API recognizes. Displays in the left-sidebar of the spec under PARAMETERS.
{% endtable %}
<!--vale on-->


## What can I do with API specs in Insomnia?

The following sections provide common API spec use cases you can solve with Insomnia.

<!--vale off-->

### Manage API specs

{% table %}
columns:
  - title: Use case
    key: usecase
  - title: Instructions
    key: instructions
rows:
  - usecase: Create a new spec directly in the Insomnia editor
    instructions: |
      In your Insomnia workspace, click **Create** and select **Design document**. Your spec editor is in the center pane. 
      <br>For more information, see [Create a design document](/how-to/create-a-design-document/).
  - usecase: Import an existing spec
    instructions: |
      In your workspace, click **Import** and select the source of the import: **File**, **URL**, or **Clipboard**. 
      <br>For more information, see [Import an API specification as a design document in Insomnia](/how-to/import-an-api-spec-as-a-document/).
{% endtable %}

### Linting

{% table %}
columns:
  - title: Use case
    key: usecase
  - title: Instructions
    key: instructions
rows:
  - usecase: Automatic linting on your specs (new or imported) directly in Insomnia
    instructions: |
      Navigate to the design document with your API spec. The linting error messages display below the center pane.
  - usecase: Automate linting on specs using the Inso CLI
    instructions: |
      Run `inso lint spec` and select the spec from the list that displays. 
      <br>For more information, see the [`inso lint spec` reference](/inso-cli/reference/lint_spec/).
  - usecase: Use custom linting to ensure your spec adheres to your team or company's standards
    instructions: |
      To lint locally, create a `.spectral.yaml` file with the custom rules in the same directory as the `oas.yaml` file you want to lint. Then run `inso lint spec ./oas.yaml` from that directory. <br><br>
      To [apply custom lint rules in the Insomnia UI](/how-to/add-custom-linting-rules/), add the `.spectral.yaml` file to the root of the collection git repository at the same level as the `.insomnia` folder.
{% endtable %}

### Work with requests

{% table %}
columns:
  - title: Use case
    key: usecase
  - title: Instructions
    key: instructions
rows:
  - usecase: Automatically generate a collection and requests from your spec
    instructions: |
      From your design document with your API spec, click the **Settings** icon and select **Generate collection**. 
      <br>For more information, see [Generate a collection from a design document](/how-to/generate-a-collection-from-a-design-document/).
  - usecase: Use mock servers to mock your requests
    instructions: |
      Run a request, then click the **Mock** tab in the response pane. Create a new mock server there along with the route for the request. 
      <br>For more information, see [Mock server](/insomnia/mock-servers/).
{% endtable %}

### Collaboration

{% table %}
columns:
  - title: Use case
    key: usecase
  - title: Instructions
    key: instructions
rows:
  - usecase: Collaborate with a team on API specs using Git sync and version control
    instructions: |
      You can collaborate on API specs by cloning your existing repository with the specs. 
      <br>For more information, see [how to Git sync in Insomnia](/insomnia/storage/#git-sync).
{% endtable %}

<!--vale on-->