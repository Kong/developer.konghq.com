{:.info}
> **Note**: This policy only runs on records that the parent Schema Validation policy successfully parses.
> If the parent policy uses the `passthrough` or `mark` failure mode, records that fail schema validation are {% if include.phase == "produce" %}sent to the backend cluster{% else %}delivered to the client{% endif %} without parsing, so this policy can't run on them and their fields are left unchanged.
