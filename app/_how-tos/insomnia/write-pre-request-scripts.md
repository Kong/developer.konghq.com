---
title: Write a pre-request script to add an environment variable in Insomnia
permalink: /how-to/write-pre-request-scripts/
content_type: how_to
description: Write a pre-request script to dynamically set a variable in a request.
related_resources:
  - text: Scripts in Insomnia
    url: /insomnia/scripts/
  - text: Automate tests in Insomnia
    url:  /how-to/automate-tests/
  - text: Chain requests in Insomnia
    url: /how-to/chain-requests/
  - text: Write an after-response script to test a response in Insomnia
    url: /how-to/write-after-response-script/

products:
    - insomnia

tags:
    - test-apis

tldr:
    q: How can I carry out pre-processing such as setting variable values, parameters, headers, and body data for requests in Insomnia?
    a: Use pre-request scripts on a collection in Insomnia to carry out pre-processing such as setting variable values, parameters, headers, and body data for requests.

faqs:
  - q: Can I migrate my pre-request scripts from another API client, like Postman, to Insomnia?
    a: Yes, you can copy and paste your pre-request scripts directly from Postman into an Insomnia pre-request script.
  - q: Can I run pre-request scripts without a collection?
    a: No, you can only run pre-request scripts from a collection or a collection that was generated from a document.
  - q: Can I use variables in request paths?
    a: |
      Yes. Insomnia supports variables in request paths through **template tags** and **environment variables**.  
      
      Define variables in your environment, then reference them directly in a request URL using Liquid syntax, for example:  
      ```liquid
      {% raw %}https://api.example.com/users/{{ user_id }}{% endraw %}
      ```  
      For detailed usage examples, go to [**Requests**](/insomnia/requests/#faqs) and [**Pre-request scripts**](/how-to/write-pre-request-scripts/).  

prereqs:
    inline:
        - title: Create and configure a collection
          include_content: prereqs/create-collection
          icon_url: /assets/icons/menu.svg
---

## Add a pre-request script

In this example, we'll configure a pre-request script that sets a variable in the request:

1. In Insomnia, navigate to the "Flight Service 0.1.0" document.
1. Click the **Collection** tab in the sidebar.
1. In the sidebar of your collection, select the **Get a specific flight by flight number** request.
1. Click the **Scripts** tab on the request.
1. Insomnia provides example pre-request scripts. From the **Pre-request** tab, click **Variable Snippets** at the bottom of the pane and select **Set an environment variable**.
1. In the example script, replace `variable_name` with `flightNumber` and `variable_value` with `KA0285`. The script should look like the following:
```javascript
insomnia.environment.set("flightNumber", "KA0285");
```

## Validate the pre-request script

Now that we created a pre-request script, we can validate it by sending a GET request to the `/flights/{flightNumber}` endpoint.

Click **Send**. You should get a `200` status code and the following response:
```json
{
	"number": "KA0285",
	"route_id": "LHR-SFO",
	"scheduled_arrival": "2024-04-03T11:10:00Z",
	"scheduled_departure": "2024-04-03T22:15:00Z"
}
```
