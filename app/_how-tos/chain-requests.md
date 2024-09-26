---
title: Chain requests in Insomnia

products:
    - insomnia

tags:
    - requests
    - responses
    - template-tags

prereqs:
    inline:
        - title: Create a collection with requests
          content: |
            [Create a collection]() and [import]() the [KongAir Flights](https://raw.githubusercontent.com/Kong/KongAir/refs/heads/main/flight-data/flights/openapi.yaml) requests.
          icon_url: /assets/icons/add.svg
        - title: Configure the environment
          content: |
            Add the KongAir base URL to your environment.

            1. In your collection, click **Base Environment**
            1. Click the edit button and add the following content:
            ```json
                {
                    "base_url": "https://api.kong-air.com"
                }
            ```
            1. Click **Close**.
          icon_url: /assets/icons/world.svg

tldr:
    q: How can I reuse content from a response in another request?
    a: Create at least two requests, send one to get a response, then configure a template tag in the second request to reuse a value from the first request's response.
---

## 1. Send the first request

In the KongAir collection, open the _Get KongAir planned flights_ request and click **Send** to get a list of flights. We can reuse content from the response in the next request.

## 2. Edit the second request

Open the _Fetch more details about a flight_ request. This request requires a flight number in the path. We'll use a template tag to get a flight number from the list of flights from the previous request.

Remove the `_.flightNumber` placeholder and start typing `response` in its place. When a drop-down list appears, click **Response > Body Attribute**.

![Request URL with drop-down list to select a template tag](/assets/images/insomnia/response-autocomplete.png)

## 3. Configure the template tag

Click the template tag, and configure it with the following values to get the flight number for the first flight on the list:

|Field|Value|
|---|---|
|Function to Perform|Response|
|Attribute|Body Attribute|
|Request|GET Get KongAir planned flights|
|Filter|`$.[0].number`|
|Trigger Behavior|Never|

Once this is done, we can see the live preview of the value (KA0284 in this example). We can can then click **Done** to apply the changes.

## 4. Send the second request

Click **Send** on the _Fetch more details about a flight_ to get the information about the first flight on the list. This is the response:

```json
{
	"aircraft_type": "Boeing 777",
	"flight_number": "KA0284",
	"in_flight_entertainment": true,
	"meal_options": [
		"Chicken",
		"Fish",
		"Vegetarian"
	]
}
```