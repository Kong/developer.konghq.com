---
title: We would like to capture information about requests that do not match a route in Kong
content_type: support
description: A global Kong log plugin on a non-default workspace does not log 404 responses for unmatched routes; add a global log plugin to the default workspace to capture them.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why doesn't my global log plugin capture the 404 responses for requests that don't match any route?
  a: |
    Plugins are scoped to a workspace, and unmatched requests can't be associated with a non-default workspace, so a log plugin there never runs for them.
    Add a global log plugin to the default workspace to capture those 404 responses.
related_resources: []
---

## Problem

We are trying to capture more information about requests that do not match a kong route but cause Kong to return a 404 response with `{"message":"no Route matched with those value"}`. We are using a specific workspace, and have enabled a global kong log plugin on that workspace but requests which do not match any route are not getting logged.

## Cause

Like all entities, plugins are associated with a specific workspace, and are isolated from other workspaces. When Kong cannot find a matching route for an incoming request, it cannot associate a log plugin that is not associated with the default workspace with the request, so the non-default workspace plugin is not executed.

## Solution

To capture 404 responses which are due to no Kong route matching the request with a Kong log plugin, you can add a global log plugin to the default workspace.
