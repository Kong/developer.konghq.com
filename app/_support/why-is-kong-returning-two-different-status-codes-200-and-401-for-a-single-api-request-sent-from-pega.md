---
title: Kong returns two different status codes (200 and 401) for a single API request sent from Pega
content_type: support
description: Pega's pre-emptive authentication sends an initial unauthenticated request (401) followed by an authenticated one (200) for what looks like a single call, which is expected client-side behavior, not a Kong misconfiguration.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why is Kong returning two different status codes (200 and 401) for a single API request sent from Pega?
  a: |
    Pega's pre-emptive authentication sends two requests: an initial one without auth headers (which gets a 401) followed by one with credentials (which gets a 200), sharing the same Correlation ID.
    Kong is behaving correctly and processing each request it receives; the duplicate is client-side behavior, not a Kong misconfiguration.
related_resources:
  - text: "Pega: Preemptive authentication option for the Basic authentication profile"
    url: "https://support.pega.com/question/preemptive-authentication-option-basic-authentication-profile"
  - text: "Pega: Configuring a Basic authentication profile"
    url: "https://docs-previous.pega.com/security/86/configuring-basic-authentication-profile"
---

## Problem

Kong returns two different status codes (200 and 401) for a single API request sent from Pega.

## Cause

The issue is linked to Pega's pre-emptive authentication feature, which caused the duplicate requests with differing authentication states. When a basic authentication connection is set up in Pega, it is standard behavior for Pega to send an initial request without authorization headers (possibly to test sessions), and if a 401 is returned, send a follow up request with the authorization header set correctly.

## Solution

The core issue revolves around Kong receiving two simultaneous requests when only one request is sent from the client application (in this case, Pega). Both requests carry the same Correlation ID, indicating they originate from the same initial request. However, Kong logs and processes the "single" request as 2 separate requests, resulting in two different responses: one with a status code of 200 (OK) and another with 401 (Unauthorized).

Kong is operating as expected by processing the requests it received. The duplicate requests and the resulting different status codes were due to the client application's handling of the 2 separate requests, not a misconfiguration or error within Kong.

This underscores the importance of thoroughly investigating both the API gateway and the client application when troubleshooting unexpected behaviors in API request processing. In scenarios where duplicate requests or varying responses are observed, it is crucial to examine client-side configurations and behaviors, such as retry mechanisms or authentication features, that may influence the requests sent to Kong.
