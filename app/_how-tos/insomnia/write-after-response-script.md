---
title: Write an after-response script to test a response in Insomnia
permalink: /how-to/write-after-response-script/
content_type: how_to
description: Write an after-response script to check that the response body contains the expected value.
related_resources:
  - text: Scripts in Insomnia
    url: /insomnia/scripts/
  - text: Automate tests in Insomnia
    url:  /how-to/automate-tests/
  - text: Chain requests in Insomnia
    url: /how-to/chain-requests/
  - text: Write a pre-request script to add an environment variable in Insomnia
    url: /how-to/write-pre-request-scripts/

products:
    - insomnia

tags:
    - test-apis

tldr:
    q: How can I run tests on responses in Insomnia?
    a: In your request, go to **Scripts** > **After-response** and use `insomnia.test()` to create a test, then write the code for the test and send the request to validate it. 

prereqs:
    inline:
        - title: Create and configure a collection
          include_content: prereqs/create-collection
          icon_url: /assets/icons/menu.svg
---

## Add an after-response script

In this example, we'll configure an after-response script that checks the value of a JSON field in a response:

1. In Insomnia, navigate to the "Flight Service 0.1.0" document.
1. Click the **Collection** tab in the sidebar.
1. In the sidebar of your collection, select the **Get KongAir planned flights** request.
1. Open **Scripts** > **After-response**.
1. In the bottom pane, click **Response Handling** > **Get body as JSON**. This will add code that creates a `jsonBody` variable that we can use to check the content of the response body.
1. Add the following content after the variable:
   ```js
   insomnia.test('Check the first route ID', () => {
    insomnia.expect(jsonBody[0].route_id).to.eql('LHR-JFK');
    });
   ```

   In this example, `insomnia.test()` creates a new test, and `insomnia.expect()` creates an assertion on the value of the `route_id` field in the first object of the array returned by the request.

## Validate the after-response script

Now that we created an after-response script, we can validate it by sending a GET request to the `/flights/` endpoint.

Click **Send**. You should get a `200` status code with a JSON array as the response. Go to the **Tests** tab in the right pane to check that the test passed.