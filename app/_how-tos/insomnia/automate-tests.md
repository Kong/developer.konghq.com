---
title: Automate tests in Insomnia
permalink: /how-to/automate-tests/
content_type: how_to

description: Automate tests written in Insomnia using the Inso CLI.

related_resources:
  - text: Write tests for headers in the response in Insomnia
    url: /how-to/write-headers-in-response-test/ 
  - text: Write tests for HTTP status codes in Insomnia
    url: /how-to/write-http-status-tests/
  - text: Write tests for content types in Insomnia
    url: /how-to/write-content-type-tests/
  - text: Automate tests in Insomnia
    url:  /how-to/automate-tests/
  - text: Chain requests in Insomnia
    url: /how-to/chain-requests/

products:
    - insomnia

tools:
    - inso-cli

tags:
    - test-apis

tldr:
    q: How do I automate tests in Insomnia?
    a: You can automate tests written in Insomnia by using the Inso CLI with the `inso run test "document name" --env "environment name"` command.

prereqs:
    inline:
        - title: Create and configure a collection
          include_content: prereqs/create-collection
          icon_url: /assets/icons/menu.svg
        - title: Write a test
          include_content: prereqs/tests
          icon_url: /assets/icons/insomnia/checkbox-active.svg
---

## Run a test with Inso CLI in the command line

You can use the `inso run test` command to execute unit tests written inside Insomnia from your terminal or in a CI/CD environment. Once the command is executed, the Inso CLI will report test results and exit with an exit code. 

Run the following to test the `Flights Service 0.1.0` document in the `OpenAPI env api.kong-air.com` environment:

```sh
inso run test "Flights Service 0.1.0" --env "OpenAPI env api.kong-air.com"
```

You should get a report saying which tests were conducted and that the one test you set up passed. For example:

```sh
  New Suite
    ✔ Returns 200 (1576ms)


  1 passing (2s)
```