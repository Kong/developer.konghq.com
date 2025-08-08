---
title: 'OPA'
name: 'OPA'

content_type: plugin
tier: enterprise
publisher: kong-inc
description: 'Authorize requests against Open Policy Agent'


products:
    - gateway

works_on:
    - on-prem
    - konnect

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: opa.png

categories:
  - security

search_aliases:
  - open policy agent

tags:
  - authorization
  - opa

related_resources:
  - text: Block unauthorized requests in {{site.base_gateway}} with the OPA plugin
    url: /how-to/block-unauthorized-requests-with-opa/
  - text: How to Implement Secure Access Control with OPA and {{site.base_gateway}}
    url: https://konghq.com/blog/engineering/secure-access-control-with-opa-and-kong

min_version:
  gateway: '2.4'

---

The OPA plugin allows you to forward requests to [Open Policy Agent](https://openpolicyagent.org/) and process the requests only if the authorization policy allows it. 

For example, if a request comes in, the OPA plugin sends the relevant details to the OPA host (`config.opa_host`) specified in the plugin configuration. If OPA approves the request, the request is allowed to proceed. If OPA denies the request, the request is rejected.

## OPA input format

When the OPA plugin is enabled, {{site.base_gateway}} uses the following JSON structure to forward request data to OPA.
It includes request data, headers, and regex capture groups, along with the information about the related [Gateway Service](/gateway/entities/service/#schema), [Route](/gateway/entities/route/#schema), and [Consumer](/gateway/entities/consumer/#schema).
For definitions of each entity parameter appearing in the example below, see each entity's schema.

```json
{
 "input": {
   "request": { # details about the request from client to Kong
     "http": {
       "host": "example.org", # host header used by the client to make the request
       "port": "8000",        # port to which the request was made
       "tls": {},             # TLS details if the request was made on HTTPS and Kong terminated the TLS connection
       "method": "GET",       # HTTP method used in the request
       "scheme": "http",      # protocol used to make the request by the client, this can be either `http` or `https`
       "path": "/foo/bar",    # HTTP path used in the request
       "querystring": {       # Query string in the HTTP request as key-value pairs
         "foo" : "bar",
         "foo2" : "bar2",
       },
       "headers": {           # HTTP headers of the request
         "accept-encoding": "gzip, deflate",
         "connection": "keep-alive",
         "accept": "*\\/*"
       },
       "uri_captures": {      # The regex capture groups captured on the Kong Gateway Route's path field in the current request. Injected only if `include_uri_captures_in_opa_input` is set to `true`.
         "named": {},
         "unnamed": []
       }
     }
   },
   "client_ip": "127.0.0.1",# client IP address as interpreted by Kong
   "service": {             # The Kong Service resource that this request is forwarded to if OPA allows. Injected only if `include_service_in_opa_input` is set to `true`.
     "host": "httpbin.konghq.com",
     "created_at": 1612819937,
     "connect_timeout": 60000,
     "id": "e6fd8b19-89e5-44e6-8a2a-79e8bf3c31a5",
     "protocol": "http",
     "name": "foo",
     "read_timeout": 60000,
     "port": 80,
     "updated_at": 1612819937,
     "ws_id": "d6020dc4-67f5-4c62-8b45-e2f497c20f5c",
     "retries": 5,
     "write_timeout": 60000
   },
   "route": {               # The Kong Route that was matched for this request. Injected only if `include_route_in_opa_input` is set to `true`.
     "id": "bc6d8617-76a7-441f-aa40-32eb1f5be9e6",
     "paths": [
       "\\/"
     ],
     "protocols": [
       "http",
       "https"
     ],
     "strip_path": true,
     "created_at": 1612819949,
     "ws_id": "d6020dc4-67f5-4c62-8b45-e2f497c20f5c",
     "request_buffering": true,
     "updated_at": 1612819949,
     "preserve_host": false,
     "regex_priority": 0,
     "response_buffering": true,
     "https_redirect_status_code": 426,
     "path_handling": "v0",
     "service": {
       "id": "e6fd8b19-89e5-44e6-8a2a-79e8bf3c31a5"
     }
   },
   "consumer": {            # Kong Consumer that was used for authentication for this request. Injected only if `include_consumer_in_opa_input` is set to `true`.
     "id": "bc6d8617-76a7-431f-aa40-32eb1f5be7e6",
     "username": "kong-consumer-username"
   }
 }
}
```

You can use this structure, along with the [OPA docs](https://www.openpolicyagent.org/docs/latest/policy-language/), as a reference to create your policies. For example, you can use `input.request.http.querystring.page` to refer to a `page` query parameter.

## OPA response

Once OPA is done executing policies, the plugin expects the policy evaluation result as either a boolean or an object. If OPA returns any other format or a status code other than `200 OK`, the plugin will return a `500 Internal Server Error` to the client.

### Boolean response

OPA can return a `true` or `false` result after a policy evaluation. If the input request meets the defined policies, OPA should send a `"result": true` response.  If the request violates the policy, OPA should send a `"result": false` response. In this case, any other fields in the response are ignored.


### Object response

For most use cases, the boolean response should suffice. However, you can configure the policy to return an object if needed. This can be used to inject custom HTTP headers to the request, or to change the HTTP code for rejected requests.

In this case, the OPA response has the following structure:
```json
{
 "result": {
   "allow": true,
   "status": 201,
   "headers": {
     "key": "value",
     "key2": "value2"
   },
   "message": "value3 or object",
 }
}
```

The only required field in this response is `result.allow`, which accepts a boolean value.

If `result.allow` is `true`, then the key-value pairs in `result.headers` are injected into the request before it's forwarded to the upstream service.

If `result.allow` is set to false, then the key-value pairs in `result.headers` are injected into the response, the response message is set to `result.message`, and the status code of the response is set to `result.status`. If `result.status` is absent, the default `403` status code is sent. If `result.message` is absent, then the default `unauthorized` message is sent.
