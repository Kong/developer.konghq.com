---
title: Collected data

description: Insomnia collects usage analytics data to help improve the application.

content_type: reference
layout: reference

products:
    - insomnia

faqs:
  - q: What specific data does Insomnia collect?
    a: |
      Insomnia collects information like the following JSON:

      ```json
      {
        "anonymousId": "device-Specific-UUID-here",
        "context": {
      "app": {
        "name": "Insomnia",
        "version": "8.2.0"
      },
      "library": {
        "name": "@segment/analytics-node",
        "version": "1.0.0"
      },
      "os": {
        "name": "mac",
        "version": "14.0.0"
      }
        },
        "event": "Request Executed",
        "integrations": {},
        "messageId": "node-next-message-specific-id-here",
        "originalTimestamp": "2023-10-10T09:57:53.346Z",
        "properties": {
      "mimeType": "application/json",
      "preferredHttpVersion": "default"
        },
        "receivedAt": "2023-10-10T09:58:05.056Z",
        "sentAt": null,
        "timestamp": "2023-10-10T09:57:53.346Z",
        "type": "track",
        "writeKey": "REDACTED"
      }
      ```
  - q: Do you retain server logs, or event logs?
    a: All server logs stored are kept within GCP and only accessed by engineers authorized to manage the Insomnia servers.
  - q: I use the Insomnia app scratch pad locally, does Insomnia collect my data too?
    a: unsure 
  - q: I use the desktop Insomnia app, how do I opt out of data collection?
    a: If you use the Insomnia desktop application without an account, users have the choice to opt out of sending this information in the desktop application user interface. Users can opt out of sharing analytics data with Insomnia via the Insomnia app Preference Page by scrolling down to the Network Activity section and checking or unchecking the box next to Send Usage Statistics.
  - q: Do you retain server logs, or event logs?
    a: All server logs stored are kept within GCP and only accessed by engineers authorized to manage the Insomnia servers.
---

If users are logged into their Insomnia account or if they haven't opted out of analytics in the desktop application, we collect usage data to help improve the application. The usage analytics are collected to evaluate user behavior for the purpose of guiding product decisions.

Insomnia collects usage data like the following:
* Insomnia app version
* OS name and version
* Events (like executing a request)
* Preferred HTTP version