---
title: "Configure an AWS managed cache for Dedicated Cloud Gateways control plane"
content_type: how_to
permalink: /dedicated-cloud-gateways/aws-managed-cache-control-plane/
breadcrumbs:
  - /dedicated-cloud-gateways/
products:
  - gateway
works_on:
  - konnect
automated_tests: false
tldr:
  q: How do I configure ?
  a: |
    placeholder 
related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
min_version:
  gateway: '3.13'
prereqs:
  skip_product: true
  inline:
    - title: "Dedicated Cloud Gateway"
      include_content: prereqs/dedicated-cloud-gateways
      icon_url: /assets/icons/kogo-white.svg
    - title: "AWS"
      content: |
        You need an AWS IAM user account with permissions to create AWS Resource Configuration Groups, Resource Gateways, and to use AWS Resource Access Manager (RAM).

        You also need:
        * A configured [VPC and subnet](https://docs.aws.amazon.com/vpc/latest/userguide/create-vpc.html#create-vpc-and-other-resources)
        * A [resource gateway](https://docs.aws.amazon.com/vpc-lattice/latest/ug/create-resource-gateway.html)
        * A [resource configuration group](https://docs.aws.amazon.com/vpc-lattice/latest/ug/create-resource-configuration.html)
          
          Copy and save the resource configuration ID and resource definition domain name for each resource configuration. {{site.konnect_short_name}} will use these to create a mapping of upstream domain names and resource configuration IDs.  
        
        Export your AWS resource configuration domain name:
        ```sh
        export RESOURCE_DOMAIN_NAME='http://YOUR-RESOURCE-DOMAIN-NAME/anything'
        ```
        We'll use this to connect to our Dedicated Cloud Gateway service.
      icon_url: /assets/icons/aws.svg
    
faqs:
  - q: Which Availability Zones (AZs) does AWS resource endpoints support for Dedicated Cloud Gateway?
    a: |
      Dedicated Cloud Gateways supports [specific Availability Zones (AZs)](/konnect-platform/geos/#dedicated-cloud-gateways) in the supported AWS regions.
next_steps:
  - text: Dedicated Cloud Gateways production readiness checklist
    url: /dedicated-cloud-gateways/production-readiness/
---
blah