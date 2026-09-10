---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
categories:
  - ai
tags:
  - ai
  - dlp
  - security
related_resources:
  - text: AI Model
    url: /ai-gateway/entities/ai-model/
  - text: AI Policy
    url: /ai-gateway/entities/ai-policy/
  - text: AI Custom Guardrail Policy
    url: /ai-gateway/policies/ai-custom-guardrail/
  - text: "{{site.ai_gateway}} audit log reference"
    url: /ai-gateway/ai-audit-log-reference/#ai-pii-sanitizer-logs
---

The AI PII Sanitizer Policy for {{site.ai_gateway}} helps protect sensitive information in client request bodies before they reach upstream AI providers or tools.

By integrating with an external PII service, this Policy ensures compliance with data privacy regulations while preserving the usability of request data.

The AI PII Sanitizer supports multiple sanitization modes, including replacing sensitive information with fixed placeholders or generating synthetic replacements that retain category-specific characteristics.

Additionally, AI PII Sanitizer offers an optional restoration feature, allowing the original request data to be reinstated in responses when needed.

The AI PII Sanitizer Policy uses the AI PII Anonymizer Service, which can run in a Docker container, to detect and sanitize sensitive data.

## How it works

The AI PII Sanitizer Policy can be applied to:
* Input data (requests)
* Output data (responses)
* Both input and output data

Here's how it works if you apply it to both requests and responses:

1. The Policy intercepts the request body and sends it to the external PII service.
   - The PII service detects sensitive data and applies the chosen sanitization method (placeholders or synthetic replacements).
1. The sanitized request is forwarded upstream to the selected AI Model.
1. On the way back, the Policy intercepts the response body and sends it to the external PII service.
   - The PII service detects sensitive data and applies the chosen sanitization method (placeholders or synthetic replacements).
1. (_Only applies to input data sanitization_) If restoration is enabled, the Policy restores the original request data in responses before returning them to the client.

<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant Client
    participant Policy as AI PII Sanitizer
    participant PII as PII Service
    participant AI as Upstream AI Service

    Client->>Policy: Send request
    Policy->>PII: Intercept & send request body
    PII->>PII: Detect sensitive data in request
    PII->>Policy: Return sanitized request<br/>(placeholders/synthetic data)
    Policy->>{{site.ai_gateway}}: Forward sanitized request
    {{site.ai_gateway}}->>AI: Process sanitized request
    AI->>{{site.ai_gateway}}: Return AI response
    {{site.ai_gateway}}->>Policy: Forward response
    Policy->>PII: Intercept & send response body
    PII->>PII: Detect sensitive data in response
    PII->>Policy: Return sanitized response<br/>(placeholders/synthetic data)
    Policy->>Client: Return sanitized response
{% endmermaid %}
<!--vale on-->

> _Figure 1: Diagram showing the request and response flow with the AI PII Sanitizer Policy._

## AI PII Anonymizer service

Kong publishes the AI PII Anonymizer service as public Docker images. Each image includes a built-in NLP model and is tagged using the `version-lang_code` format. For example:

* `ai-pii-service:v0.2.2-en`: English model, version 0.2.2
* `ai-pii-service:v0.2.2-it`: Italian model, version 0.2.2
* `ai-pii-service:v0.2.2-fr`: French model, version 0.2.2

{:.info}
> All models are bundled into a single image per version, tagged using the format `v<version>`. For example: `v0.2.2`
> If you need to add or modify models, edit the configuration file at `ai_pii_service/nlp_engine_conf.yml`.

### Sanitization endpoints

* `POST /llm/v1/sanitize`: Sanitize specified types of PII information, including credentials, and custom patterns
* `POST /llm/v1/sanitize_credentials`: Only for sanitizing credentials

See the [AI PII Sanitizer OpenAPI specification](/ai-gateway/policies/ai-sanitizer/api/) for complete details.

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
* `domain`: Anonymizes domain names. It was deprecated, use `url` instead.
* `url`: Anonymizes web URLs.
* `medical`: Anonymizes medical identifiers (for example, medical license numbers, NHS numbers, medicare numbers).
* `driverlicense`: Anonymizes driver's license numbers.
* `passport`: Anonymizes passport numbers.
* `bank`: Anonymizes bank account numbers and related banking identifiers (for example, VAT codes, IBAN).
* `nationalid`: Anonymizes various national identification numbers (for example, Aadhaar, PESEL, NRIC, social security, or voter IDs).
* `custom`: Anonymizes user-defined custom PII patterns using regular expressions only when custom patterns are provided.
* `credentials`: Anonymizes the credentials, similar to `/sanitize_credentials`.
* `all`: Includes all the fields above, including custom ones.

### Access the Docker images

Kong distributes these images publicly on Docker Hub, under the `kong/ai-pii-service` repository. No authentication is required to pull them.

#### Pull the AI PII service image

To pull an image:

```bash
docker pull kong/ai-pii-service:TAG
```

Replace `TAG` with the appropriate version and language code, such as:

```bash
docker pull kong/ai-pii-service:v0.2.2-en
```

#### Run the AI PII service as a standalone container

To run the image directly, without a `Dockerfile`:

```bash
docker run -d kong/ai-pii-service:v0.2.2-en
```

#### AI PII service Dockerfile usage

Alternatively, to use an image in a `Dockerfile`, reference it as follows:

```dockerfile
FROM kong/ai-pii-service:v0.2.2-en
```

### Available language tags

The following language-specific images are currently available:

* `-en` (English)
* `-es` (Spanish)
* `-fr` (French)
* `-de` (German)
* `-it` (Italian)
* `-ja` (Japanese)
* `-ko` (Korean)
* `-nl` (Dutch)
* `-pt` (Portuguese)
* `-th` (Thai)
* `-tr` (Turkish)

{% include /md/ai-gateway/v2/policies/spacy-pii-note.md %}

### Image configuration options

This service takes the following optional environment variables at startup:
* `GUNICORN_WORKERS`: Specifies the number of Gunicorn processes to run
* `PII_SERVICE_ENGINE_CONF`: Specifies the natural language processing (NLP) engine configuration file
* `GUNICORN_LOG_LEVEL`: Specifies log level

## Forward proxy support

{% include md/ai-gateway/v2/forward-proxy.md %}