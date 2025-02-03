{% assign konnect_token = site.data.entity_examples.config.konnect_variables.pat.placeholder %}

Synchronize your [decK](/deck/) configuration files.
Make sure you created the `deck_files` directory in the [prerequisites](#prerequisites).

First, compare the decK file or files to the state of the {{site.base_gateway}}:
```bash
deck gateway diff deck_files
```

The output shows you which entities will change if you sync the state files.

If everything looks right, synchronize them to update your Gateway configuration:

```bash
deck gateway sync deck_files
```