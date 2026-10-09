---
title: Setting up the HMAC Authentication plugin
content_type: support
description: How to configure the required `Authorization` header format and calculate the HMAC signature the `hmac-auth` plugin expects.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How can the HMAC Authentication plugin be setup?
  a: |
    The `hmac-auth` plugin requires an `Authorization` header of the form `hmac username="...",algorithm="...",headers="...",signature="..."`, where the signature is an HMAC (for example `hmac-sha256`) computed over the headers listed in the plugin's `enforce_headers` config (typically `date` and `request-line`) using the consumer credential's secret. The request's `Date` header must also fall within the plugin's configured skew tolerance, or Kong returns a `HMAC signature cannot be verified` error.
related_resources:
  - text: the documentation for the plugin
    url: /plugins/hmac-auth/#clock-skew
---

## Overview

When using the HMAC Authentication plugin, an error is returned to the client;

```
{"message":"HMAC signature cannot be verified, a valid date or x-date header is required for HMAC Authentication"}
```

If a Date header is added, then a different error is returned;

```
{"message":"HMAC signature does not match"}
```

How can the plugin be configured to authenticate the client?

## Steps

The hmac-auth plugin requires a specific Authentication header format that includes details of the Consumer authentication username, the HMAC algorithm, the headers to use for the HMAC calculation and the actual HMAC signature itself.

Assuming that a GET request is being made to the `/hmac-echo` endpoint, the current date-time is " Mon, 07 Sep 2026 07:58:05 GMT " and the plugin has the below configuration;

```
config.enforce_headers": [ "date", "request-line" ]
```

Then the required HMAC can be found by running the below command;

```bash
printf "date: Mon, 07 Sep 2026 07:58:05 GMT\nGET /hmac-echo HTTP/1.1"  | openssl dgst -sha256 -hmac "secret123" -binary | openssl enc -base64 -A
```

which outputs the below hmac value;

```
DCiYhzZME5ox2kGkDm9gsRt7oekcxsscGVW6rOhecyo=
```

## Worked Example for the `hmac-auth` plugin

1. Create a Consumer

```bash
curl --location --request POST https://kong.lan:8444/<ws>/consumers/ \
--header 'Content-Type: application/json' \
--header 'Kong-Admin-Token: my-token' \
--data-raw '{
    "username": "hmac-consumer"
}'
```

2. Create `hmac-auth` credentials for the consumer

```bash
curl --location --request POST https://kong.lan:8444/<ws>/consumers/{{consumer_hmac-consumer}}/hmac-auth \
--header 'Content-Type: application/json;charset=UTF-8' \
--header 'Kong-Admin-Token: my-token' \
--data-raw '{"username":"hmac-username",
"secret":"secret123"}'
```

3. Create an "echo" Service

```bash
curl --location --request POST https://kong.lan:8444/<ws>/services \
--header 'Content-Type: application/json' \
--header 'Kong-Admin-Token: my-token' \
--data-raw '{
   "host":"httpbin.org",
   "protocol":"http",
   "name":"hmac-service",
   "port":80,
   "path":"/anything",
   "retries":0
}'
```

4. Create a Route for the Service

```bash
curl --location --request POST https://kong.lan:8444/<ws>/services/{{service_hmac-service}}/routes \
--header 'Kong-Admin-Token: my-token' \
--header 'Content-Type: application/json' \
--data-raw '{
	"strip_path": true,
	"path_handling": "v1",
	"paths": ["/hmac-echo"],
	"protocols": ["http"],
	"name": "hmacEcho-route"
}'
```

5. Add the `hmac-auth` plugin to the Route

```bash
curl --location --request POST https://kong.lan:8444/<ws>/routes/{{route_hmacEcho-route}}/plugins/ \
--header 'Content-Type: application/json' \
--header 'Kong-Admin-Token: my-token' \
--data-raw '{
    "name": "hmac-auth",
            "config": {
                "clock_skew": 60,
                "enforce_headers": [
                    "date",
                    "request-line"
                ],
                "algorithms": [
                    "hmac-sha256"
                ],
                "hide_credentials": true
            }
}'
```

6. Create the required HMAC header values, `Date` and HMAC signature

```bash
export HMAC_DATE=$(TZ='GMT' date '+%a, %d %b %Y %T %Z')
export HMAC_SIGNATURE=$(printf "date: $HMAC_DATE\nGET /hmac-echo HTTP/1.1"  | openssl dgst -sha256 -hmac "secret123" -binary | openssl enc -base64 -A)
```

7. Call the `hmac-auth` protected endpoint without the `Authorization` header;

```bash
curl -k --http1.1 'http://kong-proxy:8000/hmac-echo' -H 'Date: '"$HMAC_DATE"''
{
  "message":"Unauthorized"
}
```

8. Call the `hmac-auth` protected endpoint with the `Authorization` header;

```bash
curl -k --http1.1 'http://kong-proxy:8000/hmac-echo' \
-H 'Authorization: hmac username="hmac-username",algorithm="hmac-sha256",headers="date request-line",signature="'$HMAC_SIGNATURE'"' \
-H 'Date: '"$HMAC_DATE"''
{
  "args": {}, 
  "data": "", 
  "files": {}, 
  "form": {}, 
  "headers": {
    "Accept": "*/*", 
    "Date": "Fri, 21 Jun 2024 14:29:15 GMT", 
    "Host": "httpbin.org", 
    "User-Agent": "curl/8.6.0", 
    "X-Amzn-Trace-Id": "Root=1-66758e3b-5a8713be31c5911204f15a55", 
    "X-Consumer-Id": "00e88cc4-7ec8-4632-a2dc-a969d3de7901", 
    "X-Consumer-Username": "hmac-consumer", 
    "X-Credential-Identifier": "hmac-username", 
    "X-Forwarded-Host": "api.kong.lan", 
    "X-Forwarded-Path": "/hmac-echo", 
    "X-Forwarded-Prefix": "/hmac-echo", 
    "X-Kong-Request-Id": "298016373263b8217bb8d240d1f72835"
  }, 
  "json": null, 
  "method": "GET", 
  "origin": "172.20.0.12, 138.201.126.179", 
  "url": "http://api.kong.lan/anything"
}
```

Note the `username` supplied in the `Authorization` header must match the `hmac-auth` **credential's** `username` field (`hmac-username`, from step 2), not the Consumer's own `username` (`hmac-consumer`, from step 1) — supplying the Consumer's username instead returns `401 {"message":"HMAC signature cannot be verified"}`.

The plugin configuration has a skew value of 60 seconds. If you make a call using the token after 60 seconds, then you will see an "401 - Unauthorized" error.

```bash
curl -k --http1.1 'http://kong-proxy:8000/hmac-echo' \
-H 'Authorization: hmac username="hmac-username",algorithm="hmac-sha256",headers="date request-line",signature="'$HMAC_SIGNATURE'"' \
-H 'Date: '"$HMAC_DATE"''
{"message":"HMAC signature cannot be verified, a valid date or x-date header is required for HMAC Authentication"}
```

You would need to recalculate the HMAC value for the new date-time value and resubmit the request.

Below is an Insomnia "pre request" script that will calculate values for the `Date` and `Authorization` headers and add those to the request. Note, this example uses HTTP1.1 as the protocol version;

```javascript
const crypto = require('crypto-js')

var tsUTC = new Date().toUTCString();
var credentialsUsername = "hmac-username";
var hmacSecret = "secret123";
var hmacAlgorithm = "hmac-sha256"
//var hmacHeaders = ["date", "request-line", "x-custom","x-other-custom"]
var hmacHeaders = ["date","request-line"]

var hmacMessage = "";
var hmacHeaderString = "";

hmacHeaders.forEach(addHeader);

function addHeader(header, index) {
    hmacHeaderString = hmacHeaderString + header.toLowerCase() + " "
    if (header.toLowerCase() == "date") {
      hmacMessage = hmacMessage + header.toLowerCase() + ": " + tsUTC + "\n"
    }
    else if (header.toLowerCase() == "request-line") {
      hmacMessage = hmacMessage + insomnia.request.method + ' ' + insomnia.request.url.path.join('/') + " HTTP/1.1\n"
    }
    else
      hmacMessage = hmacMessage + header.toLowerCase() + ": " + insomnia.request.headers.get(header) + "\n"
    }

// remove trailing newline
hmacMessage = hmacMessage.replace(/\n$/, "")
//console.log("hmacMessage=" + hmacMessage)

var hmac = crypto.HmacSHA256(hmacMessage, hmacSecret);
var hmacBase64String = crypto.enc.Base64.stringify(hmac);

var authParts = ["hmac username=\""+credentialsUsername+"\"", "algorithm=\""+hmacAlgorithm+"\"", "headers=\""+ hmacHeaderString.trim() + "\"", "signature=\"" + hmacBase64String + "\""];

//console.log("authParts=" + authParts.toString());
//console.log("tsUTC=" + tsUTC);

insomnia.variables.set("hmacAuth", authParts.toString());
insomnia.variables.set('timestampUTC',tsUTC);

insomnia.request.addHeader({key: 'Date', value: tsUTC });
insomnia.request.addHeader({key: 'Authorization', value: authParts.toString() });
```

Note, the client and server need to have a synchronized time, preferably using NTP, to ensure the HMAC values can correctly be aligned. When calculating if the HMAC is within the allowable skew time range, the Kong server compares the value of the `Date` header to the epoch time on the server. Sending the `Date` header with GMT format avoids any problems with date comparisons. This is mentioned in the documentation for the plugin.
