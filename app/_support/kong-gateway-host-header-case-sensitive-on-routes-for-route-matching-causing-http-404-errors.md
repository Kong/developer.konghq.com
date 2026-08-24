---
title: "Kong Gateway: Host header case-sensitive on Routes for route matching, causing HTTP 404 errors"
content_type: support
description: "Host header matching on Kong Gateway Routes is case-sensitive, per RFC, even though header names are case-insensitive, so requests with a different-case Host header (e.g. `Example.com` vs. `example.com`) return a 404."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does a Route with a Host value of example.com return a 404 for requests with a different-case Host header, like Example.com?
  a: |
    Kong Gateway's Route matching is case-sensitive for header values (though header names themselves are case-insensitive) per RFC, so `Example.com` won't match a Route configured with `example.com`, producing an HTTP 404. Work around it by normalizing the Host header at the client or load balancer, listing all expected case variations on the Route, or using a global pre-function plugin to lowercase the header before routing.
---

## Problem

We are setting the Host parameter on a Route for matching-purposes, however we are finding some requests are not being matched properly to the Route. The pattern we've seen is the Host header in the request has a different case structure than what we've set on the Route. For example, our Route has a Host value of "example.com" but the request is coming in with a Host header value of "Example.com" and thus is not matched. These are causing 404 HTTP errors and we want to understand how best to address this problem.

## Solution

In this case, the Kong Gateway is working as designed/expected as header values are case-sensitive per RFC. While header names are case-insensitive, their values are case-sensitive. This is why "Example.com" is different from "example.com" and generates a 404.

There are a few ways to resolve this situation:

Method #1: Simply ensure that your client apps are sending the Host header correctly. If you have control over the application sending the requests for example, ensure it's sending the expected Host header to match what has been set in the Kong Gateway. For those apps which you do not have control over, make it known perhaps in the API documentation that they should be sending the Host header as all lower-case for example.

Method #2: Some load balancers (LBs) actually have a function which can manipulate the headers for consistency so that they can all be lower-case values for example. If this is an option in your environment, we recommend this be considered.

Method #3: You can set multiple values in the Host parameter on the Route. So in the event that you only see a few different variations (i.e. example.com, Example.com, EXAMPLE.COM), then it may be simpler to add those variations to the Host setting on the Route so that all commonly seen variations are matched correctly.

Method #4: If the first two options are not possible in your environment, you may be able to utilize the Serverless Plugin (pre-function) with Kong Gateway to manipulate the headers prior to it reaching the Route matching phase. An example is included 'as-is' below. Please understand that Serverless function code is outside the scope of Kong Support. You may wish to contact your Account Executive to hire our Field Engineering / Professional Services team who can write the code to meet your specific use-case.

To explain the JSON config from a Pre-Function plugin below from Method #4: the code to add is `ngx.req.set_header("Host", string.lower(ngx.req.get_headers()["Host"]))` to the rewrite phase and assign it at the global scope. Limitations: This does not work scoped to a particular Service or Route, it must be Global. This also limits the ability to add more Pre-Function plugins as only one Pre-Function plugin can be added to a particular scope at a time, meaning in this example another Pre-Function plugin could not be applied globally.

```json

{
	"service": null,
	"config": {
		"log": [],
		"ws_handshake": [],
		"certificate": [],
		"ws_upstream_frame": [],
		"rewrite": ["ngx.req.set_header(\"Host\", string.lower(ngx.req.get_headers()[\"Host\"]))"],
		"access": [],
		"ws_client_frame": [],
		"header_filter": [],
		"body_filter": [],
		"ws_close": []
	},
	"consumer": null,
	"name": "pre-function",
	"created_at": 1679436267,
	"id": "c0aa4d2d-941c-4225-9b70-bba140bd11a4",
	"route": null,
	"protocols": ["grpc", "grpcs", "http", "https"],
	"ordering": null,
	"tags": null,
	"enabled": true
}
```
