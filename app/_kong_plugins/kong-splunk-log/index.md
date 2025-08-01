---
title: 'Kong Splunk Log'
name: 'Kong Splunk Log'

content_type: plugin

publisher: optum
description: "Log API transactions to Splunk using the Splunk HTTP collector"

products:
    - gateway

works_on:
    - on-prem

third_party: true

support_url: https://github.com/Optum/kong-splunk-log/issues

source_code_url: https://github.com/Optum/kong-splunk-log

license_type: Apache-2.0

icon: optum.png

search_aliases:
  - optum

min_version:
  gateway: '3.0'
---

The Kong Splunk Log plugin is a modified version of the [HTTP Log plugin](/plugins/http-log/) 
that has been refactored and tailored to work with Splunk.

We recommend enabling the Splunk Logging plugin at a global level.

## Install the Kong Spec Expose plugin

{% include_cached /plugins/install-third-party.md name=page.name slug=page.slug rock="kong-splunk-log" %}

## Configure the Splunk host

The plugin requires the `SPLUNK_HOST` environment variable. 
This is how we define the `host=""` log field in Splunk:

```bash
export SPLUNK_HOST="example.company.com"
```

Make the environment variable accessible by an Nginx worker by adding this line to your `nginx.conf`:

```
env SPLUNK_HOST;
```