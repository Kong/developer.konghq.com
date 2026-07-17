<!--vale off-->
{% table %}
columns:
  - title: Field type
    key: field_type
  - title: Description
    key: description
  - title: Configurable properties
    key: properties
  - title: Example
    key: example
rows:
  - field_type: "Markdown content"
    description: "A block of Markdown (MDC) text rendered between or above other fields. Doesn't collect any input from the developer."
    properties: "`value` (Markdown content, required, up to 4096 characters)"
    example: "`## Tell us about your project`"
  - field_type: "Short text"
    description: "A single-line text input."
    properties: "`label`, `placeholder`, `description` (help text, supports Markdown), `required`"
    example: "Full name"
  - field_type: "Email"
    description: "A single-line text input, validated as an email address."
    properties: "`label`, `placeholder`, `description`, `required`"
    example: "Email address"
  - field_type: "Number"
    description: "A numeric input."
    properties: "`label`, `placeholder`, `description`, `required`"
    example: "Team size"
  - field_type: "Long text"
    description: "A multi-line text input."
    properties: "`label`, `placeholder`, `description`, `required`"
    example: "Message"
  - field_type: "Dropdown (single-select)"
    description: "A dropdown where the developer chooses exactly one option. Requires at least one option."
    properties: "`label`, `placeholder`, `description`, `required`, `options` (list of `value`/`label`/`selected`)"
    example: "Department: Sales, Support, Engineering"
  - field_type: "Dropdown (multi-select)"
    description: "A dropdown where the developer can choose more than one option. Requires at least two options."
    properties: "`label`, `placeholder`, `description`, `required`, `options` (list of `value`/`label`/`selected`)"
    example: "Topics of interest: API Gateway, Service Mesh, Developer Portal"
  - field_type: "Checkbox"
    description: "A single boolean checkbox. Commonly used for terms acceptance, since the label and description both support inline Markdown links."
    properties: "`label`, `description` (supports Markdown links), `required`"
    example: "Terms and conditions acceptance"
  - field_type: "Submit"
    description: "The submit button for the form. Exactly one is required per form."
    properties: "`value` (button label, defaults to \"Create account\")"
    example: "Submit button"
{% endtable %}
<!--vale on-->
