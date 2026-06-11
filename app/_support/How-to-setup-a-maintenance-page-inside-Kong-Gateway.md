---
title: How to setup a maintenance page inside Kong Gateway
content_type: support
description: "How to display a maintenance page in Kong Gateway using the Request Termination plugin to return a custom message and content type."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Request Termination plugin
    url: /hub/kong-inc/request-termination/
---

## Overview

We are looking to setup a maintenance page inside of the Gateway. If an endpoint is being worked on we would like to enable this page to display a message to users. Is there a out of box solution that can accomplish this?

## Steps

One of the easier ways to accomplish this is by using the Request Termination plugin.

To begin, create the Request Termination plugin on the specific route/service in question (if all services then you can set the plugin globally).

`config.body` can be used to add your messaging.

`config.content_type` can be used to set your desired content type. For example, if you wish to return an HTML page, `text/html`.

As a sample to demonstrate this we can add the following.

`config.body`:

```html
<h1 style="color:Gray;background-color:DodgerBlue;">This page is under maintenance. It will be completed by 3pm PST. Here is a turtle to look at to pass the time.</h1> <img src="https://upload.wikimedia.org/wikipedia/commons/f/f4/Florida_Box_Turtle_Digon3_re-edited.jpg">
```
