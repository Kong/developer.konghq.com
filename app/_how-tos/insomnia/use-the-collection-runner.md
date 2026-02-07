---
title: Use the Collection Runner in Insomnia
permalink: /how-to/use-the-collection-runner/
content_type: how_to
description: Use the Collection Runner to run multiple requests in a specific order.
products:
    - insomnia

tags:
    - collections
prereqs:
    inline:
        - title: Create and configure a collection
          include_content: prereqs/collection
          icon_url: /assets/icons/menu.svg

tldr:
    q: How can I send multiple requests in a specific order?
    a: Open a collection, click its name and click **Run Collection**, order and select the requests to send, and click **Run**.
    
---

## Configure the variables

In this example, we want to get a list of KongAir flights and then get more information about a specific flight. 

In the _Fetch more details about a flight_ request, we need to replace the `flightNumber` variable with an actual value. We can either [get this value from a response](/how-to/chain-requests/), or click the variable and enter a value (_KA0284_ for example).

## Order and select the requests

Click the name of the collection and click **Run Collection**. In the **Request Order** tab, we can drag and drop the requests to reorder them. In this example, we want to send three requests, starting with the _Health check endpoint for Kubernetes_ requests, then _Get KongAir planned flights_, and finally _Fetch more details about a flight_.

Once the order is defined, select the three requests to run.

## Configure run iterations

To the collection multiple times in a row, update the **Iterations** field, and add a delay. Let's run the collection three times with a 100ms delay. 

Once everything is configured, click **Run**. You can see the requests and responses in the **Console** tab on the right panel.

![Collection runner with console tab](/assets/images/insomnia/collection-runner.png)
