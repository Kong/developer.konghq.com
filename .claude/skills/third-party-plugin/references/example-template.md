# Example YAML template

Annotated template for `app/_kong_plugins/<plugin-slug>/examples/<example-name>.yaml`.
Replace all `<!-- PLACEHOLDER: ... -->` markers with real content.
Remove annotation comments before finalizing the file.

---

## Naming conventions

**File name**: `<verb>-<what-it-does>.yaml`. Use a name that describes the scenario, not just "enable":
- `deidentify-only.yaml` (not just `enable.yaml`)
- `enable-noma-runtime-protection.yaml` (acceptable when there's only one scenario)
- `monitor-mode.yaml`, `blocking-mode.yaml` (when the plugin has distinct modes)

**Weight**: 900 for the primary example, 901 for secondary, 902 for tertiary, and so on.

---

## Template

```yaml
# REQUIRED: One-line summary. Shown as the example description in the UI.
description: 'Enable the Plugin Display Name plugin.'

# OPTIONAL but recommended for complex configs: Multi-line explanation.
# Explain what the example demonstrates, what the key config choices mean,
# and any prerequisites beyond those listed in requirements.
extended_description: |
  Enable the Plugin Display Name plugin [in mode X / with feature Y].

  [Explain what the configuration does and why you'd choose it over alternatives.
  Keep it to 2-4 sentences. One sentence per line.]

  [If this example requires a specific topology or setup (for example a second route
  or a specific Kong entity), describe it here.]

# REQUIRED: Short title shown in the UI nav. Use title case.
title: 'Enable Plugin Display Name'

# REQUIRED: Controls sort order. Primary example: 900. Each subsequent: +1.
weight: 900

# REQUIRED: Prerequisites the user must satisfy before applying this config.
# Write each as a complete sentence. Link to install docs where relevant.
requirements:
  - "The Plugin Display Name plugin is [installed](/plugins/plugin-slug/#install-the-plugin-display-name-plugin)."
  - "[What the user needs from the vendor, for example: a vendor account with API access.]"
  - "[Any credential or resource they must create in advance.]"

# REQUIRED: Variables the user must supply. Each variable becomes an environment
# variable in the rendered example. Use kebab-case keys.
#
# Variable naming rules:
# - Key: kebab-case (e.g. api-key, vault-url, service-account-id)
# - value: $UPPER_SNAKE_CASE for environment variables (e.g. $VENDOR_API_KEY)
# - value: a hardcoded default for stable values (e.g. https://api.vendor.com)
# - description: one sentence explaining what this is and where to find it
variables:
  api-key:
    value: $VENDOR_API_KEY
    description: Your Plugin Display Name API key. Obtain this from [where].
  api-base-url:
    value: https://api.vendor.com
    description: The base URL for the vendor API. The default value is `https://api.vendor.com`.
  # Add more variables as needed. Only include what the user must supply.

# REQUIRED: The plugin configuration. Use ${variable-key} to reference variables.
# Use the same field names as the plugin's schema.
# For nested config, mirror the schema structure exactly.
config:
  # FLAT CONFIG example (simple plugins):
  api_key: ${api-key}
  api_base_url: ${api-base-url}
  monitor_mode: true

  # NESTED CONFIG example (complex plugins like Skyflow):
  # outer_block:
  #   inner_block:
  #     field_one: ${variable-one}
  #     field_two: value
  #   another_field: value

# REQUIRED: Leave this list unchanged for all third-party plugin examples.
# It controls which tool tabs are shown (decK, Admin API, Konnect API, KIC, Terraform).
tools:
  - deck
  - admin-api
  - konnect-api
  - kic
  - terraform

# OPTIONAL: Include only if this example requires a different minimum version
# than what is declared in index.md. Omit if the same.
# min_version:
#   gateway: '3.4'
```

---

## Multi-example patterns

When a plugin has distinct modes or postures, create one file per scenario.

**Example: two modes**

`examples/monitor-mode.yaml` (weight: 900)
- Describes the monitoring-only / non-blocking posture
- Sets `monitor_mode: true` or equivalent

`examples/blocking-mode.yaml` (weight: 901)
- Describes the enforcement / blocking posture
- Sets `monitor_mode: false` or equivalent
- Notes the latency trade-off in `extended_description`

**Example: two credential methods**

`examples/deidentify-only.yaml` (weight: 900)
- Strict egress posture, re-identification disabled
- `reidentify.enabled: false`

`examples/deidentify-and-reidentify.yaml` (weight: 901)
- Default posture, re-identification enabled
- Omit `reidentify` block entirely or set `enabled: true`

---

## What NOT to include in example YAML

- Do not include `name:` or `enabled:` at the top level — the renderer adds these.
- Do not include the Route or Service association — examples show plugin config only.
- Do not include credentials as literal values — always use `${variable}` references.
- Do not add fields that are at their default value unless it makes the example clearer.
