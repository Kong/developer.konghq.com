{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
  - title: When to use
    key: when
rows:
  - command: |
      [`adopt`](/kongctl/adopt/)
    description: |
      Adds a namespace label to an existing {{site.konnect_short_name}} resource that was created outside of kongctl, bringing it under declarative management without modifying any other fields.
    when: |
      Use before your first `dump` or `plan`, when you need to bring a manually created or UI-created resource into your configuration.
  - command: |
      [`dump`](/kongctl/dump/)
    description: |
      Exports the current state of {{site.konnect_short_name}} resources to a declarative YAML configuration file.
    when: |
      Use when bootstrapping a new declarative configuration from existing live resources, or when generating a starting point for a new configuration file.
  - command: |
      [`plan`](/kongctl/plan/)
    description: |
      Compares your local configuration files against live {{site.konnect_short_name}} state and generates a JSON plan artifact describing the changes to be made.
    when: |
      Use before applying changes, especially in CI/CD pipelines, to produce a reviewable and reusable plan artifact.
  - command: |
      [`diff`](/kongctl/diff/)
    description: |
      Displays a human-readable preview of the changes between the current live state and the desired state in your configuration files, or from a saved plan artifact.
    when: |
      Use during development to inspect what `apply` or `sync` would change before committing.
  - command: |
      [`apply`](/kongctl/apply/)
    description: |
      Creates and updates resources to match the desired state. Does not delete resources.
    when: |
      Use to incrementally apply configuration without risk of deleting anything. Use `sync` instead when you want deletes as well.
  - command: |
      [`sync`](/kongctl/sync/)
    description: |
      Applies the full desired state from your configuration files. Creates, updates, and deletes resources.
    when: |
      Use for full reconciliation between your configuration and live state, including deletions. Use `apply` if you only want creates and updates.
  - command: |
      [`delete`](/kongctl/delete/)
    description: |
      Plans and executes deletion of all resources defined in the input configuration files.
    when: |
      Use for tearing down a known set of resources, such as resetting a test environment. Not a typical step in the day-to-day declarative workflow.
  - command: |
      [`get`](/kongctl/get/)
    description: |
      Retrieves {{site.konnect_short_name}} resources.
    when: |
      Use to inspect live state after applying configuration, or to look up resource IDs and names.
{% endtable %}
