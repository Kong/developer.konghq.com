---
title: Write tests for HTTP status codes in Insomnia
permalink: /how-to/write-http-status-tests/
content_type: how_to
description: Learn how to write HTTP status code tests in Insomnia.

related_resources:
  - text: Test APIs
    url: /insomnia/test/
  - text: Write tests for headers in the response in Insomnia
    url: /how-to/write-headers-in-response-test/
  - text: Write tests for content types in Insomnia
    url: /how-to/write-content-type-tests/
  - text: Write tests for data types in Insomnia 
    url: /how-to/write-data-type-tests/
  - text: Automate tests in Insomnia
    url:  /how-to/automate-tests/
  - text: Chain requests in Insomnia
    url: /how-to/chain-requests/

products:
    - insomnia

tags:
    - test-apis

automated_tests: false

tldr:
    q: How do I write HTTP status code tests in Insomnia?
    a: After you add a collection, you can create a new test suite for the collection and then use the default Javascript test. 

prereqs:
    inline:
        - title: Create and configure a collection
          include_content: prereqs/create-collection
          icon_url: /assets/icons/menu.svg
cleanup:
  inline:
    - title: Clean up Insomnia
      include_content: cleanup/products/insomnia
      icon_url: /assets/icons/insomnia/insomnia.svg
---

## Create a test suite

{% include /how-tos/steps/insomnia-test-suite.md %}

## Create an HTTP status code test

We can create a test that checks a request against a certain status code. 

From the Test Suite we just created, click **New test**. Insomnia creates a default `Return 200` request:
```javascript
const response1 = await insomnia.send();
expect(response1.status).to.equal(200);
```

## Validate

We can validate that our test works by testing a request.

From the **Select a request** drop down, select the **GET KongAir planned flights** request.
{% include /how-tos/steps/insomnia-run-tests.md %}