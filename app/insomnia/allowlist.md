---
title: Insomnia Proxy and Allowlist

description: A reference containing allow listable domains to ensure Insomnia is operating correctly within your organization.

content_type: reference
layout: reference

products:
    - insomnia

related_resources:
  - text: Incident response
    url: /insomnia/incident-response/

faqs:
  - q: I'm experiencing issues after allowlisting Insomnia domains. Who can I reach out to for help?
    a: |
        Reach out to your IT support or reach out to Insomnia’s customer service at support@insomnia.rest or [https://support.konghq.com/support/s/](https://support.konghq.com/support/s/).

---

## Allowlist

For enterprise users utilizing Insomnia, it's crucial to ensure that specific domains are allowlisted in your network. This step is essential to guarantee that all features of Insomnia, including updates, synchronization, and documentation, work without any hindrance in environments with restricted internet access.

{% table %}
columns:
  - title: Domain
    key: domain
  - title: Description
    key: description
rows:
  - domain: insomnia.rest
    description: Main website for Insomnia.
  - domain: ai.insomnia.rest
    description: Redirects to https://app.insomnia.rest/ai.
  - domain: ai-helper.insomnia.rest
    description: Handles AI-Generated Testing features, introduced in Insomnia 8.x.
  - domain: api.insomnia.rest
    description: API endpoint for Insomnia services.
  - domain: docs.insomnia.rest
    description: Provides access to documentation and user guides.
  - domain: mock.insomnia.rest
    description: Used for Insomnia App's Mocking feature.
  - domain: updates.insomnia.rest
    description: Used to receive software updates and patches.
  - domain: auth.insomnia.rest
    description: Manages authentication processes.
  - domain: insomnia-prod.us.auth0.com
    description: Used for secure login authentication.
  - domain: djvq2ky33rnc.cloudfront.net
    description: CDN domain for static assets related to Insomnia.
  - domain: api.segment.io
    description: Used for analytics and telemetry within Insomnia.
  - domain: o1147619.ingest.sentry.io
    description: Used for error reporting and monitoring.
  - domain: js.stripe.com
    description: Used for billing (non-enterprise users).
  - domain: m.stripe.com
    description: Used for billing (non-enterprise users).
  - domain: m.stripe.network
    description: Used for billing (non-enterprise users).
{% endtable %}


Allowlisting these domains ensures uninterrupted access to all functionalities of Insomnia, including updates, documentation, and necessary backend services. Should you experience issues post-allowlisting, it's advisable to seek assistance from your IT support or reach out to Insomnia's customer service at `<support@insomnia.rest> `OR `<https://support.konghq.com/support/s/>`.

## Proxy


Insomnia does not automatically detect system-wide proxy settings. A proxy can be set up manually. Set your HTTP, HTTPS, SOCKS4 or SOCKS5 proxy server and reroute all future requests through that server by accessing Preferences via the cog icon > **General** > **HTTP Network Proxy**.

{:.alert .alert-primary}
**Note**: Proxy server settings apply to all traffic going through the Insomnia application, and cannot be restricted to entities such as Collections and individual requests.

Example usage of HTTP or HTTPS proxy

```bash
http://localhost:8005
```

For SOCKS4 or SOCKS5 proxy, one of the following prefixes should be used before the hostname depending on the version (**socks4://**, **socks4a://**, **socks5://**, **socks5h://**)

```bash
socks5h://localhost:8005
```

You can also add a comma-separated list of hostnames to the **No Proxy** box and they will be exempt from going through the proxy server.

## Authentication

Insomnia supports proxy server authentication via Basic Auth, digest, and NTLM.

If your proxy server requires Basic Auth, you can include the credentials in the URL in the following way:

```bash
http://username:password@localhost:8005
```
