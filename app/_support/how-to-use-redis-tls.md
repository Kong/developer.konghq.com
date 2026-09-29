---
title: How to use TLS-enabled Redis as a strategy for the `rate-limiting-advanced` plugin
content_type: support
description: "Set up a TLS-enabled Redis instance and configure it as the strategy for the `rate-limiting-advanced` plugin, including sharing one Redis instance across multiple Kong nodes."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: "`lua_ssl_trusted_certificate` reference"
    url: "/gateway/configuration/#lua-ssl-trusted-certificate"
tldr:
  q: How do I configure a TLS-enabled Redis instance as the strategy for the `rate-limiting-advanced` plugin?
  a: |
    Build Redis with `BUILD_TLS=yes`, generate a CA and Redis certificate/key pair, and enable `tls-port` in `redis.conf`. Configure the `rate-limiting-advanced` plugin with `config.strategy=redis`, `config.redis.ssl=true`, and `config.redis.ssl_verify=true`, then add the Redis CA certificate to `lua_ssl_trusted_certificate` (or the `KONG_LUA_SSL_TRUSTED_CERTIFICATE` environment variable) and restart Kong. Multiple Kong nodes can safely share the same Redis instance for this plugin.
---

## Overview

1. How to enable TLS for Redis
2. How to use TLS-enabled Redis as a strategy for the `rate-limiting-advanced` plugin
3. Can multiple Kong nodes share the same Redis instance?

## 1. How to enable TLS for Redis

Below is an example of installing redis-6.0.5 on CentOS 7.

### Step 1: Install dependencies

```bash
#Change to root user
sudo su
#Update CentOS package repository
yum update -y
#Install packages that are needed to compile and install Redis from source
yum install wget -y
yum install tcl -y
yum install gcc -y
yum install centos-release-scl -y
yum install devtoolset-9-gcc devtooset-g-gcc-c++ devtoolset-9-binutils -y
yum install openssl-devel* -y
#Update GCC
scl enable devtoolset-9 bash
echo "source /opt/rh/devtoolset-9/enable" >> /etc/profile
```

### Step 2: Install Redis by using make

```bash
#Create redis user
useradd --system redis
#create directories used by Redis
#Set necessary permissions
mkdir /var/lib/redis
chown redis:redis /var/lib/redis
mkdir /var/log/redis
touch /var/log/redis/redis.log
chmod 660 /var/log/redis
chmod 640 /var/log/redis/redis.log
mkdir /etc/redis
chown -R redis:redis /etc/redis

#Download redis
cd /tmp/
mkdir redis
cd redis/
wget http://download.redis.io/releases/redis-6.0.5.tar.gz
tar -xzvf redis-6.0.5.tar.gz
cd redis-6.0.5
#Install by make, set BUILD_TLS as yes
make BUILD_TLS=yes install
```

### Step 3: Start Redis without TLS

```bash
#Move redis.conf to the /etc/redis/
cp redis.conf /etc/redis
chown redis:redis /etc/redis/redis.conf
chmod 640 /etc/redis/redis.conf

#Modify redis to listen from any IP address
vi /etc/redis/redis.conf
-bind 127.0.0.1
+bind 0.0.0.0

#Start redis without TLS
/usr/local/bin/redis-server /etc/redis/redis.conf &
#Now we can access redis without TLS
/usr/local/bin/redis-cli -h localhost -p 6379
localhost:6379> ping
PONG
```

### Step 4: Create the TLS certificate and key

```bash
#Move to a new directory for the operation
mkdir /tmp/certs && cd /tmp/certs

#Generating a key
openssl genrsa -out ca.key 4096
#Generating a certificate
openssl req -x509 -new -nodes -sha256 -key ca.key -days 365 -subj '/O=Redislabs/CN=Redis Prod CA' -out ca.crt

#Generating the redis private key
openssl genrsa -out redis.key 2048
mkdir /etc/ssl/private
#Generating the redis certificate
openssl req -new -sha256 -nodes -key redis.key -subj '/O=Redislabs/CN=Production Redis' | openssl x509 -req -sha256 -CA ca.crt -CAkey ca.key -CAserial /etc/ssl/private/ca.txt -CAcreateserial -days 365 -out redis.crt

#Move the keys/certs to the appropriate locations
mkdir /usr/local/share/ca-certificates
cp ca.crt /usr/local/share/ca-certificates/
cp ca.key /etc/ssl/private/
cp redis.key /etc/ssl/private/
cp redis.crt /etc/ssl/
#set necessary permissions
chown redis:redis /usr/local/share/ca-certificates/ca.crt
chmod 644 /usr/local/share/ca-certificates/ca.crt
chown redis:redis /etc/ssl/private/ca.key
chmod 400 /etc/ssl/private/ca.key
chown redis:redis /etc/ssl/private/redis.key
chmod 400 /etc/ssl/private/redis.key
chown redis:redis /etc/ssl/redis.crt
chmod 644 /etc/ssl/redis.crt
```

### Step 5: Start Redis with TLS

```bash
#Modify redis.conf to enable TLS
vi /etc/redis/redis.conf
+port 0
+tls-port 6379
+tls-cert-file /etc/ssl/redis.crt
+tls-key-file /etc/ssl/private/redis.key
+tls-ca-cert-file /usr/local/share/ca-certificates/ca.crt
+tls-auth-clients no
+tls-protocols "TLSv1.2"
+tls-ciphersuites TLS_CHACHA20_POLY1305_SHA256
+tls-prefer-server-ciphers no

/usr/local/bin/redis-server /etc/redis/redis.conf &

#Now we can not access redis without TLS
/usr/local/bin/redis-cli -h localhost -p 6379
localhost:6379> ping
Error
#Now we can access redis with TLS
/usr/local/bin/redis-cli -h localhost -p 6379 --tls --cacert /usr/local/share/ca-certificates/ca.crt
localhost:6379> ping
PONG
```

## 2. How to use TLS-enabled Redis as a strategy for the `rate-limiting-advanced` plugin

### Step 1: Add the `rate-limiting-advanced` plugin with the following configuration

(This is an example of adding the `rate-limiting-advanced` plugin to a route that only allows 5 requests in 5 minutes.)

```bash
curl -X POST http://<kong>:8001/routes/<route-name>/plugins \
    --data "name=rate-limiting-advanced"  \
    --data "config.limit=5" \
    --data "config.window_size=300" \
    --data "config.sync_rate=-1" \
    --data "config.strategy=redis" \
    --data "config.redis.host=<redis-host>" \
    --data "config.redis.port=6379" \
    --data "config.redis.ssl=true" \
    --data "config.redis.ssl_verify=true"
```

### Step 2: Add the Redis certificate to `lua_ssl_trusted_certificate` and restart Kong

Store `/usr/local/share/ca-certificates/ca.crt` from Step 4 above somewhere Kong can access.

If Kong is not installed in Docker/K8s, please set `lua_ssl_trusted_certificate=/path/to/ca.crt` in the Kong configuration file (e.g., `kong.conf`).

If Kong is installed in Docker/K8s, please set the environment variable `KONG_LUA_SSL_TRUSTED_CERTIFICATE=/path/to/ca.crt`.

Please check the `lua_ssl_trusted_certificate` reference for more detail.

### Step 3: Check the result by making 6 consecutive requests

```bash
#For the 1st ~ 5th access
curl -i <kong>:8000/<route-name>
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 491
Connection: keep-alive
RateLimit-Remaining: (This value shows how many times remaining, e.g 4-0)
RateLimit-Limit: 5
X-RateLimit-Limit-300: 5
X-RateLimit-Remaining-300: (This value shows how many times remaining, e.g 4-0)
RateLimit-Reset: 61
Server: gunicorn/19.9.0
Date: Thu, 06 Aug 2026 14:49:00 GMT
Access-Control-Allow-Origin: *
Access-Control-Allow-Credentials: true
X-Kong-Upstream-Latency: 18
X-Kong-Proxy-Latency: 90
Via: 1.1 kong/3.14.0.0-enterprise-edition
X-Kong-Request-Id: c48f99447ab88a09c1259026afa74b6e

...

#For the 6th access
curl -i <kong>:8000/<route-name>
HTTP/1.1 429 Too Many Requests
Date: Thu, 06 Aug 2026 14:49:00 GMT
Content-Type: application/json; charset=utf-8
Connection: keep-alive
RateLimit-Remaining: 0
RateLimit-Limit: 5
X-RateLimit-Limit-300: 5
X-RateLimit-Remaining-300: 0
Retry-After: 120
RateLimit-Reset: 120
Content-Length: 37
X-Kong-Response-Latency: 0
Server: kong/3.14.0.0-enterprise-edition
X-Kong-Request-Id: 691d82238eb0d90064fbad24d7e3bb32

{"message":"API rate limit exceeded"}
```

## 3. Can multiple Kong nodes share the same Redis instance?

Yes.

For example, Kong1 and Kong2 are installed in different environments and use different databases. They can share the same Redis instance for their `rate-limiting-advanced` plugins. No conflict will happen.
