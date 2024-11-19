---
title: Insomnia domains to allowlist

content_type: reference
layout: reference

description: See a list of domains to allowlist to ensure full functionality of Insomnia.

related_resources:
  - text: Authentication & Authorization in Insomnia
    url: /insomnia/authentication-authorization

tags:
    - allowlist
    - whitelist
    - authorization

products:
    - insomnia

faqs:
  - q: I'm experiencing issues after allowlisting Insomnia domains. Who can I reach out to for help?
    a: |
        Reach out to your IT support or reach out to Insomnia’s customer service at support@insomnia.rest or [https://support.konghq.com/support/s/](https://support.konghq.com/support/s/).

breadcrumbs:
  - /insomnia/
---

To ensure full functionality of Insomnia features, allowlist the following domains:

| Domain | Description |
|--------|-------------|
| `insomnia.rest` | Main website for Insomnia. | 
| `ai.insomnia.rest` | Redirects to the Insomnia AI Runners site ([https://app.insomnia.rest/ai](https://app.insomnia.rest/ai)). | 
| `ai-helper.insomnia.rest` | Handles AI-generated testing related features in Insomnia (version 8.x or later). | 
| `api.insomnia.rest` | API endpoint for Insomnia services. | 
| `docs.insomnia.rest` | Provides access to Insomnia's documentation and user guides. | 
| `mock.insomnia.rest` | Used for the mocking feature in Insomnia. | 
| `updates.insomnia.rest` | Used for receiving software updates and patches. | 
| `auth.insomnia.rest` | Manages authentication processes for Insomnia. | 
| `insomnia-prod.us.auth0.com` | A domain linked to authentication used for secure logins. | 
| `djvq2ky33rnc.cloudfront.net` | A CDN domain for hosting static assets related to Insomnia. | 
| `api.segment.io` | Used for analytics and telemetry in Insomnia. | 
| `o1147619.ingest.sentry.io` | Used for error reporting and monitoring to enhance the application’s stability and performance. | 
| `js.stripe.com`, `m.stripe.com`, `m.stripe.network` | Used for non-enterprise users. Allowing these help prevent billing issues on an Individual or Team plan. | 