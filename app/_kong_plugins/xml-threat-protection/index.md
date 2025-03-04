---
title: 'XML Threat Protection'
name: 'XML Threat Protection'

content_type: plugin

publisher: kong-inc
description: 'Apply structural and size checks on XML payloads'

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.1'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: xml-threat-protection.png

categories:
  - traffic-control

search_aliases:
  - xml-threat-protection

related_resources:
  - text: JSON Threat Protection plugin
    url: /plugins/json-threat-protection/
---

The XML Threat Protection plugin reduces the risk of XML attacks by validating the structure of XML payloads.

The plugin validates the maximum complexity (depth of the tree), maximum size of elements, and attributes 
against your configured policy. If a request violates the policy, the plugin blocks it.

Using this plugin, you can mitigate the following threats:
* XML External Entity (XXE) attacks
* XML bomb attacks
* Oversized XML payload attacks

The checks are implemented using a streaming [SAX parser](http://www.saxproject.org/). 
This ensures that even very large and complex payloads can be validated safely.

## Using the unparsed buffer setting

Due to the way SAX parsers work, a bad input needs to be parsed first before a SAX callback allows the plugin to check its size. 
This is an even a bigger problem for elements with attributes, because both the element name and all of its attributes are returned in a single callback. 
For example, passing in 100 attributes, each with a 1 GB value, could overwhelm the system and make it run out of resources.

To mitigate this, you can use the unparsed buffer size setting: [`config.buffer`](/plugins/xml-threat-protection/reference/#schema--config-buffer).
The buffer is counted from the last byte parsed (for example, the closing tag on the previous element), to the last byte passed into the parser. 
If the buffer size is greater than the allowed value, the request is rejected.

For example, assume the following limits are defined:
* `config.localname`: 1 kB
* `config.attribute`: 10 kB
* `config.max_attributes`: 10

If a request comes containing an element with 100 attributes, each 1 GB, the parser reads the payload and tries to fire a callback
for a new element of at least 100 GB in size, since it also contains all attributes. 
This fails because the system runs out of resources.

You can mitigate this by using the unparsed buffer size.
Assume that the maximum expected size is 111 kB: one element name (1 kB), 10 attribute names (10 kB), 10 attribute values (100 kB).
* Set `config.buffer` to 113 kB, adding 2 kB for overhead and XML whitespace.
* When validating an element with 100 attributes of 1 GB each, the plugin now detects that the unparsed buffer exceeds 
the expected maximum of 113 kB and rejects the request before parsing the entire 100 GB body.

