---
title: Key Auth plugin

name: Key Auth
publisher: kong-inc
content_type: plugin
description: Secure services and routes with key authentication
tags:
    - authentication

works_on:
    - on-prem
    - konnect
---

## Overview

This plugin lets you add API key authentication to a service or a route. Consumers then add their API key either in a query string parameter, a header, or a request body to authenticate their requests.

This plugin also comes in an enterprise version: Key Authentication Encrypted, which provides the ability to encrypt keys. Keys are encrypted at rest in the API gateway datastore.
