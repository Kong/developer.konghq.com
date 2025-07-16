---
title: 'AI Sanitizer'
name: 'AI Sanitizer'

content_type: plugin

ai_gateway_enterprise: true
tier: enterprise
publisher: kong-inc
description: Protect sensitive information in client request bodies before they reach upstream services


products:
    - gateway
    - ai-gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.10'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

icon: ai-sanitizer.png

categories:
    - ai
tags:
  - ai



related_resources:
  - text: Use AI to protect sensitive information in requests
    url: /how-to/protect-sensitive-information-with-ai/
---

The AI Sanitizer plugin for {{site.base_gateway}} helps protect sensitive information in client request bodies before they reach upstream services.
By integrating with an external PII service, the plugin ensures compliance with data privacy regulations while preserving the usability of request data.
It supports multiple sanitization modes, including replacing sensitive information with fixed placeholders or generating synthetic replacements that retain category-specific characteristics.

Additionally, AI Sanitizer offers an optional restoration feature, allowing the original data to be reinstated in responses when needed.

{% include plugins/ai-plugins-note.md %}

The AI Sanitizer plugin uses the AI PII Anonymizer Service, which can run in a Docker container, to detect and sanitize sensitive data. See the [tutorial on configuring the AI Sanitizer plugin](/how-to/protect-sensitive-information-with-ai/) for more information on how to configure the plugin with the AI PII Anonymizer Service.

## How it works

1. The plugin intercepts the request body and sends it to the external PII service.
1. The PII service detects sensitive data and applies the chosen sanitization method (placeholders or synthetic replacements).
1. The sanitized request is forwarded upstream with the AI Proxy or AI Proxy Advanced plugin.
1. If restoration is enabled, the plugin restores original data in responses before returning them to the client.

## AI PII Anonymizer service

Kong provides several [AI PII Anonymizer service](https://cloudsmith.io/~kong/repos/ai-pii/packages/) Docker images in a private repository. Each image includes a built-in NLP model and is tagged using the `version-lang_code` format. For example:

* `service:v0.1.2-en`: English model, version 0.1.2
* `service:v0.1.2-it`: Italian model, version 0.1.2
* `service:v0.1.2-fr`: French model, version 0.1.2

{:.info}
> All models are bundled into a single image per version, tagged using the format `v<version>`. For example: `v0.1.2`
> If you need to add or modify models, edit the configuration file at `ai_pii_service/nlp_engine_conf.yml`.

### Access the Docker images

Kong distributes these images via a private Cloudsmith registry. Contact [Kong Support](https://support.konghq.com/support/s/) to request access. 

#### Authenticate with the private Cloudsmith registry

To pull images, you must authenticate first with the token provided by the Support:

```bash
docker login docker.cloudsmith.io
```

Docker will then prompt you to enter username and password:

```bash
Username: kong/ai-pii
Password: YOUR-TOKEN
```

{:.info}
> This is a token-based login with read-only access. You can pull images but not push them.

#### Pull the AI PII service image

To pull an image:

```bash
docker pull docker.cloudsmith.io/kong/ai-pii/IMAGE-NAME:TAG
```

Replace `IMAGE-NAME` and `TAG` with the appropriate image and version, such as:

```bash
docker pull docker.cloudsmith.io/kong/ai-pii/service:v0.1.2-en
```

#### AI PII service Dockerfile usage

To use an image in a `Dockerfile`, reference it as follows:

```dockerfile
FROM docker.cloudsmith.io/kong/ai-pii/ai-pii-service:v0.1.2-en
```

### Available language tags

The following language-specific images are currently available:

* `-en` (English)
* `-fr` (French)
* `-de` (German)
* `-it` (Italian)
* `-ja` (Japanese)
* `-pt` (Portuguese)
* `-ko` (Korean)

{:.info}
> The PII Anonymizer service loads one NLP model by default. Ensure at least **600MB of free memory** is available when running the container.

### Image configuration options

This service takes the following optional environment variables at startup:
* `GUNICORN_WORKERS`: Specifies the number of Gunicorn processes to run
* `PII_SERVICE_ENGINE_CONF`: Specifies the natural language processing (NLP) engine configuration file
* `GUNICORN_LOG_LEVEL`: Specifies log level

### Sanitization endpoints

* `POST /llm/v1/sanitize`: Sanitize specified types of PII information, including credentials, and custom patterns
* `POST /llm/v1/sanitize_credentials`: Only for sanitizing credentials

### Available anonymization modes

You can anonymize data in requests using the following redact modes:

* `placeholder`: Replaces sensitive data with a fixed placeholder pattern, `PLACEHOLDER{i}`, where `i` is a sequence number. Identical original values receive the same placeholder.

   For example, the location `New York City` might be replaced with `LOCATION`.

* `synthetic`: Redact the sensitive data with a word in the same type.

   For example, the name `John` might be replaced with `Amir`.

  * Custom patterns are replaced with `CUSTOM{i}`.
  * Credentials are replaced with a string of `#` characters matching the original length.

### Custom patterns

You can define an array of custom patterns on a per-request basis.
Currently, only regex patterns are supported, and all fields are required: `name`, `regex`, and `score`.

The `name` must be unique for each pattern.

### Fields that can be anonymized

You can use the following fields in the `anonymize` array:

* `general`: Anonymizes general PII entities such as person names, locations, and organizations.
* `phone`: Anonymizes phone numbers (for example, `mobile`, `landline`).
* `email`: Anonymizes email addresses.
* `creditcard`: Anonymizes credit card numbers.
* `crypto`: Anonymizes cryptocurrency addresses.
* `date`: Anonymizes dates and timestamps.
* `ip`: Anonymizes IP addresses (both IPv4 and IPv6).
* `nrp`: Anonymizes a person’s nationality, religious, or political group.
* `ssn`: Anonymizes Social Security Numbers (SSN) and other related identifiers like ITIN, NIF, ABN, and more.
* `domain`: Anonymizes domain names.
* `url`: Anonymizes web URLs.
* `medical`: Anonymizes medical identifiers (for example, medical license numbers, NHS numbers, medicare numbers).
* `driverlicense`: Anonymizes driver's license numbers.
* `passport`: Anonymizes passport numbers.
* `bank`: Anonymizes bank account numbers and related banking identifiers (for example, VAT codes, IBAN).
* `nationalid`: Anonymizes various national identification numbers (for example, Aadhaar, PESEL, NRIC, social security, or voter IDs).
* `custom`: Anonymizes user-defined custom PII patterns using regular expressions only when custom patterns are provided.
* `credentials`: Anonymizes the credentials, similar to `/sanitize_credentials`.
* `all`: Includes all the fields above, including custom ones.