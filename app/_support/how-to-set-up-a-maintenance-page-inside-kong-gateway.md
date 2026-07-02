---
title: How to set up a maintenance page inside {{site.base_gateway}}
content_type: support
description: "Learn how to display a maintenance page in {{site.base_gateway}} using the Request Termination plugin to return a custom message and content type."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Request Termination plugin
    url: /plugins/request-termination/
tldr:
  q: How do I set up a maintenance page in {{site.base_gateway}} to display a message to users when an endpoint is being worked on?
  a: |
    Enable the Request Termination plugin on a specific Route or Service (or globally for
    all Services). Set `config.body` to your maintenance messaging and `config.content_type` to
    the desired content type, for example `text/html` to return an HTML page.
---

## Steps

Use the [Request Termination plugin](/plugins/request-termination/) to return a custom response on a specific Route or Service.
To apply the maintenance page to all Services, enable the plugin globally.

Set the following plugin configuration fields:

- `config.body`: the message or HTML to return to the user.
- `config.content_type`: the content type of the response, for example `text/html` to return an HTML page.

For example, to return an HTML maintenance page:

`config.body`:

```html
<h1 style="color:Gray;background-color:DodgerBlue;">This page is under maintenance. It will be completed by 3pm PST. Here is a turtle to look at to pass the time.</h1> <img src="https://upload.wikimedia.org/wikipedia/commons/f/f4/Florida_Box_Turtle_Digon3_re-edited.jpg">
```
