---
title: How to determine and test which AWS subnets service Kongs S3 buckets.
content_type: support
description: "Use AWS's published IP range list and `jq` to determine which subnets serve a Kong S3 bucket in a given region."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: "AWS's published list of subnets for all their services"
    url: https://ip-ranges.amazonaws.com/ip-ranges.json
tldr:
  q: How do I determine which subnets AWS will use to provide IP addresses to Kong S3 buckets?
  a: |
    AWS publishes a list of subnets for all its services at `ip-ranges.json`. Filter that list with `jq` for the `S3` service and your target region, then compare the resulting subnets against the IP returned by `ping`/`dig` for your bucket's hostname to find the matching range.
---

## Overview

How do I determine which subnets AWS will use to provide IP addresses to Kong S3 buckets?

## Steps

AWS publishes a list of subnets for all their services.

We can use this list along with `jq` to filter for specific regions and services from AWS.

Example:

Using bucket URL: pulp-cloud-02-eks-01-prod-us-east-2-20220929122921552700000002.s3.amazonaws.com

This bucket holds Kong binaries which are available for download.

Note: this particular bucket name is used only to illustrate the methodology. It no longer resolves to the `us-east-2` region implied by its name — it currently resolves via `us-east-1`. Rather than relying on this specific example, use a bucket/endpoint you've freshly verified for your region, or a region-specific S3 endpoint (for example `s3.<region>.amazonaws.com`), and confirm the resolved region with `dig`/`ping` before filtering `ip-ranges.json`. The `ip-ranges.json` + `jq` methodology below remains valid regardless of which bucket you check.

1. Determine the AWS service we are targeting, in this case, it is S3 .

2. If possible, extrapolate the region the resource is in. The URL makes it easy in this case: us-east-2

3. Download the list of IP addresses and filter it based on the values:

```bash

curl https://ip-ranges.amazonaws.com/ip-ranges.json | jq -r '.prefixes[] | select(.service=="S3") | select(.region=="us-east-2") | .ip_prefix' | sort

1.178.8.0/24
16.12.60.0/22
16.12.64.0/22
18.34.252.0/22
18.34.72.0/21
3.141.102.208/28
3.141.102.224/28
3.2.67.0/24
3.5.100.0/22
3.5.104.0/22
3.5.108.0/22
3.5.128.0/22
3.5.132.0/23
3.5.88.0/22
3.5.92.0/23
52.219.141.0/24
52.219.142.0/24
52.219.143.0/24
52.219.176.0/22
52.219.212.0/22
52.219.224.0/22
52.219.228.0/22
52.219.232.0/22
52.219.80.0/20
52.219.96.0/20
```

This represents a list of all IP subnet ranges that will cover any S3 bucket address in the us-east-2 region.

To prove that the URL is indeed using these subnets, a simple `ping` and lookup can be performed.

4. `Ping` the url to determine the current IP:

```bash

ping pulp-cloud-02-eks-01-prod-us-east-2-20220929122921552700000002.s3.amazonaws.com
PING s3-w.us-east-2.amazonaws.com (52.219.84.188): 56 data bytes
```

5. Find the range in the previous list that is the closest to the returned IP.

The closest related subnet is: 52.219.80.0/20

6. Use a subnet calculator so show the IP addresses that are covered by the range. Results
