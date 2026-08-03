---
title: 'Kong Ingress Controller "could not update kong admin" error caused by an invalid declarative configuration'
content_type: support
description: The Kong declarative configuration is invalid.
products:
  - kic
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does KIC log a "could not update kong admin" error when syncing configuration?
  a: |
    KIC fails to push new config to the Admin API when the generated declarative configuration contains invalid entities, for example duplicate plugins or entities missing a primary key. Use decK to dump the current configuration and run `deck validate` against it to locate and fix the invalid entries, then reapply the config.
related_resources:
  - text: decK installation instructions
    url: /deck/installation/
---

## Problem

KIC could not sync the latest k8s config to Kong. A similar error to below is present in the KIC log:

```
time="2023-03-17T06:47:51Z" level=error msg="could not update kong admin" error="posting new config to /config: HTTP status 400 (message: \"declarative config is invalid: {plugins={[217]={route={id=\\\"missing primary key\\\"}},[218]={route={id=\\\"missing primary key\\\"}}}}\")" subsystem=proxy-cache-resolver
```

This error prevents updates being made to the Kong configuration.

## Solution

The Kong declarative configuration is invalid.

To get more detailed information about the specific config entries that are invalid, follow the below process:

1. Obtain a configuration dump following this procedure: Obtain Configuration. Take a copy of the `lastbad.json` file to use in the steps below.

2. Install the latest version of decK following these instructions. Note version must be 1.18 or later.

3. Run `deck validate -s dumped_config_file.json`, this will show errors.

4. Review errors, example below:

   ```
   Error: inserting plugins into state: inserting plugin acl for route dp-loadtest.route50: entity already exists
   ```

5. Search for source of error in the config file and edit or remove.

Errors will show one at a time, continue to run until no errors remain.

Once all noted errors are resolved, configuration should validate successfully.
