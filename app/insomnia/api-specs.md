---
title: API specs in Insomnia

description: API specifications explain how an API behaves and how it interacts with other APIs.

content_type: reference
layout: reference

related_resources:
  - text: Design APIs in Insomnia
    url: /insomnia/design/
  - text: Create an API Collection in Insomnia
    url: /how-to/create-an-api-collection/
  - text: Generate requests from an API spec in Insomnia
    url: /how-to/generate-requests-from-an-api-spec/

tags:
    - collections
    - design-apis

products:
    - insomnia

faqs:
  - q: What API spec formats are supported in Insomnia?
    a: Specs must be in the OpenAPI 2.0.x or later format. You can create specs for a REST API or GraphQL API.
  - q: Why is a preview not displaying for my spec?
    a: Check to make sure your spec is in the OpenAPI 2.0.x or later format. Next, check for any errors in the linting and resolve those.
  - q: Why can't I generate requests from the API spec in my API Collection?
    a: Check the linting errors, if there's any warning level errors, you won't be able to generate requests from your spec.
  - q: How do I migrate my specs from another API client, like Postman, to Insomnia?
    a: You can import any of your specs from another API client to Insomnia. Just import the file in your Insomnia workspace. 
  - q: Can I create a GraphQL API spec in Insomnia?
    a: Yes. For Insomnia to autodetect that your spec is in GraphQL format, the path must be `/graphql`, the method must be `POST`, the request body must be application/json and must contain a property query with the type string, and the response body must be application/json.
  - q: Can I create a spec in an API Collection?
    a: "Yes. {% new_in 13.3 %} Every API Collection can hold one OpenAPI spec. Click the **Spec** tab on the API Collection screen to write a new spec or import an existing one. In Insomnia 13.2 and earlier, you could only create a spec in a separate workspace type called a design document."

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
      In your Insomnia workspace, click **Create** and select **API Collection**, then click the **Spec** tab. Your spec editor is in the center pane. 
      <br>For more information, see [Create an API Collection](/how-to/create-an-api-collection/).
  - usecase: Import an existing spec
    instructions: |
      In your workspace, click **Import** and select the source of the import: **File**, **URL**, or **Clipboard**. 
      <br>For more information, see [Import an API specification into an API Collection in Insomnia](/how-to/import-an-api-spec/).
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
      Navigate to the API Collection with your API spec and click the **Spec** tab. The linting error messages display below the center pane.
  - usecase: Automate linting on specs using the Inso CLI
    instructions: |
      Run `inso lint spec` and select the spec from the list that displays. 
      <br>For more information, see the [`inso lint spec` reference](/inso-cli/reference/lint_spec/).
  - usecase: Use custom linting to ensure your spec adheres to your team or company's standards
    instructions: |
      To lint locally, create a YAML file in the project with the custom rules in the same directory as the `oas.yaml` file you want to lint. The Inso CLI picks the rules regardless of the file name. Then run `inso lint spec ./oas.yaml` from that directory. <br><br>
      To [apply custom lint rules in the Insomnia UI](/how-to/add-custom-linting-rules/), upload a ruleset YAML file to the project that contains the API Collection you want to lint.
{% endtable %}

### Work with requests

{% table %}
columns:
  - title: Use case
    key: usecase
  - title: Instructions
    key: instructions
rows:
  - usecase: Automatically generate requests from your spec
    instructions: |
      From the **Spec** tab of your API Collection, click **Generate** and select "Requests". Insomnia adds a request for each endpoint in your spec. 
      <br>For more information, see [Generate requests from an API spec](/how-to/generate-requests-from-an-api-spec/).
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