---
title: Resolving Connection Reset Errors When Configuring Kong Audit Logs with Webhooks and Splunk
content_type: support
description: "Webhook requests to Splunk can fail with a `\"connection reset by peer\"` error; allowlisting {{site.konnect_product_name}}'s egress IP addresses on the Splunk side typically resolves it."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How to Resolve Connection Reset Errors When Configuring Kong Audit Logs with Webhooks and Splunk?
  a: |
    {{site.konnect_product_name}}'s egress IP addresses that send audit log webhook traffic may not be allowlisted on the Splunk side, causing Splunk to reset the connection. Retrieve the current egress IPs from `https://ip-addresses.origin.konghq.com/ip-addresses.json`, then allowlist the IPs for your Konnect region plus the US region (Authentication audit logs always originate from the US region) on the Splunk side.
related_resources: []
---

## Problem

When configuring {{site.konnect_product_name}}'s audit logs with webhooks and Splunk, the webhook request can fail after several attempts with a `"connection reset by peer"` error.

## Cause

This problem arises when the connection to Splunk is unexpectedly closed, potentially due to configuration or network issues.

## Solution

To address this, follow the steps outlined below:

1. Verify IP Allowlist on Splunk Side:

   Ensure that all necessary IP addresses from which {{site.konnect_product_name}} sends audit log traffic are allowed on the Splunk side. You can retrieve the current list of {{site.konnect_product_name}} egress IP addresses by accessing the following URL:

   https://ip-addresses.origin.konghq.com/ip-addresses.json

   Please note that you need to enable the `egressIPs` for the region for which you are enabling Audit logging but also ALWAYS need to enable the US region egress IP addresses.

   The reason for having to enable the US egress IP addresses is that at time of creating this KB article, 23 October 2024, Authentication audit logs originate from the US region.

   All the `egressIPs` can be retrieved with the below curl command, filtered using `jq`, which on 23 October 2024 returns the list below:

   ```bash
   curl https://ip-addresses.origin.konghq.com/ip-addresses.json|jq -r '.egressIPs'
   {
     "au": [
       "54.79.153.51",
       "13.55.230.239",
       "52.65.44.35",
       "16.50.18.205",
       "16.51.48.148",
       "16.50.82.99"
     ],
     "eu": [
       "35.157.142.129",
       "3.68.163.51",
       "3.72.189.41",
       "54.74.155.219",
       "34.254.24.160",
       "52.51.153.231"
     ],
     "us": [
       "18.217.207.159",
       "52.15.154.8",
       "3.137.43.24",
       "52.26.195.109",
       "52.13.59.51",
       "54.201.160.33"
     ]
   }
   ```

   Note: the region previously labeled `ap` has been renamed to `au` (the egress IPs are unchanged). Two additional regions, `in` and `sg`, have also been added since this article was originally written — query the endpoint directly to get their current egress IPs rather than relying on a static list.

   If you want to enable Konnect audit log webhooks for the EU region, make sure to allow on Splunk the `eu` and `us` egress IPs which based on the sample output above would be:

   ```
   "35.157.142.129",
   "3.68.163.51",
   "3.72.189.41",
   "54.74.155.219",
   "34.254.24.160",
   "52.51.153.231"
   "18.217.207.159",
   "52.15.154.8",
   "3.137.43.24",
   "52.26.195.109",
   "52.13.59.51",
   "54.201.160.33"
   ```

2. Re-enable audit logging, and verify that this continues to work after allowing the list of egress IPs from the US and your Konnect region.

   After applying the above changes, monitor the connection to see if audit logs are successfully received by Splunk without the connection being reset. Test by disabling and then re-enabling the audit webhook in the Konnect UI to verify if the issue recurs or if it has been resolved.

By following these steps, you should be able to resolve the `"connection reset by peer"` error and ensure a stable connection between {{site.konnect_product_name}} and Splunk for audit log transmission.
