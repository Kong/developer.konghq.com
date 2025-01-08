
## Understanding CORS

For security purposes a browser will stop requests from accessing URLs on different domains. This is done using CORS, a set of rules for web applications that make requests across origin. CORS works by looking at the HTTP `origin` header of a URL and checking it against a list of allowed headers. An `origin` header can contain the `scheme`, `hostname`, or `port` of the requesting URL. Operations that are restricted to same-origin content can be managed using CORS.

When making a cross-origin request, browsers issue an `origin` request header, and servers must respond with a matching `Access-Control-Allow-Origin` (ACAO) header. If the two headers do not match, the browser will discard the response, and any application components that require that response’s data will not function properly.

For example, the following request and response pairs have matching CORS headers, and will succeed:

```sh
GET / HTTP/1.1
Host: example.com
Origin: http://example.net

HTTP/1.1 200 OK
Access-Control-Allow-Origin: http://example.net
```

```sh
GET / HTTP/1.1
Host: example.com
Origin: http://example.net

HTTP/1.1 200 OK
Access-Control-Allow-Origin: *
```

The requests do not have a matching CORS headers and therefore will fail: 

```sh
GET / HTTP/1.1
Host: example.com
Origin: http://example.net

HTTP/1.1 200 OK
Access-Control-Allow-Origin: http://badbadcors.example
```

```sh
GET / HTTP/1.1
Host: example.com
Origin: http://example.net

HTTP/1.1 200 OK
```

Missing CORS headers when CORS headers are expected results in failure.
