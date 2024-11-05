---
title: Create a cloud-hosted mock server in Insomnia

products:
- insomnia

tags:
- mock-servers

tldr:
  q: How do I create a cloud-hosted mock server in Insomnia?
  a: In your Insomnia project, click **Create** > **Mock Server**, then enter a name, select **Cloud Mock** and click **Create**. Once the server is created, click **New Mock Route** and configure the route.
---

## 1. Create the mock server

In your Insomnia project, click **Create** > **Mock Server**. In  the dialog box, enter a name for the server, select **Cloud Mock**, and click **Create**.

The mock servers opens and you can start adding routes.

## 2. Create a route

In this example, we want to create a `/flights` route based on the [KongAir Flights](https://raw.githubusercontent.com/Kong/KongAir/refs/heads/main/flight-data/flights/openapi.yaml) specification.

1. In your mock server, click **New Mock Route**, enter the path, and click **Create**. Once this is done, you can click **Show URL** to see the mock URL.
1. Select the method. In this example, we'll keep the default `GET`.
1. Add the response body example from the specification:
    ```json
    [
        {
            "number": "KD924",
            "route_id": "LHR-SFO",
            "scheduled_departure": "2024-03-20T09:12:28Z",
            "scheduled_arrival": "2024-03-20T19:12:28Z"
        },
        {
            "number": "KD925",
            "route_id": "SFO-LHR",
            "scheduled_departure": "2024-03-21T09:12:28Z",
            "scheduled_arrival": "2024-03-21T19:12:28Z"
        }
    ]
    ```
1. Update the headers and status if needed. In this example we'll keep the default values.
1. Click **Test** to send a request to the mock.

{:.note}
> You can't define multiple responses for the same route. If you want to mock another response, you need to create a different mock server.

## 3. Validate

To validate, you can create a collection and import the requests from [KongAir Flights](https://raw.githubusercontent.com/Kong/KongAir/refs/heads/main/flight-data/flights/openapi.yaml), then create a new environment with your mock URL as the base URL. When you send the `Get KongAir planned flights` request with the mock environment, you will get the response created in the mock route.
