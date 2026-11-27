Kong publishes the AI PII Anonymizer service as public Docker images. Each image includes a built-in NLP model and is tagged using the `version-lang_code` format. For example:

* `ai-pii-service:v0.3.1-en`: English model, version 0.3.1
* `ai-pii-service:v0.3.1-it`: Italian model, version 0.3.1
* `ai-pii-service:v0.3.1-fr`: French model, version 0.3.1

{:.info}
> All models are bundled into a single image per version, tagged using the format `v<version>`. For example: `v0.3.1`
> If you need to add or modify models, edit the configuration file at `ai_pii_service/nlp_engine_conf.yml`.

{% if include.show_endpoints %}
### Sanitization endpoints

* `POST /llm/v1/sanitize`: Sanitize specified types of PII information, including credentials, and custom patterns
* `POST /llm/v1/sanitize_credentials`: Only for sanitizing credentials

See the [AI PII Sanitizer OpenAPI specification](/ai-gateway/policies/ai-sanitizer/api/) for complete details.
{% endif %}

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
Only regex patterns are supported, and all fields are required: `name`, `regex`, and `score`.

The `name` must be unique for each pattern.

The {{include.policy_name}} Policy accepts any value in `regex` when you save the configuration, including an expression that doesn't compile.
The PII service compiles each pattern with Python's [`re` module](https://docs.python.org/3/library/re.html) when it handles a request.
It rejects the request if a pattern is invalid.
Test each regular expression against Python's `re` module before you deploy it.

#### How the score works

The `score` is the confidence value that a custom pattern assigns to its matches.
The score matters when a custom pattern and a built-in entity type (like `email` or `nrp`), match the same text. In that case:

* The plugin uses the higher score.
* If scores are equal, the custom pattern takes precedence over the built-in entity. 

If no built-in entity matches the same text, the plugin redacts a custom pattern's matches at any score above `0`.

If the built-in type has the higher score and isn't in `anonymize`, the text isn't sanitized.
To prevent this, set `score` to `1` or add the built-in type to `anonymize`.

For example, the pattern `TCK-[0-9]{5}` with `anonymize: [custom]` matches `My ticket is TCK-12345 please help`, and the built-in `nrp` type also matches `TCK-12345`:

* With `score: 0.5`, `TCK-12345` isn't redacted, because `nrp` has the higher score.
* With `score: 1`, `TCK-12345` is redacted as a custom pattern.

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
* `credentials`: Anonymizes the credentials{% if include.show_endpoints %}, similar to `/sanitize_credentials`{% endif %}.
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
docker pull kong/ai-pii-service:v0.3.1-en
```

#### Run the AI PII service as a standalone container

To run the image directly, without a `Dockerfile`:

```bash
docker run -d kong/ai-pii-service:v0.3.1-en
```

#### AI PII service Dockerfile usage

Alternatively, to use an image in a `Dockerfile`, reference it as follows:

```dockerfile
FROM kong/ai-pii-service:v0.3.1-en
```

### Available language tags

The following language-specific images are available:

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
* `GUNICORN_CERTFILE` and `GUNICORN_KEYFILE`: Specifies TLS certificates for HTTPS access. 

### Serve AI PII service securely

To serve the AI PII service over https requires additional configuration:

1. Ensure you have trusted TLS certificates for your environment.
2. Set the `GUNICORN_CERTFILE` and `GUNICORN_KEYFILE` environment variables when starting the AI PII service. The service will switch to serving HTTPS on port `8443`.
3. Set `scheme: https` and `port: 8443` when configuring the {{include.policy_name}} Policy. The policy will connect with HTTPS.

{:.info}
> This policy does not verify SSL/TLS connections directly, it follows the global [`tls_certificate_verify`](/ai-gateway/configuration/#tls-certificate-verify) setting. Certificates can be managed with the [AI CA Certificates](/ai-gateway/entities/ai-ca-certificate/) and [AI Certificates](/ai-gateway/entities/ai-certificate/) entities.
