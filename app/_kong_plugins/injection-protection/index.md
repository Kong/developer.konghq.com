---
title: 'Injection Protection'
name: 'Injection Protection'

content_type: plugin
tier: enterprise
publisher: kong-inc
description: 'Detect and block injection attacks using regular expressions'


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.9'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: injection-protection.png

categories:
  - security

tags:
  - security
---

You can use the Injection Protection plugin to detect and block known injection patterns consistent with SQL injection, server-side include injection, and more. This plugin can complement your existing firewall solution by adding a layer of customizable protection to prevent injection attacks, or it can eliminate some content-based attacks if you don't have an existing firewall.

The Injection Protection plugin makes it easier to protect your APIs from SQL injection or other injection attacks by providing out-of-the-box regex matching for common injection attacks. 
You can also configure custom regex matching.

The Injection Protection plugin helps you detect and block known injection patterns by doing the following: 
* Extracts information from request headers, path/query parameters, or the payload body, and evaluates that content against predefined regular expressions
* Rejects the requests that match the regular expressions with a configurable HTTP status code and error message
* Logs information about rejected requests for analytics and reporting

## How does the Injection Protection plugin work?

Depending on what you have configured in the plugin's config, the Injection Protection plugin functions in the following manner, in order of execution:

1. The plugin extracts the specified content (headers, path/query parameters, payload body) from a client request.
1. The plugin checks the extracted content for matches against the specified predefined or custom regexes. 
The regexes define patterns that match well-known injection attacks.
1. Depending on if the content matches, the plugin does one of the following:
    * **Regex doesn't match:** The plugin allows the request and sends a `200` status code to the client.
    * **Regex matches:** The plugin blocks the request by sending a `400` status code to the client and sends 
    {{site.base_gateway}} an error log that contains the name of the injection type, the content that matched the pattern, and the regex that matched the content. 
    You can also configure the plugin to only log matches and allow requests that match to still be proxied.

The following diagram shows how the Injection Protection plugin detects injections and is configured to block and log matches:

<!--vale off-->
{% mermaid %}
sequenceDiagram
    actor Client
    participant Kong as {{site.base_gateway}}
    participant Plugin as Injection Protection plugin
    participant Upstream as Upstream service

    Client->>Kong: Sends a request
    Kong->>Plugin: Evaluates for regex match

    alt If no regex match
        Plugin->>Client: 200 OK
        Plugin->>Upstream: Proxies request
    else If regex matches
        Plugin->>Client: 400 Bad Request
        Plugin->>Kong: Logs injection 
    end
{% endmermaid %}
<!--vale on-->

## How do I collect and read the logs?

Logs are automatically collected when you enable the Injection Protection plugin. You can view the logs with the following options:

* [{{site.base_gateway}} error log](/gateway/logs/)
* Log serializer. You can view these logs with the following plugins:
    * [File Log](/plugins/file-log/)
    * [HTTP Log](/plugins/http-log/)
    * [Kafka Log](/plugins/kafka-log/)
    * [TCP Log](/plugins/tcp-log/)
    * [UDP Log](/plugins/udp-log/)
* [{{site.konnect_short_name}} {{site.observability}}](/observability/)

Here's a sample log entry created by the Injection Protection plugin. 

```
threat detected: 'sql', action taken: log_only, found in path_and_query, query param value: foo: insert into test
```
{:.no-copy-code}

In this example:
* The plugin detected a SQL injection threat
* It created a log entry but took no other actions
* The threat was found in the request path or query
* The inserted snippet is `foo: insert into test`
