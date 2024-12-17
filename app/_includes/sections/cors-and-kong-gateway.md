
## Understanding CORS

Cross-Origin Resource Sharing, or CORS, is a set of rules for web applications that make requests across origins, i.e. to URLs that do not share the same scheme, hostname, and port as the page making the request. When making a cross-origin request, browsers send an `origin` request header, and servers must respond with a matching `Access-Control-Allow-Origin` (ACAO) header. If the two headers do not match, the browser will discard the response, and any application components that require that response’s data will not function properly.

For example,the following request/response pairs have matching CORS headers, and will succeed:

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

These two request/response pairs do not have a matching CORS headers and therefore will fail: 

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
