---
title: Basic Auth plugin

name: Basic Auth
publisher: kong-inc
content_type: plugin
description: Secure services and routes with Basic Authentication
tags:
    - authentication

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '2.8'
---

## Overview

Add Basic Authentication to a service or a route with username and password protection. The plugin checks for valid credentials in the Proxy-Authorization and Authorization headers (in that order).


