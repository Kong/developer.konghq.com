---
title: Write tests for headers in the response in Insomnia
permalink: /how-to/write-headers-in-response-tests/
content_type: how_to
description: Learn how to write header tests in Insomnia.
related_resources:
  - text: Write tests for HTTP status codes in Insomnia
    url: /how-to/write-http-status-tests/
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

tldr:
    q: How do I write tests for response headers in Insomnia?
    a: Legacy unit tests are hidden by default since Insomnia 13.3. After you enable them and add an API Collection, you can create a new test suite for the API Collection and then create individual tests in the suite.

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

{% include insomnia/legacy-tests-deprecation.md %}

## Create a test suite

{% include /how-tos/steps/insomnia-test-suite.md %}

## Create a headers in response test

Now we can test if a header is returned in the response. 

1. Click **New test** and enter a name for the test, such as "Header in the body". 
1. From the **Select a request** drop down, select the **GET KongAir planned flights** request.
1. Enter the following JavaScript to check if there are any headers in the response:
   ```javascript
   const response1 = await insomnia.send();
   expect(Object.keys(response1.headers).length).to.be.greaterThan(0);
   const body = JSON.parse(response1.data);
   const item = body[1];
   expect(item).to.be.an('object');
   ```
{% include /how-tos/steps/insomnia-run-tests.md %}