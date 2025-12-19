---
title: Deploy a multi-zone global {{site.mesh_product_name}} control plane in Universal mode
description: TODO
content_type: how_to
permalink: /mesh/deploy-multi-zone-global-control-plane-universal/
bread-crumbs: 
  - /mesh/
related_resources:
  - text: "{{site.mesh_product_name}}"
    url: /mesh/

products:
  - mesh

tldr:
  q: TODO
  a: TODO
        
---

## Create network

```sh
docker network create kong-mesh-system
```
 
## Create database

```sh
docker run -d --network kong-mesh-system --name postgres -p 5432:5432 -e POSTGRES_USER=kong -e POSTGRES_PASSWORD=pass123 postgres
```

```sh
docker exec -it postgres psql -h localhost -U kong
```

```sh
CREATE DATABASE kmesh;
```
```sh
exit
```

## Create global control plane

```sh
export PATH=$(pwd)/kuma-2.12.5/bin:$PATH
```

```sh
    KUMA_STORE_TYPE=postgres \
    KUMA_STORE_POSTGRES_HOST=localhost \
    KUMA_STORE_POSTGRES_PORT=5432 \
    KUMA_STORE_POSTGRES_USER=kong \
    KUMA_STORE_POSTGRES_PASSWORD=pass123 \
    KUMA_STORE_POSTGRES_DB_NAME=kmesh \
  kuma-cp migrate up
```


```sh
    KUMA_MODE=global \
    KUMA_ENVIRONMENT=universal \
    KUMA_STORE_TYPE=postgres \
    KUMA_STORE_POSTGRES_HOST=localhost \
    KUMA_STORE_POSTGRES_PORT=5432 \
    KUMA_STORE_POSTGRES_USER=kong \
    KUMA_STORE_POSTGRES_PASSWORD=pass123 \
    KUMA_STORE_POSTGRES_DB_NAME=kmesh \
  kuma-cp run
```

## Create zone control plane

```sh
export PATH=$(pwd)/kuma-2.12.5/bin:$PATH
```

```sh
 KUMA_MODE=zone \
 KUMA_MULTIZONE_ZONE_NAME=zone-1\
 KUMA_ENVIRONMENT=universal \
 KUMA_STORE_TYPE=postgres \
 KUMA_STORE_POSTGRES_HOST=localhost \
 KUMA_STORE_POSTGRES_PORT=5432 \
 KUMA_STORE_POSTGRES_USER=kong \
 KUMA_STORE_POSTGRES_PASSWORD=pass123 \
 KUMA_STORE_POSTGRES_DB_NAME=kmesh \
 KUMA_MULTIZONE_ZONE_GLOBAL_ADDRESS=grpcs://localhost:5685 \
 KUMA_MULTIZONE_ZONE_KDS_TLS_SKIP_VERIFY=true
 kuma-cp run
```

## Configure kumactl

```sh
TOKEN=$(curl http://localhost:5681/global-secrets/admin-user-token | jq -r .data | base64 -d)
```

```sh
export PATH=$(pwd)/kuma-2.12.5/bin:$PATH
```

```sh
kumactl config control-planes add \
 --name zone-1 \
 --address http://localhost:5681 \
 --auth-type=tokens \
 --auth-conf token=$TOKEN \
 --skip-verify \
 --overwrite
```

```sh
kumactl generate zone-token --zone=zone-1 --valid-for 24h --scope egress --scope ingress > /tmp/zone-token
```

```sh
echo "type: ZoneIngress
name: ingress-01
networking:
  address: 127.0.0.1
  port: 10000
  advertisedAddress: 10.0.0.1
  advertisedPort: 10000" > ingress-dp.yaml
```

## TODO

```sh
kuma-dp run \
  --proxy-type=ingress \
  --cp-address=https://localhost:5678 \
  --dataplane-token-file=/tmp/zone-token \
  --dataplane-file=ingress-dp.yaml
```

```sh
export PATH=$(pwd)/kuma-2.12.5/bin:$PATH
```

```sh
kumactl config control-planes add \
  --name global-control-plane \
  --address http://localhost:5681 \
  --skip-verify \
  --overwrite
```

```sh
kumactl get zones
```