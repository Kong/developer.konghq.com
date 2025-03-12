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

min_version:
    gateway: '3.4'

# on_prem:
#   - hybrid
#   - db-less
#   - traditional
# konnect_deployments:
#   - hybrid
#   - cloud-gateways
#   - serverless

third_party: true

support_url: https://github.com/Optum/kong-splunk-log/issues

source_code_url: https://github.com/Optum/kong-splunk-log

license_type: Apache-2.0

icon: kong-splunk-log.png

search_aliases:
  - optum
---