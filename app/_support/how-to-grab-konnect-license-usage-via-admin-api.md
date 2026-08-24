---
title: "{{site.konnect_product_name}}: How to grab Konnect license usage via Admin API"
content_type: support
published: false
description: "Query the Konnect Admin API's `/kbilling/v1/usage` endpoint with a personal access token (PAT) to check current Konnect license usage."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I check Konnect license usage using the Admin API?
  a: |
    Generate a personal access token (PAT) in the Konnect UI (Organization Settings > Personal Access Tokens), then call `GET https://global.api.konghq.com/kbilling/v1/usage` with that token to retrieve the same monthly request count shown in Konnect's Billing Settings.
---

## {{site.konnect_product_name}}: How to grab Konnect license usage via Admin API

We see it is possible to view the license usage inside Konnect but we want to be able to pull this data programmatically. Is there anyway to use the Admin API to grab the license usage report?

To grab this data using the Admin API you will need to generate a personal access token (PAT). You can generate one from the Konnect UI under Organization Settings > Personal Access Tokens.

Once you have your PAT you can use the following command:

```bash

curl -X GET 'https://global.api.konghq.com/kbilling/v1/usage' --header 'Authorization: Bearer <PAT>' -s | jq .data.us.total_request_count
```

This will return the same monthly call count shown on the Konnect Billing Settings page.

Command output:

178241
